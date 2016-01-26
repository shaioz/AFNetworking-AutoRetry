//
// Created by Shai Ohev Zion on 1/21/14.

#import "AFHTTPRequestOperationManager+AutoRetry.h"
#import "ObjcAssociatedObjectHelpers.h"

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCUnusedMethodInspection"


@implementation AFHTTPRequestOperationManager (AutoRetry)

SYNTHESIZE_ASC_OBJ(__operationsDict, setOperationsDict);
SYNTHESIZE_ASC_OBJ(__retryDelayCalcBlock, setRetryDelayCalcBlock);

- (void)createOperationsDict {
    [self setOperationsDict:[[NSDictionary alloc] init]];
}

- (void)createDelayRetryCalcBlock {
    RetryDelayCalcBlock block = ^int(int totalRetries, int currentRetry, int delayInSecondsSpecified) {
        return delayInSecondsSpecified;
    };
    [self setRetryDelayCalcBlock:block];
}

- (id)retryDelayCalcBlock {
    if (!self.__retryDelayCalcBlock) {
        [self createDelayRetryCalcBlock];
    }
    return self.__retryDelayCalcBlock;
}

- (id)operationsDict {
    if (!self.__operationsDict) {
        [self createOperationsDict];
    }
    return self.__operationsDict;
}

// subclass and overide this method if necessary
- (BOOL)isErrorFatal:(NSError *)error {
    switch (error.code) {
        case kCFHostErrorHostNotFound:
        case kCFHostErrorUnknown: // Query the kCFGetAddrInfoFailureKey to get the value returned from getaddrinfo; lookup in netdb.h
            // HTTP errors
        case kCFErrorHTTPAuthenticationTypeUnsupported:
        case kCFErrorHTTPBadCredentials:
        case kCFErrorHTTPParseFailure:
        case kCFErrorHTTPRedirectionLoopDetected:
        case kCFErrorHTTPBadURL:
        case kCFErrorHTTPBadProxyCredentials:
        case kCFErrorPACFileError:
        case kCFErrorPACFileAuth:
        case kCFStreamErrorHTTPSProxyFailureUnexpectedResponseToCONNECTMethod:
            // Error codes for CFURLConnection and CFURLProtocol
        case kCFURLErrorUnknown:
        case kCFURLErrorCancelled:
        case kCFURLErrorBadURL:
        case kCFURLErrorUnsupportedURL:
        case kCFURLErrorHTTPTooManyRedirects:
        case kCFURLErrorBadServerResponse:
        case kCFURLErrorUserCancelledAuthentication:
        case kCFURLErrorUserAuthenticationRequired:
        case kCFURLErrorZeroByteResource:
        case kCFURLErrorCannotDecodeRawData:
        case kCFURLErrorCannotDecodeContentData:
        case kCFURLErrorCannotParseResponse:
        case kCFURLErrorInternationalRoamingOff:
        case kCFURLErrorCallIsActive:
        case kCFURLErrorDataNotAllowed:
        case kCFURLErrorRequestBodyStreamExhausted:
        case kCFURLErrorFileDoesNotExist:
        case kCFURLErrorFileIsDirectory:
        case kCFURLErrorNoPermissionsToReadFile:
        case kCFURLErrorDataLengthExceedsMaximum:
            // SSL errors
        case kCFURLErrorServerCertificateHasBadDate:
        case kCFURLErrorServerCertificateUntrusted:
        case kCFURLErrorServerCertificateHasUnknownRoot:
        case kCFURLErrorServerCertificateNotYetValid:
        case kCFURLErrorClientCertificateRejected:
        case kCFURLErrorClientCertificateRequired:
        case kCFURLErrorCannotLoadFromNetwork:
            // Cookie errors
        case kCFHTTPCookieCannotParseCookieFile:
            // Errors originating from CFNetServices
        case kCFNetServiceErrorUnknown:
        case kCFNetServiceErrorCollision:
        case kCFNetServiceErrorNotFound:
        case kCFNetServiceErrorInProgress:
        case kCFNetServiceErrorBadArgument:
        case kCFNetServiceErrorCancel:
        case kCFNetServiceErrorInvalid:
            // Special case
        case 101: // null address
        case 102: // Ignore "Frame Load Interrupted" errors. Seen after app store links.
            return YES;
        default:
            break;
    }
    return NO;
}

- (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)request
                                                    success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                                    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
                                                autoRetryOf:(int)retriesRemaining retryInterval:(int)intervalInSeconds {

    void (^retryBlock)(AFHTTPRequestOperation *, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error) {
        // error is fatal, do not retry
        if ([self isErrorFatal:error]) {
            ARLog(@"AutoRetry: Request failed with error: %@", error.localizedDescription);
            failure(operation, error);
            return;
        }
        
        // reached the maximum retry count
        NSMutableDictionary *retryOperationDict = self.operationsDict[request];
        int originalRetryCount = [retryOperationDict[@"originalRetryCount"] intValue];
        int retriesRemainingCount = [retryOperationDict[@"retriesRemainingCount"] intValue];
        if (!retriesRemainingCount) {
            ARLog(@"AutoRetry: Request failed %d times: %@", originalRetryCount, error.localizedDescription);
            ARLog(@"AutoRetry: No more retries allowed! executing supplied failure block...");
            failure(operation, error);
            ARLog(@"AutoRetry: done.");
            return;
        }
        
        // Retry request
            ARLog(@"AutoRetry: Request failed: %@, retry %d out of %d begining...",
                    error.localizedDescription, originalRetryCount - retriesRemainingCount + 1, originalRetryCount);
        
        NSMutableURLRequest * newRequest = [request mutableCopy];
        newRequest.timeoutInterval *= 1.5f;
        AFHTTPRequestOperation *retryOperation = [self HTTPRequestOperationWithRequest:newRequest
                                                                                   success:success
                                                                                   failure:failure
                                                                               autoRetryOf:retriesRemainingCount - 1
                                                                             retryInterval:intervalInSeconds];
            void (^addRetryOperation)() = ^{
                [self.operationQueue addOperation:retryOperation];
            };
            RetryDelayCalcBlock delayCalc = self.retryDelayCalcBlock;
            int intervalToWait = delayCalc(originalRetryCount, retriesRemainingCount, intervalInSeconds);
            if (intervalToWait > 0) {
                ARLog(@"AutoRetry: Delaying retry for %d seconds...", intervalToWait);
                dispatch_time_t delay = dispatch_time(0, (int64_t) (intervalToWait * NSEC_PER_SEC));
                dispatch_after(delay, dispatch_get_main_queue(), ^(void) {
                    addRetryOperation();
                });
            } else {
                addRetryOperation();
            }
    };
    NSMutableDictionary *operationDict = self.operationsDict[request];
    if (!operationDict) {
        operationDict = [NSMutableDictionary new];
        operationDict[@"originalRetryCount"] = [NSNumber numberWithInt:retriesRemaining];
    }
    operationDict[@"retriesRemainingCount"] = [NSNumber numberWithInt:retriesRemaining];
    NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithDictionary:self.operationsDict];
    newDict[request] = operationDict;
    self.operationsDict = newDict;
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request
                                                                      success:^(AFHTTPRequestOperation *operation, id responseObj) {
                                                                          NSMutableDictionary *successOperationDict = self.operationsDict[request];
                                                                          int originalRetryCount = [successOperationDict[@"originalRetryCount"] intValue];
                                                                          int retriesRemainingCount = [successOperationDict[@"retriesRemainingCount"] intValue];
                                                                          ARLog(@"AutoRetry: success with %d retries, running success block...", originalRetryCount - retriesRemainingCount);
                                                                          success(operation, responseObj);
                                                                          ARLog(@"AutoRetry: done.");

                                                                      } failure:retryBlock];

    return operation;
}

- (AFHTTPRequestOperation *)POST:(NSString *)URLString parameters:(NSDictionary *)parameters success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure autoRetry:(int)timesToRetry {
    return [self POST:URLString parameters:parameters success:success failure:failure autoRetry:timesToRetry retryInterval:0];
}

- (AFHTTPRequestOperation *)GET:(NSString *)URLString parameters:(NSDictionary *)parameters success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure autoRetry:(int)timesToRetry {
    return [self GET:URLString parameters:parameters success:success failure:failure autoRetry:timesToRetry retryInterval:0];
}

- (AFHTTPRequestOperation *)HEAD:(NSString *)URLString parameters:(NSDictionary *)parameters success:(void (^)(AFHTTPRequestOperation *operation))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure autoRetry:(int)timesToRetry {
    return [self HEAD:URLString parameters:parameters success:success failure:failure autoRetry:timesToRetry retryInterval:0];
}

- (AFHTTPRequestOperation *)POST:(NSString *)URLString parameters:(NSDictionary *)parameters constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure autoRetry:(int)timesToRetry {
    return [self POST:URLString parameters:parameters constructingBodyWithBlock:block success:success failure:failure autoRetry:timesToRetry retryInterval:0];
}

- (AFHTTPRequestOperation *)PUT:(NSString *)URLString parameters:(NSDictionary *)parameters success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure autoRetry:(int)timesToRetry {
    return [self PUT:URLString parameters:parameters success:success failure:failure autoRetry:timesToRetry retryInterval:0];
}

- (AFHTTPRequestOperation *)PATCH:(NSString *)URLString parameters:(NSDictionary *)parameters success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure autoRetry:(int)timesToRetry {
    return [self PATCH:URLString parameters:parameters success:success failure:failure autoRetry:timesToRetry retryInterval:0];
}

- (AFHTTPRequestOperation *)DELETE:(NSString *)URLString parameters:(NSDictionary *)parameters success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure autoRetry:(int)timesToRetry {
    return [self DELETE:URLString parameters:parameters success:success failure:failure autoRetry:timesToRetry retryInterval:0];
}


- (AFHTTPRequestOperation *)POST:(NSString *)URLString
                      parameters:(NSDictionary *)parameters
                         success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
                       autoRetry:(int)timesToRetry
                   retryInterval:(int)intervalInSeconds {
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"POST" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:parameters error:nil];
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure autoRetryOf:timesToRetry retryInterval:intervalInSeconds];
    [self.operationQueue addOperation:operation];

    return operation;
}


- (AFHTTPRequestOperation *)GET:(NSString *)URLString
                     parameters:(NSDictionary *)parameters
                        success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                        failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
                      autoRetry:(int)timesToRetry
                  retryInterval:(int)intervalInSeconds {
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"GET" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:parameters error:nil];
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure autoRetryOf:timesToRetry retryInterval:intervalInSeconds];
    [self.operationQueue addOperation:operation];

    return operation;
}

- (AFHTTPRequestOperation *)HEAD:(NSString *)URLString
                      parameters:(NSDictionary *)parameters
                         success:(void (^)(AFHTTPRequestOperation *operation))success
                         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
                       autoRetry:(int)timesToRetry
                   retryInterval:(int)intervalInSeconds {
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"HEAD" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:parameters error:nil];
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *requestOperation, __unused id responseObject) {
        if (success) {
            success(requestOperation);
        }
    }                                                                 failure:failure autoRetryOf:timesToRetry retryInterval:intervalInSeconds];
    [self.operationQueue addOperation:operation];

    return operation;
}

- (AFHTTPRequestOperation *)POST:(NSString *)URLString
                      parameters:(NSDictionary *)parameters
       constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
                         success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
                       autoRetry:(int)timesToRetry
                   retryInterval:(int)intervalInSeconds {
    NSMutableURLRequest *request = [self.requestSerializer multipartFormRequestWithMethod:@"POST" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:parameters constructingBodyWithBlock:block error:nil];
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure autoRetryOf:timesToRetry retryInterval:intervalInSeconds];
    [self.operationQueue addOperation:operation];

    return operation;
}

- (AFHTTPRequestOperation *)PUT:(NSString *)URLString
                     parameters:(NSDictionary *)parameters
                        success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                        failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
                      autoRetry:(int)timesToRetry
                  retryInterval:(int)intervalInSeconds {
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"PUT" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:parameters error:nil];
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure autoRetryOf:timesToRetry retryInterval:intervalInSeconds];
    [self.operationQueue addOperation:operation];

    return operation;
}

- (AFHTTPRequestOperation *)PATCH:(NSString *)URLString
                       parameters:(NSDictionary *)parameters
                          success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                          failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
                        autoRetry:(int)timesToRetry
                    retryInterval:(int)intervalInSeconds {
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"PATCH" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:parameters error:nil];
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure autoRetryOf:timesToRetry retryInterval:intervalInSeconds];
    [self.operationQueue addOperation:operation];

    return operation;
}

- (AFHTTPRequestOperation *)DELETE:(NSString *)URLString
                        parameters:(NSDictionary *)parameters
                           success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                           failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
                         autoRetry:(int)timesToRetry
                     retryInterval:(int)intervalInSeconds {
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"DELETE" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:parameters error:nil];
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure autoRetryOf:timesToRetry retryInterval:intervalInSeconds];
    [self.operationQueue addOperation:operation];

    return operation;
}

@end

#pragma clang diagnostic pop
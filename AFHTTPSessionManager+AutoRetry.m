//
// Created by Shai Ohev Zion on 1/23/14.
// Copyright (c) 2014 shaioz. All rights reserved.

#import "AFHTTPRequestOperationManager+AutoRetry.h"
#import "AFHTTPSessionManager+AutoRetry.h"
#import "ObjcAssociatedObjectHelpers.h"


#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCUnusedMethodInspection"

@implementation AFHTTPSessionManager (AutoRetry)

SYNTHESIZE_ASC_OBJ(__tasksDict, setTasksDict);
SYNTHESIZE_ASC_OBJ(__retryDelayCalcBlock, setRetryDelayCalcBlock);

- (void)createTasksDict {
    [self setTasksDict:[[NSDictionary alloc] init]];
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

- (id)tasksDict {
    if (!self.__tasksDict) {
        [self createTasksDict];
    }
    return self.__tasksDict;
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

- (void)setTimeout:(NSTimeInterval)timeout {
    [NSURLSessionConfiguration defaultSessionConfiguration].timeoutIntervalForRequest = timeout;
    [NSURLSessionConfiguration defaultSessionConfiguration].timeoutIntervalForResource = timeout;
}

- (NSURLSessionDataTask *)requestUrlWithAutoRetry:(int)retriesRemaining
                                    retryInterval:(int)intervalInSeconds
                           originalRequestCreator:(NSURLSessionDataTask *(^)(void (^)(NSURLSessionDataTask *, NSError *)))taskCreator
                                  originalFailure:(void(^)(NSURLSessionDataTask *, NSError *))failure {
    
    static NSTimeInterval timeout = 0;
    id taskcreatorCopy = [taskCreator copy];
    void(^retryBlock)(NSURLSessionDataTask *, NSError *) = ^(NSURLSessionDataTask *task, NSError *error) {
        // error is fatal, do not retry
        if ([self isErrorFatal:error]) {
            ARLog(@"AutoRetry: Request failed with error: %@", error.localizedDescription);
            failure(task, error);
            return;
        }
        
        // reached the maximum retry count
        NSMutableDictionary *retryOperationDict = self.tasksDict[taskcreatorCopy];
        int originalRetryCount = [retryOperationDict[@"originalRetryCount"] intValue];
        int retriesRemainingCount = [retryOperationDict[@"retriesRemainingCount"] intValue];
        if (!retriesRemainingCount) {
            ARLog(@"AutoRetry: Request failed %d times: %@", originalRetryCount, error.localizedDescription);
            ARLog(@"AutoRetry: No more retries allowed! executing supplied failure block...");
            failure(task, error);
            ARLog(@"AutoRetry: done.");
        }
        
        // Retry the request
            ARLog(@"AutoRetry: Request failed: %@, retry %d out of %d begining...",
                error.localizedDescription, originalRetryCount - retriesRemainingCount + 1, originalRetryCount);
            void (^addRetryOperation)() = ^{
            [self setTimeout:[NSURLSessionConfiguration defaultSessionConfiguration].timeoutIntervalForRequest*1.5f];
                [self requestUrlWithAutoRetry:retriesRemaining - 1 retryInterval:intervalInSeconds originalRequestCreator:taskCreator originalFailure:failure];
            };
            RetryDelayCalcBlock delayCalc = self.retryDelayCalcBlock;
            int intervalToWait = delayCalc(originalRetryCount, retriesRemainingCount, intervalInSeconds);
            if (intervalToWait > 0) {
                ARLog(@"AutoRetry: Delaying retry for %d seconds...", intervalToWait);
                dispatch_time_t delay = dispatch_time(0, (int64_t)(intervalToWait * NSEC_PER_SEC));
                dispatch_after(delay, dispatch_get_main_queue(), ^(void){
                    addRetryOperation();
                });
            } else {
                addRetryOperation();
            }
    };
    NSURLSessionDataTask *task = taskCreator(retryBlock);
    NSMutableDictionary *taskDict = self.tasksDict[taskcreatorCopy];
    if (!taskDict) {
        taskDict = [NSMutableDictionary new];
        taskDict[@"originalRetryCount"] = [NSNumber numberWithInt:retriesRemaining];
        if (!timeout) {
            timeout = [NSURLSessionConfiguration defaultSessionConfiguration].timeoutIntervalForRequest;
    }
        [self setTimeout:timeout];
    }
    taskDict[@"retriesRemainingCount"] = [NSNumber numberWithInt:retriesRemaining];
    NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithDictionary:self.tasksDict];
    newDict[task] = taskDict;
    self.tasksDict = newDict;
    return task;
}

- (NSURLSessionDataTask *)GET:(NSString *)URLString
                   parameters:(NSDictionary *)parameters
                      success:(void (^)(NSURLSessionDataTask *task, id respo))success
                      failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
                    autoRetry:(int)timesToRetry
                retryInterval:(int)intervalInSeconds
{
    NSURLSessionDataTask *task = [self requestUrlWithAutoRetry:timesToRetry retryInterval:intervalInSeconds originalRequestCreator:^NSURLSessionDataTask *(void (^retryBlock)(NSURLSessionDataTask *, NSError *)) {
        return [self GET:URLString parameters:parameters success:success failure:retryBlock];
    } originalFailure:failure];
    return task;
}

- (NSURLSessionDataTask *)HEAD:(NSString *)URLString
                    parameters:(NSDictionary *)parameters
                       success:(void (^)(NSURLSessionDataTask *task))success
                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
                     autoRetry:(int)timesToRetry
                 retryInterval:(int)intervalInSeconds
{
    NSURLSessionDataTask *task = [self requestUrlWithAutoRetry:timesToRetry retryInterval:intervalInSeconds originalRequestCreator:^NSURLSessionDataTask *(void (^retryBlock)(NSURLSessionDataTask *, NSError *)) {
        return [self HEAD:URLString parameters:parameters success:success failure:retryBlock];
    } originalFailure:failure];
    return task;
}

- (NSURLSessionDataTask *)POST:(NSString *)URLString
                    parameters:(NSDictionary *)parameters
                       success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
                     autoRetry:(int)timesToRetry
                 retryInterval:(int)intervalInSeconds
{
    NSURLSessionDataTask *task = [self requestUrlWithAutoRetry:timesToRetry retryInterval:intervalInSeconds originalRequestCreator:^NSURLSessionDataTask *(void (^retryBlock)(NSURLSessionDataTask *, NSError *)) {
        return [self POST:URLString parameters:parameters success:success failure:retryBlock];
    } originalFailure:failure];
    return task;
}

- (NSURLSessionDataTask *)POST:(NSString *)URLString
                    parameters:(NSDictionary *)parameters
     constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
                       success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
                     autoRetry:(int)timesToRetry
                 retryInterval:(int)intervalInSeconds
{
    NSURLSessionDataTask *task = [self requestUrlWithAutoRetry:timesToRetry retryInterval:intervalInSeconds originalRequestCreator:^NSURLSessionDataTask *(void (^retryBlock)(NSURLSessionDataTask *, NSError *)) {
        return [self POST:URLString parameters:parameters constructingBodyWithBlock:block success:success failure:retryBlock];
    } originalFailure:failure];
    return task;
}

- (NSURLSessionDataTask *)PUT:(NSString *)URLString
                   parameters:(NSDictionary *)parameters
                      success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                      failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
                    autoRetry:(int)timesToRetry
                retryInterval:(int)intervalInSeconds
{

    NSURLSessionDataTask *task = [self requestUrlWithAutoRetry:timesToRetry retryInterval:intervalInSeconds originalRequestCreator:^NSURLSessionDataTask *(void (^retryBlock)(NSURLSessionDataTask *, NSError *)) {
        return [self PUT:URLString parameters:parameters success:success failure:retryBlock];
    } originalFailure:failure];
    return task;
}

- (NSURLSessionDataTask *)PATCH:(NSString *)URLString
                     parameters:(NSDictionary *)parameters
                        success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                        failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
                      autoRetry:(int)timesToRetry
                  retryInterval:(int)intervalInSeconds
{

    NSURLSessionDataTask *task = [self requestUrlWithAutoRetry:timesToRetry retryInterval:intervalInSeconds originalRequestCreator:^NSURLSessionDataTask *(void (^retryBlock)(NSURLSessionDataTask *, NSError *)) {
        return [self PATCH:URLString parameters:parameters success:success failure:retryBlock];
    } originalFailure:failure];
    return task;
}

- (NSURLSessionDataTask *)DELETE:(NSString *)URLString
                      parameters:(NSDictionary *)parameters
                         success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                         failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
                       autoRetry:(int)timesToRetry
                   retryInterval:(int)intervalInSeconds
{
    NSURLSessionDataTask *task = [self requestUrlWithAutoRetry:timesToRetry retryInterval:intervalInSeconds originalRequestCreator:^NSURLSessionDataTask *(void (^retryBlock)(NSURLSessionDataTask *, NSError *)) {
        return [self DELETE:URLString parameters:parameters success:success failure:retryBlock];
    } originalFailure:failure];
    return task;
}

- (NSURLSessionDataTask *)GET:(NSString *)URLString
                   parameters:(NSDictionary *)parameters
                      success:(void (^)(NSURLSessionDataTask *task, id respo))success
                      failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
                    autoRetry:(int)timesToRetry {
    return [self GET:URLString parameters:parameters success:success failure:failure autoRetry:timesToRetry retryInterval:0];
}

- (NSURLSessionDataTask *)HEAD:(NSString *)URLString
                    parameters:(NSDictionary *)parameters
                       success:(void (^)(NSURLSessionDataTask *task))success
                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
                     autoRetry:(int)timesToRetry {
    return [self HEAD:URLString parameters:parameters success:success failure:failure autoRetry:timesToRetry retryInterval:0];
}

- (NSURLSessionDataTask *)POST:(NSString *)URLString
                    parameters:(NSDictionary *)parameters
                       success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
                     autoRetry:(int)timesToRetry {
    return [self POST:URLString parameters:parameters success:success failure:failure autoRetry:timesToRetry retryInterval:0];
}

- (NSURLSessionDataTask *)POST:(NSString *)URLString
                    parameters:(NSDictionary *)parameters
     constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
                       success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
                     autoRetry:(int)timesToRetry {
    return [self POST:URLString parameters:parameters constructingBodyWithBlock:block success:success failure:failure autoRetry:timesToRetry retryInterval:0];
}

- (NSURLSessionDataTask *)PUT:(NSString *)URLString
                   parameters:(NSDictionary *)parameters
                      success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                      failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
                    autoRetry:(int)timesToRetry {
    return [self PUT:URLString parameters:parameters success:success failure:failure autoRetry:timesToRetry retryInterval:0];
}

- (NSURLSessionDataTask *)DELETE:(NSString *)URLString
                      parameters:(NSDictionary *)parameters
                         success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                         failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
                       autoRetry:(int)timesToRetry {
    return [self DELETE:URLString parameters:parameters success:success failure:failure autoRetry:timesToRetry retryInterval:0];
}


@end

#pragma clang diagnostic pop

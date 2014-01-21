//
// Created by Shai Ohev Zion on 1/21/14.

#import "AFHTTPRequestOperationManager+AutoRetry.h"

@implementation AFHTTPRequestOperationManager (AutoRetry)
- (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)request success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure autoRetryOf:(int)timesToRetry {
    AFHTTPRequestOperation *(^requestBlock)(NSURLRequest *, void (^)(AFHTTPRequestOperation *, id), void(^)(AFHTTPRequestOperation *, NSError *)) = ^(NSURLRequest *requestObject, void (^successBlock)(AFHTTPRequestOperation *, id), void (^failureBlock)(AFHTTPRequestOperation *, NSError *)) {
        return [self HTTPRequestOperationWithRequest:requestObject success:successBlock failure:failureBlock];
    };
    void (^retryBlock)(AFHTTPRequestOperation *, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error) {
        if (timesToRetry > 0) {
            NSLog(@"AutoRetry: Request failed: %@, retry begining...", error.localizedDescription);
            AFHTTPRequestOperation *retryOperation = [self HTTPRequestOperationWithRequest:request success:success failure:failure autoRetryOf:timesToRetry-1];
            [self.operationQueue addOperation:retryOperation];
        } else {
            NSLog(@"AutoRetry: Request failed: %@, no more retries allowed! executing supplied failure block...", error.localizedDescription);
            failure(operation, error);
            NSLog(@"AutoRetry: done.");
        }
    };
    AFHTTPRequestOperation *operation = requestBlock(request, ^(AFHTTPRequestOperation *operation, id o) {
        
    }, retryBlock);
    return operation;
}

- (AFHTTPRequestOperation *)POST:(NSString *)URLString
                      parameters:(NSDictionary *)parameters
                         success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
                       autoRetry:(int)timesToRetry
{
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"POST" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:parameters error:nil];
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure autoRetryOf:timesToRetry];
    [self.operationQueue addOperation:operation];

    return operation;
}


@end
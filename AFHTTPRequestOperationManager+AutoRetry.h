//
// Created by Shai Ohev Zion on 1/21/14.

#import <Foundation/Foundation.h>
#import "AFHTTPRequestOperationManager.h"

@interface AFHTTPRequestOperationManager (AutoRetry)

- (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)request
                                                    success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                                    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
                                                autoRetryOf:(int)timesToRetry;



- (AFHTTPRequestOperation *)POST:(NSString *)URLString
                      parameters:(NSDictionary *)parameters
                         success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                         failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
                       autoRetry:(int)timesToRetry;

@end
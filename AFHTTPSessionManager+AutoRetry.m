//
// Created by Shai Ohev Zion on 1/23/14.
// Copyright (c) 2014 shaioz. All rights reserved.

#import "AFHTTPSessionManager+AutoRetry.h"


#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCUnusedMethodInspection"

@implementation AFHTTPSessionManager (AutoRetry)

- (NSURLSessionDataTask *)requestUrlWithAutoRetry:(int)timesToRetry
                                    retryInterval:(int)intervalInSeconds
                           originalRequestCreator:(NSURLSessionDataTask *(^)(void (^)(NSURLSessionDataTask *, NSError *)))taskCreator
                                  originalFailure:(void(^)(NSURLSessionDataTask *, NSError *))failure {
    
    void(^retryBlock)(NSURLSessionDataTask *, NSError *) = ^(NSURLSessionDataTask *task, NSError *error) {
        int retryCount = timesToRetry;
        if (retryCount > 0) {
            NSLog(@"AutoRetry: Request failed: %@, retry begining...", error.localizedDescription);
            void (^addRetryOperation)() = ^{
                [self requestUrlWithAutoRetry:timesToRetry-1 retryInterval:intervalInSeconds originalRequestCreator:taskCreator originalFailure:failure];
            };
            if (intervalInSeconds > 0) {
                NSLog(@"AutoRetry: Delaying retry for %d seconds...", intervalInSeconds);
                dispatch_time_t delay = dispatch_time(0, (int64_t)(intervalInSeconds * NSEC_PER_SEC));
                dispatch_after(delay, dispatch_get_main_queue(), ^(void){
                    addRetryOperation();
                });
            } else {
                addRetryOperation();
            }
        } else {
            NSLog(@"AutoRetry: Request failed: %@, no more retries allowed! executing supplied failure block...", error.localizedDescription);
            failure(task, error);
            NSLog(@"AutoRetry: done.");
        } 
    };
    NSURLSessionDataTask *task = taskCreator(retryBlock);
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
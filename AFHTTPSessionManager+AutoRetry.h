//
// Created by Shai Ohev Zion on 1/23/14.
// Edited by Shivan Raptor on 1/28/16.
// Copyright (c) 2014 shaioz. All rights reserved.

#ifdef DEBUG
#define ARLog(format, ...)  NSLog(format, ## __VA_ARGS__)
#else
#define ARLog(...)
#endif

#import <Foundation/Foundation.h>
#import "AFHTTPSessionManager.h"

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCUnusedMethodInspection"

NS_ASSUME_NONNULL_BEGIN

typedef int (^RetryDelayCalcBlock)(int, int, int); // int totalRetriesAllowed, int retriesRemaining, int delayBetweenIntervalsModifier

@interface AFHTTPSessionManager (AutoRetry)

- (nullable NSURLSessionDataTask *)requestUrlWithAutoRetry:(int)retriesRemaining
                                    retryInterval:(int)intervalInSeconds
                           originalRequestCreator:(NSURLSessionDataTask *(^)(void (^)(NSURLSessionDataTask *, NSError *)))taskCreator
                                  originalFailure:(nullable void (^)(NSURLSessionDataTask *, NSError *))failure;

- (nullable NSURLSessionDataTask *)GET:(NSString *)URLString
                   parameters:(nullable NSDictionary *)parameters
                     progress:(nullable void (^)(NSProgress * _Nonnull))downloadProgress
                      success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable respo))success
                      failure:(nullable void (^)(NSURLSessionDataTask *task, NSError *error))failure
                    autoRetry:(int)timesToRetry
                retryInterval:(int)intervalInSeconds;

- (nullable NSURLSessionDataTask *)HEAD:(NSString *)URLString
                    parameters:(nullable NSDictionary *)parameters
                       success:(nullable void (^)(NSURLSessionDataTask *task))success
                       failure:(nullable void (^)(NSURLSessionDataTask *task, NSError *error))failure
                     autoRetry:(int)timesToRetry
                 retryInterval:(int)intervalInSeconds;

- (nullable NSURLSessionDataTask *)POST:(NSString *)URLString
                    parameters:(nullable NSDictionary *)parameters
                      progress:(nullable nullable void (^)(NSProgress * _Nonnull))uploadProgress
                       success:(nullable void (^)(NSURLSessionDataTask *task, id responseObject))success
                       failure:(nullable void (^)(NSURLSessionDataTask *task, NSError *error))failure
                     autoRetry:(int)timesToRetry
                 retryInterval:(int)intervalInSeconds;

- (nullable NSURLSessionDataTask *)POST:(NSString *)URLString
                    parameters:(nullable NSDictionary *)parameters
     constructingBodyWithBlock:(nullable void (^)(id <AFMultipartFormData> formData))block
                      progress:(nullable nullable void (^)(NSProgress * _Nonnull))uploadProgress
                       success:(nullable void (^)(NSURLSessionDataTask *task, id responseObject))success
                       failure:(nullable void (^)(NSURLSessionDataTask *task, NSError *error))failure
                     autoRetry:(int)timesToRetry
                 retryInterval:(int)intervalInSeconds;

- (nullable NSURLSessionDataTask *)PUT:(NSString *)URLString
                   parameters:(nullable NSDictionary *)parameters
                      success:(nullable void (^)(NSURLSessionDataTask *task, id responseObject))success
                      failure:(nullable void (^)(NSURLSessionDataTask *task, NSError *error))failure
                    autoRetry:(int)timesToRetry
                retryInterval:(int)intervalInSeconds;

- (nullable NSURLSessionDataTask *)PATCH:(NSString *)URLString
                     parameters:(nullable NSDictionary *)parameters
                        success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable responseObject))success
                        failure:(nullable void (^)(NSURLSessionDataTask * task, NSError *error))failure
                      autoRetry:(int)timesToRetry
                  retryInterval:(int)intervalInSeconds;

- (nullable NSURLSessionDataTask *)DELETE:(NSString *)URLString
                      parameters:(nullable NSDictionary *)parameters
                         success:(nullable void (^)(NSURLSessionDataTask *task, id responseObject))success
                         failure:(nullable void (^)(NSURLSessionDataTask *task, NSError *error))failure
                       autoRetry:(int)timesToRetry
                   retryInterval:(int)intervalInSeconds;

- (nullable NSURLSessionDataTask *)GET:(NSString *)URLString
                   parameters:(nullable NSDictionary *)parameters
                      success:(nullable void (^)(NSURLSessionDataTask *task, id respo))success
                      failure:(nullable void (^)(NSURLSessionDataTask *task, NSError *error))failure
                    autoRetry:(int)timesToRetry;

- (nullable NSURLSessionDataTask *)HEAD:(NSString *)URLString
                    parameters:(nullable NSDictionary *)parameters
                       success:(nullable void (^)(NSURLSessionDataTask *task))success
                       failure:(nullable void (^)(NSURLSessionDataTask *task, NSError *error))failure
                     autoRetry:(int)timesToRetry;

- (nullable NSURLSessionDataTask *)POST:(NSString *)URLString
                    parameters:(nullable NSDictionary *)parameters
                       success:(nullable void (^)(NSURLSessionDataTask *task, id responseObject))success
                       failure:(nullable void (^)(NSURLSessionDataTask *task, NSError *error))failure
                     autoRetry:(int)timesToRetry;

- (nullable NSURLSessionDataTask *)POST:(NSString *)URLString
                    parameters:(nullable NSDictionary *)parameters
     constructingBodyWithBlock:(nullable void (^)(id <AFMultipartFormData> formData))block
                       success:(nullable void (^)(NSURLSessionDataTask *task, id responseObject))success
                       failure:(nullable void (^)(NSURLSessionDataTask *task, NSError *error))failure
                     autoRetry:(int)timesToRetry;

- (nullable NSURLSessionDataTask *)PUT:(NSString *)URLString
                   parameters:(nullable NSDictionary *)parameters
                      success:(nullable void (^)(NSURLSessionDataTask *task, id responseObject))success
                      failure:(nullable void (^)(NSURLSessionDataTask *task, NSError *error))failure
                    autoRetry:(int)timesToRetry;

- (nullable NSURLSessionDataTask *)DELETE:(NSString *)URLString
                      parameters:(nullable NSDictionary *)parameters
                         success:(nullable void (^)(NSURLSessionDataTask *task, id responseObject))success
                         failure:(nullable void (^)(NSURLSessionDataTask *task, NSError *error))failure
                       autoRetry:(int)timesToRetry;

// Deprecated functions
- (nullable NSURLSessionDataTask *)GET:(NSString *)URLString
                            parameters:(nullable NSDictionary *)parameters
                               success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable respo))success
                               failure:(nullable void (^)(NSURLSessionDataTask *task, NSError *error))failure
                             autoRetry:(int)timesToRetry
                         retryInterval:(int)intervalInSeconds DEPRECATED_ATTRIBUTE;

- (nullable NSURLSessionDataTask *)POST:(NSString *)URLString
                             parameters:(nullable NSDictionary *)parameters
                                success:(nullable void (^)(NSURLSessionDataTask *task, id responseObject))success
                                failure:(nullable void (^)(NSURLSessionDataTask *task, NSError *error))failure
                              autoRetry:(int)timesToRetry
                          retryInterval:(int)intervalInSeconds  DEPRECATED_ATTRIBUTE;

- (nullable NSURLSessionDataTask *)POST:(NSString *)URLString
                             parameters:(nullable NSDictionary *)parameters
              constructingBodyWithBlock:(nullable void (^)(id <AFMultipartFormData> formData))block
                                success:(nullable void (^)(NSURLSessionDataTask *task, id responseObject))success
                                failure:(nullable void (^)(NSURLSessionDataTask *task, NSError *error))failure
                              autoRetry:(int)timesToRetry
                          retryInterval:(int)intervalInSeconds  DEPRECATED_ATTRIBUTE;

@property (strong) id tasksDict;
@property (copy) id retryDelayCalcBlock;

@end

NS_ASSUME_NONNULL_END

#pragma clang diagnostic pop
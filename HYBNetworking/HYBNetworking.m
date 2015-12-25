//
//  HYBNetworking.m
//  AFNetworkingDemo
//
//  Created by huangyibiao on 15/11/15.
//  Copyright © 2015年 huangyibiao. All rights reserved.
//

#import "HYBNetworking.h"
#import <AFNetworking.h>
#import <AFNetworkActivityIndicatorManager.h>

// 项目打包上线都不会打印日志，因此可放心。
#ifdef DEBUG
#define HYBAppLog(s, ... ) NSLog( @"[%@：in line: %d]-->[message: %@]", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define HYBAppLog(s, ... )
#endif

static NSString *sg_privateNetworkBaseUrl = nil;
static BOOL sg_isEnableInterfaceDebug = NO;
static BOOL sg_shouldAutoEncode = YES;
static NSDictionary *sg_httpHeaders = nil;
static HYBResponseType sg_responseType = kHYBResponseTypeJSON;
static HYBRequestType  sg_requestType  = kHYBRequestTypeJSON;

@implementation HYBNetworking

+ (void)updateBaseUrl:(NSString *)baseUrl {
  sg_privateNetworkBaseUrl = baseUrl;
}

+ (NSString *)baseUrl {
  return sg_privateNetworkBaseUrl;
}

+ (void)enableInterfaceDebug:(BOOL)isDebug {
  sg_isEnableInterfaceDebug = isDebug;
}

+ (BOOL)isDebug {
  return sg_isEnableInterfaceDebug;
}

+ (void)configResponseType:(HYBResponseType)responseType {
  sg_responseType = responseType;
}

+ (void)configRequestType:(HYBRequestType)requestType {
  sg_requestType = requestType;
}

+ (void)shouldAutoEncodeUrl:(BOOL)shouldAutoEncode {
  sg_shouldAutoEncode = shouldAutoEncode;
}

+ (BOOL)shouldEncode {
  return sg_shouldAutoEncode;
}

+ (void)configCommonHttpHeaders:(NSDictionary *)httpHeaders {
  sg_httpHeaders = httpHeaders;
}

+ (HYBRequestOperation *)getWithUrl:(NSString *)url
                            success:(HYBResponseSuccess)success
                               fail:(HYBResponseFail)fail {
  return [self getWithUrl:url params:nil success:success fail:fail];
}

+ (HYBRequestOperation *)getWithUrl:(NSString *)url
                             params:(NSDictionary *)params
                            success:(HYBResponseSuccess)success
                               fail:(HYBResponseFail)fail {
  AFHTTPRequestOperationManager *manager = [self manager];
  
  if ([self shouldEncode]) {
    url = [self encodeUrl:url];
  }
  
  AFHTTPRequestOperation *op = [manager GET:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
    if (success) {
      success(responseObject);
    }
    
    if ([self isDebug]) {
      [self logWithSuccessResponse:responseObject url:operation.response.URL.absoluteString params:params];
    }
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    if (fail) {
      fail(error);
    }
    
    if ([self isDebug]) {
      [self logWithFailError:error url:operation.response.URL.absoluteString params:params];
    }
  }];
  
  return op;
}

+ (HYBRequestOperation *)postWithUrl:(NSString *)url
                              params:(NSDictionary *)params
                             success:(HYBResponseSuccess)success
                                fail:(HYBResponseFail)fail {
  if ([self shouldEncode]) {
    url = [self encodeUrl:url];
  }
  
  AFHTTPRequestOperationManager *manager = [self manager];
  
  AFHTTPRequestOperation *op = [manager POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
    if (success) {
      success(responseObject);
    }
    
    if ([self isDebug]) {
      [self logWithSuccessResponse:responseObject url:operation.response.URL.absoluteString params:params];
    }
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    if (fail) {
      fail(error);
    }
    
    if ([self isDebug]) {
      [self logWithFailError:error url:operation.response.URL.absoluteString params:params];
    }
  }];
  
  return op;
}

+ (HYBRequestOperation *)uploadWithImage:(UIImage *)image
                                     url:(NSString *)url
                                filename:(NSString *)filename
                                    name:(NSString *)name
                                 success:(HYBResponseSuccess)success
                                    fail:(HYBResponseFail)fail {
  if ([self shouldEncode]) {
    url = [self encodeUrl:url];
  }
  
  AFHTTPRequestOperationManager *manager = [self manager];
  AFHTTPRequestOperation *op = [manager POST:url parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
    NSData *imageData = UIImageJPEGRepresentation(image, 1);
    
    NSString *imageFileName = filename;
    if (filename == nil || ![filename isKindOfClass:[NSString class]] || filename.length == 0) {
      NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
      formatter.dateFormat = @"yyyyMMddHHmmss";
      NSString *str = [formatter stringFromDate:[NSDate date]];
      imageFileName = [NSString stringWithFormat:@"%@.jpg", str];
    }
    
    // 上传图片，以文件流的格式
    [formData appendPartWithFileData:imageData name:name fileName:imageFileName mimeType:@"image/jpeg"];
  } success:^(AFHTTPRequestOperation *operation, id responseObject) {
    if (success) {
      success(responseObject);
    }
    
    if ([self isDebug]) {
      [self logWithSuccessResponse:responseObject url:operation.response.URL.absoluteString params:nil];
    }
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    if (fail) {
      fail(error);
    }
    
    if ([self isDebug]) {
      [self logWithFailError:error url:operation.response.URL.absoluteString params:nil];
    }
  }];
  
  return op;
}

#pragma mark - Private
+ (AFHTTPRequestOperationManager *)manager {
  // 开启转圈圈
  [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
  
  AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc]
                                            initWithBaseURL:[NSURL URLWithString:[self baseUrl]]];
  switch (sg_requestType) {
    case kHYBRequestTypeJSON: {
      manager.requestSerializer = [AFJSONRequestSerializer serializer];
      break;
    }
    case kHYBRequestTypePlainText: {
      manager.requestSerializer = [AFHTTPRequestSerializer serializer];
      break;
    }
    default: {
      break;
    }
  }

  switch (sg_responseType) {
    case kHYBResponseTypeJSON: {
      manager.responseSerializer = [AFJSONResponseSerializer serializer];
      break;
    }
    case kHYBResponseTypeXML: {
      manager.responseSerializer = [AFXMLParserResponseSerializer serializer];
      break;
    }
    default: {
      break;
    }
  }

  manager.requestSerializer.stringEncoding = NSUTF8StringEncoding;
  
  [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
  [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

  for (NSString *key in sg_httpHeaders.allKeys) {
    if (sg_httpHeaders[key] != nil) {
      [manager.requestSerializer setValue:sg_httpHeaders[key] forHTTPHeaderField:key];
    }
  }
  manager.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[@"application/json",
                                                                            @"text/html",
                                                                            @"text/json",
                                                                            @"text/javascript",
                                                                            @"text/xml",
                                                                            @"image/*"]];
  
  // 设置允许同时最大并发数量，过大容易出问题
  manager.operationQueue.maxConcurrentOperationCount = 3;
  return manager;
}

+ (void)logWithSuccessResponse:(id)response url:(NSString *)url params:(NSDictionary *)params {
  HYBAppLog(@"\nabsoluteUrl: %@\n params:%@\n response:%@\n\n",
            url,
            params,
            response);
}

+ (void)logWithFailError:(NSError *)error url:(NSString *)url params:(NSDictionary *)params {
  HYBAppLog(@"\nabsoluteUrl: %@\n params:%@\n errorInfos:%@\n\n",
            url,
            params,
            [error localizedDescription]);
}

+ (NSString *)encodeUrl:(NSString *)url {
  return [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

@end

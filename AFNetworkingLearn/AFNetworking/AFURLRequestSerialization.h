//
//  AFURLRequestSerialization.h
//  AFNetworkingLearn
//
//  Created by 车 on 2018/6/7.
//  Copyright © 2018年 车. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TargetConditionals.h>

#if TARGET_OS_IOS || TARGET_OS_TV
#import <UIKit/UIKit.h>
#elif TARGET_OS_WATCH
#import <WatchKit/WatchKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

// 将字符串进行URL编码
FOUNDATION_EXPORT NSString * AFPercentEscapedStringFromString(NSString *string);

// 将字典转换成URL编码的参数
FOUNDATION_EXPORT NSString * AFQueryStringFromParameters(NSDictionary *parameters);

@protocol AFURLRequestSerialization <NSObject, NSSecureCoding, NSCopying>

// 
- (nullable NSURLRequest *)requestBySerializiingRequest:(NSURLRequest *)request withParameters:(nullable id)parameters error:(NSError *_Nullable __autoreleasing *)error NS_SWIFT_NOTHROW;

@end

#pragma mark -

typedef NS_ENUM(NSUInteger, AFHTTPRequestQueryStringSerializationStyle) {
    AFHTTPRequestQueryStringDefaultStyle = 0,
};

@protocol AFMultipartFormData;

@interface AFHTTPRequestSerializer : NSObject <AFURLRequestSerialization>

// 字符串编码 默认是NSUTF8StringEncoding
@property (nonatomic, assign) NSStringEncoding stringEncoding;

// 是否允许访问蜂窝数据 默认YES
@property (nonatomic, assign) BOOL allowsCellularAccess;

// 缓存策略 默认是NSURLRequestUseProtocolCachePolicy
@property (nonatomic, assign) NSURLRequestCachePolicy cachePolicy;

// 是否使用默认的cookie处理 默认是YES
@property (nonatomic, assign) BOOL HTTPShouldHandleCookies;

// 是否使用管线化 默认NO
@property (nonatomic, assign) BOOL HTTPShouldUsePipelining;

// 网络服务类型
@property (nonatomic, assign) NSURLRequestNetworkServiceType networkServiceType;

// 超时时间
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

// HTTP Header信息
@property (readonly, nonatomic, strong) NSDictionary <NSString *, NSString *> *HTTPRequestHeaders;

// 返回默认实例对象
+ (instancetype)serializer;

// 设置 HTTP header 当value为nil 移除field
- (void)setValue:(nullable NSString *)value
forHTTPHeaderField:(NSString *)field;

// 返回field标记的内容
- (nullable NSString *)valueForHTTPHeaderField:(NSString *)field;

// 根据 username&password 设置Authorization字段
- (void)setAuthorizationHeaderFieldWithUsername:(NSString *)username
                                       password:(NSString *)password;

// 清空
- (void)clearAuthorizationHeader;

// 需要把参数拼接到url中 HTTP methods 默认这个集合包含了 GET/HEAD/DELETE
@property (nonatomic, strong) NSSet <NSString *> *HTTPMethodsEncodingParametersInURI;

// 设置查询字符串序列化的样式, AFN只实现了百分比编码
- (void)setQueryStringSerializationWithStyle:(AFHTTPRequestQueryStringSerializationStyle)style;

// 可以自定制序列化方法, 这个方法通过这个block实现 AFN内部查询字符串序列化会调用这个方法
- (void)setQueryStringSerializationWithBlock:(nullable NSString * (^)(NSURLRequest *request, id parameters, NSError * __autoreleasing *error))block;

/******** Creating Request Objects ********/

// 生成并返回一个NSMutableURLRequest对象 当method为 GET/HEAD/DELETE 时,参数会被拼接到URL中,其他情况则会当做requset的body处理
- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                 URLString:(NSString *)URLString
                                parameters:(nullable id)parameters
                                     error:(NSError * _Nullable __autoreleasing *)error;

// 支持上传数据
- (NSMutableURLRequest *)multipartFormRequestWithMethod:(NSString *)method
                                              URLString:(NSString *)URLString
                                             parameters:(nullable NSDictionary <NSString *, id> *)parameters
                              constructingBodyWithBlock:(nullable void (^)(id <AFMultipartFormData> formData))block
                                                  error:(NSError * _Nullable __autoreleasing *)error;

// 通过一个 Multipart-Form 的request创建一个request 新request的httpBody是fileURL指定的文件,并且是通过HTTPBodyStream这个属性添加,HTTPBodyStream属性的数据会自动添加为httpBody
- (NSMutableURLRequest *)requestWithMultipartFormRequest:(NSURLRequest *)request
                             writingStreamContentsToFile:(NSURL *)fileURL
                                       completionHandler:(nullable void (^)(NSError * _Nullable error))handler;
@end

#pragma mark -

@protocol AFMultipartFormData

//
- (BOOL)appendPartWithFileURL:(NSURL *)fileURL
                         name:(NSString *)name
                        error:(NSError * _Nullable __autoreleasing *)error;

//
- (BOOL)appendPartWithFileURL:(NSURL *)fileURL
                         name:(NSString *)name
                     fileName:(NSString *)fileName
                     mimeType:(NSString *)mimeType
                        error:(NSError * _Nullable __autoreleasing *)error;

//
- (void)appendPartWithInputStream:(nullable NSInputStream *)inputStream
                             name:(NSString *)name
                         fileName:(NSString *)fileName
                           length:(int64_t)length
                         mimeType:(NSString *)mimeType;

//
- (void)appendPartWithFileData:(NSData *)data
                          name:(NSString *)name
                      fileName:(NSString *)fileName
                      mimeType:(NSString *)mimeType;

//
- (void)appendPartWithFormData:(NSData *)data
                          name:(NSString *)name;

//
- (void)appendPartWithHeaders:(nullable NSDictionary <NSString *, NSString *> *)headers
                         body:(NSData *)body;

//
- (void)throttleBandwidthWithPacketSize:(NSUInteger)numberOfBytes
                                  delay:(NSTimeInterval)delay;

@end

#pragma mark -

@interface AFJSONRequestSerializer : AFHTTPRequestSerializer

@property (nonatomic, assign) NSJSONWritingOptions writingOptions;

//
+ (instancetype)serializerWithWritingOptions:(NSJSONWritingOptions)writingOptions;

@end

#pragma mark -

@interface AFPropertyListRequestSerializer : AFHTTPRequestSerializer

@property (nonatomic, assign) NSPropertyListFormat format;

@property (nonatomic, assign) NSPropertyListWriteOptions writeOptions;

+ (instancetype)serializerWithFormat:(NSPropertyListFormat)format
                        writeOptions:(NSPropertyListWriteOptions)writeOptions;

@end

#pragma mark -

FOUNDATION_EXPORT NSString * const AFURLRequestSerializationErrorDomain;

FOUNDATION_EXPORT NSString * const AFNetworkingOperationFailingURLRequestErrorKey;

FOUNDATION_EXPORT NSUInteger const kAFUploadStream3GSuggestedPacketSize;
FOUNDATION_EXPORT NSTimeInterval const kAFUploadStream3GSuggestedDelay;


x : NSObject

@end

NS_ASSUME_NONNULL_END

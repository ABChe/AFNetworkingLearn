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

- (nullable NSURLRequest *)requestBySerializiingRequest:(NSURLRequest *)request withParameters:(nullable id)parameters error:(NSError *_Nullable __autoreleasing *)error NS_SWIFT_NOTHROW;

@end

@interface AFURLRequestSerialization : NSObject

@end

NS_ASSUME_NONNULL_END

//
//  AFNetworkReachabilityManager.h
//  AFNetworkingLearn
//
//  Created by 车 on 2018/5/29.
//  Copyright © 2018年 车. All rights reserved.
//

#import <Foundation/Foundation.h>

#if !TARGET_OS_WATCH
#import <SystemConfiguration/SystemConfiguration.h>

typedef NS_ENUM(NSInteger, AFNetworkReachabilityStatus) {
    AFNetworkReachabilityStatusUnknown          = -1,   // 未知
    AFNetworkReachabilityStatusNotReachable     = 0,    // 无网络
    AFNetworkReachabilityStatusReachableViaWWAN = 1,    // WWAN
    AFNetworkReachabilityStatusReachableViaWiFi = 2,    // WiFi
};

/* NS_ASSUME_NONNULL_BEGIN 和 NS_ASSUME_NONNULL_END 在这两个宏之间的代码 所有简单指针对象都被假定为nonnul */
NS_ASSUME_NONNULL_BEGIN

@interface AFNetworkReachabilityManager : NSObject

// 网络状态
@property (readonly, nonatomic, assign) AFNetworkReachabilityStatus networkReachabilityStatus;

// 是否可达
@property (readonly, nonatomic, assign, getter = isReachable) BOOL reachable;

// WWAN 是否可达
@property (readonly, nonatomic, assign, getter = isReachableViaWWAN) BOOL reachableViaWWAN;

// WiFi是否可达
@property (readonly, nonatomic, assign, getter = isReachableViaWiFi) BOOL reachableViaWiFi;


#pragma mark - Initialize

//
- (instancetype)shareManager;

//
+ (instancetype)manager;

//
+ (instancetype)managerForDomain:(NSString *)domain;

//
+ (instancetype)managerForAddress:(const void *)address;

//
- (instancetype)initWithReachability:(SCNetworkReachabilityRef)reachability NS_DESIGNATED_INITIALIZER;

//
+ (instancetype)new NS_UNAVAILABLE;

//
- (instancetype)init NS_UNAVAILABLE;


#pragma mark - Start & stop Reachability Moitoring

// 开始监听
- (void)startMonitoring;

// 暂停监听
- (void)stopMonitoring;


#pragma mark - Getting Localized Reachability Description

//
- (NSString *)localozedNetworkReachabilityStatusString;


#pragma mark - Setting Network Reachability Change Callback

//
- (void)setReachabilityStatusChangeBlock:(nullable void (^)(AFNetworkReachabilityStatus status))block;

@end


#pragma mark - Notifications

/* FOUNDATION_EXPORT 定义的字符串可以使用'=='进行直接判断 比较的是__地址__
   define 比较的是每个字符 相对来说前者效率更高
 */
FOUNDATION_EXPORT NSString * const AFNetworkingReachabilityDidChangeNotification;
FOUNDATION_EXPORT NSString * const AFNetworkingReachabilityNotificationStatusItem;


#pragma mark - Functions

FOUNDATION_EXPORT NSString * AFStringFromNetworkReachabilityStatus(AFNetworkReachabilityStatus status);

NS_ASSUME_NONNULL_END
#endif

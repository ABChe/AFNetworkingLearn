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

// WiFi 是否可达
@property (readonly, nonatomic, assign, getter = isReachableViaWiFi) BOOL reachableViaWiFi;


#pragma mark - Initialize

// 返回 AFNetworkReachabilityManager 单例对象
+ (instancetype)shareManager;

// 创建并返回具有默认socket地址的 AFNetworkReachabilityManager 对象, 主动监视默认的socket地址
+ (instancetype)manager;

// 创建并返回指定域的 AFNetworkReachabilityManager 对象, 主动监视默认的socket地址
+ (instancetype)managerForDomain:(NSString *)domain;

// 创建并返回指定socket地址的 AFNetworkReachabilityManager 对象, 主动监视默认的socket地址
+ (instancetype)managerForAddress:(const void *)address;

// 创建并返回一个用指定的 SCNetworkReachabilityRef 对象初始化的 AFNetworkReachabilityManager 对象, 主动监视指定的可达性
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

// 返回一个网络状态的本地语言字符串
- (NSString *)localozedNetworkReachabilityStatusString;


#pragma mark - Setting Network Reachability Change Callback

// 设置网络连接状态改变的回调
- (void)setReachabilityStatusChangeBlock:(nullable void (^)(AFNetworkReachabilityStatus status))block;

@end


#pragma mark - Notifications

/* FOUNDATION_EXPORT 定义的字符串可以使用'=='进行直接判断 比较的是__地址__
   define 比较的是每个字符 相对来说前者效率更高
 */
FOUNDATION_EXPORT NSString * const AFNetworkingReachabilityDidChangeNotification; // 网络状态发生改变
FOUNDATION_EXPORT NSString * const AFNetworkingReachabilityNotificationStatusItem; // 检测网络可达性


#pragma mark - Functions

// 定义一个C语言函数
FOUNDATION_EXPORT NSString * AFStringFromNetworkReachabilityStatus(AFNetworkReachabilityStatus status);

NS_ASSUME_NONNULL_END
#endif

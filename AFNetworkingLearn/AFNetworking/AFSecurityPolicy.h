//
//  AFSecurityPolicy.h
//  AFNetworkingLearn
//
//  Created by 车 on 2018/6/2.
//  Copyright © 2018年 车. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Security/Security.h>

typedef NS_ENUM(NSUInteger, AFSSLPinningMode) {
    AFSSLPinningModeNone,   // 无条件信任服务器证书
    AFSSLPinningModePublicKey,  // 对返回证书的公钥进行验证
    AFSSLPinningModeCertificate,    // 对服务器返回的证书同本地证书进行完全校验
};

NS_ASSUME_NONNULL_BEGIN

@interface AFSecurityPolicy : NSObject <NSSecureCoding, NSCopying>

// SSL Pinning类型, 默认AFSSLPinningModeNone
@property (readonly, nonatomic, assign) AFSSLPinningMode SSLPinningMode;

/*
    根据 SSLPinningMode 来校验服务器返回证书的证书
    通常都保存在mainBundle下.通常默认情况下,AFNetworking会自动寻找在mainBundle的根目录下所有的.cer文件并保存在pinnedCertificates数组里,以校验服务器返回的证书
    注意:如果集合中任一证书通过验证 evaluateServerTrust:forDomain: 就会返回ture, 即通过验证
 */
@property (nonatomic, strong, nullable) NSSet <NSData *> *pinnedCertificates;

// 是否信任无效或过期的证书,默认是不信任
@property (nonatomic, assign) BOOL allowInvalidCertificates;

// 是否验证证书中的域名,默认验证
@property (nonatomic, assign) BOOL validatesDomainName;


#pragma mark - Getting Certificates from Bundle

// 返回指定bundle中的证书,如果使用AFNetworking的证书验证,就必须实现此这个方法,并且使用 policyWithPinningMode:withPinnedCertificates 方法创建实例对象
+ (NSSet <NSData *> *)certificatesInBundle:(NSBundle *)bundle;

/*
    创建并返回默认的实例对象
    默认设置: 1.不允许无效或过期的证书 2.验证域名名称 3.不对固定证书和公钥进行验证
 */
+ (instancetype)defaultPolicy;


#pragma mark - Initialization

// 创建并返回一个指定安全模式的实例对象
+ (instancetype)policyWithPinningModel:(AFSSLPinningMode)pingModel;

// 创建并返回一个指定安全模式并绑定证书的实例对象
+ (instancetype)policyWithPinningModel:(AFSSLPinningMode)pingModel withPinnedCertificates:(NSSet <NSData *> *)pinnedCertificates;


#pragma mark - Evaluating Server Trust

// 根据 serverTrust 和 domain 来检验服务器发来的证书是否可信
- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust
                  forDomain:(nullable NSString *)domain;

@end

NS_ASSUME_NONNULL_END

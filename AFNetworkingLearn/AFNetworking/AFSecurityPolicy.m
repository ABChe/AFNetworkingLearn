//
//  AFSecurityPolicy.m
//  AFNetworkingLearn
//
//  Created by 车 on 2018/6/2.
//  Copyright © 2018年 车. All rights reserved.
//

#import "AFSecurityPolicy.h"

#import <AssertMacros.h>

#if !TARGET_OS_IOS && !TARGET_OS_WATCH && !TARGET_OS_TV
static NSData * AFSecKeyGetData(SecKeyRef key) {
    CFDataRef data = NULL;
    
    __Require_noErr_Quiet(SecItemExport(key, kSecFormatUnknown, kSecItemPemArmour, NULL, &data), _out);
    
    return (__bridge_transfer NSData *)data;
    
_out:
    if (data) {
        CFRelease(data);
    }
    
    return nil;
}
#endif

static BOOL AFSecKeyIsEqualToKey(SecKeyRef key1, SecKeyRef key2) {
#if TARGET_OS_IOS || TARGET_OS_WATCH || TARGET_OS_TV
    return [(__bridge id)key1 isEqual:(__bridge id)key2];
#else
    return [AFSecKeyGetData(key1) isEqual:AFSecKeyGetData(key2)];
#endif
}


// 从证书中获取公钥
static id AFPublicKeyForCertificate(NSData *certificate) {
    id allowedPublicKey = nil;
    SecCertificateRef allowedCertificate;
    SecPolicyRef policy = nil;
    SecTrustRef allowedTrust = nil;
    SecTrustResultType result;
    
    // 1. 根据二进制的 certificate 生成 SecCertificateRef 类型的证书
    allowedCertificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)certificate);
    // 2. 如果 allowedCertificate 为空, 直接执行 _out 标记后的语句
    __Require_Quiet(allowedCertificate != NULL, _out);
    
    // 3. 新建policy为X.509
    policy = SecPolicyCreateBasicX509();
    // 4. 如果 函数SecTrustCreateWithCertificates 返回异常, 直接执行 _out 标记后的语句
    __Require_noErr_Quiet(SecTrustCreateWithCertificates(allowedCertificate, policy, &allowedTrust), _out);
    // 5. 如果 函数SecTrustEvaluate 返回异常, 直接执行 _out 标记后的语句
    __Require_noErr_Quiet(SecTrustEvaluate(allowedTrust, &result), _out);
    
    // 6. 在 SecTrustRef 对象中取出公钥
    // __bridge_transfer 被转换的变量所持有的对象在该变量被赋值给转换目标变量后随之释放
    allowedPublicKey = (__bridge_transfer id)SecTrustCopyPublicKey(allowedTrust);
    
_out:
    if (allowedTrust) {
        CFRelease(allowedTrust);
    }
    
    if (policy) {
        CFRelease(policy);
    }
    
    if (allowedCertificate) {
        CFRelease(allowedCertificate);
    }
    
    return allowedPublicKey;
}

// 验证服务器是否被信任
static BOOL AFServerTrustIsValid(SecTrustRef serverTrust) {
    BOOL isValid = NO;
    SecTrustResultType result;
    // 将函数 SecTrustEvaluate 的结果赋值给result
    __Require_noErr_Quiet(SecTrustEvaluate(serverTrust, &result), _out);
    
    // kSecTrustResultUnspecified:证书通过验证,但用户没有设置这些证书是否被信任
    // kSecTrustResultProceed:证书通过验证,用户有操作设置了证书被信任,例如在弹出的是否信任的alert框中选择always trust
    isValid = (result == kSecTrustResultUnspecified || result == kSecTrustResultProceed);

_out:
    return isValid;
}

// 获取 serverTrust中证书链上的所有证书
static NSArray * AFCertificatetrustChainForServerTrust(SecTrustRef serverTrust) {
    CFIndex certificateCount = SecTrustGetCertificateCount(serverTrust);
    // arrayWithCapacity 会创建了一个autorelease对象
    // 即:当数组使用完毕后即可销毁,就相当于将这个数组放在了一个新的 @autoreleasepool{} 中
    NSMutableArray *trustChain = [NSMutableArray arrayWithCapacity:(NSUInteger)certificateCount];
    
    for (CFIndex i = 0; i < certificateCount; i++) {
        SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, i);
        [trustChain addObject:(__bridge_transfer NSData *)SecCertificateCopyData(certificate)];
    }
    return [NSArray arrayWithArray:trustChain];
}

// 取出serverTrust中证书链上每个证书的公钥,并返回对应的该组公钥
static NSArray * AFPublicKeyTrustChainForServerTrust(SecTrustRef serverTrust) {
    SecPolicyRef policy = SecPolicyCreateBasicX509();
    CFIndex certificateCount = SecTrustGetCertificateCount(serverTrust);
    NSMutableArray *trustChain = [NSMutableArray arrayWithCapacity:(NSUInteger)certificateCount];
    for (CFIndex i = 0; i < certificateCount; i++) {
        SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, i);
        
        SecCertificateRef someCertificates[] = {certificate};
        CFArrayRef certificates = CFArrayCreate(NULL, (const void **)someCertificates, 1, NULL);
        
        SecTrustRef trust;
        __Require_noErr_Quiet(SecTrustCreateWithCertificates(certificates, policy, &trust), _out);
        
        SecTrustResultType result;
        __Require_noErr_Quiet(SecTrustEvaluate(trust, &result), _out);
        
        
        [trustChain addObject:(__bridge_transfer NSData *)SecTrustCopyPublicKey(trust)];
         
     _out:
        if (trust) {
            CFRelease(trust);
        }
        
        if (certificates) {
            CFRelease(certificates);
        }
        
        continue;
    }
    CFRelease(policy);
    
    return [NSArray arrayWithArray:trustChain];
}


#pragma mark -

@interface AFSecurityPolicy()
@property (readwrite, nonatomic, assign) AFSSLPinningMode SSLPinningMode;
@property (readwrite, nonatomic, strong) NSSet *pinnedPublicKeys;
@end

@implementation AFSecurityPolicy

+ (NSSet *)certificatesInBundle:(NSBundle *)bundle {
    NSArray *paths = [bundle pathsForResourcesOfType:@"cer" inDirectory:@"."];
    
    NSMutableSet *certificates = [NSMutableSet setWithCapacity:[paths count]];
    for (NSString *path in paths) {
        NSData *certificateData = [NSData dataWithContentsOfFile:path];
        [certificates addObject:certificateData];
    }
    
    return [NSSet setWithSet:certificates];
}

+ (NSSet *)defaultPinnerCertificates {
    static NSSet *_defaultPinnerCertificates = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 获取当前类的bundle
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        _defaultPinnerCertificates = [self certificatesInBundle:bundle];
    });
    
    return _defaultPinnerCertificates;
}

+ (instancetype)defaultPolicy {
    AFSecurityPolicy *securityPolicy = [[self alloc] init];
    securityPolicy.SSLPinningMode = AFSSLPinningModeNone;
    
    return securityPolicy;
}

+ (instancetype)policyWithPinningModel:(AFSSLPinningMode)pingModel {
    return [self policyWithPinningModel:pingModel withPinnedCertificates:[self defaultPinnerCertificates]];
}

+ (instancetype)policyWithPinningModel:(AFSSLPinningMode)pingModel withPinnedCertificates:(NSSet<NSData *> *)pinnedCertificates {
    AFSecurityPolicy *securityPolicy = [[self alloc] init];
    securityPolicy.SSLPinningMode = AFSSLPinningModeNone;
    
    [securityPolicy setPinnedCertificates:pinnedCertificates];
    
    return securityPolicy;
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.validatesDomainName = YES;
    
    return self;
}

- (void)setPinnedCertificates:(NSSet<NSData *> *)pinnedCertificates {
    _pinnedCertificates = pinnedCertificates;
    
    if (self.pinnedCertificates) {
        NSMutableSet *mutablePinnedPublicKeys = [NSMutableSet setWithCapacity:[self.pinnedCertificates count]];
        for (NSData *certifiacate in self.pinnedCertificates) {
            id publickey = AFPublicKeyForCertificate(certifiacate);
            if (!publickey) {
                continue;
            }
            [mutablePinnedPublicKeys addObject:publickey];
        }
        self.pinnedPublicKeys = [NSSet setWithSet:mutablePinnedPublicKeys];
    } else {
        self.pinnedPublicKeys = nil;
    }
}

#pragma mark -

- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust
                  forDomain:(NSString *)domain
{
    // 当使用自建证书验证域名时,需要使用AFSSLPinningModePublicKey或者AFSSLPinningModeCertificate进行验证
    if (domain && self.allowInvalidCertificates && self.validatesDomainName && (self.SSLPinningMode == AFSSLPinningModeNone || [self.pinnedCertificates count] == 0)) {
        NSLog(@"In order to validate a domain name for self signed certificates, you MUST use pinning.");
        return NO;
    }
    
    NSMutableArray *policies = [NSMutableArray array];
    // 需要验证域名时,需要添加一个验证域名的策略
    if (self.validatesDomainName) {
        [policies addObject:(__bridge_transfer id)SecPolicyCreateSSL(true, (__bridge CFStringRef)domain)];
    } else {
        [policies addObject:(__bridge_transfer id)SecPolicyCreateBasicX509()];
    }
    
    // 设置验证域名策略
    SecTrustSetPolicies(serverTrust, (__bridge CFArrayRef)policies);
    
    if (self.SSLPinningMode == AFSSLPinningModeNone) {
        // allowInvalidCertificates 为 YES 时, 代表服务器的所有证书都能通过验证
        // allowInvalidCertificates 为 NO 时, 需要判断此服务器证书是否是系统信任的证书
        return self.allowInvalidCertificates || AFServerTrustIsValid(serverTrust);
    } else if (!AFServerTrustIsValid(serverTrust) && !self.allowInvalidCertificates) {
        //  如果服务器证书不是系统信任证书,且不允许不信任的证书 通过验证则返回 NO
        return NO;
    }
    
    switch (self.SSLPinningMode) {
        case AFSSLPinningModeNone:
        default:
            return NO;
        case AFSSLPinningModeCertificate: {
            // AFSSLPinningModeCertificate 是直接将本地的证书设置为信任的根证书,然后来进行判断,并且比较本地证书的内容和服务器证书内容是否相同,如果有一个相同则返回 YES
            NSMutableArray *pinnedCertificates = [NSMutableArray array];
            for (NSData *certificateData in self.pinnedCertificates) {
                [pinnedCertificates addObject:(__bridge id)SecCertificateCreateWithData(NULL, (__bridge CFDataRef)certificateData)];
            }
            // 设置本地证书为根证书,即服务器应当信任的证书
            SecTrustSetAnchorCertificates(serverTrust, (__bridge CFArrayRef)pinnedCertificates);
            
            // 检验能否信任
            if (!AFServerTrustIsValid(serverTrust)) {
                return NO;
            }
            
            NSArray *serverCertificates = AFCertificatetrustChainForServerTrust(serverTrust);
            
            // 判断本地证书和服务器证书是否相同
            for (NSData *trustChainCertificate in [serverCertificates reverseObjectEnumerator]) {
                if ([self.pinnedCertificates containsObject:trustChainCertificate]) {
                    return YES;
                }
            }
            
            return NO;
        }
        case AFSSLPinningModePublicKey: {
            NSUInteger trustPublicKeyCount = 0;
            NSArray *publicKeys = AFPublicKeyTrustChainForServerTrust(serverTrust);
            
            // AFSSLPinningModePublicKey 是通过比较证书当中公钥(PublicKey)部分来进行验证,通过SecTrustCopyPublicKey方法获取本地证书和服务器证书,然后进行比较,如果有一个相同,则通过验证
            for (id trustChainPublickKey in publicKeys) {
                for (id pinnedPublicKey in self.pinnedPublicKeys) {
                    if (AFSecKeyIsEqualToKey((__bridge SecKeyRef)trustChainPublickKey, (__bridge SecKeyRef)pinnedPublicKey)) {
                        trustPublicKeyCount += 1;
                    }
                }
            }
            return trustPublicKeyCount > 0;
        }
    }
    return NO;
}

#pragma mark - NSKeyValueObserving

+ (NSSet *)keyPathsForValuesAffectingPinnedPublicKeys {
    return [NSSet setWithObject:@"pinnedCertificates"];
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.SSLPinningMode = [[decoder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(SSLPinningMode))] unsignedIntegerValue];
    self.allowInvalidCertificates = [decoder decodeBoolForKey:NSStringFromSelector(@selector(allowInvalidCertificates))];
    self.validatesDomainName = [decoder decodeBoolForKey:NSStringFromSelector(@selector(validatesDomainName))];
    self.pinnedCertificates = [decoder decodeObjectOfClass:[NSArray class] forKey:NSStringFromSelector(@selector(pinnedCertificates))];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:[NSNumber numberWithUnsignedInteger:self.SSLPinningMode] forKey:NSStringFromSelector(@selector(SSLPinningMode))];
    [coder encodeBool:self.allowInvalidCertificates forKey:NSStringFromSelector(@selector(allowInvalidCertificates))];
    [coder encodeBool:self.validatesDomainName forKey:NSStringFromSelector(@selector(validatesDomainName))];
    [coder encodeObject:self.pinnedCertificates forKey:NSStringFromSelector(@selector(pinnedCertificates))];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    AFSecurityPolicy *securityPolicy = [[[self class] allocWithZone:zone] init];
    securityPolicy.SSLPinningMode = self.SSLPinningMode;
    securityPolicy.allowInvalidCertificates = self.allowInvalidCertificates;
    securityPolicy.validatesDomainName = self.validatesDomainName;
    securityPolicy.pinnedCertificates = [self.pinnedCertificates copyWithZone:zone];
    
    return securityPolicy;
}

@end

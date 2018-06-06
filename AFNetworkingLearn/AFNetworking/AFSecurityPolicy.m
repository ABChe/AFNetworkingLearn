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

@end

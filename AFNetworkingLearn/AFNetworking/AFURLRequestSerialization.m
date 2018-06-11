//
//  AFURLRequestSerialization.m
//  AFNetworkingLearn
//
//  Created by 车 on 2018/6/7.
//  Copyright © 2018年 车. All rights reserved.
//

#import "AFURLRequestSerialization.h"

NSString *AFPercentEscapedStringFromString(NSString *string) {
    static NSString * const kAFCharactersGeneralDelimitersToEncode = @":#[]@";
    static NSString * const kAFCharactersSubDelimitersToEncode = @"!$&'()*+,;=";

    NSMutableCharacterSet * allowedCharacterSet = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [allowedCharacterSet removeCharactersInString:[kAFCharactersGeneralDelimitersToEncode stringByAppendingString:kAFCharactersSubDelimitersToEncode]];

    // 50应该是一个'经验数'
    static NSUInteger const batchSize = 50;
    
    NSUInteger index = 0;
    NSMutableString *escaped = @"".mutableCopy;
    
    while (index < string.length) {
        NSUInteger length = MIN(string.length - index, batchSize);
        NSRange range = NSMakeRange(index, length);
        
        range = [string rangeOfComposedCharacterSequencesForRange:range];
        
        NSString *substring = [string substringWithRange:range];
        NSString *encoded = [substring stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];
        [escaped appendString:encoded];
        
        index += range.length;
    }
    
    return escaped;
}

#pragma mark -

// AFQueryStringFromParameters 函数使用  字典转URL编码
@interface AFQueryStringPair : NSObject
@property (readwrite, nonatomic, strong) id field;
@property (readwrite, nonatomic, strong) id value;

- (instancetype)initWithField:(id)field value:(id)value;

- (NSString *)URLEncodeStringValue;
@end

@implementation AFQueryStringPair

- (instancetype)initWithField:(id)field value:(id)value {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.field = field;
    self.value = value;
    
    return self;
}

- (NSString *)URLEncodeStringValue {
    if (!self.value || [self.value isEqual:[NSNull null]]) {
        return AFPercentEscapedStringFromString([self.field description]);
    } else {
        return [NSString stringWithFormat:@"%@=%@",AFPercentEscapedStringFromString([self.field description]), AFPercentEscapedStringFromString([self.value description])];
    }
}

@end

#pragma mark -

FOUNDATION_EXPORT NSArray * AFQueryStringPairsFromDictionary(NSDictionary *dictionary);
FOUNDATION_EXPORT NSArray * AFQueryStringPairsFromKeyAndValue(NSString *key, id value);

NSString * AFQueryStringFromParameters(NSDictionary *parameters) {
    NSMutableArray *mutablePairs = [NSMutableArray array];
    for (AFQueryStringPair *pair in AFQueryStringPairsFromDictionary(parameters)) {
        [mutablePairs addObject:[pair URLEncodeStringValue]];
    }
    
    return [mutablePairs componentsJoinedByString:@"&"];
}

NSArray *AFQueryStringPairsFromDictionary(NSDictionary *dictionary) {
    return AFQueryStringPairsFromKeyAndValue(nil, dictionary);
}

NSArray * AFQueryStringPairsFromKeyAndValue(NSString *key, id value) {
    /*
     转换效果：
     @{
     @"name" : @"bang",
     @"phone": @{@"mobile": @"xx", @"home": @"xx"},
     @"families": @[@"father", @"mother"],
     @"nums": [NSSet setWithObjects:@"1", @"2", nil]
     }
     ->
     @[
     field: @"name", value: @"bang",
     field: @"phone[mobile]", value: @"xx",
     field: @"phone[home]", value: @"xx",
     field: @"families[]", value: @"father",
     field: @"families[]", value: @"mother",
     field: @"nums", value: @"1",
     field: @"nums", value: @"2",
     ]
     */
    NSMutableArray *mutableQueryStringComponents = [NSMutableArray array];
    
    // 排序: 升序
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES selector:@selector(compare:)];
    
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = value;
        
        for (id nestedKey in [dictionary.allKeys sortedArrayUsingDescriptors:@[ sortDescriptor]]) {
            id nestedValue = dictionary[nestedKey];
            if (nestedValue) {
                [mutableQueryStringComponents addObjectsFromArray:AFQueryStringPairsFromKeyAndValue(key ? [NSString stringWithFormat:@"%@[%@]", key, nestedKey] : nestedKey, nestedValue)];
            }
        }
    } else if ([value isKindOfClass:[NSArray class]]) {
        NSArray *array = value;
        for (id nestedValue in array) {
            [mutableQueryStringComponents addObjectsFromArray:AFQueryStringPairsFromKeyAndValue([NSString stringWithFormat:@"%@[]", key], nestedValue)];
        }
    } else if ([value isKindOfClass:[NSSet class]]) {
        NSSet *set = value;
        for (id obj in [set sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            [mutableQueryStringComponents addObjectsFromArray:AFQueryStringPairsFromKeyAndValue(key, obj)];
        }
    } else {
        [mutableQueryStringComponents addObject:[[AFQueryStringPair alloc] initWithField:key value:value]];
    }
    
    return mutableQueryStringComponents;
}

#pragma mark -

static NSString * AFCreateMultipartFormBoundary() {
    return [NSString stringWithFormat:@"Boundary+%08X%08X", arc4random(), arc4random()];
}

static NSString * const kAFMultipartFormCRLF = @"\r\n";

static inline NSString * AFMultipartFormInitialBoundary(NSString *boundary) {
    return [NSString stringWithFormat:@"--%@%@", boundary, kAFMultipartFormCRLF];
}

static inline NSString * AFMultipartFormEncapsulationBoundary(NSString *boundary) {
    return [NSString stringWithFormat:@"%@--%@%@", kAFMultipartFormCRLF, boundary, kAFMultipartFormCRLF];
}

static inline NSString * AFMultipartFormFinalBoundary(NSString *boundary) {
    return [NSString stringWithFormat:@"%@--%@--%@", kAFMultipartFormCRLF, boundary, kAFMultipartFormCRLF];
}

static inline NSString * AFContentTypeForPathExtension(NSString *extension) {
    NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL);
    NSString *contentType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
    if (!contentType) {
        return @"application/octet-stream";
    } else {
        return contentType;
    }
}

NSUInteger const kAFUploadStream3GSuggestedPacketSize = 1024 * 16;
NSTimeInterval const kAFUploadStream3GSuggestedDelay = 0.2;

@interface AFHTTPBodyPart : NSObject
// 编码方式
@property (nonatomic, assign) NSStringEncoding stringEncoding;
// 头
@property (nonatomic, strong) NSDictionary *headers;
// 边界
@property (nonatomic, copy) NSString *boundary;
// 主体内容
@property (nonatomic, strong) id body;
// 主体大小
@property (nonatomic, assign) unsigned long long bodyContentLength;
// 流
@property (nonatomic, strong) NSInputStream *inputStream;

// 是够有初始边界
@property (nonatomic, assign) BOOL hasInitialBoundary;
// 是否有结束边界
@property (nonatomic, assign) BOOL hasFinalBoundary;

// body 是否有可用字节
@property (readonly, nonatomic, assign, getter=hasBytesAvailable) BOOL bytesAvailable;
// 长度
@property (readonly, nonatomic, assign) unsigned long long contentLength;

// 读取数据
- (NSInteger)read:(uint8_t)buffer
        maxLength:(NSUInteger)length;
@end



@implementation AFURLRequestSerialization


@end

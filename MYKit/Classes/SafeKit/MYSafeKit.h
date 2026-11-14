//
//  MYSafeKit.h
//  MYKitDemo
//
//  Created by QMMac on 2018/6/26.
//  Copyright © 2018 com.51fanxing. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, MYSafeKitShieldType) {
    MYSafeKitShieldTypeUnrecognizedSelector = 1 << 1,
    MYSafeKitShieldTypeContainer = 1 << 2,
    MYSafeKitShieldTypeKVO = 1 << 3,
    MYSafeKitShieldTypeNotification = 1 << 4,
    MYSafeKitShieldTypeTimer = 1 << 5,
    MYSafeKitShieldTypeNull = 1 << 6,
    MYSafeKitShieldTypeAll = (MYSafeKitShieldTypeUnrecognizedSelector | MYSafeKitShieldTypeContainer | MYSafeKitShieldTypeKVO | MYSafeKitShieldTypeNotification | MYSafeKitShieldTypeTimer | MYSafeKitShieldTypeNull),
};

@protocol MYSafeKitRecordProtocol <NSObject>

- (void)recordWithReason:(NSError *)reason;

@end

@interface MYSafeKit : NSObject

/**
 注册汇报中心
 
 @param record 汇报中心
 */
+ (void)registerRecordHandler:(nullable id<MYSafeKitRecordProtocol>)record;

/**
 注册 SDK，默认只要开启就打开防 Crash
 */
+ (void)registerSafeKitShield;

/**
 注册 SDK，根据不同 ability 开启防 Crash
 支持单项、组合及 MYSafeKitShieldTypeAll；注册不可撤销。
 @param ability ability
 */
+ (void)registerSafeKitShieldWithAbility:(MYSafeKitShieldType)ability;

/** Register an exact-class fallback signature; enable UnrecognizedSelector separately.
 The caller guarantees the complete encoding matches a non-variadic call. Unsupported
 or conflicting encodings return NO. For class methods pass the metaclass.
 Existing custom forwarding and its exceptions retain precedence. */
+ (BOOL)registerFallbackForClass:(Class)cls selector:(SEL)selector typeEncoding:(const char *)encoding;

@end

NS_ASSUME_NONNULL_END

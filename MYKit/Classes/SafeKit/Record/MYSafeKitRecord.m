#import "MYSafeKitRecord.h"
#include <stdio.h>

@implementation MYSafeKitRecord
static id<MYSafeKitRecordProtocol> recordHandler;
static _Thread_local BOOL recording;
+ (void)registerRecordHandler:(id<MYSafeKitRecordProtocol>)record {
    @synchronized (self) { recordHandler = record; }
}
+ (void)recordFatalWithReason:(NSString *)reason errorType:(MYSafeKitShieldType)type {
    if (recording) return;
    recording = YES;
    @try {
        id<MYSafeKitRecordProtocol> handler;
        @synchronized (self) { handler = recordHandler; }
        if (!handler) return;
        NSArray *stack = [NSThread callStackSymbols];
        if (stack.count > 32) stack = [stack subarrayWithRange:NSMakeRange(0, 32)];
        NSError *error = [NSError errorWithDomain:[NSString stringWithFormat:@"com.xxshield.%@", NSBundle.mainBundle.bundleIdentifier] code:-(NSInteger)type userInfo:@{NSLocalizedDescriptionKey:reason.length ? reason : @"Unknown protection failure", @"callStack":stack ?: @[]}];
        [handler recordWithReason:error];
    } @catch (__unused NSException *exception) {
        fputs("MYKit: record handler raised an exception\n", stderr);
    } @finally { recording = NO; }
}
+ (NSString *)getErrorMessageWithTipString:(NSString *)tip {
    NSArray *stack = [NSThread callStackSymbols];
    if (stack.count > 32) stack = [stack subarrayWithRange:NSMakeRange(0, 32)];
    return [NSString stringWithFormat:@"%@\n%@", tip ?: @"", [stack componentsJoinedByString:@"\n"]];
}
+ (void)safeKit_showAlterWithMessage:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [[[UIAlertView alloc] initWithTitle:@"MYKit" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
#pragma clang diagnostic pop
    });
}
@end

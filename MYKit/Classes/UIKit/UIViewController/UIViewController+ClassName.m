//
//  UIViewController+ClassName.m
//  MYKitDemo
//
//  Created by sunjinshuai on 2018/3/23.
//  Copyright © 2018年 com.51fanxing. All rights reserved.
//

#import "UIViewController+ClassName.h"
#import "UIDevice+Addition.h"
#import "UIView+Position.h"
#import "NSObject+Swizzle.h"
#import "MYWindowContextInternal.h"
#import <objc/runtime.h>

#define kClassNameTag 20000

static BOOL displayClassName = NO;
static char MYClassNameLabelKey;

// A scene may disconnect before debugging is disabled. Track owners weakly so
// cleanup reaches every label without retaining its window.
static NSHashTable<UIWindow *> *MYClassNameWindows(void) {
    static NSHashTable<UIWindow *> *windows;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ windows = [NSHashTable weakObjectsHashTable]; });
    return windows;
}

@implementation UIViewController (ClassName)

+ (void)displayClassName:(BOOL)yesOrNo {
    displayClassName = yesOrNo;
    if (displayClassName) {
        [self displayClassName];
    } else {
        [self removeClassName];
    }
}

+ (void)load {
    
    [self instanceSwizzleMethod:@selector(yn_viewDidAppear:) replaceMethod:@selector(viewDidAppear:)];
}

#pragma mark - Method Swizzling

- (void)yn_viewDidAppear:(BOOL)animated {
    [self yn_viewDidAppear:animated];
    
    if (displayClassName) {
        [[self class] displayClassNameInWindow:self.view.window];
    }
}

+ (void)displayClassName {
    [self displayClassNameInWindow:MYCurrentApplicationWindow()];
}

+ (void)displayClassNameInWindow:(UIWindow *)window {
    if (!window) return;
    UILabel *classNameLabel = objc_getAssociatedObject(window, &MYClassNameLabelKey);
    if (!classNameLabel) {
        classNameLabel = [[UILabel alloc] init];
        classNameLabel.frame = CGRectMake(5, 15, window.width, 20);
        classNameLabel.textColor = [UIColor redColor];
        classNameLabel.font = [UIFont systemFontOfSize:12];
        classNameLabel.tag = kClassNameTag;
        objc_setAssociatedObject(window, &MYClassNameLabelKey, classNameLabel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [window addSubview:classNameLabel];
        [MYClassNameWindows() addObject:window];
    }
    [window bringSubviewToFront:classNameLabel];
    classNameLabel.userInteractionEnabled = NO;
    
    const char *className = class_getName(self.class);
    NSString *classNameStr = [NSString stringWithCString:className encoding:NSUTF8StringEncoding];
    
    if ([self needDisplay:classNameStr]) {
        [classNameLabel setText:classNameStr];
    }
}

+ (void)removeClassName {
    NSArray<UIWindow *> *windows = MYClassNameWindows().allObjects;
    for (UIWindow *window in windows) {
        UILabel *label = objc_getAssociatedObject(window, &MYClassNameLabelKey);
        [label removeFromSuperview];
        objc_setAssociatedObject(window, &MYClassNameLabelKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [MYClassNameWindows() removeAllObjects];
}

+ (BOOL)needDisplay:(NSString *)className {
    if ([className isEqualToString:@"UIInputWindowController"] || [className isEqualToString:@"UINavigationController"] || [className isEqualToString:@"UIApplicationRotationFollowingControllerNoTouches"]) {
        return NO;
    } else if ([NSClassFromString(className) isSubclassOfClass:[UIInputViewController class]]) {    // 输入类controller
        return NO;
    } else {
        return YES;
    }
}

@end

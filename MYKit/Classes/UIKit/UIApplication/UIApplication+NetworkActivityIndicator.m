//
//  UIApplication+NetworkActivityIndicator.m
//  MYKitDemo
//
//  Created by sunjinshuai on 2017/9/7.
//  Copyright © 2017年 com.51fanxing. All rights reserved.
//

#import "UIApplication+NetworkActivityIndicator.h"
#import <stdatomic.h>

@implementation UIApplication (NetworkActivityIndicator)

static _Atomic(int32_t) numberOfActiveNetworkConnections;

#pragma mark Public API

- (void)beganNetworkActivity
{
    // Serialize the property update with the count, so an older write cannot win.
    @synchronized (UIApplication.class) {
        atomic_fetch_add_explicit(&numberOfActiveNetworkConnections, 1, memory_order_relaxed);
        self.networkActivityIndicatorVisible = atomic_load_explicit(&numberOfActiveNetworkConnections, memory_order_relaxed) > 0;
    }
}

- (void)endedNetworkActivity
{
    @synchronized (UIApplication.class) {
        atomic_fetch_sub_explicit(&numberOfActiveNetworkConnections, 1, memory_order_relaxed);
        self.networkActivityIndicatorVisible = atomic_load_explicit(&numberOfActiveNetworkConnections, memory_order_relaxed) > 0;
    }
}

@end

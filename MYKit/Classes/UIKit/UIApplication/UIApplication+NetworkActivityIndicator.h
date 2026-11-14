//
//  UIApplication+NetworkActivityIndicator.h
//  MYKitDemo
//
//  Created by sunjinshuai on 2017/9/7.
//  Copyright © 2017年 com.51fanxing. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIApplication (NetworkActivityIndicator)

/**
 Legacy network-activity state bookkeeping. iOS 13 and later do not display the
 old status-bar indicator. These methods retain the observable property updates
 for callers that still read networkActivityIndicatorVisible; use app-owned UI
 for visible progress. Balance every begin with an end.
 */
- (void)beganNetworkActivity;
- (void)endedNetworkActivity;

@end

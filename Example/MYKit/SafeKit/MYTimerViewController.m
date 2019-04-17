//
//  MYTimerViewController.m
//  MYKitDemo
//
//  Created by QMMac on 2018/7/30.
//  Copyright © 2018 com.51fanxing. All rights reserved.
//

#import "MYTimerViewController.h"
#import "NSTimer+Safe.h"

@interface MYTimerViewController ()

@property (nonatomic, strong) NSTimer *timer;

@end

@implementation MYTimerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"";
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(timerEvent) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)timerEvent {
    NSLog(@"timer");
}

- (void)dealloc {
    
    NSLog(@"%@ %s 销毁",[self class] ,__func__);
}

@end

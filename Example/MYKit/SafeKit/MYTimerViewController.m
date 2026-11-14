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
@property (nonatomic) NSUInteger tickCount;
@property (nonatomic, strong) UILabel *statusLabel;

@end

@implementation MYTimerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(24, 120, 320, 80)];
    self.statusLabel.numberOfLines = 0;
    self.statusLabel.accessibilityIdentifier = @"timer.status";
    self.statusLabel.text = @"定时器运行中；退出页面后目标可释放。";
    [self.view addSubview:self.statusLabel];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(timerEvent:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)timerEvent:(NSTimer *)timer {
    self.tickCount += 1;
    self.statusLabel.text = [NSString stringWithFormat:@"已触发 %lu 次；退出页面后目标可释放。", (unsigned long)self.tickCount];
}

- (void)dealloc {
    
    NSLog(@"%@ %s 销毁",[self class] ,__func__);
}

@end

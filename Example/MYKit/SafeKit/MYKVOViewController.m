//
//  MYKVOViewController.m
//  MYKitDemo
//
//  Created by QMMac on 2018/7/30.
//  Copyright © 2018 com.51fanxing. All rights reserved.
//

#import "MYKVOViewController.h"
#import "NSObject+SafeKVO.h"

@interface MYKVOViewController ()

@end

@implementation MYKVOViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  
    [self testKVO2];
}

- (void)testKVO1 {
//    [self addObserver:[Person new ] forKeyPath:@"view" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    
    self.view = [UIView new]; // Crash
    // 被观察者是局部变量  触发KVOCrash
}

- (void)testKVO2 {
    [self addObserver:self forKeyPath:@"view" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];

    [self addObserver:self forKeyPath:@"frame" options:kNilOptions context:NULL];
//    [self addObserver:self forKeyPath:@"frame" options:kNilOptions context:NULL];
    [self addObserver:self forKeyPath:@"center" options:kNilOptions context:NULL];
    [self addObserver:self forKeyPath:@"bounds" options:kNilOptions context:NULL];
    [self addObserver:self forKeyPath:@"transform" options:kNilOptions context:NULL];

    self.view = [UIView new];
    // 会触发多次响应事件

    // for test 多余的移除会导致Crash  because it is not registered as an observer.'
//    [self removeObserver:self forKeyPath:@"view"];
//    [self removeObserver:self forKeyPath:@"view"];
}

- (void)dealloc {
    NSLog(@"%@ --> %s", [self class], __func__);
    
    [self removeObserver:self forKeyPath:@"view"];
    [self removeObserver:self forKeyPath:@"view"];
}

@end

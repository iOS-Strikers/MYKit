//
//  MYUncaughtExceptionViewController.m
//  MYKitDemo
//
//  Created by michael on 2019/2/22.
//  Copyright © 2019 com.51fanxing. All rights reserved.
//

#import "MYUncaughtExceptionViewController.h"

typedef struct Test {
    int a;
    int b;
};

@interface MYUncaughtExceptionViewController ()

@end

@implementation MYUncaughtExceptionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - 100)/2, 100, 100, 50);
    [button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [button setTitle:@"SignalException" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(buttonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)buttonClick {
    struct Test *pTest = {1,2};
    free(pTest);
    pTest->a = 5;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

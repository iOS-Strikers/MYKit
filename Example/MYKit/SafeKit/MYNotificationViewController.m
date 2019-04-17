//
//  MYNotificationViewController.m
//  MYKitDemo
//
//  Created by QMMac on 2018/8/3.
//  Copyright © 2018 com.51fanxing. All rights reserved.
//

#import "MYNotificationViewController.h"

@interface MYNotificationViewController ()

@end

@implementation MYNotificationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(testNotification) name:@"TestNotification" object:nil];
}

- (void)testNotification {
    
    
}

@end

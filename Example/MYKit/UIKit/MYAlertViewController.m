//
//  MYAlertViewController.m
//  MYKitDemo
//
//  Created by QMMac on 2018/7/17.
//  Copyright © 2018 com.51fanxing. All rights reserved.
//

#import "MYAlertViewController.h"
#import "MYKitMacroHeader.h"
#import "UIAlertController+Blocks.h"
#import "UINavigationController+BackButtonHandler.h"

@interface MYAlertViewController ()

@property (nonatomic, strong) UIAlertControllerCompletionBlock tapBlock;

@end

@implementation MYAlertViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.tapBlock = ^(UIAlertController *controller, UIAlertAction *action, NSInteger buttonIndex){
        if (buttonIndex == controller.destructiveButtonIndex) {
            NSLog(@"Delete");
        } else if (buttonIndex == controller.cancelButtonIndex) {
            NSLog(@"Cancel");
        } else if (buttonIndex >= controller.firstOtherButtonIndex) {
            NSLog(@"Other %ld", (long)buttonIndex - controller.firstOtherButtonIndex + 1);
        }
    };
    
    UIButton *alertButton = [UIButton buttonWithType:UIButtonTypeCustom];
    alertButton.frame = CGRectMake((MYScreenWidth - 100)/2, 150, 100, 50);
    [alertButton setTitle:@"showAlert" forState:UIControlStateNormal];
    [alertButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [alertButton addTarget:self action:@selector(showAlert:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:alertButton];
    
    UIButton *actionSheetButton = [UIButton buttonWithType:UIButtonTypeCustom];
    actionSheetButton.frame = CGRectMake((MYScreenWidth - 100)/2, CGRectGetMaxY(alertButton.frame) + 50, 100, 50);
    [actionSheetButton setTitle:@"showActionSheet" forState:UIControlStateNormal];
    [actionSheetButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [actionSheetButton addTarget:self action:@selector(showActionSheet:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:actionSheetButton];
}

- (BOOL)navigationShouldPopOnBackButton {
    return NO;
}

- (IBAction)showAlert:(id)sender {
    [UIAlertController showAlertInViewController:self
                                       withTitle:@"Test Alert"
                                         message:@"Test Message"
                               cancelButtonTitle:@"Cancel"
                          destructiveButtonTitle:@"Delete"
                               otherButtonTitles:@[@"First Other", @"Second Other"]
                                        tapBlock:self.tapBlock];
}

- (IBAction)showActionSheet:(UIButton *)sender {
    [UIAlertController showActionSheetInViewController:self
                                             withTitle:@"Test Action Sheet"
                                               message:@"Test Message"
                                     cancelButtonTitle:@"Cancel"
                                destructiveButtonTitle:@"Delete"
                                     otherButtonTitles:@[@"First Other", @"Second Other"]
                                              tapBlock:self.tapBlock];
}
@end

//
//  MYImageViewController.m
//  MYKitDemo
//
//  Created by sunjinshuai on 2018/7/20.
//  Copyright © 2018年 com.51fanxing. All rights reserved.
//

#import "MYImageViewController.h"
#import "MYKitMacroHeader.h"
#import "UIImageView+CornerRadius.h"
#import "UIImageView+RectCorner.h"
#import "UIImage+CornerRadius.h"
#import "UIImage+Color.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface MYImageViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation MYImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];

    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.frame = CGRectMake(20, 84, MYScreenWidth - 20*2, 200);
    UIImage *image = [UIImage createImageWithColor:[UIColor blueColor]];
    imageView.image = [UIImage covertToGrayImageFromImage:image];
    
    [self.view addSubview:imageView];
    
//    [self.view addSubview:self.tableView];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return 30;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 64.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    
    return 0.01f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    
    return 0.01f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
//        cell.imageView.image = [UIImage createImageFromView:self.view];
        
        UIImageView *imageView1 = [[UIImageView alloc] initWithCornerRadiusAdvance:25.0f rectCornerType:UIRectCornerTopLeft];
        imageView1.frame = CGRectMake(100, 5, 50, 50);
        imageView1.backgroundColor = [UIColor orangeColor];
        imageView1.contentMode = UIViewContentModeScaleAspectFill;
        cell.accessoryView = imageView1;
    }
    
    NSString *url = nil;
    switch (indexPath.row % 3) {
        case 0:
            url = @"http://pic24.nipic.com/20121022/1417516_151626862000_2.jpg";
            break;
        case 1:
            url = @"http://img3.doubanio.com/view/commodity_review/large/public/p200907257.jpg";
            break;
        default:
            url = @"http://pic26.nipic.com/20130114/9252150_140310235330_2.jpg";
            break;
    }
    
    [(UIImageView *)cell.accessoryView sd_setImageWithURL:[NSURL URLWithString:url] placeholderImage:[UIImage imageNamed:@"avatar1"]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
   
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, MYScreenWidth, MYScreenHeight) style:UITableViewStyleGrouped];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.backgroundColor = [UIColor whiteColor];
        if (@available(iOS 11.0, *)) {
            _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
        }
        [self.view addSubview:_tableView];
    }
    return _tableView;
}

@end

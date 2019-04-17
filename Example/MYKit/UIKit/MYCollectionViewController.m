//
//  MYCollectionViewController.m
//  MYKitDemo
//
//  Created by QMMac on 2018/8/6.
//  Copyright © 2018 com.51fanxing. All rights reserved.
//

#import "MYCollectionViewController.h"
#import "CollectionViewPlaceHolderDelegate.h"
#import "MYPlaceHolderView.h"
#import "MYUIKit.h"
#import <MJRefresh.h>

#define MJRandomColor [UIColor colorWithRed:arc4random_uniform(255)/255.0 green:arc4random_uniform(255)/255.0 blue:arc4random_uniform(255)/255.0 alpha:1]

@interface MYCollectionViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, MYPlaceHolderViewDelegate>

@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, assign, getter=isNoResult) BOOL noResult;

@end

@implementation MYCollectionViewController

/**
 *  初始化
 */
- (id)init {
    // UICollectionViewFlowLayout的初始化（与刷新控件无关）
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(80, 80);
    layout.sectionInset = UIEdgeInsetsMake(20, 20, 20, 20);
    layout.minimumInteritemSpacing = 20;
    layout.minimumLineSpacing = 20;
    return [self initWithCollectionViewLayout:layout];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"MYCollectionViewPlaceHolder";
    self.collectionView.backgroundColor = [UIColor whiteColor];
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"collectionViewCell"];
    __unsafe_unretained __typeof(self) weakSelf = self;
    self.collectionView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [weakSelf loadNewData];
    }];
    
    // 马上进入刷新状态
    [self.collectionView.mj_header beginRefreshing];
}

#pragma mark - collection数据源代理
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"collectionViewCell" forIndexPath:indexPath];
    cell.backgroundColor = self.dataSource[indexPath.row];
    return cell;
}

- (void)loadNewData {
    if (!self.isNoResult) {
        self.dataSource = nil;
    } else {
        // 1.添加假数据
        for (int i = 0; i<5; i++) {
            
            [self.dataSource insertObject:MJRandomColor atIndex:0];
        }
    }
    
    // 2.模拟1秒后刷新表格UI（真实开发中，可以移除这段gcd代码）
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 刷新表格
        [self.collectionView my_reloadData];
        [self.collectionView.mj_header endRefreshing];
    });
}

#pragma mark - MYPlaceHolderViewDelegate

- (UIView *)makePlaceHolderView {
    return [self placeHolderView];
}

- (UIView *)placeHolderView {
    MYPlaceHolderView *placeHolder = [[MYPlaceHolderView alloc] initWithFrame:self.collectionView.frame];
    placeHolder.delegate = self;
    return placeHolder;
}

#pragma mark - CollectionViewPlaceHolderDelegate

- (void)emptyOverlayClicked:(id)sender {
    [self.collectionView.mj_header beginRefreshing];
}

#pragma mark - setter & getter
- (BOOL)isNoResult {
    _noResult = (self.dataSource.count == 0);
    return _noResult;
}

- (NSMutableArray *)dataSource {
    if (!_dataSource) {
        _dataSource = [[NSMutableArray alloc] init];
    }
    return _dataSource;
}

@end

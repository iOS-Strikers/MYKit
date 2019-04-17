//
//  MYPlaceHolderView.h
//  MYKitDemo
//
//  Created by QMMac on 2018/8/6.
//  Copyright © 2018 com.51fanxing. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MYPlaceHolderViewDelegate <NSObject>

@required
- (void)emptyOverlayClicked:(id)sender;

@end

@interface MYPlaceHolderView : UIView

@property (nonatomic, weak) id<MYPlaceHolderViewDelegate> delegate;

@end

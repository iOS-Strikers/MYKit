//
//  MYKitMacroHeader.h
//  MYKitDemo
//
//  Created by QMMac on 2018/7/17.
//  Copyright © 2018 com.51fanxing. All rights reserved.
//

#ifndef MYKitMacroHeader_h
#define MYKitMacroHeader_h

#define weakSelf(type) __weak __typeof(&*self)weakSelf = self;
#define WeakObj(o) autoreleasepool{} __weak typeof(o) o##Weak = o;
#define StrongObj(o) autoreleasepool{} __strong typeof(o) o = o##Weak;
#define MYScreenWidth [UIScreen mainScreen].bounds.size.width
#define MYScreenHeight [UIScreen mainScreen].bounds.size.height
#define MYSCREEN_RATIO ([[UIScreen mainScreen]bounds].size.height)/667
#define MYSCREEN_SCALESIZE ([[UIScreen mainScreen]bounds].size.width)/375

#endif /* MYKitMacroHeader_h */

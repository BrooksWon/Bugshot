//
//  UIWindow+PazLabs.h
//  Bugshot
//
//  获取视图栈最上层的ViewController
//
//  Created by Brooks on 2018/3/20.
//  Copyright © 2018年 Brooks. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIWindow (PazLabs)
- (UIViewController *)visibleViewController;
@end

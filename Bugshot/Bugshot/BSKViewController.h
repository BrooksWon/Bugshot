//
//  BSKViewController.h
//
//  Bugshot 组件
//
//  Created by Brooks on 2018/3/20.
//  Copyright © 2018年 Brooks. All rights reserved.
//

#import <UIKit/UIKit.h>


@class BSKViewController;
@protocol BSKReporterProtocol;
@class BSKIssue;

@protocol BSKViewControllerDelegate

- (void)bugshotViewControllerDidDismiss:(BSKViewController *)viewController;

@end

@interface BSKViewController : UIViewController

@property (nonatomic, strong) BSKIssue *issue;

@property (nonatomic, weak) id<BSKViewControllerDelegate> delegate;
@property (nonatomic, strong) id<BSKReporterProtocol> reporter;

@end

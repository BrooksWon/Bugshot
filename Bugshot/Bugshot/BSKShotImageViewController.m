//
//  BSKShotImageViewController.m
//  Bugshot
//
//  Created by Brooks on 2018/3/27.
//  Copyright © 2018年 Brooks. All rights reserved.
//

#import "BSKShotImageViewController.h"

#import "BSKDrawingBoard.h"

@interface BSKShotImageViewController ()
/** 画板 */
@property (nonatomic, strong) BSKDrawingBoard *drawingBoard;

@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation BSKShotImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"清除"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self.drawingBoard
                                                                                action:@selector(clearDrawingBoard)];
    
    [self.view addSubview:self.imageView];
    
    self.imageView.image = self.shotImage;
    [self.imageView addSubview:self.drawingBoard];
}

//- (void)viewDidAppear:(BOOL)animated {
//    [super viewDidAppear:animated];
//
//    self.imageView.image = self.shotImage;
//    [self.imageView addSubview:self.drawingBoard];
//}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.drawingBoard.frame = self.imageView.bounds;
    
}

- (void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NEW_screenshotImage" object:[self imageFromeView:self.imageView]];
    [super viewDidDisappear:animated];
}

- (UIImage *)imageFromeView:(UIView *)view {
    
    CGFloat scale = [[UIScreen mainScreen] scale];
    UIImage *screenshot;
    UIGraphicsBeginImageContextWithOptions(view.frame.size, YES, scale);
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    }else {
        [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    }
    screenshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    
    return screenshot;
}

- (BSKDrawingBoard *)drawingBoard {
    if (!_drawingBoard) {
        _drawingBoard = [[BSKDrawingBoard alloc] init];
        _drawingBoard.backgroundColor = [UIColor clearColor];
    }
    return _drawingBoard;
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        _imageView.userInteractionEnabled = YES;
    }
    
    return _imageView;
}

@end

//
//  BSKDrawingBoard.h
//  Bugshot
//
//  Created by Brooks on 2018/3/27.
//  Copyright © 2018年 Brooks. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BSKDrawingBoard : UIView
@property (nonatomic, strong) UIColor *penColor;
@property (nonatomic, assign) CGFloat lineWidth;
@property (nonatomic, assign, readonly) BOOL isDrawing;
- (void)clearDrawingBoard;
- (void)clearDrawingBoardByStep;
@end

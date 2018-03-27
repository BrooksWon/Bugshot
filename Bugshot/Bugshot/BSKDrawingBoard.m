//
//  BSKDrawingBoard.m
//  Bugshot
//
//  Created by Brooks on 2018/3/27.
//  Copyright © 2018年 Brooks. All rights reserved.
//

#import "BSKDrawingBoard.h"

@interface BSKDrawingBoard ()
@property (nonatomic, strong) NSMutableArray <UIColor *> *lineColors;
@property (nonatomic, strong) NSMutableArray <NSMutableArray *> *lines;
@property (nonatomic, assign, readwrite) BOOL isDrawing;
@end

@implementation BSKDrawingBoard


- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self ordinaryInit];
    }
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self ordinaryInit];
    }
    return self;
}

- (void)ordinaryInit {
    self.lines = [[NSMutableArray alloc] init];
    self.lineColors = [[NSMutableArray alloc] init];
    self.penColor = [UIColor redColor];
    self.lineWidth = 3;
    self.isDrawing = YES;
}

- (void)clearDrawingBoard {
    if (self.lines.count > 0) {
        [self.lines removeAllObjects];
    }
    if (self.lineColors.count > 0) {
        [self.lineColors removeAllObjects];
    }
    
    [self setNeedsDisplay];
}
- (void)clearDrawingBoardByStep {
    if (self.lines.count > 0) {
        [self.lines removeLastObject];
    }
    if (self.lineColors.count > 0) {
        [self.lineColors removeLastObject];
    }
    [self setNeedsDisplay];
}
- (void)drawRect:(CGRect)rect {
    if (self.isDrawing) {
        //当前view的绘制信息
        CGContextRef context = UIGraphicsGetCurrentContext();
        //设置线条宽度
        CGContextSetLineWidth(context, self.lineWidth);
        //设置线条颜色
        CGContextSetStrokeColorWithColor(context, [self penColor].CGColor);
        /*  设置线的起点
         CGContextMoveToPoint(context, 0, 0);
         添加一条线，规定线的终点
         CGContextAddLineToPoint(context, 200, 200);
         */
        for (int i = 0; i < MIN(self.lines.count, self.lineColors.count); i++) {
            // 获取到每一条线（点的数组）
            NSMutableArray *points = [self.lines objectAtIndex:i];
            UIColor *color = [self.lineColors objectAtIndex:i];
            //如果数组中没有点 跳过此次循环
            if (0 == points.count) {
                continue;
            }
            for (int j = 0; j < points.count - 1; j ++) {
                //获取每一个点及这个点之后的点， 连线
                CGContextSetStrokeColorWithColor(context, color.CGColor);
                NSValue *pointValueA = [points objectAtIndex:j];
                NSValue *pointValueB = [points objectAtIndex:j + 1];
                CGPoint pointA = [pointValueA CGPointValue];
                CGPoint pointB = [pointValueB CGPointValue];
                CGContextMoveToPoint(context, pointA.x, pointA.y);
                CGContextAddLineToPoint(context, pointB.x, pointB.y);
            }
            //根据绘制信息在uiview上绘制图形
            CGContextStrokePath(context);
        }
    }
}
//记录划线的点信息
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[event allTouches]  anyObject];
    [touch gestureRecognizers];
    //每次接触大屏幕，都需要创建一条线（点的数组）
    NSMutableArray *points = [NSMutableArray array];
    //每次都将新的线添加到线的数组中，方便管理
    [self.lines addObject:points];
    [self.lineColors addObject:self.penColor];
    //将每次的颜色添加到数组
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    //    if (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable) {
    //        UITouch *touch = touches.anyObject;
    //        self.lineWidth = touch.force * 3;
    //        NSLog(@"%@",@(touch.force));
    //    }
    UITouch *touch = [touches anyObject];//集合的取值
    CGPoint point = [touch locationInView:self];
    NSValue *pointValue = [NSValue valueWithCGPoint:point];//因为数组内只能存对象类型
    //强制view调用drawRect：方法 实现边画边绘制
    //获取到当前的（点的数组）
    NSMutableArray *points = [self.lines lastObject];
    //把点添加到线（点的数组）中
    [points addObject:pointValue];
    [self setNeedsDisplay];
    
}
@end

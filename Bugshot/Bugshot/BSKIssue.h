//
//  BSKIssue.h
//
//  GitLab Issue 对象
//
//  Created by Brooks on 2018/3/20.
//  Copyright © 2018年 Brooks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface BSKIssue : NSObject

@property (nonatomic, copy) NSString *projectId;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *body;
@property (nonatomic, copy) NSArray *labels;
@property (nonatomic, copy) NSString *milestoneId;
@property (nonatomic, copy) NSString *assigneeId;
@property (nonatomic, strong) UIImage *screenshotImage;
@property (nonatomic, strong) NSDictionary *userInfo;

@end

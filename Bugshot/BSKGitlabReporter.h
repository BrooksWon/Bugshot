//
//  BSKGitlabReporter.h
//  GitLab Issue Reporter
//
//  GitLab Issue 发布器
//
//  Created by Brooks on 2018/3/20.
//  Copyright © 2018年 Brooks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BugshotKit.h"


@interface BSKGitlabReporter : NSObject <BSKReporterProtocol>

- (instancetype)initWithGitLabPrivateToken:(NSString *)gitlabPrivateToken;

@property (nonatomic, copy) NSString *gitlabPrivateToken;

@end

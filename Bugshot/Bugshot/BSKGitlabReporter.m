//
//  BSKGitlabReporter.m
//
//
//  Created by Brooks on 2018/3/20.
//  Copyright © 2018年 Brooks. All rights reserved.
//

#import "BSKGitlabReporter.h"

static NSString const * kGitLabBaseUrl = @"https://gitlab.weiboyi.com"; // 反向链接地址
static NSString const * kGitLabProjectId = @"87";// wby/app/Git

@implementation BSKGitlabReporter

- (instancetype)initWithGitLabPrivateToken:(NSString *)gitlabPrivateToken {
    self = [super init];
    if (self) {
        self.gitlabPrivateToken = gitlabPrivateToken;
    }

    return self;
}

- (void)uploadContentData:(NSData *_Nonnull)contentData
              contentType:(NSString *_Nonnull)contentType
           withCompletion:(void (^)(NSString *, NSError *))completion {

    if (self.gitlabPrivateToken.length == 0) {
        completion(nil, nil);
        return;
    }

    NSURL *gitlabUploadsUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/api/v3/projects/%@/uploads", kGitLabBaseUrl, kGitLabProjectId]];
    NSString *boundary = @"__Bugshot_Boundary__";
    NSMutableData *body = [NSMutableData data];
    if (contentData) {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"screenshot.jpg\"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Type: image/jpeg\r\n\r\n", contentType] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:contentData];
        [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];

    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.HTTPAdditionalHeaders = @{
        @"PRIVATE-TOKEN" : self.gitlabPrivateToken,
        @"Accept"        : @"application/json",
        @"Content-Type"  : [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary]
    };

    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:nil delegateQueue:nil];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:gitlabUploadsUrl];
    request.HTTPMethod = @"POST";
    request.HTTPBody = body;
    NSURLSessionDataTask *uploadTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error == nil) {
            NSLog(@"URL Session Task Succeeded: HTTP %zd", ((NSHTTPURLResponse*)response).statusCode);

            // 201 标识创建成功
            if (((NSHTTPURLResponse *)response).statusCode == 201) {
                NSError *jsonError;
                NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
                if (jsonError) {
                    completion(nil, jsonError);
                } else {
                    completion(responseDict[@"markdown"], nil);
                }
            } else {
                completion(nil, error);
            }
        } else {
            NSLog(@"URL Session Task Failed: %@", [error localizedDescription]);
            completion(nil, error);
        }
    }];

    [uploadTask resume];
}

- (void)uploadIssue:(BSKIssue *_Nonnull)issue withCompletion:(void (^)(NSError *))completion {
    if (self.gitlabPrivateToken.length == 0) {
        completion(nil);
        return;
    }

    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:nil];

    NSURL *gitlabIssuesUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/api/v3/projects/%@/issues", kGitLabBaseUrl, kGitLabProjectId]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:gitlabIssuesUrl];
    [request setHTTPMethod:@"POST"];

    NSRange range = [issue.title rangeOfString:@"\n"];
    NSInteger min = range.location;
    NSString *titleText = [[issue.title substringToIndex:MIN(issue.title.length, min)] stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    NSDictionary *bodyDict = @{
        @"title" : titleText.length > 0 ? titleText : @"No Title",
        @"description" : [NSString stringWithFormat:@"%@\r\n\r\n%@", issue.body ?: @"", issue.userInfo],
        @"labels" : issue.labels ?[issue.labels componentsJoinedByString:@","] : @"",
        @"assignee_id" : issue.assigneeId ?: @"",
        @"milestone_id" : issue.milestoneId ?: @"",
    };

    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:bodyDict options:0 error:&jsonError];

    if (!jsonData) {
        completion(jsonError);
        return;
    } else {
        [request setValue:self.gitlabPrivateToken forHTTPHeaderField:@"PRIVATE-TOKEN"];
        [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long) jsonData.length] forHTTPHeaderField:@"Content-Length"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

        [request setHTTPBody:jsonData];

        NSURLSessionTask *task = [session dataTaskWithRequest:request
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                completion(error);
                                            }];
        [task resume];
    }
}

- (void)submitIssue:(BSKIssue *_Nonnull)issue withCompletion:(void (^)(NSError *))completion {
    if (issue.screenshotImage) {
        UIImage *image = [self imageWithImage:issue.screenshotImage scaledToWidth:320];
        NSData *imageData = UIImageJPEGRepresentation(image, 0.90);

        [self uploadContentData:imageData
                    contentType:@"image/jpeg"
                 withCompletion:^(NSString *string, NSError *error) {
                     if (string && !error) {
                         issue.body = [NSString stringWithFormat:@"%@\r\n\r\n%@", string, issue.body];
                         [self uploadIssue:issue withCompletion:^(NSError *error1) {
                             completion(error1);
                         }];
                     } else {
                         completion(error);
                     }
                 }];
    } else {
        [self uploadIssue:issue withCompletion:^(NSError *error) {
            completion(error);
        }];
    }
}

- (UIImage *)imageWithImage:(UIImage *)sourceImage scaledToWidth:(float)destWidth {
    float oldWidth = sourceImage.size.width;
    float scaleFactor = destWidth / oldWidth;

    float newHeight = sourceImage.size.height * scaleFactor;
    float newWidth = oldWidth * scaleFactor;

    UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
    [sourceImage drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
    UIImage *destImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return destImage;
}

@end

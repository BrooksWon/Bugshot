//  BugshotKit.h
//  See included LICENSE file for the (MIT) license.
//  Created by Marco Arment on 1/15/14.

#import <UIKit/UIKit.h>
#import "BSKViewController.h"
#import "BSKIssue.h"


@protocol BSKReporterProtocol

- (void)submitIssue:(BSKIssue *_Nonnull)issue withCompletion:(nullable void (^)(NSError *_Nullable error))completion;

@end

extern NSString * _Nullable const BSKLogMessagesDidUpdateNotification;

@interface BugshotKit : NSObject <UIGestureRecognizerDelegate, BSKViewControllerDelegate>

/*
 * Call this from your UIApplication didFinishLaunching:... method.
 * 双指双击触发
 */
+ (void)enable;

/* You can also always show it manually */
+ (void)show;
+ (void)dismissAnimated:(BOOL)animated completion:(void(^ _Nullable)())completion;

+ (nonnull instancetype)sharedManager;

+ (void)addLogMessage:(NSString * _Nullable)message;

@property (nonatomic) NSUInteger consoleLogMaxLines;

- (void)currentLogWithTimestamp:(BOOL)containsTimestamp withCompletion:(void (^)(NSString *result))completion;

@property (nonatomic, strong) UIColor *annotationFillColor;
@property (nonatomic, strong) UIColor *annotationStrokeColor;

// don't mess with these
@property (nonatomic, strong, nullable) UIImage *snapshotImage;
@property (nonatomic, copy, nullable) NSArray *annotations;
@property (nonatomic, strong, nullable) UIImage *annotatedImage;

@end

//  BugshotKit.m
//  See included LICENSE file for the (MIT) license.
//  Created by Marco Arment on 1/15/14.

#import "BugshotKit.h"
#import "BSKNavigationController.h"
#import <asl.h>
#import "BSKBackgroundTimer.h"
#import "BSKGitlabReporter.h"
#import "UIWindow+PazLabs.h"


NSString *const BSKLogMessagesDidUpdateNotification = @"BSKLogMessagesDidUpdateNotification";
NSString *const BSKGitLabPrivateToken = @"Books.GitLabPrivateToken";

@interface BSKLogMessage : NSObject
@property (nonatomic, copy) NSString *message;
@property (nonatomic) NSTimeInterval timestamp;
@end

@implementation BSKLogMessage
@end

@interface BugshotKit () <UIAlertViewDelegate> {
    dispatch_source_t source;
}

@property (nonatomic) BOOL isVisible;
@property (nonatomic) BOOL isDisabled;

@property (nonatomic, weak) BSKNavigationController *presentedNavigationController;
@property (nonatomic, weak) UIWindow *window;
@property (nonatomic) NSMapTable *windowsWithGesturesAttached;

@property (nonatomic) NSMutableSet *collectedASLMessageIDs;
@property (nonatomic) NSMutableArray *logMessages;
@property (nonatomic) dispatch_queue_t logQueue;
@property (nonatomic) BSKBackgroundTimer *logThrottler;

@end

@implementation BugshotKit

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    static BugshotKit *sharedManager;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

+ (void)enable {
    if (BugshotKit.sharedManager.isDisabled) {
        return;
    }

    // dispatched to next main-thread loop so the app delegate has a chance to set up its window
    dispatch_async(dispatch_get_main_queue(), ^{
        [BugshotKit.sharedManager ensureWindow];
        [BugshotKit.sharedManager attachToWindow:BugshotKit.sharedManager.window];
    });
}

- (instancetype)init {
    if ((self = [super init])) {
        self.windowsWithGesturesAttached = [NSMapTable weakToWeakObjectsMapTable];

        self.annotationFillColor = [UIColor colorWithRed:1.0f green:0.2196f blue:0.03922f alpha:1.0f];
        self.annotationStrokeColor = [UIColor whiteColor];

        self.collectedASLMessageIDs = [NSMutableSet set];
        self.logMessages = [NSMutableArray array];
        self.consoleLogMaxLines = 5000;

        self.logQueue = dispatch_queue_create("BugshotKit console", NULL);
        self.logThrottler = [[BSKBackgroundTimer alloc] initWithObject:self behavior:BSKBackgroundTimerCoalesce queueLabel:"BugshotKit console throttler"];
        [self.logThrottler setTargetQueue:self.logQueue];

        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(windowDidBecomeVisible:)
                                                   name:UIWindowDidBecomeVisibleNotification
                                                 object:nil];

        // notify on every write to stderr (so we can track NSLog real-time, without polling, when a console is showing)
        source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, (uintptr_t) fileno(stderr), DISPATCH_VNODE_WRITE, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
        __weak BugshotKit *weakSelf = self;
        dispatch_source_set_event_handler(source, ^{
            [weakSelf.logThrottler afterDelay:0.5 do:^(id self) {
                if ([self collectASLMessages]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [NSNotificationCenter.defaultCenter postNotificationName:BSKLogMessagesDidUpdateNotification object:nil];
                    });
                }
            }];
        });

        // start to resume observation
        dispatch_async(self.logQueue, ^{
            [self collectASLMessages];
            dispatch_resume(source);
        });
    }

    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIWindowDidBecomeVisibleNotification object:nil];
    if (!self.isDisabled) {
        dispatch_source_cancel(source);
    }
}

- (void)ensureWindow {
    if (self.window) {
        return;
    }

    self.window = UIApplication.sharedApplication.keyWindow;
    if (!self.window) {
        self.window = UIApplication.sharedApplication.windows.lastObject;
    }

    if (!self.window) {
        NSAssert(NO, @"BugshotKit cannot find any application windows");
    }

    if (!self.window.rootViewController) {
        NSAssert(NO, @"BugshotKit requires a rootViewController set on the window");
    }
}

- (void)windowDidBecomeVisible:(NSNotification *)notification {
    UIWindow *window = (UIWindow *) notification.object;
    if (!window || ![window isKindOfClass:UIWindow.class]) {
        return;
    }

    [self attachToWindow:window];
}

- (void)attachToWindow:(UIWindow *)window {
    if (self.isDisabled) {
        return;
    }

    if ([self.windowsWithGesturesAttached objectForKey:window]) {
        return;
    }

    [self.windowsWithGesturesAttached setObject:window forKey:window];

    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
    longPressGestureRecognizer.numberOfTouchesRequired = 2;
    longPressGestureRecognizer.delegate = self;
    [window addGestureRecognizer:longPressGestureRecognizer];
}

- (UIInterfaceOrientation)statusBarOrientation {
    return [[UIApplication sharedApplication] statusBarOrientation];
}

- (void)handleGesture:(UIGestureRecognizer *)sender {
    if (self.isVisible) {
        return;
    }

    // 读取 UserDefaults 里的 GitLab Private Token, Private Token 单独保存
    NSString *gitlabPrivateToken = [[NSUserDefaults standardUserDefaults] valueForKey:BSKGitLabPrivateToken];

    if (gitlabPrivateToken.length == 0) {
        self.isVisible = YES;

        // 当第一次配置bugshot的时候，通过[[UIApplication sharedApplication] keyWindow]获取到的是悬浮按钮的window
        // 下次从新进入的时候，[[UIApplication sharedApplication] keyWindow]获取到的又是正确的window
        // 目前未找到原因，如果区分不同版本的弹窗方式，[[UIApplication sharedApplication] keyWindow]获取到的是正确的window
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"GitLab" message:@"Enter the GitLab Private Token:" preferredStyle:UIAlertControllerStyleAlert];
            [alert addTextFieldWithConfigurationHandler:nil];

            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                if ([alert.textFields firstObject].text.length > 0) {
                    [[NSUserDefaults standardUserDefaults] setObject:[alert.textFields firstObject].text forKey:BSKGitLabPrivateToken];

                    self.isVisible = NO;
                }
            }];

            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                self.isVisible = NO;
            }];

            [alert addAction:okAction];
            [alert addAction:cancelAction];

            [self.window.visibleViewController presentViewController:alert animated:YES completion:nil];

        return;
    }

    UIInterfaceOrientation interfaceOrientation = self.statusBarOrientation;

    self.isVisible = YES;

    UIGraphicsBeginImageContextWithOptions(self.window.bounds.size, NO, UIScreen.mainScreen.scale);

    NSMutableSet *drawnWindows = [NSMutableSet set];
    for (UIWindow *window in UIApplication.sharedApplication.windows) {
        [drawnWindows addObject:window];
        [window drawViewHierarchyInRect:window.bounds afterScreenUpdates:NO];
    }

    // Must iterate through all windows we know about because UIAlertViews, etc. don't add themselves to UIApplication.windows
    for (UIWindow *window in self.windowsWithGesturesAttached) {
        if ([drawnWindows containsObject:window]) {
            continue;
        }

        [drawnWindows addObject:window];

        [window.layer renderInContext:UIGraphicsGetCurrentContext()]; // drawViewHierarchyInRect: doesn't capture UIAlertView opacity properly
    }

    self.snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    if (interfaceOrientation != UIInterfaceOrientationPortrait) {
        self.snapshotImage = [[UIImage alloc] initWithCGImage:self.snapshotImage.CGImage
                                                        scale:UIScreen.mainScreen.scale
                                                  orientation:(interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown ? UIImageOrientationDown : (interfaceOrientation == UIInterfaceOrientationLandscapeLeft ? UIImageOrientationRight : UIImageOrientationLeft))];
    }

    UIViewController *visibleViewController = [[[UIApplication sharedApplication] keyWindow] visibleViewController];

    while (visibleViewController.presentedViewController) {
        visibleViewController = visibleViewController.presentedViewController;
    }

    BSKViewController *bugshotViewController = [[BSKViewController alloc] init];
    bugshotViewController.delegate = self;
    
    bugshotViewController.issue.title = @"No Title";

//    if (visibleViewController.log_eventName.length > 0) {
//        bugshotViewController.issue.title = [NSString stringWithFormat:@"【%@】", visibleViewController.log_eventName];
//    }

    bugshotViewController.reporter = [[BSKGitlabReporter alloc] initWithGitLabPrivateToken:gitlabPrivateToken];
    BSKNavigationController *navigationController = [[BSKNavigationController alloc] initWithRootViewController:bugshotViewController lockedToRotation:self.statusBarOrientation];
    self.presentedNavigationController = navigationController;
    navigationController.navigationBar.tintColor = BugshotKit.sharedManager.annotationFillColor;
    navigationController.navigationBar.titleTextAttributes = @{
        NSForegroundColorAttributeName : BugshotKit.sharedManager.annotationFillColor
    };

    [visibleViewController presentViewController:navigationController animated:YES completion:NULL];
}

+ (void)show {
    [BugshotKit.sharedManager ensureWindow];
    [BugshotKit.sharedManager handleGesture:nil];
}

+ (void)dismissAnimated:(BOOL)animated completion:(void (^)())completion {
    UIViewController *presentingVC = BugshotKit.sharedManager.presentedNavigationController.presentingViewController;
    if (presentingVC) {
        [presentingVC dismissViewControllerAnimated:animated completion:completion];
        [BugshotKit.sharedManager bugshotViewControllerDidDismiss:nil];
    } else {
        if (completion)
            completion();
    }
}

- (void)bugshotViewControllerDidDismiss:(BSKViewController *)viewController {
    self.isVisible = NO;
    self.snapshotImage = nil;
    self.annotatedImage = nil;
    self.annotations = nil;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.alertViewStyle == UIAlertViewStylePlainTextInput) {
        NSString *gitlabPrivateToken = [alertView textFieldAtIndex:0].text;
        if (gitlabPrivateToken.length > 0) {
            [[NSUserDefaults standardUserDefaults] setObject:gitlabPrivateToken forKey:BSKGitLabPrivateToken];

            [BugshotKit.sharedManager bugshotViewControllerDidDismiss:nil];
        } else {
            self.isVisible = NO;
        }
    }
}

#pragma mark - Console logging

- (void)currentLogWithTimestamp:(BOOL)containsTimestamp withCompletion:(void (^)(NSString *result))completion {
    dispatch_async(self.logQueue, ^{
        NSMutableString *string = [NSMutableString string];

        char fdate[24];
        for (BSKLogMessage *msg in self.logMessages) {
            if (containsTimestamp) {
                time_t timestamp = (time_t) msg.timestamp;
                struct tm *lt = localtime(&timestamp);
                strftime(fdate, 24, "%Y-%m-%d %T", lt);
                [string appendFormat:@"%s.%03d %@\n", fdate, (int) (1000.0 * (msg.timestamp - floor(msg.timestamp))), msg.message];
            } else {
                [string appendFormat:@"%@\n", msg.message];
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            completion(string);
        });
    });
}

+ (void)addLogMessage:(NSString *)message {
    BugshotKit *manager = BugshotKit.sharedManager;
    if (manager.isDisabled)
        return;

    dispatch_async(manager.logQueue, ^{
        [manager addLogMessage:message timestamp:[NSDate date].timeIntervalSince1970];
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSNotificationCenter.defaultCenter postNotificationName:BSKLogMessagesDidUpdateNotification object:nil];
        });
    });
}

// assumed to always be in logQueue
- (void)addLogMessage:(NSString *)message timestamp:(NSTimeInterval)timestamp {
    BSKLogMessage *msg = [BSKLogMessage new];
    msg.message = message;
    msg.timestamp = timestamp;
    [self.logMessages addObject:msg];

    // once the log has exceeded the length limit by 25%, prune it to the length limit
    if (self.logMessages.count > self.consoleLogMaxLines * 1.25) {
        [self.logMessages removeObjectsInRange:NSMakeRange(0, self.logMessages.count - self.consoleLogMaxLines)];
    }
}

// Because aslresponse_next is now deprecated.
asl_object_t SystemSafeASLNext(asl_object_t r) {
    if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0f) {
        return asl_next(r);
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    // The deprecation attribute incorrectly states that the replacement method, asl_next()
    // is available in __IPHONE_7_0; asl_next() first appears in __IPHONE_8_0.
    // This would require both a compile and runtime check to properly implement the new method
    // while the minimum deployment target for this project remains iOS 7.0.
    return aslresponse_next(r);
#pragma clang diagnostic pop
}

// assumed to always be in logQueue
// http://www.cocoanetics.com/2011/03/accessing-the-ios-system-log/
- (BOOL)collectASLMessages {
    pid_t myPID = getpid();

    aslmsg q, m;
    q = asl_new(ASL_TYPE_QUERY);
    aslresponse r = asl_search(NULL, q);
    BOOL foundEntries = NO;

    while ((m = SystemSafeASLNext(r))) {
        if (myPID != atol(asl_get(m, ASL_KEY_PID)))
            continue;

        // dupe checking
        NSNumber *msgID = @( atoll(asl_get(m, ASL_KEY_MSG_ID)) );
        if ([_collectedASLMessageIDs containsObject:msgID])
            continue;
        [_collectedASLMessageIDs addObject:msgID];
        foundEntries = YES;

        NSTimeInterval msgTime = (NSTimeInterval) atol(asl_get(m, ASL_KEY_TIME)) + ((NSTimeInterval) atol(asl_get(m, ASL_KEY_TIME_NSEC)) / 1000000000.0);

        const char *msg = asl_get(m, ASL_KEY_MSG);
        if (msg == NULL) {
            continue;
        }

        [self addLogMessage:[NSString stringWithUTF8String:msg] timestamp:msgTime];
    }

    if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0f) {
        asl_release(r);
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        // The deprecation attribute incorrectly states that the replacement method, asl_release()
        // is available in __IPHONE_7_0; asl_release() first appears in __IPHONE_8_0.
        // This would require both a compile and runtime check to properly implement the new method
        // while the minimum deployment target for this project remains iOS 7.0.
        aslresponse_free(r);
#pragma clang diagnostic pop
    }

    asl_free(q);

    return foundEntries;
}

@end

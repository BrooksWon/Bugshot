//  BSKScreenshotViewController.m
//  See included LICENSE file for the (MIT) license.
//  Created by Marco Arment on 6/28/13.

#import "BSKScreenshotViewController.h"
#import "BugshotKit.h"
#import "BSKAnnotationBoxView.h"
#import "BSKAnnotationArrowView.h"
#import "BSKAnnotationBlurView.h"
#import "BSKCheckerboardView.h"


#define kAnnotationToolArrow 0

@interface BSKScreenshotViewController () {
    BSKAnnotationView *annotationViewInProgress;
    int annotationToolChosen;
}

@property (nonatomic, retain) UIImage *screenshotImage;
@property (nonatomic, strong) UITapGestureRecognizer *contentAreaTapGestureRecognizer;
@property (nonatomic, copy) NSArray *annotationsToImport;

@end

@implementation BSKScreenshotViewController

- (id)initWithImage:(UIImage *)image annotations:(NSArray *)annotations {
    if ((self = [super init])) {
        self.screenshotImage = image;
        self.annotationsToImport = annotations;

        annotationViewInProgress = nil;
        annotationToolChosen = kAnnotationToolArrow;

        self.contentAreaTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(contentAreaTapped:)];
    }
    return self;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationFade;
}

- (BOOL)prefersStatusBarHidden {
    return self.navigationController.navigationBarHidden;
}

- (void)loadView {
    CGRect frame = UIScreen.mainScreen.bounds;
    frame.origin = CGPointZero;
    UIView *view = [[UIView alloc] initWithFrame:frame];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    view.autoresizesSubviews = YES;

    self.screenshotImageView = [[UIImageView alloc] initWithFrame:frame];
    self.screenshotImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.screenshotImageView.image = self.screenshotImage;
    [view addSubview:self.screenshotImageView];

    view.tintColor = BugshotKit.sharedManager.annotationFillColor;

    if (self.annotationsToImport) {
        for (UIView *annotation in self.annotationsToImport)
            [view addSubview:annotation];
    }

    view.multipleTouchEnabled = YES;
    [view addGestureRecognizer:self.contentAreaTapGestureRecognizer];

    self.view = view;
}

- (void)viewWillDisappear:(BOOL)animated {
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, YES, UIScreen.mainScreen.scale);
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *annotatedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    NSMutableArray *annotations = [NSMutableArray array];
    for (UIView *annotation in self.view.subviews) {
        if ([annotation isKindOfClass:BSKAnnotationView.class])
            [annotations addObject:annotation];
    }

    BugshotKit.sharedManager.annotations = annotations;
    BugshotKit.sharedManager.annotatedImage = annotatedImage;

    [super viewWillDisappear:animated];
}

- (void)contentAreaTapped:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateRecognized && !UIAccessibilityIsVoiceOverRunning()) {
        BOOL hidden = !self.navigationController.navigationBarHidden;
        [self.navigationController setNavigationBarHidden:hidden animated:YES];
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

#pragma mark - Touch handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (touches.count == 1) {
        UITouch *touch = touches.anyObject;

        if ([touch.view isKindOfClass:BSKAnnotationView.class]) {
            // Resizing or moving an existing annotation
        } else {
            // Creating a new annotation
            CGRect annotationFrame = {[touch locationInView:self.view], CGSizeMake(1, 1)};

            if (annotationToolChosen == kAnnotationToolArrow) {
                annotationViewInProgress = [[BSKAnnotationArrowView alloc] initWithFrame:annotationFrame];
            } else {
                NSAssert1(0, @"Unknown tool %d chosen", annotationToolChosen);
            }

            annotationViewInProgress.annotationStrokeColor = BugshotKit.sharedManager.annotationStrokeColor;
            annotationViewInProgress.annotationFillColor = BugshotKit.sharedManager.annotationFillColor;

            [self.view addSubview:annotationViewInProgress];

            annotationViewInProgress.startedDrawingAtPoint = annotationFrame.origin;
        }
    } else if (annotationViewInProgress) {
        [annotationViewInProgress removeFromSuperview];
        annotationViewInProgress = nil;
    } else {
        [super touchesBegan:touches withEvent:event];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (touches.count == 1 && annotationViewInProgress) {
        UITouch *touch = touches.anyObject;
        CGPoint p1 = [touch locationInView:self.view], p2 = annotationViewInProgress.startedDrawingAtPoint;

        CGRect bounding = CGRectMake(MIN(p1.x, p2.x), MIN(p1.y, p2.y), ABS(p1.x - p2.x), ABS(p1.y - p2.y));

        if (bounding.size.height < 40)
            bounding.size.height = 40;
        if (bounding.size.width < 40)
            bounding.size.width = 40;
        annotationViewInProgress.frame = bounding;

        if ([annotationViewInProgress isKindOfClass:[BSKAnnotationArrowView class]]) {
            ((BSKAnnotationArrowView *) annotationViewInProgress).arrowEnd = p1;
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (annotationViewInProgress) {
        CGSize annotationSize = annotationViewInProgress.bounds.size;
        if (MIN(annotationSize.width, annotationSize.height) < 5.0f || (annotationSize.width < 32.0f && annotationSize.height < 32.0f)) {
            // Too small, probably accidental
            [annotationViewInProgress removeFromSuperview];
        } else {
            [self.contentAreaTapGestureRecognizer requireGestureRecognizerToFail:annotationViewInProgress.doubleTapDeleteGestureRecognizer];
            [annotationViewInProgress initialScaleDone];
        }

        annotationViewInProgress = nil;
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    if (annotationViewInProgress) {
        [annotationViewInProgress removeFromSuperview];
        annotationViewInProgress = nil;
    }
}

@end

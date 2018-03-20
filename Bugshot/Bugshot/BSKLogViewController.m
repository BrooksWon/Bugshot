//  BSKLogViewController.m
//  See included LICENSE file for the (MIT) license.
//  Created by Marco Arment on 1/17/14.

#import "BSKLogViewController.h"
#import "BugshotKit.h"

@interface BSKLogViewController ()

@property (nonatomic) UITextView *consoleTextView;

@end

static int markerNumber = 0;

@implementation BSKLogViewController

- (instancetype)init {
    if ((self = [super init])) {
        self.title = @"Log";
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                               target:self
                                                                                               action:@selector(addMarkerButtonTapped:)];

        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(refresh:) name:BSKLogMessagesDidUpdateNotification object:nil];
    }
    return self;
}

- (void)addMarkerButtonTapped:(id)sender {
    NSTimeInterval timeInterval = [NSDate date].timeIntervalSince1970;
    [BugshotKit addLogMessage:[NSString stringWithFormat:@"----------- marker #%d / %.lf -----------", markerNumber, timeInterval]];
    markerNumber++;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    UIView *consoleView = self.consoleTextView;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[c]|" options:0 metrics:nil views:@{@"c" : consoleView}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[top][c]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"c" : consoleView, @"top" : self.topLayoutGuide}]];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self refresh:nil];
    });
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self name:BSKLogMessagesDidUpdateNotification object:nil];
}

- (void)loadView {
    CGRect frame = UIScreen.mainScreen.bounds;
    frame.origin = CGPointZero;
    UIView *view = [[UIView alloc] initWithFrame:frame];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    view.autoresizesSubviews = YES;

    self.automaticallyAdjustsScrollViewInsets = NO;
    self.consoleTextView = [[UITextView alloc] initWithFrame:frame];
    self.consoleTextView.translatesAutoresizingMaskIntoConstraints = NO;
    self.consoleTextView.editable = NO;
    self.consoleTextView.font = [UIFont fontWithName:@"CourierNewPSMT" size:9.f];
    [view addSubview:self.consoleTextView];

    self.view = view;
}

- (void)refresh:(NSNotification *)n {
    if (!self.isViewLoaded)
        return;

    [BugshotKit.sharedManager currentLogWithTimestamp:YES withCompletion:^(NSString *result) {
        self.consoleTextView.text = result;
        [self.consoleTextView scrollRangeToVisible:NSMakeRange([result length], 0)];
    }];
}

@end

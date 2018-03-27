//
//  BSKViewController.m
//  TestBugshotKit
//
//
//  Created by Brooks on 2018/3/20.
//  Copyright © 2018年 Brooks. All rights reserved.
//

#import <sys/sysctl.h>
#import "BSKViewController.h"
#import "BugshotKit.h"
#import "BSKIssue.h"
#import <Masonry/Masonry.h>
#import <OAStackView/OAStackView.h>
#import "BSKShotImageViewController.h"


@interface BSKViewController () <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>

@property (nonatomic, assign) BOOL didSetupConstraints;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) OAStackView *stackView;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *bodyLabel;
@property (nonatomic, strong) UILabel *levelLabel;
@property (nonatomic, strong) UILabel *assigneeLabel;

@property (nonatomic, strong) UITextView *titleTextView;
@property (nonatomic, strong) UITextView *bodyTextView;
@property (nonatomic, strong) UIButton *levelButton;
@property (nonatomic, strong) UIButton *assigneeButton;

@property (nonatomic, strong) UIActionSheet *levelActionSheet;
@property (nonatomic, strong) UIActionSheet *assigneeActionSheet;

@property (nonatomic, strong) UIButton *submitButton;

@property (nonatomic, strong) NSDictionary *levels;
@property (nonatomic, strong) NSDictionary *assignees;

@end

@implementation BSKViewController {
    UIImage *_screenshotImage;
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (UIInterfaceOrientation)statusBarOrientation {
    return [[UIApplication sharedApplication] statusBarOrientation];
}

- (void)NEW_screenshotImage:(NSNotification*)noti
{
    if (noti.object && [noti.object isKindOfClass:[UIImage class]]) {
        _screenshotImage = noti.object;
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(NEW_screenshotImage:)
                                                name:@"NEW_screenshotImage"
                                              object:nil];

    self.levels = @{
        @"P0" : @"P0",
        @"P1" : @"P1",
        @"P2" : @"P2",
        @"P3" : @"P3",
    };

    self.assignees = @{
        @"Brooks" : @"27",
        @"SunXX"  : @"40",
    };

    self.title = @"Bugshot";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消"
                                     style:UIBarButtonItemStylePlain
                                    target:self
                                    action:@selector(dismissAction:)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"提交"
                                     style:UIBarButtonItemStyleDone
                                    target:self
                                    action:@selector(sendAction:)];

    self.view.backgroundColor = [UIColor whiteColor];

    [self.stackView addArrangedSubview:self.titleLabel];
    [self.stackView addArrangedSubview:self.titleTextView];
    [self.stackView addArrangedSubview:self.bodyLabel];
    [self.stackView addArrangedSubview:self.bodyTextView];

    OAStackView *stackView1 = [[OAStackView alloc] initWithArrangedSubviews:@[self.levelLabel, self.levelButton, self.assigneeLabel, self.assigneeButton]];
    stackView1.axis = UILayoutConstraintAxisHorizontal;
    stackView1.distribution = OAStackViewDistributionEqualSpacing;
    stackView1.alignment = OAStackViewAlignmentCenter;
    [self.stackView addArrangedSubview:stackView1];

    [stackView1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.stackView).offset(-24);
    }];

    [self.view addSubview:self.tableView];
    [self.view addSubview:self.stackView];
    [self.view addSubview:self.submitButton];

    for (NSString *level in [self.levels.allKeys sortedArrayUsingSelector:@selector(compare:)]) {
        [self.levelActionSheet addButtonWithTitle:level];
    }

    for (NSString *assignee in self.assignees.allKeys) {
        [self.assigneeActionSheet addButtonWithTitle:assignee];
    }

    self.titleTextView.text = self.issue.title;
    self.bodyTextView.text = self.issue.body;

    [self updateViewConstraints];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    self.submitButton.enabled = YES;
    self.submitButton.hidden = YES;

    self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void)updateViewConstraints {
    if (!self.didSetupConstraints) {

        [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view);
            make.centerX.and.width.equalTo(self.view);
            make.height.equalTo(@176);
        }];

        [self.stackView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.tableView.mas_bottom);
            make.centerX.and.width.equalTo(self.view);
        }];

        [@[self.titleLabel, self.bodyLabel] mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(self.stackView).offset(-24);
            make.height.equalTo(@36);
        }];

        [self.titleTextView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(self.stackView).offset(-24);
            make.height.equalTo(@44);
        }];

        [self.bodyTextView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(self.stackView).offset(-24);
            make.height.equalTo(@88);
        }];

        [@[self.levelLabel, self.assigneeLabel] mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.greaterThanOrEqualTo(@44);
        }];

        [@[self.levelButton, self.assigneeButton] mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.greaterThanOrEqualTo(@44);
            make.height.equalTo(@44);
        }];

        [self.submitButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.and.width.equalTo(self.view);
            make.height.equalTo(@44);
            make.bottom.equalTo(self.view);
        }];

        self.didSetupConstraints = YES;
    }

    [super updateViewConstraints];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if (indexPath.row == 0) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        cell.textLabel.text = @"截图";
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else if (indexPath.row == 1) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        cell.textLabel.text = @"日志";
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (indexPath.row == 0) {
        
        cell.accessoryType = cell.accessoryType == UITableViewCellAccessoryCheckmark ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryCheckmark;
        
        //圈选截图
        {
            if (!_screenshotImage) {
                _screenshotImage = BugshotKit.sharedManager.annotatedImage ?: BugshotKit.sharedManager.snapshotImage;
            }
            
            BSKShotImageViewController *editScreenshotImageVC = [[BSKShotImageViewController alloc] init];
            
            editScreenshotImageVC.shotImage = _screenshotImage;
            
            [self.navigationController pushViewController:editScreenshotImageVC animated:YES];
        }
        
        
    } else if (indexPath.row == 1) {
        cell.accessoryType = cell.accessoryType == UITableViewCellAccessoryCheckmark ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryCheckmark;
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)dismissAction:(id)sender {
    [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:^{
        if (self.delegate) {
            [self.delegate bugshotViewControllerDidDismiss:self];
        }
    }];
}

- (void)sendAction:(id)sender {
    
    self.titleTextView.layer.borderColor = [UIColor grayColor].CGColor;
    if (self.titleTextView.text.length == 0) {
        self.titleTextView.layer.borderColor = [UIColor redColor].CGColor;
        return;
    }

    self.submitButton.enabled = NO;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    

    if (!_screenshotImage) {
        _screenshotImage = BugshotKit.sharedManager.annotatedImage ?: BugshotKit.sharedManager.snapshotImage;
    }
    

    NSString *appIdentifierString = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    NSString *appVersionString = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"];

    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *name = malloc(size);
    sysctlbyname("hw.machine", name, &size, NULL, 0);
    NSString *modelIdentifier = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
    free(name);

    // TODO add commit id
    NSDictionary *userInfo = @{
        @"appIdentifier" : appIdentifierString,
        @"appVersion" : appVersionString,
        @"systemVersion" : UIDevice.currentDevice.systemVersion,
        @"deviceModel" : modelIdentifier,
    };

    self.issue.title = self.titleTextView.text;
    self.issue.body = self.bodyTextView.text;

    NSString *levelTitle = [self.levelButton titleForState:UIControlStateNormal];
    if (levelTitle && ![levelTitle isEqualToString:@"选择"]) {
        self.issue.labels = @[@"bug", self.levels[levelTitle]];
    } else {
        self.issue.labels = @[@"bug"];
    }

    NSString *assigneeTitle = [self.assigneeButton titleForState:UIControlStateNormal];
    if (assigneeTitle) {
        if ([assigneeTitle isEqualToString:@"选择"]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                            message:@"请选[择责任人]"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            self.navigationItem.rightBarButtonItem.enabled = YES;
            return;
        } else {
            self.issue.assigneeId = self.assignees[assigneeTitle];
        }
    }

    self.issue.userInfo = userInfo;

    self.issue.screenshotImage = _screenshotImage;

    if (self.reporter) {
        [self.reporter submitIssue:self.issue withCompletion:^(NSError *error) {
            if (error) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提交失败"
                                                                message:@""
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            } else {
                [self dismissAction:nil];
            }
        }];
    }
}

- (void)levelAction:(id)sender {
    [self.levelActionSheet showInView:self.view];
}

- (void)assigneeAction:(id)sender {
    [self.assigneeActionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet == self.levelActionSheet) {
        NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
        [self.levelButton setTitle:buttonTitle forState:UIControlStateNormal];
    } else if (actionSheet == self.assigneeActionSheet) {
        NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
        [self.assigneeButton setTitle:buttonTitle forState:UIControlStateNormal];
    }
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [UITableView new];
        _tableView.scrollEnabled = NO;
        _tableView.dataSource = self;
        _tableView.delegate = self;
    }

    return _tableView;
}

- (OAStackView *)stackView {
    if (!_stackView) {
        _stackView = [OAStackView new];
        _stackView.axis = UILayoutConstraintAxisVertical;
        _stackView.alignment = OAStackViewAlignmentCenter;
        _stackView.distribution = OAStackViewDistributionEqualSpacing;
    }

    return _stackView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.text = @"标题：";
    }

    return _titleLabel;
}

- (UILabel *)bodyLabel {
    if (!_bodyLabel) {
        _bodyLabel = [UILabel new];
        _bodyLabel.text = @"描述：";
    }

    return _bodyLabel;
}

- (UILabel *)levelLabel {
    if (!_levelLabel) {
        _levelLabel = [UILabel new];
        _levelLabel.text = @"级别：";
    }

    return _levelLabel;
}

- (UILabel *)assigneeLabel {
    if (!_assigneeLabel) {
        _assigneeLabel = [UILabel new];
        _assigneeLabel.text = @"责任人：";
    }

    return _assigneeLabel;
}

- (UITextView *)titleTextView {
    if (!_titleTextView) {
        _titleTextView = [UITextView new];
        _titleTextView.layer.borderColor = [UIColor grayColor].CGColor;
        _titleTextView.layer.borderWidth = 1;
    }

    return _titleTextView;
}

- (UITextView *)bodyTextView {
    if (!_bodyTextView) {
        _bodyTextView = [UITextView new];
        _bodyTextView.layer.borderColor = [UIColor grayColor].CGColor;
        _bodyTextView.layer.borderWidth = 1;
    }

    return _bodyTextView;
}

- (UIButton *)levelButton {
    if (!_levelButton) {
        _levelButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_levelButton addTarget:self action:@selector(levelAction:) forControlEvents:UIControlEventTouchUpInside];
        [_levelButton setTitle:@"选择" forState:UIControlStateNormal];
    }

    return _levelButton;
}

- (UIButton *)assigneeButton {
    if (!_assigneeButton) {
        _assigneeButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_assigneeButton addTarget:self action:@selector(assigneeAction:) forControlEvents:UIControlEventTouchUpInside];
        [_assigneeButton setTitle:@"选择" forState:UIControlStateNormal];
    }

    return _assigneeButton;
}

- (UIActionSheet *)levelActionSheet {
    if (!_levelActionSheet) {
        _levelActionSheet = [UIActionSheet new];
        _levelActionSheet.delegate = self;
    }

    return _levelActionSheet;
}

- (UIActionSheet *)assigneeActionSheet {
    if (!_assigneeActionSheet) {
        _assigneeActionSheet = [UIActionSheet new];
        _assigneeActionSheet.delegate = self;
    }

    return _assigneeActionSheet;
}

- (UIButton *)submitButton {
    if (!_submitButton) {
        _submitButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_submitButton setTitle:@"提 交" forState:UIControlStateNormal];
        [_submitButton setBackgroundColor:[UIColor whiteColor]];
        [_submitButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [_submitButton addTarget:self action:@selector(sendAction:) forControlEvents:UIControlEventTouchUpInside];
    }

    return _submitButton;
}

- (BSKIssue *)issue {
    if (!_issue) {
        _issue = [[BSKIssue alloc] init];
    }

    return _issue;
}

@end

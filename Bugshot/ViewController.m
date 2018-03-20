//
//  ViewController.m
//  Bugshot
//
//  Created by Brooks on 2018/3/19.
//  Copyright © 2018年 Brooks. All rights reserved.
//

#import "ViewController.h"
#import "BugshotKit.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

}

- (IBAction)bugshotAction:(id)sender {
    [BugshotKit show];
}



@end

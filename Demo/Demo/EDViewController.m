/*
 Copyright 2012 LinkedIn, Inc.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "EDViewController.h"
#import "EDDetailViewController.h"

@interface EDViewController (Private)

- (void)setupDetailButton;
- (void)pushDetailViewController:(id)sender;

@end

@implementation EDViewController

- (void)loadView {
    [super loadView];
    self.view.backgroundColor = [UIColor redColor];
    
    // Optional button to demonstrate navigation stack
//    [self setupDetailButton];
}

- (void)setupDetailButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setTitle:NSLocalizedString(@"detail_button_title", @"detail_button_title")
            forState:UIControlStateNormal];
    [button sizeToFit];
    button.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
    button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|
    UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
    [button addTarget:self action:@selector(pushDetailViewController:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.toolbarHidden = YES;
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"expose_title", @"expose_title")
                                                                               style:UIBarButtonItemStyleBordered
                                                                              target:self.navigationController.exposeController
                                                                              action:@selector(toggleExpose)] autorelease];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"viewWillAppear:%d, %@", animated, self);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"viewDidAppear:%d, %@", animated, self);
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    NSLog(@"viewWillDisappear:%d, %@", animated, self);
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    NSLog(@"viewDidDisappear:%d, %@", animated, self);
}

- (void)viewWillShrinkInExposeController:(LIExposeController *)exposeController animated:(BOOL)animated {
    NSLog(@"viewWillShrinkInExposeController:%d, %@", animated, self);
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewDidShrinkInExposeController:(LIExposeController *)exposeController animated:(BOOL)animated {
    NSLog(@"viewDidShrinkInExposeController:%d, %@", animated, self);
}

- (void)viewWillExpandInExposeController:(LIExposeController *)exposeController animated:(BOOL)animated {
    NSLog(@"viewWillExpandInExposeController:%d, %@", animated, self);
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)viewDidExpandInExposeController:(LIExposeController *)exposeController animated:(BOOL)animated {
    NSLog(@"viewDidExpandInExposeController:%d, %@", animated, self);
}

- (void)pushDetailViewController:(id)sender {
    EDDetailViewController *detailViewController = [[[EDDetailViewController alloc] init] autorelease];
    [self.navigationController pushViewController:detailViewController animated:YES];
}

@end
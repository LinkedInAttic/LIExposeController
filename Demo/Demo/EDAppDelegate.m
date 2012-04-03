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

#import "EDAppDelegate.h"
#import "EDViewController.h"

NSString * const ADD_BUTTON_IMAGE = @"add.png";


@interface EDAppDelegate ()

- (UIViewController *)newViewControllerForExposeController:(LIExposeController *)exposeController;

@end

@implementation EDAppDelegate

static int _viewControllerId = 0;

@synthesize window=_window;

#pragma mark - LIExposeControllerDelegate Methods

- (BOOL)canAddViewControllersForExposeController:(LIExposeController *)exposeController {
    return YES;
}

- (BOOL)exposeController:(LIExposeController *)exposeController canDeleteViewController:(UIViewController *)viewController {
    return YES;
}

#pragma mark - LIExposeControllerDataSource Methods

- (UIView *)backgroundViewForExposeController:(LIExposeController *)exposeController {
    UIView *v = [[[UIView alloc] initWithFrame:CGRectMake(0, 
                                                          0, 
                                                          exposeController.view.frame.size.width, 
                                                          exposeController.view.frame.size.height)] autorelease];
    v.backgroundColor = [UIColor darkGrayColor];
    return v;
}

- (void)shouldAddViewControllerForExposeController:(LIExposeController *)exposeController {
    [exposeController addNewViewController:[self newViewControllerForExposeController:exposeController] 
                                  animated:YES];
}

- (UIView *)addViewForExposeController:(LIExposeController *)exposeController {
    UIView *addView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:ADD_BUTTON_IMAGE]] autorelease];
    return addView;
}

- (UIView *)exposeController:(LIExposeController *)exposeController overlayViewForViewController:(UIViewController *)viewController {
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        viewController = [(UINavigationController *)viewController topViewController];
    }
    if ([viewController isKindOfClass:[EDViewController class]]) {
        UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(0, 
                                                                    0, 
                                                                    viewController.view.bounds.size.width, 
                                                                    viewController.view.bounds.size.height)] autorelease];
        label.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
        label.text = viewController.title;
        label.textColor = [UIColor whiteColor];
        label.textAlignment = UITextAlignmentCenter;
        label.font = [UIFont boldSystemFontOfSize:48];
        label.adjustsFontSizeToFitWidth = YES;
        label.shadowColor = [UIColor blackColor];
        label.shadowOffset = CGSizeMake(1, 1);
        return label;
    } else {
        return nil;
    }
}

- (UILabel *)exposeController:(LIExposeController *)exposeController labelForViewController:(UIViewController *)viewController {
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        viewController = [(UINavigationController *)viewController topViewController];
    }
    if ([viewController isKindOfClass:[EDViewController class]]) {
        UILabel *label = [[[UILabel alloc] init] autorelease];
        label.backgroundColor = [UIColor clearColor];
        label.text = viewController.title;
        label.textColor = [UIColor whiteColor];
        label.textAlignment = UITextAlignmentCenter;
        label.font = [UIFont boldSystemFontOfSize:14];
        label.shadowColor = [UIColor blackColor];
        label.shadowOffset = CGSizeMake(1, 1);
        [label sizeToFit];
        CGRect frame = label.frame;
        frame.origin.y = 4;
        label.frame = frame;
        return label;
    } else {
        return nil;
    }
}

/**
 Optional Header View
 */
//- (UIView *)headerViewForExposeController:(LIExposeController *)exposeController {
//    UINavigationBar *headerBar = [[[UINavigationBar alloc] initWithFrame:CGRectMake(0, 
//                                                                                    0,
//                                                                                    exposeController.view.frame.size.width,
//                                                                                    44)] autorelease];
//    UILabel *titleView = [[[UILabel alloc] init] autorelease];
//    titleView.backgroundColor = [UIColor clearColor];
//    titleView.text = NSLocalizedString(@"expose_title", @"expose_title");
//    titleView.textColor = [UIColor whiteColor];
//    titleView.shadowColor = [UIColor darkGrayColor];
//    titleView.shadowOffset = CGSizeMake(0, -0.5);
//    titleView.userInteractionEnabled = YES;
//    titleView.font = [UIFont boldSystemFontOfSize:20];
//    [titleView sizeToFit];
//    UITapGestureRecognizer *exposeGesture = [[[UITapGestureRecognizer alloc] initWithTarget:exposeController action:@selector(toggleExpose)] autorelease];
//    [titleView addGestureRecognizer:exposeGesture];
//    UINavigationItem *navItem = [[[UINavigationItem alloc] init] autorelease];
//    navItem.titleView = titleView;
//    headerBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
//    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
//        headerBar.autoresizingMask |= UIViewAutoresizingFlexibleHeight;
//    }
//    headerBar.items = [NSArray arrayWithObject:navItem];
//    return headerBar;
//}

/**
 Optional Footer View
 */
//- (UIView *)footerViewForExposeController:(LIExposeController *)exposeController {
//    UIToolbar *toolBar = [[[UIToolbar alloc] initWithFrame:CGRectMake(0,
//                                                                      0,
//                                                                      exposeController.view.frame.size.width,
//                                                                      44)] autorelease];
//    toolBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
//    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
//        toolBar.autoresizingMask |= UIViewAutoresizingFlexibleHeight;
//    }
//    toolBar.items = [NSArray arrayWithObject:exposeController.editButtonItem];
//    return toolBar;
//}

#pragma mark - Helper Methods

- (UIViewController *)newViewControllerForExposeController:(LIExposeController *)exposeController {
    UIViewController *vc = [[[EDViewController alloc] init] autorelease];
    vc.title = [NSString stringWithFormat:NSLocalizedString(@"view_title_format_string", @"view_title_format_string"), _viewControllerId];
    _viewControllerId++;
    return [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
}

#pragma mark - UIApplicationDelegate Methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    LIExposeController *exposeController = [[[LIExposeController alloc] init] autorelease];
    exposeController.exposeDelegate = self;
    exposeController.exposeDataSource = self;
    exposeController.editing = YES;
    
    exposeController.viewControllers = [NSMutableArray arrayWithObjects:
                                        [self newViewControllerForExposeController:exposeController],
                                        [self newViewControllerForExposeController:exposeController],
                                        [self newViewControllerForExposeController:exposeController],
                                        nil];
    
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    self.window.rootViewController = exposeController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)dealloc
{
    [_window release];
    [super dealloc];
}

@end

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

/**
 
 Authors:
 Sudeep Yegnashankaran, Peter Shih
 
 Frameworks Required:
 1. UIKit
 2. Foundation
 3. QuartzCore
 4. CoreGraphics
 
 Instructions:
 1) Add LIExposeController.h and LIExposeController.m to your Xcode project.
 2) Create an instance like so: exposeController = [[LIExposeController alloc] init]
 3) Add your view controllers: exposeController.viewControllers = [NSArray arrayWithObjects:..., nil];
 4) Add expose controller to your view hierarchy: window.rootViewController = exposeController
 5) Enjoy!
 
 */

#import <UIKit/UIKit.h>

@protocol LIExposeControllerDelegate;
@protocol LIExposeControllerDataSource;
@protocol LIExposeControllerChildViewControllerDelegate;


@interface LIExposeController : UIViewController <UIGestureRecognizerDelegate, UIScrollViewDelegate>

/**
 Initialization and Setup Methods
 */
- (id)init;
@property (nonatomic, retain) NSMutableArray *viewControllers;
@property (nonatomic, assign) id<LIExposeControllerDelegate> exposeDelegate;
@property (nonatomic, assign) id<LIExposeControllerDataSource> exposeDataSource;

/**
 Display Configuration Methods
 */
@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, assign) CGFloat scaleFactor;
@property (nonatomic, assign) CGFloat rowOffset;
@property (nonatomic, assign) BOOL showsTouchDown;
@property (nonatomic, assign) CGFloat animationDuration;
@property (nonatomic, assign) NSUInteger numRows;
@property (nonatomic, assign) NSUInteger numCols;
- (void)setNumRows:(NSUInteger)numRows animated:(BOOL)animated;
- (void)setNumCols:(NSUInteger)numCols animated:(BOOL)animated;

/**
 Toggles Between the Expanded/Collapsed State for Expose
 */
- (void)toggleExpose;
- (void)toggleExpose:(BOOL)animated;

/**
 Adds a New View Controller to the List
 */
- (void)addNewViewController:(UIViewController *)viewController animated:(BOOL)animated;

/**
 Check the Current State
 */
@property (nonatomic, readonly) BOOL isZoomedOut;
@property (nonatomic, readonly) NSUInteger selectedIndex;
@property (nonatomic, readonly) UIViewController *selectedViewController;

/**
 Access the Header and Footer Views
 */
@property (nonatomic, readonly, retain) UIView *headerView;
@property (nonatomic, readonly, retain) UIView *footerView;

@end


/**
 Delegate Protocol for LIExposeController
 */
@protocol LIExposeControllerDelegate <NSObject>

@optional
- (BOOL)canAddViewControllersForExposeController:(LIExposeController *)exposeController;
- (void)shouldAddViewControllerForExposeController:(LIExposeController *)exposeController;
- (void)exposeControllerWillZoomOut:(LIExposeController *)exposeController animated:(BOOL)animated;
- (void)exposeControllerDidZoomOut:(LIExposeController *)exposeController animated:(BOOL)animated;
- (void)exposeControllerWillZoomIn:(LIExposeController *)exposeController animated:(BOOL)animated;
- (void)exposeControllerDidZoomIn:(LIExposeController *)exposeController animated:(BOOL)animated;
- (void)exposeController:(LIExposeController *)exposeController willSwitchFromViewController:(UIViewController *)oldViewController toViewController:(UIViewController *)newViewController;
- (void)exposeController:(LIExposeController *)exposeController didSelectViewController:(UIViewController *)viewController;
- (BOOL)exposeController:(LIExposeController *)exposeController canDeleteViewController:(UIViewController *)viewController;
- (void)exposeController:(LIExposeController *)exposeController didDeleteViewController:(UIViewController *)viewController atIndex:(NSUInteger)index;
@end


/**
 Data Source Protocol for LIExposeController
 */
@protocol LIExposeControllerDataSource <NSObject>

@optional
- (UIView *)headerViewForExposeController:(LIExposeController *)exposeController;
- (UIView *)footerViewForExposeController:(LIExposeController *)exposeController;
- (UIView *)backgroundViewForExposeController:(LIExposeController *)exposeController;
- (UIView *)addViewForExposeController:(LIExposeController *)exposeController;
- (UILabel *)exposeController:(LIExposeController *)exposeController labelForViewController:(UIViewController *)viewController;
- (UIView *)exposeController:(LIExposeController *)exposeController overlayViewForViewController:(UIViewController *)viewController;
@end


/**
 Delegate Protocol for Child Views of LIExposeController
 */
@protocol LIExposeControllerChildViewControllerDelegate <NSObject>

@optional
- (void)viewWillShrinkInExposeController:(LIExposeController *)exposeController animated:(BOOL)animated;
- (void)viewDidShrinkInExposeController:(LIExposeController *)exposeController animated:(BOOL)animated;
- (void)viewWillExpandInExposeController:(LIExposeController *)exposeController animated:(BOOL)animated;
- (void)viewDidExpandInExposeController:(LIExposeController *)exposeController animated:(BOOL)animated;
@end


/**
 Easy Access Property for View Controllers to Access a Parent Expose Controller
 */
@interface UIViewController (LIExposeController)

@property (nonatomic, readonly, retain) LIExposeController *exposeController;

@end

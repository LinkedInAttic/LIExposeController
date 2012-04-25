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

#import "LIExposeController.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

NSString * const DELETE_BUTTON_IMAGE = @"deleteBtn.png";


/**
 Methods are named this way to avoid potential conflicts with anyone else
 who may have created a category of UIView
 */
@interface UIView (Expose_Additions)

@property(nonatomic) CGFloat exposeLeft;
@property(nonatomic) CGFloat exposeTop;
@property(nonatomic,readonly) CGFloat exposeRight;
@property(nonatomic,readonly) CGFloat exposeBottom;
@property(nonatomic) CGFloat exposeWidth;
@property(nonatomic) CGFloat exposeHeight;

@end


@interface UIViewController (LIExposeController_Private)

@property (nonatomic, retain) LIExposeController *exposeController;

@end


@interface LIExposeController ()

/**
 Subviews
 */
@property (nonatomic, retain) UIView *headerView;
@property (nonatomic, retain) UIView *footerView;
@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) UIPageControl *pageControl;
@property (nonatomic, retain) UIView *addChildButton;
@property (nonatomic, retain) UIView *backgroundView;
// Element is a button/NSNull used to delete its respective child view controller
@property (nonatomic, retain) NSMutableArray *deleteButtons;
// Element is a view containing overlay, label and has a tap gesture
@property (nonatomic, retain) NSMutableArray *containerViews;

/**
 Current State
 */
@property (nonatomic, assign) BOOL isZoomedOut;
@property (nonatomic, assign) NSUInteger selectedIndex;
@property (nonatomic, assign) UIViewController *selectedViewController;
@property (nonatomic, readonly) UIViewController *selectedContentViewController;
@property (nonatomic, readonly) NSUInteger numPerPage;
@property (nonatomic, assign) NSUInteger currentPage;

/**
 Setting Up View Hierarchy
 */
- (void)setupContentView;
- (void)setupBackgroundView;
- (void)setupViewControllers;

/**
 Layout
 */
- (void)layoutGrid:(BOOL)animated completion:(void (^)(BOOL finished))completion;
- (void)calculateContentSize;
- (CGPoint)centerWithIndex:(NSUInteger)index;
- (void)setPage;
- (void)setExposeZoomedOut:(BOOL)zoomedOut animated:(BOOL)animated;

/**
 Helpers
 */
- (BOOL)isPad;
- (void)newViewController:(UIViewController *)viewController index:(NSUInteger)index;
+ (UIViewController *)getContentViewControllerFromContainer:(UIViewController *)containerViewController;
- (void)bounceView:(UIView *)view;

/**
 Gesture Actions
 */
- (void)toggleGestureRecognizer:(BOOL)toggle forView:(UIView *)view;
- (void)selectView:(UITapGestureRecognizer *)gestureRecognizer;
- (void)selectViewController:(UIViewController *)viewController;
- (void)selectViewControllerAtIndex:(NSUInteger)index;
- (void)addViewController:(UITapGestureRecognizer *)gestureRecognizer;
- (void)deleteViewController:(id)sender;
- (void)keepButtonHighlighted:(UIButton *)button;

/**
 Zooming Callbacks
 */
- (void)exposeZoomedOut:(BOOL)animated;
- (void)exposeZoomedIn:(BOOL)animated;

@end


@implementation LIExposeController

@synthesize viewControllers=_viewControllers;
@synthesize selectedIndex=_selectedIndex;
@synthesize exposeDelegate=_exposeDelegate;
@synthesize exposeDataSource=_exposeDataSource;
@synthesize isZoomedOut=_isZoomedOut;
@synthesize numRows=_numRows;
@synthesize numCols=_numCols;
@synthesize cornerRadius=_cornerRadius;
@synthesize scaleFactor=_scaleFactor;
@synthesize showsTouchDown=_showsTouchDown;
@synthesize animationDuration=_animationDuration;

@synthesize headerView=_headerView;
@synthesize footerView=_footerView;
@synthesize scrollView=_scrollView;
@synthesize pageControl=_pageControl;
@synthesize addChildButton=_addChildButton;
@synthesize backgroundView=_backgroundView;
@synthesize deleteButtons=_deleteButtons;
@synthesize selectedViewController=_selectedViewController;
@synthesize selectedContentViewController=_selectedContentViewController;
@synthesize rowOffset=_rowOffset;
@synthesize numPerPage=_numPerPage;
@synthesize currentPage=_currentPage;
@synthesize containerViews=_containerViews;

#pragma mark - Initialization/Deallocation Methods

- (id)init {
    self = [super init];
    if (self) {
        _deleteButtons = [[NSMutableArray array] retain];
        _containerViews = [[NSMutableArray array] retain];
        _viewControllers = nil;
        _selectedViewController = nil;
        _selectedContentViewController = nil;
        _selectedIndex = 0;
        _exposeDelegate = nil;
        _exposeDataSource = nil;
        _isZoomedOut = NO;
        _currentPage = 0;
        _cornerRadius = 20.0;
        _animationDuration = 0.3;
        if ([self isPad]) {
            _numRows = 3;
            _numCols = 3;
            _scaleFactor = 0.28;
            _rowOffset = -10.0;
        } else {
            _numRows = 2;
            _numCols = 2;
            _scaleFactor = 0.36;
            _rowOffset = -10.0;
        }
        _numPerPage = _numRows * _numCols;
    }
    return self;
}

- (void)dealloc {
    self.addChildButton = nil;
    self.headerView = nil;
    self.footerView = nil;
    self.scrollView = nil;
    self.pageControl = nil;
    self.backgroundView = nil;
    self.viewControllers = nil;
    self.deleteButtons = nil;
    self.containerViews = nil;
    
    [super dealloc];
}

#pragma mark - Setters

- (void)setViewControllers:(NSMutableArray *)controllers {
    // Clear Arrays
    NSUInteger index = 0;
    for (UIViewController *viewController in _viewControllers) {
        viewController.exposeController = nil;
        [viewController.view removeFromSuperview];
        [(UIView *)[self.containerViews objectAtIndex:index] removeFromSuperview];
        id deleteButton = [self.deleteButtons objectAtIndex:index];
        if (deleteButton != [NSNull null]) {
            [(UIView *)deleteButton removeFromSuperview];
        }
        index++;
    }
    [_viewControllers autorelease];
    [self.deleteButtons removeAllObjects];
    [self.containerViews removeAllObjects];
    
    _viewControllers = [controllers retain];
    self.selectedViewController = nil;
    self.selectedIndex = 0;
    if (_viewControllers.count > self.selectedIndex) {
        self.selectedViewController = [_viewControllers objectAtIndex:self.selectedIndex];
    }
    
    if ([self isViewLoaded]) {
        [self setupViewControllers];
        if (self.isZoomedOut) {
            [self layoutGrid:NO completion:nil];
        }
        [self setExposeZoomedOut:self.isZoomedOut animated:NO];
    }
}

- (void)setNumRows:(NSUInteger)rows {
    [self setNumRows:rows animated:NO];
}

- (void)setNumCols:(NSUInteger)cols {
    [self setNumCols:cols animated:NO];
}

- (void)setNumRows:(NSUInteger)rows animated:(BOOL)animated {
    _numRows = rows;
    _numPerPage = _numRows * _numCols;
    if (self.isZoomedOut) {
        [self layoutGrid:animated completion:nil];
    }
}

- (void)setNumCols:(NSUInteger)cols animated:(BOOL)animated {
    _numCols = cols;
    _numPerPage = _numRows * _numCols;
    if (self.isZoomedOut) {
        [self layoutGrid:animated completion:nil];
    }
}

- (void)setCornerRadius:(CGFloat)radius {
    _cornerRadius = radius;
    
    if ([self isViewLoaded]) {
        if (self.isZoomedOut) {
            for (UIViewController *viewController in self.viewControllers) {
                viewController.view.layer.cornerRadius = _cornerRadius;
            }
        }
        
        for (UIView *containerView in self.containerViews) {
            if (containerView.subviews.count) {
                ((UIView *)[containerView.subviews objectAtIndex:0]).layer.cornerRadius = _cornerRadius * self.scaleFactor;
            }
        }
    }
}

- (void)setScaleFactor:(CGFloat)scale {
    _scaleFactor = scale;
    
    if ([self isViewLoaded] && self.isZoomedOut) {
        self.addChildButton.transform = CGAffineTransformMakeScale(_scaleFactor, _scaleFactor);
        for (UIView *containerView in self.containerViews) {
            if (containerView.subviews.count) {
                ((UIView *)[containerView.subviews objectAtIndex:0]).layer.cornerRadius = _cornerRadius * self.scaleFactor;
            }
        }
        [self layoutGrid:NO completion:nil];
    }
}

- (void)setRowOffset:(CGFloat)offset {
    _rowOffset = offset;
    
    if ([self isViewLoaded] && self.isZoomedOut) {
        [self layoutGrid:NO completion:nil];
    }
}

#pragma mark - Getters

- (UIViewController *)selectedContentViewController {
    return [[self class] getContentViewControllerFromContainer:self.selectedViewController];
}

- (UIView *)addChildButton {
    if (!_addChildButton) {
        if ([self.exposeDelegate respondsToSelector:@selector(canAddViewControllersForExposeController:)]) {
            if ([self.exposeDelegate canAddViewControllersForExposeController:self]) {
                if ([self.exposeDataSource respondsToSelector:@selector(addViewForExposeController:)]) {
                    _addChildButton = [[self.exposeDataSource addViewForExposeController:self] retain];
                    _addChildButton.transform = CGAffineTransformMakeScale(self.scaleFactor, self.scaleFactor);
                    _addChildButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|
                    UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
                    _addChildButton.userInteractionEnabled = YES;
                    NSUInteger addIndex = self.viewControllers.count;
                    _addChildButton.center = [self centerWithIndex:addIndex];
                    
                    // Add gesture
                    UITapGestureRecognizer *addGesture = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(addViewController:)] autorelease];
                    addGesture.numberOfTapsRequired = 1;
                    [_addChildButton addGestureRecognizer:addGesture];
                }
            }
        }
    }
    return _addChildButton;
}

#pragma mark - View Hierarchy

- (void)loadView {
    [super loadView];
    self.view.autoresizingMask = ~UIViewAutoresizingNone;
    [self setupContentView];
    [self setupViewControllers];
    [self setupBackgroundView];
    [self layoutGrid:NO completion:nil];
    [self setExposeZoomedOut:NO animated:NO];
}

#pragma mark - View Setup

- (void)setupContentView {
    // Header View
    if ([self.exposeDataSource respondsToSelector:@selector(headerViewForExposeController:)]) {
        self.headerView = [self.exposeDataSource headerViewForExposeController:self];
        self.headerView.autoresizingMask |= UIViewAutoresizingFlexibleBottomMargin;
        [self.view addSubview:self.headerView];
    }

    // Footer View
    if ([self.exposeDataSource respondsToSelector:@selector(footerViewForExposeController:)]) {
        self.footerView = [self.exposeDataSource footerViewForExposeController:self];
        self.footerView.exposeTop = self.view.exposeHeight - self.footerView.exposeHeight;
        self.footerView.autoresizingMask |= UIViewAutoresizingFlexibleTopMargin;
        [self.view addSubview:self.footerView];
    }
    
    // Scroll View
    self.scrollView = [[[UIScrollView alloc] initWithFrame:CGRectMake(0, self.headerView.exposeHeight, self.view.exposeWidth, self.view.exposeHeight - self.headerView.exposeHeight - self.footerView.exposeHeight)] autorelease];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight|
                                       UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
    if (self.headerView.autoresizingMask & UIViewAutoresizingFlexibleHeight) {
        self.scrollView.autoresizingMask |= UIViewAutoresizingFlexibleTopMargin;
    }
    if (self.footerView.autoresizingMask & UIViewAutoresizingFlexibleHeight) {
        self.scrollView.autoresizingMask |= UIViewAutoresizingFlexibleBottomMargin;
    }
    self.scrollView.delegate = self;
    self.scrollView.scrollEnabled = NO;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.scrollsToTop = NO;
    self.scrollView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.scrollView];
    
    //Add page control
    self.pageControl = [[[UIPageControl alloc] init] autorelease];
    self.pageControl.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight|
                                        UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|
                                        UIViewAutoresizingFlexibleTopMargin;
    if (self.footerView.autoresizingMask & UIViewAutoresizingFlexibleHeight) {
        self.pageControl.autoresizingMask |= UIViewAutoresizingFlexibleBottomMargin;
    }
    self.pageControl.hidesForSinglePage = YES;
    self.pageControl.center = CGPointMake(floorf(self.view.exposeWidth / 2),
                                          self.scrollView.exposeBottom - 10);
    self.pageControl.alpha = 0.0;
    [self.view addSubview:self.pageControl];
    
    [self.scrollView addSubview:self.addChildButton]; 
}

- (void)setupBackgroundView {
    if ([self.exposeDataSource respondsToSelector:@selector(backgroundViewForExposeController:)]) {
        [self.backgroundView removeFromSuperview];
        self.backgroundView = [self.exposeDataSource backgroundViewForExposeController:self];
        self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [self.view insertSubview:self.backgroundView atIndex:0];
    }
}

- (void)setupViewControllers {
    NSUInteger i = 0;
    for (UIViewController *viewController in self.viewControllers) {
        [self newViewController:viewController index:i];
        i++;
    }
    
    [self calculateContentSize];
}

- (CGPoint)centerWithIndex:(NSUInteger)index {
    CGFloat page = index / self.numPerPage;
    CGFloat col = (index % self.numCols);
    CGFloat row = (index % self.numPerPage) / self.numCols;
    
    CGFloat left = 0;
    CGFloat top = 0;
    CGPoint c = CGPointZero;
    CGFloat width = floorf(self.scrollView.exposeWidth * self.scaleFactor);
    CGFloat height = floorf((self.scrollView.exposeHeight - self.pageControl.exposeHeight) * self.scaleFactor);
    CGFloat colSpacing = floorf((self.scrollView.exposeWidth - (self.numCols * width)) / (self.numCols + 1));
    CGFloat rowSpacing = floorf((self.scrollView.exposeHeight - (self.numRows * height)) / (self.numRows + 1));
    
    left = colSpacing + (col * colSpacing) + (col * width) + (page * self.scrollView.exposeWidth);
    top = rowSpacing + (row * rowSpacing) + (row * height) + self.rowOffset;
    c = CGPointMake(left + floorf(width / 2), top + floorf(height / 2));
    
    return c;
}

- (void)newViewController:(UIViewController *)viewController index:(NSUInteger)index {
    viewController.exposeController = self;
    
    // Real View
    viewController.view.frame = self.scrollView.bounds;
    viewController.view.autoresizingMask = ~UIViewAutoresizingNone;
    
    // Apply Transforms to real view
    CGPoint c = [self centerWithIndex:index];
    
    CGFloat tx = c.x - viewController.view.center.x;
    CGFloat ty = c.y - viewController.view.center.y;
    CGAffineTransform t = CGAffineTransformMakeTranslation(tx, ty);
    t = CGAffineTransformScale(t, self.scaleFactor, self.scaleFactor);
    viewController.view.transform = t;
    [self.scrollView addSubview:viewController.view];
    
    // Add container view
    UIView *containerView = [[[UIView alloc] initWithFrame:viewController.view.bounds] autorelease];
    containerView.autoresizingMask = viewController.view.autoresizingMask;
    containerView.clipsToBounds = NO;
    containerView.frame = viewController.view.frame;
    containerView.alpha = self.editing ? 1.0 : 0.0;
    [self.containerViews addObject:containerView];
    [self.scrollView addSubview:containerView];
    
    // Tap to select gesture
    UITapGestureRecognizer *selectGesture = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectView:)] autorelease];
    selectGesture.enabled = NO;
    selectGesture.delegate = self;
    [containerView addGestureRecognizer:selectGesture];
    
    // Optional Overlay View
    if ([self.exposeDataSource respondsToSelector:@selector(exposeController:overlayViewForViewController:)]) {
        UIView *overlayView = [self.exposeDataSource exposeController:self overlayViewForViewController:viewController];
        overlayView.autoresizingMask = containerView.autoresizingMask;
        overlayView.layer.cornerRadius = self.cornerRadius * self.scaleFactor;
        overlayView.frame = containerView.bounds;
        [containerView addSubview:overlayView];
    }
    
    // Optional Label
    if ([self.exposeDataSource respondsToSelector:@selector(exposeController:labelForViewController:)]) {
        UILabel *label = [self.exposeDataSource exposeController:self labelForViewController:viewController];
        label.autoresizingMask |= UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin|
                                  UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|
                                  UIViewAutoresizingFlexibleHeight;
        label.frame = CGRectMake((containerView.exposeWidth - label.exposeWidth) / 2, containerView.exposeHeight + label.exposeTop, label.exposeWidth, label.exposeHeight);
        [containerView addSubview:label];
    }
    
    // Add delete buttons (optional)
    if ([self.exposeDelegate respondsToSelector:@selector(exposeController:canDeleteViewController:)] &&
        [self.exposeDelegate exposeController:self canDeleteViewController:viewController]) {
        UIImage *deleteImage = [UIImage imageNamed:DELETE_BUTTON_IMAGE];
        UIButton *deleteBtn = [[[UIButton alloc] initWithFrame:CGRectMake(containerView.exposeLeft - floorf(deleteImage.size.width / 2),
                                                                          containerView.exposeTop - floorf(deleteImage.size.height / 2),
                                                                          deleteImage.size.width,
                                                                          deleteImage.size.height)] autorelease];
        [deleteBtn setImage:deleteImage forState:UIControlStateNormal];
        [deleteBtn addTarget:self action:@selector(deleteViewController:) forControlEvents:UIControlEventTouchUpInside];
        deleteBtn.hidden = !self.editing;
        deleteBtn.autoresizingMask = UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleLeftMargin|
        UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleTopMargin;
        [self.scrollView addSubview:deleteBtn];
        [self.deleteButtons addObject:deleteBtn];
    }
    else {
        [self.deleteButtons addObject:[NSNull null]];
    }
}

#pragma mark - Select

- (void)selectView:(UITapGestureRecognizer *)gestureRecognizer {
    NSUInteger index = [self.containerViews indexOfObject:gestureRecognizer.view];
    [self selectViewControllerAtIndex:index];
}

- (void)selectViewController:(UIViewController *)viewController {
    NSUInteger index = [self.viewControllers indexOfObject:viewController];
    [self selectViewControllerAtIndex:index];
}

- (void)selectViewControllerAtIndex:(NSUInteger)index {
    UIViewController *oldViewController = self.selectedViewController;
    self.selectedIndex = index;
    self.selectedViewController = [self.viewControllers objectAtIndex:self.selectedIndex];
    
    // Will Switch Callback
    if ([self.exposeDelegate respondsToSelector:@selector(exposeController:willSwitchFromViewController:toViewController:)]) {
        [self.exposeDelegate exposeController:self
                 willSwitchFromViewController:oldViewController
                             toViewController:self.selectedViewController];
    }
    
    [self toggleExpose:YES]; // This will collapse spaces
}

#pragma mark - Add a new view controller

- (void)addViewController:(id)sender {
    if ([self.exposeDelegate respondsToSelector:@selector(shouldAddViewControllerForExposeController:)]) {
        [self.exposeDelegate shouldAddViewControllerForExposeController:self];
    }
}

- (void)addNewViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [self.viewControllers addObject:viewController];
    
    NSUInteger i = self.viewControllers.count - 1;
    [self newViewController:viewController index:i];
    [self toggleGestureRecognizer:YES forView:self.containerViews.lastObject];
    [self layoutGrid:animated completion:nil];
}

#pragma mark - Delete a view controller

- (void)keepButtonHighlighted:(UIButton *)button {
    button.highlighted = YES;
    button.selected = YES;
}

- (void)deleteViewController:(id)sender {
    if (![sender isKindOfClass:[UIButton class]]) {
        return;
    }
    
    UIButton *button = (UIButton *)sender;
    [self performSelector:@selector(keepButtonHighlighted:) withObject:button afterDelay:0];
    NSUInteger deleteIndex = [self.deleteButtons indexOfObject:button];
    UIViewController *viewController = [self.viewControllers objectAtIndex:deleteIndex];
    UIView *containerView = [self.containerViews objectAtIndex:deleteIndex];
    
    [UIView animateWithDuration:self.animationDuration
                     animations:^{
                         viewController.view.alpha = 0.0;
                         containerView.alpha = 0.0;
                         button.alpha = 0.0;
                     }
                     completion:^(BOOL finished) {
                         if ([self.exposeDelegate respondsToSelector:@selector(exposeController:didDeleteViewController:atIndex:)]) {
                             [self.exposeDelegate exposeController:self didDeleteViewController:viewController atIndex:deleteIndex];
                         }
                         
                         [viewController.view removeFromSuperview];
                         [containerView removeFromSuperview];
                         [button removeFromSuperview];
                         viewController.exposeController = nil;
                         [self.viewControllers removeObject:viewController];
                         [self.deleteButtons removeObject:button];
                         [self.containerViews removeObject:containerView];
                         
                         if ([viewController isEqual:self.selectedViewController]) {
                             self.selectedViewController = nil;
                             self.selectedIndex = 0;
                             if (self.viewControllers.count > self.selectedIndex) {
                                 self.selectedViewController = [self.viewControllers objectAtIndex:self.selectedIndex];
                             }
                         }
                         
                         [self layoutGrid:YES completion:nil];
                     }];  
}

#pragma mark - Expose

- (void)toggleExpose {
    [self toggleExpose:YES];
}

- (void)toggleExpose:(BOOL)animated {
    [self setExposeZoomedOut:!self.isZoomedOut animated:animated];
}

- (void)setExposeZoomedOut:(BOOL)zoomedOut animated:(BOOL)animated {
    CGFloat animateDuration = animated ? self.animationDuration : 0.0;
    self.isZoomedOut = zoomedOut;
    
    if (self.isZoomedOut) {
        // Will Shrink Callback
        if ([self.selectedContentViewController conformsToProtocol:@protocol(LIExposeControllerChildViewControllerDelegate)] &&
            [self.selectedContentViewController respondsToSelector:@selector(viewWillShrinkInExposeController:animated:)]) {
            [(id<LIExposeControllerChildViewControllerDelegate>)self.selectedContentViewController viewWillShrinkInExposeController:self animated:animated];
        }
        
        self.pageControl.alpha = 1.0;
        
        // Will Zoom Out Callback
        if ([self.exposeDelegate respondsToSelector:@selector(exposeControllerWillZoomOut:animated:)]) {
            [self.exposeDelegate exposeControllerWillZoomOut:self animated:animated];
        }
        
        // Will Appear Callback
        for (NSUInteger i = 0; i < self.viewControllers.count; i++) {
            if (i != self.selectedIndex) {
                UIViewController *vc = [self.viewControllers objectAtIndex:i];
                [vc viewWillAppear:animated];
                [self.scrollView sendSubviewToBack:vc.view];
            }
        }
        
        // Perform Frame Adjustment
        [self layoutGrid:animated completion:^(BOOL finished) {
            [self exposeZoomedOut:animated];
        }];
        
    } else {
        // Will Expand Callback
        if ([self.selectedContentViewController conformsToProtocol:@protocol(LIExposeControllerChildViewControllerDelegate)] &&
            [self.selectedContentViewController respondsToSelector:@selector(viewWillExpandInExposeController:animated:)]) {
            [(id<LIExposeControllerChildViewControllerDelegate>)self.selectedContentViewController viewWillExpandInExposeController:self animated:animated];
        }
        
        self.pageControl.alpha = 0;
        
        // Bring the selected view to the top of the stack
        [self.scrollView bringSubviewToFront:self.selectedViewController.view];
        
        // Will Zoom In Callback
        if ([self.exposeDelegate respondsToSelector:@selector(exposeControllerWillZoomIn:animated:)]) {
            [self.exposeDelegate exposeControllerWillZoomIn:self animated:animated];
        }
        
        // Perform Frame Adjustment
        int i = 0;
        for (UIViewController *viewController in self.viewControllers) {
            UIView *containerView = [self.containerViews objectAtIndex:i];
            UIButton *deleteButton = nil;
            if (self.deleteButtons.count > 0) {
                if ([self.deleteButtons objectAtIndex:i] != [NSNull null]) {
                    deleteButton = [self.deleteButtons objectAtIndex:i];
                }
            }
            
            // Will Disappear Callback
            if (![viewController isEqual:self.selectedViewController]) {
                [viewController viewWillDisappear:animated];
            }
            
            // Animate (optional)
            [UIView animateWithDuration:animateDuration
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 containerView.alpha = 0.0;
                                 deleteButton.alpha = 0.0;
                                 
                                 if ([viewController isEqual:self.selectedViewController]) {
                                     viewController.view.transform = CGAffineTransformIdentity;
                                     viewController.view.layer.cornerRadius = 0;
                                     viewController.view.frame = CGRectMake(self.pageControl.currentPage * self.scrollView.exposeWidth, 0, self.scrollView.exposeWidth, self.scrollView.exposeHeight);
                                 } else {
                                     viewController.view.alpha = 0.0;
                                 }
                             }
                             completion:^(BOOL finished) {
                                 self.scrollView.scrollEnabled = NO;
                                 if ([viewController isEqual:self.selectedViewController]) {
                                     [self exposeZoomedIn:animated];
                                 } else {
                                     [viewController viewDidDisappear:animated];
                                 }
                             }];
            i++;
        }
        
        // Did Select Callback
        if ([self.exposeDelegate respondsToSelector:@selector(exposeController:didSelectViewController:)]) {
            [self.exposeDelegate exposeController:self didSelectViewController:self.selectedViewController];
        }
    }
}

- (void)calculateContentSize {
    NSInteger numPages = (NSInteger)ceilf((CGFloat)self.viewControllers.count / self.numPerPage);
    if ([self.exposeDelegate respondsToSelector:@selector(canAddViewControllersForExposeController:)]) {
        if ([self.exposeDelegate canAddViewControllersForExposeController:self]) {
            numPages = (NSInteger)ceilf((CGFloat)(self.viewControllers.count + 1) / self.numPerPage);
        }
    }
    
    self.scrollView.contentSize = CGSizeMake(self.scrollView.exposeWidth * numPages, self.scrollView.exposeHeight);
    self.pageControl.numberOfPages = numPages;
}

- (void)layoutGrid:(BOOL)animated completion:(void (^)(BOOL finished))completion {
    CGFloat animateDuration = animated ? self.animationDuration : 0.0;
    
    // This is the currently selected view
    NSUInteger i = 0;
    for (UIViewController *viewController in self.viewControllers) {
        // Real View
        [viewController.view endEditing:YES];
        
        // Container View
        UIView *containerView = [self.containerViews objectAtIndex:i];
        [self.scrollView bringSubviewToFront:containerView];
        
        // Delete Button
        UIButton *deleteButton = nil;
        if (self.deleteButtons.count > 0) {
            if ([self.deleteButtons objectAtIndex:i] != [NSNull null]) {
                deleteButton = [self.deleteButtons objectAtIndex:i];
                [self.scrollView bringSubviewToFront:deleteButton];
            }
        }
        
        // Layout the grid
        CGPoint c = [self centerWithIndex:i];
        
        CGFloat tx = c.x - floorf(viewController.view.center.x);
        CGFloat ty = c.y - floorf(viewController.view.center.y);
        
        // Animate (optional)      
        [UIView animateWithDuration:animateDuration
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             // Transforms
                             CGAffineTransform t = CGAffineTransformMakeTranslation(tx, ty);
                             t = CGAffineTransformScale(t, self.scaleFactor, self.scaleFactor);
                             viewController.view.transform = t;
                             viewController.view.layer.masksToBounds = YES;
                             viewController.view.layer.cornerRadius = self.cornerRadius;
                             
                             viewController.view.alpha = 1.0;
                             containerView.alpha = 1.0;
                             containerView.frame = viewController.view.frame;
                             if (deleteButton) {
                                 deleteButton.alpha = 1.0;
                                 deleteButton.center = containerView.frame.origin;
                             }
                         }
                         completion:^(BOOL finished) {
                             self.scrollView.scrollEnabled = YES;
                             if ([viewController isEqual:self.selectedViewController]) {
                                 if (completion) {
                                     completion(finished);
                                 }
                             }
                         }];
        i++;
    }
    
    // Show Add View
    [self.scrollView bringSubviewToFront:self.addChildButton];
    
    // Adjust addChildButton position and frame
    NSUInteger addIndex = self.viewControllers.count;
    CGPoint c = [self centerWithIndex:addIndex];
    
    [UIView animateWithDuration:animateDuration
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.addChildButton.center = c;
                     }
                     completion:nil];
    
    // Recalculate content size
    [self calculateContentSize];
}

#pragma mark - Editing

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    for (id deleteButton in self.deleteButtons) {
        if ([deleteButton isKindOfClass:[UIButton class]]) {
            ((UIButton *)deleteButton).hidden = !editing;
        }
    }
}

#pragma mark - Gesture Recognizers

- (void)toggleGestureRecognizer:(BOOL)toggle forView:(UIView *)view {
    ((UIGestureRecognizer *)[view.gestureRecognizers objectAtIndex:0]).enabled = toggle;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if(self.showsTouchDown && self.isZoomedOut && ![gestureRecognizer.view isKindOfClass:[UIImageView class]]) {
        NSUInteger index = [self.containerViews indexOfObject:gestureRecognizer.view];
        [self bounceView:((UIViewController *)[self.viewControllers objectAtIndex:index]).view];
    }
    
    if ([touch.view isKindOfClass:[UIButton class]]) {
        return NO;
    }
    else {
        return YES;
    }
}

#pragma mark - Animations

- (void)exposeZoomedOut:(BOOL)animated {
    for (UIView *view in self.containerViews) {
        [self toggleGestureRecognizer:YES forView:view];
    }
    [self bounceView:self.selectedViewController.view];
    if ([self.selectedContentViewController conformsToProtocol:@protocol(LIExposeControllerChildViewControllerDelegate)] &&
        [self.selectedContentViewController respondsToSelector:@selector(viewDidShrinkInExposeController:animated:)]) {
        [(id<LIExposeControllerChildViewControllerDelegate>)self.selectedContentViewController viewDidShrinkInExposeController:self animated:animated];
    }
    
    if ([self.exposeDelegate respondsToSelector:@selector(exposeControllerDidZoomOut:animated:)]) {
        [self.exposeDelegate exposeControllerDidZoomOut:self animated:animated];
    }
    
    for (UIViewController *viewController in self.viewControllers) {
        if (![viewController isEqual:self.selectedViewController]) {
            [viewController viewDidAppear:animated];
        }
    }
}

- (void)exposeZoomedIn:(BOOL)animated {
    for (UIView *view in self.containerViews) {
        [self toggleGestureRecognizer:NO forView:view];
    }
    self.selectedViewController.view.layer.masksToBounds = YES;
    if ([self.selectedContentViewController conformsToProtocol:@protocol(LIExposeControllerChildViewControllerDelegate)] &&
        [self.selectedContentViewController respondsToSelector:@selector(viewDidExpandInExposeController:animated:)]) {
        [(id<LIExposeControllerChildViewControllerDelegate>)self.selectedContentViewController viewDidExpandInExposeController:self animated:animated];
    }
    
    if ([self.exposeDelegate respondsToSelector:@selector(exposeControllerDidZoomIn:animated:)]) {
        [self.exposeDelegate exposeControllerDidZoomIn:self animated:animated];
    }
}

#pragma mark - Rotation Methods

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    BOOL shouldRotate = YES;
    for (UIViewController *viewController in self.viewControllers) {
        shouldRotate &= [viewController shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
    }
    return shouldRotate;
}

- (void)willAnimateFirstHalfOfRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willAnimateFirstHalfOfRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    for (UIViewController *viewController in self.viewControllers) {
        [viewController willAnimateFirstHalfOfRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    }
}

- (void)willAnimateSecondHalfOfRotationFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willAnimateSecondHalfOfRotationFromInterfaceOrientation:fromInterfaceOrientation duration:duration];
    for (UIViewController *viewController in self.viewControllers) {
        [viewController willAnimateSecondHalfOfRotationFromInterfaceOrientation:fromInterfaceOrientation duration:duration];
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    for (UIViewController *viewController in self.viewControllers) {
        [viewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    }
    
    if (self.isZoomedOut) {
        [self layoutGrid:YES completion:nil];
    }
    self.scrollView.contentOffset = CGPointMake(self.scrollView.exposeWidth * self.currentPage, 0);
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    for (UIViewController *viewController in self.viewControllers) {
        [viewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    }
    
    self.currentPage = self.scrollView.contentOffset.x / self.scrollView.exposeWidth;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    for (UIViewController *viewController in self.viewControllers) {
        [viewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    }
    
    [self calculateContentSize];
}

#pragma mark - UIScrollViewDelegate Methods

- (void)setPage {
    NSInteger page = (self.scrollView.contentOffset.x + floorf(self.scrollView.exposeWidth / 2)) / self.scrollView.exposeWidth;
    self.pageControl.currentPage = page;
}

- (void)scrollViewDidScroll:(UIScrollView *)scroller {
    if ([scroller isEqual:self.scrollView]) {
        [self setPage];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scroller {
    if ([scroller isEqual:self.scrollView]) {
        [self setPage];
    }
}

#pragma mark - Helpers Methods

- (BOOL)isPad {
    return ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
}

+ (UIViewController *)getContentViewControllerFromContainer:(UIViewController *)containerViewController {
    if ([containerViewController isKindOfClass:[UINavigationController class]]) {
        return [(UINavigationController *)containerViewController topViewController];
    } else if ([containerViewController isKindOfClass:[UITabBarController class]]) {
        return [(UITabBarController *)containerViewController selectedViewController];
    } else {
        return containerViewController;
    }
}

- (void)bounceView:(UIView *)view {
    CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    bounceAnimation.values = [NSArray arrayWithObjects:
                              [NSNumber numberWithFloat:self.scaleFactor],
                              [NSNumber numberWithFloat:self.scaleFactor-0.02],
                              [NSNumber numberWithFloat:self.scaleFactor],
                              nil];
    bounceAnimation.duration = self.animationDuration;
    bounceAnimation.removedOnCompletion = NO;
    [view.layer addAnimation:bounceAnimation forKey:@"bounce"];
}

@end


#pragma mark - UIView+Additions

@implementation UIView (Expose_Additions)

- (CGFloat)exposeLeft {
    return self.frame.origin.x;
}

- (void)setExposeLeft:(CGFloat)x {
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
}

- (CGFloat)exposeTop {
    return self.frame.origin.y;
}

- (void)setExposeTop:(CGFloat)y {
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
}

- (CGFloat)exposeRight {
    return self.frame.origin.x + self.frame.size.width;
}

- (CGFloat)exposeBottom {
    return self.frame.origin.y + self.frame.size.height;
}

- (CGFloat)exposeWidth {
    return self.frame.size.width;
}

- (void)setExposeWidth:(CGFloat)width {
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}

- (CGFloat)exposeHeight {
    return self.frame.size.height;
}

- (void)setExposeHeight:(CGFloat)height {
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}

@end


#pragma mark - UIViewController+LIExposeController

@implementation UIViewController (LIExposeController)

NSString const * kExposeController = @"exposeController";

- (LIExposeController *)exposeController {
    return (LIExposeController *)objc_getAssociatedObject(self, kExposeController);
}

- (void)setExposeController:(LIExposeController *)exposeController {
    objc_setAssociatedObject(self, kExposeController, exposeController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

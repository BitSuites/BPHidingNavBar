//
//  BPHidingNavBar.m
//
//  Copyright (c) 2013 BitSuites, LLC. All rights reserved.
//

#import "BPHidingNavBar.h"

@interface BPHidingNavBar() {
    CGFloat lastOffset;
    BOOL checkedBackButton;
    BOOL checkStartedScrolling;
    BOOL showingBack;
    CGFloat lastHeight;
    CGFloat scrollOffsets;
    CGFloat percentShowing;
    BOOL updatingOffset;
    
    CGFloat startedScollPoint;
    BOOL holdScrolling;
    
    BOOL adjustingScrollFrame;
}

@end

@implementation BPHidingNavBar

- (id)init {
    self = [super init];
    if (self) {
        [self initSetup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initSetup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initSetup];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    @try {
        [self.associatedScrollView removeObserver:self forKeyPath:@"contentOffset"];
        [self.associatedScrollView removeObserver:self forKeyPath:@"frame"];
    } @catch (id anException) {
        //do nothing, the scroll view does not have that observer
    }
}

/**
 Initalize the values and listeners for the nav bar.
 */
- (void)initSetup {
    // Set inital values for variables.
    updatingOffset = NO;
    self.holdUpdates = NO;
    checkStartedScrolling = NO;
    adjustingScrollFrame = NO;
    self.scrollHoldPercent = 0.2;
    
    // Add Observer for when we rotate the sceen
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(orientationChanged)  name:UIDeviceOrientationDidChangeNotification  object:nil];
}

#pragma mark - User Methods

/**
 Setup the nav bar listing to the specified scroll view.

 @param associatedScrollView UIScrollView that we are linking to the navbar.
 */
- (void)setupNavBarWithAssiciatedScrollView:(UIScrollView *)associatedScrollView {
    // Animate the nav bar to be showing again if we are setting up the scroll since scroll content should be at the top.
    [UIView animateWithDuration:0.3 animations:^{
        CGRect currentFrame = self.frame;
        currentFrame.origin.y = [UIApplication sharedApplication].statusBarFrame.size.height;
        self.frame = currentFrame;
        self->percentShowing = 1.0;
        // Fixes issue if controller is nil when going back sliding
        if (!associatedScrollView) {
            [self updateViewAlpha];
        }
    }];
    
    // Add Listeners for the scroll view.
    [self setAssociatedScrollView:associatedScrollView];
    
    // Reset variables for new scroll view.
    checkStartedScrolling = NO;
    checkedBackButton = NO;
}

/**
 Setup the nav bar listing to the specified scroll view and determining if the content will be allowed behind the nav bar.

 @param associatedScrollView UIScrollView that we are linking to the navbar.
 @param contentBehind Bool as to wether the content will extend behind the nav bar or not.
 */
- (void)setupNavBarWithAssiciatedScrollView:(UIScrollView *)associatedScrollView contentBehindNav:(BOOL)contentBehind {
    self.allowContentBehind = contentBehind;
    [self setupNavBarWithAssiciatedScrollView:associatedScrollView];
}

/**
 Sets the scroll view that we are listing to for changes in the position to update the navbar.

 @param associatedScrollView UIScrollView that we are linking to the navbar.
 */
- (void)setAssociatedScrollView:(UIScrollView *)associatedScrollView {
    BOOL trackFrame = NO;
    if (!self.translucent) {
        // Extra steps that need to be performed if the navbar is not translucent.
        // In order to keep the scroll view showing full screen when hiding the nav bar we need to adjust the constraints
        // while animating the nav bar change so there is no dead space.
        UIView *mainView = associatedScrollView;
        if ([[mainView superview] isKindOfClass:[UIWebView class]]) {
            mainView = [mainView superview];
        }
        NSArray *constraints = [[mainView superview] constraints];
        CGFloat adjustAmount = self.frame.size.height + [self statusBarHeight];
        if ([constraints count] <= 0) {
            // There are no constrainsts for the view so mark that we need to manually handle the changing of the size.
            trackFrame = YES;
            if (mainView.frame.origin.y == adjustAmount) {
                [self performSelector:@selector(adjustScrollFrame) withObject:nil afterDelay:0.0];
            }
        } else {
            // Find the constraint for the top of the scroll view and adjust it accordingly based on nav bar visibility.
            for (NSLayoutConstraint *nextConstraint in constraints) {
                if ([nextConstraint firstItem] == mainView || [nextConstraint secondItem] == mainView) {
                    if ([nextConstraint firstItem] == mainView) {
                        if ([nextConstraint firstAttribute] != NSLayoutAttributeTop) {
                            continue;
                        }
                    } else {
                        if ([nextConstraint secondAttribute] != NSLayoutAttributeTop) {
                            continue;
                        }
                    }
                    // We are in the top constraint of scroll view
                    if ([nextConstraint constant] == 0) {
                        [nextConstraint setConstant:-adjustAmount];
                    }
                }
            }
        }
    }
    
    if (self.associatedScrollView) {
        // Remove any observers on the current scroll view.
        @try {
            [self.associatedScrollView removeObserver:self forKeyPath:@"contentOffset"];
            [self.associatedScrollView removeObserver:self forKeyPath:@"frame"];
        } @catch (id anException) {
            //do nothing, the scroll view does not have that observer
        }
        _associatedScrollView = nil;
    }
    
    // Add observers for the new scroll view.
    _associatedScrollView = associatedScrollView;
    if (self.associatedScrollView) {
        [self updateScrollInsetRotation:NO];
        [self.associatedScrollView addObserver:self forKeyPath:@"contentOffset" options:0 context:NULL];
        if (trackFrame) {
            [self.associatedScrollView addObserver:self forKeyPath:@"frame" options:0 context:NULL];
        }
    }
    
    // Get the current offset of the scroll view so we can start listing for changes.
    dispatch_async(dispatch_get_main_queue(), ^{
        self->lastOffset = associatedScrollView.contentOffset.y;
    });
}

/**
 Adjust the scroll view frame so that it is fully showing when hiding the nav bar.
 */
- (void)adjustScrollFrame {
    // Calculate the new frame based on the adjust amount.
    CGFloat adjustAmount = self.frame.size.height + [self statusBarHeight];
    CGRect currentFrame = [self.associatedScrollView frame];
    currentFrame.origin.y = currentFrame.origin.y - adjustAmount;
    currentFrame.size.height = currentFrame.size.height + adjustAmount;
    
    // Mark that we are adjusting the scroll frame so we don't get into a loop.
    adjustingScrollFrame = YES;
    
    [self.associatedScrollView setFrame:currentFrame];
    
    // Mark that we are finished adjusting the scroll view so we can update again if necessary.
    adjustingScrollFrame = NO;
}

/**
 Shows the nav bar animating.
 */
- (void)showFullNavBar {
    [self showFullNavBarAnimated:YES];
}

/**
 Shows the nav bar animating based on paramater.

 @param animated BOOL if we should animate the change or not.
 */
- (void)showFullNavBarAnimated:(BOOL)animated {
    [UIView animateWithDuration:(animated ? 0.3 : 0.0) animations:^{
        CGRect currentFrame = self.frame;
        currentFrame.origin.y = [UIApplication sharedApplication].statusBarFrame.size.height;
        self.frame = currentFrame;
        self->percentShowing = 1.0;
        [self updateViewAlpha];
    } completion:^(BOOL finished) {
        self->lastOffset = self.associatedScrollView.contentOffset.y;
    }];
}

#pragma mark - Local Methdos

/**
 Check to see if the app is running iOS 11 or greater.

 @return BOOL if the app is running iOS 11 or greater.
 */
- (BOOL)isIOS11Greater {
    if (@available(iOS 11, *)) {
        return YES;
    }
    return NO;
}

/**
 Check to see if the provided view is the back button view.

 @param possibleView UIView we are checking to see if it is the back button.
 @return BOOL if the view is the back button or not.
 */
- (BOOL)isBackButtonView:(UIView *)possibleView {
    return [NSStringFromClass([possibleView class]) rangeOfString:@"Back"].location != NSNotFound && [NSStringFromClass([possibleView class]) rangeOfString:@"Background"].location == NSNotFound;
}

/**
 Check to see if the provided view is the background view.
 
 @param possibleView UIView we are checking to see if it is the background view.
 @return BOOL if the view is the background view or not.
 */
- (BOOL)isBackgroundView:(UIView *)possibleView {
    return [NSStringFromClass([possibleView class]) rangeOfString:@"Background"].location != NSNotFound;
}

/**
 Updates the scroll views offset based on the nav bar visibility.

 @param rotation BOOL if this is being called when the device has rotated or not.
 */
- (void)updateScrollInsetRotation:(BOOL)rotation {
    // Get the inital height onad offset on the navbar.
    lastHeight = self.frame.size.height;
    scrollOffsets = self.frame.size.height + [self statusBarHeight];
    if (![self isIOS11Greater]) {
        // In iOS 11 this offset has to be 0 since apple changed something.
        scrollOffsets = 0;
    }
    
    // If we have a scroll view update it.
    if (self.associatedScrollView) {
        // Mark that we are updating so we don't get into a loop with the observer.
        updatingOffset = YES;
        
        // Get the new top offset.
        CGFloat top = lastHeight + [self statusBarHeight];
        if ([self isIOS11Greater]) {
            top = 0.0;
            [self updateScrollInsetsWithTopOffset:scrollOffsets];
        } else {
            [self updateScrollInsetsWithTopOffset:top];
        }
        
        // Determine if this is the first load and what the start offset is.
        BOOL firstLoad = self.associatedScrollView.scrollIndicatorInsets.top < top;
        CGPoint startOffest = self.associatedScrollView.contentOffset;
        
        // Should only add the top on the first time it is loaded or the offest begins to go beyond the bar
        if (startOffest.y <= 0 && startOffest.y > -top && !rotation && firstLoad) {
            [self.associatedScrollView setContentOffset:CGPointMake(startOffest.x, (-top + startOffest.y))];
        } else {
            [self.associatedScrollView setContentOffset:startOffest];
        }
        
        // Mark that we finished updating so we can see changes again.
        updatingOffset = NO;
    }
}

/**
 Get the status bar height of the application. Determine if it is hidden or not.

 @return CGFloat of the height of the status bar.
 */
- (CGFloat)statusBarHeight {
    return ([[UIApplication sharedApplication] isStatusBarHidden] ? 0.0 : [UIApplication sharedApplication].statusBarFrame.size.height);
}

/**
 Update the scroll view insets based on the current offset.

 @param topOffset CGFloat of the current offset of the navbar.
 */
- (void)updateScrollInsetsWithTopOffset:(CGFloat)topOffset {
    topOffset -= scrollOffsets;
    
    // Calculate scroll insets to make sure they fill the entire screen.
    UIEdgeInsets currentScrollInsets = self.associatedScrollView.scrollIndicatorInsets;
    currentScrollInsets.top = topOffset;
    [self.associatedScrollView setScrollIndicatorInsets:currentScrollInsets];
    
    // If the content doesn't go behind update the inset of the content so there is no empty space.
    if (!self.allowContentBehind) {
        UIEdgeInsets currentContentInsets = self.associatedScrollView.contentInset;
        currentContentInsets.top = topOffset;
        [self.associatedScrollView setContentInset:currentContentInsets];
    }
    
    // If the scroll view is using the delegate pass the information along.
    if (self.associatedScrollView.delegate && [self.associatedScrollView.delegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
        [self.associatedScrollView.delegate scrollViewDidScroll:self.associatedScrollView];
    }
}

/**
 Updates the nav bar height and scroll view after changing orientation.
 */
- (void)updateInfoForOrientationChange {
    // Mark that we are updating so we don't get into a loop.
    updatingOffset = YES;
    
    // If the new orientation is not tall enough set everything to be showing
    float minHeight = (lastHeight - [self statusBarHeight]) + self.associatedScrollView.frame.size.height;
    if (self.associatedScrollView.contentSize.height <= minHeight || minHeight <= 0) {
        percentShowing = 1.0;
    }
    
    // Update the nav bar
    [self updateScrollInsetRotation:YES];
    [self updateBasedOnPercent];
    
    // Mark that we stoped updating so we can get constant updates.
    updatingOffset = NO;
}

/**
 Update the amount nav bar is showing based on the percent that was calculated.
 */
- (void)updateBasedOnPercent {
    // Mark that we are updating so we don't get into a loop.
    updatingOffset = YES;
    
    // Calculate the new frame pased on the percent showing.
    CGRect currentFrame = self.frame;
    CGFloat total = [self statusBarHeight] + (lastHeight - [self statusBarHeight]);
    CGFloat amountCaluclated = total - (total * percentShowing);
    currentFrame.origin.y = ([self statusBarHeight] - amountCaluclated);
    self.frame = currentFrame;
    
    // Now update the alpha of the buttons so they disappear with the navbar.
    [self updateViewAlpha];
    
    // Calculate the offset of the content and update.
    float topOffset = self.frame.origin.y + lastHeight;
    [self updateScrollInsetsWithTopOffset:topOffset];
    
    // Get new last offset.
    lastOffset = [self.associatedScrollView contentOffset].y;
    
    // Mark that we stoped updating so we can get constant updates.
    updatingOffset = NO;
}

/**
 Called when the system recieves an orientation change.
 */
- (void)orientationChanged {
    // Give fraction of sec for value to change
    [self performSelector:@selector(updateInfoForOrientationChange) withObject:nil afterDelay:0.1];
}

/**
 Updates the alpha of all the buttons and backgrounds of the navbar.
 */
- (void)updateViewAlpha {
    // See if we are showing the back button.
    [self checkBackButton];
    
    // Adjust subview alphas
    for (UIView *view in self.subviews) {
        // This filters both the Back button view and the Background view
        if (![self isBackgroundView:view] && ![self isBackButtonView:view]) {
            [view setAlpha:percentShowing];
        }
        
        // If we're showing the back button, go ahead and do that one too
        if ([self isBackButtonView:view] && showingBack) {
            [view setAlpha:percentShowing];
        }
    }
}

/**
 Check to see if the back button for the nav bar is showing or not.
 */
- (void)checkBackButton {
    if (!checkedBackButton) {
        // If the percent is 1.0 that means the view is fully visible and we can compute whether the back button is showing or not
        // Set showing back button
        [[self subviews] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            UIView *view = obj;
            if ([self isBackButtonView:view]) {
                // Found back button
                *stop = YES;
                self->showingBack = view.alpha == 1.0;
                if (self->checkStartedScrolling) {
                    self->checkedBackButton = YES;
                }
            }
        }];
    }
}

#pragma mark - Key Value Observer

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"frame"]) {
        if (!adjustingScrollFrame) {
            // Only update if we are not currently updating.
            [self adjustScrollFrame];
        }
    } else if ([keyPath isEqualToString:@"contentOffset"]) {
        if (updatingOffset || self.holdUpdates) {
            // We are either already updating or is selected not to allow updates so don't continue.
            return;
        }
        // Don't start updating until the user starts scrolling
        if (!checkStartedScrolling) {
            if ([self.associatedScrollView panGestureRecognizer].state == UIGestureRecognizerStateBegan) {
                checkStartedScrolling = YES;
            } else {
                // Fix for container items where the offset gets updated
                updatingOffset = YES;
                float topOffset = self.frame.origin.y + lastHeight;
                [self updateScrollInsetsWithTopOffset:topOffset];
                updatingOffset = NO;
                return;
            }
        }
        
        // Make sure content is tall enough
        float minHeight = (lastHeight - [self statusBarHeight]) + self.associatedScrollView.frame.size.height;
        if (self.associatedScrollView.contentSize.height <= minHeight) {
            if (percentShowing != 1.0) {
                percentShowing = 1.0;
                [self updateBasedOnPercent];
            }
            return;
        }
        
        CGPoint offset = [self.associatedScrollView contentOffset];
        
        // If this is start of scroll determine if should be holding for displaying nav bar
        if ([self.associatedScrollView panGestureRecognizer].state == UIGestureRecognizerStateBegan) {
            startedScollPoint = offset.y;
            if ((-(lastHeight - [self statusBarHeight])) == self.frame.origin.y) {
                holdScrolling = YES;
            } else {
                holdScrolling = NO;
            }
        }
        
        if (holdScrolling) {
            // If holding Determine if hold has expired based on scrolling past percent of screen
            // Or if we are at the top of the screen
            float diff = startedScollPoint - offset.y;
            if (diff > (self.associatedScrollView.frame.size.height * self.scrollHoldPercent) || offset.y <= 0) {
                holdScrolling = NO;
            } else {
                lastOffset = offset.y;
                return;
            }
        }
        
        CGFloat topInset = lastHeight + [self statusBarHeight];
        if (self.allowContentBehind) {
            topInset = 0.0;
        }
        if (offset.y + topInset <= 0.0) {
            // Above the top, bouncing nav should be fully showing
            lastOffset = offset.y;
            if (percentShowing != 1.0) {
                percentShowing = 1.0;
                [self updateBasedOnPercent];
            }
            return;
        }
        
        if (self.associatedScrollView.contentOffset.y >= (self.associatedScrollView.contentSize.height - self.associatedScrollView.frame.size.height + self.associatedScrollView.contentInset.bottom)) {
            // Bellow bottom, bouncing nav should be fully hidden
            lastOffset = offset.y;
            if (percentShowing != 0.0) {
                percentShowing = 0.0;
                [self updateBasedOnPercent];
            }
            return;
        }
        
        // Calculate the new frame height.
        CGFloat frameOrigin = self.frame.origin.y;
        CGFloat dy = offset.y - lastOffset;
        
        frameOrigin = MIN(MAX(frameOrigin - dy, - (lastHeight - [self statusBarHeight])), [self statusBarHeight]);
        CGRect currentFrame = self.frame;
        currentFrame.origin.y = frameOrigin;
        
        // Update Insets so headers stay at the top
        updatingOffset = YES;
        float topOffset = frameOrigin + lastHeight;
        if (self.associatedScrollView.contentInset.top >= -scrollOffsets) {
            [self updateScrollInsetsWithTopOffset:topOffset];
        }
        updatingOffset = NO;
        
        // Calculate the percent that we should be showing the nav bar
        percentShowing = (frameOrigin + (lastHeight - [self statusBarHeight])) / lastHeight;
        
        // Update the frame.
        self.frame = currentFrame;
        
        // Update the alpha of the buttons.
        [self updateViewAlpha];
        lastOffset = offset.y;
    }
}

@end


//
//  BPHidingNavBar.m
//
//  Created by Cory Imdieke on 12/31/13.
//  Copyright (c) 2013 BitSuites, LLC. All rights reserved.
//

#import "BPHidingNavBar.h"

@implementation BPHidingNavBar

- (id)init{
    self = [super init];
    if (self) {
        [self initSetup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self initSetup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initSetup];
    }
    return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [_associatedScrollView removeObserver:self forKeyPath:@"contentOffset"];
}

- (void)initSetup{
    updatingOffset = NO;
    _holdUpdates = NO;
    checkStartedScrolling = NO;
    _scrollHoldPercent = 0.2;
    if ([self isPreiOS7]) // Stop NavBar only works on iOS 7
        return;
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(orientationChanged)  name:UIDeviceOrientationDidChangeNotification  object:nil];
}

#pragma mark - User Methods

- (void)setupNavBarWithAssiciatedScrollView:(UIScrollView *)associatedScrollView{
    if ([self isPreiOS7]) // Stop NavBar only works on iOS 7
        return;
    [UIView animateWithDuration:0.3 animations:^{
        CGRect currentFrame = self.frame;
        currentFrame.origin.y = 20.0;
        self.frame = currentFrame;
        percentShowing = 1.0;
        // Fixes issue if controller is nil when going back sliding
        if (!associatedScrollView) {
            [self updateViewAlpha];
        }
    }];
    [self setAssociatedScrollView:associatedScrollView];
    checkStartedScrolling = NO;
	checkedBackButton = NO;
}

- (void)setAssociatedScrollView:(UIScrollView *)associatedScrollView{
    if ([self isPreiOS7]) // Stop NavBar only works on iOS 7
        return;
	if(_associatedScrollView){
		[_associatedScrollView removeObserver:self forKeyPath:@"contentOffset"];
		_associatedScrollView = nil;
	}
    
	_associatedScrollView = associatedScrollView;
	if(_associatedScrollView){
        [self updateScrollInsetRotation:NO];
		[_associatedScrollView addObserver:self forKeyPath:@"contentOffset" options:0 context:NULL];
	}
	
	lastOffset = associatedScrollView.contentOffset.y;
}

- (void)showFullNavBar;{
    [self showFullNavBarAnimated:YES];
}

- (void)showFullNavBarAnimated:(BOOL)animated{
    if ([self isPreiOS7]) // Stop NavBar only works on iOS 7
        return;
    [UIView animateWithDuration:(animated ? 0.3 : 0.0) animations:^{
        CGRect currentFrame = self.frame;
        currentFrame.origin.y = 20.0;
        self.frame = currentFrame;
        percentShowing = 1.0;
        [self updateViewAlpha];
    } completion:^(BOOL finished) {
		lastOffset = _associatedScrollView.contentOffset.y;
    }];
}

#pragma mark - Local Methdos

- (BOOL)isPreiOS7{
    return (!(NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1));
}

- (BOOL)isBackButtonView:(UIView *)possibleView{
	return [NSStringFromClass([possibleView class]) rangeOfString:@"Back"].location != NSNotFound && [NSStringFromClass([possibleView class]) rangeOfString:@"Background"].location == NSNotFound;
}

- (BOOL)isBackgroundView:(UIView *)possibleView{
	return [NSStringFromClass([possibleView class]) rangeOfString:@"Background"].location != NSNotFound;
}

- (void)updateScrollInsetRotation:(BOOL)rotation{
    lastHeight = self.frame.size.height;
    if (_associatedScrollView) {
        updatingOffset = YES;
        CGFloat top = lastHeight + [self statusBarHeight];
        BOOL firstLoad = _associatedScrollView.scrollIndicatorInsets.top < top;
        CGPoint startOffest = _associatedScrollView.contentOffset;
        
        [_associatedScrollView setScrollIndicatorInsets:UIEdgeInsetsMake(top, 0.0, 0.0, 0.0)];
        [_associatedScrollView setContentInset:UIEdgeInsetsMake(top, 0.0, 0.0, 0.0)];
        // Should only add the top on the first time it is loaded or the offest begins to go beyond the bar
        if (startOffest.y <= 0 && startOffest.y > -top && !rotation && firstLoad)
            [_associatedScrollView setContentOffset:CGPointMake(startOffest.x, (-top + startOffest.y))];
        else
            [_associatedScrollView setContentOffset:startOffest];
        updatingOffset = NO;
    }
}

- (CGFloat)statusBarHeight{
    return ([[UIApplication sharedApplication] isStatusBarHidden] ? 0.0 : 20.0);
}

- (void)updateInfoForOrientationChange{
    updatingOffset = YES;
    // If the new orientation is not tall enough set everything to be showing
    float minHeight = (lastHeight - [self statusBarHeight]) + self.associatedScrollView.frame.size.height;
    if (self.associatedScrollView.contentSize.height <= minHeight) {
        percentShowing = 1.0;
    }
    
    [self updateScrollInsetRotation:YES];
    [self updateBasedOnPercent];
    updatingOffset = NO;
}

- (void)updateBasedOnPercent{
    // Reloads nav bar bassed on the percent amount shown
    updatingOffset = YES;
    CGRect currentFrame = self.frame;
    CGFloat total = [self statusBarHeight] + (lastHeight - [self statusBarHeight]);
    CGFloat amountCaluclated = total - (total * percentShowing);
    currentFrame.origin.y = ([self statusBarHeight] - amountCaluclated);
    self.frame = currentFrame;
    [self updateViewAlpha];
    
    float topOffset = self.frame.origin.y + lastHeight;
    [_associatedScrollView setScrollIndicatorInsets:UIEdgeInsetsMake(topOffset, 0.0, 0.0, 0.0)];
    [_associatedScrollView setContentInset:UIEdgeInsetsMake(topOffset, 0.0, 0.0, 0.0)];
    
    lastOffset = [self.associatedScrollView contentOffset].y;
    updatingOffset = NO;
}

- (void)orientationChanged{
    // Give fraction of sec for value to change
    [self performSelector:@selector(updateInfoForOrientationChange) withObject:nil afterDelay:0.1];
}

- (void)updateViewAlpha{
    [self checkBackButton];
    // Adjust subview alphas
    for (UIView *view in self.subviews) {
        // This filters both the Back button view and the Background view
        if(![self isBackgroundView:view] && ![self isBackButtonView:view]) {
            [view setAlpha:percentShowing];
        }
        
        // If we're showing the back button, go ahead and do that one too
        if([self isBackButtonView:view] && showingBack){
            [view setAlpha:percentShowing];
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	if([keyPath isEqualToString:@"contentOffset"]){
        if (updatingOffset || _holdUpdates)
            return;
        // Don't start updating until the user starts scrolling
        if (!checkStartedScrolling) {
            if ([self.associatedScrollView panGestureRecognizer].state == UIGestureRecognizerStateBegan){
                checkStartedScrolling = YES;
            } else {
                // Fix for container items where the offset gets updated
                updatingOffset = YES;
                float topOffset = self.frame.origin.y + lastHeight;
                [_associatedScrollView setScrollIndicatorInsets:UIEdgeInsetsMake(topOffset, 0.0, 0.0, 0.0)];
                [_associatedScrollView setContentInset:UIEdgeInsetsMake(topOffset, 0.0, 0.0, 0.0)];
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
            if (diff > (self.associatedScrollView.frame.size.height * _scrollHoldPercent) || offset.y <= 0) {
                holdScrolling = NO;
            } else {
                lastOffset = offset.y;
                return;
            }
        }
        
        CGFloat topInset = lastHeight + [self statusBarHeight];
        if(offset.y + topInset <= 0.0){
			// Above the top, bouncing nav should be fully showing
			lastOffset = offset.y;
            if (percentShowing != 1.0) {
                percentShowing = 1.0;
                [self updateBasedOnPercent];
            }
			return;
		}
        
        if(self.associatedScrollView.contentOffset.y > (self.associatedScrollView.contentSize.height - self.associatedScrollView.frame.size.height + self.associatedScrollView.contentInset.bottom)){
			// Bellow bottom, bouncing nav should be fully hidden
			lastOffset = offset.y;
            if (percentShowing != 0.0) {
                percentShowing = 0.0;
                [self updateBasedOnPercent];
            }
			return;
        }
		CGFloat frameOrigin = self.frame.origin.y;
		CGFloat dy = offset.y - lastOffset;
        
		
		frameOrigin = MIN(MAX(frameOrigin - dy, - (lastHeight - [self statusBarHeight])), [self statusBarHeight]);
		CGRect currentFrame = self.frame;
		currentFrame.origin.y = frameOrigin;
        
        // Update Insets so headers stay at the top
        updatingOffset = YES;
        float topOffset = frameOrigin + lastHeight;
        if (_associatedScrollView.contentInset.top >= 0) {
            [_associatedScrollView setScrollIndicatorInsets:UIEdgeInsetsMake(topOffset, 0.0, 0.0, 0.0)];
            [_associatedScrollView setContentInset:UIEdgeInsetsMake(topOffset, 0.0, 0.0, 0.0)];
        }
        updatingOffset = NO;
        
		percentShowing = (frameOrigin + (lastHeight - [self statusBarHeight])) / lastHeight;
        
		self.frame = currentFrame;
		
		[self updateViewAlpha];
		
		lastOffset = offset.y;
	}
}

- (void)checkBackButton{
    if(!checkedBackButton){
		// If the percent is 1.0 that means the view is fully visible and we can compute whether the back button is showing or not
        // Set showing back button
        [[self subviews] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            UIView *view = obj;
            if([self isBackButtonView:view]){
                // Found back button
                *stop = YES;
                showingBack = view.alpha == 1.0;
                if (checkStartedScrolling)
                    checkedBackButton = YES;
            }
        }];
    }
}

@end

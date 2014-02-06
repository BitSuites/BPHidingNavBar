//
//  BPHidingNavBar.m
//  HidingSample
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

- (void)initSetup{
    updatingOffset = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(orientationChanged)  name:UIDeviceOrientationDidChangeNotification  object:nil];
    _scrollHoldPercent = 0.2;
}

- (void)setAssociatedScrollView:(UIScrollView *)associatedScrollView{
	if(_associatedScrollView){
		[_associatedScrollView removeObserver:self forKeyPath:@"contentOffset"];
		_associatedScrollView = nil;
	}
    
    [UIView animateWithDuration:0.3 animations:^{
        CGRect currentFrame = self.frame;
        currentFrame.origin.y = 20.0;
        self.frame = currentFrame;
        percentShowing = 1.0;
		[self updateViewAlpha];
    }];
    
	_associatedScrollView = associatedScrollView;
	if(_associatedScrollView){
        [self updateScrollInset];
		[_associatedScrollView addObserver:self forKeyPath:@"contentOffset" options:0 context:NULL];
	}
	
	lastOffset = associatedScrollView.contentOffset.y;
	checkedBackButton = NO;
}

- (BOOL)isBackButtonView:(UIView *)possibleView{
	return [NSStringFromClass([possibleView class]) rangeOfString:@"Back"].location != NSNotFound && [NSStringFromClass([possibleView class]) rangeOfString:@"Background"].location == NSNotFound;
}

- (BOOL)isBackgroundView:(UIView *)possibleView{
	return [NSStringFromClass([possibleView class]) rangeOfString:@"Background"].location != NSNotFound;
}

- (void)updateScrollInset{
    lastHeight = self.frame.size.height;
    if (_associatedScrollView) {
        CGFloat top = lastHeight + [self statusBarHeight];
        [_associatedScrollView setScrollIndicatorInsets:UIEdgeInsetsMake(top, 0.0, 0.0, 0.0)];
        [_associatedScrollView setContentInset:UIEdgeInsetsMake(top, 0.0, 0.0, 0.0)];
    }
}

- (CGFloat)statusBarHeight{
    return ([[UIApplication sharedApplication] isStatusBarHidden] ? 0.0 : 20.0);
}

- (void)updateInfoForOrientationChange{
    // Update everything for an orientation change
    updatingOffset = YES;
    [self updateScrollInset];
    CGRect currentFrame = self.frame;
    CGFloat total = [self statusBarHeight] + (lastHeight - [self statusBarHeight]);
    CGFloat amountCaluclated = total - (total * percentShowing);
    currentFrame.origin.y = ([self statusBarHeight] - amountCaluclated);
    self.frame = currentFrame;
    [self updateViewAlpha];
    lastOffset = [self.associatedScrollView contentOffset].y;
    updatingOffset = NO;
}

- (void)orientationChanged{
    // Give fraction of sec for value to change
    [self performSelector:@selector(updateInfoForOrientationChange) withObject:nil afterDelay:0.1];
}

- (void)updateViewAlpha{
    // Adjust subview alphas
    for (UIView *view in self.subviews) {
        // This filters both the Back button view and the Background view
        if(![self isBackgroundView:view] && ![self isBackButtonView:view])
            [view setAlpha:percentShowing];
        
        // If we're showing the back button, go ahead and do that one too
        if([self isBackButtonView:view] && showingBack){
            [view setAlpha:percentShowing];
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	if([keyPath isEqualToString:@"contentOffset"]){
        if (updatingOffset)
            return;
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
			// Above the top, bouncing
			lastOffset = offset.y;
			return;
		}
        
        if(self.associatedScrollView.contentOffset.y > (self.associatedScrollView.contentSize.height - self.associatedScrollView.frame.size.height + self.associatedScrollView.contentInset.bottom)){
			// Bottom bouncing
			lastOffset = offset.y;
			return;
        }
		CGFloat frameOrigin = self.frame.origin.y;
		CGFloat dy = offset.y - lastOffset;
        
		
		frameOrigin = MIN(MAX(frameOrigin - dy, - (lastHeight - [self statusBarHeight])), [self statusBarHeight]);
		
		CGRect currentFrame = self.frame;
		currentFrame.origin.y = frameOrigin;
		percentShowing = (frameOrigin + (lastHeight - [self statusBarHeight])) / lastHeight;
    
		self.frame = currentFrame;
		
		// If the percent is 1.0 that means the view is fully visible and we can compute whether the back button is showing or not
		if(!checkedBackButton){
			// Set showing back button
			[[self subviews] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
				UIView *view = obj;
				if([self isBackButtonView:view]){
					// Found back button
					*stop = YES;
					showingBack = view.alpha == 1.0;
					checkedBackButton = YES;
				}
			}];
		}
		
		[self updateViewAlpha];
		
		lastOffset = offset.y;
	}
}

@end

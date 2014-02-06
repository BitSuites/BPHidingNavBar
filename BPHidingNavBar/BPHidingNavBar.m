//
//  BPHidingNavBar.m
//  HidingSample
//
//  Created by Cory Imdieke on 12/31/13.
//  Copyright (c) 2013 BitSuites, LLC. All rights reserved.
//

#import "BPHidingNavBar.h"

#define kInsetAmount 64.0

@implementation BPHidingNavBar

- (void)setAssociatedScrollView:(UIScrollView *)associatedScrollView{
	if(_associatedScrollView){
		[_associatedScrollView removeObserver:self forKeyPath:@"contentOffset"];
		_associatedScrollView = nil;
	}
	
	if(associatedScrollView){
		[associatedScrollView setScrollIndicatorInsets:UIEdgeInsetsMake(kInsetAmount, 0.0, 0.0, 0.0)];
		[associatedScrollView setContentInset:UIEdgeInsetsMake(kInsetAmount, 0.0, 0.0, 0.0)];
		
		[associatedScrollView addObserver:self forKeyPath:@"contentOffset" options:0 context:NULL];
	}
	
	_associatedScrollView = associatedScrollView;
	lastOffset = associatedScrollView.contentOffset.y;
	checkedBackButton = NO;
}

- (BOOL)isBackButtonView:(UIView *)possibleView{
	return [NSStringFromClass([possibleView class]) rangeOfString:@"Back"].location != NSNotFound && [NSStringFromClass([possibleView class]) rangeOfString:@"Background"].location == NSNotFound;
}

- (BOOL)isBackgroundView:(UIView *)possibleView{
	return [NSStringFromClass([possibleView class]) rangeOfString:@"Background"].location != NSNotFound;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	if([keyPath isEqualToString:@"contentOffset"]){
		CGPoint offset = [self.associatedScrollView contentOffset];
		
		//NSLog(@"%f", offset.y);
		
		//NSLog(@"%@", self.subviews);
		
		if(offset.y + kInsetAmount <= 0.0){
			// Above the top, bouncing
			lastOffset = offset.y;
			return;
		}
		
		CGFloat frameOrigin = self.frame.origin.y;
		
		CGFloat dy = offset.y - lastOffset;
		frameOrigin = MIN(MAX(frameOrigin - dy, -24.0), 20.0);
		//NSLog(@"frameOrigin: %f", frameOrigin);
		
		CGRect currentFrame = self.frame;
		currentFrame.origin.y = frameOrigin;
		CGFloat percent = (frameOrigin + 24.0) / 44.0;
		NSLog(@"%f", percent);
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
		
//		NSMutableDictionary *currentTitleTextAttributes = [self.titleTextAttributes mutableCopy];
//		if(!currentTitleTextAttributes)
//			currentTitleTextAttributes = [@{NSForegroundColorAttributeName : [UIColor blackColor]} mutableCopy];
//		UIColor *currentColor = currentTitleTextAttributes[NSForegroundColorAttributeName];
//		[currentTitleTextAttributes setObject:[currentColor colorWithAlphaComponent:percent] forKey:NSForegroundColorAttributeName];
//		[self setTitleTextAttributes:currentTitleTextAttributes];
		
		// Adjust subview alphas
		for (UIView *view in self.subviews) {
			// This filters both the Back button view and the Background view
			if(![self isBackgroundView:view] && ![self isBackButtonView:view])
				[view setAlpha:percent];
			
			// If we're showing the back button, go ahead and do that one too
			if([self isBackButtonView:view] && showingBack){
				[view setAlpha:percent];
			}
		}
		
		lastOffset = offset.y;
	}
}

@end

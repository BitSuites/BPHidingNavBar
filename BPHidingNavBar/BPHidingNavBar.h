//
//  BPHidingNavBar.h
//
//  Copyright (c) 2013 BitSuites, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BPHidingNavBar : UINavigationBar

/** Scrollview that we associate with for hiding and showing the nav bar
 
 Only use this to change the scrollview that has the same nav bar button for example Page view Contrller
 If you are trying to update scrollview with a new controller use setupNavBarWithAssiciatedScrollView: method
 which sets up nav bar with the new buttons so they can be hidden properly
 */
@property (nonatomic, strong) UIScrollView *associatedScrollView;

/** Percent Scroll View needs to move before reshowing nav bar
 
 Return a percentage 1.0 full screen 0.0 no scroll
 Default value 0.2
 */
@property (nonatomic) CGFloat scrollHoldPercent;

/** Called to hold all updates associatedScrollView gets related to content change
 Was added for use in page view controllers
 
 Return YES to hold and NO to resume
 */
@property (nonatomic) BOOL holdUpdates;

/** Called to inform navbar wether the content is behind the nav bar or not
 
 Return YES to hold and NO as to wehter there is content behind
 */
@property (nonatomic) BOOL allowContentBehind;

/** Setup nav bar with scrollview that initalises nav bar with buttons that will be hiding
 
 @param associatedScrollView scroll view that will be used to show and hide the navBar
 */
- (void)setupNavBarWithAssiciatedScrollView:(UIScrollView *)associatedScrollView;

/** Setup nav bar with scrollview that initalises nav bar with buttons that will be hiding
 
 @param associatedScrollView scroll view that will be used to show and hide the navBar
 @param contentBehind wether there is content that is behind the nav bar
 */
- (void)setupNavBarWithAssiciatedScrollView:(UIScrollView *)associatedScrollView contentBehindNav:(BOOL)contentBehind;

/** Shows the full nav bar with animation
 */
- (void)showFullNavBar;

/** Shows the full nav bar
 
 @param animated detemies whetere showing the nav bar is animated or no
 */
- (void)showFullNavBarAnimated:(BOOL)animated;

@end

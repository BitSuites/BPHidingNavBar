//
//  BPHidingNavBar.h
//  HidingSample
//
//  Created by Cory Imdieke on 12/31/13.
//  Copyright (c) 2013 BitSuites, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BPHidingNavBar : UINavigationBar <UINavigationControllerDelegate>{
	CGFloat lastOffset;
	BOOL checkedBackButton;
	BOOL showingBack;
    CGFloat lastHeight;
    CGFloat percentShowing;
    BOOL updatingOffset;
    
    CGFloat startedScollPoint;
    BOOL holdScrolling;
    
}

@property (nonatomic, strong) UIScrollView *associatedScrollView;
@property (nonatomic) CGFloat scrollHoldPercent; // Default 0.2 percent of frame

@end

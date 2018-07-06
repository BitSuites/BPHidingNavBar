BPHidingNavBar
================================

BPHiddingNavBar is code to manage the hiding and showing of a navbar that responds to a users scrolling in a scroll view or table view. When a user scrolls down the navbar will hide and if a user scrolls up it will show.

## Project Installation ##

##### Installation #####

Installation can be done 2 ways

- Installation through adding the executables to your project.

This method is simple and works by simply copying the latest source into your project.

- Installation through Cocoapods.

Installation is handled using Cocoapods. While the executables are added through cocopods they are not added to the app just made available.

`pod 'BPHidingNavBar', :git => "git@github.com:BitSuites/BPHidingNavBar.git"`


## Usage ##
This needs to be done on every class that you want the navbar to scroll with.

1) In the storyboard NavigationController set the NavBar class to `BPHidingNavBar`

2) In the ViewController in viewWillAppear set the scrollview to the navbar.
```Shell
- (void)viewWillAppear:(BOOL)animated{
	[super viewWillAppear:animated];
	[(BPHidingNavBar *)self.navigationController.navigationBar setupNavBarWithAssiciatedScrollView:self.tableView];
}
```

3) In the ViewController in viewDidLoad set scrollview automaticall adjusts.
```Shell
- (void)viewDidLoad{
    [super viewDidLoad];
    [self setAutomaticallyAdjustsScrollViewInsets:NO];
}
```

## License

[BPHidingNavBar](https://github.com/BitSuites/BPHidingNavBar) was created by [BitSuites](https://github.com/BitSuites) and released under a [MIT License](License).


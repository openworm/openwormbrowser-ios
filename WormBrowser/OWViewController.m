//
//  OWViewController.m
//  WormBrowser
//
//  Created by Rich Stoner on 12/2/12.
//  Copyright (c) 2012 Rich Stoner. All rights reserved.
//

#import "OWViewController.h"

@interface OWViewController ()
{
    bool mIsInSearch;
    bool mHasPendingOnPause;
    
    UIButton* mShowSearchButton;
    UIButton* mCameraButton;
    UIButton* mAboutButton;
    
//    UIButton* mShowMetaDataButton;

    
    
    UIActivityIndicatorView* loadingActivity;
    
    BOOL isUsingFreeCam;
    
    UIImage* pillImage;
    UIImage* airplaneImage;
    
}
@end

@implementation OWViewController

@synthesize mSearchView, mOpacityView, mCurrentLayer, mView, mMetaDataView;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    isUsingFreeCam = NO;
    
    self.mCurrentLayer = layerCuticle;
    
    self.mView = [[OWGLViewController alloc] init];
    [self.mView.view setFrame:[self frameForGLView]];
    [self.view addSubview:self.mView.view];
    
    
    self.mOpacityView = [[WSOpacityViewController alloc] init];
    [self.view addSubview:self.mOpacityView.view];
    
    
    // initialized search view here
    self.mSearchView = [[OWSearchViewController alloc] init];
    
    
    self.mMetaDataView = [[OWMetaDataViewController alloc] init];
    
    BOOL iPad = NO;
#ifdef UI_USER_INTERFACE_IDIOM
    iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
#endif
    if (iPad) {
     
        [self.mMetaDataView.view setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin];
        [self.mSearchView.view setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin];
        
    }
    else
    {
        self.mSearchView.view.backgroundColor = [UIColor whiteColor];
    }
    
    
//    [self.view addSubview:self.mMetaDataView.view];

    
    mShowSearchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [mShowSearchButton setFrame:CGRectMake(0,0,40,40)];
    [mShowSearchButton setImage:[UIImage imageNamed:@"owSearch"] forState:UIControlStateNormal];
    [mShowSearchButton setCenter:CGPointMake(self.view.frame.size.width - 30, 30)];
    [mShowSearchButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin];
    [mShowSearchButton setBackgroundColor:kButtonViewBackground];
    
    
    airplaneImage = [UIImage imageNamed:@"owPan"];
    pillImage = [UIImage imageNamed:@"owPill"];
    
    mCameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [mCameraButton setFrame:CGRectMake(0,0,40,40)];
    [mCameraButton setImage:pillImage forState:UIControlStateNormal];
    [mCameraButton setCenter:CGPointMake(self.view.frame.size.width - 30, 130)];
    [mCameraButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin];
    [mCameraButton setBackgroundColor:kButtonViewBackground];
    [mCameraButton addTarget:self action:@selector(handleButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    [mCameraButton setTag:1];
    [self.view addSubview:mCameraButton];
    
    mAboutButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [mAboutButton setFrame:CGRectMake(0,0,40,40)];
    [mAboutButton setImage:[UIImage imageNamed:@"owInfo"] forState:UIControlStateNormal];
    [mAboutButton setCenter:CGPointMake(self.view.frame.size.width - 30, 80)];
    [mAboutButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin];
    [mAboutButton setBackgroundColor:kButtonViewBackground];
    [mAboutButton addTarget:self action:@selector(handleButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    [mAboutButton setTag:2];
    [self.view addSubview:mAboutButton];
    
#warning TODO(RMS) add enum for this tag
    [mShowSearchButton setTag:0];
    [mShowSearchButton addTarget:self action:@selector(handleButtonTap:) forControlEvents:UIControlEventTouchUpInside];

#if TARGET_IPHONE_SIMULATOR

    [self.view addSubview:mShowSearchButton];
    
#else

    loadingActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [loadingActivity setFrame:CGRectMake(0,0,40,40)];
    [loadingActivity startAnimating];
    [loadingActivity setCenter:CGPointMake(self.view.frame.size.width - 30, 30)];
    [loadingActivity setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin];
    [loadingActivity setBackgroundColor:kButtonViewBackground];
    [self.view addSubview:loadingActivity];
    
#endif
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(allLayersLoaded:) name:kNotificationAllLayersLoaded object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(searchViewClosed:) name:kNotificationCloseSearchView object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(metaDataClosed:) name:kNotificationCloseMetaView object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showMetaDataForItem:) name:kNotificationShowMetaDataForItem object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCameraMode:) name:kUpdateCameraSetting object:nil];
    
}



-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.mOpacityView.view setFrame:[self frameForOpacityView]];
    [self.mSearchView.view setFrame:[self frameForSearchView]];
    [self.mMetaDataView.view setFrame:[self frameForMetaDataView]];

    
}



-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    BOOL iPad = NO;
#ifdef UI_USER_INTERFACE_IDIOM
    iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
#endif
    if (iPad) {
        return YES;        
        
    }
    else
    {
        return YES;
    }
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.mView willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - method for layout

-(CGRect) frameForGLView
{
    return self.view.frame;
}


-(CGRect) frameForSearchView
{
     
    CGRect frameToReturn = CGRectZero;
    
    BOOL iPad = NO;
#ifdef UI_USER_INTERFACE_IDIOM
    iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
#endif
    if (iPad) {
        
        UIInterfaceOrientation toInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        
        if (toInterfaceOrientation == UIInterfaceOrientationPortrait || toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
            
            frameToReturn = CGRectMake(self.view.frame.size.width - 320 - 10, 10, 320, 400);
        }
        else
        {
            frameToReturn = CGRectMake(self.view.frame.size.height - 320 - 10, 10, 320, 400);
        }
        
    }
    else
    {
        frameToReturn = self.view.frame;
    }
    
    NSLog(@"%s: %@", (char*)_cmd, [NSValue valueWithCGRect:frameToReturn]);
    
    return frameToReturn;
}

-(CGRect) frameForMetaDataView
{
    
    CGRect frameToReturn = CGRectZero;
    
    BOOL iPad = NO;
#ifdef UI_USER_INTERFACE_IDIOM
    iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
#endif
    if (iPad) {
        
        UIInterfaceOrientation toInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        
        if (toInterfaceOrientation == UIInterfaceOrientationPortrait || toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
            
            frameToReturn = CGRectMake(self.view.frame.size.width - 320 - 10, 10, 320, 400);
        }
        else
        {
            frameToReturn = CGRectMake(self.view.frame.size.height - 320 - 10, 10, 320, 400);
        }
        
    }
    else
    {
        frameToReturn = self.view.frame;
    }
    
    NSLog(@"%s: %@", (char*)_cmd, [NSValue valueWithCGRect:frameToReturn]);
    
    return frameToReturn;
}



-(CGRect) frameForOpacityView
{
    
    CGRect frameToReturn = CGRectZero;
    
    BOOL iPad = NO;
#ifdef UI_USER_INTERFACE_IDIOM
    iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
#endif
    if (iPad) {
        
        
        frameToReturn = CGRectMake(25, 0, kOpacityViewWidth+ 20, kOpacityViewHeight + 20);
        
        
    }
    else
    {
        // need to flip coordinates for iphone landscape
//        float width = [UIScreen mainScreen].bounds.size.height;
//        float height = [UIScreen mainScreen].bounds.size.width;
        
        frameToReturn = CGRectMake(20, 0, kOpacityViewWidth+ 20, kOpacityViewHeight + 20);
        
    }
    
    NSLog(@"%s: %@", (char*)_cmd, [NSValue valueWithCGRect:frameToReturn]);
    return frameToReturn;
}


#pragma mark - incoming notifications

-(void) allLayersLoaded:(NSNotification*) notification
{
    
    NSLog(@"all layers loaded");
    mShowSearchButton.alpha = 0.0f;
    mShowSearchButton.center = loadingActivity.center;
    
    [UIView animateWithDuration:0.5 animations:^{
       
        [loadingActivity setAlpha:0.0f];
        
    } completion:^(BOOL finished) {
        
        [loadingActivity removeFromSuperview];

        [self.view addSubview:mShowSearchButton];
        
        [UIView animateWithDuration:0.5 animations:^{
            
            mShowSearchButton.alpha = 1.0f;
            
        } completion:^(BOOL finished) {
            
        }];
    }];
    
    
}


-(void) showMetaDataForItem:(NSNotification*) notification
{
    
    NSLog(@"Here");

    OWAppDelegate* delegate = AppDelegate;
    OWResource* resource = delegate.resource;
    NSString* nameToSelect = [notification object];
    NSDictionary* metadata = [resource getMetaDataDetailsForName:nameToSelect];


    
    BOOL iPad = NO;
#ifdef UI_USER_INTERFACE_IDIOM
    iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
#endif
    if (iPad) {
        
        if (metadata != nil) {
            NSLog(@"found valid set of details");
            
            [self.mMetaDataView populateWithMetaDataDict:metadata forTerm:nameToSelect];
//            [self.mView setPaused:YES];

            [self.view addSubview:self.mMetaDataView.view];
            
//            [self presentViewController:self.mMetaDataView animated:YES completion:^{
//            }];
            
        }
        else
        {
            NSLog(@"no details found, loading default");
        }
        
    }
    else{
        
        if (metadata != nil) {
            NSLog(@"found valid set of details");
            
            [self.mMetaDataView populateWithMetaDataDict:metadata forTerm:nameToSelect];
            [self.mView setPaused:YES];
            [self presentViewController:self.mMetaDataView animated:YES completion:^{
            }];
            
        }
        else
        {
            NSLog(@"no details found, loading default");
        }

    }
}

-(void) updateCameraMode:(id) s
{
    
    
    if ([self.mView isCameraPill]) {
        [mCameraButton setImage:pillImage forState:UIControlStateNormal];
    }
    else{
        [mCameraButton setImage:airplaneImage forState:UIControlStateNormal];
    }
    
}




-(void) showAboutView
{
    
    
    BOOL iPad = NO;
#ifdef UI_USER_INTERFACE_IDIOM
    iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
#endif
    if (iPad) {
        
        [self.mMetaDataView loadAboutView];
        
        [self.view addSubview:self.mMetaDataView.view];
        
    }
    else{

        [self.mMetaDataView loadAboutView];
        [self.mView setPaused:YES];
        [self presentViewController:self.mMetaDataView animated:YES completion:^{
            }];
        
    }
}


-(void) metaDataClosed:(NSNotification*) notification
{
    BOOL iPad = NO;
#ifdef UI_USER_INTERFACE_IDIOM
    iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
#endif
    if (iPad) {
        
        [self.mMetaDataView.view removeFromSuperview];
        [self.mSearchView.view removeFromSuperview];
        
    }
    else
    {
        
    }
    
    
    [self.mView setPaused:NO];

}


-(void) searchViewClosed:(NSNotification*) notification
{
    BOOL iPad = NO;
#ifdef UI_USER_INTERFACE_IDIOM
    iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
#endif
    if (iPad) {
        
        [self.mMetaDataView.view removeFromSuperview];
        [self.mSearchView.view removeFromSuperview];
        
    }
    else
    {
        
    }
        
        
    [self.mView setPaused:NO];
}

-(void) showSearchView
{
    BOOL iPad = NO;
#ifdef UI_USER_INTERFACE_IDIOM
    iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
#endif
    if (iPad) {
        
        
        
        
//        [self.mView setPaused:YES];
        
        NSLog(@"Present search view");
//        [self presentViewController:self.mSearchView animated:YES completion:^{
        [self.view addSubview:self.mSearchView.view];
        
            
        
        
    }
    else
    {
        
        
        
        [self.mView setPaused:YES];
        
        NSLog(@"Present search view");
        [self presentViewController:self.mSearchView animated:YES completion:^{
            
            
            
        }];
    }
}


#pragma mark - handle button taps on main screen

-(void) handleButtonTap:(id)sender
{
    int tag = [sender tag];
    
    switch (tag) {
        case 0:
            
            [self showSearchView];

            break;
            
        case 1:
            
            // handle camera tap
            [self.mView toggleCameraMode];
            
            
            
 
            
            
            break;
            
        case 2:
            
            // handle info tap
            
            [self showAboutView];
            
        default:
            break;
    }
    
    if ([self.mView isCameraPill]) {
        [mCameraButton setImage:pillImage forState:UIControlStateNormal];
    }
    else{
        [mCameraButton setImage:airplaneImage forState:UIControlStateNormal];
    }
    

}


@end

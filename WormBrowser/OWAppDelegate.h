//
//  OWAppDelegate.h
//  WormBrowser
//
//  Created by Rich Stoner on 12/2/12.
//  Copyright (c) 2012 Rich Stoner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OWResource.h"

@class OWViewController;

@interface OWAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow  *window;

@property (strong, nonatomic) OWViewController *viewController;

@property (strong, nonatomic) OWResource *resource;

@end

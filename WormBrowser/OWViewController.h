//
//  OWViewController.h
//  WormBrowser
//
//  Created by Rich Stoner on 12/2/12.
//  Copyright (c) 2012 Rich Stoner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OWSearchViewController.h"
#import "OWGLViewController.h"
#import "WSOpacityViewController.h"
#import "OWMetaDataViewController.h"

/** OWViewController description
 
 */
@interface OWViewController : UIViewController
{
    
 
    
    
}



/**
 GLKit Viewcontroller -> mView
 */
@property(nonatomic, strong)    OWGLViewController*     mView;

/**
 Search UIViewController  -> mSearchView
 */
@property(nonatomic, strong)    OWSearchViewController* mSearchView;

/**
 
 */
@property(nonatomic, strong)    WSOpacityViewController* mOpacityView;

/**
 current layerSelected
 */
@property                       layerType mCurrentLayer;


/**
 Metadata viewcontroller
 */
@property(nonatomic, strong)    OWMetaDataViewController* mMetaDataView;

@end

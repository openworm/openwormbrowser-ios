//
//  OWGLViewController.h
//  WormBrowser
//
//  Created by Rich Stoner on 12/4/12.
//  Copyright (c) 2012 Rich Stoner. All rights reserved.
//

#import <GLKit/GLKit.h>

/** OWGLViewController description
 
 */
@interface OWGLViewController : GLKViewController <UIGestureRecognizerDelegate>
{

    
}

/**
 global parameter for model opacity
 @param opac global opacity
 */
-(void) setBodyOpacity:(GLfloat) opac;

/**  Toggles between the various camera modes such as Pill, free, and transition

 */
-(void) toggleCameraMode;

/** returns if camera is pill
 
 */
-(BOOL) isCameraPill;

@end
//
//  OWNavigate.h
//  WormBrowser
//
//  Created by Rich Stoner on 12/2/12.
//  Copyright (c) 2012 Rich Stoner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OWInterpolant.h"
#import "OWEntityInfo.h"
#import "OWCamera.h"

#define rotationStartPercent 0.01f
#define ROTATION_REDUCTION 0.1f
#define VERTICAL_REDUCTION 0.1f
#define ZOOM_REDUCTION 1.0f
#define VERTICAL_ADJUSTMENT 1
#define VERTICAL_PAN_LIMIT 0.1
#define ZOOM_NEAR_LIMIT 0.1f
#define ZOOM_FAR_LIMIT 250
#define START_PAN 0.1f

/** OWNavigate description
 
 */
@interface OWNavigate : NSObject
{
    NSMutableArray* mInterpolants;
    OWInterpolant* mDollyY;
    OWInterpolant* mDollyZ;
    OWInterpolant* mTheta;
    
    OWCamera* camera;
    
    float initialDollyZ;
}

@property float aspectRatio;
@property(nonatomic, strong) OWInterpolant* mDollyZ;
@property(nonatomic, strong) OWInterpolant* mDollyY;
@property(nonatomic, strong) OWInterpolant* mTheta;


/** returns current camera (not needed since we put camera in public interface)
 
 */
-(OWCamera*) getCamera;

/** Recalculate the camera parameters based on tweens and touches
 
 */
-(void) recalculate;


/** animates to entity with bounding box
 @param entity the entity to navigate to
 @param urgency how fast to go (from scale from 0 to 1)
 */
-(void) goToForEntity:(OWEntityInfo*)entity withUrgency:(float) urgency;

/** basic movement control
 e.g. single finger camera motion
 @param delta the difference between this touch and the last
 @param absolute the total translation from start of touch
 */
-(void) handlePrimaryTouchDelta:(CGPoint) delta withAbsolute:(CGPoint) absolute;

/** secondary movement control
 e.g. two finger drag motion
 @param delta the difference between this touch and the last
 @param absolute the total translation from start of touch
 */
-(void) handleSecondaryTouchDelta:(CGPoint) delta withAbsolute:(CGPoint) absolute;

/** zoom control
 e.g. two finger pinch
 @param scale the scale value passed by the gesture recognizer
 */
-(void) handleZoomScale:(float) scale;


/** sets the baseline dolly value to zoom against
 
 */
-(void) setZoomStart;


/** alternates between camera modes
 
 */
-(void) toggleCameraMode;

/** returns true if the camera is pill
 
 */
-(BOOL) isCameraPill;

@end

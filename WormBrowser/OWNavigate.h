//
//    OpenWorm Browser for iOS **
//
//    Developed for the OpenWorm.org project.
//    Inspired / ported from Google Body Browser (now https://code.google.com/p/open-3d-viewer/)
//    Released under MIT license
//
//    Copyright 2012 Rich Stoner
//
//    Permission is hereby granted, free of charge, to any person obtaining
//    a copy of this software and associated documentation files (the
//    "Software"), to deal in the Software without restriction, including
//    without limitation the rights to use, copy, modify, merge, publish,
//    distribute, sublicense, and/or sell copies of the Software, and to
//    permit persons to whom the Software is furnished to do so, subject to
//    the following conditions:
//
//    The above copyright notice and this permission notice shall be
//    included in all copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//    NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
//    LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
//    OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//    WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

//
//  OWNavigate.h
//  WormBrowser
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
    
    OWInterpolant* mRotateLocalX;
    OWInterpolant* mRotateLocalY;
    OWInterpolant* mTranslateLocalX;
    OWInterpolant* mTranslateLocalY;
    OWInterpolant* mTranslateLocalZ;
    
    OWCamera* camera;
    
    float initialDollyZ;
}

@property float aspectRatio;
@property(nonatomic, strong) OWInterpolant* mDollyZ;
@property(nonatomic, strong) OWInterpolant* mDollyY;
@property(nonatomic, strong) OWInterpolant* mTheta;

@property(nonatomic, strong) OWInterpolant* mRotateLocalX;
@property(nonatomic, strong) OWInterpolant* mRotateLocalY;

@property(nonatomic, strong) OWInterpolant* mTranslateLocalX;
@property(nonatomic, strong) OWInterpolant* mTranslateLocalY;
@property(nonatomic, strong) OWInterpolant* mTranslateLocalZ;


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

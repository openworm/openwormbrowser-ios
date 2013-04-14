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
//  OWNavigate.m
//  WormBrowser
//

#import "OWNavigate.h"

typedef enum {
    cameraStatePill,
    cameraStateFree,
    cameraStateReturning,
    cameraStateGoing,
} OWCameraState;


@interface OWNavigate ()
{
    OWCameraState currentCameraState;
}

-(GLfloat) projectedMinMaxForEntity:(OWEntityInfo*) entity forVector:(GLKVector3) projectionVector;
-(float) absoluteLimit:(float)value forLimit:(float) absLimit withNewValue:(float)newValue;
-(void) doNavigateWithAngle:(float)angle forY:(float)y forZoom:(float)zoom;
-(void) doNavigateWithAngle:(float)angle forY:(float)y forZoom:(float)zoom withUrgency:(float)urgency;

@end

@implementation OWNavigate

@synthesize aspectRatio;
@synthesize mTheta, mDollyY,mDollyZ;
@synthesize mTranslateLocalX, mTranslateLocalY, mTranslateLocalZ;
@synthesize mRotateLocalX, mRotateLocalY;

#pragma mark - initialization methods -

- (id)init
{
    self = [super init];
    if (self) {
        
        currentCameraState = cameraStateFree;

        mTheta = [[OWInterpolant alloc] initWithValue:(float)M_PI];
        mDollyY = [[OWInterpolant alloc] initWithValue:0];
        mDollyZ = [[OWInterpolant alloc] initWithValue:35.0f];
        
        mRotateLocalX = [[OWInterpolant alloc] initWithValue:0];
        mRotateLocalY = [[OWInterpolant alloc] initWithValue:0];
        
        mTranslateLocalX = [[OWInterpolant alloc] initWithValue:0];
        mTranslateLocalY = [[OWInterpolant alloc] initWithValue:0];
        mTranslateLocalZ = [[OWInterpolant alloc] initWithValue:0];
        
        
        mInterpolants = [[NSMutableArray alloc] init];
        [mInterpolants addObject:mTheta];
        [mInterpolants addObject:mDollyY];
        [mInterpolants addObject:mDollyZ];
        [mInterpolants addObject:mRotateLocalX];
        [mInterpolants addObject:mRotateLocalY];
        [mInterpolants addObject:mTranslateLocalX];
        [mInterpolants addObject:mTranslateLocalY];
        [mInterpolants addObject:mTranslateLocalZ];
        
        camera = [[OWCamera alloc] init];
        
        camera.eye = GLKVector3Make(-35,0,0);
        camera.target = GLKVector3Make(0,0,0);
        camera.up = GLKVector3Make(0,1,0);
        camera.fov = 50;
        
        initialDollyZ  = -35.0f;
        
        
    }
    return self;
}




-(BOOL) isCameraPill
{
    switch (currentCameraState) {
        case cameraStateReturning:
        case cameraStatePill:

            return YES;
            
            break;
            

        case cameraStateFree:
        case cameraStateGoing:
            
            return NO;
            
        default:
            break;
    }
}





#pragma mark - private methods -

-(GLfloat) projectedMinMaxForEntity:(OWEntityInfo*) entity forVector:(GLKVector3) projectionVector
{
    
    GLKVector3 verts[8];
    GLfloat proj[8];
    
    verts[0] = GLKVector3Make(entity.bbl.x, entity.bbl.y, entity.bbl.z);
    verts[1] = GLKVector3Make(entity.bbl.x, entity.bbh.y, entity.bbl.z);
    verts[2] = GLKVector3Make(entity.bbl.x, entity.bbl.y, entity.bbh.z);
    verts[3] = GLKVector3Make(entity.bbl.x, entity.bbh.y, entity.bbh.z);
    verts[4] = GLKVector3Make(entity.bbh.x, entity.bbl.y, entity.bbl.z);
    verts[5] = GLKVector3Make(entity.bbh.x, entity.bbh.y, entity.bbl.z);
    verts[6] = GLKVector3Make(entity.bbh.x, entity.bbl.y, entity.bbh.z);
    verts[7] = GLKVector3Make(entity.bbh.x, entity.bbh.y, entity.bbh.z);
    
    for (int v =0; v < 8; v++) {
        
        GLKVector3 vertVector = GLKVector3Subtract(verts[v], camera.eye);
        proj[v] = GLKVector3DotProduct(projectionVector, vertVector);
        
    }
    
    float maxVal = MAXFLOAT*-1;
    float minVal = MAXFLOAT;
    
    for (int v = 0; v < 8; v++) {
        
        minVal = fminf(minVal, proj[v]);
        maxVal = fmaxf(maxVal, proj[v]);
        
//        printf("max min: %f %f\n", maxVal, minVal);        
    }
    

    
    return maxVal - minVal;
}



-(void) delayedEntityNavigation:(OWEntityInfo*)entity
{
    GLKVector3 centerPoint = GLKVector3DivideScalar(GLKVector3Add(entity.bbl, entity.bbh), 2);
    
    float dYAxis = sqrtf(powf(centerPoint.z, 2) + powf(centerPoint.x, 2));
    float x = (atanf(centerPoint.z / centerPoint.x) ) + M_PI_2;
    float projectedHeight = [self projectedMinMaxForEntity:entity forVector:camera.up];
    
    //    NSLog(@"x: %f , projected height: %f", x, projectedHeight);
    
    float y_angle = 0.5f * GLKMathDegreesToRadians(camera.fov);
    float zy_dist = projectedHeight / tanf(y_angle);
    
    GLKVector3 sideVector = GLKVector3CrossProduct(camera.up, GLKVector3Subtract(camera.eye, camera.target));
    sideVector = GLKVector3Normalize(sideVector);
    
    float projectedWidth = [self projectedMinMaxForEntity:entity forVector:sideVector];
    
    //    NSLog(@"This alg thinks the object is %f x %f", projectedWidth, projectedHeight); // 12 x 2... this sounds correct
    
    float x_angle = 0.5f * GLKMathDegreesToRadians(camera.fov * self.aspectRatio);
    float zx_dist = projectedWidth / tanf(x_angle);
    float z_dist = MAX(zy_dist, zx_dist);
    
    //    NSLog(@"xyz: %f %f %f %f %f : %f", 180 * x / M_PI, centerPoint.y, dYAxis + z_dist, camera.fov, self.aspectRatio, dYAxis);
    
    [self doNavigateWithAngle:x forY:centerPoint.y forZoom:dYAxis + z_dist withUrgency:0.25];
   
}



-(float) absoluteLimit:(float)value forLimit:(float) absLimit withNewValue:(float)newValue
{
    if (value < absLimit && value > - absLimit)
        return newValue;
    return value;
}

#pragma mark - public methods -


-(OWCamera*) getCamera
{
    return camera;
}



-(void) recalculate
{

    [OWInterpolant tweenAll:mInterpolants];
        //
        //    NSLog(@"recalc: %f %f %f", mTheta.present, mDollyY.present, mDollyZ.present);
        //    NSLog(@"future: %f %f %f", mTheta.future, mDollyY.future, mDollyZ.future);
        //
    
    // part of integration
    if (currentCameraState == cameraStatePill || currentCameraState == cameraStateFree) {
        
        
        float angle = mTheta.present;
        float z_val = mDollyZ.present;
        float y_val = mDollyY.present;
        //
        float cx = z_val * cosf(angle);
        float cy = y_val;
        float cz = z_val * sinf(angle);
        float ty = y_val;
        //
        float rotLimit = rotationStartPercent * VERTICAL_PAN_LIMIT;
        float phi_multiplier = 0;
        float vertDist = cy;
        float topStartRotation = VERTICAL_PAN_LIMIT - rotLimit;
        
        if (cy < rotLimit) {
            phi_multiplier = -1;
            ty = rotLimit;
            vertDist = rotLimit - vertDist;
        }
        else if (cy > topStartRotation)
        {
            //        NSLog(@" we are in > than regime");
            phi_multiplier = 1;
            ty = topStartRotation;
            vertDist = rotLimit - (VERTICAL_PAN_LIMIT - cy);
        }
        
        if (phi_multiplier != 0)
        {
            //        NSLog(@" we are in rotate regime?");
            
            float phi = phi_multiplier * M_PI_2 * (vertDist / VERTICAL_ADJUSTMENT);
            
            cx *= cosf(phi);
            cy = ty + z_val * sinf(phi);
            cz *= cosf(phi);
            
            float up_phi = M_PI_2 - phi;
            
            camera.up = GLKVector3Make(- cosf(angle) * cosf(up_phi) , sinf(up_phi), -sinf(angle)*cosf(up_phi));
            
        }
        else{
            camera.up = GLKVector3Make(0, 1, 0);
        }
        
        camera.eye = GLKVector3Make(cx, cy, cz);
        
        #define RADIANS_PER_PIXEL (M_PI / 320.f)
        
// Added 3/26/13 - Adding a local camera transform on top of pill camera
// Built on quaternians. Not the most efficient but will suffice
        
        GLKVector3 up = camera.up;
        GLKVector3 baseTargetVector = GLKVector3Make(0, ty, 0);
        
        GLKVector3 right = GLKVector3Normalize(GLKVector3CrossProduct(GLKVector3Subtract(baseTargetVector, camera.eye), camera.up));
        
        GLKQuaternion quarternion = GLKQuaternionMake(0.f, 0.f, 0.f, 1.f);
        quarternion = GLKQuaternionMultiply(quarternion, GLKQuaternionMakeWithAngleAndVector3Axis(mRotateLocalX.present * RADIANS_PER_PIXEL, up));
        
        quarternion = GLKQuaternionMultiply(quarternion, GLKQuaternionMakeWithAngleAndVector3Axis(mRotateLocalY.present * RADIANS_PER_PIXEL, right));
  
        GLKVector3 rotatedTarget = GLKQuaternionRotateVector3(quarternion, GLKVector3Subtract(baseTargetVector, camera.eye));
        
        GLKVector3 translationVector = GLKVector3Make(mTranslateLocalX.present, mTranslateLocalY.present, mTranslateLocalZ.present);
        
        camera.target = GLKVector3Add(rotatedTarget, translationVector);
        camera.eye = GLKVector3Add(camera.eye, translationVector);
        
        
        
//        camera.target = rotatedTarget;
        
        
    }
    else if(currentCameraState == cameraStateReturning)
    {
        
        GLKVector3 targetUp, targetEye, targetTarget;
        
        float angle = mTheta.present;
        float z_val = mDollyZ.present;
        float y_val = mDollyY.present;
        float cx = z_val * cosf(angle);
        float cy = y_val;
        float cz = z_val * sinf(angle);
        float ty = y_val;
        //
        float rotLimit = rotationStartPercent * VERTICAL_PAN_LIMIT;
        float phi_multiplier = 0;
        float vertDist = cy;
        float topStartRotation = VERTICAL_PAN_LIMIT - rotLimit;
        
        if (cy < rotLimit) {
            phi_multiplier = -1;
            ty = rotLimit;
            vertDist = rotLimit - vertDist;
        }
        else if (cy > topStartRotation)
        {
            //        NSLog(@" we are in > than regime");
            phi_multiplier = 1;
            ty = topStartRotation;
            vertDist = rotLimit - (VERTICAL_PAN_LIMIT - cy);
        }
        
        if (phi_multiplier != 0)
        {
            
            float phi = phi_multiplier * M_PI_2 * (vertDist / VERTICAL_ADJUSTMENT);
            cx *= cosf(phi);
            cy = ty + z_val * sinf(phi);
            cz *= cosf(phi);
            
            float up_phi = M_PI_2 - phi;
            
             targetUp = GLKVector3Make(- cosf(angle) * cosf(up_phi) , sinf(up_phi), -sinf(angle)*cosf(up_phi));
            
        }
        else{
            targetUp = GLKVector3Make(0, 1, 0);
        }
        
        targetEye = GLKVector3Make(cx, cy, cz);
        targetTarget = GLKVector3Make(0, ty, 0);
        
        GLKVector3 dVeye = GLKVector3Subtract(targetEye, camera.eye);
        GLKVector3 dVup = GLKVector3Subtract(targetUp, camera.up);
        GLKVector3 dVtarget = GLKVector3Subtract(targetTarget, camera.target);
        
        if( GLKVector3Length(dVeye) < 0.01 && GLKVector3Length(dVup) < 0.01 && GLKVector3Length(dVtarget) < 0.01)
        {
            currentCameraState = cameraStatePill;
        }
        else
        {
            camera.eye = GLKVector3Add(camera.eye, GLKVector3MultiplyScalar(dVeye, 0.1));
            camera.target = GLKVector3Add(camera.target, GLKVector3MultiplyScalar(dVtarget, 0.1));
            camera.up = GLKVector3Add(camera.up, GLKVector3MultiplyScalar(dVup, 0.1));
        }
    }
}


-(void) goToForEntity:(OWEntityInfo*)entity withUrgency:(float) urgency
{
    currentCameraState = cameraStateReturning;

    [self performSelector:@selector(delayedEntityNavigation:) withObject:entity afterDelay:0.0];
}



#pragma mark - new touch controls -

-(void) toggleCameraMode
{
    switch (currentCameraState) {
        case cameraStateFree:
            printf("free -> pill");
            
            currentCameraState = cameraStatePill;
            
            break;
            
        case cameraStatePill:
            printf("pill -> free");
            
            currentCameraState = cameraStateFree;
            
            break;
            
        case cameraStateGoing:
            printf("going ->");
            
        default:
            break;
    }
}

-(void) handlePrimaryTouchDelta:(CGPoint)delta withAbsolute:(CGPoint)absolute
{
    switch (currentCameraState) {
        case cameraStateFree:
            
            [self translateLocalDX:delta.x DY:delta.y];
            
            break;
            
        case cameraStatePill:

            [self doNavigateDeltaX:delta.x/40 DeltaY:delta.y/40 DeltaZ:0];
            
            break;
                        
        default:
            break;
    }
}



-(void) handleSecondaryTouchDelta:(CGPoint)delta withAbsolute:(CGPoint)absolute
{
    switch (currentCameraState) {
        case cameraStateFree:
            
             [self rotateLocalDX:delta.x DY:delta.y];            
            
            break;
            
        case cameraStatePill:
            
// RMS 4/2/13 -> combined camera controls (removing 'free' mode)
//             [self rotateLocalDX:delta.x DY:delta.y];
            
            [self translateLocalDX:delta.x DY:delta.y];            
            
            break;
            
        default:
            break;
    }
}


-(void) rotateLocalDX:(float)dx DY:(float)dy
{

    // RMS 4/1/13
    // decreased sensitivity on rotate ( 1.0 to 0.5)
    
    [mRotateLocalX setFuture:(mRotateLocalX.future + dx*0.5) withUrgency:1.0];
    [mRotateLocalY setFuture:(mRotateLocalY.future + dy*0.5) withUrgency:1.0];
    
}

-(void) translateLocalDX:(float)dx DY:(float)dy
{
    // get local coordinate frame, translate
    GLKVector3 sideVector = GLKVector3CrossProduct(camera.up, GLKVector3Subtract(camera.target, camera.eye));
    sideVector = GLKVector3Normalize(sideVector);
    
// RMS 4/1/13
// decreased sensitivity on translate (0.05 to 0.04)
    
// RMS 4/2/13
// Greatly reduced sensitivity on translate (0.04 to 0.01)

// Readjusted to 0.06
// Added zoom-sensitive scaling
    float camera_scale = mDollyZ.present / 80;
    
    GLKVector3 camDX = GLKVector3MultiplyScalar(sideVector, dx*0.1*camera_scale);
    GLKVector3 camDY = GLKVector3MultiplyScalar(camera.up, dy*0.1*camera_scale);
    
// RMS 4/11/13 - > modified to keep translation along Z axis (Anterior - Posterior translation)

    //    [mTranslateLocalX setFuture:(mTranslateLocalX.future + camDX.x + camDY.x) withUrgency:1.0]; -> uncomment to enable ML translation
    //    [mTranslateLocalY setFuture:(mTranslateLocalY.future + camDX.y + camDY.y) withUrgency:1.0]; -> uncomment to enable SI translation
    
    // adding clamp to domain (there has to be a more efficient comparison, this was done on little sleep with no internet)
    float futureVal = mTranslateLocalZ.future + camDX.z + camDY.z;
    float APoffset = 5.0;
    
    if (futureVal > APoffset)
    {
        futureVal = APoffset;
    }
    else if (futureVal < - APoffset)
    {
        futureVal = - APoffset;
    }
    
    [mTranslateLocalZ setFuture:(futureVal) withUrgency:1.0];
    
}

-(void) zoomLocalScale:(float)scale
{
    GLKVector3 lookVector = GLKVector3Subtract(camera.eye, camera.target);
//    float mag = sqrtf(powf(lookVector.x, 2) + powf(lookVector.y, 2));
    float mag = 0.01f; // using this instead, zoom occurs at fixed speed invariant of position relative to model
    
    GLKVector3 movementVector = GLKVector3MultiplyScalar(lookVector, mag*scale);
    [mTranslateLocalX setFuture:(mTranslateLocalX.future + movementVector.x) withUrgency:1.0];
    [mTranslateLocalY setFuture:(mTranslateLocalY.future + movementVector.y) withUrgency:1.0];
    [mTranslateLocalZ setFuture:(mTranslateLocalZ.future + movementVector.z) withUrgency:1.0];

}


-(void) handleZoomScale:(float)scale
{
    switch (currentCameraState) {
        case cameraStateFree:

            
            // recenter scale to 0 +/- change
            [self zoomLocalScale:(-1 * (scale - 1))];

            break;
            
        case cameraStatePill:
            
            [self scaledZoom:scale];
            
            break;
            
        default:
            break;
    }
}







#pragma mark - deprecated methods -

-(void) doNavigateWithAngle:(float)angle forY:(float)y forZoom:(float)zoom
{
    [self doNavigateWithAngle:angle forY:y forZoom:zoom withUrgency:0.1f];
}

-(void) doNavigateWithAngle:(float)angle forY:(float)y forZoom:(float)zoom withUrgency:(float)urgency
{
    [mTheta setFuture:angle withUrgency:urgency];
    
    float verticalLowerLimit = -VERTICAL_ADJUSTMENT;
    float verticalUpperLimit = VERTICAL_PAN_LIMIT + VERTICAL_ADJUSTMENT;

    if (y < verticalLowerLimit) {
        
        y = verticalLowerLimit;
    }
    
    if (y > verticalUpperLimit)
    {
        //  at upper limit
        y = verticalUpperLimit;
    }
    
    [mDollyY setFuture:y withUrgency:urgency];
    
    if (zoom < ZOOM_NEAR_LIMIT) {
        zoom = ZOOM_NEAR_LIMIT;
    }
    
    if (zoom > ZOOM_FAR_LIMIT) {
        zoom = ZOOM_FAR_LIMIT;
    }
    
    [mDollyZ setFuture:zoom withUrgency:urgency];
}

-(void) reset
{
    [self doNavigateWithAngle:M_PI forY:0 forZoom:11];
}

-(void) updateDeltDollyY:(float)dy
{
    float camera_scale = mDollyZ.present / 80;
    
    [mDollyY setFuture:mDollyY.future + camera_scale*dy withUrgency:1.0f];
}

-(void) updateThetaX:(float)dx
{
    float camera_scale = mDollyZ.present / 80;
    [mTheta setFuture:mTheta.future + camera_scale*dx withUrgency:1.0f];
}

-(void) doNavigateDeltaX:(float)dx DeltaY:(float)dy DeltaZ:(float)dz
{
    float camera_scale = mDollyZ.present / 80;
    
    float constant_scale = 0.25;
    
    //    NSLog(@"camera scale: %f, %f %f %f", camera_scale, mTheta.future + camera_scale*dx, mDollyY.future + camera_scale*dy, mDollyZ.future + camera_scale*dz);
    [self doNavigateWithAngle:mTheta.future + constant_scale*dx
                         forY:mDollyY.future + 1.1*camera_scale*dy
                      forZoom:mDollyZ.future + camera_scale*dz withUrgency:1.0f];
}

-(void) setZoomStart
{
    if(currentCameraState == cameraStatePill)
    {
        initialDollyZ = mDollyZ.future;
    }
    else
    {
        GLKVector3 lookVector = GLKVector3Subtract(camera.eye, camera.target);
        initialDollyZ = sqrtf(powf(lookVector.x, 2) + powf(lookVector.y, 2));
    }
    
    // resets dolly zoom to 2 as a way to quickly pull out.
    if (initialDollyZ < 2) {
        initialDollyZ = 2;
    }
}

-(void) scaledZoom:(float) dz
{

    float offset = initialDollyZ + (1 - dz)*initialDollyZ / 2;
    
//    float offset = (1 - (dz - 1)) * initialDollyZ/2 ;
//    NSLog(@"dz %f, %f, %f",dz, 1 - (dz - 1) , offset);
//    float offset = 2*initialDollyZ - ( dz * initialDollyZ );
//    float offset = dz * initialDollyZ;
//    NSLog(@"%f", offset);
    
    [self doNavigateWithAngle:mTheta.future
                         forY:mDollyY.future
                      forZoom:offset
                  withUrgency:1.0f];
    
}

-(void) printVector3:(GLKVector3)inputVec
{
    NSLog(@"vec3: %f %f %f", inputVec.x, inputVec.y, inputVec.z);
}



-(void) dragDeltaX:(float)dx DeltaY:(float)dy
{
    float deltaRotate = ROTATION_REDUCTION * dx;
    float deltaPan = VERTICAL_REDUCTION * dy;
    
    deltaPan = [self absoluteLimit:deltaPan forLimit:START_PAN withNewValue:0];
    
    [self doNavigateDeltaX:deltaRotate DeltaY:deltaPan DeltaZ:0];
}

-(void) scrollDeltaY:(float)dy
{
    [self doNavigateDeltaX:0 DeltaY:0 DeltaZ:-dy*ZOOM_REDUCTION];
}




@end

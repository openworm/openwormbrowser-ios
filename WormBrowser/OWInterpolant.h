//
//  OWInterpolant.h
//  WormBrowser
//
//  Created by Rich Stoner on 12/2/12.
//  Copyright (c) 2012 Rich Stoner. All rights reserved.
//

#import <Foundation/Foundation.h>

#define fEPSILON 0.001f

/** OWInterpolant description
    based off of the original open-3d-viewer interpolant
 */
@interface OWInterpolant : NSObject
{
@private
    float mPast;
    float mPresent;
    float mFuture;
    float mUrgency;
    
}

@property(readonly) float present;
@property(readonly) float future;

/**
 @param value sets future during init
 */
- (id)initWithValue:(float) value;

/**
 @param future destination value
 @param urgency how fast to arrive
 */
-(void) setFuture:(float)future withUrgency:(float) urgency;

/**
 
 */
-(BOOL) tween;

/**
 @param t time point
 @param p0 1 of 4 point Bezier 
 @param p1 2 of 4 point Bezier
 @param p2 3 of 4 point Bezier
 @param p3 4 of 4 point Bezier
 */
-(float) bezierPoint:(float) t p0:(float)p0  p1:(float)p1 p2:(float) p2 p3:(float)p3;

/**
 @param interpolants list of interpolants to iterate
 */
+(BOOL) tweenAll:(NSArray*)interpolants;

@end
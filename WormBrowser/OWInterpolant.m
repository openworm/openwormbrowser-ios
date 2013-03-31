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
//  OWInterpolant.m
//  WormBrowser
//

#import "OWInterpolant.h"



@interface BezierClass : NSObject
{
    float x0;
    float x1;
    float x2;
    float x3;
}

-(id) initWithValuesX0:(float)x0 X1:(float)x1 X2:(float)x2 X3:(float)x3;
-(float) getPointForT:(float)t;
-(float) lerpForX0:(float)x0 X1:(float)x1 forT:(float)t;

@end

@implementation BezierClass

- (id)initWithValuesX0:(float)_x0 X1:(float)_x1 X2:(float)_x2 X3:(float)_x3
{
    self = [super init];
    if (self) {
        
        x0 = _x0;
        x1 = _x1;
        x2 = _x2;
        x3 = _x3;
    }
    return self;
}

-(float) getPointForT:(float)t
{
    if (t ==0) {
        return x0;
    }
    else if(t==1)
    {
        return x3;
    }
    
    float ix0 = [self lerpForX0:x0 X1:x1 forT:t];
    float ix1 = [self lerpForX0:x1 X1:x2 forT:t];
    float ix2 = [self lerpForX0:x2 X1:x3 forT:t];
    
    ix0 = [self lerpForX0:ix0 X1:ix1 forT:t];
    ix1 = [self lerpForX0:ix1 X1:ix2 forT:t];
    return [self lerpForX0:ix0 X1:ix1 forT:t];
    
}

-(float) lerpForX0:(float)_x0 X1:(float)_x1 forT:(float)_t
{
    return _x0 + _t*(_x1 - _x0);
    
}

@end




@implementation OWInterpolant

@synthesize present = mPresent;
@synthesize future = mFuture;

- (id)initWithValue:(float) value
{
    self = [super init];
    if (self) {
        
        mPast = value;
        mPresent = value;
        mFuture = value;
        mUrgency = 0.25f;
        
    }
    return self;
}

-(void) setFuture:(float)_future withUrgency:(float)urgency
{
    mUrgency = urgency;
    mFuture = _future;
}

-(float) bezierPoint:(float) t p0:(float)p0  p1:(float)p1 p2:(float) p2 p3:(float)p3
{
    return powf(1-t, 3) * p0 + 3 * powf(1-t, 2) * t * p1 + 3 * (1-t) * powf(t, 2) * p2 + powf(t, 3) * p3;
}

-(BOOL) tween
{
    if(fabsf(mFuture - mPresent) < fEPSILON)
    {
        mPast = mFuture;
        mPresent = mFuture;
        return NO;
    }
    
    BezierClass* b = [[BezierClass alloc] initWithValuesX0:mPast X1:2*mPresent-mPast X2:2*mFuture-mPresent X3:mFuture];
    mPast = mPresent;
    mPresent = [b getPointForT:mUrgency];
    
    //    mPresent = [self bezierPoint:mUrgency p0:mPast p1:2*mPresent - mPast p2:2*mFuture - mPresent p3:mFuture];
    
    return YES;
}

+(BOOL) tweenAll:(NSArray*)interpolants
{
    BOOL ret = NO;
    
    for (OWInterpolant* interpolant in interpolants) {
        
        ret |= [interpolant tween];
        
    }
    return ret;
}


@end

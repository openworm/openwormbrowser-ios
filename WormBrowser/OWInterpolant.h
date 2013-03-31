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
//  OWInterpolant.h
//  WormBrowser
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
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
//  WSEntityInfo.m
//  OpenWormViewer
//

#import "OWEntityInfo.h"

@implementation OWEntityInfo

@synthesize layer, bbl, bbh, displayName, indexCount, indexOffset, entityID;
//@synthesize bb0, bb1, bb2, bb3, bb4, bb5;

- (id)init
{
    self = [super init];
    if (self) {
        
        self.displayName = @"";
        self.entityID = -1;
        self.layer = -1;
        self.indexCount = 0;
        self.indexOffset = 0;
        
        self.bbh = GLKVector3Make(0, 0, 0);
        self.bbl = GLKVector3Make(0, 0, 0);
        
//        bb0 = bb1 = bb2 = bb3 = bb4 = bb5 = 0.0f;
        
    }
    return self;
}

-(void) printDebugString
{
    NSLog(@"Entity %@", self.displayName);
    NSLog(@"\tEntity ID: %d", self.entityID);
    NSLog(@"\tLayer: %d", self.layer);
    NSLog(@"\tindex Count: %d", self.indexCount);
    NSLog(@"\tindex offset: %d", self.indexOffset);
    NSLog(@"\tBB high: %f %f %f", self.bbh.x, self.bbh.y, self.bbh.z);
    NSLog(@"\tBB low : %f %f %f", self.bbl.x, self.bbl.y, self.bbl.z);
    
}


@end

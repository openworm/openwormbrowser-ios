//
//  WSEntityInfo.m
//  OpenWormViewer
//
//  Created by Rich Stoner on 10/20/12.
//  Copyright (c) 2012 Rich Stoner. All rights reserved.
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

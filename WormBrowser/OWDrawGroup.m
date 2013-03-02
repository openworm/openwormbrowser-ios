//
//  OWDrawGroup.m
//  WormBrowser
//
//  Created by Rich Stoner on 12/2/12.
//  Copyright (c) 2012 Rich Stoner. All rights reserved.
//

#import "OWDrawGroup.h"

@implementation OWDrawGroup

@synthesize vertexBuffer, indexBuffer, numIndices, vertexBufferData, indexBufferData, colorBufferData, diffuseColor, draws, boundingBoxData;

- (id)init
{
    self = [super init];
    if (self) {
        self.draws = [[NSMutableArray alloc] init];
    }
    return self;
}

@end

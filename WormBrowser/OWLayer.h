//
//  OWLayer.h
//  WormBrowser
//
//  Created by Rich Stoner on 12/2/12.
//  Copyright (c) 2012 Rich Stoner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OWInterpolant.h"

@interface OWLayer : NSObject
{
    
}

@property BOOL      isVisibleTarget;
@property BOOL      isLoaded;
@property int       type;
@property(strong, nonatomic) OWInterpolant*  opacity;
@property(strong, nonatomic) NSMutableArray* drawGroups;
@property GLfloat   renderOpacity;
@property int       totalDrawCount;

-(id) initWithInfo:(int)_info;

-(void) loadDrawGroupsInContext:(EAGLContext*) context;

-(void) printDebugString;

@end

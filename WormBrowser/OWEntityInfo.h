//
//  WSEntityInfo.h
//  OpenWormViewer
//
//  Created by Rich Stoner on 10/20/12.
//  Copyright (c) 2012 Rich Stoner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

/** OWEntityInfo description
 
 */
@interface OWEntityInfo : NSObject
{
    int layer;
    int entityID;

    GLuint indexOffset;
    GLuint indexCount;

    GLKVector3 bbl;
    GLKVector3 bbh;
    
    NSString* displayName;
    
}

@property int layer;
@property int entityID;
@property GLuint indexOffset;
@property GLuint indexCount;

@property GLKVector3 bbl;
@property GLKVector3 bbh;
@property(nonatomic, strong) NSString* displayName;

-(void) printDebugString;

@end

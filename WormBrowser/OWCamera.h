//
//  OWCamera.h
//  WormBrowser
//
//  Created by Rich Stoner on 12/4/12.
//  Copyright (c) 2012 Rich Stoner. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OWCamera : NSObject

@property GLKVector3 eye;
@property GLKVector3 target;
@property GLKVector3 up;
@property GLfloat   fov;


@end

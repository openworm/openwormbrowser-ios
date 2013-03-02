//
//  OWDraw.h
//  WormBrowser
//
//  Created by Rich Stoner on 12/2/12.
//  Copyright (c) 2012 Rich Stoner. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OWDraw : NSObject
{
}

@property(nonatomic, strong) NSString* geometry;
@property GLKVector4 selectColor;
@property GLuint offset;
@property GLuint count;

@end

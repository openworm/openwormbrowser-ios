//
//  OWDrawGroup.h
//  WormBrowser
//
//  Created by Rich Stoner on 12/2/12.
//  Copyright (c) 2012 Rich Stoner. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OWDrawGroup : NSObject
{
//@public
  
//    GLuint colorBuffer;
    
//    NSString* texture;
//    GLuint diffuseTexture;
//    UIImage* loadedDiffuseTexture;
//    Texture* loadedCompressedDiffuseTexture;
    

}

@property vertexDataTextured* vertexBufferData;
@property GLushort* indexBufferData;
@property GLushort* colorBufferData;
@property float* boundingBoxData;

@property GLuint numIndices;
@property GLuint indexBuffer;
@property GLuint vertexBuffer;

@property GLKVector4 diffuseColor;
@property(nonatomic, strong) NSMutableArray* draws;


@end

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
//  OWLayer.m
//  WormBrowser
//


#import "OWLayer.h"
#import "OWEntityInfo.h"
#import "OWDraw.h"
#import "OWDrawGroup.h"
#import "OWResource.h"

@implementation OWLayer

@synthesize isVisibleTarget, type, opacity, drawGroups, totalDrawCount;

- (id)initWithInfo:(int)_info
{
    self = [super init];
    if (self) {
        
        self.type = _info;
        
        
        
    }
    return self;
}


-(void) loadDrawGroupsInContext:(EAGLContext *)context
{
    
    // we're using an index for each draw subgroup
    // red channel = layer
    // green channel = drawgroup
    // blue channel = draw
    
    int draw_index = 0;
    int draw_group_index = 0;
    self.totalDrawCount = 0;
    
    // initialize drawGroup array
    drawGroups = [[NSMutableArray alloc] init];

    OWAppDelegate* delegate = AppDelegate;
    OWResource* resource = delegate.resource;

    // get loading parameters (decode params)
    int strideLength = 8;
    NSArray* decodeScales = [[resource getDecodeParameters] objectForKey:@"decodeScales"];
    NSArray* decodeOffsets = [[resource getDecodeParameters] objectForKey:@"decodeOffsets"];
    
    GLfloat decodeScaleVals[] ={1/8191, 1/8191, 1/8191, 1/1023, 1/1023, 1/1023, 1/1023, 1/1023};
    GLfloat decodeOffsetVals[] = {-4095, -4095, -4095, 0, 0, -511, -511, -511};
    
    for (int i = 0; i < strideLength; i++)
    {
        decodeScaleVals[i] = [[decodeScales objectAtIndex:i] floatValue];
        decodeOffsetVals[i] = [[decodeOffsets objectAtIndex:i] floatValue];
    }

    // load list of layers
    NSArray* layerList = [resource remapDAGtoNodeName:[resource getDAGForID:@1]];
    NSArray* layerInfo = [layerList objectAtIndex:self.type];
    NSNumber* layerID = [layerInfo objectAtIndex:0];
    NSArray* resourceInformation = [resource remapDAGtoEntityName:[resource getDAGForID:layerID]];

//    NSLog(@"%@", resourceInformation);
    
    // resourceInformation now contains an array of entities
    // each object contains the entityID and the display name
    
/*
    start loading mesh data into drawGroups
*/
    
    
    // set active context
    [EAGLContext setCurrentContext:context];

    
    // from the list of objects, get list of files to open
    NSArray* fileList = [resource getFileListForResourceInfo:resourceInformation];

//    NSLog(@"File list for %@ : %@", [layerInfo objectAtIndex:1], fileList);
 
    for (NSString* fileName in fileList) {
        
        NSArray* meshList = [resource getMeshListForFile:fileName];
//        NSLog(@" %d submesh(es) to load.", [meshList count]);
        
        // each submesh is a drawgroup
        for (NSDictionary* meshDictionary in meshList) {
            
//            NSLog(@"%@", meshDictionary);
            
            OWDrawGroup* drawGroup = [[OWDrawGroup alloc] init];
            NSString* materialName = [meshDictionary objectForKey:@"material"];
            [drawGroup setDiffuseColor:[resource getDiffuseColorForMaterial:materialName]];
            
            // parameters for attribute / vertice data
            int attribStart = [[[meshDictionary objectForKey:@"attribRange"] objectAtIndex:0] intValue];
            int numVerts = [[[meshDictionary objectForKey:@"attribRange"] objectAtIndex:1] intValue];
            int inputOffset = attribStart;
            
            NSData* meshData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[fileName stringByDeletingPathExtension] ofType:@"utf8"]];
            
            NSString* meshString = [[NSString alloc] initWithData:meshData encoding:NSUTF8StringEncoding];
            
            drawGroup.vertexBufferData = malloc(sizeof(vertexDataTextured) * numVerts);
            
//            drawGroup.colorBufferData = malloc(sizeof(GLushort) * numVerts );
            
            
            //            private void createColorBuffer(DrawGroup drawGroup) {
            //                int numVertices = drawGroup.vertexBufferData.capacity() / 8;  // 3 pos, 3 norm, 2 texcoord
            //
            //                ByteBuffer byteBuffer = ByteBuffer.allocateDirect(numVertices * 2);
            //                byteBuffer.order(ByteOrder.nativeOrder());
            //                drawGroup.colorBufferData = byteBuffer.asShortBuffer();
            //
            //                for (Draw draw : drawGroup.draws) {
            //                    short selectionColor = mMaxColorIndex++;
            //                    mSelectionColorMap.put((int) selectionColor, draw);
            //
            //                    BodyJni.setColorForIndices(
            //                                               drawGroup.colorBufferData, selectionColor,
            //                                               drawGroup.indexBufferData, draw.offset, draw.count);
            //                }
            //            }
            
            
            
            for(int j = 0; j < strideLength; j++)
            {
                int end = inputOffset + numVerts;
                GLfloat scaleval = decodeScaleVals[j];
                
                int outputStart = j;
                if (scaleval > 0) {
                    
                    int prev = 0;
                    for(int k = inputOffset; k < end; k++)
                    {
                        unichar code = [meshString characterAtIndex:k];
                        prev += (code >> 1) ^ (-(code & 1));
                        
                        switch (j) {
                            case 0:
                                 drawGroup.vertexBufferData[outputStart / strideLength].vertex.x = 1* decodeScaleVals[j] * (prev + decodeOffsetVals[j]);
                                
                                break;
                                
                            case 1:
                                
                                 drawGroup.vertexBufferData[outputStart / strideLength].vertex.y = 1*  decodeScaleVals[j] * (prev + decodeOffsetVals[j]);
                                
                                break;
                                
                            case 2:
                                
                                 drawGroup.vertexBufferData[outputStart / strideLength].vertex.z = 1* decodeScaleVals[j] * (prev + decodeOffsetVals[j]);
                                
                                break;
                                
                            case 3:
                                
                                 drawGroup.vertexBufferData[outputStart / strideLength].texCoord.s = decodeScaleVals[j] * (prev + decodeOffsetVals[j]);
                                
                                break;
                                
                            case 4:
                        
                                 drawGroup.vertexBufferData[outputStart / strideLength].texCoord.t = decodeScaleVals[j] * (prev + decodeOffsetVals[j]);
                                
                                break;
                                
                            case 5:
                                 drawGroup.vertexBufferData[outputStart / strideLength].normal.x = decodeScaleVals[j] * (prev + decodeOffsetVals[j]);
                                
                                break;
                                
                            case 6:
                                
                                 drawGroup.vertexBufferData[outputStart / strideLength].normal.y = decodeScaleVals[j] * (prev + decodeOffsetVals[j]);
                                
                                break;
                                
                            case 7:
                                
                                 drawGroup.vertexBufferData[outputStart / strideLength].normal.z = decodeScaleVals[j] * (prev + decodeOffsetVals[j]);
                                
                                break;
                                
                            default:
                                break;
                        }
                        
                        outputStart += strideLength;
                        
                    }
                }
                inputOffset = end;
            }

            // completed loading vertex data into buffer

#pragma mark - index parsing
            
            int indexStart = [[[meshDictionary objectForKey:@"indexRange"] objectAtIndex:0] intValue];
            
            drawGroup.numIndices = 3*[[[meshDictionary objectForKey:@"indexRange"] objectAtIndex:1] intValue];
            
            drawGroup.indexBufferData = malloc(drawGroup.numIndices * sizeof(GLushort));
            
            //    int holdThis = indexStart;
            
            int highest = 0;
            int outputStart = 0;
            for(int k = 0; k < drawGroup.numIndices; k++)
            {
                unichar code = [meshString characterAtIndex:indexStart++];
                drawGroup.indexBufferData[outputStart++] = highest - code;
                if (code==0) {
                    highest++;
                }
            }
            
        
#pragma mark bounding box parsing
            
            int bboffset = [[meshDictionary objectForKey:@"bboxes"] intValue];
            
            if (bboffset > 0) {
                NSArray *meshes = [meshDictionary objectForKey:@"names"];
                int numBBoxen = [meshes count];
                
                int numFloats = numBBoxen * 6;
                int inputStart = bboffset;
                int inputEnd = bboffset + numFloats;
                int outputStart = 0;
                
//                NSLog(@"There are %d bounding boxes", numBBoxen);
                
                drawGroup.boundingBoxData = malloc(sizeof(GLfloat) * numFloats);
                
                int k = 0;
                int lengthOffset = 0;
                
                draw_index = 0;
                
                for(int i =inputStart; i < inputEnd; i+=6)
                {
                    NSString* name = [[meshDictionary objectForKey:@"names"] objectAtIndex:k];
                    NSNumber* length = [[meshDictionary objectForKey:@"lengths"] objectAtIndex:k];
                    
                    OWDraw* draw = [[OWDraw alloc] init];
                    [draw setGeometry:name];
                    [draw setCount:[length intValue]];
                    [draw setOffset:lengthOffset];
                    [draw setSelectColor:GLKVector4Make((float)self.type/256, (float)draw_group_index/256, (float)draw_index/256, 1.0)];
                    
                    [drawGroup.draws addObject:draw];
                    
                    lengthOffset += [length intValue];
                    k++;
                    
                    
                    OWEntityInfo* _entity = [resource getInfoForEntityName:name];
                    [_entity setLayer:self.type];
                    
                    GLfloat minX = [meshString characterAtIndex:i+0] + decodeOffsetVals[0];
                    GLfloat minY = [meshString characterAtIndex:i+1] + decodeOffsetVals[1];
                    GLfloat minZ = [meshString characterAtIndex:i+2] + decodeOffsetVals[2];
                    GLfloat diaX = [meshString characterAtIndex:i+3] + 1;
                    GLfloat diaY = [meshString characterAtIndex:i+4] + 1;
                    GLfloat diaZ = [meshString characterAtIndex:i+5] + 1;
                    
                    drawGroup.boundingBoxData[outputStart++] = decodeScaleVals[0] * minX;
                    drawGroup.boundingBoxData[outputStart++] = decodeScaleVals[1] * minY;
                    drawGroup.boundingBoxData[outputStart++] = decodeScaleVals[2] * minZ; 
                    
                    drawGroup.boundingBoxData[outputStart++] = decodeScaleVals[0] * diaX;
                    drawGroup.boundingBoxData[outputStart++] = decodeScaleVals[1] * diaY;
                    drawGroup.boundingBoxData[outputStart++] = decodeScaleVals[2] * diaZ;
                    
                    if (_entity != nil) {
                        [_entity setBbl:GLKVector3Make( drawGroup.boundingBoxData[outputStart - 6], drawGroup.boundingBoxData[outputStart - 5], drawGroup.boundingBoxData[outputStart - 4])];
                        
                        [_entity setBbh:GLKVector3Make( drawGroup.boundingBoxData[outputStart - 3], drawGroup.boundingBoxData[outputStart - 2], drawGroup.boundingBoxData[outputStart -1])];
                        
                        [resource putInfo:_entity forName:[NSString stringWithFormat:@"%d", _entity.entityID]];
                    }
                    else{
                        NSLog(@"Error setting entity information for %@", name);
                    }
                    

                    draw_index++;
                }
            }

            
//            glGenVertexArraysOES(1, &_vao1);
//            glBindVertexArrayOES(_vao1);
            
            GLuint _vertexBuffer;
            glGenBuffers(1, &_vertexBuffer);
            glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
            glBufferData(GL_ARRAY_BUFFER, sizeof(vertexDataTextured)*numVerts, drawGroup.vertexBufferData, GL_STATIC_DRAW);
            
            [drawGroup setVertexBuffer:_vertexBuffer];
            
            // Vertices
            glEnableVertexAttribArray(GLKVertexAttribPosition);
            glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(vertexDataTextured), (void*)offsetof(vertexDataTextured, vertex)); // for model, normals, and texture
            
            // Normals
            glEnableVertexAttribArray(GLKVertexAttribNormal);
            glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, sizeof(vertexDataTextured), (void*)offsetof(vertexDataTextured, normal)); // for model,
            
            // Texture
            glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
            glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(vertexDataTextured), (void*)offsetof(vertexDataTextured, texCoord)); // for model,
            
            
            GLuint _indexBuffer;
            glGenBuffers(1, &_indexBuffer);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
            glBufferData(GL_ELEMENT_ARRAY_BUFFER, drawGroup.numIndices*sizeof(GLushort), drawGroup.indexBufferData, GL_STATIC_DRAW);

            [drawGroup setIndexBuffer:_indexBuffer];
        
            glBindBuffer(GL_ARRAY_BUFFER,0);
            glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, 0 );
            
//            glBindVertexArrayOES(0);
            

            [self.drawGroups addObject:drawGroup];
            
            draw_group_index++;
            self.totalDrawCount += draw_index;
        }
    }
    
    [self setIsLoaded:YES];
}

-(void) printDebugString
{

    for (OWDrawGroup* drawGroup in self.drawGroups) {

        NSLog(@"%u - %u", drawGroup.vertexBuffer, drawGroup.indexBuffer);
        
        for (OWDraw* draw in drawGroup.draws) {
        
            NSLog(@"%@ : %d , %d", draw.geometry, draw.offset, draw.count);
        }
    }
    
}

@end

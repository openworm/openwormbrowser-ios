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
//  OWResource.h
//  WormBrowser
//

#import <Foundation/Foundation.h>
#import "OWEntityInfo.h"

/** OWResource description
 
 */
@interface OWResource : NSObject

@property(nonatomic, strong) NSDictionary* relationDictionary;
@property(nonatomic, strong) NSDictionary* metaDataDictionary;
@property(nonatomic, strong) NSDictionary* descriptiveDataDictionary;

/**
 List of all layers
 */
-(NSArray*) getLayerList;

/**
 @param layerID layer of interest in graph (int)
 */
-(NSArray*) getLayerListForID:(NSNumber*) layerID;

/**
 @param dagID full graph of entities for ID
 */
-(NSArray*) getDAGForID:(NSNumber*) dagID;

/**
 @param dagArray converts ID to entity names
 */
-(NSArray*) remapDAGtoEntityName:(NSArray*) dagArray;

/**
 @param dagArray converts ID to sorted entity names
 */
-(NSArray*) remapDAGtoSortedEntityName:(NSArray*) dagArray;


/**
 @param nodeArray not sure
 */
-(NSArray*) remapDAGtoNodeName:(NSArray*) nodeArray;

/**
 
 */
-(NSDictionary*) getDecodeParameters;

/**
 
 */
-(NSDictionary*) getMaterialsDictionary;

/**
 @param materialName converts material to color4
 */
-(GLKVector4) getDiffuseColorForMaterial:(NSString*) materialName;

/**
 @param resourceInfo list of all mesh raw files
 */
-(NSArray*) getFileListForResourceInfo:(NSArray*) resourceInfo;

/**
 @param filename list of all meshes in single file
 */
-(NSArray*) getMeshListForFile:(NSString*) filename;

/**
 List of unique names list to search across for user lookup
 */
@property(nonatomic, strong)        NSMutableArray* mSearchList;

/**
 dictionary of name to entity pairings
 */
@property(nonatomic, strong)        NSMutableDictionary* mSearchToEntity;

/**
 dictionary of entityInfo
 */
@property(nonatomic, strong)        NSMutableDictionary* mEntities;

/**
 loads entities
 */
-(void) loadEntities;

/**
 @param search string to search for
 */
-(NSString*) getEntityNameForSearch:(NSString*) search;

/**
 @param name string to search for
 */
-(OWEntityInfo*) getInfoForEntityName:(NSString*) name;

/**
 @param info object info (bbox, material, name)
 @param name object name to look up
 */
-(void) putInfo:(OWEntityInfo*) info forName:(NSString*) name;


/**
 @param name string to look up metadata for
 */
-(NSDictionary*) getMetaDataDetailsForName:(NSString*) name;

/**
 
 */
-(NSArray*) getArrayofLayers;


@end

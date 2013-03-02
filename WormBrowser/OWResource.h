//
//  OWResource.h
//  WormBrowser
//
//  Created by Rich Stoner on 12/4/12.
//  Copyright (c) 2012 Rich Stoner. All rights reserved.
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

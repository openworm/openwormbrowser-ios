//
//  OWResource.m
//  WormBrowser
//
//  Created by Rich Stoner on 12/4/12.
//  Copyright (c) 2012 Rich Stoner. All rights reserved.
//

#import "OWResource.h"

@implementation OWResource

@synthesize relationDictionary, metaDataDictionary, descriptiveDataDictionary;
@synthesize mSearchList, mSearchToEntity, mEntities;


- (id)init
{
    self = [super init];
    if (self) {
        
        // ported
        mSearchList = [[NSMutableArray alloc] init];
        mSearchToEntity = [[NSMutableDictionary alloc] init];
        mEntities = [[NSMutableDictionary alloc] init];
        
        
        
        
        
        
    }
    return self;
}

-(NSArray*) getLayerList
{
    return [self remapDAGtoNodeName:[self getDAGForID:@1]];
}

-(NSArray*) getLayerListForID:(NSNumber*) layerID
{
    return [self remapDAGtoEntityName:[self getDAGForID:layerID]];
}

-(NSArray*) getDAGForID:(NSNumber*) dagID
{
    NSArray* dagArray = [self.relationDictionary objectForKey:@"dag"];
    NSArray* targetLeafArray;
    
    for (NSArray* datObject in dagArray) {
        NSNumber* objectIndex = [datObject objectAtIndex:0];
        
        if ([objectIndex isEqualToNumber: dagID]) {
            targetLeafArray = [datObject objectAtIndex:1];
        }
    }
    return targetLeafArray;
}

-(NSArray*) remapDAGtoEntityName:(NSArray*) dagArray
{
    NSArray* leafArray = [self.relationDictionary objectForKey:@"leafs"];
    NSMutableArray* arrayToReturn = [[NSMutableArray alloc] init];
    
    for (NSArray* leaf in leafArray) {
        for (NSNumber* dagIndex in dagArray) {
            if ([[leaf objectAtIndex:0] isEqualToNumber:dagIndex]) {
                [arrayToReturn addObject:leaf];
            }
        }
    }
    return arrayToReturn;
}

-(NSArray*) remapDAGtoSortedEntityName:(NSArray*) dagArray
{
    NSArray* leafArray = [self.relationDictionary objectForKey:@"leafs"];
    NSMutableArray* arrayToReturn = [[NSMutableArray alloc] init];
    
    for (NSArray* leaf in leafArray) {
        for (NSNumber* dagIndex in dagArray) {
            if ([[leaf objectAtIndex:0] isEqualToNumber:dagIndex]) {
                [arrayToReturn addObject:[leaf objectAtIndex:1]];
            }
        }
    }
    
    NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:nil ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    
    NSArray* sortedArray = [arrayToReturn sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    return sortedArray;
}


-(NSArray*) remapDAGtoNodeName:(NSArray*) nodeArray
{
    NSArray* leafArray = [self.relationDictionary objectForKey:@"nodes"];
    NSMutableArray* arrayToReturn = [[NSMutableArray alloc] init];
    for (NSArray* leaf in leafArray) {
        for (NSNumber* nodeIndex in nodeArray) {
            if ([[leaf objectAtIndex:0] isEqualToNumber:nodeIndex]) {
                [arrayToReturn addObject:leaf];
            }
        }
    }
    return arrayToReturn;
}

-(NSDictionary*) getDecodeParameters
{
    return [self.metaDataDictionary objectForKey:@"decodeParams"];
}

-(NSDictionary*) getMaterialsDictionary
{
    return [self.metaDataDictionary objectForKey:@"materials"];
}

-(GLKVector4) getDiffuseColorForMaterial:(NSString *)materialName
{
    NSDictionary* materialDict = [self.getMaterialsDictionary objectForKey:materialName];
    
    NSArray* diffuseArray = [materialDict objectForKey:@"Kd"];
    GLKVector4 diffuseColor = GLKVector4Make([[diffuseArray objectAtIndex:0] floatValue]/255,
                                             [[diffuseArray objectAtIndex:1] floatValue]/255,
                                             [[diffuseArray objectAtIndex:2] floatValue]/255,
                                             1.0);
    return diffuseColor;
}

-(NSArray*) getFileListForResourceInfo:(NSArray*) resourceInfo
{
    NSMutableArray* fileList = [[NSMutableArray alloc] init];
    
    NSArray* fileKeys  = [[self.metaDataDictionary objectForKey:@"urls"] allKeys];
    
//    NSLog(@"filekeys %@", fileKeys);
    
    for (NSString* key in fileKeys) {
        
        BOOL addToArray = NO;
        
        NSArray* fileMetaDataArray = [[self.metaDataDictionary objectForKey:@"urls"] objectForKey:key];
        
        for (NSDictionary* fileMetaData in fileMetaDataArray) {
            
            NSArray* nameArray = [fileMetaData objectForKey:@"names"];
            
            for (NSArray* resource in resourceInfo) {
                
                if ([nameArray containsObject:[resource objectAtIndex:1]])
                {
                    addToArray = YES;
                }
                
            }
        }
        
        if (addToArray) {
            [fileList addObject:key];
        }
    }
    
    return fileList;
}

-(NSArray*) getMeshListForFile:(NSString*) filename
{
    // we could simplify this by combining with getFileListForResourceInfo:
    return [[self.metaDataDictionary objectForKey:@"urls"] objectForKey:filename];
    
}

- (void) loadEntities
{
    
    
    NSError* e;
    
    self.descriptiveDataDictionary = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"data" ofType:@"json"]] options: NSJSONReadingMutableContainers error: &e];
    
    if (e) {
        NSLog(@"%@", [e debugDescription]);
    }
    
    
    self.relationDictionary = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"entity_metadata" ofType:@"json"]] options: NSJSONReadingMutableContainers error: &e];

    if (e) {
        NSLog(@"%@", [e debugDescription]);
    }
    
    BOOL iPad = NO;
#ifdef UI_USER_INTERFACE_IDIOM
    iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
#endif
    if (iPad) {
    
        self.metaDataDictionary = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"mesh_data_clean" ofType:@"json"]] options: NSJSONReadingMutableContainers error: &e];
    
    }
    else
    {
        self.metaDataDictionary = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"reduced" ofType:@"json"]] options: NSJSONReadingMutableContainers error: &e];
    }
    
    
    if (e) {
        NSLog(@"%@", [e debugDescription]);
    }
    
//    NSLog(@"meta: %@", self.metaDataDictionary);
    
    NSArray* leafArray = [self.relationDictionary objectForKey:@"leafs"];
    
    for (NSArray* leaf in leafArray) {
        
        OWEntityInfo* entity = [[OWEntityInfo alloc] init];
        [entity setDisplayName:[leaf objectAtIndex:1]];
        entity.entityID = [[leaf objectAtIndex:0] intValue];
        
        [self.mEntities setObject:entity forKey:[leaf objectAtIndex:0]];
        
        if (![self.mSearchList containsObject:entity.displayName]) {
            
            [self.mSearchList addObject:entity.displayName];
            
            // create new array when new item is found ... smarter.
            NSMutableArray* idArray = [[NSMutableArray alloc] init];
            [self.mSearchToEntity setObject:idArray forKey:entity.displayName];
            
        }
        
        NSMutableArray* s2e = [self.mSearchToEntity objectForKey:entity.displayName];
        [s2e addObject:[NSNumber numberWithInt:entity.entityID]];
        [self.mSearchToEntity setObject:entity.displayName forKey:s2e];
        
    }
}
//
//-(NSArray*) getFilteredSearchList
//{
//    NSMutableArray* filteredSearchList = [[NSMutableArray alloc] init];
//    
//    for (NSString* searchTerm in self.mSearchList) {
//        if ([[self.mEntities allKeys] containsObject:searchTerm]) {
//            [filteredSearchList addObject:searchTerm];
//        }
//    }
//    NSSortDescriptor *sortDescriptor;
//    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"length" ascending:YES];
//    
//    [filteredSearchList sortUsingDescriptors:@[sortDescriptor]];
//    
//    return filteredSearchList;
//    
//}


-(NSString*) getEntityNameForSearch:(NSString*) search
{
    return [[self.mSearchToEntity objectForKey:search] objectAtIndex:0];
}


-(NSDictionary*) getMetaDataDetailsForName:(NSString*) name
{
    NSString* searchName = [name uppercaseString];
    
//    NSLog(@"%@", [self.descriptiveDataDictionary allKeys]);
    
    if ([[self.descriptiveDataDictionary allKeys] containsObject:searchName])
    {
        return [self.descriptiveDataDictionary objectForKey:searchName];
    }
    else{
        return nil;
    }
}

-(OWEntityInfo*) getInfoForEntityName:(NSString*) name
{
    #warning THIS IS HORRENDOUSLY inefficient but necessary to support legacy configuration
    return [self.mEntities objectForKey:[self getEntityNameForSearch:name]];
}

-(void) putInfo:(OWEntityInfo*) _info forName:(NSString*) name
{
    [self.mEntities setObject:_info forKey:name];
}

-(NSArray*) getArrayofLayers
{
    NSMutableArray* returnArray = [[NSMutableArray alloc] initWithCapacity:NUMBER_OF_LAYERS];
    
    NSArray* layerList = [self remapDAGtoNodeName:[self getDAGForID:@1]];
    
    for(int i = 0; i < NUMBER_OF_LAYERS; i++)
    {
        NSArray* layerInfo = [layerList objectAtIndex:i];
        NSNumber* layerID = [layerInfo objectAtIndex:0];
        NSArray* resourceInformation = [self remapDAGtoSortedEntityName:[self getDAGForID:layerID]];

        NSMutableDictionary* dictToReturn = [[NSMutableDictionary alloc] init];
        [dictToReturn setObject:resourceInformation forKey:[layerInfo objectAtIndex:1]];
        
        [returnArray addObject:dictToReturn];
    }
    
    return returnArray;
    
}


@end

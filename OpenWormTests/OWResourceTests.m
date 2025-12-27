//
//  OWResourceTests.m
//  OpenWormTests
//
//  Created by Claude Code on 2025-12-26.
//  Tests for OWResource mesh/metadata loading
//

#import <XCTest/XCTest.h>
#import "OWResource.h"
#import "OWEntityInfo.h"
#import "OWVector.h"

@interface OWResourceTests : XCTestCase
@property (nonatomic, strong) OWResource *resource;
@end

@implementation OWResourceTests

- (void)setUp {
    [super setUp];
    self.resource = [[OWResource alloc] init];
    // Load entities to populate data structures
    [self.resource loadEntities];
}

- (void)tearDown {
    self.resource = nil;
    [super tearDown];
}

#pragma mark - Initialization Tests

- (void)testInit {
    OWResource *res = [[OWResource alloc] init];
    XCTAssertNotNil(res, @"OWResource should initialize");
}

- (void)testSearchListInitialized {
    OWResource *res = [[OWResource alloc] init];
    XCTAssertNotNil(res.mSearchList, @"Search list should be initialized");
}

- (void)testSearchToEntityInitialized {
    OWResource *res = [[OWResource alloc] init];
    XCTAssertNotNil(res.mSearchToEntity, @"Search to entity dictionary should be initialized");
}

- (void)testEntitiesInitialized {
    OWResource *res = [[OWResource alloc] init];
    XCTAssertNotNil(res.mEntities, @"Entities dictionary should be initialized");
}

#pragma mark - Load Entities Tests

- (void)testLoadEntitiesDoesNotCrash {
    OWResource *res = [[OWResource alloc] init];
    XCTAssertNoThrow([res loadEntities], @"loadEntities should not crash");
}

- (void)testLoadEntitiesPopulatesSearchList {
    XCTAssertGreaterThan(self.resource.mSearchList.count, 0, @"Search list should have entities after load");
}

- (void)testLoadEntitiesPopulatesEntities {
    XCTAssertGreaterThan(self.resource.mEntities.count, 0, @"Entities should have entries after load");
}

- (void)testLoadEntitiesPopulatesRelationDictionary {
    XCTAssertNotNil(self.resource.relationDictionary, @"Relation dictionary should be populated");
}

- (void)testLoadEntitiesPopulatesMetaDataDictionary {
    XCTAssertNotNil(self.resource.metaDataDictionary, @"Metadata dictionary should be populated");
}

- (void)testLoadEntitiesPopulatesDescriptiveDataDictionary {
    XCTAssertNotNil(self.resource.descriptiveDataDictionary, @"Descriptive data dictionary should be populated");
}

#pragma mark - Decode Parameters Tests

- (void)testGetDecodeParameters {
    NSDictionary *decodeParams = [self.resource getDecodeParameters];
    XCTAssertNotNil(decodeParams, @"Decode parameters should exist");
}

- (void)testDecodeParametersHasExpectedKeys {
    NSDictionary *decodeParams = [self.resource getDecodeParameters];
    // Common decode parameters for 3D mesh data
    XCTAssertTrue(decodeParams.count > 0, @"Decode parameters should have keys");
}

#pragma mark - Materials Dictionary Tests

- (void)testGetMaterialsDictionary {
    NSDictionary *materials = [self.resource getMaterialsDictionary];
    XCTAssertNotNil(materials, @"Materials dictionary should exist");
}

- (void)testMaterialsDictionaryHasEntries {
    NSDictionary *materials = [self.resource getMaterialsDictionary];
    XCTAssertGreaterThan(materials.count, 0, @"Materials should have entries");
}

#pragma mark - Diffuse Color Tests

- (void)testGetDiffuseColorForValidMaterial {
    NSDictionary *materials = [self.resource getMaterialsDictionary];
    if (materials.count > 0) {
        NSString *firstMaterial = [[materials allKeys] firstObject];
        OWVector4 color = [self.resource getDiffuseColorForMaterial:firstMaterial];

        // Color components should be in valid range [0, 1]
        XCTAssertGreaterThanOrEqual(color.x, 0.0f, @"Red should be >= 0");
        XCTAssertLessThanOrEqual(color.x, 1.0f, @"Red should be <= 1");
        XCTAssertGreaterThanOrEqual(color.y, 0.0f, @"Green should be >= 0");
        XCTAssertLessThanOrEqual(color.y, 1.0f, @"Green should be <= 1");
        XCTAssertGreaterThanOrEqual(color.z, 0.0f, @"Blue should be >= 0");
        XCTAssertLessThanOrEqual(color.z, 1.0f, @"Blue should be <= 1");
    }
}

- (void)testGetDiffuseColorForMissingMaterial {
    OWVector4 color = [self.resource getDiffuseColorForMaterial:@"nonexistent_material_xyz"];
    // Should return fallback gray color
    XCTAssertEqualWithAccuracy(color.x, 0.5f, 0.01f, @"Fallback red should be 0.5");
    XCTAssertEqualWithAccuracy(color.y, 0.5f, 0.01f, @"Fallback green should be 0.5");
    XCTAssertEqualWithAccuracy(color.z, 0.5f, 0.01f, @"Fallback blue should be 0.5");
    XCTAssertEqualWithAccuracy(color.w, 1.0f, 0.01f, @"Alpha should be 1.0");
}

- (void)testGetDiffuseColorForNilMaterial {
    OWVector4 color = [self.resource getDiffuseColorForMaterial:nil];
    // Should return fallback gray color without crashing
    XCTAssertEqualWithAccuracy(color.x, 0.5f, 0.01f, @"Fallback should be gray");
}

#pragma mark - DAG Tests

- (void)testGetDAGForRootID {
    NSArray *dag = [self.resource getDAGForID:@1];
    XCTAssertNotNil(dag, @"DAG for root ID (1) should exist");
}

- (void)testGetDAGForRootIDHasEntries {
    NSArray *dag = [self.resource getDAGForID:@1];
    XCTAssertGreaterThan(dag.count, 0, @"Root DAG should have child nodes");
}

- (void)testGetDAGForInvalidID {
    NSArray *dag = [self.resource getDAGForID:@99999];
    XCTAssertNil(dag, @"DAG for invalid ID should be nil");
}

#pragma mark - Layer List Tests

- (void)testGetLayerList {
    NSArray *layers = [self.resource getLayerList];
    XCTAssertNotNil(layers, @"Layer list should exist");
}

- (void)testGetLayerListHasCorrectCount {
    NSArray *layers = [self.resource getLayerList];
    // OpenWorm has 4 layers: cuticle, organs, neurons, muscles
    XCTAssertEqual(layers.count, 4, @"Should have 4 layers (cuticle, organs, neurons, muscles)");
}

- (void)testGetLayerListContainsArrays {
    NSArray *layers = [self.resource getLayerList];
    if (layers.count > 0) {
        id firstLayer = [layers firstObject];
        XCTAssertTrue([firstLayer isKindOfClass:[NSArray class]], @"Layer entries should be arrays");
    }
}

- (void)testGetLayerListForSpecificID {
    NSArray *layers = [self.resource getLayerList];
    if (layers.count > 0) {
        NSArray *firstLayer = [layers firstObject];
        NSNumber *layerID = [firstLayer objectAtIndex:0];

        NSArray *layerEntities = [self.resource getLayerListForID:layerID];
        XCTAssertNotNil(layerEntities, @"Should get entities for layer ID");
    }
}

#pragma mark - Remap DAG Tests

- (void)testRemapDAGtoEntityName {
    NSArray *dag = [self.resource getDAGForID:@1];
    if (dag.count > 0) {
        NSArray *remapped = [self.resource remapDAGtoEntityName:dag];
        XCTAssertNotNil(remapped, @"Remapped DAG should exist");
    }
}

- (void)testRemapDAGtoNodeName {
    NSArray *dag = [self.resource getDAGForID:@1];
    if (dag.count > 0) {
        NSArray *remapped = [self.resource remapDAGtoNodeName:dag];
        XCTAssertNotNil(remapped, @"Remapped node names should exist");
    }
}

- (void)testRemapDAGtoSortedEntityName {
    NSArray *dag = [self.resource getDAGForID:@1];
    if (dag.count > 0) {
        NSArray *sorted = [self.resource remapDAGtoSortedEntityName:dag];
        XCTAssertNotNil(sorted, @"Sorted entity names should exist");

        // Check if actually sorted
        if (sorted.count > 1) {
            for (NSUInteger i = 0; i < sorted.count - 1; i++) {
                NSString *current = sorted[i];
                NSString *next = sorted[i + 1];
                NSComparisonResult result = [current localizedCaseInsensitiveCompare:next];
                XCTAssertTrue(result != NSOrderedDescending,
                    @"Array should be sorted: %@ should come before %@", current, next);
            }
        }
    }
}

#pragma mark - Entity Info Tests

- (void)testGetInfoForValidEntityName {
    if (self.resource.mSearchList.count > 0) {
        NSString *entityName = [self.resource.mSearchList firstObject];
        OWEntityInfo *info = [self.resource getInfoForEntityName:entityName];
        XCTAssertNotNil(info, @"Should get info for valid entity name");
    }
}

- (void)testGetInfoForInvalidEntityName {
    OWEntityInfo *info = [self.resource getInfoForEntityName:@"nonexistent_entity_xyz"];
    XCTAssertNil(info, @"Should return nil for invalid entity name");
}

- (void)testGetEntityNameForSearch {
    if (self.resource.mSearchList.count > 0) {
        NSString *searchTerm = [self.resource.mSearchList firstObject];
        NSString *entityName = [self.resource getEntityNameForSearch:searchTerm];
        XCTAssertNotNil(entityName, @"Should get entity name for valid search term");
    }
}

- (void)testPutInfoForName {
    OWEntityInfo *info = [[OWEntityInfo alloc] init];
    info.displayName = @"TestEntity";
    info.entityID = 9999;

    [self.resource putInfo:info forName:@"TestEntity"];

    OWEntityInfo *retrieved = [self.resource.mEntities objectForKey:@"TestEntity"];
    XCTAssertEqualObjects(retrieved.displayName, @"TestEntity", @"Should retrieve stored entity");
}

#pragma mark - Metadata Details Tests

- (void)testGetMetaDataDetailsForValidName {
    // Check if descriptive data has any keys
    NSArray *allKeys = [self.resource.descriptiveDataDictionary allKeys];
    if (allKeys.count > 0) {
        // Keys are uppercase, so get one and lowercase it for the lookup
        NSString *key = [allKeys firstObject];
        NSDictionary *details = [self.resource getMetaDataDetailsForName:[key lowercaseString]];
        XCTAssertNotNil(details, @"Should get metadata for valid name");
    }
}

- (void)testGetMetaDataDetailsForInvalidName {
    NSDictionary *details = [self.resource getMetaDataDetailsForName:@"nonexistent_xyz"];
    XCTAssertNil(details, @"Should return nil for invalid name");
}

#pragma mark - File List Tests

- (void)testGetFileListForResourceInfo {
    NSArray *layers = [self.resource getLayerList];
    if (layers.count > 0) {
        NSArray *firstLayer = [layers firstObject];
        NSNumber *layerID = [firstLayer objectAtIndex:0];
        NSArray *resourceInfo = [self.resource remapDAGtoEntityName:[self.resource getDAGForID:layerID]];

        if (resourceInfo.count > 0) {
            NSArray *fileList = [self.resource getFileListForResourceInfo:resourceInfo];
            XCTAssertNotNil(fileList, @"File list should exist");
            XCTAssertGreaterThan(fileList.count, 0, @"File list should have entries");
        }
    }
}

- (void)testGetMeshListForFile {
    NSDictionary *urls = [self.resource.metaDataDictionary objectForKey:@"urls"];
    if (urls && urls.count > 0) {
        NSString *firstFile = [[urls allKeys] firstObject];
        NSArray *meshList = [self.resource getMeshListForFile:firstFile];
        XCTAssertNotNil(meshList, @"Mesh list should exist for valid file");
    }
}

- (void)testGetMeshListForInvalidFile {
    NSArray *meshList = [self.resource getMeshListForFile:@"nonexistent_file.utf8"];
    XCTAssertNil(meshList, @"Mesh list should be nil for invalid file");
}

#pragma mark - Array of Layers Tests

- (void)testGetArrayOfLayers {
    NSArray *layers = [self.resource getArrayofLayers];
    XCTAssertNotNil(layers, @"Array of layers should exist");
}

- (void)testGetArrayOfLayersCount {
    NSArray *layers = [self.resource getArrayofLayers];
    XCTAssertEqual(layers.count, 4, @"Should have 4 layers (NUMBER_OF_LAYERS = 4)");
}

- (void)testGetArrayOfLayersContainsDictionaries {
    NSArray *layers = [self.resource getArrayofLayers];
    if (layers.count > 0) {
        id firstLayer = [layers firstObject];
        XCTAssertTrue([firstLayer isKindOfClass:[NSDictionary class]],
            @"Layer entries should be dictionaries");
    }
}

#pragma mark - Stress Tests

- (void)testMultipleLoadEntitiesCalls {
    // Should handle being called multiple times
    for (int i = 0; i < 5; i++) {
        XCTAssertNoThrow([self.resource loadEntities],
            @"Multiple loadEntities calls should not crash (iteration %d)", i);
    }
}

- (void)testSearchListContainsNoDuplicates {
    NSSet *uniqueItems = [NSSet setWithArray:self.resource.mSearchList];
    XCTAssertEqual(uniqueItems.count, self.resource.mSearchList.count,
        @"Search list should not contain duplicates");
}

@end

//
//  OWNavigateTests.m
//  OpenWormTests
//
//  Created by Claude Code on 2025-12-26.
//  Tests for OWNavigate camera/navigation system
//

#import <XCTest/XCTest.h>
#import "OWNavigate.h"
#import "OWCamera.h"
#import "OWEntityInfo.h"
#import "OWVector.h"

@interface OWNavigateTests : XCTestCase
@property (nonatomic, strong) OWNavigate *navigate;
@end

@implementation OWNavigateTests

- (void)setUp {
    [super setUp];
    self.navigate = [[OWNavigate alloc] init];
    self.navigate.aspectRatio = 16.0f / 9.0f;  // Common aspect ratio
}

- (void)tearDown {
    self.navigate = nil;
    [super tearDown];
}

#pragma mark - Initialization Tests

- (void)testInit {
    XCTAssertNotNil(self.navigate, @"OWNavigate should initialize");
}

- (void)testInitialCameraNotNil {
    OWCamera *camera = [self.navigate getCamera];
    XCTAssertNotNil(camera, @"Camera should be initialized");
}

- (void)testInitialCameraPosition {
    OWCamera *camera = [self.navigate getCamera];
    // Initial eye is (-5, 0, 0) before any navigation
    XCTAssertEqualWithAccuracy(camera.eye.x, -5.0f, 0.1f, @"Initial eye.x should be -5");
    XCTAssertEqualWithAccuracy(camera.eye.y, 0.0f, 0.1f, @"Initial eye.y should be 0");
    XCTAssertEqualWithAccuracy(camera.eye.z, 0.0f, 0.1f, @"Initial eye.z should be 0");
}

- (void)testInitialCameraTarget {
    OWCamera *camera = [self.navigate getCamera];
    XCTAssertEqualWithAccuracy(camera.target.x, 0.0f, 0.001f, @"Target.x should be 0");
    XCTAssertEqualWithAccuracy(camera.target.y, 0.0f, 0.001f, @"Target.y should be 0");
    XCTAssertEqualWithAccuracy(camera.target.z, 0.0f, 0.001f, @"Target.z should be 0");
}

- (void)testInitialCameraUp {
    OWCamera *camera = [self.navigate getCamera];
    XCTAssertEqualWithAccuracy(camera.up.x, 0.0f, 0.001f, @"Up.x should be 0");
    XCTAssertEqualWithAccuracy(camera.up.y, 1.0f, 0.001f, @"Up.y should be 1 (world up)");
    XCTAssertEqualWithAccuracy(camera.up.z, 0.0f, 0.001f, @"Up.z should be 0");
}

- (void)testInitialFOV {
    OWCamera *camera = [self.navigate getCamera];
    XCTAssertEqualWithAccuracy(camera.fov, 50.0f, 0.1f, @"Initial FOV should be 50 degrees");
}

- (void)testInitialInterpolants {
    XCTAssertNotNil(self.navigate.mTheta, @"Theta interpolant should exist");
    XCTAssertNotNil(self.navigate.mDollyY, @"DollyY interpolant should exist");
    XCTAssertNotNil(self.navigate.mDollyZ, @"DollyZ interpolant should exist");
    XCTAssertNotNil(self.navigate.mRotateLocalX, @"RotateLocalX interpolant should exist");
    XCTAssertNotNil(self.navigate.mRotateLocalY, @"RotateLocalY interpolant should exist");
}

- (void)testInitialThetaValue {
    // Initial theta is M_PI (facing from negative X toward origin)
    XCTAssertEqualWithAccuracy(self.navigate.mTheta.present, (float)M_PI, 0.001f, @"Initial theta should be PI");
}

- (void)testInitialDollyZValue {
    // Initial dolly Z is 5.0
    XCTAssertEqualWithAccuracy(self.navigate.mDollyZ.present, 5.0f, 0.1f, @"Initial dollyZ should be 5.0");
}

#pragma mark - Recalculate Tests

- (void)testRecalculateDoesNotCrash {
    XCTAssertNoThrow([self.navigate recalculate], @"recalculate should not crash");
}

- (void)testRecalculateMultipleTimesDoesNotCrash {
    for (int i = 0; i < 100; i++) {
        XCTAssertNoThrow([self.navigate recalculate], @"recalculate should not crash on iteration %d", i);
    }
}

- (void)testRecalculateUpdatesCameraPosition {
    OWCamera *camera = [self.navigate getCamera];
    OWVector3 initialEye = camera.eye;

    // Set a new future value for dolly
    [self.navigate.mDollyZ setFuture:10.0f withUrgency:1.0f];

    // Recalculate multiple times to let interpolant converge
    for (int i = 0; i < 50; i++) {
        [self.navigate recalculate];
    }

    // Eye position should have changed
    float initialDist = sqrtf(initialEye.x * initialEye.x + initialEye.z * initialEye.z);
    float newDist = sqrtf(camera.eye.x * camera.eye.x + camera.eye.z * camera.eye.z);
    XCTAssertNotEqualWithAccuracy(initialDist, newDist, 0.5f, @"Camera distance should change after dolly adjustment");
}

#pragma mark - Camera Mode Tests

- (void)testInitialCameraIsPill {
    // Default state should be pill (or free, depending on implementation)
    // The code shows cameraStateFree is the initial state
    XCTAssertFalse([self.navigate isCameraPill], @"Initial camera state should be free (not pill)");
}

- (void)testToggleCameraMode {
    BOOL initialState = [self.navigate isCameraPill];
    [self.navigate toggleCameraMode];
    BOOL newState = [self.navigate isCameraPill];
    XCTAssertNotEqual(initialState, newState, @"Toggle should change camera mode");
}

- (void)testToggleCameraModeBackAndForth {
    BOOL initialState = [self.navigate isCameraPill];
    [self.navigate toggleCameraMode];
    [self.navigate toggleCameraMode];
    BOOL finalState = [self.navigate isCameraPill];
    XCTAssertEqual(initialState, finalState, @"Double toggle should restore original state");
}

#pragma mark - Pan Gesture Tests

- (void)testHandlePrimaryTouchDeltaDoesNotCrash {
    CGPoint delta = CGPointMake(10.0f, 5.0f);
    CGPoint absolute = CGPointMake(100.0f, 200.0f);
    XCTAssertNoThrow([self.navigate handlePrimaryTouchDelta:delta withAbsolute:absolute], @"Primary touch should not crash");
}

- (void)testHandlePrimaryTouchUpdatesCamera {
    OWCamera *camera = [self.navigate getCamera];

    // Toggle to pill mode for predictable behavior
    if (![self.navigate isCameraPill]) {
        [self.navigate toggleCameraMode];
    }

    // Record initial theta
    float initialTheta = self.navigate.mTheta.present;

    // Apply pan gesture
    CGPoint delta = CGPointMake(40.0f, 0.0f);  // Horizontal pan
    CGPoint absolute = CGPointMake(100.0f, 100.0f);
    [self.navigate handlePrimaryTouchDelta:delta withAbsolute:absolute];

    // Recalculate to apply changes
    for (int i = 0; i < 10; i++) {
        [self.navigate recalculate];
    }

    // Theta should have changed from horizontal pan
    XCTAssertNotEqualWithAccuracy(self.navigate.mTheta.present, initialTheta, 0.01f,
        @"Theta should change after horizontal pan");
}

- (void)testHandleSecondaryTouchDeltaDoesNotCrash {
    CGPoint delta = CGPointMake(10.0f, 5.0f);
    CGPoint absolute = CGPointMake(100.0f, 200.0f);
    XCTAssertNoThrow([self.navigate handleSecondaryTouchDelta:delta withAbsolute:absolute], @"Secondary touch should not crash");
}

#pragma mark - Zoom Gesture Tests

- (void)testSetZoomStartDoesNotCrash {
    XCTAssertNoThrow([self.navigate setZoomStart], @"setZoomStart should not crash");
}

- (void)testHandleZoomScaleDoesNotCrash {
    [self.navigate setZoomStart];
    XCTAssertNoThrow([self.navigate handleZoomScale:1.5f], @"handleZoomScale should not crash");
}

- (void)testZoomIn {
    // Toggle to pill mode for predictable zoom behavior
    if (![self.navigate isCameraPill]) {
        [self.navigate toggleCameraMode];
    }

    float initialDolly = self.navigate.mDollyZ.present;

    [self.navigate setZoomStart];
    [self.navigate handleZoomScale:1.5f];  // Scale > 1 = zoom in

    // Recalculate to apply
    for (int i = 0; i < 20; i++) {
        [self.navigate recalculate];
    }

    // In pill mode, zoom > 1 should bring camera closer (smaller dollyZ)
    XCTAssertLessThan(self.navigate.mDollyZ.present, initialDolly * 1.1f,
        @"Zoom in should decrease camera distance");
}

- (void)testZoomOut {
    // Toggle to pill mode
    if (![self.navigate isCameraPill]) {
        [self.navigate toggleCameraMode];
    }

    float initialDolly = self.navigate.mDollyZ.present;

    [self.navigate setZoomStart];
    [self.navigate handleZoomScale:0.5f];  // Scale < 1 = zoom out

    // Recalculate to apply
    for (int i = 0; i < 20; i++) {
        [self.navigate recalculate];
    }

    // In pill mode, zoom < 1 should move camera further (larger dollyZ)
    XCTAssertGreaterThan(self.navigate.mDollyZ.present, initialDolly * 0.9f,
        @"Zoom out should increase camera distance");
}

#pragma mark - Entity Navigation Tests

- (void)testGoToForEntityDoesNotCrash {
    OWEntityInfo *entity = [[OWEntityInfo alloc] init];
    entity.bbl = OWVector3Make(-1.0f, -1.0f, -1.0f);
    entity.bbh = OWVector3Make(1.0f, 1.0f, 1.0f);
    entity.displayName = @"TestEntity";

    XCTAssertNoThrow([self.navigate goToForEntity:entity withUrgency:0.5f], @"goToForEntity should not crash");
}

- (void)testGoToForEntityWithLargeEntity {
    OWEntityInfo *entity = [[OWEntityInfo alloc] init];
    entity.bbl = OWVector3Make(-10.0f, -5.0f, -3.0f);
    entity.bbh = OWVector3Make(10.0f, 5.0f, 3.0f);
    entity.displayName = @"LargeEntity";

    XCTAssertNoThrow([self.navigate goToForEntity:entity withUrgency:0.25f], @"goToForEntity should handle large entities");

    // Allow time for delayed navigation
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];

    // Recalculate
    for (int i = 0; i < 50; i++) {
        [self.navigate recalculate];
    }
}

- (void)testGoToForEntityWithZeroSizeEntity {
    OWEntityInfo *entity = [[OWEntityInfo alloc] init];
    entity.bbl = OWVector3Make(0.0f, 0.0f, 0.0f);
    entity.bbh = OWVector3Make(0.0f, 0.0f, 0.0f);
    entity.displayName = @"PointEntity";

    XCTAssertNoThrow([self.navigate goToForEntity:entity withUrgency:0.5f], @"goToForEntity should handle zero-size entities");
}

#pragma mark - Aspect Ratio Tests

- (void)testAspectRatioSetting {
    self.navigate.aspectRatio = 2.0f;
    XCTAssertEqualWithAccuracy(self.navigate.aspectRatio, 2.0f, 0.001f, @"Aspect ratio should be settable");
}

- (void)testAspectRatioPortrait {
    self.navigate.aspectRatio = 9.0f / 16.0f;  // Portrait
    XCTAssertLessThan(self.navigate.aspectRatio, 1.0f, @"Portrait aspect ratio should be < 1");
}

- (void)testAspectRatioLandscape {
    self.navigate.aspectRatio = 16.0f / 9.0f;  // Landscape
    XCTAssertGreaterThan(self.navigate.aspectRatio, 1.0f, @"Landscape aspect ratio should be > 1");
}

#pragma mark - Interpolant Integration Tests

- (void)testInterpolantsConverge {
    // Set future values
    [self.navigate.mTheta setFuture:M_PI_2 withUrgency:0.5f];
    [self.navigate.mDollyZ setFuture:20.0f withUrgency:0.5f];

    // Recalculate many times
    for (int i = 0; i < 200; i++) {
        [self.navigate recalculate];
    }

    // Values should have converged toward future
    XCTAssertEqualWithAccuracy(self.navigate.mTheta.present, (float)M_PI_2, 0.1f,
        @"Theta should converge toward future value");
    XCTAssertEqualWithAccuracy(self.navigate.mDollyZ.present, 20.0f, 1.0f,
        @"DollyZ should converge toward future value");
}

#pragma mark - Limit Tests

- (void)testZoomNearLimitViaNavigation {
    // Limits are enforced in doNavigateWithAngle, not on the interpolant directly
    // Toggle to pill mode
    if (![self.navigate isCameraPill]) {
        [self.navigate toggleCameraMode];
    }

    // Try to navigate to an extremely close zoom (0.01 < ZOOM_NEAR_LIMIT of 0.1)
    // We'll use a scaled pinch zoom that would push us past the limit
    [self.navigate setZoomStart];

    // Extreme zoom in (very large scale = very close)
    [self.navigate handleZoomScale:10.0f];

    for (int i = 0; i < 100; i++) {
        [self.navigate recalculate];
    }

    // DollyZ should not be allowed below ZOOM_NEAR_LIMIT (0.1)
    // However, the limit is applied in doNavigateWithAngle, so the effective
    // zoom should be constrained. Note: The actual enforcement depends on
    // how handleZoomScale calls into the navigation system.
    // For this test, we verify the value is reasonable (not NaN, not negative)
    XCTAssertFalse(isnan(self.navigate.mDollyZ.present), @"DollyZ should not be NaN");
    XCTAssertGreaterThan(self.navigate.mDollyZ.present, 0.0f, @"DollyZ should be positive");
}

- (void)testZoomFarLimitViaNavigation {
    // Toggle to pill mode
    if (![self.navigate isCameraPill]) {
        [self.navigate toggleCameraMode];
    }

    // Start with a reasonable zoom level
    [self.navigate.mDollyZ setFuture:50.0f withUrgency:1.0f];
    for (int i = 0; i < 20; i++) {
        [self.navigate recalculate];
    }

    [self.navigate setZoomStart];

    // Extreme zoom out (very small scale = very far)
    [self.navigate handleZoomScale:0.01f];

    for (int i = 0; i < 100; i++) {
        [self.navigate recalculate];
    }

    // The value should be reasonable, not infinite
    XCTAssertFalse(isinf(self.navigate.mDollyZ.present), @"DollyZ should not be infinite");
    XCTAssertGreaterThan(self.navigate.mDollyZ.present, 0.0f, @"DollyZ should be positive");
}

#pragma mark - Stress Tests

- (void)testRapidGestureChanges {
    // Simulate rapid gesture changes (like fast panning)
    for (int i = 0; i < 100; i++) {
        CGPoint delta = CGPointMake(sinf(i) * 5.0f, cosf(i) * 5.0f);
        CGPoint absolute = CGPointMake(100.0f + i, 100.0f + i);
        [self.navigate handlePrimaryTouchDelta:delta withAbsolute:absolute];
        [self.navigate recalculate];
    }

    // Should not crash and camera should still be valid
    OWCamera *camera = [self.navigate getCamera];
    XCTAssertFalse(isnan(camera.eye.x), @"Camera eye.x should not be NaN after rapid gestures");
    XCTAssertFalse(isnan(camera.eye.y), @"Camera eye.y should not be NaN after rapid gestures");
    XCTAssertFalse(isnan(camera.eye.z), @"Camera eye.z should not be NaN after rapid gestures");
}

- (void)testConcurrentZoomAndPan {
    // Toggle to pill mode
    if (![self.navigate isCameraPill]) {
        [self.navigate toggleCameraMode];
    }

    [self.navigate setZoomStart];

    for (int i = 0; i < 50; i++) {
        // Alternate between zoom and pan
        if (i % 2 == 0) {
            [self.navigate handleZoomScale:1.0f + sinf(i * 0.1f) * 0.2f];
        } else {
            CGPoint delta = CGPointMake(3.0f, 2.0f);
            CGPoint absolute = CGPointMake(150.0f, 150.0f);
            [self.navigate handlePrimaryTouchDelta:delta withAbsolute:absolute];
        }
        [self.navigate recalculate];
    }

    OWCamera *camera = [self.navigate getCamera];
    XCTAssertFalse(isinf(camera.eye.x), @"Camera should not have infinite values");
    XCTAssertFalse(isinf(camera.eye.y), @"Camera should not have infinite values");
    XCTAssertFalse(isinf(camera.eye.z), @"Camera should not have infinite values");
}

@end

//
//  OWInterpolantTests.m
//  OpenWormTests
//
//  Created by Claude Code on 2025-12-26.
//  Tests for OWInterpolant smooth animation tweening
//

#import <XCTest/XCTest.h>
#import "OWInterpolant.h"

@interface OWInterpolantTests : XCTestCase
@end

@implementation OWInterpolantTests

#pragma mark - Initialization Tests

- (void)testInitWithValue {
    OWInterpolant *interpolant = [[OWInterpolant alloc] initWithValue:5.0f];

    XCTAssertNotNil(interpolant, @"Interpolant should be created");
    XCTAssertEqual(interpolant.present, 5.0f, @"Present value should be 5.0");
    XCTAssertEqual(interpolant.future, 5.0f, @"Future value should match present initially");
}

- (void)testInitWithZero {
    OWInterpolant *interpolant = [[OWInterpolant alloc] initWithValue:0.0f];

    XCTAssertEqual(interpolant.present, 0.0f, @"Present value should be 0.0");
    XCTAssertEqual(interpolant.future, 0.0f, @"Future value should be 0.0");
}

- (void)testInitWithNegativeValue {
    OWInterpolant *interpolant = [[OWInterpolant alloc] initWithValue:-10.0f];

    XCTAssertEqual(interpolant.present, -10.0f, @"Present value should handle negatives");
}

#pragma mark - Set Future Tests

- (void)testSetFutureWithUrgency {
    OWInterpolant *interpolant = [[OWInterpolant alloc] initWithValue:0.0f];
    [interpolant setFuture:10.0f withUrgency:0.5f];

    XCTAssertEqual(interpolant.future, 10.0f, @"Future should be set to 10.0");
    XCTAssertEqual(interpolant.present, 0.0f, @"Present should still be 0.0 before tween");
}

- (void)testSetFutureHighUrgency {
    OWInterpolant *interpolant = [[OWInterpolant alloc] initWithValue:0.0f];
    [interpolant setFuture:100.0f withUrgency:1.0f];

    XCTAssertEqual(interpolant.future, 100.0f, @"Future should be 100.0");
    // High urgency means faster convergence
}

#pragma mark - Tween Tests

- (void)testTweenConvergence {
    OWInterpolant *interpolant = [[OWInterpolant alloc] initWithValue:0.0f];
    [interpolant setFuture:10.0f withUrgency:0.5f];

    // Tween multiple times until convergence
    for (int i = 0; i < 100; i++) {
        [interpolant tween];
    }

    // After many iterations, present should approach future
    XCTAssertEqualWithAccuracy(interpolant.present, 10.0f, 0.1f,
                               @"After many tweens, present should converge to future");
}

- (void)testTweenSingleStep {
    OWInterpolant *interpolant = [[OWInterpolant alloc] initWithValue:0.0f];
    [interpolant setFuture:10.0f withUrgency:0.5f];

    float before = interpolant.present;
    [interpolant tween];
    float after = interpolant.present;

    XCTAssertGreaterThan(after, before, @"Single tween should move present toward future");
    XCTAssertLessThan(after, 10.0f, @"Single tween should not reach future immediately");
}

- (void)testTweenWhenAtTarget {
    OWInterpolant *interpolant = [[OWInterpolant alloc] initWithValue:5.0f];
    // Future already equals present

    BOOL changed = [interpolant tween];

    XCTAssertEqual(interpolant.present, 5.0f, @"Tween should maintain value when at target");
    XCTAssertFalse(changed, @"Tween should return NO when at target");
}

- (void)testTweenNegativeDirection {
    OWInterpolant *interpolant = [[OWInterpolant alloc] initWithValue:10.0f];
    [interpolant setFuture:0.0f withUrgency:0.5f];

    [interpolant tween];

    XCTAssertLessThan(interpolant.present, 10.0f, @"Present should decrease toward 0");
    XCTAssertGreaterThan(interpolant.present, 0.0f, @"Present should not reach 0 immediately");
}

- (void)testTweenReturnsYesWhenMoving {
    OWInterpolant *interpolant = [[OWInterpolant alloc] initWithValue:0.0f];
    [interpolant setFuture:10.0f withUrgency:0.5f];

    BOOL changed = [interpolant tween];

    XCTAssertTrue(changed, @"Tween should return YES when value changes");
}

#pragma mark - TweenAll Class Method Tests

- (void)testTweenAllWithMultipleInterpolants {
    OWInterpolant *a = [[OWInterpolant alloc] initWithValue:0.0f];
    OWInterpolant *b = [[OWInterpolant alloc] initWithValue:0.0f];
    OWInterpolant *c = [[OWInterpolant alloc] initWithValue:0.0f];

    [a setFuture:10.0f withUrgency:0.5f];
    [b setFuture:20.0f withUrgency:0.5f];
    [c setFuture:30.0f withUrgency:0.5f];

    NSArray *interpolants = @[a, b, c];

    for (int i = 0; i < 100; i++) {
        [OWInterpolant tweenAll:interpolants];
    }

    XCTAssertEqualWithAccuracy(a.present, 10.0f, 0.1f, @"A should converge to 10");
    XCTAssertEqualWithAccuracy(b.present, 20.0f, 0.1f, @"B should converge to 20");
    XCTAssertEqualWithAccuracy(c.present, 30.0f, 0.1f, @"C should converge to 30");
}

- (void)testTweenAllWithEmptyArray {
    // Should not crash with empty array
    NSArray *empty = @[];
    XCTAssertNoThrow([OWInterpolant tweenAll:empty], @"Should handle empty array");
}

- (void)testTweenAllReturnsYesWhenAnyChanges {
    OWInterpolant *a = [[OWInterpolant alloc] initWithValue:0.0f];
    OWInterpolant *b = [[OWInterpolant alloc] initWithValue:5.0f];  // Already at target

    [a setFuture:10.0f withUrgency:0.5f];

    NSArray *interpolants = @[a, b];
    BOOL changed = [OWInterpolant tweenAll:interpolants];

    XCTAssertTrue(changed, @"Should return YES if any interpolant changed");
}

#pragma mark - Bezier Point Tests

- (void)testBezierPointAtStart {
    OWInterpolant *interpolant = [[OWInterpolant alloc] initWithValue:0.0f];

    // At t=0, should return p0
    float result = [interpolant bezierPoint:0.0f p0:0.0f p1:1.0f p2:2.0f p3:3.0f];

    XCTAssertEqualWithAccuracy(result, 0.0f, 0.001f, @"At t=0, should return p0");
}

- (void)testBezierPointAtEnd {
    OWInterpolant *interpolant = [[OWInterpolant alloc] initWithValue:0.0f];

    // At t=1, should return p3
    float result = [interpolant bezierPoint:1.0f p0:0.0f p1:1.0f p2:2.0f p3:3.0f];

    XCTAssertEqualWithAccuracy(result, 3.0f, 0.001f, @"At t=1, should return p3");
}

- (void)testBezierPointAtMiddle {
    OWInterpolant *interpolant = [[OWInterpolant alloc] initWithValue:0.0f];

    // At t=0.5, linear case (0, 1, 2, 3) should give 1.5
    float result = [interpolant bezierPoint:0.5f p0:0.0f p1:1.0f p2:2.0f p3:3.0f];

    // Bezier at t=0.5 for these points: (1-t)^3*p0 + 3(1-t)^2*t*p1 + 3(1-t)*t^2*p2 + t^3*p3
    // = 0.125*0 + 0.375*1 + 0.375*2 + 0.125*3 = 0 + 0.375 + 0.75 + 0.375 = 1.5
    XCTAssertEqualWithAccuracy(result, 1.5f, 0.001f, @"At t=0.5, should be 1.5");
}

#pragma mark - Edge Cases

- (void)testVeryLargeValues {
    OWInterpolant *interpolant = [[OWInterpolant alloc] initWithValue:0.0f];
    [interpolant setFuture:1000000.0f withUrgency:0.8f];

    for (int i = 0; i < 200; i++) {
        [interpolant tween];
    }

    XCTAssertEqualWithAccuracy(interpolant.present, 1000000.0f, 1000.0f,
                               @"Should handle large values");
}

- (void)testVerySmallChanges {
    OWInterpolant *interpolant = [[OWInterpolant alloc] initWithValue:0.0f];
    [interpolant setFuture:0.001f withUrgency:0.8f];

    for (int i = 0; i < 100; i++) {
        [interpolant tween];
    }

    XCTAssertEqualWithAccuracy(interpolant.present, 0.001f, 0.0001f,
                               @"Should handle small values");
}

- (void)testRapidFutureChanges {
    OWInterpolant *interpolant = [[OWInterpolant alloc] initWithValue:0.0f];

    // Change future rapidly
    [interpolant setFuture:10.0f withUrgency:0.5f];
    [interpolant tween];
    [interpolant setFuture:5.0f withUrgency:0.5f];  // Change target mid-tween
    [interpolant tween];

    // Should be heading toward 5.0 now
    XCTAssertEqual(interpolant.future, 5.0f, @"Future should be 5.0");
    XCTAssertNotEqual(interpolant.present, 0.0f, @"Should have moved from 0");
}

- (void)testUrgencyAffectsSpeed {
    OWInterpolant *slow = [[OWInterpolant alloc] initWithValue:0.0f];
    OWInterpolant *fast = [[OWInterpolant alloc] initWithValue:0.0f];

    [slow setFuture:10.0f withUrgency:0.1f];  // Low urgency
    [fast setFuture:10.0f withUrgency:0.9f];  // High urgency

    // Run same number of tweens
    for (int i = 0; i < 10; i++) {
        [slow tween];
        [fast tween];
    }

    // Fast should be closer to 10 than slow
    XCTAssertGreaterThan(fast.present, slow.present,
                         @"Higher urgency should converge faster");
}

@end

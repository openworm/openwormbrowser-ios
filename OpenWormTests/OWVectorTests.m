//
//  OWVectorTests.m
//  OpenWormTests
//
//  Created by Claude Code on 2025-12-26.
//  Tests for OWVector math utilities
//

#import <XCTest/XCTest.h>
#import <simd/simd.h>
#import "OWVector.h"

@interface OWVectorTests : XCTestCase
@end

@implementation OWVectorTests

#pragma mark - Vector3 Creation Tests

- (void)testVector3Make {
    OWVector3 v = simd_make_float3(1.0f, 2.0f, 3.0f);
    XCTAssertEqual(v.x, 1.0f, @"X component should be 1.0");
    XCTAssertEqual(v.y, 2.0f, @"Y component should be 2.0");
    XCTAssertEqual(v.z, 3.0f, @"Z component should be 3.0");
}

- (void)testVector3Zero {
    OWVector3 v = simd_make_float3(0.0f, 0.0f, 0.0f);
    XCTAssertEqual(simd_length(v), 0.0f, @"Zero vector should have length 0");
}

#pragma mark - Vector3 Arithmetic Tests

- (void)testVector3Add {
    OWVector3 a = simd_make_float3(1.0f, 2.0f, 3.0f);
    OWVector3 b = simd_make_float3(4.0f, 5.0f, 6.0f);
    OWVector3 result = a + b;

    XCTAssertEqual(result.x, 5.0f, @"X should be 1+4=5");
    XCTAssertEqual(result.y, 7.0f, @"Y should be 2+5=7");
    XCTAssertEqual(result.z, 9.0f, @"Z should be 3+6=9");
}

- (void)testVector3Subtract {
    OWVector3 a = simd_make_float3(5.0f, 7.0f, 9.0f);
    OWVector3 b = simd_make_float3(1.0f, 2.0f, 3.0f);
    OWVector3 result = a - b;

    XCTAssertEqual(result.x, 4.0f, @"X should be 5-1=4");
    XCTAssertEqual(result.y, 5.0f, @"Y should be 7-2=5");
    XCTAssertEqual(result.z, 6.0f, @"Z should be 9-3=6");
}

- (void)testVector3ScalarMultiply {
    OWVector3 v = simd_make_float3(2.0f, 3.0f, 4.0f);
    OWVector3 result = v * 2.0f;

    XCTAssertEqual(result.x, 4.0f, @"X should be 2*2=4");
    XCTAssertEqual(result.y, 6.0f, @"Y should be 3*2=6");
    XCTAssertEqual(result.z, 8.0f, @"Z should be 4*2=8");
}

#pragma mark - Vector3 Operations Tests

- (void)testVector3Normalize {
    OWVector3 v = simd_make_float3(3.0f, 0.0f, 4.0f);  // Length = 5
    OWVector3 normalized = simd_normalize(v);

    XCTAssertEqualWithAccuracy(simd_length(normalized), 1.0f, 0.0001f, @"Normalized vector should have length 1");
    XCTAssertEqualWithAccuracy(normalized.x, 0.6f, 0.0001f, @"X should be 3/5 = 0.6");
    XCTAssertEqualWithAccuracy(normalized.z, 0.8f, 0.0001f, @"Z should be 4/5 = 0.8");
}

- (void)testVector3Dot {
    OWVector3 a = simd_make_float3(1.0f, 2.0f, 3.0f);
    OWVector3 b = simd_make_float3(4.0f, 5.0f, 6.0f);
    float dot = simd_dot(a, b);

    // 1*4 + 2*5 + 3*6 = 4 + 10 + 18 = 32
    XCTAssertEqual(dot, 32.0f, @"Dot product should be 32");
}

- (void)testVector3Cross {
    OWVector3 a = simd_make_float3(1.0f, 0.0f, 0.0f);  // X axis
    OWVector3 b = simd_make_float3(0.0f, 1.0f, 0.0f);  // Y axis
    OWVector3 cross = simd_cross(a, b);

    // X cross Y = Z
    XCTAssertEqualWithAccuracy(cross.x, 0.0f, 0.0001f, @"X should be 0");
    XCTAssertEqualWithAccuracy(cross.y, 0.0f, 0.0001f, @"Y should be 0");
    XCTAssertEqualWithAccuracy(cross.z, 1.0f, 0.0001f, @"Z should be 1 (right-hand rule)");
}

- (void)testVector3Length {
    OWVector3 v = simd_make_float3(3.0f, 4.0f, 0.0f);  // 3-4-5 triangle
    float len = simd_length(v);

    XCTAssertEqualWithAccuracy(len, 5.0f, 0.0001f, @"Length should be 5");
}

#pragma mark - Quaternion Tests

- (void)testQuaternionIdentity {
    OWQuaternion q = simd_quaternion(0.0f, 0.0f, 0.0f, 1.0f);  // Identity quaternion
    OWVector3 v = simd_make_float3(1.0f, 2.0f, 3.0f);

    // Rotating by identity should not change the vector
    OWVector3 rotated = simd_act(q, v);

    XCTAssertEqualWithAccuracy(rotated.x, v.x, 0.0001f, @"X should be unchanged");
    XCTAssertEqualWithAccuracy(rotated.y, v.y, 0.0001f, @"Y should be unchanged");
    XCTAssertEqualWithAccuracy(rotated.z, v.z, 0.0001f, @"Z should be unchanged");
}

- (void)testQuaternionRotation90DegreesAroundZ {
    // Rotate 90 degrees around Z axis
    float angle = M_PI / 2.0f;  // 90 degrees in radians
    OWVector3 axis = simd_make_float3(0.0f, 0.0f, 1.0f);
    OWQuaternion q = simd_quaternion(angle, axis);

    // Rotate point (1, 0, 0) should give (0, 1, 0)
    OWVector3 v = simd_make_float3(1.0f, 0.0f, 0.0f);
    OWVector3 rotated = simd_act(q, v);

    XCTAssertEqualWithAccuracy(rotated.x, 0.0f, 0.0001f, @"X should be ~0");
    XCTAssertEqualWithAccuracy(rotated.y, 1.0f, 0.0001f, @"Y should be ~1");
    XCTAssertEqualWithAccuracy(rotated.z, 0.0f, 0.0001f, @"Z should be 0");
}

- (void)testQuaternionMultiplication {
    // Two 90-degree rotations should equal 180 degrees
    float angle = M_PI / 2.0f;
    OWVector3 axis = simd_make_float3(0.0f, 0.0f, 1.0f);
    OWQuaternion q = simd_quaternion(angle, axis);

    // q * q = 180 degree rotation
    OWQuaternion q2 = simd_mul(q, q);

    // Rotate (1, 0, 0) by 180 degrees around Z should give (-1, 0, 0)
    OWVector3 v = simd_make_float3(1.0f, 0.0f, 0.0f);
    OWVector3 rotated = simd_act(q2, v);

    XCTAssertEqualWithAccuracy(rotated.x, -1.0f, 0.0001f, @"X should be ~-1");
    XCTAssertEqualWithAccuracy(rotated.y, 0.0f, 0.0001f, @"Y should be ~0");
}

#pragma mark - Matrix Tests

- (void)testMatrix4x4Identity {
    matrix_float4x4 identity = matrix_identity_float4x4;
    OWVector4 v = simd_make_float4(1.0f, 2.0f, 3.0f, 1.0f);

    OWVector4 result = simd_mul(identity, v);

    XCTAssertEqualWithAccuracy(result.x, 1.0f, 0.0001f, @"X unchanged");
    XCTAssertEqualWithAccuracy(result.y, 2.0f, 0.0001f, @"Y unchanged");
    XCTAssertEqualWithAccuracy(result.z, 3.0f, 0.0001f, @"Z unchanged");
    XCTAssertEqualWithAccuracy(result.w, 1.0f, 0.0001f, @"W unchanged");
}

@end

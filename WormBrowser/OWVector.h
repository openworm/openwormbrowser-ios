#ifndef OWVector_h
#define OWVector_h
#include <math.h>
#import <simd/simd.h>
#define OWDegreesToRadians(deg) ((deg) * (M_PI / 180.0f))

typedef vector_float3 OWVector3;
typedef vector_float4 OWVector4;
typedef vector_float2 OWVector2;
typedef simd_quatf   OWQuaternion;

static inline OWVector3 OWVector3Make(float x, float y, float z) { return (OWVector3){x,y,z}; }
static inline OWVector4 OWVector4Make(float x, float y, float z, float w) { return (OWVector4){x,y,z,w}; }
static inline OWVector2 OWVector2Make(float x, float y) { return (OWVector2){x,y}; }

static inline OWVector3 OWVector3Add(OWVector3 a, OWVector3 b) { return a + b; }
static inline OWVector3 OWVector3Subtract(OWVector3 a, OWVector3 b) { return a - b; }
static inline OWVector3 OWVector3MultiplyScalar(OWVector3 v, float s) { return v * s; }
static inline OWVector3 OWVector3DivideScalar(OWVector3 v, float s) { return v / s; }
static inline float OWVector3Dot(OWVector3 a, OWVector3 b) { return simd_dot(a,b); }
static inline OWVector3 OWVector3Cross(OWVector3 a, OWVector3 b) { return simd_cross(a,b); }
static inline OWVector3 OWVector3Normalize(OWVector3 v) { return simd_normalize(v); }
static inline float OWVector3Length(OWVector3 v) { return simd_length(v); }

static inline OWQuaternion OWQuaternionMake(float x, float y, float z, float w) { return simd_quaternion((vector_float4){x,y,z,w}); }
static inline OWQuaternion OWQuaternionMultiply(OWQuaternion q1, OWQuaternion q2) { return simd_mul(q1,q2); }
static inline OWQuaternion OWQuaternionMakeWithAngleAndVector3Axis(float angle, OWVector3 axis) { return simd_quaternion(angle, axis); }
static inline OWVector3 OWQuaternionRotateVector3(OWQuaternion q, OWVector3 v) { return simd_act(q,v); }

#endif

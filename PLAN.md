# OpenWorm Browser iOS - Restoration Plan

## Executive Summary

This 12-year-old Objective-C app has been partially modernized from OpenGL to Metal, but **does not currently work**. This plan outlines a test-driven approach to fix it.

---

## Current State Analysis

### Build Status: **FAILING**

```
error: Interface Builder can't determine the type of "LaunchScreen.storyboard"
```

### Code Architecture

| Component | Purpose | Status |
|-----------|---------|--------|
| `OWMetalViewController` | Metal render loop, gesture handling | Ported to Metal |
| `OWNavigate` | Camera/navigation with interpolated tweens | Working logic |
| `OWLayer` | Layer model (cuticle, neurons, muscle, organs) | Loads mesh data |
| `OWDrawGroup` | Drawable groups with Metal buffers | Partially ported |
| `OWDraw` | Individual drawable with index buffer offset | Working |
| `OWResource` | JSON metadata + mesh file parsing | Legacy Objective-C |
| `Shaders.metal` | Lighting + picking shaders | New, untested |
| `OWInterpolant` | Smooth animation tweening | Working |

### Test Coverage: **ZERO**

No unit tests, no UI tests, no integration tests.

---

## Identified Issues

### P0: Blocking Build

1. **LaunchScreen.storyboard SDK Error**
   - Interface Builder can't determine storyboard type
   - Likely missing iOS SDK reference or corrupt storyboard XML
   - Fix: Recreate storyboard or fix SDK references in project.pbxproj

### P1: Critical Runtime Issues

2. **Vertex Buffer Layout Mismatch**
   - `OWLayer.m` loads data into `vertexDataTextured` struct
   - `OWMetalViewController` creates Metal buffers expecting `MetalVertex` layout
   - Both have same fields but **byte alignment may differ**
   - Fix: Ensure struct packing matches between CPU and GPU

3. **Picking Implementation Incomplete**
   - `findObjectByPoint:` creates 1x1 texture but:
     - Doesn't transform screen point to NDC
     - Doesn't set viewport/scissor
     - Reads from wrong texture (renders to 1x1 but uses MVP for full viewport)
   - Fix: Complete picking implementation with proper coordinate transform

4. **Draws Array Not Populated for All Layers**
   - `OWDrawGroup.draws` array created but only populated when bounding boxes exist
   - Some mesh files may not have bounding box data
   - Fix: Always create OWDraw entries from index ranges

### P2: Memory & Threading

5. **Memory Leaks**
   - `malloc()` calls in `OWLayer.loadDrawGroups` without corresponding `free()` in dealloc
   - Metal buffers created but never released
   - Fix: Add proper cleanup in dealloc or use ARC-friendly patterns

6. **Thread Safety Race Condition**
   - `loadLayersAsync:` runs on background thread (non-simulator)
   - `prepareDrawForLayer:` accesses layer data on main thread
   - No synchronization between them
   - Fix: Add proper @synchronized or dispatch barriers

### P3: Correctness

7. **Shader Uniform Buffer Not Synced Per Draw**
   - `drawOWLayer:withOpacity:encoder:` updates uniforms but doesn't call `memcpy` per draw
   - Multiple draws with same uniform buffer may show wrong colors
   - Fix: Use multiple uniform buffers or update properly between draws

8. **Camera Aspect Ratio Inverted**
   - `viewWillTransitionToSize:` sets aspect ratio inversely for landscape
   - Fix: Verify and correct aspect ratio calculation

---

## Test-Driven Development Plan

### Phase 1: Unit Test Foundation

Create `OpenWormTests` target with XCTest.

#### 1.1 Math & Vector Tests (`OWVectorTests.m`)
```objc
// Test Cases:
- testVector3Make
- testVector3Add
- testVector3Subtract
- testVector3Normalize
- testVector3Cross
- testQuaternionRotation
```

#### 1.2 Interpolant Tests (`OWInterpolantTests.m`)
```objc
// Test Cases:
- testInitWithValue
- testSetFutureWithUrgency
- testTweenAll
- testTweenConvergence
```

#### 1.3 Navigate Tests (`OWNavigateTests.m`)
```objc
// Test Cases:
- testCameraInitialPosition
- testRecalculateDoesNotCrash
- testHandlePanDelta
- testHandleZoomScale
- testGoToEntity
```

#### 1.4 Resource Parsing Tests (`OWResourceTests.m`)
```objc
// Test Cases:
- testLoadMetadata
- testGetDecodeParameters
- testGetDAGForID
- testRemapDAGtoEntityName
- testGetFileListForResourceInfo
- testGetMeshListForFile
```

### Phase 2: Metal Rendering Tests

#### 2.1 Shader Compilation Tests (`OWShaderTests.m`)
```objc
// Test Cases:
- testLightingVertexShaderCompiles
- testLightingFragmentShaderCompiles
- testPickingVertexShaderCompiles
- testPickingFragmentShaderCompiles
```

#### 2.2 Buffer Creation Tests (`OWMetalBufferTests.m`)
```objc
// Test Cases:
- testVertexBufferCreation
- testIndexBufferCreation
- testUniformBufferLayout
- testVertexDescriptorMatchesStruct
```

#### 2.3 Pipeline State Tests (`OWPipelineTests.m`)
```objc
// Test Cases:
- testShadingPipelineStateCreation
- testPickingPipelineStateCreation
- testDepthStencilStateCreation
```

### Phase 3: Layer Loading Tests

#### 3.1 Layer Tests (`OWLayerTests.m`)
```objc
// Test Cases:
- testLayerInit
- testLoadDrawGroupsDoesNotCrash
- testDrawGroupsNotEmpty
- testVertexDataValid
- testIndexDataValid
- testBoundingBoxDataValid
```

#### 3.2 DrawGroup Tests (`OWDrawGroupTests.m`)
```objc
// Test Cases:
- testDrawGroupInit
- testDrawsArrayNotNil
- testDiffuseColorSet
- testMetalBufferCreation
```

### Phase 4: Integration Tests

#### 4.1 Render Loop Tests (`OWRenderTests.m`)
```objc
// Test Cases:
- testDrawInMTKViewDoesNotCrash
- testRenderProducesNonBlackPixels
- testMultipleFramesRender
```

#### 4.2 Gesture Tests (`OWGestureTests.m`)
```objc
// Test Cases:
- testPanGestureUpdatesCamera
- testPinchGestureZooms
- testTapGestureFiresNotification
```

### Phase 5: UI Tests

#### 5.1 Basic UI Tests (`OpenWormUITests.m`)
```objc
// Test Cases:
- testAppLaunches
- testWormModelVisible
- testPinchToZoom
- testPanToRotate
- testDoubleTapResetsView
```

---

## Implementation Order

### Sprint 1: Build Fix + Test Infrastructure (Days 1-2)

1. [ ] Fix LaunchScreen.storyboard build error
2. [ ] Create OpenWormTests target
3. [ ] Write OWVectorTests
4. [ ] Write OWInterpolantTests
5. [ ] Verify build succeeds on simulator

### Sprint 2: Core Logic Tests (Days 3-4)

1. [ ] Write OWNavigateTests
2. [ ] Write OWResourceTests
3. [ ] Fix any bugs discovered by tests
4. [ ] Document test coverage

### Sprint 3: Metal Tests + Fixes (Days 5-7)

1. [ ] Write OWShaderTests
2. [ ] Write OWMetalBufferTests
3. [ ] Fix vertex buffer layout mismatch
4. [ ] Fix uniform buffer sync issues
5. [ ] Write OWPipelineTests

### Sprint 4: Layer Loading Tests (Days 8-9)

1. [ ] Write OWLayerTests
2. [ ] Write OWDrawGroupTests
3. [ ] Fix memory leaks (add dealloc)
4. [ ] Fix thread safety issues

### Sprint 5: Integration + UI Tests (Days 10-12)

1. [ ] Write OWRenderTests
2. [ ] Write OWGestureTests
3. [ ] Write OpenWormUITests
4. [ ] Fix picking implementation
5. [ ] End-to-end testing

### Sprint 6: Polish + Release (Days 13-14)

1. [ ] Run full test suite
2. [ ] Profile performance
3. [ ] Fix any remaining issues
4. [ ] Update README
5. [ ] Prepare for App Store

---

## Files to Create

```
OpenWormTests/
├── OWVectorTests.m
├── OWInterpolantTests.m
├── OWNavigateTests.m
├── OWResourceTests.m
├── OWShaderTests.m
├── OWMetalBufferTests.m
├── OWPipelineTests.m
├── OWLayerTests.m
├── OWDrawGroupTests.m
├── OWRenderTests.m
├── OWGestureTests.m
└── Info.plist

OpenWormUITests/
├── OpenWormUITests.m
└── Info.plist
```

---

## Success Criteria

1. **Build passes** on Xcode 15+ with iOS 15+ deployment target
2. **App launches** on simulator and device
3. **Worm renders** with all 4 layers visible
4. **Gestures work** (pan, pinch, tap)
5. **Entity picking works** (tap to select neuron/cell)
6. **80%+ test coverage** on core logic
7. **No memory leaks** in Instruments
8. **60 FPS** on modern devices

---

## Notes

- Original developer: Rich Stoner @ WholeSlide Inc. (2012)
- Metal port: Codex AI (2024)
- Data source: Virtual Worm Project @ CalTech
- License: MIT

---

## Development Log

### 2024-12-26: Metal Rendering Fixed! 🎉

**Session Summary:** After multiple debugging iterations, the Metal rendering pipeline is now working. The C. elegans worm renders with proper colors.

#### The Critical Bug: Missing `setFragmentBuffer`

**Symptom:** Black screen (later revealed as black geometry against background once clear color was changed)

**Root Cause:** The uniform buffer was only bound to the vertex stage, but the fragment shader also needed access to read color and lighting uniforms.

**The Fix:**
```objc
// In drawElementsForGroup: - THIS LINE WAS MISSING
[enc setFragmentBuffer:self.uniformBuffer offset:0 atIndex:1];
```

**Why This Happened:** When porting from OpenGL to Metal, it's easy to forget that Metal requires explicit binding of buffers to BOTH shader stages. In OpenGL, uniforms are global. In Metal, each stage (vertex, fragment) has its own buffer bindings.

#### Debugging Journey & Gotchas

1. **Black Screen Doesn't Mean Nothing is Rendering**
   - Changed clear color from black to blue → revealed geometry was rendering but as black silhouettes
   - Lesson: Always use a non-black clear color when debugging render issues

2. **Test Triangle Technique**
   - Added a simple test triangle with identity matrix to verify the pipeline
   - The triangle also rendered black, proving the issue was in the fragment shader, not geometry loading
   - Lesson: Use simple test geometry to isolate pipeline issues

3. **MVP Matrix Gotcha**
   - Test triangle with identity MVP renders in NDC (-1 to 1 range)
   - Actual geometry needs proper camera MVP to be visible
   - Lesson: When testing, use identity matrix for quick validation, then restore proper camera

4. **Lighting Can Make Things Invisible**
   - With ambient=0.2 and perpendicular normals, `color * 0.2` ≈ black
   - Temporarily set ambient=1.0 to bypass lighting for color debugging
   - Lesson: High ambient removes lighting as a variable when debugging colors

5. **Material Colors May Be Missing**
   - Some mesh materials not found in metadata → diffuseColor = (0,0,0)
   - Added fallback colors by layer type (skin, red, green, purple)
   - Lesson: Always have fallback colors for missing material data

6. **Draws Array Empty for Some Meshes**
   - OWDraw objects only created when `bboffset > 0` (bounding box data exists)
   - Added fallback: create single OWDraw for all indices when draws array empty
   - Lesson: Don't assume optional data fields are always present

#### Metal-Specific Gotchas

| Issue | OpenGL | Metal | Fix |
|-------|--------|-------|-----|
| Uniform access | Global uniforms | Per-stage buffer binding | Call `setFragmentBuffer` AND `setVertexBuffer` |
| Struct layout | `glUniform*` handles it | Must match exactly | Use `offsetof()` to verify |
| Buffer updates | Immediate | May need sync | Use `StorageModeShared` for CPU-GPU shared |
| Depth buffer | Auto-created | Must configure | Set `depthStencilPixelFormat` on MTKView |

#### Files Modified

1. **OWMetalViewController.m**
   - Added `setFragmentBuffer` call in `drawElementsForGroup:`
   - Added fallback colors for missing materials
   - Set proper clear color and lighting parameters
   - Cleaned up debug logging

2. **OWLayer.m**
   - Added fallback OWDraw creation when bounding boxes missing

#### Test Results

- ✅ App builds successfully
- ✅ 33 unit tests passing (OWVectorTests + OWInterpolantTests)
- ✅ Cuticle layer renders with proper color
- ✅ Gestures responsive (pinch/pan work)

#### Next Steps

1. **Write OWNavigateTests** - Camera/navigation unit tests
2. **Write OWResourceTests** - Mesh loading unit tests
3. **Test other layers** - Digestive, nervous, reproductive systems
4. **Test picking** - Tap to select entities
5. **Profile performance** - Ensure 60 FPS on target devices

#### Key Debugging Commands Used

```bash
# Build
xcodebuild -workspace OpenWorm.xcworkspace -scheme OpenWorm \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5' build

# Install & Launch
xcrun simctl install 'iPhone 16 Pro' /path/to/OpenWorm.app
xcrun simctl launch 'iPhone 16 Pro' org.openworm.openwormbrowser-ios

# Screenshot
xcrun simctl io 'iPhone 16 Pro' screenshot /tmp/screenshot.png
```

#### Architecture Reminder

```
MTKView.delegate.drawInMTKView:
  └── For each OWLayer:
        └── prepareDrawForLayer: (creates Metal buffers lazily)
        └── drawOWLayer:withOpacity:encoder:
              └── For each OWDrawGroup:
                    └── Set uniforms (MVP, color, lighting)
                    └── For each OWDraw:
                          └── drawElementsForGroup: ← setFragmentBuffer was missing here!
```

---

### Pre-Session Issues (Now Fixed)

| Issue | Status | Fix Applied |
|-------|--------|-------------|
| LaunchScreen.storyboard build error | ✅ Fixed | Recreated storyboard |
| CocoaPods sandbox permission | ✅ Fixed | Set ENABLE_USER_SCRIPT_SANDBOXING=NO |
| Black screen rendering | ✅ Fixed | Added setFragmentBuffer call |
| Missing fallback draws | ✅ Fixed | Create OWDraw when bboffset=0 |
| Missing material colors | ✅ Fixed | Fallback colors by layer type |
| Worm too small on launch | ✅ Fixed | Set aspectRatio + 0.6x zoom scale |
| Opacity slider not working | ✅ Fixed | Alpha blending + staged opacity |

### 2024-12-26: Staged Opacity Implementation 🎉

**Problem:** The opacity slider wasn't revealing internal layers.

**Root Causes Found:**
1. `drawInMTKView:` wasn't using `globalOpacity`
2. Alpha blending wasn't enabled in Metal pipeline
3. Simple opacity multiplication affected all layers equally (wrong behavior)

**The Original Staged Opacity Logic:**
```
globalOpacity >= 0.75: All 4 layers, cuticle fading out
globalOpacity >= 0.50: Neurons + muscles + organs (organs fading)
globalOpacity >= 0.25: Neurons + muscles (muscles fading)
globalOpacity <  0.25: Neurons only (fading)
```

**Fixes Applied:**
1. Added alpha blending to Metal pipeline descriptor
2. Implemented staged opacity logic matching original OpenGL code
3. Render order: neurons (innermost) → muscles → organs → cuticle (outermost)
4. Each layer fades at its own stage of the slider

**Result:** Slider now progressively peels away layers to reveal internal structures!

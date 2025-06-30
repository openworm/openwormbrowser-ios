# AGENT Instructions
- After modifying `Podfile` or any pod dependency, run `pod install --allow-root` to regenerate the workspace.
- Ensure project build settings in `OpenWorm.xcodeproj/project.pbxproj` are updated accordingly when bumping deployment target or architectures.

This repository contains the Objective-C implementation of the OpenWorm Browser for iOS. The project relies on CocoaPods and OpenGL for rendering worm models. Open `OpenWorm.xcworkspace` in Xcode to build the app. When changing resources or configuration files, keep the project file in sync so it continues to build on recent Xcode versions.

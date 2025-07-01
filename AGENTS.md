# AGENT Instructions
- After modifying `Podfile` or any pod dependency, run `pod install --allow-root` to regenerate the workspace.
- Ensure project build settings in `OpenWorm.xcodeproj/project.pbxproj` are updated accordingly when bumping deployment target or architectures.

This repository contains the Objective-C implementation of the OpenWorm Browser for iOS. The project relies on CocoaPods and **Metal** for rendering worm models. After cloning, run `./setup.sh` to install CocoaPods if needed and execute `pod install`. When modifying the `Podfile` or pod dependencies, re-run `pod install --allow-root` (or `./setup.sh`) to regenerate the workspace. Then open `OpenWorm.xcworkspace` in Xcode to build the app. Keep the project file in sync with resource changes so it continues to build on recent Xcode versions.

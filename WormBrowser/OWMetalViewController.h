#import <UIKit/UIKit.h>
#import <MetalKit/MetalKit.h>

@interface OWMetalViewController : UIViewController<MTKViewDelegate>
- (void)setBodyOpacity:(float)opac;
- (void)toggleCameraMode;
- (BOOL)isCameraPill;
@end

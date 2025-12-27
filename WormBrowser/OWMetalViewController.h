#import <UIKit/UIKit.h>
#import <MetalKit/MetalKit.h>

#import "OWNavigate.h"
#import "OWLayer.h"
#import "OWInterpolant.h"

@interface OWMetalViewController : UIViewController<MTKViewDelegate, UIGestureRecognizerDelegate>
- (void)setBodyOpacity:(float)opac;
- (void)toggleCameraMode;
- (BOOL)isCameraPill;
- (void)setPaused:(BOOL)paused;
@end

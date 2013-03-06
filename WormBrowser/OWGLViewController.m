//
//  OWGLViewController.m
//  WormBrowser
//
//  Created by Rich Stoner on 12/4/12.
//  Copyright (c) 2012 Rich Stoner. All rights reserved.
//

#import "OWGLViewController.h"
#import "OWNavigate.h"
#import "OWDrawGroup.h"
#import "OWDraw.h"
#import "OWLayer.h"


@interface OWGLViewController ()
{
    CGPoint lastPoint;
    CGPoint lastPointDrag;
    BOOL bSliderIsVertical;
    
    renderSetting currentRenderSetting;


}

@property (strong, nonatomic)   EAGLContext *context;
@property (strong, nonatomic)   GLKBaseEffect *effect;


- (void)setupGL;
- (void)tearDownGL;

//needed for Render view (Housed in GLViewController)
@property (strong, nonatomic)   OWNavigate* mNavigate;
@property (strong, nonatomic)   NSMutableArray* mLayerOpacityInterpolants;
@property (strong, nonatomic)   NSMutableArray* mLayers;
@property (strong, nonatomic)   UIView* mLabelView;
@property (strong, nonatomic)   UILabel* mSelectedLabel;
@property (strong, nonatomic)   UIButton* mShowMetadata;
@property float globalOpacity;

@property (strong, nonatomic)   NSMutableArray* selectedObjects;

-(GLuint) createShortBufferWithTarget:(GLuint)_target withBuffer:(NSData*) _buffer;
-(OWLayer*) createLayerWithInfo:(int) _info;
-(void) loadLayersWithContext:(EAGLContext*) _context;
-(void) prepareDrawForLayer:(OWLayer*) _layer withOpacity:(GLfloat) _opacity;
-(void) drawOneGeometryOnly:(OWLayer*) _layer withGeometry:(NSString*) _geometry;
-(void) drawOWLayer:(OWLayer*) _layer withOpacity:(GLfloat) _opacity;
-(void) drawElementsForVB:(GLuint)vertexBuffer
                    forIB:(GLuint)indexBuffer
               withOffset:(GLuint)offset
            forNumIndices:(GLuint)numIndices;




@end







@implementation OWGLViewController

@synthesize context = _context;
@synthesize effect  = _effect;

@synthesize mNavigate;
@synthesize mLayerOpacityInterpolants;
@synthesize globalOpacity;
@synthesize mLabelView, mSelectedLabel, mShowMetadata;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    self.preferredFramesPerSecond = 60;
    self.globalOpacity = 1.0f;
    
    bSliderIsVertical = YES;
    currentRenderSetting = renderSettingLow;
    
    if(!self.context)
    {
        NSLog(@"Failed to create ES context");
        return;
    }
    
    self.mLabelView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width, kBarThickness)];
//    [self.mLabelView setBackgroundColor:kSelectedLabelBackgroundColor];
    

    
    [self.mLabelView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin];
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = CGRectMake(0,0,self.view.frame.size.height, kBarThickness);
    gradient.colors = [NSArray arrayWithObjects:(id)[kWormGreen CGColor], (id)[[UIColor colorWithWhite:1.0f alpha:0.5f] CGColor], nil];
    [gradient setStartPoint:CGPointMake(1.0, 0.5)];
    [gradient setEndPoint:CGPointMake(0.0, 0.5)];

    [self.mLabelView.layer insertSublayer:gradient atIndex:0];
    
    self.mSelectedLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 0, self.view.frame.size.width - 20 - 30, kBarThickness)];
    [self.mSelectedLabel setText:@"Object"];
    [self.mSelectedLabel setTextColor:kSelectedLabelFontColor];
    [self.mSelectedLabel setFont:kMenuFontIphone];
    [self.mSelectedLabel setTextAlignment:UITextAlignmentRight];
    [self.mSelectedLabel setBackgroundColor:[UIColor clearColor]];
    [self.mSelectedLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [self.mLabelView addSubview:self.mSelectedLabel];
    
    self.mShowMetadata = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    [self.mShowMetadata setCenter:CGPointMake( self.view.frame.size.width - 30, kBarThickness/2)];
    [self.mShowMetadata setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
    [self.mShowMetadata addTarget:self action:@selector(handleShowMetaData:) forControlEvents:UIControlEventTouchUpInside];
    
//    [self.mLabelView addSubview:self.mShowMetadata];
    
    [self.view addSubview:self.mLabelView];
    
    // v1 contained the Navigate here
    self.mNavigate = [[OWNavigate alloc] init];
//    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
//    NSLog(@"initializing camera with aspect ratio: %f", aspect);
    
    
    UIInterfaceOrientation toInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    switch (toInterfaceOrientation) {
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            
            NSLog(@"Rotating to Landscape %f", fabsf(self.view.bounds.size.height / self.view.bounds.size.width));
            
            [self.mNavigate setAspectRatio:fabsf(self.view.bounds.size.height / self.view.bounds.size.width)];
//            [self.mNavigate recalculate];
            
            
            break;
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
            
            NSLog(@"Rotating to Portrait %f", fabsf(self.view.bounds.size.width / self.view.bounds.size.height));
            
            [self.mNavigate setAspectRatio:fabsf(self.view.bounds.size.width / self.view.bounds.size.height)];
//            [self.mNavigate recalculate];
            
        default:
            break;
    }
    
//    [mNavigate setAspectRatio:aspect];
    
    // v1 contained an array of layers here
    
    self.mLayers = [[NSMutableArray alloc] init];
    self.mLayerOpacityInterpolants = [[NSMutableArray alloc] init];
    self.selectedObjects = [[NSMutableArray alloc] init];
    
    for (int i=0; i<NUMBER_OF_LAYERS; i++)
    {
        OWInterpolant* interp = [[OWInterpolant alloc] initWithValue:1.0f];
        [self.mLayerOpacityInterpolants addObject:interp];
    }
    
    [self loadLayersWithContext:self.context];

    GLKView *view   = (GLKView *)self.view;
    view.context    = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    view.drawableMultisample = GLKViewDrawableMultisample4X;
    
    
    
    
    UIPanGestureRecognizer* panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(updatePan:)];
    [panRecognizer setDelegate:self];
    [self.view addGestureRecognizer:panRecognizer];
    

    UIPinchGestureRecognizer* pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handleZoomFromGestureRecognizer:)];
    [pinchRecognizer setDelegate:self];
    [self.view addGestureRecognizer:pinchRecognizer];
    
    
    UITapGestureRecognizer* doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    [doubleTapRecognizer setNumberOfTapsRequired:2];
    [self.view addGestureRecognizer:doubleTapRecognizer];

    UITapGestureRecognizer* singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [singleTapRecognizer setNumberOfTapsRequired:1];
    [self.view addGestureRecognizer:singleTapRecognizer];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLayerOpacity:) name:kUpdateHorizontalSlider object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLayerOpacity:) name:kUpdateVerticalSlider object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateSliderMode:) name:kToggleSliderMode object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectSingleObject:) name:kNotificationSelectSingleObject object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showMetaDataForItem:) name:kNotificationShowMetaDataForItem object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearSelection:) name:kNotificationClearSelection object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetView:) name:kResetAllNotification object:nil];
    
    [self setupGL];
    
    [self performSelector:@selector(animateToBaseEntity:) withObject:nil afterDelay:0.1];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    switch (toInterfaceOrientation) {
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:

            NSLog(@"Rotating to Landscape %f", fabsf(self.view.bounds.size.height / self.view.bounds.size.width));
            
            [self.mNavigate setAspectRatio:fabsf(self.view.bounds.size.height / self.view.bounds.size.width)];
            [self.mNavigate recalculate];
            
            
            break;
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
            
            NSLog(@"Rotating to Portrait %f", fabsf(self.view.bounds.size.width / self.view.bounds.size.height));
            
            [self.mNavigate setAspectRatio:fabsf(self.view.bounds.size.width / self.view.bounds.size.height)];
            [self.mNavigate recalculate];
            
        default:
            break;
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - notifications

-(void) resetView:(NSNotification*)n
{
    [self animateToBaseEntity:nil];
}

-(void) animateToBaseEntity:(id)sender
{
    OWAppDelegate* delegate = AppDelegate;
    OWResource* resource = delegate.resource;
    OWEntityInfo* info = [resource getInfoForEntityName:@"cuticle"];
    [info printDebugString];
    
    [mNavigate goToForEntity:info withUrgency:0.12];
    
}



-(void) selectSingleObject:(NSNotification*) notification
{
    NSString* nameToSelect = [notification object];

    if (nameToSelect != nil) {
        
        OWAppDelegate* delegate = AppDelegate;
        OWResource* resource = delegate.resource;
        OWEntityInfo* info = [resource getInfoForEntityName:nameToSelect];
        [info printDebugString];
        
#warning uncomment to go to entity for each selection (breaks badly with worm models)
//        [mNavigate goToForEntity:info withUrgency:0.25];
        
        [self.selectedObjects removeAllObjects];
        [self.selectedObjects addObject:info];
    
        NSLog(@"Selection ARray:: %@", self.selectedObjects);
        
        [self.mSelectedLabel setText:nameToSelect];
        [self showSelectionLabel];
        
    }
    
}


-(void) showMetaDataForItem:(NSNotification*) notification
{
    
    BOOL iPad = NO;
#ifdef UI_USER_INTERFACE_IDIOM
    iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
#endif
    if (iPad) {
        
        NSString* nameToSelect = [notification object];
        
        OWAppDelegate* delegate = AppDelegate;
        OWResource* resource = delegate.resource;
        OWEntityInfo* info = [resource getInfoForEntityName:nameToSelect];
        [info printDebugString];
        
        [self.selectedObjects removeAllObjects];
        [self.selectedObjects addObject:info];
        
#warning uncomment to go to entity for each selection (breaks badly with worm models)
//        [mNavigate goToForEntity:info withUrgency:0.1];
        
        NSLog(@"Selection ARray:: %@", self.selectedObjects);
        
        [self.mSelectedLabel setText:nameToSelect];
        [self showSelectionLabel];
        
        
    }
    else{
        
        NSLog(@"Iphone metadata request - don't do anything in renderer");
        
    }
}



-(void) clearSelection:(NSNotification*) notification
{
    NSLog(@"Clearing selection");
    
    [self.selectedObjects removeAllObjects];
    [self hideSelectionLabel];
}

-(void) showSelectionLabel
{
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options:UIViewAnimationCurveLinear animations:^{
                            
                            [self.mLabelView setCenter:CGPointMake(self.view.center.x, self.view.frame.size.height - kBarThickness/2)];
                            
                        } completion:^(BOOL finished) {
        
                        }];
    
    
}

-(void) hideSelectionLabel
{
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options:UIViewAnimationCurveLinear animations:^{
                            
                            [self.mLabelView setCenter:CGPointMake(self.view.center.x, self.view.frame.size.height +  kBarThickness/2)];
                            
                        } completion:^(BOOL finished) {
                            
                        }];
    
    
}



-(void) updateLayerOpacity:(NSNotification*) notification
{
    
    if ([notification.name isEqualToString:kUpdateHorizontalSlider])
    {
        NSArray* opacityArray = [notification object];
        //        NSLog(@"Horizontal Update: %@", opacityArray);

        for(int i=0; i < opacityArray.count; i++)
        {
            NSNumber* val = opacityArray[i];
            
            switch (i) {
                case 0:
                    
                    [(OWInterpolant*)[self.mLayerOpacityInterpolants objectAtIndex:0] setFuture:[val floatValue] withUrgency:0.25];
                    
                    break;
                
                case 1:
                    
                    [(OWInterpolant*)[self.mLayerOpacityInterpolants objectAtIndex:3] setFuture:[val floatValue] withUrgency:0.25];
                    
                    break;
                    
                case 2:
                    
                    [(OWInterpolant*)[self.mLayerOpacityInterpolants objectAtIndex:2] setFuture:[val floatValue] withUrgency:0.25];
                    
                    break;
                    
                case 3:
                    
                    [(OWInterpolant*)[self.mLayerOpacityInterpolants objectAtIndex:1] setFuture:[val floatValue] withUrgency:0.25];
                    
                    break;
                    
                default:
                    break;
            }
            
            
        }
//        int i=0;
//        for (NSNumber* val in opacityArray) {
//            
//            [(OWInterpolant*)[self.mLayerOpacityInterpolants objectAtIndex:i] setFuture:[val floatValue] withUrgency:0.25];
//            i++;
//            
//        }
        
        
    }
    else
    {
        NSNumber* opacityValue = [notification object];
//        NSLog(@"Vertical Update: %@", opacityValue);
        
        globalOpacity = 1 - [opacityValue floatValue];
        
        if (globalOpacity > 1) {
            globalOpacity = 1;
        }
        if (globalOpacity < 0)
        {
            globalOpacity = 0;
        }
        
        
    }
}

-(void) updateSliderMode:(NSNotification*) notification
{
    bSliderIsVertical = !bSliderIsVertical;
    
    NSLog(@"Toggle success");
    
    
}


static inline CGPoint
CGPointSub(const CGPoint v1, const CGPoint v2)
{
    return CGPointMake(v1.x - v2.x, v1.y - v2.y);
}


#pragma mark - touch and gesture handlers

-(void) handleZoomFromGestureRecognizer:(UIPinchGestureRecognizer*) sender
{
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            
            [mNavigate setZoomStart];
            
            break;
        
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStatePossible:
            break;
            
        case UIGestureRecognizerStateChanged:
            [mNavigate handleZoomScale:[sender scale]];
            break;
            
            
            
        default:
            break;
    }
    
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

-(void) updatePan:(UIPanGestureRecognizer*)r
{
    
    CGPoint translatedPoint = [(UIPanGestureRecognizer*)r translationInView:self.view];
    CGPoint deltaPoint = CGPointSub(translatedPoint, lastPoint);
    
    switch (r.state) {
        case UIGestureRecognizerStateBegan:
            
            lastPoint = translatedPoint;
            
            break;
            
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStatePossible:
            
            // do nothing
            
            break;
            
        case UIGestureRecognizerStateChanged:
            
            
            if( sqrtf((powf(deltaPoint.x,2) + powf(deltaPoint.y, 2))) > 3.0)
            {
                lastPoint = translatedPoint;
                
//                NSLog(@"%@ - %@", [NSValue valueWithCGPoint:translatedPoint], [NSValue valueWithCGPoint:deltaPoint]);
                
                [mNavigate handlePrimaryTouchDelta:deltaPoint withAbsolute:translatedPoint];
                
//                [mNavigate expLook:translatedPoint];
//                if (abs(deltaPoint.x) > abs(deltaPoint.y)) {
//                    
//                    
//                    
//                }
//                else
//                {
//                    
//                }
            }
            break;
        default:
            break;
    }

}

-(void) handleTap:(UITapGestureRecognizer*) recognizer
{
    CGPoint tapLocation = [recognizer locationInView:[recognizer view]];
    
    NSLog(@"Tap at %@", [NSValue valueWithCGPoint:tapLocation]);
    
    [self findObjectByPoint:tapLocation];
}

-(void) handleDoubleTap:(UITapGestureRecognizer*) recognizer
{
    
    
    [self animateToBaseEntity:nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateCameraSetting object:nil];

}

-(void) updatePosition:(id)_camera
{
}

-(void)handleShowMetaData:(id)sender
{

    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationShowMetaDataForItem object:self.mSelectedLabel.text];
    
}


-(void) handleDragGesture:(UIPanGestureRecognizer*) r
{

    CGPoint translatedPoint = [(UIPanGestureRecognizer*)r translationInView:self.view];
    CGPoint deltaPoint = CGPointSub(translatedPoint, lastPoint);
    
    switch (r.state) {
        case UIGestureRecognizerStateBegan:
            
            lastPoint = translatedPoint;
            
            break;
            
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStatePossible:
            
            // do nothing
            
            break;
            
        case UIGestureRecognizerStateChanged:
            
            
            if( sqrtf((powf(deltaPoint.x,2) + powf(deltaPoint.y, 2))) > 3.0)
            {
                lastPoint = translatedPoint;
                
                [mNavigate handleSecondaryTouchDelta:deltaPoint withAbsolute:translatedPoint];
                
                //                [mNavigate expLook:translatedPoint];
                //                if (abs(deltaPoint.x) > abs(deltaPoint.y)) {
                //
                //
                //
                //                }
                //                else
                //                {
                //                    
                //                }
            }
            break;
        default:
            break;
    }}




-(void) toggleCameraMode
{
    
    [mNavigate toggleCameraMode];
    
}

-(BOOL) isCameraPill
{
    return [mNavigate isCameraPill];
}




#pragma mark - GL setup and teardown

//- (void) updateRenderSettings
//{
//    
//    switch (currentRenderSetting) {
//            
//        case renderSettingHigh:
//        case renderSettingHigh4X:
//            
//            // set scale to 1.0
//            
//            [self.view setContentScaleFactor:0.5f];
//            
//            break;
//        
//        case renderSettingMedium:
//        case renderSettingMedium4X:
//            
//            // set scale 1.5
//            [self.view setContentScaleFactor:1.0f];
//            
//            break;
//            
//        case renderSettingLow:
//        case renderSettingLow4X:
//            
//            // set scale 2.0
//            [self.view setContentScaleFactor:3.0f];
//            
//            break;
//            
//        default:
//            break;
//    }
//    
//    if (currentRenderSetting % 2 == 0) {
//        
//        GLKView* view = (GLKView*)self.view;
//        view.drawableMultisample = GLKViewDrawableMultisampleNone;
//        
//    }
//    
//}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
    glEnable(GL_DEPTH_TEST);
    
    // Lighting
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.light0.enabled  = GL_TRUE;
    
    GLfloat ambientColor        = 1.0f;
    GLfloat alpha               = 1.0f;
    
    self.effect.light0.ambientColor = GLKVector4Make(ambientColor, ambientColor, ambientColor, alpha);
    
    GLfloat diffuseColor        = 1.0f;
    
    self.effect.light0.diffuseColor = GLKVector4Make(diffuseColor, diffuseColor, diffuseColor, alpha);
    
    // Spotlight
    GLfloat specularColor       = 0.3f;
    
    self.effect.light0.specularColor    = GLKVector4Make(0.0, 0.0f, specularColor, alpha);
    self.effect.light0.position         = GLKVector4Make(5.0f, 10.0f, 10.0f, 0.0);
    self.effect.light0.spotDirection    = GLKVector3Make(0.0f, 0.0f, -1.0f);
    self.effect.light0.spotCutoff       = 20.0; // 40° spread total.
    
    self.effect.lightingType = GLKLightingTypePerPixel;
    
#warning consider performance tradeoff here
//    self.effect.lightModelTwoSided      = YES;
    
    self.effect.material.ambientColor = GLKVector4Make(0.2, 0.2, 0.2, alpha);
    [self update];
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    self.effect = nil;
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    [mNavigate recalculate];
    
    OWCamera* camera = [mNavigate getCamera];
    
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(40.0f), aspect, 0.1f, 250.0f);
    
    self.effect.transform.projectionMatrix = projectionMatrix;
    
    GLKMatrix4 viewMatrix = GLKMatrix4MakeLookAt(camera.eye.x, camera.eye.y, camera.eye.z, camera.target.x, camera.target.y, camera.target.z, camera.up.x, camera.up.y, camera.up.z);
    
    self.effect.transform.modelviewMatrix = viewMatrix;
    
    [OWInterpolant tweenAll:self.mLayerOpacityInterpolants];
    
}





- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    
    glClearColor(0.94f, 0.94f, 0.94f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    self.effect.light0.enabled = YES;
    
    [self renderNormal];
    
}

-(void) renderSelect
{
    OWLayer* skinLayer = [self.mLayers objectAtIndex:layerCuticle];
    OWLayer* neuronLayer = [self.mLayers objectAtIndex:layerNeurons];
    OWLayer* muscleLayer = [self.mLayers objectAtIndex:layerMuscle];
    OWLayer* organLayer = [self.mLayers objectAtIndex:layerOrgans];
    
    if (bSliderIsVertical) {
        
        // check if selection
        if (NO) {
            
            [self drawOneGeometryOnly:skinLayer withGeometry:@"cuticle"];
        }
        else if (self.globalOpacity >= 0.95)
        {
            // don't start drawing underlying layers until opacity is below threshold
            [self drawSelectOWLayerCorrected:skinLayer withOpacity:( self.globalOpacity - 0.75 ) * 4];
    
        }
        else
        {
            if (self.globalOpacity >= 0.75) {
                
                [self drawSelectOWLayerCorrected:neuronLayer withOpacity:1];
                [self drawSelectOWLayerCorrected:muscleLayer withOpacity:1];
                [self drawSelectOWLayerCorrected:organLayer withOpacity:1];
                [self drawSelectOWLayerCorrected:skinLayer withOpacity:(self.globalOpacity - 0.75) * 4 ];
                
            }
            else if(self.globalOpacity >= 0.5 ) {
                
                [self drawSelectOWLayerCorrected:neuronLayer withOpacity:1];
                [self drawSelectOWLayerCorrected:muscleLayer withOpacity:1];
                [self drawSelectOWLayerCorrected:organLayer withOpacity:(self.globalOpacity -0.5) * 4];
                
            }
            else if(self.globalOpacity >= 0.25) {
                
                [self drawSelectOWLayerCorrected:neuronLayer withOpacity:1];
                [self drawSelectOWLayerCorrected:muscleLayer withOpacity:(self.globalOpacity - 0.25) * 4];
                
            }
            else {

                [self drawSelectOWLayerCorrected:neuronLayer withOpacity:(self.globalOpacity) * 4];
                
            }
            
        }
    }
    else
    {
        
        
        OWInterpolant* neuronInterp = [self.mLayerOpacityInterpolants objectAtIndex:layerNeurons];
        
        if (neuronInterp.present > 0.95) {
            
            [self drawSelectOWLayerCorrected:neuronLayer withOpacity:1];
            
        }
        else{
            

            [self drawSelectOWLayerCorrected:neuronLayer withOpacity:neuronInterp.present];
            
        }
        
        
        OWInterpolant* muscleInterp = [self.mLayerOpacityInterpolants objectAtIndex:layerMuscle];
        
        if (muscleInterp.present > 0.95) {
            
            [self drawSelectOWLayerCorrected:muscleLayer withOpacity:1];
            
        }
        else{
            

            [self drawSelectOWLayerCorrected:muscleLayer withOpacity:muscleInterp.present];
            
        }
        
        
        OWInterpolant* organInterp = [self.mLayerOpacityInterpolants objectAtIndex:layerOrgans];
        
        if (organInterp.present > 0.95) {
            
            [self drawSelectOWLayerCorrected:organLayer withOpacity:1];
            
        }
        else{
            

            [self drawSelectOWLayerCorrected:organLayer withOpacity:organInterp.present];
            
        }
        
        
        
        
        OWInterpolant* skinInterp = [self.mLayerOpacityInterpolants objectAtIndex:layerCuticle];
        
        if (skinInterp.present > 0.95) {
            
            [self drawSelectOWLayerCorrected:skinLayer withOpacity:1];
            
        }
        else{
            

            [self drawSelectOWLayerCorrected:skinLayer withOpacity:skinInterp.present];
            
        }
    }
}

-(void) renderNormal
{
    
    OWLayer* skinLayer = [self.mLayers objectAtIndex:layerCuticle];
    OWLayer* neuronLayer = [self.mLayers objectAtIndex:layerNeurons];
    OWLayer* muscleLayer = [self.mLayers objectAtIndex:layerMuscle];
    OWLayer* organLayer = [self.mLayers objectAtIndex:layerOrgans];
    
    if (bSliderIsVertical) {
        
        // check if selection
        if ([self.selectedObjects count] > 0) {
            
            OWEntityInfo* info = (OWEntityInfo*)self.selectedObjects[0];
            
            [self drawOneGeometryOnly:self.mLayers[info.layer] withGeometry:info.displayName];
            
            glEnable(GL_BLEND);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

//            for (OWLayer* layer in self.mLayers) {
//                [self drawFadedLayer:layer];
//            }
            [self drawFadedLayer:self.mLayers[info.layer]];
            
            glDisable(GL_BLEND);
            
        }
        else if(self.globalOpacity >= 0.95)
        {
            [self drawOWLayer:organLayer withOpacity:1];            
            [self drawOWLayer:skinLayer withOpacity:(self.globalOpacity - 0.75) * 4 ];
    
        }
        else
        {
            if (self.globalOpacity >= 0.75) {
                
                [self drawOWLayer:neuronLayer withOpacity:1];
                [self drawOWLayer:muscleLayer withOpacity:1];
                [self drawOWLayer:organLayer withOpacity:1];
                
                [self drawOWLayer:skinLayer withOpacity:(self.globalOpacity - 0.75) * 4 ];
                
            }
            else if(self.globalOpacity >= 0.5 ) {
                
                [self drawOWLayer:neuronLayer withOpacity:1];
                [self drawOWLayer:muscleLayer withOpacity:1];
                
                [self drawOWLayer:organLayer withOpacity:(self.globalOpacity -0.5) * 4];
                
            }
            else if(self.globalOpacity >= 0.25) {
                
                [self drawOWLayer:neuronLayer withOpacity:1];
                [self drawOWLayer:muscleLayer withOpacity:(self.globalOpacity - 0.25) * 4];
                
            }
            else {
                
                [self drawOWLayer:neuronLayer withOpacity:(self.globalOpacity) * 4];
                
            }
            
        }
    }
    else
    {
        OWInterpolant* neuronInterp = [self.mLayerOpacityInterpolants objectAtIndex:layerNeurons];
        
        
        if ([self.selectedObjects count] > 0) {
            
            OWEntityInfo* info = (OWEntityInfo*)self.selectedObjects[0];
            
            [self drawOneGeometryOnly:self.mLayers[info.layer] withGeometry:info.displayName];
            
            glEnable(GL_BLEND);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            
            //            for (OWLayer* layer in self.mLayers) {
            //                [self drawFadedLayer:layer];
            //            }
            [self drawFadedLayer:self.mLayers[info.layer]];
            
            glDisable(GL_BLEND);
            
        }
        else
        {
            
            
            
            if (neuronInterp.present > 0.95) {
                
                [self drawOWLayer:neuronLayer withOpacity:1];
                
            }
            else{
                
                glEnable(GL_BLEND);
                glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                
                [self drawOWLayer:neuronLayer withOpacity:neuronInterp.present];
                
                glDisable(GL_BLEND);
                
            }
            
            
            OWInterpolant* muscleInterp = [self.mLayerOpacityInterpolants objectAtIndex:layerMuscle];
            
            if (muscleInterp.present > 0.95) {
                
                [self drawOWLayer:muscleLayer withOpacity:1];
                
            }
            else{
                
                glEnable(GL_BLEND);
                glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                
                [self drawOWLayer:muscleLayer withOpacity:muscleInterp.present];
                
                glDisable(GL_BLEND);
                
            }
            
            
            OWInterpolant* organInterp = [self.mLayerOpacityInterpolants objectAtIndex:layerOrgans];
            
            if (organInterp.present > 0.95) {
                
                [self drawOWLayer:organLayer withOpacity:1];
                
            }
            else{
                
                glEnable(GL_BLEND);
                glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                
                [self drawOWLayer:organLayer withOpacity:organInterp.present];
                
                glDisable(GL_BLEND);
                
            }
            
            
            
            
            OWInterpolant* skinInterp = [self.mLayerOpacityInterpolants objectAtIndex:layerCuticle];
            
            if (skinInterp.present > 0.95) {
                
                [self drawOWLayer:skinLayer withOpacity:1];
                
            }
            else{
                
                glEnable(GL_BLEND);
                glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                
                [self drawOWLayer:skinLayer withOpacity:skinInterp.present];
                
                glDisable(GL_BLEND);
                
            }   
        }
    }
    
}


#pragma mark - selection function


//    if (x < 0 || x > mClientWidth || y < 0 || y > mClientHeight)
//        return "";
//
//    final int kSelectionRectWidth = 20;
//
//    // Render at a much smaller resolution (only 20x20 pixel around touch point).
//    int fboWidth = kSelectionRectWidth;
//    int fboHeight = kSelectionRectWidth;
//
//    OffscreenSurface selection = createOffscreenSurface(fboWidth, fboHeight);
//    if (selection == null) {
//        Log.w("Body", "Failed to create framebuffer");
//        return "";
//    }
//    int selectionSurfaceSize = fboWidth * fboHeight * 4;
//    mSelectionSurfaceBuffer = ByteBuffer.allocateDirect(selectionSurfaceSize);
//
//    GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, selection.framebuffer);
//
//    drawBodyForSelection(x, mClientHeight - 1 - y, fboWidth, fboHeight);
//
//    GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0);
//
//    int sx = kSelectionRectWidth / 2, sy = kSelectionRectWidth / 2;
//    int value = findPixelInRect(
//                                sx, sy, kSelectionRectWidth, fboWidth, fboHeight, mSelectionSurfaceBuffer);
//
//    // Clear stuff.
//    mSelectionSurfaceBuffer = null;
//    int[] framebuffers = { selection.framebuffer };
//    GLES20.glDeleteFramebuffers(1, framebuffers, 0);
//    int[] renderbuffers = { selection.renderbuffer };
//    GLES20.glDeleteRenderbuffers(1, renderbuffers, 0);
//    int[] textures = { selection.colorTexture };
//    GLES20.glDeleteTextures(1, textures, 0);
//
//    value = (int)Math.floor(value / selectionColorScale);
//    if (value != 0 && mSelectionColorMap.containsKey(value)) {
//        return mSelectionColorMap.get(value).geometry;
//    } else {
//        return "";
//    }




- (NSUInteger)findObjectByPoint:(CGPoint)point
{
    [self setPaused:YES];
    
    // working view port
    NSInteger height = ((GLKView *)self.view).drawableHeight;
    NSInteger width = ((GLKView *)self.view).drawableWidth;
    
    // open-3d only renders a small region to FBO ... smart, but requires additional matrix math to adjust 'effective zoom'
    
    NSInteger actualHeight = 20;
    NSInteger actualWidth = 20;
    
    // bytes to store data in ... may need to make larger
    
    Byte pixelColor[4] = {0,};
    GLuint colorRenderbuffer;
    GLuint framebuffer;
    
    // create framebruffer & render buffer
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glGenRenderbuffers(1, &colorRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    
    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8_OES, width, height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER, colorRenderbuffer);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Framebuffer status: %x", (int)status);
        return 0;
    }
    else
    {
        NSLog(@"Offscreen FB created okay");
    }
    
    // off screen buffer created, now perform render using updated matrices
    
    
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glEnable(GL_CULL_FACE);
//    glCullFace(GL_CCW);
    glEnable(GL_DEPTH_TEST);
    glDisable(GL_BLEND);
    
    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
    glDisableVertexAttribArray(2);
  
    self.effect.light0.enabled = NO;
    [self.effect prepareToDraw];
    
    [self renderSelect];
    
    
    CGFloat scale = self.view.contentScaleFactor;
    
    // get 1 pixel, modify for larger selection region to scan
    glReadPixels(point.x * scale, (height - (point.y * scale)), 1, 1, GL_RGBA, GL_UNSIGNED_BYTE, pixelColor);
    
    //    NSLog(@"%f %f %f", pixelColor[0]/(63.75) , pixelColor[1]/25.50, pixelColor[2]/25.50 );
    int layerValue = (int)(pixelColor[0]) ; // -> 64 / 256
    int dgValue = (pixelColor[1]);
    int dValue = (pixelColor[2]);
    
//    NSLog(@"%d %d %d", layerValue, dgValue, dValue);
    if (layerValue != 255) {
        //

        OWLayer* selectedLayer = (OWLayer*)[self.mLayers objectAtIndex:layerValue];
        OWDrawGroup* selectedDG = [selectedLayer.drawGroups objectAtIndex:dgValue];
        OWDraw* selectedDraw = [selectedDG.draws objectAtIndex:dValue];
        NSLog(@"Selected %@", selectedDraw.geometry);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSelectSingleObject object:selectedDraw.geometry];
        
    }
    else
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationClearSelection object:nil];
    }
    
    
#if SAVE_IMAGES
    
    NSInteger x = 0, y = 0;
    NSInteger dataLength = width * height * 4;
    GLubyte *data = (GLubyte*)malloc(dataLength * sizeof(GLubyte));
    
    glPixelStorei(GL_PACK_ALIGNMENT, 4);
    glReadPixels(x, y, width, height, GL_RGBA, GL_UNSIGNED_BYTE, data);
    
    CGDataProviderRef ref = CGDataProviderCreateWithData(NULL, data, dataLength, NULL);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGImageRef iref = CGImageCreate(width, height, 8, 32, width * 4, colorspace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast,
                                    ref, NULL, true, kCGRenderingIntentDefault);
    
    
    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    CGContextRef cgcontext = UIGraphicsGetCurrentContext();
    CGContextSetBlendMode(cgcontext, kCGBlendModeCopy);
    CGContextDrawImage(cgcontext, CGRectMake(0.0, 0.0, width, height), iref);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    free(data);
    CFRelease(ref);
    CFRelease(colorspace);
    CGImageRelease(iref);
    
    
    NSString  *pngPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Test.png"];
//    NSString  *jpgPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Test.jpg"];
    
    // Write a UIImage to JPEG with minimum compression (best quality)
    // The value 'image' must be a UIImage object
    // The value '1.0' represents image compression quality as value from 0.0 to 1.0
    //    [UIImageJPEGRepresentation(image, 1.0) writeToFile:jpgPath atomically:YES];
    
    // Write image to PNG
    [UIImagePNGRepresentation(image) writeToFile:pngPath atomically:YES];
    
    // Let's check to see if files were successfully written...
    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    
    // Create file manager
    //    NSError *error;
    //    NSFileManager *fileMgr = [NSFileManager defaultManager];
    //
    //    // Point to Document directory
    //    NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    //
    //    // Write out the contents of home directory to console
    //    NSLog(@"Documents directory: %@", [fileMgr contentsOfDirectoryAtPath:documentsDirectory error:&error]);
    
#endif
    
    glDeleteRenderbuffers(1, &colorRenderbuffer);
    glDeleteFramebuffers(1, &framebuffer);
    
    [self setPaused:NO];
    
    return pixelColor[0];
    
}








#pragma mark - RENDER methods

-(OWLayer*) createLayerWithInfo:(int) _info
{
    OWLayer* layer = [[OWLayer alloc] initWithInfo:_info];
    GLfloat initialOpacity = 0;
    
    if(_info == layerCuticle)
    {
        initialOpacity = 1;
    }
    
    OWInterpolant* layerInterpolant = [[OWInterpolant alloc] initWithValue:initialOpacity];
    [self.mLayerOpacityInterpolants addObject:layerInterpolant];
    
    [layer setOpacity:layerInterpolant];
    [layer setRenderOpacity:initialOpacity];
    
    return layer;
}

-(void) loadLayersWithContext:(EAGLContext*) _context
{
    // populate layer array
    for(int i=0; i < NUMBER_OF_LAYERS; i++)
    {
        OWLayer* layer = [self createLayerWithInfo:i];
        [self.mLayers addObject:layer];
    }
    
#if TARGET_IPHONE_SIMULATOR

    [self loadLayersAsync:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationAllLayersLoaded object:nil];

    
#else
    
    [self performSelectorInBackground:@selector(loadLayersAsync:) withObject:nil];
    
#endif

}

-(void) loadLayersAsync:(id)sender
{
    for (OWLayer* layer in self.mLayers) {

        NSDate *start = [NSDate date];


        [layer loadDrawGroupsInContext:self.context];

        NSDate *methodFinish = [NSDate date];
        NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:start];
        NSLog(@"Time to load layer %d: %f sec", layer.type, executionTime);


        //        [layer printDebugString];
        
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationAllLayersLoaded object:nil];
}

//-(void) prepareDrawForLayer:(OWLayer*) _layer withOpacity:(GLfloat) _opacity
//{
//    GLfloat renderOpacity = _opacity;
//    renderOpacity = (renderOpacity > 1 ? 1 : renderOpacity);
//    renderOpacity = (renderOpacity < 0 ? 0 : renderOpacity);
//    
//}


-(void) drawOneGeometryOnly:(OWLayer*) _layer withGeometry:(NSString*) _geometry
{
//    [self prepareDrawForLayer:_layer withOpacity:1.0];
    
    for (OWDrawGroup* drawGroup in _layer.drawGroups) {
        
        for (OWDraw* draw in drawGroup.draws) {
            
            if ([draw.geometry isEqualToString:_geometry]) {
                
                self.effect.material.diffuseColor = drawGroup.diffuseColor;
                
                [self.effect prepareToDraw];
                [self drawElementsForVB:drawGroup.vertexBuffer forIB:drawGroup.indexBuffer withOffset:draw.offset forNumIndices:draw.count];
                
            }
        }
    }
}

-(void) drawSelectOWLayer:(OWLayer *)_layer withOpacity:(GLfloat)_opacity
{
//    [self prepareDrawForLayer:_layer withOpacity:_opacity];
    
    for (OWDrawGroup* dg in _layer.drawGroups) {
        
        for (OWDraw* draw in dg.draws) {

            self.effect.useConstantColor = YES;
            self.effect.constantColor = draw.selectColor;
            
            glBindBuffer(GL_ARRAY_BUFFER, dg.vertexBuffer);
            glEnableVertexAttribArray(GLKVertexAttribPosition);
            glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(vertexDataTextured), (void*)offsetof(vertexDataTextured, vertex));

            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, dg.indexBuffer);
            glDrawElements(GL_TRIANGLES, draw.count, GL_UNSIGNED_SHORT, (const void * ) (draw.offset * 2));
        }
    }
}

-(void) drawSelectOWLayerCorrected:(OWLayer*) _layer withOpacity:(GLfloat) _opacity
{
    // _opacity is below 0.95, therefore start fading away individual items
    float opacity_step = 1.0 / _layer.totalDrawCount;
    
    int threshold = _opacity / opacity_step;
    int initialThreshold = threshold;
    
    // handles last object
    BOOL drawSolid = _opacity > 0;
    
    // set to YES to blend the last object
    BOOL drawBlended = NO;
    
    for (OWDrawGroup* drawGroup in _layer.drawGroups) {
        
        for (OWDraw* draw in drawGroup.draws) {
            
            if (drawSolid) {
                
                self.effect.useConstantColor = YES;
                self.effect.constantColor = draw.selectColor;
                [self.effect prepareToDraw];
                glBindBuffer(GL_ARRAY_BUFFER, drawGroup.vertexBuffer);
                glEnableVertexAttribArray(GLKVertexAttribPosition);
                glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(vertexDataTextured), (void*)offsetof(vertexDataTextured, vertex));
                
                glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, drawGroup.indexBuffer);
                glDrawElements(GL_TRIANGLES, draw.count, GL_UNSIGNED_SHORT, (const void * ) (draw.offset * 2));
                
                threshold--;
                
                if (threshold <= 0) {
                    drawSolid = NO;
                }
            }
        }
    }

}


-(void) drawFadedLayer:(OWLayer*) _layer
{
    float _opacity = 0.1;
    
//    [self prepareDrawForLayer:_layer withOpacity:_opacity];
    
    // just draw the layer straight through
    for (OWDrawGroup* drawGroup in _layer.drawGroups) {
        
        self.effect.material.diffuseColor = GLKVector4Make(drawGroup.diffuseColor.x, drawGroup.diffuseColor.y, drawGroup.diffuseColor.z, _opacity);
        
        [self.effect prepareToDraw];
        
        [self drawElementsForVB:drawGroup.vertexBuffer forIB:drawGroup.indexBuffer withOffset:0 forNumIndices:drawGroup.numIndices];
        
    }

}

-(void) drawOWLayer:(OWLayer*) _layer withOpacity:(GLfloat) _opacity
{
    if(!_layer.isLoaded)
    {
        return;
    }
    
//    [self prepareDrawForLayer:_layer withOpacity:_opacity];
    
    if (_opacity > 0.95) {
        
        // just draw the layer straight through
        for (OWDrawGroup* drawGroup in _layer.drawGroups) {
            
            self.effect.material.diffuseColor = GLKVector4Make(drawGroup.diffuseColor.x, drawGroup.diffuseColor.y, drawGroup.diffuseColor.z, _opacity);
            
//            self.effect.light0.diffuseColor =GLKVector4Make(drawGroup.diffuseColor.x, drawGroup.diffuseColor.y, drawGroup.diffuseColor.z, _opacity);
//            self.effect.material.diffuseColor = GLKVector4Make(0, 0, 1, 1);
            
            [self.effect prepareToDraw];
            
            [self drawElementsForVB:drawGroup.vertexBuffer forIB:drawGroup.indexBuffer withOffset:0 forNumIndices:drawGroup.numIndices];
            
        }
        
    }
    else
    {

        
#if BLEND_BY_DRAWGROUP
        
        // _opacity is below 0.95, therefore start fading away individual items
        float opacity_step = 1.0 / _layer.drawGroups.count;
        
        int threshold = _opacity / opacity_step;
        int initialThreshold = threshold;
        
//        NSLog(@"%d", threshold);
        BOOL drawSolid = YES;
        
        // set to YES to blend the last object
        BOOL drawBlended = YES;
        
        for (OWDrawGroup* drawGroup in _layer.drawGroups) {
            
            if (drawSolid) {
                
                self.effect.material.diffuseColor = drawGroup.diffuseColor;
                [self.effect prepareToDraw];
                [self drawElementsForVB:drawGroup.vertexBuffer forIB:drawGroup.indexBuffer withOffset:0 forNumIndices:drawGroup.numIndices];
                threshold--;
                
                if (threshold <= 0) {
                    drawSolid = NO;
                }
            }
            else if (drawBlended)
            {
                drawBlended = NO;
                
                glEnable(GL_BLEND);
                glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                
                float minorOpacity = (_opacity - (initialThreshold * opacity_step))/opacity_step;
                
                self.effect.material.diffuseColor = GLKVector4Make(drawGroup.diffuseColor.x, drawGroup.diffuseColor.y, drawGroup.diffuseColor.z, minorOpacity);
//                NSLog(@"minor: %f", minorOpacity);
                
                [self.effect prepareToDraw];
                
                [self drawElementsForVB:drawGroup.vertexBuffer forIB:drawGroup.indexBuffer withOffset:0 forNumIndices:drawGroup.numIndices];
                
                glDisable(GL_BLEND);
                
            }
                // else don't draw it!
        }
    
#else
        
        // _opacity is below 0.95, therefore start fading away individual items
        float opacity_step = 1.0 / _layer.totalDrawCount;
        
        int threshold = _opacity / opacity_step;
        int initialThreshold = threshold;
        
        // handles last object
        BOOL drawSolid = _opacity > 0;
        
        // set to YES to blend the last object
        BOOL drawBlended = NO;
        
        for (OWDrawGroup* drawGroup in _layer.drawGroups) {
            
            for (OWDraw* draw in drawGroup.draws) {
                
                if (drawSolid) {
                    
                    self.effect.material.diffuseColor = drawGroup.diffuseColor;
                    [self.effect prepareToDraw];
                    [self drawElementsForVB:drawGroup.vertexBuffer forIB:drawGroup.indexBuffer withOffset:draw.offset forNumIndices:draw.count];
                    threshold--;
                    
                    if (threshold <= 0) {
                        drawSolid = NO;
                    }
                }
                
                else if (drawBlended)
                {
                    drawBlended = NO;
                    
                    glEnable(GL_BLEND);
                    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                    
                    float minorOpacity = (_opacity - (initialThreshold * opacity_step))/opacity_step;
                    
                    self.effect.material.diffuseColor = GLKVector4Make(drawGroup.diffuseColor.x, drawGroup.diffuseColor.y, drawGroup.diffuseColor.z, minorOpacity);
//                    NSLog(@"minor: %f", minorOpacity);
                    
                    [self.effect prepareToDraw];
                    
                    [self drawElementsForVB:drawGroup.vertexBuffer forIB:drawGroup.indexBuffer withOffset:draw.offset forNumIndices:draw.count];
                    
                    glDisable(GL_BLEND);
                    
                }
                
                // else don't draw it!
                
            }
        }
        
#endif
        
        
    }
}

-(void) drawElementsForVB:(GLuint)vertexBuffer
                    forIB:(GLuint)indexBuffer
               withOffset:(GLuint)offset
            forNumIndices:(GLuint)numIndices
{
    
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(vertexDataTextured), (void*)offsetof(vertexDataTextured, vertex)); // for model, normals, and texture
    
    // Normals
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, sizeof(vertexDataTextured), (void*)offsetof(vertexDataTextured, normal)); // for model,
    
    // Texture
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(vertexDataTextured), (void*)offsetof(vertexDataTextured, texCoord)); // for model,
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glDrawElements(GL_TRIANGLES, numIndices, GL_UNSIGNED_SHORT, (const void * ) (offset * 2));
    
}












@end

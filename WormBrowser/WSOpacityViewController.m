//
//  WSOpacityViewController.m
//  OpenWormViewer
//
//  Created by Rich Stoner on 11/20/12.
//  Copyright (c) 2012 Rich Stoner. All rights reserved.
//

#import "WSOpacityViewController.h"
#import "DCRoundSwitch.h"
#import <QuartzCore/QuartzCore.h>

#define kVerticalSliderHeight 25
#define kVerticalSliderOrigin 50 - kVerticalSliderHeight/2
#define kVerticalSliderTerminal 188 + 50 - kVerticalSliderHeight/2

#define kHorizontalSliderWidth 20
#define kHorizontalSliderHeight 47
#define kHorizontalSliderOrigin 10

#define kHorizontalSliderTerminal 60


@interface WSOpacityViewController ()
{
    UIView*         falseBackground;
    
    UIImageView*    sliderView;
    
    UIImage*        singleSliderImage;
    UIImage*        multipleSliderImage;
    
    UIImageView*    modelView;
    UIImageView*    toggleView;
    
    BOOL            bSliderIsVertical;
    
    UIView*         verticalSlider;
    float           verticalSliderValue;
    
    NSMutableArray* arrayOfHorizontalSliders;
    NSMutableArray* arrayOfHorizontalValues;
    
    
    
}

@property (nonatomic, strong)  DCRoundSwitch *toggleSwitch;


@end

@implementation WSOpacityViewController

@synthesize toggleSwitch;

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
    bSliderIsVertical = YES;
    
    arrayOfHorizontalSliders = [[NSMutableArray alloc] initWithCapacity:4];
    arrayOfHorizontalValues = [[NSMutableArray alloc] initWithCapacity:4];
    
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self.view setBackgroundColor:[UIColor clearColor]];
    [self.view setAutoresizingMask:UIViewAutoresizingNone];
    
    falseBackground = [[UIView alloc] initWithFrame:CGRectMake(10, 10, kOpacityViewWidth, kOpacityViewHeight)];
//    [falseBackground setBackgroundColor:[UIColor whiteColor]];
    [falseBackground setBackgroundColor:kOpacityViewBackground];
    [falseBackground setClipsToBounds:YES];

    falseBackground.layer.cornerRadius = 0.0f;
//    falseBackground.layer.borderColor = [UIColor blackColor].CGColor;
//    falseBackground.layer.borderWidth = 1.0f;
    
    
    
    
    modelView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"model_icon.png"]];
    [modelView setFrame:CGRectMake(0, 0, kOpacityViewWidth, 50)];
//    modelView.layer.borderColor = [UIColor blackColor].CGColor;
//    modelView.layer.borderWidth = 1.0f;
    [falseBackground addSubview:modelView];
    
    sliderView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"sliderNew.png"]];
    [sliderView setFrame:CGRectMake(0, 50, kOpacityViewWidth, 188)];
    [sliderView setUserInteractionEnabled:YES];
    [falseBackground addSubview:sliderView];
    
    
//    singleSliderImage = [UIImage imageNamed:@"toggleMulti.png"];
//    multipleSliderImage = [UIImage imageNamed:@"toggleSingle.png"];
    
    
//    toggleView = [[UIImageView alloc] initWithImage:singleSliderImage];
//    [toggleView setFrame:CGRectMake(7, 188+50+10, kOpacityViewWidth - 14, 29)];
//    [toggleView setUserInteractionEnabled:YES];
//    
    toggleSwitch = [[DCRoundSwitch alloc] initWithFrame:CGRectMake(2, 188+50+10+3, kOpacityViewWidth - 4, 30)];
    toggleSwitch.onText = @"";
    toggleSwitch.offText = @"";
    toggleSwitch.onTintColor = kWormGreen;
    [toggleSwitch addTarget:self action:@selector(tapToggleView:) forControlEvents:UIControlEventValueChanged];
    
    
    UITapGestureRecognizer* modelTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapModelView:)];
    [modelView setUserInteractionEnabled:YES];
    [modelView addGestureRecognizer:modelTap];
    
    UITapGestureRecognizer* tapToggle = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToggleView:)];
    [toggleView addGestureRecognizer:tapToggle];
    
    [falseBackground addSubview:toggleSwitch];
//    [falseBackground addSubview:toggleView];
    
    UITapGestureRecognizer* tapSlider = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapSliderView:)];
    [tapSlider setNumberOfTapsRequired:1];
    [sliderView addGestureRecognizer:tapSlider];
    
    UIPanGestureRecognizer* panVerticalSlider = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panVerticalSliderFull:)];
    [sliderView addGestureRecognizer:panVerticalSlider];
    
    [self.view addSubview:falseBackground];
    
    [self initializeVerticalSlider];
    [self initializeHorizonalSliders];
    
  
  
}


-(void) initializeVerticalSlider
{
    verticalSlider = [[UIView alloc] initWithFrame:CGRectMake(-3 + 10, 10 + kVerticalSliderOrigin, kOpacityViewWidth+6, kVerticalSliderHeight)];
//    [verticalSlider setBackgroundColor:kWormGreen];
    
    
//    UIView *view = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 100)] autorelease];
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = verticalSlider.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[kWormGreen CGColor], (id)[kWormDarker CGColor], nil];
    [verticalSlider.layer insertSublayer:gradient atIndex:0];
    [verticalSlider setClipsToBounds:YES];
    
    
    verticalSlider.layer.cornerRadius = 5.0f;
    [verticalSlider setAlpha:0.5];
    
    UIPanGestureRecognizer* panVerticalSlider = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panVerticalSlider:)];
    [verticalSlider addGestureRecognizer:panVerticalSlider];
    [self.view addSubview:verticalSlider];
}

-(void) initializeHorizonalSliders
{

    for( int i =0; i < 4; i++)
    {
        UIView* horizontalSlider = [[UIView alloc] initWithFrame:CGRectMake(0,0,kHorizontalSliderWidth, kHorizontalSliderHeight)];
//        [horizontalSlider setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.3]];
        [horizontalSlider.layer setBorderColor:[UIColor blackColor].CGColor];
        [horizontalSlider.layer setCornerRadius:5.0];
        
        [horizontalSlider setCenter:CGPointMake(kHorizontalSliderTerminal + 10, 10 + 50 + kHorizontalSliderHeight /2  + kHorizontalSliderHeight * i)];
        [horizontalSlider setTag:i];
        UIPanGestureRecognizer* panHorizontalSlider = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panHorizontalSlider:)];
        [horizontalSlider setClipsToBounds:YES];
        [horizontalSlider setAlpha:0.5];
        [horizontalSlider addGestureRecognizer:panHorizontalSlider];
        [horizontalSlider setHidden:YES];
        
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = horizontalSlider.bounds;
        gradient.colors = [NSArray arrayWithObjects:(id)[kWormGreen CGColor], (id)[kWormDarker CGColor], nil];
        [horizontalSlider.layer insertSublayer:gradient atIndex:0];
        
        [arrayOfHorizontalSliders addObject:horizontalSlider];
        
        NSNumber* horizontalValue = [NSNumber numberWithInt:1.0];
        [arrayOfHorizontalValues addObject:horizontalValue];
        
        [self.view addSubview:horizontalSlider];
        
    }
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - handle taps

-(void) tapSliderView:(UITapGestureRecognizer*) recognizer
{
    CGPoint tapPoint = [recognizer locationInView:recognizer.view];
    

    
    if (bSliderIsVertical) {
        
        CGPoint location = [recognizer locationInView:verticalSlider.superview];
        
        [verticalSlider setCenter:CGPointMake(verticalSlider.center.x,  location.y)];
    
        verticalSliderValue = ( verticalSlider.frame.origin.y - kVerticalSliderOrigin - 10) / (kVerticalSliderTerminal - kVerticalSliderOrigin);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateVerticalSlider object:[NSNumber numberWithFloat:verticalSliderValue]];
        
    }
    else{
        
//        CGPoint translation = [recognizer translationInView:recognizer.view.superview];
        
        CGPoint location = [recognizer locationInView:recognizer.view];
        
        int index = floorf(location.y / 47);

        if (index >= 0 && index < 4) {
            
            UIView* _handle = [arrayOfHorizontalSliders objectAtIndex:index];
            
//            [_handle setCenter:CGPointMake(kHorizontalSliderOrigin, _handle.center.y)];
            [_handle setCenter:CGPointMake(location.x + 10, _handle.center.y)];
            
            float horizontalValue = ( _handle.center.x - 10 ) / (kHorizontalSliderTerminal);
            
            NSLog(@"%f", horizontalValue);
            
            [arrayOfHorizontalValues replaceObjectAtIndex:_handle.tag withObject:[NSNumber numberWithFloat:horizontalValue]];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateHorizontalSlider object:arrayOfHorizontalValues];
            
            
//            
//            if (_handle.center.x + translation.x >= kHorizontalSliderTerminal + 10 ) {
//                
//                [_handle setCenter:CGPointMake(kHorizontalSliderTerminal + 10, _handle.center.y)];
//                
//            }
//            else if (_handle.center.x + translation.x < kHorizontalSliderOrigin ) {
//                
//                [_handle setCenter:CGPointMake(kHorizontalSliderOrigin, _handle.center.y)];
//                
//            }
//            else {
//                
//                [_handle setCenter:CGPointMake(_handle.center.x + translation.x, _handle.center.y)];
//                
//            }
//            
//            [recognizer setTranslation:CGPointZero inView:_handle.superview];
//            
//            
//            float horizontalValue = ( _handle.center.x - 10 ) / (kHorizontalSliderTerminal);
//            
//            NSLog(@"%f", horizontalValue);
//            
//            [arrayOfHorizontalValues replaceObjectAtIndex:_handle.tag withObject:[NSNumber numberWithFloat:horizontalValue]];
//            
//            [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateHorizontalSlider object:arrayOfHorizontalValues];
            
            
        }

        
    }
    
}

-(void) tapModelView:(UITapGestureRecognizer*)r
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kResetAllNotification object:nil];
 
    [UIView animateWithDuration:0.5 animations:^{
       
        
        [verticalSlider setFrame:CGRectMake(-3 + 10, 10 + kVerticalSliderOrigin, kOpacityViewWidth+6, kVerticalSliderHeight)];
        
        verticalSliderValue = 0.0;
        
        for (UIView* horizontalSlider in arrayOfHorizontalSliders) {
            
            CGPoint originalCenter = horizontalSlider.center;
            originalCenter.x = kHorizontalSliderTerminal + 10;
            horizontalSlider.center = originalCenter;
            
        }
        
    } completion:^(BOOL finished) {
        
        
        
        for (int i=0; i<4; i++) {
            
            [arrayOfHorizontalValues replaceObjectAtIndex:i withObject:[NSNumber numberWithFloat:1.0f]];
        }
        
        
        
        if (bSliderIsVertical) {
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateVerticalSlider object:[NSNumber numberWithFloat:verticalSliderValue]];
            
        }
        else
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateHorizontalSlider object:arrayOfHorizontalValues];
            
        }
        
        
    }];
    
    
    
    
}

-(void) tapToggleView:(UITapGestureRecognizer*) recognizer
{
    NSLog(@"toggle slider mode");
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kToggleSliderMode object:nil];
    
    if (bSliderIsVertical) {
        
        NSLog(@"Making slider horizontal");
        bSliderIsVertical = NO;
        
        for (UIView* horizontalSlider in arrayOfHorizontalSliders) {
            horizontalSlider.hidden = NO;
        }
        
        verticalSlider.hidden = YES;
     
        [toggleView setImage:multipleSliderImage];
        
    }
    else
    {
        NSLog(@"Making slider vertical");
        bSliderIsVertical = YES;
        
        for (UIView* horizontalSlider in arrayOfHorizontalSliders) {
            horizontalSlider.hidden = YES;
        }
        
        [toggleView setImage:singleSliderImage];
        
        verticalSlider.hidden = NO;
        
        
    }
    
    
}



-(void) panHorizontalSlider:(UIPanGestureRecognizer*) recognizer
{
    
    if(recognizer.state == UIGestureRecognizerStateBegan || recognizer.state == UIGestureRecognizerStateChanged)
    {
        CGPoint translation = [recognizer translationInView:recognizer.view.superview];
        
        if (recognizer.view.center.x + translation.x >= kHorizontalSliderTerminal + 10 ) {
            
            [recognizer.view setCenter:CGPointMake(kHorizontalSliderTerminal + 10, recognizer.view.center.y)];
            
        }
        else if (recognizer.view.center.x + translation.x < kHorizontalSliderOrigin ) {
            
            [recognizer.view setCenter:CGPointMake(kHorizontalSliderOrigin, recognizer.view.center.y)];
            
        }
        else {
            
            [recognizer.view setCenter:CGPointMake(recognizer.view.center.x + translation.x, recognizer.view.center.y)];
            
        }
        
        [recognizer setTranslation:CGPointZero inView:recognizer.view.superview];
        
        
        float horizontalValue = ( recognizer.view.center.x - 10 ) / (kHorizontalSliderTerminal);
        
        NSLog(@"%f", horizontalValue);
        
        [arrayOfHorizontalValues replaceObjectAtIndex:recognizer.view.tag withObject:[NSNumber numberWithFloat:horizontalValue]];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateHorizontalSlider object:arrayOfHorizontalValues];
        
    }

}




-(void) panVerticalSlider:(UIPanGestureRecognizer*) recognizer
{
    if([recognizer view] == verticalSlider)
    {
        if(recognizer.state == UIGestureRecognizerStateBegan || recognizer.state == UIGestureRecognizerStateChanged)
        {
            CGPoint translation = [recognizer translationInView:verticalSlider.superview];
            
            if (verticalSlider.center.y + translation.y >= kVerticalSliderTerminal + kVerticalSliderHeight/2 + 10) {

                [verticalSlider setCenter:CGPointMake(verticalSlider.center.x, kVerticalSliderTerminal + kVerticalSliderHeight/2 + 10)];

            }
            else if (verticalSlider.center.y + translation.y < kVerticalSliderOrigin + kVerticalSliderHeight/2 + 10) {
             
                [verticalSlider setCenter:CGPointMake(verticalSlider.center.x, kVerticalSliderOrigin + kVerticalSliderHeight/2 + 10)];

            }
            else {
            
                [verticalSlider setCenter:CGPointMake(verticalSlider.center.x, verticalSlider.center.y + translation.y)];

            }
            
            [recognizer setTranslation:CGPointZero inView:verticalSlider.superview];
     
            verticalSliderValue = ( verticalSlider.frame.origin.y - kVerticalSliderOrigin - 10) / (kVerticalSliderTerminal - kVerticalSliderOrigin);
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateVerticalSlider object:[NSNumber numberWithFloat:verticalSliderValue]];
            
        }
    }
}



-(void) panVerticalSliderFull:(UIPanGestureRecognizer*) recognizer
{
    if([recognizer view] == sliderView)
    {
        if (bSliderIsVertical) {

            if(recognizer.state == UIGestureRecognizerStateBegan || recognizer.state == UIGestureRecognizerStateChanged)
            {
                CGPoint translation = [recognizer translationInView:verticalSlider.superview];
                
                if (verticalSlider.center.y + translation.y >= kVerticalSliderTerminal + kVerticalSliderHeight/2 + 10) {
                    
                    [verticalSlider setCenter:CGPointMake(verticalSlider.center.x, kVerticalSliderTerminal + kVerticalSliderHeight/2 + 10)];
                    
                }
                else if (verticalSlider.center.y + translation.y < kVerticalSliderOrigin + kVerticalSliderHeight/2 + 10) {
                    
                    [verticalSlider setCenter:CGPointMake(verticalSlider.center.x, kVerticalSliderOrigin + kVerticalSliderHeight/2 + 10)];
                    
                }
                else {
                    
                    [verticalSlider setCenter:CGPointMake(verticalSlider.center.x, verticalSlider.center.y + translation.y)];
                    
                }
                
                [recognizer setTranslation:CGPointZero inView:verticalSlider.superview];
                
                verticalSliderValue = ( verticalSlider.frame.origin.y - kVerticalSliderOrigin - 10) / (kVerticalSliderTerminal - kVerticalSliderOrigin);
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateVerticalSlider object:[NSNumber numberWithFloat:verticalSliderValue]];
                
            }
        }
        else
        {
            if(recognizer.state == UIGestureRecognizerStateBegan || recognizer.state == UIGestureRecognizerStateChanged)
            {
                
                CGPoint translation = [recognizer translationInView:recognizer.view.superview];
                CGPoint location = [recognizer locationInView:recognizer.view];
                
                int index = floorf(location.y / 47);
                
//                NSLog(@"%d", index);
                
                if (index >= 0 && index < 4) {
                    
                    UIView* _handle = [arrayOfHorizontalSliders objectAtIndex:index];
                    
                    
                    
                    if (_handle.center.x + translation.x >= kHorizontalSliderTerminal + 10 ) {
                        
                        [_handle setCenter:CGPointMake(kHorizontalSliderTerminal + 10, _handle.center.y)];
                        
                    }
                    else if (_handle.center.x + translation.x < kHorizontalSliderOrigin ) {
                        
                        [_handle setCenter:CGPointMake(kHorizontalSliderOrigin, _handle.center.y)];
                        
                    }
                    else {
                        
                        [_handle setCenter:CGPointMake(_handle.center.x + translation.x, _handle.center.y)];
                        
                    }
                    
                    [recognizer setTranslation:CGPointZero inView:_handle.superview];
                    
                    
                    float horizontalValue = ( _handle.center.x - 10 ) / (kHorizontalSliderTerminal);
                    
                    NSLog(@"%f", horizontalValue);
                    
                    [arrayOfHorizontalValues replaceObjectAtIndex:_handle.tag withObject:[NSNumber numberWithFloat:horizontalValue]];
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateHorizontalSlider object:arrayOfHorizontalValues];
                    
                    
                }
            }
        }
    }
}










@end

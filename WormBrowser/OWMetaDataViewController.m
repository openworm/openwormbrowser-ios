//
//  OWMetaDataViewController.m
//  WormBrowser
//
//  Created by Rich Stoner on 12/20/12.
//  Copyright (c) 2012 Rich Stoner. All rights reserved.
//

#import "OWMetaDataViewController.h"
#import "RegexKitLite.h"

@interface OWMetaDataViewController ()
{
    
}

@property(nonatomic, strong) UIButton* mShowMetaDataButton;
@property(nonatomic, strong) UIWebView* metaDataView;

@end

@implementation OWMetaDataViewController

@synthesize metaDataView, mShowMetaDataButton;

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
    
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    self.metaDataView  = [[UIWebView alloc] initWithFrame:[self frameForWebView]];
    [self.metaDataView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
    [self.metaDataView setDelegate:self];
    [self.metaDataView setScalesPageToFit:YES];
    
    for(UIView *wview in [[[self.metaDataView subviews] objectAtIndex:0] subviews]) {
        if([wview isKindOfClass:[UIImageView class]]) { wview.hidden = YES; }
    }
    
    [self.view addSubview:self.metaDataView];
    
    mShowMetaDataButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [mShowMetaDataButton setFrame:CGRectMake(0,0,40,40)];
    [mShowMetaDataButton setImage:[UIImage imageNamed:@"37-circle-x"] forState:UIControlStateNormal];
    [mShowMetaDataButton setCenter:CGPointMake(self.view.frame.size.width - 30, 30)];
    [mShowMetaDataButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin];
//    [mShowMetaDataButton setBackgroundColor:[UIColor colorWithWhite:0.5f alpha:0.5]];
    
#warning TODO(RMS) add enum for this tag
    [mShowMetaDataButton setTag:0];
    [mShowMetaDataButton addTarget:self action:@selector(handleButtonTap:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:mShowMetaDataButton];
    
    

    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - public methods

-(void) loadAboutView
{
    
    BOOL iPad = NO;
#ifdef UI_USER_INTERFACE_IDIOM
    iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
#endif
    if (iPad) {
        
    
    NSMutableString* htmlString = [NSMutableString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"aboutIpad" ofType:@"html"] encoding:NSUTF8StringEncoding error:nil];
        NSString *path = [[NSBundle mainBundle] bundlePath];
        NSURL *baseURL = [NSURL fileURLWithPath:path];
        
        [self.metaDataView loadHTMLString:htmlString baseURL:baseURL];
        
    }
    else
    {
        NSMutableString* htmlString = [NSMutableString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"about" ofType:@"html"] encoding:NSUTF8StringEncoding error:nil];
        NSString *path = [[NSBundle mainBundle] bundlePath];
        NSURL *baseURL = [NSURL fileURLWithPath:path];
        
        [self.metaDataView loadHTMLString:htmlString baseURL:baseURL];
        
    }
    
    

    
    
}

-(void) populateWithMetaDataDict:(NSDictionary*) metaDataDictionary forTerm:(NSString*) term
{
    
    NSMutableString* htmlString = [NSMutableString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"header" ofType:@"html"] encoding:NSUTF8StringEncoding error:nil];
    [htmlString appendFormat:@"<h2>%@</h2>", term];
    
    for (NSString* key in [metaDataDictionary allKeys]) {
        
        [htmlString appendFormat:@"<h4>%@</h4><p>%@</p>", key, [self linkifyString:[metaDataDictionary objectForKey:key]]];
        
    }
    
    [htmlString appendString:[self closeHTML]];
    
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSURL *baseURL = [NSURL fileURLWithPath:path];

    [self.metaDataView loadHTMLString:htmlString baseURL:baseURL];
    
}


-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSRange contains = [request.URL.absoluteString rangeOfString:@".app"];
    
    if (contains.location == NSNotFound) {
        
        [[UIApplication sharedApplication] openURL:request.URL];
        
        return NO;
    }
    else{
        return YES;
    }
}

-(NSString*) linkifyString:(NSString*) inputString
{
    
//    [ADA](http://www.wormatlas.org/ver1/MoW_built0.92/cells/ada.html)
//    NSString *regEx = @"\\[(.*)\\]\\((.*)\\)";
    
    NSString* regEx = @"\\[(.*?)]\\((.*?)\\)";
    
    NSMutableArray* arrayOfRanges = [[NSMutableArray alloc] init];
//    NSMutableArray* arrayOfTagStrings = [[NSMutableArray alloc] init];
    NSMutableString* outputString = [[NSMutableString alloc] init];
    
    BOOL foundMatch = NO;
    
    for(NSString *match in [inputString componentsMatchedByRegex:regEx]) {
        
        foundMatch = YES;
        
        // match contains the [..](..) string
        NSRange matchRange = [inputString rangeOfString:match];
        
        [arrayOfRanges addObject:[NSValue valueWithRange:matchRange]];
        
        NSArray* splitArray = [match arrayOfCaptureComponentsMatchedByRegex:regEx];
        NSString* tagString = [NSString stringWithFormat:@"<a href=\"%@\" target='_blank'>%@</a>", splitArray[0][2], splitArray[0][1]];
        
        [outputString appendFormat:@"<p>%@</p>", tagString];
    }
    
    if (foundMatch) {
        return outputString;
    }
    else
    {
        return inputString;
    }
  


    

//
//    if ([arrayOfRanges count] > 0) {
//        
//        [outputString appendString:[inputString substringToIndex:[(NSValue*)arrayOfRanges[0] rangeValue].location]];
//    }
//    
//    NSUInteger location = 0;
//    
//    for (int i =1; i < [arrayOfRanges count]; i++) {
//        
//        NSRange prelocrange = [(NSValue*)[arrayOfRanges objectAtIndex:i-1] rangeValue];
//        NSRange curlocrange =[(NSValue*)[arrayOfRanges objectAtIndex:i] rangeValue];
//        location = prelocrange.location + prelocrange.length;
//        
//        [outputString appendString:arrayOfTagStrings[i]];
//        [outputString appendString:[inputString substringWithRange:NSMakeRange(location, curlocrange.location - location)]];
//        
//        
//    }
    
//    NSLog(@"output string: %@", arrayOfTagStrings);
    
//    return @"haha";
}


-(NSString*) closeHTML
{
    return @"</div></div></div></body>";
}


#pragma mark - Frame methods

-(CGRect) frameForWebView
{
    return self.view.frame;
}


#pragma mark - webview methods


#pragma mark - handle button taps on main screen

-(void) handleButtonTap:(id)sender
{
    int tag = [sender tag];
    
    switch (tag) {
        case 0:
            
            
            [self closeView];
            
            break;
            
        default:
            break;
    }
}

-(void) closeView
{
    BOOL iPad = NO;
#ifdef UI_USER_INTERFACE_IDIOM
    iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
#endif
    if (iPad) {

        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationCloseMetaView object:nil];

    }
    else
    {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationCloseMetaView object:nil];
        
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
        
       
        
        
    }
}


@end

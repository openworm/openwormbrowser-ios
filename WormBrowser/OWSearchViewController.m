//
//  OWSearchViewController.m
//  WormBrowser
//
//  Created by Rich Stoner on 12/4/12.
//  Copyright (c) 2012 Rich Stoner. All rights reserved.
//

#import "OWSearchViewController.h"
#import "SearchTermCell.h"

@interface OWSearchViewController ()
{
    UIToolbar* topToolBar;
    UITableView* entityTable;
    
    UIBarButtonItem* homeBarItem;
    UIBarButtonItem* starBarItem;
    UIBarButtonItem* mailBarItem;
    UIBarButtonItem* actionBarItem;
    
    UIBarButtonItem* flexBarItem;
    UIBarButtonItem* fixedBarItem;

    UIBarButtonItem* searchBarButtonItem;
    UIBarButtonItem* searchBarItem;
    UISearchBar*     mSearchBar;
    UIBarButtonItem* searchCancel;
    
    UIBarButtonItem* closeView;
    
    
    UIBarButtonItem* skinLayerItem;
    UIBarButtonItem* organsLayerItem;
    UIBarButtonItem* muscleLayerItem;
    UIBarButtonItem* neuronLayerItem;
    
    
}

@property(strong, nonatomic) NSArray* unfilteredArray;
@property(strong, nonatomic) NSMutableArray* filteredArray;

@end

@implementation OWSearchViewController

@synthesize unfilteredArray, filteredArray;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        unfilteredArray = [[NSArray alloc] init];
        filteredArray = [[NSMutableArray alloc] init];
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
//    [self.view setBackgroundColor:[UIColor blackColor]];
    [self.view setClipsToBounds:YES];
    self.view.layer.cornerRadius = 5.0f;
//    self.view.layer.borderColor = [UIColor blackColor].CGColor;
//    self.view.layer.borderWidth = 1.0;
    
//    [self.view setAutoresizingMask:UIViewAutoresizingNone];
    
    [self setupToolbar];
    [self setupToolbarItems];

    [self setTable];
    [self loadDefaultItems];
    [self showDefaultBar];
}

-(void) viewDidAppear:(BOOL)animated
{

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - load items by layer

-(void) loadDefaultItems
{
    
    OWAppDelegate* delegate = AppDelegate;
    [self setUnfilteredArray:[delegate.resource getArrayofLayers]];

}


#pragma mark - toolbar method

-(void) setupToolbar
{
    topToolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, kBarThickness)];
    [topToolBar setBarStyle:UIBarStyleBlackTranslucent];
    [topToolBar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [topToolBar setBackgroundImage:[UIImage imageNamed:@"subtlenet2"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    
    NSLog(@"%@", [NSValue valueWithCGRect:topToolBar.frame]);
    
    //    [topToolBar setBarStyle:UIBarStyleBlack]
    //    [topToolBar setTranslucent:YES];
    //
//    for (UIView * sv in [topToolBar subviews])
//    {
//        [sv removeFromSuperview];
//    }
    
    [self.view addSubview:topToolBar];
}

-(void) setupToolbarItems
{
    homeBarItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(handleToolBarTap:)];
    [homeBarItem setTintColor:kWormGreen];
    [homeBarItem setTag:barButton_home];
    
    starBarItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks target:self action:@selector(handleToolBarTap:)];
    [starBarItem setTintColor:kWormGreen];
    [starBarItem setTag:barButton_star];
    
    mailBarItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(handleToolBarTap:)];
    [mailBarItem setTintColor:kWormGreen];
    [mailBarItem setTag:barButton_mail];
    
    actionBarItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(handleToolBarTap:)];
    [actionBarItem setTintColor:kWormGreen];
    [actionBarItem setTag:barButton_action];
    
    

    UIFont* fontToUse;
    
    BOOL iPad = NO;
#ifdef UI_USER_INTERFACE_IDIOM
    iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
#endif
    if (iPad) {
    
        fontToUse = kMenuFontIpad;
        
    }
    else
    {
        fontToUse = kMenuFontIphone;
        
    }
    

    skinLayerItem = [[UIBarButtonItem alloc] initWithTitle:@"Cut." style:UIBarButtonItemStylePlain target:self action:@selector(handleToolBarTap:)];
//    [skinLayerItem setTintColor:kWormGreen];

    [skinLayerItem setTitleTextAttributes:
     @{
                 UITextAttributeTextColor: kWormGreen,
                      UITextAttributeFont: fontToUse,
          UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetMake(0, 1)],
           UITextAttributeTextShadowColor: [UIColor colorWithWhite:0.0 alpha:0.5],     
     }
                                 forState:UIControlStateNormal];
    
    [skinLayerItem setTag:barButton_scrollToSkin];
    [skinLayerItem setWidth:40.0f];
    
    organsLayerItem = [[UIBarButtonItem alloc] initWithTitle:@"Org." style:UIBarButtonItemStylePlain target:self action:@selector(handleToolBarTap:)];
    [organsLayerItem setTitleTextAttributes:
     @{
                 UITextAttributeTextColor: kWormGreen,
                      UITextAttributeFont: fontToUse,
          UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetMake(0, 1)],
           UITextAttributeTextShadowColor: [UIColor colorWithWhite:0.0 alpha:0.5],
     }
                                 forState:UIControlStateNormal];
    [organsLayerItem setTag:barButton_scrollToOrgans];
    [organsLayerItem setWidth:40.0f];
    
    muscleLayerItem = [[UIBarButtonItem alloc] initWithTitle:@"Mus." style:UIBarButtonItemStylePlain target:self action:@selector(handleToolBarTap:)];
    [muscleLayerItem setTitleTextAttributes:
     @{
                 UITextAttributeTextColor: kWormGreen,
                      UITextAttributeFont: fontToUse,
          UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetMake(0, 1)],
           UITextAttributeTextShadowColor: [UIColor colorWithWhite:0.0 alpha:0.5],
     }
                                 forState:UIControlStateNormal];
    [muscleLayerItem setTag:barButton_scrollToMuscles];
    [muscleLayerItem setWidth:40.0f];    
    
    neuronLayerItem = [[UIBarButtonItem alloc] initWithTitle:@"Neu." style:UIBarButtonItemStylePlain target:self action:@selector(handleToolBarTap:)];
    [neuronLayerItem setTitleTextAttributes:
     @{
                 UITextAttributeTextColor: kWormGreen,
                      UITextAttributeFont: fontToUse,
          UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetMake(0, 1)],
           UITextAttributeTextShadowColor: [UIColor colorWithWhite:0.0 alpha:0.5],
     }
                                 forState:UIControlStateNormal];
    [neuronLayerItem setTag:barButton_scrollToNeurons];
    [neuronLayerItem setWidth:40.0f];

    
    
    
    
    // search
    
    searchBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(handleToolBarTap:)];
    [searchBarButtonItem setTintColor:kWormGreen];

    [searchBarButtonItem setTag:barButton_search];
    
    mSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0,0,250, kBarThickness)];
    [mSearchBar setAutoresizingMask:UIViewAutoresizingNone];
    [mSearchBar setDelegate:self];
    [mSearchBar setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [mSearchBar setKeyboardType:UIKeyboardTypeASCIICapable];
    [mSearchBar setBackgroundImage:[UIImage imageNamed:@"subtlenet2"]];

    searchBarItem = [[UIBarButtonItem alloc] initWithCustomView:mSearchBar];
    
    searchCancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(handleToolBarTap:)];
    [searchCancel setTintColor:kWormGreen];
    [searchCancel setTag:barButton_searchDone];
    
    
    
    // misc items
    
    flexBarItem  = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    fixedBarItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [fixedBarItem setWidth:30];
    
    // close item
    
    closeView = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(handleToolBarTap:)];
    [closeView setTag:barButton_close];
    [closeView setTintColor:kWormGreen];
    
}




#pragma mark - tableview method

-(void) setTable
{
    entityTable = [[UITableView alloc] initWithFrame:[self frameForTable] style:UITableViewStylePlain];
    [entityTable setBackgroundColor:[UIColor clearColor]];
    [entityTable setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [entityTable setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [entityTable setDataSource:self];

    [entityTable setDelegate:self];
    
    [self.view addSubview:entityTable];
}

-(CGRect) frameForTable
{
    return CGRectMake(0, kBarThickness, self.view.frame.size.width, self.view.frame.size.height - kBarThickness);
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ExampleCell";
    
    SearchTermCell *cell = (SearchTermCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[SearchTermCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    //    NSLog(@"%@ - %d", m_set.tileCount, indexPath.row);
    
    //    AnatomicTile* tile = [m_set tileForIndex:indexPath.row];
    //
    //    switch (tile.tileFormat) {
    //        case 1:
    //
    //            [cell setFlickrPhoto:[NSString stringWithFormat:@"%@?0+0+0+256+-1+80", tile.thumbnailURL]];
    //            [cell setMainText:tile.tileID];
    //            [cell setDimensions:[NSString stringWithFormat:@"%d x %d", tile.m_width, tile.m_height]];
    //            break;
    //        default:
    //            break;
    //    }
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
//    [cell.mainText setText:@"example"];
    [cell.mainText setText:[self titleForCellAtIndexPath:indexPath]];
    
    return cell;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.filteredArray count];
}

-(NSString*)titleForCellAtIndexPath:(NSIndexPath*) indexPath
{
    NSDictionary* layerDict = [self.filteredArray objectAtIndex:indexPath.section];
    NSArray* layerArray = [layerDict objectForKey:[[layerDict allKeys] objectAtIndex:0]];
    return [layerArray objectAtIndex:indexPath.row];
}

-(NSString*)titleForSection:(int)section
{
    return [[[self.filteredArray objectAtIndex:section] allKeys] objectAtIndex:0];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSDictionary* layerDict = [self.filteredArray objectAtIndex:section];
    NSArray* layerArray = [layerDict objectForKey:[[layerDict allKeys] objectAtIndex:0]];
    
    return [layerArray count];
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 40;
}

-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UILabel* returnLabel = [[UILabel alloc] initWithFrame:CGRectMake(10,0,350, 40)];
    [returnLabel setBackgroundColor:[UIColor clearColor]];
    [returnLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f]];
    [returnLabel setText:[NSString stringWithFormat:@"Layer : %@", [self titleForSection:section]]];
    
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, entityTable.frame.size.width, 40)];
    [view setBackgroundColor:[UIColor colorWithWhite:0.9f alpha:1.0f]];
    [view addSubview:returnLabel];
    
    
    return view;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40;
}



//-(UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
//{
//    UIView*
//}
//
//-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
//{
//    return 40;
//}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    NSString* sectionName = [[[self.filteredArray objectAtIndex:indexPath.section] allKeys] objectAtIndex:0];
    NSString* objectName = [[[self.filteredArray objectAtIndex:indexPath.section] objectForKey:sectionName] objectAtIndex:indexPath.row];
    
    OWAppDelegate* delegate = AppDelegate;
    //    [self setUnfilteredArray:[delegate.resource getArrayofLayers]];
    OWResource* resource = delegate.resource;
    OWEntityInfo* info = [resource getInfoForEntityName:objectName];
    
    [info printDebugString];
    
//    
//    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationCloseSearchView object:nil];
//    
//    [self dismissViewControllerAnimated:YES completion:^{
//        
//        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationShowMetaDataForItem object:objectName];
//        
//    }];
    
    BOOL iPad = NO;
#ifdef UI_USER_INTERFACE_IDIOM
    iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
#endif
    if (iPad) {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationShowMetaDataForItem object:objectName];

        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSelectSingleObject object:objectName];

   
    }
    else
    {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationCloseSearchView object:nil];
        
        [self dismissViewControllerAnimated:YES completion:^{
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSelectSingleObject object:objectName];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationShowMetaDataForItem object:objectName];
            
        }];
        
        
    }

    
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* sectionName = [[[self.filteredArray objectAtIndex:indexPath.section] allKeys] objectAtIndex:0];
    NSString* objectName = [[[self.filteredArray objectAtIndex:indexPath.section] objectForKey:sectionName] objectAtIndex:indexPath.row];
    
    NSLog(@"%@", objectName);
    
    
    
    OWAppDelegate* delegate = AppDelegate;
//    [self setUnfilteredArray:[delegate.resource getArrayofLayers]];
    OWResource* resource = delegate.resource;
    OWEntityInfo* info = [resource getInfoForEntityName:objectName];
    
    [info printDebugString];
    
    BOOL iPad = NO;
#ifdef UI_USER_INTERFACE_IDIOM
    iPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
#endif
    if (iPad) {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSelectSingleObject object:objectName];

        
    }
    else
    {
     
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationCloseSearchView object:nil];
        
        [self dismissViewControllerAnimated:YES completion:^{
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSelectSingleObject object:objectName];
            
        }];
        
        
    }
    
    

    
    
    
    return indexPath;
}



#pragma mark - Handle toolbar tap

-(void) handleToolBarTap:(id) sender
{
    CGRect sectionRect;
    barButtons selectedButton = [sender tag];
    
    NSIndexPath* path;
    
    switch (selectedButton) {
        case barButton_action:
        case barButton_home:
        case barButton_mail:
        case barButton_star:
            
            NSLog(@"tap button");
            
            break;
            
        case barButton_search:
            
            NSLog(@"Tap search");
            
            [self showSearchBar];
            
            break;
            
        case barButton_searchDone:
            
            [mSearchBar resignFirstResponder];
            [self showDefaultBar];
            
            break;
        
        case barButton_close:

            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationCloseSearchView object:nil];
            
            [self dismissViewControllerAnimated:YES completion:^{
                
            }];
            

            
            break;
            
        case barButton_scrollToSkin:
            
            NSLog(@"Tap scroll");
            
//            sectionRect = [entityTable rectForHeaderInSection:0];
//            [entityTable scrollRectToVisible:sectionRect animated:YES];
//
            path = [NSIndexPath indexPathForItem:0 inSection:0];
            [entityTable scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionTop animated:YES];
            
            
            break;
            
        case barButton_scrollToMuscles:
            
            
            NSLog(@"Tap muscles");
            
//            sectionRect = [entityTable rectForHeaderInSection:1];
//            [entityTable scrollRectToVisible:sectionRect animated:YES];
//            
            path = [NSIndexPath indexPathForItem:0 inSection:2];
            [entityTable scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionTop animated:YES];
            
            
            
            break;
            
        case barButton_scrollToOrgans:
            
            NSLog(@"Tap organs");
            
//            sectionRect = [entityTable rectForHeaderInSection:2];
            
            path = [NSIndexPath indexPathForItem:0 inSection:3];
            [entityTable scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionTop animated:YES];
            
//            [entityTable scrollRectToVisible:sectionRect animated:YES];
//            [entityTable scrollToRowAtIndexPath:<#(NSIndexPath *)#> atScrollPosition:<#(UITableViewScrollPosition)#> animated:<#(BOOL)#>]
            
            break;
            
        case barButton_scrollToNeurons:
            
            NSLog(@"Tap neurons");
//            
//            sectionRect = [entityTable rectForHeaderInSection:3];
//            [entityTable scrollRectToVisible:sectionRect animated:YES];
//            

            path = [NSIndexPath indexPathForItem:0 inSection:1];
            [entityTable scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionTop animated:YES];
            
            break;
            
        default:
            break;
    }
    
}


-(void) showSearchBar
{
    [topToolBar setItems:@[searchBarItem, flexBarItem, searchCancel] animated:YES];
    [mSearchBar becomeFirstResponder];
}

-(void) showDefaultBar
{
    [mSearchBar setText:@""];
    
//    [topToolBar setItems:@[homeBarItem, fixedBarItem, starBarItem, fixedBarItem, mailBarItem, fixedBarItem, actionBarItem, fixedBarItem, searchBarButtonItem, flexBarItem, closeView]];
//    [topToolBar setItems:@[searchBarButtonItem, flexBarItem, closeView]];
    [topToolBar setItems:@[searchBarButtonItem, flexBarItem, skinLayerItem, organsLayerItem, muscleLayerItem, neuronLayerItem, flexBarItem, closeView]];
    
    [self.filteredArray removeAllObjects];
    [self.filteredArray setArray:self.unfilteredArray];
    [entityTable reloadData];
}

#pragma mark - search bar delegates


//- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar;                      // return NO to not become first responder
//- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar;                     // called when text starts editing
//- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar;                        // return NO to not resign first responder
//- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar;                       // called when text ends editing

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText   // called when text changes (including clear)
{
    if ([searchBar.text length] > 0) {
        // have something to search for
    
        NSString* lowerCaseString = [searchText lowercaseString];
        
        [self.filteredArray removeAllObjects];
        
        for (NSDictionary* layerDict in self.unfilteredArray) {
            
            // 'layer name' : 'array of object names, sorted'
            
            BOOL foundInThisLayer = NO;
            
            NSMutableArray* includeArray;
            
            NSString* keyName = [[layerDict allKeys] objectAtIndex:0];
            
            for (NSString* meshName in [layerDict objectForKey:keyName]) {
                
                if ([meshName rangeOfString:lowerCaseString options:NSCaseInsensitiveSearch].location != NSNotFound) {
                    
                    if (!foundInThisLayer) {
                        includeArray = [[NSMutableArray alloc] init];
                        foundInThisLayer = YES;
                    }
                    
                    [includeArray addObject:meshName];
                    
                    
                }
            }
            
            if (foundInThisLayer) {
                
                [self.filteredArray addObject:[NSDictionary dictionaryWithObject:includeArray forKey:keyName]];
            }
        }
    }
    else
    {
        [self.filteredArray removeAllObjects];
        [self.filteredArray setArray:self.unfilteredArray];
    }
    
    [entityTable reloadData];
        
}

//- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text NS_AVAILABLE_IOS(3_0); // called before text changes
//
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar                     // called when keyboard search button pressed
{
    [searchBar resignFirstResponder];
}

//- (void)searchBarBookmarkButtonClicked:(UISearchBar *)searchBar;                   // called when bookmark button pressed
//- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar;                    // called when cancel button pressed
//- (void)searchBarResultsListButtonClicked:(UISearchBar *)searchBar NS_AVAILABLE_IOS(3_2); // called when search results button pressed
//
//- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope NS_AVAILABLE_IOS(3_0);




@end

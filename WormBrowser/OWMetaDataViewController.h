//
//  OWMetaDataViewController.h
//  WormBrowser
//
//  Created by Rich Stoner on 12/20/12.
//  Copyright (c) 2012 Rich Stoner. All rights reserved.
//

#import <UIKit/UIKit.h>

/** OWMetaDataViewController description
 
*/
@interface OWMetaDataViewController : UIViewController <UIWebViewDelegate>



/**
 Loads the metadata dictionary and generates HTML to render
 @param metaDataDictionary nsdict of key-value pairs to render
 @param term the title object, in our case selected object
 */
-(void) populateWithMetaDataDict:(NSDictionary*) metaDataDictionary forTerm:(NSString*) term;

/** loads the about view html
 
 */
-(void) loadAboutView;

@end

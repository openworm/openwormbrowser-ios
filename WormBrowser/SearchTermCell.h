//
//  SearchTermCell.h
//
//  Created by Richard Stoner on 2/21/12.
//  Copyright (c) 2012 UCSD. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SearchTermCell : UITableViewCell
{
    UILabel*        mainText; // header
    UIImageView*    normalityView;
}

@property(nonatomic, retain) UILabel* mainText;
@property(nonatomic, retain) UIImageView* normalityView;

@end

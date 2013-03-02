//
//  SearchTermCell.m
//
//  Created by Richard Stoner on 2/21/12.
//

#import "SearchTermCell.h"

@implementation SearchTermCell

@synthesize mainText;
@synthesize normalityView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        
        self.contentView.backgroundColor = [UIColor clearColor];   
        
        mainText = [[UILabel alloc] initWithFrame:CGRectMake(14, 5, 500, 30)];
        [mainText setFont:[UIFont fontWithName:@"HelveticaNeue-CondensedBold" size:15]];
        mainText.text = @"Primary Label";
        mainText.textColor = [UIColor blackColor];
        
//        [self setAccessoryType:UITableViewCellAccessoryDetailDisclosureButton];   
        
//        normalityView = [[UIImageView alloc] initWithFrame:CGRectMake(10,10,16,16)];
//        [normalityView.layer setCornerRadius:8.0];
//        [normalityView setBackgroundColor:[UIColor clearColor]];
//        [normalityView.layer setBorderWidth:1];
//        [normalityView.layer setBorderColor:[UIColor darkGrayColor].CGColor];
//        
        [self.contentView addSubview:mainText];
        [self.contentView addSubview:normalityView];
    }
	
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    if (selected) {
        mainText.textColor = [UIColor whiteColor];        
        mainText.backgroundColor = [UIColor clearColor];
        self.backgroundColor = [UIColor colorWithRed:0.0 green:0.50 blue:0.0 alpha:1.0];

//        [normalityView.layer setBorderColor:[UIColor whiteColor].CGColor];
//        [mainText setFont:[UIFont fontWithName:@"HelveticaNeue" size:14]];
        [mainText setShadowColor:[UIColor blackColor]];
        [mainText setShadowOffset:CGSizeMake(1, 1)];
    }
    else
    {
        mainText.textColor = [UIColor blackColor];        
        mainText.backgroundColor = [UIColor whiteColor];
        self.backgroundColor = [UIColor whiteColor];
        
//        [normalityView.layer setBorderColor:[UIColor darkGrayColor].CGColor];        
//        [mainText setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:14]];
        [mainText setShadowColor:[UIColor whiteColor]];
    }
}

@end

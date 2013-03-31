//
//    OpenWorm Browser for iOS **
//
//    Developed for the OpenWorm.org project.
//    Inspired / ported from Google Body Browser (now https://code.google.com/p/open-3d-viewer/)
//    Released under MIT license
//
//    Copyright 2012 Rich Stoner
//
//    Permission is hereby granted, free of charge, to any person obtaining
//    a copy of this software and associated documentation files (the
//    "Software"), to deal in the Software without restriction, including
//    without limitation the rights to use, copy, modify, merge, publish,
//    distribute, sublicense, and/or sell copies of the Software, and to
//    permit persons to whom the Software is furnished to do so, subject to
//    the following conditions:
//
//    The above copyright notice and this permission notice shall be
//    included in all copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//    NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
//    LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
//    OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//    WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

//
//  SearchTermCell.m

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

        [mainText setShadowColor:[UIColor blackColor]];
        [mainText setShadowOffset:CGSizeMake(1, 1)];
    }
    else
    {
        mainText.textColor = [UIColor blackColor];        
        mainText.backgroundColor = [UIColor whiteColor];
        self.backgroundColor = [UIColor whiteColor];
        
        [mainText setShadowColor:[UIColor whiteColor]];
    }
}

@end

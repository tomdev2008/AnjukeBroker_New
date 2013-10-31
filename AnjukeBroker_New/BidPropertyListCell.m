//
//  BidPropertyListCell.m
//  AnjukeBroker_New
//
//  Created by jianzhongliu on 10/29/13.
//  Copyright (c) 2013 Wu sicong. All rights reserved.
//

#import "BidPropertyListCell.h"
#import "Util_UI.h"

@implementation BidPropertyListCell
@synthesize title;
@synthesize price;
@synthesize string;
@synthesize stringNum;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        title = [[UILabel alloc] initWithFrame:CGRectMake(20, 10, 200, 20)];
        title.text = @"汤臣一品";
        title.textColor = SYSTEM_BLACK;
        title.font = [UIFont systemFontOfSize:16];
        [self.contentView addSubview:title];
        
        price = [[UILabel alloc] initWithFrame:CGRectMake(20, 35, 200, 20)];
        price.textColor = [Util_UI colorWithHexString:@"666666"];
        price.text = @"3室2厅 120平 400万";
        price.font = [UIFont systemFontOfSize:12];
        price.layer.cornerRadius = 6;
        [self.contentView addSubview:price];
        
        UILabel *contentView = [[UILabel alloc] initWithFrame:CGRectMake(0, 62, 320, 50)];
        [contentView setBackgroundColor:[Util_UI colorWithHexString:@"#F9F9F9"]];
        
        string = [[UILabel alloc] initWithFrame:CGRectMake(20, 5, 280, 20)];
        string.textColor = [Util_UI colorWithHexString:@"#666666"];
        string.text = @"当前排名       今日点击       出价(元)      预算余额(元)";
        string.font = [UIFont systemFontOfSize:11];
        string.layer.cornerRadius = 6;
        [contentView addSubview:string];
        
        stringNum = [[UILabel alloc] initWithFrame:CGRectMake(20, 25, 280, 20)];
        stringNum.text = @"   1                  10                  2.0             18.00";
        stringNum.font = [UIFont systemFontOfSize:12];
        stringNum.layer.cornerRadius = 6;
        [contentView addSubview:stringNum];
        [self.contentView addSubview:contentView];

        // Initialization code
    }
    return self;
}
-(void)setValueForCellByDictinary:(NSDictionary *) dic{
    title.text = [dic objectForKey:@"title"];
    price.text = [dic objectForKey:@"price"];
    string.text = [dic objectForKey:@"string"];
    stringNum.text = [dic objectForKey:@"stringNum"];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end

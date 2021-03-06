//
//  PPCDataShowCell.m
//  AnjukeBroker_New
//
//  Created by xiazer on 14-7-1.
//  Copyright (c) 2014年 Anjuke. All rights reserved.
//

#import "PPCDataShowCell.h"
#import "PPCDataShowModel.h"

@interface PPCDataShowCell ()
@property(nonatomic, strong) UILabel *titLab;
@property(nonatomic, strong) UILabel *todayClickLab;
@property(nonatomic, strong) UILabel *todayCostLab;
@property(nonatomic, strong) UILabel *houseNumLab;
@end

@implementation PPCDataShowCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)initUI{
    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 150)];
    bgView.backgroundColor = [UIColor whiteColor];
    [self.contentView addSubview:bgView];

    self.backgroundColor = [UIColor brokerWhiteColor];
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    self.selectionStyle = UITableViewCellSelectionStyleGray;
    
    self.titLab = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 120, 20)];
    self.titLab.backgroundColor = [UIColor clearColor];
    self.titLab.textAlignment = NSTextAlignmentLeft;
    self.titLab.font = [UIFont ajkH2Font_B];
    self.titLab.textColor = [UIColor brokerBlackColor];
    [self.contentView addSubview:self.titLab];

    UILabel *clickTitLab = [[UILabel alloc] initWithFrame:CGRectMake(30, 120, 60, 15)];
    clickTitLab.backgroundColor = [UIColor clearColor];
    clickTitLab.textAlignment = NSTextAlignmentLeft;
    clickTitLab.font = [UIFont ajkH5Font];
    clickTitLab.textColor = [UIColor brokerMiddleGrayColor];
    clickTitLab.text = @"今日点击";
    [self.contentView addSubview:clickTitLab];
    
    UILabel *costTitLab = [[UILabel alloc] initWithFrame:CGRectMake(145, 120, 60, 15)];
    costTitLab.backgroundColor = [UIColor clearColor];
    costTitLab.textAlignment = NSTextAlignmentLeft;
    costTitLab.font = [UIFont ajkH5Font];
    costTitLab.textColor = [UIColor brokerMiddleGrayColor];
    costTitLab.text = @"今日花费";
    [self.contentView addSubview:costTitLab];

    UILabel *houseNumTitLab = [[UILabel alloc] initWithFrame:CGRectMake(225, 120, 60, 15)];
    houseNumTitLab.backgroundColor = [UIColor clearColor];
    houseNumTitLab.textAlignment = NSTextAlignmentLeft;
    houseNumTitLab.font = [UIFont ajkH5Font];
    houseNumTitLab.textColor = [UIColor brokerMiddleGrayColor];
    houseNumTitLab.text = @"房源量";
    [self.contentView addSubview:houseNumTitLab];
    
    self.todayClickLab = [[UILabel alloc] initWithFrame:CGRectMake(30, 45, 110, 80)];
    self.todayClickLab.backgroundColor = [UIColor clearColor];
    self.todayClickLab.font = [UIFont boldSystemFontOfSize:80];
    self.todayClickLab.text = @"0";
    [self.contentView addSubview:self.todayClickLab];

    self.todayCostLab = [[UILabel alloc] initWithFrame:CGRectMake(145, 90, 60, 30)];
    self.todayCostLab.backgroundColor = [UIColor clearColor];
    self.todayCostLab.textColor = [UIColor brokerMiddleGrayColor];
    self.todayCostLab.font = [UIFont boldSystemFontOfSize:30];
    self.todayCostLab.text = @"0";
    [self.contentView addSubview:self.todayCostLab];

    self.houseNumLab = [[UILabel alloc] initWithFrame:CGRectMake(225, 90, 60, 30)];
    self.houseNumLab.backgroundColor = [UIColor clearColor];
    self.houseNumLab.textColor = [UIColor brokerMiddleGrayColor];
    self.houseNumLab.font = [UIFont boldSystemFontOfSize:30];
    self.houseNumLab.text = @"0";
    [self.contentView addSubview:self.houseNumLab];
}

- (BOOL)configureCell:(id)dataModel withIndex:(int)index {
    if (self.cellType == CELLTYPEFORPRICING) {
        self.titLab.text = @"定价推广";
        self.todayClickLab.textColor = [UIColor brokerBlueColor];
    }else if (self.cellType == CELLTYPEFORSELECTING){
        self.titLab.text = @"精选推广";
        self.todayClickLab.textColor = [UIColor colorWithHex:0xFFB75B alpha:1.0];
    }else if (self.cellType == CELLTYPEFORBIT){
        self.titLab.text = @"竞价推广";
        self.todayClickLab.textColor = [UIColor colorWithHex:0xFFB75B alpha:1.0];
    }

    
    PPCDataShowModel *model = (PPCDataShowModel *)dataModel;
    
    NSString *clickStr = [NSString stringWithFormat:@"%d",[model.todayClickNum intValue]];
    
    self.todayClickLab.text = clickStr;
    if (clickStr.length == 3) {
        self.todayClickLab.font = [UIFont systemFontOfSize:60];
    }else if (clickStr.length == 4){
        self.todayClickLab.font = [UIFont systemFontOfSize:50];
    }
    
    self.todayCostLab.text = model.todayCostFee;
    self.houseNumLab.text = [NSString stringWithFormat:@"%d",[model.houseNum intValue]];
    
    return YES;
}
@end

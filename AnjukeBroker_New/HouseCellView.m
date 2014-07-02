//
//  HouseCellView.m
//  AnjukeBroker_New
//
//  Created by xiazer on 14-7-2.
//  Copyright (c) 2014年 Wu sicong. All rights reserved.
//

#import "HouseCellView.h"
#import "BK_WebImageView.h"
#import "PPCPriceingListModel.h"
#import "Util_UI.h"

@interface HouseCellView ()
@property(nonatomic, strong) BK_WebImageView *mainImgView;
@property(nonatomic, strong) UILabel *titLab;
@property(nonatomic, strong) UIImageView *mutImgView;
@property(nonatomic, strong) UIImageView *choiceImgView;
@property(nonatomic, strong) UIImageView *fromImgView;
@property(nonatomic, strong) UILabel *commNameLab;
@property(nonatomic, strong) UILabel *houseDetailLab;
@property(nonatomic, strong) UILabel *totalClickTitLab;
@property(nonatomic, strong) UILabel *totalClickLab;
@end

@implementation HouseCellView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self initUI];
    }
    return self;
}

- (void)configCellViewWithData:(id)dataModel{
    [self configureView:dataModel];
}

- (void)initUI{
    self.mainImgView = [[BK_WebImageView alloc] initWithFrame:CGRectMake(15, 15, 80, 60)];
    self.mainImgView.layer.masksToBounds = YES;
    self.mainImgView.layer.cornerRadius = 4;
    self.mainImgView.backgroundColor = [UIColor brokerLineColor];
    [self addSubview:self.mainImgView];
    
    self.titLab = [[UILabel alloc] initWithFrame:CGRectMake(80+15+11, 15, 200, 20)];
    self.titLab.textColor = [UIColor brokerBlackColor];
    self.titLab.backgroundColor = [UIColor clearColor];
    self.titLab.font = [UIFont ajkH3Font];
    [self addSubview:self.titLab];
    
    self.commNameLab = [[UILabel alloc] initWithFrame:CGRectMake(80+15+11, 40, 200, 15)];
    self.commNameLab.textColor = [UIColor brokerLightGrayColor];
    self.commNameLab.backgroundColor = [UIColor clearColor];
    self.commNameLab.font = [UIFont ajkH4Font];
    [self addSubview:self.commNameLab];
    
    self.houseDetailLab = [[UILabel alloc] initWithFrame:CGRectMake(80+15+11, 65, 150, 15)];
    self.houseDetailLab.textColor = [UIColor brokerLightGrayColor];
    self.houseDetailLab.backgroundColor = [UIColor clearColor];
    self.houseDetailLab.font = [UIFont ajkH4Font];
    [self addSubview:self.houseDetailLab];
    
    self.totalClickTitLab = [[UILabel alloc] initWithFrame:CGRectMake(ScreenWidth-25-50, 65, 50, 15)];
    self.totalClickTitLab.textColor = [UIColor brokerBlackColor];
    self.totalClickTitLab.backgroundColor = [UIColor clearColor];
    self.totalClickTitLab.textAlignment = NSTextAlignmentRight;
    self.totalClickTitLab.font = [UIFont ajkH4Font];
    self.totalClickTitLab.text = @"总点击";
    [self addSubview:self.totalClickTitLab];
    
    self.totalClickLab = [[UILabel alloc] initWithFrame:CGRectMake(ScreenWidth-15-57, 65 - 1, 60, 15)];
    self.totalClickLab.textColor = [UIColor brokerBlackColor];
    self.totalClickLab.backgroundColor = [UIColor clearColor];
    self.totalClickLab.font = [UIFont ajkH3Font];
    self.totalClickLab.textAlignment = NSTextAlignmentRight;
    self.totalClickLab.text = @"0";
    [self addSubview:self.totalClickLab];
}

- (BOOL)configureView:(id)dataModel{
    PPCPriceingListModel *model = (PPCPriceingListModel *)dataModel;
    
    
    [self.mainImgView setImageUrl:model.imgURL];
    self.titLab.text = model.title;
    self.commNameLab.text = model.commName;
    self.houseDetailLab.text = [NSString stringWithFormat:@"%@室%@厅 %.0f平 %.0f%@",model.roomNum,model.hallNum,[model.area floatValue],[model.price floatValue],model.priceUnit];
    NSString *clickStr;
    if (!model.fixClickNum || model.fixClickNum.length == 0) {
        clickStr = @"0";
    }
    self.totalClickLab.text = clickStr;
    
    CGSize size = [Util_UI sizeOfString:clickStr maxWidth:60 withFontSize:15];
    self.totalClickTitLab.frame = CGRectMake(ScreenWidth-15-50-8-size.width, 65, 60, 15);
    
    int i = 0;
    if (![model.isPhonePub isEqualToString:@"1"]) {
        i++;
        
        UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(ScreenWidth - 15 - 17*i - 3*(i-1), 15 , 17, 17)];
        imgView.backgroundColor = [UIColor lightGrayColor];
        [self addSubview:imgView];
    }else if (![model.isChoice isEqualToString:@"1"]){
        i++;
        
        UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(ScreenWidth - 15 + 17*(i-1), 15 , 17, 17)];
        imgView.backgroundColor = [UIColor lightGrayColor];
        [self addSubview:imgView];
    }else if (![model.isMoreImg isEqualToString:@"1"]){
        i++;
        
        UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(ScreenWidth - 15 + 17*(i-1), 15 , 17, 17)];
        imgView.backgroundColor = [UIColor lightGrayColor];
        [self addSubview:imgView];
    }
    self.titLab.frame = CGRectMake(80+15+11, 15, 200 - i*20, 20);
    
    return YES;
}


@end
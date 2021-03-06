//
//  CustomerTableViewCell.m
//  AnjukeBroker_New
//
//  Created by leozhu on 14-6-11.
//  Copyright (c) 2014年 Anjuke. All rights reserved.
//

#import "CustomerTableViewCell.h"
#import "UIImageView+WebCache.h"
#import "CustomerModel.h"
#import "UIViewExt.h"
#import "Util_UI.h"

#define GAP_H 6
#define GAP_V 3

@interface CustomerTableViewCell ()

@property (nonatomic, retain) UIImageView* userIcon;  //用户头像
@property (nonatomic, retain) UILabel* userName;   //用户名
@property (nonatomic, retain) UILabel* loginTime;  //用户上次登录时间
@property (nonatomic, retain) UILabel* location; //地点
@property (nonatomic, retain) UILabel* houseType; //户型
@property (nonatomic, retain) UILabel* price; //售价
@property (nonatomic, retain) UILabel* propertyCount; //浏览房源数
@property (nonatomic, retain) UILabel* userStatus; //当前改用户相对于经纪人的状态 (我抢了, 抢完了)

@end

@implementation CustomerTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self initCell];
    }
    return self;
}


#pragma mark -
#pragma mark UI相关

- (void)initCell {
    
    //用户头像
    _userIcon = [[UIImageView alloc] initWithFrame:CGRectZero];
    _userIcon.backgroundColor = [UIColor clearColor];
    _userIcon.layer.cornerRadius = 4.0f;
    _userIcon.layer.masksToBounds = YES;
    _userIcon.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:_userIcon];
    
    //用户名称
    _userName = [[UILabel alloc] initWithFrame:CGRectZero];
    _userName.backgroundColor = [UIColor clearColor];
    _userName.font = [UIFont ajkH2Font];
    [_userName setTextColor:[UIColor brokerBlackColor]];
    [self.contentView addSubview:_userName];
    
    //用户上次登录时间
    _loginTime = [[UILabel alloc] initWithFrame:CGRectZero];
    _loginTime.backgroundColor = [UIColor clearColor];
    _loginTime.font = [UIFont ajkH5Font];
    [_loginTime setTextColor:[UIColor brokerLightGrayColor]];
    [self.contentView addSubview:_loginTime];
    
    //地点
    _location = [[UILabel alloc] initWithFrame:CGRectZero];
    _location.backgroundColor = [UIColor clearColor];
    _location.font = [UIFont ajkH4Font];
    [_location setTextColor:[UIColor brokerLightGrayColor]];
    [self.contentView addSubview:_location];
    
    //户型
    _houseType = [[UILabel alloc] initWithFrame:CGRectZero];
    _houseType.backgroundColor = [UIColor clearColor];
    _houseType.font = [UIFont ajkH4Font];
    [_houseType setTextColor:[UIColor brokerLightGrayColor]];
    [self.contentView addSubview:_houseType];
    
    //租金或售价
    _price = [[UILabel alloc] initWithFrame:CGRectZero];
    _price.backgroundColor = [UIColor clearColor];
    _price.font = [UIFont ajkH4Font];
    [_price setTextColor:[UIColor brokerLightGrayColor]];
    [self.contentView addSubview:_price];
    
    //浏览房源数
    _propertyCount = [[UILabel alloc] initWithFrame:CGRectZero];
    _propertyCount.backgroundColor = [UIColor clearColor];
    _propertyCount.font = [UIFont ajkH4Font];
    [_propertyCount setTextColor:[UIColor brokerLightGrayColor]];
    [self.contentView addSubview:_propertyCount];
    
    //用户相对于经纪人的状态
    _userStatus = [[UILabel alloc] initWithFrame:CGRectZero];
    _userStatus.backgroundColor = [UIColor clearColor];
    _userStatus.font = [UIFont ajkH3Font];
    _userStatus.hidden = YES; //默认隐藏
    [self.contentView addSubview:_userStatus];
    
    //cell的背景视图, 默认选中是蓝色
//    UIView* backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 0)];
//    backgroundView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.5];
//    self.selectedBackgroundView = backgroundView;
    
    self.contentView.backgroundColor = [UIColor brokerWhiteColor];
    
}


//加载数据
- (void)layoutSubviews{
    [super layoutSubviews];
    
    //用户头像
    _userIcon.frame = CGRectMake(10, 12, 60, 60);
    NSString* iconPath = self.customerModel.user_photo;
    if (iconPath != nil && ![@"" isEqualToString:iconPath]) {
        //加载图片
        [_userIcon setImageWithURL:[NSURL URLWithString:iconPath] placeholderImage:[UIImage imageNamed:@"anjuke_icon_headpic"]];
    }else{
        _userIcon.image = [UIImage imageNamed:@"anjuke_icon_headpic"]; //默认图片
    }
    
    //用户名称
//    CGSize commNameSize = [self.customerModel.commName sizeWithFont:self.commName.font constrainedToSize:CGSizeMake(ScreenWidth-120, 20)];
    
    _userName.frame = CGRectMake(_userIcon.right + 10, 12, 170, 20);
    _userName.text = self.customerModel.user_name;
//    _userName.backgroundColor = [UIColor redColor];
    
    //用户上次登录时间
    _loginTime.frame = CGRectMake(ScreenWidth - 72, 12, 60, 20);
    _loginTime.textAlignment = NSTextAlignmentRight;
    _loginTime.text = self.customerModel.last_operate_time;
//    _loginTime.backgroundColor = [UIColor yellowColor];
    
    //地点
    if (self.customerModel.blcok_name && self.customerModel.blcok_name.length > 0) {
        _location.frame = CGRectMake(_userIcon.right + 10, _userName.bottom + GAP_V, 100, 20);
        _location.text = self.customerModel.blcok_name;
        [_location sizeToFit]; //大小自适应
        _location.hidden = NO;
    }else{
        _location.hidden = YES;
    }
//    _location.backgroundColor = [UIColor purpleColor];
    
    //户型
    if (self.customerModel.house_type_preference && self.customerModel.house_type_preference.length > 0) {
        if (self.customerModel.blcok_name && self.customerModel.blcok_name.length > 0) {
            _houseType.frame = CGRectMake(_location.right + GAP_H, _userName.bottom + GAP_V, 100, 20);
            _houseType.text = self.customerModel.house_type_preference;
            [_houseType sizeToFit];
            _houseType.hidden = NO;
        }else{
            _houseType.frame = CGRectMake(_userIcon.right + 10, _userName.bottom + GAP_V, 100, 20);
            _houseType.text = self.customerModel.house_type_preference;
            [_houseType sizeToFit];
            _houseType.hidden = NO;
        }
    }else{
        _houseType.hidden = YES;
    }
//    _houseType.backgroundColor = [UIColor grayColor];
    
    //租金或售价
    if (self.customerModel.price_preference && self.customerModel.price_preference.length > 0) {
        if (self.customerModel.house_type_preference && self.customerModel.house_type_preference.length > 0) {
            _price.frame = CGRectMake(_houseType.right + GAP_H, _userName.bottom + GAP_V, 100, 20);
            _price.text = self.customerModel.price_preference;
            [_price sizeToFit];
            _price.hidden = NO;
        }else if(self.customerModel.blcok_name && self.customerModel.blcok_name.length > 0){
            _price.frame = CGRectMake(_location.right + GAP_H, _userName.bottom + GAP_V, 100, 20);
            _price.text = self.customerModel.price_preference;
            [_price sizeToFit];
            _price.hidden = NO;
        }else{
            _price.frame = CGRectMake(_userIcon.right + 10, _userName.bottom + GAP_V, 100, 20);
            _price.text = self.customerModel.price_preference;
            [_price sizeToFit];
            _price.hidden = NO;
        }
    }else{
        _price.hidden = YES;
    }
//    _price.backgroundColor = [UIColor redColor];
    
    //浏览房源数
    _propertyCount.frame = CGRectMake(_userIcon.right + 10, 55, 100, 20);
    _propertyCount.text = [NSString stringWithFormat:@"浏览了%@套房源", self.customerModel.view_prop_num];
//    _propertyCount.backgroundColor = [UIColor yellowColor];
    
    //用户相对于经纪人的状态, 0, 1, 2
    _userStatus.frame = CGRectMake(ScreenWidth - 72, 55, 60, 20);
    _userStatus.textAlignment = NSTextAlignmentRight;
//    _userStatus.text = self.customerModel.status_msg;
    if ([@"0" isEqualToString:self.customerModel.status]) { //可以抢
        _userStatus.hidden = YES;
    }else if([@"1" isEqualToString:self.customerModel.status]){ //已抢到
        _userStatus.text = @"我抢了";
        [_userStatus setTextColor:[UIColor brokerBabyBlueColor]];
        _userStatus.hidden = NO;
    }else if([@"2" isEqualToString:self.customerModel.status]){ //抢完了
        _userStatus.text = @"抢完了";
        [_userStatus setTextColor:[Util_UI colorWithHexString:@"#CE100B"]];
        _userStatus.hidden = NO;
    }else if([@"3" isEqualToString:self.customerModel.status]){ //锁定状态
        _userStatus.text = @"我抢了";
        [_userStatus setTextColor:[UIColor brokerBabyBlueColor]];
        _userStatus.hidden = NO;
    }
    

    
}

@end

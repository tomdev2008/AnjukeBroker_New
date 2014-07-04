//
//  PricePromotionPropertySingleViewController.m
//  AnjukeBroker_New
//
//  Created by leozhu on 14-7-1.
//  Copyright (c) 2014年 Wu sicong. All rights reserved.
//

#import "PropertySingleViewController.h"
#import "AXChatWebViewController.h"
#import "PropertyEditViewController.h"

#import "PropertyDetailTableViewFooter.h"

#import "PropertyDetailTableViewCell.h"
#import "PricePromotioningCell.h"
#import "ChoicePromotionableCell.h"
#import "ChoicePromotioningCell.h"
#import "ChoicePromotionDisableCell.h"
#import "PricePromotionableCell.h"
#import "ChoicePromotionQueuingCell.h"

#import "PropertyDetailCellModel.h"
#import "PricePromotionCellModel.h"
#import "ChoicePromotionCellModel.h"
#import "ChoiceSummaryModel.h"
#import "BrokerBalanceModel.h"

@interface PropertySingleViewController ()

@property (nonatomic, strong) UITableView* tableView;
@property (nonatomic, assign) BOOL networkRequesting; //网络请求锁
@property (nonatomic, strong) PropertyDetailTableViewFooter* footer; //页脚
@property (nonatomic, strong) UIView* loadingView; //正在加载中的UIView;
@property (nonatomic, strong) UILabel* loadingTipLabel; //正在加载中的UILabel
@property (nonatomic, strong) UIActivityIndicatorView* activity; //风火轮

@property (nonatomic, strong) NSMutableArray* data; //数组用来存储5个请求回来的对象
@property (nonatomic, copy) NSString* balance; //经纪人可用余额(带单位)
@property (nonatomic, copy) NSString* minBudget; //最小预算(不带单位)
@property (nonatomic, copy) NSString* maxBudget; //最大预算(带单位)
@property (nonatomic, copy) NSString* budget; //经纪人输入的预算

//浮层相关
@property (nonatomic, strong) MBProgressHUD* hud;
@property (nonatomic, strong) UIImageView* hudBackground;
@property (nonatomic, strong) UIImageView* hudImageView;
@property (nonatomic, strong) UILabel* hudText;

//无网络UI
@property (nonatomic, strong) UIView* emptyBackgroundView;
@property (nonatomic, strong) UIImageView* emptyBackgroundImageView;
@property (nonatomic, strong) UILabel* emptyBackgroundLabel;

@end

@implementation PropertySingleViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setTitleViewWithString:@"房源单页"];
    
    //取出参数
//    @"brokerId":@"858573", @"propId":@"168783092"   for test
    if (_propId == nil) {
        _propId = @"168783092";
    }
    
    //表
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight - 20 - 44 - 49) style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.backgroundColor = [UIColor brokerBgPageColor];
    _tableView.contentInset = UIEdgeInsetsMake(0, 0, -30, 0);
    _tableView.hidden = YES;
    [self.view addSubview:_tableView];
    
    //页脚
    _footer = [[PropertyDetailTableViewFooter alloc] init]; //页尾
    _footer.hidden = YES;
    [self initFooterBlock];
    [self.view addSubview:_footer];
    
    //正在加载中的view
    _loadingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight - 20 - 44)];
    
    _loadingView.userInteractionEnabled = NO;
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(refresh:)];
    [_loadingView addGestureRecognizer:tap];
    
    _activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _activity.bounds = CGRectMake(0, 0, 200, 200);
    _activity.center = CGPointMake(ScreenWidth*0.5 - 60, (ScreenHeight-20-44)*0.5);
    [_activity startAnimating];
    [_loadingView addSubview:_activity];
    
    _loadingTipLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 20)];
    _loadingTipLabel.center = CGPointMake(ScreenWidth*0.5, (ScreenHeight-20-44)*0.5);
    _loadingTipLabel.font = [UIFont ajkH3Font];
    _loadingTipLabel.textColor = [UIColor brokerLightGrayColor];
    _loadingTipLabel.text = @"努力加载中...";
    _loadingTipLabel.textAlignment = NSTextAlignmentCenter;
    [_loadingView addSubview:_loadingTipLabel];
    
    [self.view addSubview:_loadingView];
    self.view.backgroundColor = [UIColor brokerBgPageColor];

}

#pragma mark -
#pragma mark view出现
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self requestPropFixChoice];
    
}

#pragma mark -
#pragma mark 页脚block定义
- (void)initFooterBlock{
    __weak PropertySingleViewController* this = self;
    _footer.editBlock = ^{
        PropertyEditViewController *controller = [[PropertyEditViewController alloc] init];
        controller.isHaozu = this.isHaozu;
        controller.propertyID = this.propId;
        controller.backType = RTSelectorBackTypePopBack;
        [this.navigationController pushViewController:controller animated:YES];
    };
    
    _footer.deleteBlock = ^{
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"确定删除当前房源" delegate:this cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        alert.tag = 2;
        [alert show]; //一定要放设置键盘之后
    };
    
}


#pragma mark -
#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    if (self.data.count > 2) {
        if (self.pageType == PAGE_TYPE_FIX) { //从定价过来
            return 3;
        }else if (self.pageType == PAGE_TYPE_CHOICE){ //从精选过来
            return 3;
        }else{ //从待推广过来, 默认从待推广过来
            return 2;
        }
    }else{
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.section == 0) { //房源
        static NSString* identifier = @"PropertyDetailTableViewCell";
        PropertyDetailTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        if (cell == nil) {
            cell = [[PropertyDetailTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        }
        if (self.data.count > 0) {
            cell.propertyDetailTableViewCellModel = self.data[0]; //第一个是房源数据模型
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            [cell showTopLine];
            [cell showBottonLineWithCellHeight:95];
            return cell;
        }else{
            return nil;
        }
        
    }else if (indexPath.section == 1){ //定价
        
        if (self.pageType == PAGE_TYPE_NO_PLAN) { //从待推广过来
            static NSString* identifier1 = @"PricePromotionableCell";
            PricePromotionableCell* cell = [tableView dequeueReusableCellWithIdentifier:identifier1];
            if (cell == nil) {
                cell = [[PricePromotionableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier1];
            }
            if (self.data.count > 1) {
                cell.pricePromotionCellModel = self.data[1]; //第二个是定价推广概况
                NSString* planId = cell.pricePromotionCellModel.planId;
                __weak PropertySingleViewController* this = self;
                cell.block = ^(NSString* string){
                    //开始定价推广
                    [this requestFixWithPlanId:planId];
                };
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                [cell showTopLine];
                [cell showBottonLineWithCellHeight:120];
                return cell;
            }else{
                return nil;
            }
            
        }else{
            static NSString* identifier2 = @"PricePromotioningCell";
            PricePromotioningCell* cell = [tableView dequeueReusableCellWithIdentifier:identifier2];
            if (cell == nil) {
                cell = [[PricePromotioningCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            }
            if (self.data.count > 1) {
                cell.pricePromotionCellModel = self.data[1]; //第二个是定价推广概况
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                [cell showTopLine];
                [cell showBottonLineWithCellHeight:90];
                return cell;
            }else{
                return nil;
            }
            
        }
      
    }else if(indexPath.section == 2){ //精选
        
        if (self.pageType == PAGE_TYPE_NO_PLAN) { //如果是从待推广过来, 不显示第三个cell
            return nil;
        }else{
            if (self.data.count > 2) {
                ChoicePromotionCellModel* propChoice = self.data[2]; //第三个是精选推广概况
                NSString* actionType = propChoice.status;
                __weak PropertySingleViewController* this = self;
                if ([@"1-1" isEqualToString:actionType]) { //推广中
                    ChoicePromotioningCell* cell = [[ChoicePromotioningCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
                    cell.choicePromotionModel = propChoice;
                    cell.block = ^(NSString* string){
                        //取消精选推广
                        [this requestChoiceStop];
                    };
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    [cell showTopLine];
                    [cell showBottonLineWithCellHeight:150];
                    return cell;
                    
                }else if ([@"1-2" isEqualToString:actionType]){ //排队中
                    
                    ChoicePromotionQueuingCell* cell = [[ChoicePromotionQueuingCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
                    cell.queuePosition = propChoice.statusMsg; //这里应该是个数字
                    cell.block = ^(NSString* string){
                        //取消排队
                        [this requestChoiceStop];
                    };
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    [cell showTopLine];
                    [cell showBottonLineWithCellHeight:150];
                    return cell;
                
                }else if ([@"2-1" isEqualToString:actionType]){ //推广位已满
                    
                    ChoicePromotionableCell* cell = [[ChoicePromotionableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
                    cell.choicePromotionModel = self.data[2];
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    [cell showTopLine];
                    [cell showBottonLineWithCellHeight:200];
                    return cell;
                    
                }else if ([@"2-2" isEqualToString:actionType]){ //可排队
                    
                    ChoicePromotionableCell* cell = [[ChoicePromotionableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
                    cell.choicePromotionModel = self.data[2];
                    
                    cell.block = ^(NSString* string){
                        //立即排队
                        NSString* text = [NSString stringWithFormat:@"可用余额为%@", this.balance];
                        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"设置预算" message:text delegate:this cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
                        alert.tag = 1;
                        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
                        NSString* budget = [NSString stringWithFormat:@"输入预算, %@~%@", this.minBudget, this.maxBudget];
                        [alert textFieldAtIndex:0].placeholder = budget;
                        [alert textFieldAtIndex:0].keyboardType = UIKeyboardTypeNumberPad;
                        [alert show]; //一定要放设置键盘之后
                        
                    };
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    [cell showTopLine];
                    [cell showBottonLineWithCellHeight:200];
                    return cell;
                
                    
                }else if ([@"2-3" isEqualToString:actionType]){ //可推广
                    
                    ChoicePromotionableCell* cell = [[ChoicePromotionableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
                    cell.choicePromotionModel = self.data[2];
                    cell.block = ^(NSString* string){
                        //立即推广
                        NSString* text = [NSString stringWithFormat:@"可用余额为%@", this.balance];
                        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"设置预算" message:text delegate:this cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
                        alert.tag = 1;
                        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
                        NSString* budget = [NSString stringWithFormat:@"输入预算, %@~%@", this.minBudget, this.maxBudget];
                        [alert textFieldAtIndex:0].placeholder = budget;
                        [alert textFieldAtIndex:0].keyboardType = UIKeyboardTypeNumberPad;
                        [alert show]; //一定要放设置键盘之后
                        
                    };
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    [cell showTopLine];
                    [cell showBottonLineWithCellHeight:200];
                    return cell;
                
                }else if ([@"3-2" isEqualToString:actionType]){ //不符合精选推广条件
                    
                    ChoicePromotionDisableCell* cell = [[ChoicePromotionDisableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
                    cell.choiceConditionText = propChoice.statusMsg; //
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    [cell showTopLine];
                    [cell showBottonLineWithCellHeight:125];
                    return cell;
                    
                }else{
                    
                    NSLog(@"返回状态异常 ------ %@", actionType);
                    return nil;
                }
                
                
            }else{
                return nil;
            }
            
        }
        
    }else{
        return nil;
    }
    
}



#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSLog(@"行%d 组%d", indexPath.row, indexPath.section);
    [tableView deselectRowAtIndexPath:indexPath animated:YES]; //取消高亮
    
    if (indexPath.section == 0) {
        
        if (self.data.count > 0) {
            //push 到 webview
            AXChatWebViewController *webViewController = [[AXChatWebViewController alloc] init];
            PropertyDetailCellModel* property = self.data[0];
            webViewController.webUrl = property.url;
            webViewController.webTitle = property.title;
            [self.navigationController pushViewController:webViewController animated:YES];
        }
        
    }
    
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{

    if (indexPath.section == 0) { //房源详情
        return 95;
    }else{
        
        if (self.pageType == PAGE_TYPE_NO_PLAN) { //从待推广过来
            if (indexPath.section == 1) {
                return 120;
            }else{
                return 0;
            }
        }else{
            
            if (indexPath.section == 1) {
                return 90;
            }else{
                
                if (self.data.count > 2) {
                    ChoicePromotionCellModel* propChoice = self.data[2]; //第三个是精选推广概况
                    NSString* actionType = propChoice.status;
                    
                    //1-1 推广中 1-2排队中 2-1推广位已满 2-2可立即排队 2-3可立即推广 3-2不符合精选推广条件
                    
                    if ([@"1-1" isEqualToString:actionType]) {   //推广中
                        return 150;
                    }else if ([@"1-2" isEqualToString:actionType]){  //排队中
                        return 150;
                    }else if ([@"2-1" isEqualToString:actionType]){  //坑位已满
                        return 200;
                    }else if ([@"2-2" isEqualToString:actionType]){  //可排队
                        return 200;
                    }else if ([@"2-3" isEqualToString:actionType]){  //可推广
                        return 200;
                    }else if ([@"3-2" isEqualToString:actionType]){  //不符合推广条件
                        return 125;
                    }else{
                        
                        NSLog(@"返回状态异常 ------ %@", actionType);
                        return 0;
                    }
                }else{
                    return 0;
                }
            }
            
        }
        
    }
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 15;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    if (section == 2) {
        return 30;
    }else{
        return 0;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 15)];
    label.backgroundColor = [UIColor brokerBgPageColor];
    return label;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    if (section == 2) {
        
        if (self.data.count > 0) {
            UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 30)];
            view.backgroundColor = [UIColor clearColor];
            
            UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth-15, 30)];
            label.backgroundColor = [UIColor brokerBgPageColor];
            label.textAlignment = NSTextAlignmentRight;
            label.font = [UIFont ajkH5Font];
            label.textColor = [UIColor brokerLightGrayColor];
            PropertyDetailCellModel* property = self.data[0];
            label.text = property.publishDaysMsg;
            [view addSubview:label];
            return view;
        }else{
            return nil;
        }
    }else{
        return nil;
    }
}


#pragma mark -
#pragma mark 解决section不跟随tableView移动的问题
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat sectionHeaderHeight = 15;
    if (scrollView.contentOffset.y <= sectionHeaderHeight && scrollView.contentOffset.y >= 0) {
        scrollView.contentInset = UIEdgeInsetsMake(-scrollView.contentOffset.y, 0, -30, 0);
    } else if (scrollView.contentOffset.y >= sectionHeaderHeight) {
        scrollView.contentInset = UIEdgeInsetsMake(-sectionHeaderHeight, 0, -30, 0);
    }
    

}


#pragma mark 请求房源详情 + 定价推广 + 精选推广  - 可推广, 推广中, 可排队(坑会超过一半), 排队中, 推广位已满, 不符合推广条件
- (void)requestPropFixChoice{
    if (self.networkRequesting) {
        return;
    }
    
    self.networkRequesting = YES;
    
    NSString* prefix = @"anjuke";
    if (self.isHaozu) { //如果是租房 (默认是二手房)
        prefix = @"zufang";
    }
    
//    NSDictionary* param1 = @{@"token":[LoginManager getToken], @"brokerId":[LoginManager getUserID], @"propId":self.propId};
    NSDictionary* param1 = @{@"token":[LoginManager getToken], @"brokerId":@"858573", @"propId":_propId};
    NSDictionary* dic1 = @{@"method":@"GET", @"relative_url":[prefix stringByAppendingString:@"/prop/summary/"], @"query_params":param1}; //房源概况

    NSDictionary* param2 = @{@"token":[LoginManager getToken], @"cityId":[LoginManager getCity_id], @"propId":_propId}; //11表示上海
    NSDictionary* dic2 = @{@"method":@"GET", @"relative_url":[prefix stringByAppendingString:@"/prop/fix/summary/"], @"query_params":param2}; //房源定价概况
    
    NSDictionary* param3 = @{@"token":[LoginManager getToken], @"brokerId":@"858573", @"propId":_propId};
    NSDictionary* dic3 = @{@"method":@"GET", @"relative_url":[prefix stringByAppendingString:@"/prop/choice/summary/"], @"query_params":param3}; //房源精选概况
    
    NSDictionary* param4 = @{@"token":[LoginManager getToken], @"brokerId":@"858573", @"propId":_propId};
    NSDictionary* dic4 = @{@"method":@"GET", @"relative_url":[prefix stringByAppendingString:@"/choice/summary/"], @"query_params":param4}; //最大最小预算余额
    
    NSDictionary* param5 = @{@"token":[LoginManager getToken], @"brokerId":@"858573"};
    NSDictionary* dic5 = @{@"method":@"GET", @"relative_url":@"broker/account/balance/", @"query_params":param5}; //经纪人可用余额
    
    NSDictionary* param = @{@"requests":@{@"prop_summary":dic1,
                                          @"prop_fix_summary":dic2,
                                          @"prop_choice_summary":dic3,
                                          @"choice_summary":dic4,
                                          @"broker_balance":dic5
                                        }};
    
    [[RTRequestProxy sharedInstance] asyncRESTPostWithServiceID:RTBrokerRESTServiceID methodName:@"batch/" params:param target:self action:@selector(onRequestPropFixChoiceFinished:)];
    
}

- (void)onRequestPropFixChoiceFinished:(RTNetworkResponse *)response{
    //解除请求锁
    self.networkRequesting = NO;
    
    RTNetworkResponseStatus status = response.status;
    
    //如果请求数据成功
    if (status == RTNetworkResponseStatusSuccess) {
        
        if ([@"ok" isEqualToString:response.content[@"status"]]) { //匹请求成功
            
            NSDictionary* propSum = [response.content[@"data"][@"responses"][@"prop_summary"][@"body"] JSONValue];
            NSDictionary* propFixSum = [response.content[@"data"][@"responses"][@"prop_fix_summary"][@"body"] JSONValue];
            NSDictionary* propChoiceSum = [response.content[@"data"][@"responses"][@"prop_choice_summary"][@"body"] JSONValue];
            NSDictionary* choiceSum = [response.content[@"data"][@"responses"][@"choice_summary"][@"body"] JSONValue];
            NSDictionary* brokerBalance = [response.content[@"data"][@"responses"][@"broker_balance"][@"body"] JSONValue];
            
            self.data = [NSMutableArray arrayWithCapacity:5]; //清空
            
            if (propSum != nil && propFixSum != nil && propChoiceSum != nil) { //前三个不为空
                if ([@"ok" isEqualToString:[propSum objectForKey:@"status"]] &&
                    [@"ok" isEqualToString:[propFixSum objectForKey:@"status"]] &&
                    [@"ok" isEqualToString:[propChoiceSum objectForKey:@"status"]] &&
                    [@"ok" isEqualToString:[choiceSum objectForKey:@"status"]] &&
                    [@"ok" isEqualToString:[brokerBalance objectForKey:@"status"]]) {
                    PropertyDetailCellModel* property = [[PropertyDetailCellModel alloc] initWithDataDic:[propSum objectForKey:@"data"]]; //房源概况
                    [self.data addObject:property];
                    
                    PricePromotionCellModel* fix = [[PricePromotionCellModel alloc] initWithDataDic:[propFixSum objectForKey:@"data"]]; //房源定价概况
                    [self.data addObject:fix];
                    
                    ChoicePromotionCellModel* propChoice = [[ChoicePromotionCellModel alloc] initWithDataDic:[propChoiceSum objectForKey:@"data"]]; //房源精选概况
                    //######################################### for test
                    propChoice.maxBucketNum = @"20";
                    propChoice.usedBucketNum = @"15";
                    propChoice.status = @"2-2"; //1-1 推广中 1-2排队中 2-1推广位已满 2-2可立即排队 2-3可立即推广 3-2不符合精选推广条件
                    //#########################################
                    [self.data addObject:propChoice];
                    
                    ChoiceSummaryModel* choice = [[ChoiceSummaryModel alloc] initWithDataDic:[choiceSum objectForKey:@"data"]];
                    self.minBudget = choice.minChoicePrice;
                    self.maxBudget = [choice.maxChoicePrice stringByAppendingString:choice.maxChoicePriceUnit];
                    [self.data addObject:choice];
                    
                    BrokerBalanceModel* balance = [[BrokerBalanceModel alloc] initWithDataDic:[brokerBalance objectForKey:@"data"]];
                    self.balance = [balance.balance stringByAppendingString:balance.balanceUnit];
                    [self.data addObject:balance];
                    
                    _tableView.hidden = NO;
                    _footer.hidden = NO;
                    _loadingView.hidden = YES;
                    [_tableView reloadData];
                    
                }else{ //五个中任意一个失败, 页面等待, 重新请求, 请求超时
                    [_activity stopAnimating];
                    _loadingTipLabel.text = @"加载超时, 点击重新加载";
                    _loadingView.userInteractionEnabled = YES;
                    
                }
            }
            
        }else{  //匹请求失败
            [self displayHUDWithStatus:@"error" Message:@"请求超时" ErrCode:@"1"];
        }
        
        
    }else{ //网络不畅
        _loadingView.hidden = YES;
        _tableView.hidden = NO;
        [self showTipViewWithImageViewFrame:CGRectMake(ScreenWidth/2-100/2, ScreenHeight/2-20-44-70/2, 200/2, 140/2) ImageName:@"check_no_wifi" LabelText:@"无网络连接"];
    }
    
    
}


#pragma mark 定价推广请求
- (void)requestFixWithPlanId:(NSString*)planId{
    if (self.networkRequesting) {
        return;
    }
    
    self.networkRequesting = YES;
    
    NSString* prefix = @"anjuke";
    if (self.isHaozu) { //如果是租房 (默认是二手房)
        prefix = @"zufang";
    }
//    NSDictionary* param1 = @{@"token":[LoginManager getToken], @"brokerId":[LoginManager getUserID], @"planId":planId};
    NSDictionary* param1 = @{@"token":[LoginManager getToken], @"brokerId":@"858573", @"planId":planId};
    NSDictionary* dic1 = @{@"method":@"GET", @"relative_url":[prefix stringByAppendingString:@"/fix/spreadstart/"], @"query_params":param1}; //房源概况
    NSDictionary* param = @{@"requests":@{@"result":dic1}};
    [[RTRequestProxy sharedInstance] asyncRESTPostWithServiceID:RTBrokerRESTServiceID methodName:@"batch/" params:param target:self action:@selector(onRequestFixFinished:)];
    
}

- (void)onRequestFixFinished:(RTNetworkResponse *)response{
    //解除请求锁
    self.networkRequesting = NO;
    
    RTNetworkResponseStatus status = response.status;
    
    //如果请求数据成功
    if (status == RTNetworkResponseStatusSuccess) {
        
        if ([@"ok" isEqualToString:response.content[@"status"]]) { //匹请求成功
            
            NSDictionary* result = [response.content[@"data"][@"responses"][@"result"][@"body"] JSONValue];
            if ([@"ok" isEqualToString:[result objectForKey:@"status"]]) { //定价推广成功
                [self displayHUDWithStatus:@"ok" Message:@"定价推广成功" ErrCode:nil];
                
                //最简单的做法就是重新加载, 虽然效率不高
                [self requestPropFixChoice];
                
            }else{ //定价推广失败
                NSString* message = [result objectForKey:@"message"];
                [self displayHUDWithStatus:@"error" Message:message ErrCode:@"1"];
            }

        }else{  //匹请求失败
            [self displayHUDWithStatus:@"error" Message:@"请求超时" ErrCode:@"1"];
        }
        
    }else{ //数据请求失败
        [self displayHUDWithStatus:@"error" Message:nil ErrCode:nil];
    }
    
    
}


#pragma mark 精选推广/排队 开始请求
- (void)requestChoiceWithBudget:(NSString*)budget{
    if (self.networkRequesting) {
        return;
    }
    
    self.networkRequesting = YES;
    
    NSString* prefix = @"anjuke";
    if (self.isHaozu) { //如果是租房 (默认是二手房)
        prefix = @"zufang";
    }
//    NSDictionary* param1 = @{@"token":[LoginManager getToken], @"brokerId":[LoginManager getUserID], @"propId":self.propId, @"budget":budget};
    NSDictionary* param1 = @{@"token":[LoginManager getToken], @"brokerId":@"858573", @"propId":@"168783092", @"budget":budget};
    NSDictionary* dic1 = @{@"method":@"GET", @"relative_url":[prefix stringByAppendingString:@"/prop/choice/start/"], @"query_params":param1}; //房源概况
    NSDictionary* param = @{@"requests":@{@"result":dic1}};
    [[RTRequestProxy sharedInstance] asyncRESTPostWithServiceID:RTBrokerRESTServiceID methodName:@"batch/" params:param target:self action:@selector(onRequestChoiceFinished:)];
    
}

- (void)onRequestChoiceFinished:(RTNetworkResponse *)response{
    //解除请求锁
    self.networkRequesting = NO;
    
    RTNetworkResponseStatus status = response.status;
    
    //如果请求数据成功
    if (status == RTNetworkResponseStatusSuccess) {
        
        if ([@"ok" isEqualToString:response.content[@"status"]]) { //匹请求成功
            
            NSDictionary* result = [response.content[@"data"][@"responses"][@"result"][@"body"] JSONValue];
            if ([@"ok" isEqualToString:[result objectForKey:@"status"]]) { //精选推广成功
                NSString* message = [[result objectForKey:@"data"] objectForKey:@"statusMsg"];
                [self displayHUDWithStatus:@"ok" Message:message ErrCode:nil];
                
                //最简单的做法就是重新加载, 虽然效率不高
                [self requestPropFixChoice];
                
            }else{ //精选推广失败
                NSString* message = [result objectForKey:@"message"];
                [self displayHUDWithStatus:@"error" Message:message ErrCode:@"1"];
            }
            
        }else{  //匹请求失败
            [self displayHUDWithStatus:@"error" Message:@"请求超时" ErrCode:@"1"];
        }
        
    }else{ //数据请求失败
        [self displayHUDWithStatus:@"error" Message:nil ErrCode:nil];
    }
    

}


#pragma mark 精选推广/排队 停止请求
- (void)requestChoiceStop{
    if (self.networkRequesting) {
        return;
    }
    
    self.networkRequesting = YES;
    
    NSString* prefix = @"anjuke";
    if (self.isHaozu) { //如果是租房 (默认是二手房)
        prefix = @"zufang";
    }
//    NSDictionary* param1 = @{@"token":[LoginManager getToken], @"brokerId":[LoginManager getUserID], @"propId":self.propId};
    NSDictionary* param1 = @{@"token":[LoginManager getToken], @"brokerId":@"858573", @"propId":@"168783092"};
    NSDictionary* dic1 = @{@"method":@"GET", @"relative_url":[prefix stringByAppendingString:@"/prop/choice/stop/"], @"query_params":param1}; //房源概况
    NSDictionary* param = @{@"requests":@{@"result":dic1}};
    [[RTRequestProxy sharedInstance] asyncRESTPostWithServiceID:RTBrokerRESTServiceID methodName:@"batch/" params:param target:self action:@selector(onRequestChoiceStopFinished:)];
    
}

- (void)onRequestChoiceStopFinished:(RTNetworkResponse *)response{
    //解除请求锁
    self.networkRequesting = NO;
    
    RTNetworkResponseStatus status = response.status;
    
    //如果请求数据成功
    if (status == RTNetworkResponseStatusSuccess) {
        
        if ([@"ok" isEqualToString:response.content[@"status"]]) { //匹请求成功
            
            NSDictionary* result = [response.content[@"data"][@"responses"][@"result"][@"body"] JSONValue];
            if ([@"ok" isEqualToString:[result objectForKey:@"status"]]) { //精选推广停止成功
                NSString* message = [[result objectForKey:@"data"] objectForKey:@"msg"];
                [self displayHUDWithStatus:@"ok" Message:message ErrCode:nil];
                
                //最简单的做法就是重新加载, 虽然效率不高
                [self requestPropFixChoice];
                
            }else{ //精选推广停止失败
                NSString* message = [result objectForKey:@"message"];
                [self displayHUDWithStatus:@"error" Message:message ErrCode:@"1"];
            }
            
        }else{  //匹请求失败
            [self displayHUDWithStatus:@"error" Message:@"请求超时" ErrCode:@"1"];
        }
        
    }else{ //数据请求失败
        [self displayHUDWithStatus:@"error" Message:nil ErrCode:nil];
    }
    
    
}


#pragma mark 删除房源API
- (void)requestPropertyDelete{
    if (self.networkRequesting) {
        return;
    }
    
    self.networkRequesting = YES;
    
    NSString* prefix = @"anjuke";
    if (self.isHaozu) { //如果是租房 (默认是二手房)
        prefix = @"zufang";
    }

//    NSDictionary* params = @{@"token":[LoginManager getToken], @"cityId":[LoginManager getCity_id], @"brokerId":[LoginManager getUserID], @"propIds":self.propId};
    NSDictionary* params = @{@"token":[LoginManager getToken], @"cityId":[LoginManager getCity_id], @"brokerId":@"858573", @"propIds":@"168783092"};
    NSString* method = [prefix stringByAppendingString:@"/prop/delprops/"];
    
    [[RTRequestProxy sharedInstance] asyncRESTPostWithServiceID:RTBrokerRESTServiceID methodName:method params:params target:self action:@selector(onRequestPropertyDeleteFinished:)];
}

- (void)onRequestPropertyDeleteFinished:(RTNetworkResponse *)response {
    //解除请求锁
    self.networkRequesting = NO;
    RTNetworkResponseStatus status = response.status;
    if (status == RTNetworkResponseStatusSuccess) {
        NSString* result = [response.content objectForKey:@"status"];
        if ([@"ok" isEqualToString:result]) {
            [self displayHUDWithStatus:@"ok" Message:@"删除房源成功" ErrCode:nil];
//            //这里要跳转到对应列表
            double delayInSeconds = 1.f;
            dispatch_time_t delayInNanoSeconds = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(delayInNanoSeconds, dispatch_get_main_queue(), ^(void)
            {
                [self.navigationController popViewControllerAnimated:YES];
            });
            
            
        }else{
            [self displayHUDWithStatus:@"error" Message:@"删除房源失败" ErrCode:@"1"];
        }
        
    }else{ //数据请求失败
        [self displayHUDWithStatus:@"error" Message:nil ErrCode:nil];
    }
    
    
}


#pragma mark -
#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (alertView.tag == 1) {
        NSLog(@"%@", [alertView textFieldAtIndex:0].text);
        
        if (buttonIndex == 1) { //确定按钮
            [self requestChoiceWithBudget:[alertView textFieldAtIndex:0].text];
        }else{
            
        }
    }else if (alertView.tag == 2){
        //删除当前房源
        [self requestPropertyDelete];
        
    }
    
    
    
}


#pragma mark -
#pragma mark 手势重新加载
- (void)refresh:(UITapGestureRecognizer*)gesture{
    NSLog(@"tap");
    _loadingView.userInteractionEnabled = NO;
    _loadingTipLabel.text = @"努力加载中...";
    [_activity startAnimating];
    [self requestPropFixChoice];
}


#pragma mark -
#pragma mark MBProgressHUD 相关
//使用 MBProgressHUD 显示房源推广状态
- (void)displayHUDWithStatus:(NSString *)status Message:(NSString*)message ErrCode:(NSString*)errCode {
    if (self.hudBackground == nil) {
        self.hudBackground = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 135, 135)];
        self.hudBackground.image = [UIImage imageNamed:@"anjuke_icon_tips_bg"];
        
        self.hudImageView = [[UIImageView alloc] initWithFrame:CGRectMake(135/2-70/2, 135/2-70/2 - 20, 70, 70)];
        self.hudText = [[UILabel alloc] initWithFrame:CGRectMake(10, self.hudImageView.bottom - 5, 115, 60)];
        [self.hudText setTextColor:[UIColor colorWithWhite:0.95 alpha:1]];
        [self.hudText setFont:[UIFont systemFontOfSize:13.0f]];
        self.hudText.numberOfLines = 0;
        [self.hudText setTextAlignment:NSTextAlignmentCenter];
        self.hudText.backgroundColor = [UIColor clearColor];
        
        [self.hudBackground addSubview:self.hudImageView];
        [self.hudBackground addSubview:self.hudText];
        
    }
    
    //使用 MBProgressHUD
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.color = [UIColor clearColor];
    self.hud.customView = self.hudBackground;
    self.hud.yOffset = -20;
    self.hud.mode = MBProgressHUDModeCustomView;
    self.hud.dimBackground = NO;
    
    if ([@"ok" isEqualToString:status]) { //成功的状态提示
        self.hudImageView.image = [UIImage imageNamed:@"check_status_ok"];
        self.hudText.text = message;
    }else{ //失败的状态提示
        if ([@"1" isEqualToString:errCode]) {
            self.hudImageView.image = [UIImage imageNamed:@"anjuke_icon_tips_sad"];
            self.hudText.text = message;
            
        }else{
            self.hudImageView.image = [UIImage imageNamed:@"check_no_wifi"];
            self.hudImageView.contentMode = UIViewContentModeScaleAspectFit;
            self.hudText.text = @"无网络连接";
            self.hudText.hidden = NO;
            
        }
    }
    
    
    [self.hud hide:YES afterDelay:2]; //显示一段时间后隐藏
}


#pragma mark -
#pragma mark UI相关
- (void) showTipViewWithImageViewFrame:(CGRect)imageViewFrame ImageName:(NSString*)imageName LabelText:(NSString*)labelText{
    if (self.emptyBackgroundView == nil) {
        _emptyBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight-20-44)];
        _emptyBackgroundView.backgroundColor = [UIColor clearColor];
        _emptyBackgroundImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        [self.emptyBackgroundView addSubview:_emptyBackgroundImageView];
        
        _emptyBackgroundLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _emptyBackgroundLabel.backgroundColor = [UIColor clearColor];
        _emptyBackgroundLabel.textAlignment = NSTextAlignmentCenter;
        [_emptyBackgroundLabel setFont:[UIFont ajkH3Font]];
        [_emptyBackgroundLabel setTextColor:[UIColor brokerLightGrayColor]];
        [self.emptyBackgroundView addSubview:_emptyBackgroundLabel];
        
        UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(refresh:)];
        [self.emptyBackgroundView addGestureRecognizer:tap];
        
    }
    
    _emptyBackgroundImageView.frame = imageViewFrame;
    _emptyBackgroundImageView.image = [UIImage imageNamed:imageName];
    
    _emptyBackgroundLabel.frame = CGRectMake(ScreenWidth/2-90/2, _emptyBackgroundImageView.bottom, 90, 30);
    _emptyBackgroundLabel.text = labelText;
    
    if (self.data.count == 0) {
        self.tableView.tableHeaderView = self.emptyBackgroundView;
        self.tableView.tableHeaderView.hidden = NO;
    }else{
        self.tableView.tableHeaderView.hidden = YES;
    }
    [self.tableView reloadData];
    
}

@end

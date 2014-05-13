//
//  AJK_HomeViewController.m
//  AnjukeBroker_New
//
//  Created by Wu sicong on 13-10-21.
//  Copyright (c) 2013年 Wu sicong. All rights reserved.
//

#import "HomeViewController.h"
#import "AnjukeEditPropertyViewController.h"
#import "SystemMessageViewController.h"
#import "Util_UI.h"
#import "BrokerLineView.h"
#import "WebImageView.h"
#import "LoginManager.h"
#import "AppManager.h"
#import "AXPhotoManager.h"
#import "RTGestureBackNavigationController.h"

#import "PublishBuildingViewController.h"
#import "CommunityListViewController.h"
#import "MoreViewController.h"
#import "FindHomeViewController.h"
#import "BrokerAccountController.h"
#import "BrokerTwoDimensionalCodeViewController.h"
#import <AFNetworking/UIImageView+AFNetworking.h>

#import "AXChatMessageCenter.h"
#import "AppDelegate.h"
#import "BrokerWebViewController.h"
#import "LocationManager.h"
#import "RTNetworkResponse.h"
#import "AXIMGDownloader.h"
#import "IMGDowloaderManager.h"
#import "CheckoutCommunityViewController.h"

#import "SaleBidDetailController.h"
#import "SaleFixedDetailController.h"
#import "SaleNoPlanGroupController.h"
#import "SelectionToolView.h"

#define HOME_cellHeight 50
#define Max_Account_Lb_Width 80

#define HEADER_VIEW1_Height 250
#define HEADER_VIEW2_Height 125
#define HEADER_VIEW_WHOLE_HEIGHT HEADER_VIEW1_Height+HEADER_VIEW2_Height

@interface HomeViewController ()
@property (nonatomic, strong) NSArray *taskArray;
@property (nonatomic, strong) UITableView *tvList;
@property (nonatomic, strong) WebImageView *photoImg;
@property (nonatomic, strong) AXIMGDownloader *imgDownloader;
@property (nonatomic, strong) NSMutableDictionary *dataDic;
@property (nonatomic, strong) NSMutableDictionary *ppcDataDic;
@property BOOL isAJK;
@property (nonatomic, strong) NSString *isSeedPid;
@property (nonatomic, strong) NSMutableArray *myArray;

@property (nonatomic, strong) UILabel *tapName;
@property (nonatomic, strong) UILabel *tapValue;
@property (nonatomic, strong) UILabel *costName;
@property (nonatomic, strong) UILabel *costValue;

@property BOOL configChecked;
@property (nonatomic, copy) NSString *loadingURL;
@property (nonatomic, strong) UIButton *topAlertButton;
@property (nonatomic, strong) SelectionToolView *selectionView;
@end

@implementation HomeViewController

#pragma mark - log
- (void)sendAppearLog {
    [[BrokerLogger sharedInstance] logWithActionCode:AJK_HOME_001 note:[NSDictionary dictionaryWithObjectsAndKeys:[Util_TEXT logTime], @"ot", nil]];
}

- (void)sendDisAppearLog {
    [[BrokerLogger sharedInstance] logWithActionCode:AJK_HOME_002 note:[NSDictionary dictionaryWithObjectsAndKeys:[Util_TEXT logTime], @"dt", nil]];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (AXIMGDownloader *)imgDownloader {
    if (_imgDownloader == nil) {
        _imgDownloader = [[AXIMGDownloader alloc] init];
    }
    return _imgDownloader;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initRightBarButton];
    [self initView];
    [self initTitleView];
    [self initSelectionView];
}

- (void)initTitleView {
    UISegmentedControl *segment = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"二手房",@"租房", nil]];
    segment.frame = CGRectMake(0, 0, 200, 30);
    segment.segmentedControlStyle = UISegmentedControlStylePlain;
    segment.selectedSegmentIndex = 0;
    segment.backgroundColor = [UIColor grayColor];
    segment.tintColor = [UIColor blackColor];
    [segment addTarget:self action:@selector(pickOne:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = segment;
}
- (void)initSelectionView {
    SelectionToolView *selectionView = [[SelectionToolView alloc] initWithFrame:CGRectMake(200, 5, 100, 80)];
    selectionView.delegate = self;
    [self.view addSubview:selectionView];
    self.selectionView = selectionView;
    self.selectionView.hidden = YES;
}
- (void)initView {
    [self setTitle:@"房源"];
    
    UITableView *tv = [[UITableView alloc] initWithFrame:FRAME_WITH_TAB style:UITableViewStylePlain];
    self.tvList = tv;
    tv.backgroundColor = [UIColor lightGrayColor];
    tv.delegate = self;
    tv.dataSource = self;
    tv.separatorStyle = UITableViewCellSeparatorStyleNone;
    tv.showsHorizontalScrollIndicator = NO;
    tv.showsVerticalScrollIndicator = NO;
    [self.view addSubview:tv];
    
    UIView *hView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [self windowWidth], 110)];
    hView.backgroundColor = [UIColor whiteColor];
    tv.tableHeaderView = hView;

    self.tapName = [[UILabel alloc] init];
    self.tapName.text = @"今日点击";
    self.tapName.textAlignment = NSTextAlignmentCenter;
    self.tapValue = [[UILabel alloc] init];
    self.tapValue.textAlignment = NSTextAlignmentCenter;
    self.tapValue.text = @"2";
    self.costName = [[UILabel alloc] init];
    self.costName.textAlignment = NSTextAlignmentCenter;
    self.costName.text = @"今日花费";
    self.costValue = [[UILabel alloc] init];
    self.costValue.textAlignment = NSTextAlignmentCenter;
    self.costValue.text = @"1.0";
    
    [hView addSubview:self.tapName];
    [hView addSubview:self.tapValue];
    [hView addSubview:self.costName];
    [hView addSubview:self.costValue];
    
    if ([self.view respondsToSelector:@selector(addConstraint:)]) {
        self.tapName.translatesAutoresizingMaskIntoConstraints  = NO;
        self.tapValue.translatesAutoresizingMaskIntoConstraints = NO;
        self.costName.translatesAutoresizingMaskIntoConstraints = NO;
        self.costValue.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSDictionary *dictionary = NSDictionaryOfVariableBindings(_tapName, _tapValue, _costName, _costValue);
        float widthIndex = [self windowWidth]/320.0f;
        NSDictionary *metrics = @{@"leftSpace":@(60.0*widthIndex), @"centerSpace":@(40.0f*widthIndex), @"topSpace":@(30.0f*widthIndex), @"valueAndNameSpace": @(10.0f*widthIndex)};
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-leftSpace-[_tapName(80)]-centerSpace-[_costName(80)]" options:0 metrics:metrics views:dictionary]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-leftSpace-[_tapValue(80)]-centerSpace-[_costValue(80)]" options:0 metrics:metrics views:dictionary]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-topSpace-[_tapValue(30)]-valueAndNameSpace-[_tapName(30)]" options:0 metrics:metrics views:dictionary]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-topSpace-[_costValue(30)]-valueAndNameSpace-[_costName(30)]" options:0 metrics:metrics views:dictionary]];
    }else {
        self.tapValue.frame = CGRectMake(60.0f, 30.0f, 80.0f, 30.0f);
        self.tapName.frame = CGRectMake(60.0f, 70.0f, 80.0f, 30.0f);
        self.costValue.frame = CGRectMake(180.0f, 30.0f, 80.0f, 30.0f);
        self.costName.frame = CGRectMake(180.0f, 70.0f, 80.0f, 30.0f);
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
    [self doRequest];
    [self doRequestPPC];
    if (!self.configChecked) {
        [self requestForConfigure];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
}
#pragma mark - private method
- (void)initRightBarButton {
    UIBarButtonItem *rightItem = [UIBarButtonItem getBarButtonItemWithImage:[UIImage imageNamed:@"anjuke_icon_setting.png"] highLihtedImg:[UIImage imageNamed:@"anjuke_icon_setting_press.png"] taget:self action:@selector(rightButtonAction:)];
    if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {//fix ios7以下 10像素偏离
        UIBarButtonItem *spacer = [UIBarButtonItem getBarSpace:10.0];
        [self.navigationItem setRightBarButtonItems:@[spacer, rightItem]];
    }else{
        self.navigationItem.rightBarButtonItem = rightItem;
    }
}

- (void)initModel {
    self.isAJK = YES;
    self.taskArray = [NSArray arrayWithObjects:@"定价房源", @"竞价房源", @"待推广房源", nil];
    
    self.dataDic = [NSMutableDictionary dictionary];
    self.ppcDataDic = [NSMutableDictionary dictionary];
    self.myArray = [NSMutableArray array];
}

- (void)setHomeValue {
    //账户自适应
}

- (void)rightButtonAction:(id)sender {
    if (self.selectionView.isHidden) {
        [self showSelectionView];
    }else {
        [self hideSelectionView];
    }
}

- (void)showSelectionView {
    self.selectionView.hidden = NO;
}

- (void)hideSelectionView {
    self.selectionView.hidden = YES;
}

- (void)pickOne:(id)sender {
    UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
    switch (segmentedControl.selectedSegmentIndex) {
        case 0:
        {
        
        }
            break;
        case 1:
        {
            
        }
            break;
        default:
            break;
    }
}
#pragma mark - Request Method

- (void)doRequest {
    if (![self isNetworkOkay]) {
        [self hideLoadWithAnimated:YES];
        self.isLoading = NO;
        return;
    }
    
    [[RTRequestProxy sharedInstance] cancelRequestsWithTarget:self];
    
    [self showLoadingActivity:YES];
    self.isLoading = YES;
    
    NSMutableDictionary *params = nil;
    NSString *method = nil;
    
    params = [NSMutableDictionary dictionaryWithObjectsAndKeys:[LoginManager getToken], @"token", [LoginManager getUserID], @"brokerId",[LoginManager getCity_id], @"cityId", @"1", @"chatFlag", nil];
    method = @"broker/getinfoandppc/";
    
    [[RTRequestProxy sharedInstance] asyncRESTPostWithServiceID:RTBrokerRESTServiceID methodName:method params:params target:self action:@selector(onRequestFinished:)];
}

- (void)onRequestFinished:(RTNetworkResponse *)response {
    DLog(@"。。。response [%@]", [response content]);
    
    if ([response status] == RTNetworkResponseStatusFailed || [[[response content] objectForKey:@"status"] isEqualToString:@"error"]) {
        
        NSString *errorMsg = [NSString stringWithFormat:@"%@",[[response content] objectForKey:@"message"]];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:errorMsg delegate:self cancelButtonTitle:@"确认" otherButtonTitles:nil, nil];
        [alert show];
        
        [self hideLoadWithAnimated:YES];
        self.isLoading = NO;
        
        return;
    }
    
    self.dataDic = [[[response content] objectForKey:@"data"] objectForKey:@"brokerBaseInfo"];
    self.ppcDataDic = [[[response content] objectForKey:@"data"] objectForKey:@"brokerPPCInfo"];
    
    if ([LoginManager getChatID].length <=0 || [LoginManager getChatID] == nil) {
        //保存聊天id和聊天token
        NSString *chatID = [[[response content] objectForKey:@"data"] objectForKey:@"chatId"];
        NSString *tokenChat = [[[response content] objectForKey:@"data"] objectForKey:@"tokenChat"];
        NSString *phone = [self.dataDic objectForKey:@"phone"];
        NSString *realName = [self.dataDic objectForKey:@"brokerName"]; //真实姓名保存
        NSString *twoCodeIcon = [[[response content] objectForKey:@"data"] objectForKey:@"twoCodeIcon"];
        
        //保存
        [[NSUserDefaults standardUserDefaults] setValue:chatID forKey:@"chatID"];
        [[NSUserDefaults standardUserDefaults] setValue:tokenChat forKey:@"tokenChat"];
        [[NSUserDefaults standardUserDefaults] setValue:phone forKey:@"phone"]; //联系电话
        [[NSUserDefaults standardUserDefaults] setValue:realName forKey:@"realName"]; //真实姓名
        [[NSUserDefaults standardUserDefaults] setValue:twoCodeIcon forKey:@"twoCodeIcon"]; //二维码


    }
    //保存头像
    AXMappedPerson *person = [[AXChatMessageCenter defaultMessageCenter] fetchPersonWithUID:[LoginManager getChatID]];
    self.img = [[IMGDowloaderManager alloc] init];
    if (person.iconPath.length < 2) {
        if ([LoginManager getUse_photo_url] && ![[LoginManager getUse_photo_url] isEqualToString:@""]) {
//            NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:[LoginManager getUse_photo_url]]];
            if (self.photoImg) {
                [self.imgDownloader dowloadIMGWithURL:[NSURL URLWithString:[LoginManager getUse_photo_url]] resultBlock:^(RTNetworkResponse *response) {
                    if (response.status == 2) {
                        if (response.content && [response.content objectForKey:@"imagePath"]) {
                            UIImage *image = [UIImage imageWithContentsOfFile:[response.content objectForKey:@"imagePath"]];
                            NSArray*libsPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
                            NSString*libPath = [libsPath objectAtIndex:0];
                            NSString *userFolder = [libPath stringByAppendingPathComponent:[LoginManager getChatID]];
                            if ([UIImageJPEGRepresentation(image, 0.96) writeToFile:userFolder atomically:YES]) {
                            }else{
                            }
                            AXMappedPerson *person = [[AXChatMessageCenter defaultMessageCenter] fetchPersonWithUID:[LoginManager getChatID]];
                            person.iconUrl = [LoginManager getUse_photo_url];
                            person.iconPath = [LoginManager getChatID];
                            person.isIconDownloaded = YES;
                            [[AXChatMessageCenter defaultMessageCenter] updatePerson:person];
                        }
                    }
                }];
            }
        }
    }

    [self setHomeValue];
    
    if (!self.hasLongLinked) {
        if (![LoginManager getChatID] || [[LoginManager getChatID] isEqualToString:@""] || [LoginManager getChatID] == nil) {
            
        }
        else {
//            [self setTitleViewWithString:[LoginManager getRealName]];
//            [self setTitleViewWithString:@"房源"];
            //******兼容安居客team得到userInfoDic并设置NSUserDefaults，以帮助底层通过对应路径获取相应数据******
            NSDictionary *dic = [LoginManager getFuckingChatUserDicJustForAnjukeTeamWithPhone:[LoginManager getPhone] uid:[LoginManager getChatID]];
            [[NSUserDefaults standardUserDefaults] setValue:dic forKey:USER_DEFAULT_KEY_AXCHATMC_USE];
            [AXChatMessageCenter defaultMessageCenter];

            [[AppDelegate sharedAppDelegate] connectLongLinkForChat];
            
        }
        self.hasLongLinked = YES;
    }
    
    [self hideLoadWithAnimated:YES];
    self.isLoading = NO;
    
}

- (void)requestForConfigure {
    if (![self isNetworkOkay]) {
        return;
    }
    
    NSMutableDictionary *params = nil;
    NSString *method = nil;
    
    params = [NSMutableDictionary dictionaryWithObjectsAndKeys:[LoginManager getToken], @"token", [LoginManager getUserID], @"brokerId", nil];
    method = @"globalconf/";
    [[RTRequestProxy sharedInstance] asyncRESTPostWithServiceID:RTBrokerRESTServiceID methodName:method params:params target:self action:@selector(onRequestConfigureFinished:)];
}

- (void)onRequestConfigureFinished:(RTNetworkResponse *)response {
    DLog(@"。。。configure response [%@]", [response content]);
    
    if ([response status] == RTNetworkResponseStatusFailed || [[[response content] objectForKey:@"status"] isEqualToString:@"error"]) {
        
        NSString *errorMsg = [NSString stringWithFormat:@"%@",[[response content] objectForKey:@"message"]];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:errorMsg delegate:nil cancelButtonTitle:@"确认" otherButtonTitles:nil, nil];
        [alert show];
        
        return;
    }
    
    self.configChecked = YES;
    
    NSDictionary *resultFromAPI = [[response content] objectForKey:@"data"];
    
    NSArray *frendOverNumArr = [resultFromAPI objectForKey:@"frendOverNum"]; //好友上限用
    [[NSUserDefaults standardUserDefaults] setValue:frendOverNumArr forKey:@"frendOverNumArr"];
    
    NSDictionary *tipsDic = [resultFromAPI objectForKey:@"tips"]; //是否显示状态条并跳转webView
    if ([[tipsDic objectForKey:@"openFlag"] isEqualToString:@"1"]) {//开启弹窗和跳转 test
//        [self showWebViewJumpWithDic:tipsDic];
    }
    else {
//        [self hideWebViewJumpBtn];
    }
}
#pragma mark - 获取计划管理信息
-(void)doRequestPPC{
    if (self.isLoading == YES) {
        //        return;
    }
    
    if(![self isNetworkOkay]){
        [self showInfo:NONETWORK_STR];
        return;
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:[LoginManager getToken], @"token", [LoginManager getUserID], @"brokerId", [LoginManager getCity_id], @"cityId", nil];
    [[RTRequestProxy sharedInstance] asyncRESTPostWithServiceID:RTBrokerRESTServiceID methodName:@"anjuke/prop/ppc/" params:params target:self action:@selector(onGetSuccess:)];
    
    [self showLoadingActivity:YES];
    self.isLoading = YES;
}

- (void)onGetSuccess:(RTNetworkResponse *)response {
    DLog(@"------response [%@]", [response content]);
    
    if([[response content] count] == 0){
        [self hideLoadWithAnimated:YES];
        self.isLoading = NO;
        [self showInfo:@"操作失败"];
        return ;
    }
    if ([response status] == RTNetworkResponseStatusFailed || [[[response content] objectForKey:@"status"] isEqualToString:@"error"]) {
        NSString *errorMsg = [NSString stringWithFormat:@"%@",[[response content] objectForKey:@"message"]];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"请求失败" message:errorMsg delegate:self cancelButtonTitle:@"确认" otherButtonTitles:nil, nil];
        [alert show];
        [self hideLoadWithAnimated:YES];
        self.isLoading = NO;
        
        return;
    }
    [self.myArray removeAllObjects];
    NSDictionary *resultFromAPI = [NSDictionary dictionaryWithDictionary:[[response content] objectForKey:@"data"]];
    if([resultFromAPI count] ==  0){
        [self hideLoadWithAnimated:YES];
        self.isLoading = NO;
        
        return ;
    }
    NSMutableDictionary *bidPlan = [[NSMutableDictionary alloc] initWithDictionary:[resultFromAPI objectForKey:@"bidPlan"]];
    [bidPlan setValue:@"1" forKey:@"type"];
    [self.myArray addObject:bidPlan];
    
    NSMutableArray *fixPlan = [NSMutableArray array];
    [fixPlan addObjectsFromArray:[resultFromAPI objectForKey:@"fixPlan"]];
    [self.myArray addObjectsFromArray:fixPlan];
    if ([fixPlan count] == 1) {
        self.isSeedPid = [[fixPlan objectAtIndex:0] objectForKey:@"fixPlanId"];
    }
    NSMutableDictionary *nodic = [[NSMutableDictionary alloc] init];
    [nodic setValue:@"待推广房源" forKey:@"title"];
    [nodic setValue:[resultFromAPI objectForKey:@"unRecommendPropNum"] forKey:@"unRecommendPropNum"];
    [nodic setValue:@"1" forKey:@"type"];
    [self.myArray addObject:nodic];
    
    [self.tvList reloadData];
    [self hideLoadWithAnimated:YES];
    self.isLoading = NO;
    
}

#pragma mark - tableView Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
   return  self.taskArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return HOME_cellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentify = @"cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentify];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentify];
    }
    cell.textLabel.text = [self.taskArray objectAtIndex:indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    ((UILabel *)[cell viewWithTag:101]).text = @"";
    [(UILabel *)[cell viewWithTag:101] setBackgroundColor:[UIColor clearColor]];
    
    BrokerLineView *line = [[BrokerLineView alloc] initWithFrame:CGRectMake(15, 1, 320 - 15, 1)];
    [cell.contentView addSubview:line];
    
    return cell;
}

#pragma mark - tableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (indexPath.row) {
        case 0:
        {
            [[BrokerLogger sharedInstance] logWithActionCode:AJK_PPC_HOME_004 note:nil];
            
            SaleFixedDetailController *controller = [[SaleFixedDetailController alloc] init];
            controller.tempDic = [self.myArray objectAtIndex:indexPath.row];
            controller.backType = RTSelectorBackTypePopToRoot;
            [controller setHidesBottomBarWhenPushed:YES];
            [self.navigationController pushViewController:controller animated:YES];
        }
            break;
        case 1:
        {
            [[BrokerLogger sharedInstance] logWithActionCode:AJK_PPC_HOME_003 note:nil];
            
            SaleBidDetailController *controller = [[SaleBidDetailController alloc] init];
            controller.backType = RTSelectorBackTypePopToRoot;
            [controller setHidesBottomBarWhenPushed:YES];
            [self.navigationController pushViewController:controller animated:YES];

        }
            break;
        case 2:
        {
            [[BrokerLogger sharedInstance] logWithActionCode:AJK_PPC_HOME_005 note:nil];
            
            SaleNoPlanGroupController *controller = [[SaleNoPlanGroupController alloc] init];
            controller.isSeedPid = self.isSeedPid;
            [controller setHidesBottomBarWhenPushed:YES];
            [self.navigationController pushViewController:controller animated:YES];

        }
            break;
            
        default:
            break;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark- SelectionToolViewDelegate

- (void)didClickSectionAtIndex:(NSInteger) index {
    self.selectionView.hidden = YES;
    switch (index) {
        case 0:
        {
            [[BrokerLogger sharedInstance] logWithActionCode:AJK_HOME_003 note:nil];
            
            //模态弹出小区--万恶的结构变动尼玛
            CommunityListViewController *controller = [[CommunityListViewController alloc] init];
            controller.backType = RTSelectorBackTypeDismiss;
            controller.isFirstShow = YES;
            RTGestureBackNavigationController *nav = [[RTGestureBackNavigationController alloc] initWithRootViewController:controller];
            [self presentViewController:nav animated:YES completion:nil];
        }
            break;
        case 1:
        {
            [[BrokerLogger sharedInstance] logWithActionCode:AJK_HOME_004 note:nil];
            
            //模态弹出小区--万恶的结构变动尼玛
            CommunityListViewController *controller = [[CommunityListViewController alloc] init];
            controller.backType = RTSelectorBackTypeDismiss;
            controller.isFirstShow = YES;
            controller.isHaouzu = YES;
            RTGestureBackNavigationController *nav = [[RTGestureBackNavigationController alloc] initWithRootViewController:controller];
            [self presentViewController:nav animated:YES completion:nil];
        }
            break;
        default:
            break;
    }
}

@end

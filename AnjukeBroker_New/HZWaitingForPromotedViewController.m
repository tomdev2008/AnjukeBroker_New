//
//  HZWaitingForPromotedViewController.m
//  AnjukeBroker_New
//
//  Created by xubing on 14-7-1.
//  Copyright (c) 2014年 Wu sicong. All rights reserved.
//

#import "HZWaitingForPromotedViewController.h"
#import "PropSelectStatusModel.h"
#import "PropertyDetailCellModel.h"
#import "PropertyEditViewController.h"
#import "MultipleChoiceAndEditListCell.h"
#import "RTGestureBackNavigationController.h"
#import "PropertySingleViewController.h"
#import "UIView+AXChatMessage.h"
#import "UIFont+RT.h"
#import "HudTipsUtils.h"

@interface HZWaitingForPromotedViewController ()

@property (nonatomic, strong) UIButton *buttonSelect;  //编辑按钮
@property (nonatomic, strong) UIButton *buttonPromote;  //推广按钮
@property (nonatomic, strong) UIImageView *selectImage;
@property (nonatomic, strong) NSMutableArray *cellSelectStatus;
@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) NSString *editPropertyId;//编辑和删除cell的房源Id
@property (nonatomic) NSInteger selectedCellCount;

@property (nonatomic) BOOL isSelectAll;
@property (nonatomic) BOOL isHaozu;

@end

@implementation HZWaitingForPromotedViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setTitleViewWithString:@"待推广房源"];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight - 50) style:UITableViewStylePlain];
    } else {
        self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight - 50 - 20) style:UITableViewStylePlain];
    }
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
    self.tableView.rowHeight = 90;
    [self.tableView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
    self.MutipleEditView = [[UIView alloc] initWithFrame:CGRectMake(0, ScreenHeight - 49 -64, ScreenWidth, 49)];
    self.isSelectAll = false;
    self.selectedCellCount = 0;
    [self.view addSubview:self.tableView];

}

- (void)showBottomView
{
    if (self.mutipleEditView) {
        [self.view addSubview:self.mutipleEditView];
    }
    
    self.MutipleEditView = [[UIView alloc] initWithFrame:CGRectMake(0, ScreenHeight - 49 -64, ScreenWidth, 49)];
    self.mutipleEditView.backgroundColor = [UIColor brokerBlackColor];
    self.mutipleEditView.alpha = 0.7;
    
    _buttonSelect = [UIButton buttonWithType:UIButtonTypeCustom];
    _buttonSelect.frame = CGRectMake(0, 0, ScreenWidth * 0.48, 49);
    [_buttonSelect addTarget:self action:@selector(selectAllProps:) forControlEvents:UIControlEventTouchUpInside];
    
    UIImageView *selectImage = [[UIImageView alloc] initWithFrame:CGRectMake((56 - 22)/2, (50 - 22)/2, 22, 22)];
    selectImage.image = [UIImage imageNamed:@"broker_property_control_select_gray@2x.png"];
    [_buttonSelect addSubview:selectImage];
    self.selectImage = selectImage;
    
    UILabel *allSelectLabel = [[UILabel alloc] initWithFrame:CGRectMake(44, 10, 80, 40)];
    allSelectLabel.backgroundColor = [UIColor clearColor];
    allSelectLabel.font = [UIFont ajkH2Font];
    allSelectLabel.text = @"全选";
    allSelectLabel.textColor = [UIColor whiteColor];
    allSelectLabel.centerY = 50/2;
    allSelectLabel.left = selectImage.right + 5;
    [_buttonSelect addSubview:allSelectLabel];
    
    _buttonPromote = [UIButton buttonWithType:UIButtonTypeCustom];
    _buttonPromote.frame = CGRectMake(0, 12, 120, 33);
    _buttonPromote.right = ScreenWidth - 10;
    _buttonPromote.centerY = 50/2;
    _buttonPromote.titleLabel.font = [UIFont ajkH3Font];
    [_buttonPromote setBackgroundImage:[[UIImage imageNamed:@"anjuke_icon_button_little_blue"] stretchableImageWithLeftCapWidth:5 topCapHeight:5] forState:UIControlStateNormal];
    [_buttonPromote setTitle:[NSString stringWithFormat:@"定价推广(%d)", self.selectedCellCount]  forState:UIControlStateNormal];
    [_buttonPromote addTarget:self action:@selector(clickFixPromotionButton:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.mutipleEditView addSubview:_buttonSelect];
    [self.mutipleEditView addSubview:_buttonPromote];
    
    [self.view addSubview:self.mutipleEditView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self loadData];
}

- (void)loadData
{
   [self clearStatus];
   [self requestDataWithBrokerId:[LoginManager getUserID] cityId:[LoginManager getCity_id]];
}

- (void)clearStatus
{
    self.isSelectAll = false;
    self.selectedCellCount = 0;
    self.selectImage.image = [UIImage imageNamed:@"broker_property_control_select_gray@2x.png"];
    [self updatePromotionButtonText];
}

- (void)requestDataWithBrokerId:(NSString *)brokerId cityId:(NSString *)cityId
{
    NSString *method = @"zufang/prop/noplanprops/";
    NSDictionary *params = @{@"token":[LoginManager getToken],@"brokerId":brokerId,@"cityId":cityId};
    [[RTRequestProxy sharedInstance]asyncRESTGetWithServiceID:RTBrokerRESTServiceID methodName:method params:params target:self action:@selector(handleRequestData:)];
    self.isLoading = YES;
    [self showLoadingActivity:YES];
}

- (void)handleRequestData:(RTNetworkResponse *)response
{
    self.isLoading = NO;
    [self hideLoadWithAnimated:YES];
    if (![self checkNetworkAndErrorWithResponse:response]) {
        return;
    };
    NSArray *dataArray  = [self checkDataWithResponse:response];
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:dataArray.count];
    for (int i = 0; i < dataArray.count; i++) {
        PropSelectStatusModel *selectStatusModel = [PropSelectStatusModel new];
        selectStatusModel.selectStatus = false;
        selectStatusModel.propId       = [dataArray[i] objectForKey:@"propId"];
        [arr addObject:selectStatusModel];
    }
    self.cellSelectStatus  = arr;
    self.dataSource        = [NSMutableArray arrayWithArray:dataArray];
    [self.tableView reloadData];
    
}

- (void)clickFixPromotionButton:(id)sender
{
    [self sendClickFixPromotionButtonLog];
    if (![self checkWithPlanIdandSelectCount]) {
        return;
    };
    NSString *propIds    = @"";
    for (PropSelectStatusModel *selectStatusModel in self.cellSelectStatus) {
        if (selectStatusModel.selectStatus) {
            propIds = [propIds stringByAppendingFormat:@"%@,",selectStatusModel.propId];
        }
    }
    propIds = [propIds substringToIndex:propIds.length - 1];
    NSString *method     = @"zufang/fix/addpropstoplan/";
    NSDictionary *params = @{@"token":[LoginManager getToken], @"brokerId":[LoginManager  getUserID], @"planId":self.planId,@"propIds":propIds};
    [[RTRequestProxy sharedInstance]asyncRESTGetWithServiceID:RTBrokerRESTServiceID methodName:method params:params target:self action:@selector(onFixPromotionRequestFinished:)];
    self.isLoading = YES;
    [self showLoadingActivity:YES];
}


- (void)onFixPromotionRequestFinished:(RTNetworkResponse *)response
{
    self.isLoading = NO;
    [self hideLoadWithAnimated:YES];
    if (![self checkNetworkAndErrorWithResponse:response]) {
        return;
    };
    if ([[response.content valueForKey:@"status"] isEqualToString:@"ok"]) {
        [self loadData];
        [self displayHUDWithStatus:@"ok" Message:@"推广成功" ErrCode:nil];
    }
    
}
- (void)showAlertViewWithTitle:(NSString *)title
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:@"" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alertView show];
}
- (void)displayHUDWithStatus:(NSString *)status Message:(NSString*)message ErrCode:(NSString*)errCode
{
    [[HudTipsUtils sharedInstance] displayHUDWithStatus:status Message:message ErrCode:errCode toView:self.view];
}
#pragma mark - response check
- (BOOL)checkNetworkAndErrorWithResponse:(RTNetworkResponse *)response
{
    if (response.status == RTNetworkResponseStatusFailed) {
        [self displayHUDWithStatus:@"error" Message:@"无网络连接" ErrCode:response.content[@"errcode"]];
        return false;
    } else if ([[response.content valueForKey:@"status"] isEqualToString:@"error"]) {
        DLog(@"message:--->%@",[response.content valueForKey:@"message"]);
        [self displayHUDWithStatus:response.content[@"status"] Message:response.content[@"message"] ErrCode:@"1"];
        return false;
    }
    return true;
}

- (NSArray *)checkDataWithResponse:(RTNetworkResponse *)response
{
    NSArray *dataArray = [[response.content objectForKey:@"data"] objectForKey:@"propertyList"];
    if (dataArray == nil || [dataArray count] == 0) {
        UIImageView *noResult = [[UIImageView alloc] initWithFrame:CGRectMake(104.0f, 210 - 80, 112.0f, 80.0f)];
        [noResult setImage:[UIImage imageNamed:@"pic_3.4_01.png"]];
        [self.view addSubview:noResult];
        
        UILabel *noR = [[UILabel alloc] initWithFrame:CGRectMake(0, 210 + 15, 200, 50)];
        noR.text = @"暂无待推广房源";
        noR.textColor = [UIColor grayColor];
        [noR sizeToFit];
        noR.centerX = self.view.centerX;
        [self.view addSubview:noR];
        [self.mutipleEditView removeFromSuperview];
    } else {
        [self showBottomView];
    }
    
    return dataArray;
}

- (BOOL)checkWithPlanIdandSelectCount
{
    if (self.planId == nil || [self.planId isEqualToString:@""]) {
        DLog(@"planId is nil or empty");
        [self showAlertViewWithTitle:@"没有房源计划"];
        return false;
    }
    if (self.selectedCellCount == 0) {
        [self showAlertViewWithTitle:@"请选择要推广的房源"];
        return false;
    }
    return true;
}

#pragma mark - cell选择处理

- (void)selectAllProps:(id)sender
{
    [self sendClickSelectAllButtonLog];
    self.selectedCellCount = 0;
    if (!self.isSelectAll) {
        self.selectImage.image = [UIImage imageNamed:@"broker_property_control_selected"];
        for (PropSelectStatusModel *statusModel in self.cellSelectStatus) {
            statusModel.selectStatus = true;
            self.selectedCellCount ++;
        }
    } else {
        self.selectImage.image = [UIImage imageNamed:@"broker_property_control_select_gray"];
        for (PropSelectStatusModel *statusModel in self.cellSelectStatus) {
            statusModel.selectStatus = false;
        }
    }
    self.isSelectAll = !self.isSelectAll;
    [self.tableView reloadData];
    [self updatePromotionButtonText];
    
}

#pragma mark - CellSelectStatusDelegate
- (void)cellStatusChanged:(BOOL)isSelect atRowIndex:(NSInteger)rowIndex
{
    if (isSelect) {
        self.selectedCellCount ++;
        if (self.selectedCellCount == [self.cellSelectStatus count]) {
            self.selectImage.image = [UIImage imageNamed:@"broker_property_control_selected"];
            self.isSelectAll = YES;
        }
    } else {
        self.selectedCellCount --;
        if (self.isSelectAll) {
            self.selectImage.image = [UIImage imageNamed:@"broker_property_control_select_gray"];
            self.isSelectAll = NO;
        }
    }
    PropSelectStatusModel *statusModel = self.cellSelectStatus[rowIndex];
    statusModel.selectStatus = isSelect;
    [self updatePromotionButtonText];
    DLog(@"%@----%@",statusModel.propId,[self.dataSource[rowIndex] valueForKey:@"propId"]);

}

- (void)updatePromotionButtonText
{
    [self.buttonPromote setTitle:[NSString stringWithFormat:@"定价推广(%d)",self.selectedCellCount] forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataSource.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 90.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"identifierCell";
    MultipleChoiceAndEditListCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];

    NSArray *rightBtnarr = [NSArray array];
    rightBtnarr = [self rightButtons];
    if (cell == nil) {
        cell = [[MultipleChoiceAndEditListCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                    reuseIdentifier:@"identifierCell"
                                                containingTableView:tableView
                                                 leftUtilityButtons:nil
                                                rightUtilityButtons:rightBtnarr];

    cell.delegate = self;
    }
    PropSelectStatusModel *selectStatusModel = self.cellSelectStatus[indexPath.row];
    [cell changeCellSelectStatus:selectStatusModel.selectStatus];
    PropertyDetailCellModel *model = [[PropertyDetailCellModel alloc] initWithDataDic:[self.dataSource objectAtIndex:indexPath.row]];
    cell.propertyDetailTableViewCellModel   = model;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.rowIndex       = indexPath.row;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    cell.delegate = self;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    int i = indexPath.row;
    NSDictionary *editCell = self.dataSource[i];
    self.editPropertyId = [editCell objectForKey:@"propId"];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
   PropertySingleViewController *propZF = [[PropertySingleViewController alloc] init];
//    propZF.isHaozu = YES;
    propZF.pageType = PAGE_TYPE_NO_PLAN;
    propZF.propId = self.editPropertyId;
    [self.navigationController pushViewController:propZF animated:YES];
}

- (NSArray *)rightButtons
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray array];
    [rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor brokerLineColor] title:@"编辑"];
    [rightUtilityButtons sw_addUtilityButtonWithColor:[UIColor brokerRedColor] title:@"删除"];
    return rightUtilityButtons;
}

#pragma mark - SWTableViewCellDelegate
- (void)swipeableTableViewCell:(MultipleChoiceAndEditListCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
    self.editAndDeleteCellIndexPath = [self.tableView indexPathForCell:cell];
    int i = self.editAndDeleteCellIndexPath.row;
    NSDictionary *editCell = self.dataSource[i];
    self.editPropertyId = [editCell objectForKey:@"propId"];

    [self showLoadingActivity:YES];

    switch (index) {
        case 0:
        {
            //编辑房源
            [self hideLoadWithAnimated:YES];
            [cell hideUtilityButtonsAnimated:YES];
            [self editProperty];
            break;
        }
        case 1:
        {
            //删除房源
            [self hideLoadWithAnimated:YES];
            UIAlertView *alertTest = [[UIAlertView alloc] initWithTitle:@"您确认删除吗?"
                                                                message:nil
                                                               delegate:self
                                                      cancelButtonTitle:@"取消"
                                                      otherButtonTitles:@"确认", nil];
            [alertTest show];


            break;
        };

        default:
            break;
    }
}

- (BOOL)swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:(SWTableViewCell *)cell {
    return YES;
}

//编辑房源
- (void)editProperty
{
    PropertyEditViewController *controller = [[PropertyEditViewController alloc] init];
    controller.isHaozu = self.isHaozu;
    controller.propertyID = [self.dataSource objectAtIndex:self.editAndDeleteCellIndexPath.row][@"propId"];
    controller.backType = RTSelectorBackTypeDismiss;
    RTGestureBackNavigationController *nav = [[RTGestureBackNavigationController alloc] initWithRootViewController:controller];
    [self presentViewController:nav animated:YES completion:nil];
    
}


#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        PropSelectStatusModel *model = self.cellSelectStatus[self.editAndDeleteCellIndexPath.row];
        if (model.selectStatus == true) {
            self.selectedCellCount --;
        }
        [self doDeleteProperty:self.editPropertyId];
        [self updatePromotionButtonText];

    }
}

//删除房源
- (void)doDeleteProperty:(NSString *)propertyID{
    self.isLoading = YES;
    if (![self isNetworkOkayWithNoInfo]) {
        [[HUDNews sharedHUDNEWS] createHUD:@"无网络连接" hudTitleTwo:nil addView:self.view isDim:NO isHidden:YES hudTipsType:HUDTIPSWITHNetWorkBad];
        self.isLoading = NO;
        return;
    }
    //更新房源信息
    NSMutableDictionary *params = nil;
    NSString *method = nil;

    params = [NSMutableDictionary dictionaryWithObjectsAndKeys:[LoginManager getCity_id], @"cityId", [LoginManager getToken], @"token", [LoginManager getUserID], @"brokerId", propertyID, @"propIds", nil];
        method = @"zufang/prop/delprops/";

    [[RTRequestProxy sharedInstance] asyncRESTPostWithServiceID:RTBrokerRESTServiceID methodName:method params:params target:self action:@selector(onDeletePropFinished:)];
    self.isLoading = YES;
    [self showLoadingActivity:YES];
}

- (void)onDeletePropFinished:(RTNetworkResponse *)response {
    DLog(@"--delete Prop。。。response [%@]", [response content]);
    [self hideLoadWithAnimated:YES];
    self.isLoading = NO;
    if([[response content] count] == 0){
        [[HUDNews sharedHUDNEWS] createHUD:@"无网络连接" hudTitleTwo:nil addView:self.view isDim:NO isHidden:YES hudTipsType:HUDTIPSWITHNetWorkBad];
    }

    if ([response status] == RTNetworkResponseStatusFailed || [[[response content] objectForKey:@"status"] isEqualToString:@"error"]) {
        [[HUDNews sharedHUDNEWS] createHUD:@"网络不畅" hudTitleTwo:nil addView:self.view isDim:NO isHidden:YES hudTipsType:HUDTIPSWITHNetWorkBad];

        //        NSString *errorMsg = [NSString stringWithFormat:@"%@",[[response content] objectForKey:@"message"]];
        return;
    }
    
    [self.dataSource removeObjectAtIndex:self.editAndDeleteCellIndexPath.row];
    [self.cellSelectStatus removeObjectAtIndex:self.editAndDeleteCellIndexPath.row];
    [self.tableView deleteRowsAtIndexPaths:@[self.editAndDeleteCellIndexPath] withRowAnimation:UITableViewRowAnimationLeft];

    [self loadData];
    [[HUDNews sharedHUDNEWS] createHUD:@"删除房源成功" hudTitleTwo:nil addView:self.view isDim:NO isHidden:YES hudTipsType:HUDTIPSWITHNORMALOK];
    
}

#pragma mark - Log
-(void)sendAppearLog
{
    [[BrokerLogger sharedInstance] logWithActionCode:ZF_WTG_LIST_ONVIEW page:ZF_WTG_LIST_PAGE note:[NSDictionary dictionaryWithObjectsAndKeys:[Util_TEXT logTime], @"ot", nil]];
}
-(void)sendClickSelectAllButtonLog
{
    [[BrokerLogger sharedInstance] logWithActionCode:ZF_WTG_LIST_CLICK_SELECTALL page:ZF_WTG_LIST_PAGE note:[NSDictionary dictionaryWithObjectsAndKeys:[Util_TEXT logTime], @"ot", nil]];
}
- (void)sendClickFixPromotionButtonLog
{
    [[BrokerLogger sharedInstance] logWithActionCode:ZF_WTG_LIST_CLICK_DJTG page:ZF_WTG_LIST_PAGE note:[NSDictionary dictionaryWithObjectsAndKeys:[Util_TEXT logTime], @"ot", nil]];
}

- (void)doBack:(id)sender
{
    [[BrokerLogger sharedInstance] logWithActionCode:ZF_WTG_LIST_BACK page:ZF_WTG_LIST_PAGE note:[NSDictionary dictionaryWithObjectsAndKeys:[Util_TEXT logTime], @"ot", nil]];
    [self.navigationController popViewControllerAnimated:YES];
}

@end

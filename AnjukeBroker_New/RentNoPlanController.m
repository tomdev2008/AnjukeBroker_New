//
//  RentNpPlanController.m
//  AnjukeBroker_New
//
//  Created by jianzhongliu on 11/4/13.
//  Copyright (c) 2013 Wu sicong. All rights reserved.
//

#import "RentNoPlanController.h"
#import "BaseNoPlanListCell.h"
#import "SaleNoPlanListCell.h"
#import "SalePropertyObject.h"
#import "LoginManager.h"
#import "SaleNoPlanListManager.h"
#import "RentGroupListController.h"
#import "SalePropertyObject.h"
#import "RentFixedDetailController.h"
#import "CellHeight.h"
#import "RTGestureBackNavigationController.h"

@interface RentNoPlanController ()
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIBarButtonItem *seleceAllItem; //全选btnItem
@property int singleSelectBtnRow; //记录最后打勾按钮所在indexPath.row
@property (nonatomic, strong) UIButton *editBtn; //编辑按钮
@property (nonatomic, strong) UIBarButtonItem *rightButtonItem;
@end

@implementation RentNoPlanController
@synthesize contentView;
@synthesize seleceAllItem;
@synthesize singleSelectBtnRow;
@synthesize editBtn;
@synthesize isSeedPid;
@synthesize rightButtonItem;
#pragma mark - log
- (void)sendAppearLog {
    [[BrokerLogger sharedInstance] logWithActionCode:ZF_WTG_LIST_ONVIEW  page:ZF_WTG_LIST_PAGE note:[NSDictionary dictionaryWithObjectsAndKeys:[Util_TEXT logTime], @"ot", nil]];
}

- (void)sendDisAppearLog {
    [[BrokerLogger sharedInstance] logWithActionCode:HZ_PPC_NO_PLAN_02 note:[NSDictionary dictionaryWithObjectsAndKeys:[Util_TEXT logTime], @"dt", nil]];
}

#pragma mark - View lifecycle
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initDisplay_];
	// Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if([self.selectedArray count] == 0){
        [self doRequest];
    }
}

-(void)dealloc{
    self.myTable.delegate = nil;
    self.myTable.dataSource = nil;
    self.myTable = nil;
}
- (void)initDisplay_ {
//    self.myTable.frame = FRAME_WITH_NAV;
    
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, [self currentViewHeight], [self windowWidth], TOOL_BAR_HEIGHT)];
    self.contentView.backgroundColor = SYSTEM_NAVIBAR_COLOR;
    
    //编辑、删除、定价推广btn
    UIButton *mutableSelect = [UIButton buttonWithType:UIButtonTypeCustom];
    [mutableSelect setTitle:@"编辑" forState:UIControlStateNormal];
    [mutableSelect setTitleColor:SYSTEM_BLUE forState:UIControlStateNormal];
    mutableSelect.frame = CGRectMake(10, 0, 90, TOOL_BAR_HEIGHT);
    self.editBtn = mutableSelect;
    [mutableSelect addTarget:self action:@selector(doEdit) forControlEvents:UIControlEventTouchDown];
    [self.contentView addSubview:mutableSelect];
    
    UIButton *multiSelect = [UIButton buttonWithType:UIButtonTypeCustom];
    multiSelect.frame = CGRectMake(110, 0, 90, TOOL_BAR_HEIGHT);
    [multiSelect setTitle:@"定价推广" forState:UIControlStateNormal];
    [multiSelect setTitleColor:SYSTEM_BLUE forState:UIControlStateNormal];
    [multiSelect addTarget:self action:@selector(mutableFixed) forControlEvents:UIControlEventTouchDown];
    [self.contentView addSubview:multiSelect];
    [self.view addSubview:self.contentView];
    
    UIButton *delete = [UIButton buttonWithType:UIButtonTypeCustom];
    [delete setTitle:@"删除" forState:UIControlStateNormal];
    delete.frame = CGRectMake(210, 0, 90, TOOL_BAR_HEIGHT);
    [delete setTitleColor:SYSTEM_BLUE forState:UIControlStateNormal];
    [delete addTarget:self action:@selector(delete) forControlEvents:UIControlEventTouchDown];
    [self.contentView addSubview:delete];
    
    [self setEditBtnEnableStatus];
}

#pragma mark - PropertyDelete Delegate
- (void)propertyDidDelete {
    [self.selectedArray removeAllObjects];
    [self.myArray removeAllObjects];
    [self.myTable reloadData];
    
    [self setEditBtnEnableStatus];
    [self doRequest];
}

#pragma mark - Request 未推广列表
-(void)doRequest{
    if (![self isNetworkOkayWithNoInfo]) {
        [[HUDNews sharedHUDNEWS] createHUD:@"无网络连接" hudTitleTwo:nil addView:self.view isDim:NO isHidden:YES hudTipsType:HUDTIPSWITHNetWorkBad];
        return;
    }

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:[LoginManager getToken], @"token", [LoginManager getUserID], @"brokerId", [LoginManager getCity_id], @"cityId", nil];
    [[RTRequestProxy sharedInstance] asyncRESTPostWithServiceID:RTBrokerRESTServiceID methodName:@"zufang/prop/noplanprops/" params:params target:self action:@selector(onGetSuccess:)];
    [self showLoadingActivity:YES];
    self.isLoading = YES;
}
- (void)onGetSuccess:(RTNetworkResponse *)response {
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
    DLog(@"------response [%@]", [response content]);
    NSDictionary *resultFromAPI = [NSDictionary dictionaryWithDictionary:[[response content] objectForKey:@"data"]];
    if([resultFromAPI count] ==  0){
        [self hideLoadWithAnimated:YES];
        self.isLoading = NO;
        
        return ;
    }
    if (([[resultFromAPI objectForKey:@"propertyList"] count] == 0 || resultFromAPI == nil)) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"没有找到房源" delegate:self cancelButtonTitle:@"确认" otherButtonTitles:nil, nil];
        [alert show];
        [self.myArray removeAllObjects];
        [self.myTable reloadData];
        [self hideLoadWithAnimated:YES];
        self.isLoading = NO;
        
        return;
    }
    
    NSMutableArray *result = [SaleNoPlanListManager propertyObjectArrayFromDicArray:[resultFromAPI objectForKey:@"propertyList"]];
    [self.myArray removeAllObjects];
    [self.myArray addObjectsFromArray:result];
    if([self.myArray count] >0){
        //全选
        rightButtonItem = [UIBarButtonItem getBarButtonItemWithChangeString:@"全选" taget:self action:@selector(rightButtonAction:)];
        UIBarButtonItem *space = [UIBarButtonItem getBarSpace:-5.0];
        if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
            self.navigationItem.rightBarButtonItem = rightButtonItem;
        }else{
            self.navigationItem.rightBarButtonItems = @[space,rightButtonItem];
        }
    }
    [self.myTable reloadData];
    [self setEditBtnEnableStatus];
    
    [self hideLoadWithAnimated:YES];
    self.isLoading = NO;
    
}
#pragma mark - 批量删除房源
-(void)doDeleteProperty{
    if (![self isNetworkOkayWithNoInfo]) {
        [[HUDNews sharedHUDNEWS] createHUD:@"无网络连接" hudTitleTwo:nil addView:self.view isDim:NO isHidden:YES hudTipsType:HUDTIPSWITHNetWorkBad];
        return;
    }

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:[LoginManager getToken], @"token", [LoginManager getUserID], @"brokerId", [self getStringFromArray:self.selectedArray], @"propIds", [LoginManager getCity_id], @"cityId", nil];
    [[RTRequestProxy sharedInstance] asyncRESTPostWithServiceID:RTBrokerRESTServiceID methodName:@"zufang/prop/delprops/" params:params target:self action:@selector(onDeleteSuccess:)];
    [self showLoadingActivity:YES];
    self.isLoading = YES;
}

- (void)onDeleteSuccess:(RTNetworkResponse *)response {
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
    
    [self hideLoadWithAnimated:YES];
    self.isLoading = NO;
    
    [self.selectedArray removeAllObjects];
    
    [self doRequest];
}
-(NSString *)getStringFromArray:(NSArray *) array{
    NSMutableString *tempStr = [NSMutableString string];
    for (int i=0;i<[array count];i++) {
        SalePropertyObject *pro = (SalePropertyObject *)[array objectAtIndex:i];
        if(tempStr.length == 0){
            [tempStr appendString:[NSString stringWithFormat:@"%@",pro.propertyId]];
        }else{
            [tempStr appendString:@","];
            [tempStr appendString:[NSString stringWithFormat:@"%@",pro.propertyId]];
        }
    }
    
    DLog(@"====%@",tempStr);
    return tempStr;
}
#pragma mark - Request 定价推广
-(void)doFixed{
    if (![self isNetworkOkayWithNoInfo]) {
        [[HUDNews sharedHUDNEWS] createHUD:@"无网络连接" hudTitleTwo:nil addView:self.view isDim:NO isHidden:YES hudTipsType:HUDTIPSWITHNetWorkBad];
        return;
    }

    //    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:[LoginManager getToken], @"token", [LoginManager getUserID], @"brokerId",  @"187275101", @"proIds", @"388666", @"planId", nil];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:[LoginManager getToken], @"token", [LoginManager getUserID], @"brokerId",  [self getStringFromArray:self.selectedArray], @"propIds", self.isSeedPid, @"planId", nil];

    [[RTRequestProxy sharedInstance] asyncRESTPostWithServiceID:RTBrokerRESTServiceID methodName:@"zufang/fix/addpropstoplan/" params:params target:self action:@selector(onFixedSuccess:)];
    [self showLoadingActivity:YES];
    self.isLoading = YES;
}

- (void)onFixedSuccess:(RTNetworkResponse *)response {
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
        [[BrokerLogger sharedInstance] logWithActionCode:ZF_WTG_LIST_CLICK_DJTG page:ZF_WTG_LIST_PAGE note:[NSDictionary dictionaryWithObjectsAndKeys:@"false", @"dj_s", nil]];
        return;
    }
    if([[[response content] objectForKey:@"status"] isEqualToString:@"ok"]){
        [[BrokerLogger sharedInstance] logWithActionCode:ZF_WTG_LIST_CLICK_DJTG page:ZF_WTG_LIST_PAGE note:[NSDictionary dictionaryWithObjectsAndKeys:@"true", @"dj_s", nil]];
    }
    [self hideLoadWithAnimated:YES];
    self.isLoading = NO;
    
    RentFixedDetailController *controller = [[RentFixedDetailController alloc] init];
    controller.backType = RTSelectorBackTypePopToRoot;
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic setValue:self.isSeedPid forKey:@"fixId"];
    controller.tempDic = dic;
    [self.navigationController pushViewController:controller animated:YES];
}
//-(NSString *)getStringFromArray:(NSArray *) array{
//    NSMutableString *tempStr = [NSMutableString string];
//    for (int i=0;i<[array count];i++) {
//        SalePropertyObject *pro = (SalePropertyObject *)[array objectAtIndex:i];
//        if(tempStr.length == 0){
//            [tempStr appendString:[NSString stringWithFormat:@"%@",pro.propertyId]];
//        }else{
//            [tempStr appendString:@","];
//            [tempStr appendString:[NSString stringWithFormat:@"%@",pro.propertyId]];
//        }
//    }
//    DLog(@"====%@",tempStr);
//    return tempStr;
//}
#pragma mark - TableView Delegate & Datasource
-(float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
//    CGSize size = CGSizeMake(250, 40);
    //    CGSize si = [property.title sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:size lineBreakMode:NSLineBreakByWordWrapping];

    SalePropertyObject *property = (SalePropertyObject *)[self.myArray objectAtIndex:indexPath.row];
    return [CellHeight getNoPlanCellHeight:property.title];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{

    static NSString *cellIdent = @"cell";
//    tableView.separatorColor = [UIColor lightGrayColor];
    SaleNoPlanListCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdent];
    if(cell == nil){
        cell = [[SaleNoPlanListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdent];
        cell.btnImage.image = [UIImage imageNamed:@"anjuke_icon06_select.png"];
        cell.clickDelegate = self;
    }
    [cell configureCell:[self.myArray objectAtIndex:indexPath.row] withIndex:indexPath.row];
    
    if([self.selectedArray containsObject:[self.myArray objectAtIndex:[indexPath row]]]){
        cell.btnImage.image = [UIImage imageNamed:@"anjuke_icon06_selected.png"];
    }else{
        cell.btnImage.image = [UIImage imageNamed:@"anjuke_icon06_select.png"];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    SalePropertyObject *property = (SalePropertyObject *)[self.myArray objectAtIndex:indexPath.row];
    [cell showBottonLineWithCellHeight:[CellHeight getNoPlanCellHeight:property.title]];
    return cell;

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self doCheckmarkAtRow:indexPath.row];
}

#pragma mark - Checkmark Btn Delegate

- (void)checkmarkBtnClickedWithRow:(int)row {
    DLog(@"row -[%d]", row);
    
    [self doCheckmarkAtRow:row];
}

#pragma mark - PrivateMethod
//***打勾操作***
- (void)doCheckmarkAtRow:(int)row {
    self.singleSelectBtnRow = row;
    
    if(![self.selectedArray containsObject:[self.myArray objectAtIndex:row]]){
        [self.selectedArray addObject:[self.myArray objectAtIndex:row]];
    }else{
        [self.selectedArray removeObject:[self.myArray objectAtIndex:row]];
    }
    [self.myTable reloadData];
    
    [self setEditBtnEnableStatus];
}

- (void)doEdit {
    [[BrokerLogger sharedInstance] logWithActionCode:ZF_WTG_LIST_CLICK_EDIT page:ZF_WTG_LIST_PAGE note:nil];
    //只有单独勾选可对房源进行编辑
    if (self.selectedArray.count != 1) {
        return;
    }
    PropertyEditViewController *controller = [[PropertyEditViewController alloc] init];
    SalePropertyObject *pro = (SalePropertyObject *)[self.selectedArray objectAtIndex:0];
    controller.isHaozu = YES;
    controller.pdId = ZF_WTG_LIST_PAGE;
    controller.propertyID = pro.propertyId;
    controller.propertyDelegate = self;
    controller.backType = RTSelectorBackTypeDismiss;
    RTGestureBackNavigationController *nav = [[RTGestureBackNavigationController alloc] initWithRootViewController:controller];
    [self presentViewController:nav animated:YES completion:nil];
}
-(void)rightButtonAction:(id)sender{
    [[BrokerLogger sharedInstance] logWithActionCode:ZF_WTG_LIST_CLICK_SELECTALL page:ZF_WTG_LIST_PAGE note:nil];
    if(self.isLoading){
        return ;
    }
    if (self.myArray.count == 0) { //未推广房源被清空后不可全选
        return;
    }
    
    UIButton *btn = (UIButton *)rightButtonItem.customView;
    if ([btn.titleLabel.text isEqualToString:SELECT_ALL_STR]){
        [btn setTitle:UNSELECT_ALL_STR forState:UIControlStateNormal];
        [btn setTitle:UNSELECT_ALL_STR forState:UIControlStateHighlighted];
        [self.selectedArray removeAllObjects];
        [self.selectedArray addObjectsFromArray:self.myArray];
        [self.myTable reloadData];
    }else {
        [btn setTitle:SELECT_ALL_STR forState:UIControlStateNormal];
        [btn setTitle:SELECT_ALL_STR forState:UIControlStateHighlighted];
        
        [self.selectedArray removeAllObjects];
        [self.myTable reloadData];
    }
    
    [self setEditBtnEnableStatus];
}

-(void)delete{
    [[BrokerLogger sharedInstance] logWithActionCode:ZF_WTG_LIST_CLICK_DELETE page:ZF_WTG_LIST_PAGE note:nil];
    
    if ([self.selectedArray count] == 0) {
        UIAlertView *tempView = [[UIAlertView alloc] initWithTitle:@"友情提示" message:@"请选择房源" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [tempView show];
        return ;
    }
    
    UIAlertView *tempView = [[UIAlertView alloc] initWithTitle:@"友情提示" message:@"确定删除房源？" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    tempView.tag = 101;
    [tempView show];
}

-(void)mutableFixed{
    [[BrokerLogger sharedInstance] logWithActionCode:ZF_WTG_LIST_CLICK_DJTG page:ZF_WTG_LIST_PAGE note:nil];
    
    if ([self.selectedArray count] == 0) {
        UIAlertView *tempView = [[UIAlertView alloc] initWithTitle:@"友情提示" message:@"请选择房源" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [tempView show];
        return ;
    }
    if(self.isSeedPid.length >0){
        for (int i = 0; i < [self.selectedArray count]; i++) {
            SalePropertyObject *property = (SalePropertyObject *)[self.selectedArray objectAtIndex:i];
            if([property.isVisible isEqualToString:@"0"]){
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"房源包含违规房源" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
                [alert show];
                return ;
            }
        }
        [self doFixed];
    }else{
        for (int i = 0; i < [self.selectedArray count]; i++) {
            SalePropertyObject *property = (SalePropertyObject *)[self.selectedArray objectAtIndex:i];
            if([property.isVisible isEqualToString:@"0"]){
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"房源包含违规房源" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
                [alert show];
                return ;
            }
        }
        RentGroupListController *controller = [[RentGroupListController alloc] init];
        controller.propertyArray = self.selectedArray;
        [self.navigationController pushViewController:controller animated:YES];
    }

}

//编辑按钮状态更改
- (void)setEditBtnEnableStatus {
    BOOL enabled = NO;
    BOOL isShow = NO;
    DLog(@"selectArr [%d]", self.selectedArray.count);
    
    if (self.selectedArray.count == 1) {
        isShow = YES;
        enabled = YES;
    }
    if (self.selectedArray.count > 1) {
        isShow = YES;
    }

    
    if (isShow) {
        self.contentView.frame = CGRectMake(self.contentView.frame.origin.x, [self currentViewHeight] - TOOL_BAR_HEIGHT, self.contentView.frame.size.width, self.contentView.frame.size.height);
        self.myTable.frame = FRAME_BETWEEN_NAV_TAB;
        [self.myTable reloadData];
    }
    else {
        self.contentView.frame = CGRectMake(self.contentView.frame.origin.x, [self currentViewHeight], self.contentView.frame.size.width, self.contentView.frame.size.height);
        self.myTable.frame = FRAME_WITH_NAV;
        [self.myTable reloadData];
    }
    
    if (enabled) {
        [self.editBtn setTitleColor:SYSTEM_BLUE forState:UIControlStateNormal];
        self.editBtn.enabled = YES;
    }
    else {
        [self.editBtn setTitleColor:SYSTEM_LIGHT_GRAY forState:UIControlStateNormal];
        self.editBtn.enabled = NO;
    }
}

#pragma mark --UIActionSheetDelegate

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if(buttonIndex == 0){
        BaseGroupListController *controller = [[BaseGroupListController alloc] init];
        controller.propertyArray = self.selectedArray;
        [self.navigationController pushViewController:controller animated:YES];
    }else if (buttonIndex == 1){
        PropertyEditViewController *controller = [[PropertyEditViewController alloc] init];
        controller.isHaozu = YES;
        controller.pdId = ZF_WTG_LIST_PAGE;
        controller.propertyID = [[self.selectedArray objectAtIndex:0] objectForKey:@"id"];
        [self.navigationController pushViewController:controller animated:YES];
    }else if (buttonIndex == 2){
        //删除房源
        [self.myArray removeObjectsInArray:self.selectedArray];
        [self.selectedArray removeAllObjects];
        
        [self.myTable reloadData];
        
        DLog(@"myArr [%d]", self.myArray.count);
        
        [self setEditBtnEnableStatus];
        
    }
}
- (void)doBack:(id)sender{
    [super doBack:self];
    [[BrokerLogger sharedInstance] logWithActionCode:ZF_WTG_LIST_BACK page:ZF_WTG_LIST_PAGE note:nil];
}
#pragma mark --UIAlertViewDelegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(buttonIndex == 1){
        [self doDeleteProperty];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

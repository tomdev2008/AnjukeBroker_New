//
//  ClientListViewController.m
//  AnjukeBroker_New
//
//  Created by paper on 14-2-18.
//  Copyright (c) 2014年 Wu sicong. All rights reserved.
//

#import "ClientListViewController.h"
#import "ClientDetailViewController.h"
#import "ClientDetailPublicViewController.h"
#import "Util_UI.h"
#import "AXChatMessageCenter.h"
#import "AXMappedPerson.h"
#import "AXPerson.h"
#import "BrokerChatViewController.h"
#import "AccountManager.h"

@interface ClientListViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) UITableView *tableViewList;
@property (nonatomic, strong) NSMutableArray *listDataArray;

@property (nonatomic, strong) NSMutableArray *publicDataArr; //公共账号列表
@property (nonatomic, strong) NSMutableArray *starDataArr; //星标客户列表
@property (nonatomic, strong) NSMutableArray *allDataArr; //所有客户列表

@property (nonatomic, strong) NSArray *testArr;

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic) NSMutableIndexSet *insertIndexSet;
@property (nonatomic) NSMutableIndexSet *deleteIndexSet;

@end

@implementation ClientListViewController
@synthesize publicDataArr, starDataArr, allDataArr;
@synthesize tableViewList, listDataArray;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self setTitleViewWithString:@"我的客户"];
    self.insertIndexSet = [[NSMutableIndexSet alloc] init];
    self.deleteIndexSet = [[NSMutableIndexSet alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self showLoadingActivity:YES];
    [self getFriendList];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)getFriendList {
    [[AXChatMessageCenter defaultMessageCenter] friendListWithPersonWithCompeletionBlock:^(NSArray *friendList, BOOL whetherSuccess) {
        if (whetherSuccess) {
            [self hideLoadWithAnimated:YES];
            
            DLog(@"getFriendListgetFriendList success--[%d] friendList--[%@]", whetherSuccess, friendList);
            dispatch_async(dispatch_get_main_queue(), ^{
                self.testArr = [NSArray arrayWithArray:friendList];
                [self redrawList];
            });
        }
    }];
}

- (NSFetchedResultsController *)fetchedResultsController
{
    if (!_fetchedResultsController) {
        _fetchedResultsController = [[AXChatMessageCenter defaultMessageCenter] friendListFetchedResultController];
        _fetchedResultsController.delegate = self;
        __autoreleasing NSError *error;
        if (![_fetchedResultsController performFetch:&error]) {
            DLog(@"%@",error);
        }
        
    }
    return _fetchedResultsController;
}

#pragma mark - log
- (void)sendAppearLog {
    [[BrokerLogger sharedInstance] logWithActionCode:CLIENT_LIST_001 note:[NSDictionary dictionaryWithObjectsAndKeys:[Util_TEXT logTime], @"ot", nil]];
}

- (void)sendDisAppearLog {
    [[BrokerLogger sharedInstance] logWithActionCode:CLIENT_LIST_002 note:[NSDictionary dictionaryWithObjectsAndKeys:[Util_TEXT logTime], @"dt", nil]];
}

#pragma mark - init Method

- (void)initModel {
    self.publicDataArr = [NSMutableArray array];
    self.starDataArr = [NSMutableArray array];
    self.allDataArr = [NSMutableArray array];
    self.listDataArray = [NSMutableArray array];
}

- (void)initDisplay {
    UITableView *tv = [[UITableView alloc] initWithFrame:FRAME_BETWEEN_NAV_TAB style:UITableViewStylePlain];
    self.tableViewList = tv;
    tv.delegate = self;
    tv.dataSource = self;
    [self.view addSubview:tv];
    
    if (self.isForMessageList) {
        self.tableViewList.frame = FRAME_WITH_NAV;
    }
}

- (void)redrawList {
    self.listDataArray = [NSMutableArray array];
    [self.publicDataArr removeAllObjects];
    [self.starDataArr removeAllObjects];
    [self.allDataArr removeAllObjects];
    
    //reset 3 list arr ...
    //获取公共账号
    for (int i = 0; i < self.testArr.count; i++) {
        AXMappedPerson *item = [self.testArr objectAtIndex:i];
        if (item.userType == AXPersonTypePublic) {
            [self.publicDataArr addObject:item];
        }
//        else
//            [self.allDataArr addObject:item];
    }
    
    //非公共账号处理
    NSArray *star_arr = [NSArray arrayWithArray:self.testArr];
    for (int i = 0; i < star_arr.count; i ++) {
        if ([(AXMappedPerson *)[star_arr objectAtIndex:i] userType] == AXPersonTypeUser) {
            if ([(AXMappedPerson *)[star_arr objectAtIndex:i] isStar] == YES) {
                [self.starDataArr addObject:[star_arr objectAtIndex:i]]; //星标用户
            }
        }
    }
    
    [self.tableViewList reloadData];
    
    [self checkToAlert];
}

- (void)checkToAlert {
    NSArray *arr = [LoginManager getClientCountAlertArray];
    
    for (int i = 0; i < arr.count; i ++) {
        NSString *count = [arr objectAtIndex:i];
        
        if (self.allDataArr.count >= [count intValue]) {
            if ([[AccountManager sharedInstance] didMaxClientAlertWithCount:[count intValue]] == NO) {
                //公众号上限提醒
                NSMutableDictionary *params = nil;
                NSString *method = nil;
                
                //for test
                params = [NSMutableDictionary dictionaryWithObjectsAndKeys:[LoginManager getChatID], @"toChatId", [LoginManager getUserID], @"brokerId", @"overFriend", @"msgType", count, @"msg", [LoginManager getToken], @"token", nil];
                method = @"msg/sendpublicmsg/";
                
                [[RTRequestProxy sharedInstance] asyncRESTPostWithServiceID:RTBrokerRESTServiceID methodName:method params:params target:self action:@selector(onAlertFinished:)];
                break;
            }
        }
    }
}

- (void)onAlertFinished:(RTNetworkResponse *)response {
    DLog(@"。。。Alert response [%@]", [response content]);
    
}

#pragma mark - private Method

- (NSArray *)rightButtonsIsStar:(BOOL)isStar
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray array];
    
    if (!self.isForMessageList) {
        [rightUtilityButtons sw_addUtilityButtonWithColor:
         [UIColor whiteColor] icon:[self getImageIsStar:isStar]];
        
        [rightUtilityButtons sw_addUtilityButtonWithColor:SYSTEM_RED title:@"删除"];
    }
    
    return rightUtilityButtons;
}

- (UIImage *)getImageIsStar:(BOOL)isStar {
    UIImage *img = [UIImage imageNamed:@"anjuke_icon_noxingbiao_.png"];
    if (isStar) {
        img = [UIImage imageNamed:@"anjuke_icon_xingbiao_.png"];
    }
    
    return img;
}

- (NSArray *)leftButtons
{
    NSMutableArray *leftUtilityButtons = [NSMutableArray array];
    
    return leftUtilityButtons;
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections] count] +2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 0) {
        return self.publicDataArr.count;
    }
    else if (section == 1) {
        return self.starDataArr.count;
    }
    
    return [[self.fetchedResultsController sections][section -2] numberOfObjects];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return CLIENT_LIST_HEIGHT;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"";
    }
    else if (section == 1) {
        if (self.starDataArr.count >0) {
            return @"★星标客户";
        }
        else
            return @"";
    }
    
    if ([[[[self.fetchedResultsController sections] objectAtIndex:section-2] indexTitle] isEqualToString:@"~"]){
        return @"#";
    }
    return [[[self.fetchedResultsController sections] objectAtIndex:section-2] indexTitle];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ClientListCell *cell = (ClientListCell *)[tableView dequeueReusableCellWithIdentifier:nil];
    
    NSArray *rightBtnarr = [NSArray array];
    
    AXMappedPerson *item = nil;
    AXPerson *item2 = nil;
    
    id dataItem = nil;
    
    if (indexPath.section == 0) {
        item = [self.publicDataArr objectAtIndex:indexPath.row];
        dataItem = item;
    }
    if (indexPath.section == 1) {
        item = [self.starDataArr objectAtIndex:indexPath.row];
        rightBtnarr = [self rightButtonsIsStar:YES];
        dataItem = item;
    }
    else if (indexPath.section >= 2) {
        NSIndexPath *newIndex = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section - 2];
        item2 = [self.fetchedResultsController objectAtIndexPath:newIndex];
        rightBtnarr = [self rightButtonsIsStar:[item2.isStar boolValue]];
        
        dataItem = item2;
    }
    
    if (cell == nil) {
        cell = [[ClientListCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:nil
                                  containingTableView:tableView // Used for row height and selection
                                   leftUtilityButtons:[self leftButtons]
                                  rightUtilityButtons:rightBtnarr];
        cell.delegate = self;
    }
    
    [cell setCellHeight:CLIENT_LIST_HEIGHT];
    [cell configureCellWithData:dataItem]; //for test
    
    return cell;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    NSMutableArray *defaultTitles = [[self.fetchedResultsController sectionIndexTitles] mutableCopy];
    if ([defaultTitles containsObject:@"~"]) {
        [defaultTitles removeObject:@"~"];
        [defaultTitles addObject:@"#"];
    }
    return defaultTitles;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    if ([title isEqualToString:@"#"]) {
        title = @"~";
    }
    return [self.fetchedResultsController sectionForSectionIndexTitle:title atIndex:index];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [[BrokerLogger sharedInstance] logWithActionCode:CLIENT_LIST_003 note:nil];
    
    DLog(@"section- [%d]", indexPath.section);
    AXMappedPerson *item = nil;
    
    if (indexPath.section == 0) { //公共账号显示
        item = [self.publicDataArr objectAtIndex:indexPath.row];
        
        if (self.isForMessageList) {
            BrokerChatViewController *controller = [[BrokerChatViewController alloc] init];
            controller.isBroker = YES;
            controller.uid = item.uid;
            [controller setHidesBottomBarWhenPushed:YES];
            [self.navigationController pushViewController:controller animated:YES];
        }
        else {
            ClientDetailPublicViewController *cd = [[ClientDetailPublicViewController alloc] init];
            cd.person = item;
            [cd setHidesBottomBarWhenPushed:YES];
            [self.navigationController pushViewController:cd animated:YES];
        }
    }
    if (indexPath.section > 0) {
        if (indexPath.section == 1) { //星标用户
            item = [self.starDataArr objectAtIndex:indexPath.row];
        }
        else if (indexPath.section >= 2) { //全部用户
            NSIndexPath *newIndex = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section - 2];
            item = [self.fetchedResultsController objectAtIndexPath:newIndex];
        }
        
        if (self.isForMessageList) {
            BrokerChatViewController *controller = [[BrokerChatViewController alloc] init];
            controller.isBroker = YES;
            controller.uid = item.uid;
            [controller setHidesBottomBarWhenPushed:YES];
            [self.navigationController pushViewController:controller animated:YES];
        }
        else {
            if (item.userType == AXPersonTypePublic || [item.uid isEqualToString:@"101"]) {
                ClientDetailPublicViewController *cd = [[ClientDetailPublicViewController alloc] init];
                cd.person = item;
                [cd setHidesBottomBarWhenPushed:YES];
                [self.navigationController pushViewController:cd animated:YES];
            }
            else {
                ClientDetailViewController *cd = [[ClientDetailViewController alloc] init];
                cd.person = item;
                [cd setHidesBottomBarWhenPushed:YES];
                [self.navigationController pushViewController:cd animated:YES];
            }
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - SWTableViewDelegate

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerLeftUtilityButtonWithIndex:(NSInteger)index {
    
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
    NSIndexPath *cellIndexPath = [self.tableViewList indexPathForCell:cell];
    AXMappedPerson *item = nil;
    
    if (cellIndexPath.section == 0) {
        return;
    }
    else if (cellIndexPath.section == 1) {
        item = [self.starDataArr objectAtIndex:cellIndexPath.row];
    }
    else if (cellIndexPath.section >= 2) {
        NSIndexPath *newIndex = [NSIndexPath indexPathForRow:cellIndexPath.row inSection:cellIndexPath.section - 2];
        AXPerson *person = [self.fetchedResultsController objectAtIndexPath:newIndex];
        item = [person convertToMappedPerson];
    }
    [self showLoadingActivity:YES];
    
    switch (index) {
        case 0:
        {
            [[BrokerLogger sharedInstance] logWithActionCode:CLIENT_LIST_004 note:nil];
            
            DLog(@"isStar--section[%d],row-[%d]", cellIndexPath.section, cellIndexPath.row);
            
            item.isStar = !item.isStar;
            [[AXChatMessageCenter defaultMessageCenter] updatePerson:item];
            [[[cell rightUtilityButtons] objectAtIndex:0] setImage:[self getImageIsStar:!item.isStar] forState:UIControlStateNormal];
            
            [self getFriendList];
            break;
        }
        case 1:
        {
            [[BrokerLogger sharedInstance] logWithActionCode:CLIENT_LIST_006 note:nil];
            
            DLog(@"delete--section[%d],row-[%d]", cellIndexPath.section, cellIndexPath.row);
            
            //delete from database
            [[AXChatMessageCenter defaultMessageCenter] removeFriendBydeleteUid:[NSArray arrayWithObject:item.uid] compeletionBlock:^(BOOL isSuccess){
                if (isSuccess) {
                    [self getFriendList];
                }
                else
                    [self showInfo:@"删除客户失败，请再试一次"];
            }];
            break;
        }
        default:
            break;
    }
    
}

- (BOOL)swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:(SWTableViewCell *)cell {
    return YES;
}

@end

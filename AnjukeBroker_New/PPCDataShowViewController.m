//
//  PPCDataShowViewController.m
//  AnjukeBroker_New
//
//  Created by xiazer on 14-7-1.
//  Copyright (c) 2014年 Wu sicong. All rights reserved.
//

#import "PPCDataShowViewController.h"
#import "PPCDataShowCell.h"
#import "PPCPriceingListViewController.h"
#import "PPCSelectedListViewController.h"
#import "HZWaitingForPromotedViewController.h"
#import "ESFWaitingForPromotedViewController.h"
#import "PPCDataShowModel.h"

@interface PPCDataShowViewController ()
@property(nonatomic, strong) NSDictionary *pricingDic;
@property(nonatomic, strong) NSDictionary *selectedDic;
@property(nonatomic, assign) BOOL isLoading;
@end

@implementation PPCDataShowViewController
@synthesize isHaozu;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.pricingDic = [[NSDictionary alloc] init];
        self.selectedDic = [[NSDictionary alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor brokerBgPageColor];
    
    if (self.isHaozu) {
        [self setTitleViewWithString:@"租房"];
    }else{
        [self setTitleViewWithString:@"二手房"];
    }
    [self addRightButton:@"发布" andPossibleTitle:nil];
    
    self.tableList.dataSource = self;
    self.tableList.delegate = self;
    self.tableList.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableList.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.tableList];

    [self autoPullDown];
}


#pragma mark - UITableViewDatasource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (!self.pricingDic) {
        return 0;
    }
    return 6;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0 || indexPath.row == 3) {
        return 15;
    }else if (indexPath.row == 1 || indexPath.row == 2){
        return 150;
    }else if (indexPath.row == 4){
        return 45;
    }else{
        return 30;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identify1 = @"cell1";
    static NSString *identify2 = @"cell2";
    
    if (indexPath.row == 1 || indexPath.row == 2) {
        PPCDataShowCell *cell = [tableView dequeueReusableCellWithIdentifier:identify1];
        if (!cell) {
            cell = [[PPCDataShowCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identify1];
        }
        if (indexPath.row == 1) {
            [cell showTopLine];
            cell.isPricing = YES;
            [cell showBottonLineWithCellHeight:150 andOffsetX:15];
            
            if (self.pricingDic && self.pricingDic[@"data"]) {
                PPCDataShowModel *model = [PPCDataShowModel convertToMappedObject:self.pricingDic[@"data"]];
                [cell configureCell:model withIndex:indexPath.row];
            }else{
                [cell configureCell:nil withIndex:indexPath.row];
            }
        }else{
            cell.isPricing = NO;
            [cell showBottonLineWithCellHeight:150];

            if (self.selectedDic && self.selectedDic[@"data"]) {
                PPCDataShowModel *model = [PPCDataShowModel convertToMappedObject:self.selectedDic[@"data"]];
                [cell configureCell:model withIndex:indexPath.row];
            }else{
                [cell configureCell:nil withIndex:indexPath.row];
            }
        }
        return cell;
    }else{
        RTListCell *cell = [tableView dequeueReusableCellWithIdentifier:identify2];
        if (!cell) {
            cell = [[RTListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identify2];
        }
        if ((indexPath.row == 0 || indexPath.row == 3)) {
            cell.backgroundColor = [UIColor clearColor];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }else if (indexPath.row == 4){
            [cell showTopLine];
            [cell showBottonLineWithCellHeight:45];
            cell.textLabel.text = @"待推广房源";
            cell.textLabel.textColor = [UIColor brokerBlackColor];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
        }else if (indexPath.row == 5){
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.backgroundColor = [UIColor clearColor];
            
            UILabel *lab = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 300, 30)];
            lab.backgroundColor = [UIColor clearColor];
            lab.textAlignment = NSTextAlignmentRight;
            lab.textColor = [UIColor brokerLightGrayColor];
            lab.text = @"以上均为今日数据";
            lab.font = [UIFont ajkH5Font];
            [cell.contentView addSubview:lab];
        }
        
        return cell;
    }
}

#pragma mark -- UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.navigationController.view.frame.origin.x > 0) {
        return;
    }
    
    if (indexPath.row == 1) {

        if (self.pricingDic[@"data"] && self.pricingDic[@"data"][@"planId"]) {
            PPCPriceingListViewController *pricingListVC = [[PPCPriceingListViewController alloc] init];
            pricingListVC.isHaozu = self.isHaozu;
            pricingListVC.planId = self.pricingDic[@"data"][@"planId"];
            [self.navigationController pushViewController:pricingListVC animated:YES];
        }else{
            return;
        }
    }else if (indexPath.row == 2){
//        if (self.selectedDic[@"data"] && self.selectedDic[@"data"][@"planId"]) {
//            PPCSelectedListViewController *selectedListVC = [[PPCSelectedListViewController alloc] init];
//            selectedListVC.isHaozu = self.isHaozu;
//            [self.navigationController pushViewController:selectedListVC animated:YES];
//            selectedListVC.planId = self.selectedDic[@"data"][@"planId"];
//        }else{
//            return;
//        }
        PPCSelectedListViewController *selectedListVC = [[PPCSelectedListViewController alloc] init];
        selectedListVC.isHaozu = self.isHaozu;
        [self.navigationController pushViewController:selectedListVC animated:YES];
        selectedListVC.planId = self.selectedDic[@"data"][@"planId"];

    } else if (indexPath.row == 4) {
        if (self.isHaozu) {
            HZWaitingForPromotedViewController *hzToBePromoted = [[HZWaitingForPromotedViewController alloc] init];
            [self.navigationController pushViewController:hzToBePromoted animated:YES];
        } else {
            ESFWaitingForPromotedViewController *esfToBePromoted = [[ESFWaitingForPromotedViewController alloc] init];
            [self.navigationController pushViewController:esfToBePromoted animated:YES];
        }
    }
}

- (void)doRequest{
    self.isLoading = YES;
    NSMutableDictionary *params = nil;
    NSString *method = @"batch/";
    if (self.isHaozu) {
        NSMutableDictionary *requeseParams1 = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[LoginManager getToken],@"token",[LoginManager getUserID],@"brokerId",[LoginManager getCity_id],@"cityId", nil];
        
        NSMutableDictionary *dic1 = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                              @"GET",@"method",
                              @"zufang/fix/summary/",@"relative_url",
                              requeseParams1,@"query_params",nil];
        
        NSMutableDictionary *requeseParams2 = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[LoginManager getToken],@"token",[LoginManager getUserID],@"brokerId",[LoginManager getCity_id],@"cityId", nil];

        NSMutableDictionary *dic2 = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     @"GET",@"method",
                                     @"zufang/choice/summary/",@"relative_url",
                                     requeseParams2,@"query_params",nil];
        
        NSMutableDictionary *dics = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     dic1, @"fix",
                                     dic2, @"choice", nil];
        
        params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                  dics, @"requests", nil];
    }else{
        NSMutableDictionary *requeseParams1 = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[LoginManager getToken],@"token",[LoginManager getUserID],@"brokerId",[LoginManager getCity_id],@"cityId", nil];
        
        NSMutableDictionary *dic1 = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     @"GET",@"method",
                                     @"anjuke/fix/summary/",@"relative_url",
                                     requeseParams1,@"query_params",nil];
        
        NSMutableDictionary *requeseParams2 = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[LoginManager getToken],@"token",[LoginManager getUserID],@"brokerId",[LoginManager getCity_id],@"cityId", nil];
        
        NSMutableDictionary *dic2 = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     @"GET",@"method",
                                     @"anjuke/choice/summary/",@"relative_url",
                                     requeseParams2,@"query_params",nil];
        
        NSMutableDictionary *dics = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     dic1, @"fix",
                                     dic2, @"choice", nil];
        
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dics
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:nil];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData
                                                     encoding:NSUTF8StringEncoding];

        
        params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                  jsonString, @"requests", nil];
    }
    [[RTRequestProxy sharedInstance] asyncRESTPostWithServiceID:RTBrokerRESTServiceID methodName:method params:params target:self action:@selector(onRequestFinished:)];
}
- (void)onRequestFinished:(RTNetworkResponse *)response{
    self.isLoading = NO;
    DLog(@"response---->>%@",[response content]);
    if([[response content] count] == 0){
        [self donePullDown];
        [self.tableList setTableStatus:STATUSFORNODATAFORPRICINGLIST];
        
        UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGus:)];
        tapGes.delegate                = self;
        tapGes.numberOfTouchesRequired = 1;
        tapGes.numberOfTapsRequired    = 1;
        [self.tableList.tableHeaderView addGestureRecognizer:tapGes];
        
        self.pricingDic = nil;
        self.selectedDic = nil;
        [self.tableList reloadData];
        
        return ;
    }
    if ([response status] == RTNetworkResponseStatusFailed || [[[response content] objectForKey:@"status"] isEqualToString:@"error"]) {
        DLog(@"message--->>%@",[[response content] objectForKey:@"message"]);
        
        [self.tableList setTableStatus:STATUSFORNETWORKERROR];
        
        UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGus:)];
        tapGes.delegate                = self;
        tapGes.numberOfTouchesRequired = 1;
        tapGes.numberOfTapsRequired    = 1;
        [self.tableList.tableHeaderView addGestureRecognizer:tapGes];
        
        self.pricingDic = nil;
        self.selectedDic = nil;
        [self.tableList reloadData];
        
        [self donePullDown];
        return;
    }
    
    [self donePullDown];
    
    self.pricingDic = [[response content][@"fix"][@"body"] JSONValue];
    self.selectedDic = [[response content][@"choice"][@"body"] JSONValue];
    
    NSIndexPath *path1 = [NSIndexPath indexPathForItem:1 inSection:0];
    NSIndexPath *path2 = [NSIndexPath indexPathForItem:2 inSection:0];
    
    [self.tableList reloadRowsAtIndexPaths:[NSArray arrayWithObjects:path1, nil] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableList reloadRowsAtIndexPaths:[NSArray arrayWithObjects:path2, nil] withRowAnimation:UITableViewRowAnimationNone];
}
- (void)tapGus:(UITapGestureRecognizer *)gesture{
    [self autoPullDown];
}
#pragma mark -- rightButton
- (void)rightButtonAction:(id)sender{
    if (self.isHaozu) {
        
    }else{
        
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
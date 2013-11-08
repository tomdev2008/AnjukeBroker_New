//
//  AJK_AnjukeHomeViewController.m
//  AnjukeBroker_New
//
//  Created by Wu sicong on 13-10-21.
//  Copyright (c) 2013年 Wu sicong. All rights reserved.
//

#import "AnjukeHomeViewController.h"
#import "SaleNoPlanGroupController.h"
#import "SaleFixedDetailController.h"
#import "SaleBidDetailController.h"
#import "PPCGroupCell.h"
#import "LoginManager.h"
#import "SaleFixedManager.h"

@interface AnjukeHomeViewController ()

@end

@implementation AnjukeHomeViewController
@synthesize myTable;
@synthesize myArray;

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
    
    [self setTitleViewWithString:@"二手房"];
    

    self.myTable = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
//    self.myTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.myTable.delegate = self;
    self.myTable.dataSource = self;
    [self.view addSubview:self.myTable];

    
    
	// Do any additional setup after loading the view.
    
//    self.view.backgroundColor = [UIColor yellowColor];
}
-(void)dealloc{
    self.myTable.delegate = nil;
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self reloadData];
    [self doRequest];
}
-(void)reloadData{
    self.myArray = [NSMutableArray array];
//    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
//    [dic setValue:@"竞价房源" forKey:@"title"];
//    [dic setValue:@"房源数：0套" forKey:@"detail"];
//    [dic setValue:@"" forKey:@"status"];
//    [dic setValue:@"1" forKey:@"type"];
//    [self.myArray addObject:dic];


}
-(void)doRequest{
    if(![self isNetworkOkay]){
        return;
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:[LoginManager getToken], @"token", [LoginManager getUserID], @"brokerId", nil];
    [[RTRequestProxy sharedInstance] asyncRESTPostWithServiceID:RTBrokerRESTServiceID methodName:@"anjuke/prop/ppc/" params:params target:self action:@selector(onGetLogin:)];
    [self showLoadingActivity:YES];
}

- (void)onGetLogin:(RTNetworkResponse *)response {
    
    if ([response status] == RTNetworkResponseStatusFailed || [[[response content] objectForKey:@"status"] isEqualToString:@"error"]) {
        NSString *errorMsg = [NSString stringWithFormat:@"%@",[[response content] objectForKey:@"message"]];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"请求失败" message:errorMsg delegate:self cancelButtonTitle:@"确认" otherButtonTitles:nil, nil];
        [alert show];
        [self hideLoadWithAnimated:YES];
        return;
    }
    DLog(@"------response [%@]", [response content]);
    [self.myArray removeAllObjects];
    NSDictionary *resultFromAPI = [NSDictionary dictionaryWithDictionary:[[response content] objectForKey:@"data"]];
    NSMutableDictionary *dicPlan = [[NSMutableDictionary alloc] initWithDictionary:[[resultFromAPI objectForKey:@"bidPlan"] objectAtIndex:0]];
    [self.myArray addObject:dicPlan];
    
    NSMutableArray *pricePlan = [NSMutableArray array];
    [pricePlan addObjectsFromArray:[resultFromAPI objectForKey:@"pricPlan"]];
    [self.myArray addObjectsFromArray:pricePlan];
    
    NSMutableDictionary *nodic = [[NSMutableDictionary alloc] init];
    [nodic setValue:@"待推广房源" forKey:@"title"];
    [nodic setValue:[resultFromAPI objectForKey:@"unRecommendPropNum"] forKey:@"unRecommendPropNum"];
    [nodic setValue:@"3" forKey:@"status"];
    [nodic setValue:@"3" forKey:@"type"];
    [self.myArray addObject:nodic];
    
    [self.myTable reloadData];
    [self hideLoadWithAnimated:YES];
}
//-(void)doRequestPlans{
//    
//    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:[LoginManager getToken], @"token", [LoginManager getUserID], @"brokerId", nil];
//    [[RTRequestProxy sharedInstance] asyncRESTPostWithServiceID:RTBrokerRESTServiceID methodName:@"anjuke/fix/getplans/" params:params target:self action:@selector(onSuccess:)];
//    
//}
//
//- (void)onSuccess:(RTNetworkResponse *)response {
//    DLog(@"------response [%@]", [[response content] JSONRepresentation]);
//    DLog(@"------response [%@]", [response content]);
//    
//    if ([response status] == RTNetworkResponseStatusFailed || [[[response content] objectForKey:@"status"] isEqualToString:@"error"]) {
//        
//        NSString *errorMsg = [NSString stringWithFormat:@"%@",[[response content] objectForKey:@"message"]];
//        
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"登录失败" message:errorMsg delegate:self cancelButtonTitle:@"确认" otherButtonTitles:nil, nil];
//        [alert show];
//        return;
//    }
//    
//    NSDictionary *resultFromAPI = [NSDictionary dictionaryWithDictionary:[[response content] objectForKey:@"data"]];
//    if (([[resultFromAPI objectForKey:@"count"] integerValue] == 0 || resultFromAPI == nil)) {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"没有找到数据" delegate:self cancelButtonTitle:@"确认" otherButtonTitles:nil, nil];
//        [alert show];
//        [self.myArray removeAllObjects];
//        [self.myTable reloadData];
//        return;
//    }
//    NSMutableArray *result = [SaleFixedManager propertyObjectArrayFromDicArray:[resultFromAPI objectForKey:@"plan"]];
//    NSDictionary *dic = [[NSDictionary alloc] initWithDictionary:[self.myArray lastObject]];
//    [self.myArray removeLastObject];
//    [self.myArray addObjectsFromArray:result];
//    [self.myArray addObject:dic];
//    [self.myTable reloadData];
////    [self.myTable reloadData];
//}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

    if([indexPath row] == 0)
    {
        SaleBidDetailController *controller = [[SaleBidDetailController alloc] init];
        controller.backType = RTSelectorBackTypePopToRoot;
        [controller setHidesBottomBarWhenPushed:YES];
        [self.navigationController pushViewController:controller animated:YES];
    }else if ([indexPath row] == [self.myArray count] - 1){
        SaleNoPlanGroupController *controller = [[SaleNoPlanGroupController alloc] init];
        [controller setHidesBottomBarWhenPushed:YES];
        [self.navigationController pushViewController:controller animated:YES];
    }else{
        SaleFixedDetailController *controller = [[SaleFixedDetailController alloc] init];
        controller.tempDic = [self.myArray objectAtIndex:indexPath.row];
        controller.backType = RTSelectorBackTypePopToRoot;
        [controller setHidesBottomBarWhenPushed:YES];
        [self.navigationController pushViewController:controller animated:YES];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.myArray count];
}
-(float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 66.0f;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellIdent = @"cell";
    
    PPCGroupCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdent];
    if(cell == nil){
        cell = [[NSClassFromString(@"PPCGroupCell") alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdent];
    }
    [cell setValueForCellByData:self.myArray index:indexPath.row];
//    [cell setValueForCellByData:[self.myArray objectAtIndex:[indexPath row]]];
//    [cell setValueForCellByDictinary:[self.myArray objectAtIndex:[indexPath row]]];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

//-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
//    UIView *content = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 100)];
//    content.backgroundColor = [UIColor lightGrayColor];
//    
//    UILabel *headerLab = [[UILabel alloc] initWithFrame:CGRectMake(30, 10, 50, 20)];
//    headerLab.backgroundColor = [UIColor clearColor];
//    headerLab.text = @"10";
//    [content addSubview:headerLab];
//    
//    headerLab = [[UILabel alloc] initWithFrame:CGRectMake(20, 45, 320, 20)];
//    headerLab.text = @"在线房源";
//    [content addSubview:headerLab];
//    
//    headerLab = [[UILabel alloc] initWithFrame:CGRectMake(130, 10, 50, 20)];
//    headerLab.text = @"100";
//    [content addSubview:headerLab];
//    
//    headerLab = [[UILabel alloc] initWithFrame:CGRectMake(120, 45, 320, 20)];
//    headerLab.text = @"今日已点击";
//    [content addSubview:headerLab];
//    
//    headerLab = [[UILabel alloc] initWithFrame:CGRectMake(230, 10, 50, 20)];
//    headerLab.text = @"99.0";
//    [content addSubview:headerLab];
//    
//    headerLab = [[UILabel alloc] initWithFrame:CGRectMake(220, 45, 320, 20)];
//    headerLab.text = @"今日花费(元)";
//    [content addSubview:headerLab];
//    
//    return content;
//}
//-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
//    return 100;
//}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

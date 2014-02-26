//
//  ClientListViewController.m
//  AnjukeBroker_New
//
//  Created by paper on 14-2-18.
//  Copyright (c) 2014年 Wu sicong. All rights reserved.
//

#import "ClientListViewController.h"
#import "ClientDetailViewController.h"
#import "Util_UI.h"
#import "AXChatMessageCenter.h"
#import "AXMappedPerson.h"

@interface ClientListViewController ()

@property (nonatomic, strong) UITableView *tableViewList;
@property (nonatomic, strong) NSMutableArray *listDataArray;

@property (nonatomic, strong) NSMutableArray *publicDataArr; //公共账号列表
@property (nonatomic, strong) NSMutableArray *starDataArr; //星标客户列表
@property (nonatomic, strong) NSMutableArray *allDataArr; //所有客户列表

@property (nonatomic, strong) NSArray *testArr;

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

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self setTitleViewWithString:@"我的客户"];
    
    [self getFriendList];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self redrawList];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)getFriendList {
    [[AXChatMessageCenter defaultMessageCenter] friendListWithPersonWithCompeletionBlock:^(NSArray *friendList, BOOL whetherSuccess) {
        if (whetherSuccess) {
            DLog(@"friendList- [%@]", friendList);
            
            self.testArr = [NSArray arrayWithArray:friendList];
            [self redrawList];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
            });
        }
    }];
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
//    tv.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:tv];

}

- (void)redrawList {
    self.listDataArray = [NSMutableArray array];
    
    //reset 3 list arr ...
    //获取公共账号
    for (int i = 0; i < self.testArr.count; i++) {
        AXMappedPerson *item = [self.testArr objectAtIndex:i];
        
        if ([item.userType integerValue] == AXPersonTypePublic) {
            [self.publicDataArr addObject:item];
        }
    }
    //非公共账号处理
    for (int i = 0; i < self.testArr.count; i ++) {
        AXMappedPerson *item = [self.testArr objectAtIndex:i];
        
        if ([item.userType integerValue] == AXPersonTypeUser) {
            [self.allDataArr addObject:item]; //所有用户
            
            if ((BOOL)[item.isStar integerValue] == YES) {
                [self.starDataArr addObject:item]; //星标用户
            }
        }
    }
    
    //add 3 arr to list data att
    [self.listDataArray addObject:self.publicDataArr];
    [self.listDataArray addObject:self.starDataArr];
    [self.listDataArray addObject:self.allDataArr];
    
    [self.tableViewList reloadData];
}

#pragma mark - private Method

- (NSArray *)rightButtonsIsStar:(BOOL)isStar
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray array];
    
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor whiteColor] icon:[self getImageIsStar:isStar]];
    
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     SYSTEM_ZZ_RED icon:[UIImage imageNamed:@"anjuke_icon_delete_.png"]];
    
    return rightUtilityButtons;
}

- (UIImage *)getImageIsStar:(BOOL)isStar {
    UIImage *img = [UIImage imageNamed:@"anjuke_icon_noxingbiao_.png"];
    if (isStar) {
        img = [UIImage imageNamed:@"anjuke_icon_noxingbiao_.png"];
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
    return self.listDataArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [(NSArray *)[self.listDataArray objectAtIndex:section] count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return CLIENT_LIST_HEIGHT;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return @"";
            break;
        case 1:
            return @"★星标客户";
            break;
        case 2:
            return @"全部客户";
            break;
            
        default:
            break;
    }
    
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ClientListCell *cell = (ClientListCell *)[tableView dequeueReusableCellWithIdentifier:nil];
    
    NSArray *rightBtnarr = [NSArray array];
    AXMappedPerson *item = [[self.listDataArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    if (indexPath.section == 1) {
        rightBtnarr = [self rightButtonsIsStar:YES];
    }
    else if (indexPath.section == 2) {
        rightBtnarr = [self rightButtonsIsStar:(BOOL)[item.isStar integerValue]];
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
    [cell configureCellWithData:[[self.listDataArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row]]; //for test
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 0;
    }
    else if (section == 1) {
        if (self.starDataArr.count > 0) {
            return 20;
        }
        else
            return 0;
    }
    else if (section == 2) {
        if (self.allDataArr.count > 0) {
            return 20;
        }
        else
            return 0;
    }
    
    return 20;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    DLog(@"section- [%d]", indexPath.section);
    
    //for test
    ClientDetailViewController *cd = [[ClientDetailViewController alloc] init];
    [cd setHidesBottomBarWhenPushed:YES];
    [self.navigationController pushViewController:cd animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - SWTableViewDelegate

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerLeftUtilityButtonWithIndex:(NSInteger)index {
    
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
    NSIndexPath *cellIndexPath = [self.tableViewList indexPathForCell:cell];
    AXMappedPerson *item = [[self.listDataArray objectAtIndex:cellIndexPath.section] objectAtIndex:cellIndexPath.row];
    
    switch (index) {
        case 0:
        {
            DLog(@"More button was pressed--index[%d, %d]", cellIndexPath.section, cellIndexPath.row);
            
            [[[cell rightUtilityButtons] objectAtIndex:0] setImage:[self getImageIsStar:!(BOOL)item.isStar] forState:UIControlStateNormal];
            
            break;
        }
        case 1:
        {
            // Delete button was pressed
            [self.tableViewList beginUpdates];
            [cell hideUtilityButtonsAnimated:NO];
            
            [self.listDataArray[cellIndexPath.section] removeObjectAtIndex:cellIndexPath.row];
            [self.tableViewList deleteRowsAtIndexPaths:@[cellIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableViewList endUpdates];
            
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
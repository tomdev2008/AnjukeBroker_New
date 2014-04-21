//
//  PublishFeatureViewController.m
//  AnjukeBroker_New
//
//  Created by paper on 14-4-21.
//  Copyright (c) 2014年 Wu sicong. All rights reserved.
//

#import "PublishFeatureViewController.h"
#import "AnjukeFeatureCell.h"

@interface PublishFeatureViewController ()

@property (nonatomic, strong) UITableView *tableViewList;

@end

@implementation PublishFeatureViewController

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
    
    [self setTitleViewWithString:@"特色"];
}

- (void)dealloc {
    self.tableViewList.delegate = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)initModel {
    
}

- (void)initDisplay {
    UITableView *tv = [[UITableView alloc] initWithFrame:FRAME_WITH_NAV style:UITableViewStylePlain];
    tv.backgroundColor = [UIColor clearColor];
    tv.dataSource = self;
    tv.delegate = self;
    tv.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableViewList = tv;
    [self.view addSubview:tv];
}

#pragma mark - UITableViewDataSource && UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return CELL_HEIGHT;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellStr = @"cell";
    
    AnjukeFeatureCell *cell = [tableView dequeueReusableCellWithIdentifier:cellStr];
    if (cell == nil) {
        cell = [[AnjukeFeatureCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellStr];
    }
    
    switch (indexPath.row) {
        case 0:
        {
            cell.titleLb.text = @"满五年";
            [cell showTopLine];
        }
            break;
        case 1:
        {
            cell.titleLb.text = @"唯一住房";
        }
            break;
            
        default:
            break;
    }
    
    [cell showBottonLineWithCellHeight:CELL_HEIGHT];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end

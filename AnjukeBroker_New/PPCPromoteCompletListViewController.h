//
//  PPCPromoteCompletListViewController.h
//  AnjukeBroker_New
//
//  Created by xiazer on 14-7-3.
//  Copyright (c) 2014年 Anjuke. All rights reserved.
//

#import "BaseTableStructViewController.h"
#import "PPCHouseCell.h"
#import "PropertySingleViewController.h"

@interface PPCPromoteCompletListViewController : BaseTableStructViewController<UITableViewDataSource,UITableViewDelegate,SWTableViewCellDelegate,CHOICESUCCUSSDELEGATE>
@property(nonatomic, assign) BOOL isHaozu;
@property(nonatomic, strong) NSMutableArray *tableData;
@end

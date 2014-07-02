//
//  PPCSelectedListCell.m
//  AnjukeBroker_New
//
//  Created by xiazer on 14-7-2.
//  Copyright (c) 2014年 Wu sicong. All rights reserved.
//

#import "PPCSelectedListCell.h"
#import "HouseCellView.h"

@interface PPCSelectedListCell ()
@property(nonatomic, strong) HouseCellView *cellView;
@end

@implementation PPCSelectedListCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self initUI];
    }
    return self;
}

- (void)initUI{
    self.cellView = [[HouseCellView alloc] initWithFrame:self.bounds];
    [self.contentView addSubview:self.cellView];
}

- (BOOL)configureCell:(id)dataModel withIndex:(int)index{
    [self.cellView configCellViewWithData:dataModel];
    return YES;
}
@end
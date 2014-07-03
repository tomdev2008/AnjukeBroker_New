//
//  MultipleChoiceAndEditListCell.h
//  AnjukeBroker_New
//
//  Created by xubing on 14-7-1.
//  Copyright (c) 2014年 Wu sicong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RTListCell.h"
#import "SWTableViewCell.h"

@protocol CellSelectStatus <NSObject>

- (void)cellStatusChanged:(BOOL)isSelect atRowIndex:(NSInteger)rowIndex;

@end

@class PropertyDetailCellModel;

@interface MultipleChoiceAndEditListCell : SWTableViewCell

@property (nonatomic, strong) PropertyDetailCellModel* propertyDetailTableViewCellModel;
@property (nonatomic, strong) id<CellSelectStatus> delegate;
@property (nonatomic) NSInteger rowIndex;

- (void)changeCellSelectStatus:(BOOL)isSelected;


@end

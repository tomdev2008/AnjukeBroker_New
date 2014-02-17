//
//  PublishBigImageViewController.h
//  AnjukeBroker_New
//
//  Created by paper on 14-1-26.
//  Copyright (c) 2014年 Wu sicong. All rights reserved.
//

#import "RTViewController.h"

@protocol PublishBigImageViewClickDelegate <NSObject>

- (void)viewDidFinishWithImageArr:(NSArray *)imageArray;
- (void)onlineHouseTypeImgDelete;

- (void)editPropertyDidDeleteImgWithDeleteIndex:(int)deleteIndex;

@end

@interface PublishBigImageViewController : RTViewController <UIScrollViewDelegate, UIAlertViewDelegate>

@property (nonatomic, assign) id <PublishBigImageViewClickDelegate> clickDelegate;

@property BOOL isEditProperty; //是否是编辑房源，是则单张显示编辑图片，点击删除返回
@property int editDeleteImgIndex; //删除房源对应的index，便于通知
@property BOOL isNewAddImg; //编辑房源是否是新添加图片

- (void)showImagesWithArray:(NSArray *)imageArr atIndex:(int)index;
- (void)showImagesForOnlineHouseTypeWithDic:(NSDictionary *)dic;

@end
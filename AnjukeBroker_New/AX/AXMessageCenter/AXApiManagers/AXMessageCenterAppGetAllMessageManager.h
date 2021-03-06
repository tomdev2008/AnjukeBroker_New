//
//  AXMessageCenterAppGetAllMessageManager.h
//  Anjuke2
//
//  Created by 杨 志豪 on 14-3-5.
//  Copyright (c) 2014年 anjuke inc. All rights reserved.
//

#import "RTAPIBaseManager.h"

@interface AXMessageCenterAppGetAllMessageManager : RTAPIBaseManager<RTAPIManagerValidator,RTAPIManagerParamSourceDelegate>
@property (nonatomic, strong) NSDictionary *apiParams;
@property (nonatomic, copy) NSString *uniqLongLinkId;
@end

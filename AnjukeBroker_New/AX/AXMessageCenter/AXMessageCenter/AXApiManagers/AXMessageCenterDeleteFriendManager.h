//
//  AXMessageCenterDeleteFriendManager.h
//  Anjuke2
//
//  Created by 杨 志豪 on 14-2-26.
//  Copyright (c) 2014年 anjuke inc. All rights reserved.
//

#import "RTAPIBaseManager.h"

@interface AXMessageCenterDeleteFriendManager : RTAPIBaseManager<RTAPIManagerValidator,RTAPIManagerParamSourceDelegate>
@property (nonatomic, strong) NSDictionary *apiParams;
@end

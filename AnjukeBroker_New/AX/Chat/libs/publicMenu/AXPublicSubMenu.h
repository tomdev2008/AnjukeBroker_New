//
//  AXPublicSubMenu.h
//  AnjukeBroker_New
//
//  Created by xiazer on 14-6-13.
//  Copyright (c) 2014年 Anjuke. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AXPublicMenuButton.h"

typedef NS_ENUM(NSInteger, AXPublicSubMenuType) {
//    AXPublicSubMenuTypeSubMenu = 0,
    AXPublicSubMenuTypeAPI = 2,
    AXPublicSubMenuTypeWebView = 3
};

@protocol AXPublicSubMenuDelegate <NSObject>
@optional
- (void)publicSubMenuWithAPI:(AXPublicMenuButton *)button actionStr:(NSString *)actionStr;
- (void)publicSubMenuWithURL:(AXPublicMenuButton *)button webURL:(NSString *)webURL;
@end


@interface AXPublicSubMenu : UIView
@property(nonatomic, assign) id<AXPublicSubMenuDelegate> publicSubMenuDelegate;
@property(nonatomic, assign) NSInteger subMenuindex;
- (void)configPublicSubMenu:(AXPublicMenuButton *)button menu:(NSArray *)menus;

@end

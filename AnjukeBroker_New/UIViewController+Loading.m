//
//  UIViewController+Loading.m
//  AnjukeBroker_New
//
//  Created by Wu sicong on 13-11-8.
//  Copyright (c) 2013年 Wu sicong. All rights reserved.
//

#import "UIViewController+Loading.h"

@implementation UIViewController (Loading)

- (void)hideLoadWithAnimated:(BOOL)animated{
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}

- (void)showLoadingActivity:(BOOL)activity{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"加载中...";
}

- (void)showInfo:(NSString *)info{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = info;
    
    [hud hide:YES afterDelay:2];
}

@end

//
//  RTGestureLock.m
//  AnjukeBroker_New
//
//  Created by xiazer on 14-4-16.
//  Copyright (c) 2014年 Wu sicong. All rights reserved.
//

#import "RTGestureLock.h"
#import "RTGestureBackNavigationController.h"

@implementation RTGestureLock

+ (void)setDisableGestureForBack:(UINavigationController *)nav disable:(BOOL)disable{
    RTGestureBackNavigationController *passNav = (RTGestureBackNavigationController*)nav;
    passNav.disableGestureForBack = YES;
}
@end
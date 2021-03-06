//
//  UIImage+AXChatMessage.m
//  Anjuke2
//
//  Created by Gin on 2/24/14.
//  Copyright (c) 2014 anjuke inc. All rights reserved.
//

#import "UIImage+AXChatMessage.h"

@implementation UIImage (AXChatMessage)

+ (UIImage *)axChatDefaultAvatar:(BOOL)isBroker
{
    if (isBroker) {
        return [UIImage imageNamed:@"xproject_dialogue_me.png"];
    } else {
        return [UIImage imageNamed:@"xproject_dialogue_me.png"];
    }
}

+ (UIImage *)axChatError:(BOOL)isBroker
{
    if (isBroker) {
        return [UIImage imageNamed:@"anjuke_icon_attention.png"];
    } else {
        return [UIImage imageNamed:@"xproject_dialogue_failedsending.png"];
    }
}

+ (UIImage *)axInChatBubbleBg:(BOOL)isBroker highlighted:(BOOL)highlighted
{
    if (isBroker) {
        if (highlighted) {
            return [UIImage imageNamed:@"anjuke_icon_chat1.png"];
        } else {
            return [UIImage imageNamed:@"anjuke_icon_chat.png"];
        }
    } else {
        if (highlighted) {
            return [UIImage imageNamed:@"xproject_dialogue_greenbox_selected.png"];
        } else {
            return [UIImage imageNamed:@"xproject_dialogue_greenbox.png"];
        }
    }
}

+ (UIImage *)axOutChatBubbleBg:(BOOL)isBroker highlighted:(BOOL)highlighted
{
    if (isBroker) {
        if (highlighted) {
            return [UIImage imageNamed:@"anjuke_icon_chat3.png"];
        } else {
            return [UIImage imageNamed:@"anjuke_icon_chat2.png"];
        }
    } else {
        if (highlighted) {
            return [UIImage imageNamed:@"xproject_dialogue_greybox_selected.png"];
        } else {
            return [UIImage imageNamed:@"xproject_dialogue_greybox.png"];
        }
    }
}


+ (UIImage *)axInChatPropBubbleBg:(BOOL)isBroker highlighted:(BOOL)highlighted
{
    if (isBroker) {
        if (highlighted) {
            return [UIImage imageNamed:@"anjuke_icon_chat_fy1.png"];
        } else {
            return [UIImage imageNamed:@"anjuke_icon_chat_fy.png"];
        }
    } else {
        if (highlighted) {
            return [UIImage imageNamed:@"xproject_dialogue_greencard_selected.png"];
        } else {
            return [UIImage imageNamed:@"xproject_dialogue_greencard.png"];
        }
    }
}

+ (UIImage *)axOutChatPropBubbleBg:(BOOL)isBroker highlighted:(BOOL)highlighted
{
    if (isBroker) {
        if (highlighted) {
            return [UIImage imageNamed:@"anjuke_icon_chat2_fy_selected.png"];
        } else {
            return [UIImage imageNamed:@"anjuke_icon_chat2_fy.png"];
        }
    } else {
        if (highlighted) {
            return [UIImage imageNamed:@"xproject_dialogue_greycard_selected.png"];
        } else {
            return [UIImage imageNamed:@"xproject_dialogue_greycard.png"];
        }
    }
}

@end

//
//  PropertyObject.m
//  AnjukeBroker_New
//
//  Created by jianzhongliu on 10/29/13.
//  Copyright (c) 2013 Wu sicong. All rights reserved.
//

#import "BasePropertyObject.h"

@implementation BasePropertyObject
@synthesize propertyId;
@synthesize cpip;
@synthesize photos;
@synthesize defaultImgUrl;
@synthesize communityName;
@synthesize communityId;
@synthesize type;
@synthesize area;
@synthesize title;
@synthesize description;
@synthesize tenement;
@synthesize floor;
@synthesize mark;
@synthesize communityTag;
@synthesize propertyTag;
@synthesize propertyType;
@synthesize orientation;
@synthesize price;
@synthesize priceUnit;
@synthesize hallNum;
@synthesize roomNum;
@synthesize toiletNum;
@synthesize isMoreImg;
@synthesize isVisible;

- (id)setValueFromDictionary:(NSDictionary *)dic{
    
    self.propertyId = [dic objectForKey:@"id"];
    self.cpip = [dic objectForKey:@""];
    self.photos = [dic objectForKey:@""];
    self.defaultImgUrl = [dic objectForKey:@"defaultImgUrl"];
    self.communityName = [dic objectForKey:@"commName"];
    self.communityId = [dic objectForKey:@""];
    self.type = [dic objectForKey:@"housUnits"];
    self.area = [NSString stringWithFormat:@"%@", [dic objectForKey:@"area"]];
    self.title = [dic objectForKey:@"title"];
    self.description = [dic objectForKey:@""];
    self.tenement = [dic objectForKey:@""];
    self.floor = [dic objectForKey:@""];
    self.mark = [dic objectForKey:@""];
    self.communityTag = [dic objectForKey:@""];
    self.propertyTag = [dic objectForKey:@""];
    self.propertyType = [dic objectForKey:@""];
    self.orientation = [dic objectForKey:@""];
    self.price = [dic objectForKey:@"price"];
    self.priceUnit = [dic objectForKey:@"priceUnit"];
    self.hallNum = [dic objectForKey:@"hallNum"];
    self.roomNum = [dic objectForKey:@"roomNum"];
    self.toiletNum = [dic objectForKey:@"toiletNum"];
    self.isMoreImg = [dic objectForKey:@"isMoreImg"];
    self.isVisible = [dic objectForKey:@"isVisible"];
    return self;
}

@end

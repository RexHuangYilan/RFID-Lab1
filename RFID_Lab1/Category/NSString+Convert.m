//
//  NSString+Convert.m
//  RFID_Lab1
//
//  Created by Rex on 2017/12/9.
//  Copyright © 2017年 Rex. All rights reserved.
//


#import "NSString+Convert.h"


static NSString *const dateFormat = @"yyyy-MM-dd";

@implementation NSString (Convert)

#pragma mark - Date

+(NSString *)stringWithDate:(NSDate *)date
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:dateFormat];
    NSString *strDate = [dateFormatter stringFromDate:date];
    return strDate;
}

-(NSDate *)date
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:dateFormat];
    NSDate *date = [dateFormatter dateFromString:self];
    return date;
}

#pragma mark - variable

+(NSString *)stringWithInteger:(NSInteger)integer
{
    return [NSString stringWithFormat:@"%ld",(long)integer];
}

@end

//
//  NSString+Convert.h
//  RFID_Lab1
//
//  Created by Rex on 2017/12/9.
//  Copyright © 2017年 Rex. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Convert)

#pragma mark - Date

+(NSString *_Nullable)stringWithDate:(NSDate * _Nonnull)date;

-(NSDate *_Nullable)date;

#pragma mark - variable

+(NSString *_Nonnull)stringWithInteger:(NSInteger)integer;

@end

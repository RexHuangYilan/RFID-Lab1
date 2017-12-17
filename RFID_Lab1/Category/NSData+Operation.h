//
//  NSData+Operation.h
//  RFID_Lab1
//
//  Created by Rex on 2017/12/10.
//  Copyright © 2017年 Rex. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (Operation)

-(NSData *)changeNFCLength;
-(NSData *)changeLength:(int)length;
-(NSData *)trimZero;

-(char)toChar;
-(NSUInteger)toInteger;
-(NSString *)toASCIIString;
-(NSString *)toUTF8String;
-(NSDate *)toDate;

-(NSUInteger)getValue;
+(NSData *)getValueData:(NSUInteger)value;

+(NSData *)createValueBlockWithValue:(NSUInteger)value addr:(Byte)bAddrByte;
-(NSUInteger)point;
-(BOOL)mifareCheckValueBlockFormat;

//name
+(NSData *)dataBlockWithName:(NSString *)name;

@end

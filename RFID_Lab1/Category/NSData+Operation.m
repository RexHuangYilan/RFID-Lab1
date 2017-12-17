//
//  NSData+Operation.m
//  RFID_Lab1
//
//  Created by Rex on 2017/12/10.
//  Copyright © 2017年 Rex. All rights reserved.
//

#import "NSData+Operation.h"

@implementation NSData (Operation)

-(NSData *)changeNFCLength
{
    return [self changeLength:16];
}

-(NSData *)changeLength:(int)length
{
    NSMutableData *hashData = [NSMutableData dataWithData:self];
    if (self.length < length) {
        [hashData increaseLengthBy:length - self.length];
    }else{
        [hashData setLength:length];
    }
    return hashData;
}

-(NSData *)trimZero
{
    NSMutableData *hashData = [NSMutableData dataWithData:self];
    Byte *btyes = (Byte *)self.bytes;
    for(int i = (int)([self length] - 1);i >= 0;i--)
    {
        if (btyes[i] != 0x00) {
            [hashData setLength:i+1];
            break;
        }
    }
    return hashData;
}

-(char)toChar
{
    char c;
    [self getBytes: &c length: 1];
    return c;
}

-(NSUInteger)toInteger
{
    NSUInteger integer;
    [self getBytes:&integer length:sizeof(integer)];
    return integer;
}

-(NSString *)toASCIIString
{
    NSStringEncoding big5 = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingBig5_HKSCS_1999);
    return [[NSString alloc] initWithData:[self trimZero] encoding:big5];
}

-(NSString *)toUTF8String
{
    return [[NSString alloc] initWithData:[self trimZero] encoding:NSUTF8StringEncoding];
}

-(NSDate *)toDate
{
    NSUInteger timestamp = [self toInteger];
    return [NSDate dateWithTimeIntervalSince1970:timestamp];
}

-(NSUInteger)getValue{
    NSUInteger value = 0;
    if ( (self == nil) || (self.length < 4) ) {
        return 0;
    }
    Byte *valueByte = (Byte *)[self bytes];
    value = ( ((valueByte[0] & 0x000000ff) << 24) | ((valueByte[1] & 0x000000ff) << 16) | ((valueByte[2] & 0x000000ff) << 8) | (valueByte[3] & 0x000000ff) );
    return value;
}

+(NSData *)getValueData:(NSUInteger)value {
    Byte bytes[] = {(Byte) (((value & 0xff000000) >> 24) & 0xff),
        (Byte) (((value & 0x00ff0000) >> 16) & 0xff),
        (Byte) (((value & 0x0000ff00) >> 8) & 0xff),
        (Byte) (((value & 0x000000ff) >> 0) & 0xff)};
    
    return [[NSData alloc] initWithBytes:bytes length:4];
}

+(NSData *)createValueBlockWithValue:(NSUInteger)value addr:(Byte)bAddrByte
{
    NSData *valueData = [self getValueData:value];
    NSData *valueBlock = [NSData createValueBlock:valueData addr:bAddrByte];
    return valueBlock;
}

+(NSData *)createValueBlock:(NSData *)pValueData addr:(Byte)bAddrByte {
    if ( (pValueData == nil) || (pValueData.length < 4) ) {
        return nil;
    }
    Byte pBlock[16];
    Byte *pValue = (Byte *)[pValueData bytes];
    pBlock[0]  = pValue[0];
    pBlock[1]  = pValue[1];
    pBlock[2]  = pValue[2];
    pBlock[3]  = pValue[3];
    pBlock[4]  = (Byte) ~((pValue[0] & 0x00ff) & 0x00ff);
    pBlock[5]  = (Byte) ~((pValue[1] & 0x00ff) & 0x00ff);
    pBlock[6]  = (Byte) ~((pValue[2] & 0x00ff) & 0x00ff);
    pBlock[7]  = (Byte) ~((pValue[3] & 0x00ff) & 0x00ff);
    pBlock[8]  = pValue[0];
    pBlock[9]  = pValue[1];
    pBlock[10] = pValue[2];
    pBlock[11] = pValue[3];
    pBlock[12] = bAddrByte;
    pBlock[13] = (Byte) ~((bAddrByte & 0x00ff) & 0x00ff);
    pBlock[14] = bAddrByte;
    pBlock[15] = (Byte) ~((bAddrByte & 0x00ff) & 0x00ff);
    return [[NSData alloc] initWithBytes:pBlock length:16];
}

-(BOOL)mifareCheckValueBlockFormat{
    if ( (self == nil) || (self.length != 16) ) {
        return false;
    }
    Byte *pBlock = (Byte *)[self bytes];
    /* check format of value block */
    if ((pBlock[0] != pBlock[8]) ||
        (pBlock[1] != pBlock[9]) ||
        (pBlock[2] != pBlock[10]) ||
        (pBlock[3] != pBlock[11]) ||
        (pBlock[4] != (Byte)( (pBlock[0] & 0x00ff) ^ 0xFF)) ||
        (pBlock[5] != (Byte)( (pBlock[1] & 0x00ff) ^ 0xFF)) ||
        (pBlock[6] != (Byte)( (pBlock[2] & 0x00ff) ^ 0xFF)) ||
        (pBlock[7] != (Byte)( (pBlock[3] & 0x00ff) ^ 0xFF)) ||
        (pBlock[12] != pBlock[14]) ||
        (pBlock[13] != pBlock[15]) ||
        (pBlock[12] != (Byte)( (pBlock[13] & 0x00ff) ^ 0xFF)))
    {
        return NO;
    }
    return YES;
}

-(NSUInteger)point
{
    Byte *returnBytes = (Byte *)[self bytes];
    Byte valueBytes[] = {returnBytes[0],returnBytes[1],returnBytes[2],returnBytes[3]};
    NSData *valueData = [[NSData alloc] initWithBytes:valueBytes length:4];
    return [valueData getValue];
}

//name
+(NSData *)dataBlockWithName:(NSString *)name
{
    //    NSStringEncoding big5 = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingBig5_HKSCS_1999);
    NSData *data = [name dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    if (!data) {
        data = [NSData data];
    }
    return [data changeNFCLength];
}

@end

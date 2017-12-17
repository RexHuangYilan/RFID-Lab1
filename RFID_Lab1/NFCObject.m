//
//  NFCObject.m
//  RFID_Lab1
//
//  Created by Rex on 2017/10/5.
//  Copyright © 2017年 Rex. All rights reserved.
//

#import "NFCObject.h"
#import "NSData+Hex.h"

@implementation NFCObject

-(instancetype)init
{
    self = [super init];
    if (self) {
        self.key = @"FFFFFFFFFFFF";
        NSMutableArray *temp = [NSMutableArray array];
        for (int i = 0; i < 16; i++) {
            [temp addObject:[NSString stringWithFormat:@"%d",i]];
        }
        self.sectors = [temp copy];
        [temp removeAllObjects];
        for (int i = 0; i < 4; i++) {
            [temp addObject:[NSString stringWithFormat:@"%d",i]];
        }
        self.blocks = [temp copy];
    }
    return self;
}

-(NSData *)keyData
{
    if (self.key == nil) {
        return nil;
    }
    NSData *data = [NSData dataWithHexString:self.key];
    return data;
}

-(NSInteger)authenticate
{
    return self.block*16 + self.sector;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
//    NFCObject *copy = [[[self class] allocWithZone:zone] init];
//    copy.key = self.key;
//    copy.keyAB = self.keyAB;
//    copy.block = self.block;
//    copy.sector = self.sector;
    return self;
}

@end

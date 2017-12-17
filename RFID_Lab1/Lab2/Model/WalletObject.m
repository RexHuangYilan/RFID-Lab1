//
//  WalletObject.m
//  RFID_Lab1
//
//  Created by Rex on 2017/12/9.
//  Copyright © 2017年 Rex. All rights reserved.
//

#import "WalletObject.h"
#import "NSData+Operation.h"


@interface WalletObject()

@property (strong, nonatomic) NFCObject *hashObject;
@property (strong, nonatomic) NFCObject *uidObject;
@property (strong, nonatomic) NFCObject *nameObject;
@property (strong, nonatomic) NFCObject *createDateObject;
@property (strong, nonatomic) NFCObject *pointObject;

@property (readonly) NSData *hashData;
@property (readonly) NSData *uidData;
@property (readonly) NSData *nameData;
@property (readonly) NSData *createDateData;
@property (readonly) NSData *pointData;

@property (nonatomic, assign) BOOL isCorrectCard;

@end


@implementation WalletObject

#pragma mark - public

-(void)createNewCard
{
    int value = (arc4random() % 999999999) + 1;
    self.uid = [NSString stringWithFormat:@"R%09d",value];
    self.name = nil;
    self.createDate = [NSDate date];
    self.point = 10000;
}

-(void)clearCard
{
    self.uid = nil;
    self.name = nil;
    self.createDate = nil;
    self.point = 0;
}

-(NSArray<NFCObject *> *)nfcs
{
    [self dataToNFC];
    return @[self.hashObject,self.uidObject,self.nameObject,self.createDateObject,self.pointObject];
}

-(NSArray<NFCObject *> *)cleanNfcs
{
    [self removeNFC];
    return @[self.hashObject,self.uidObject,self.nameObject,self.createDateObject,self.pointObject];
}

#pragma mark - private

-(NSUInteger)hash {
    return [self.uid hash] ^ [self.name hash] ^ (NSUInteger)[self.createDate timeIntervalSince1970] ^ self.point;
}

-(void)dataToNFC
{
    self.hashObject.data = self.hashData;
    self.uidObject.data = self.uidData;
    self.nameObject.data = self.nameData;
    self.createDateObject.data = self.createDateData;
    self.pointObject.data = self.pointData;
}

-(void)nfcToData
{
    NSUInteger hash = [self.hashObject.data toInteger];
    
    self.uid = [self.uidObject.data toASCIIString];
    self.name = [self.nameObject.data toUTF8String];
    self.createDate = [self.createDateObject.data toDate];
    self.point = [self.pointObject.data point];
    
    self.isCorrectCard = self.hash == hash && [self.pointObject.data mifareCheckValueBlockFormat];
}

-(void)removeNFC
{
    self.hashObject.data = [[NSData data] changeNFCLength];
    self.uidObject.data = [[NSData data] changeNFCLength];
    self.nameObject.data = [[NSData data] changeNFCLength];
    self.createDateObject.data = [[NSData data] changeNFCLength];
    self.pointObject.data = [[NSData data] changeNFCLength];
}

#pragma mark - get

-(NFCObject *)hashObject
{
    if (!_hashObject) {
        _hashObject = [NFCObject new];
        _hashObject.sector = 0;
        _hashObject.block = 1;
    }
    return _hashObject;
}

-(NFCObject *)uidObject
{
    if (!_uidObject) {
        _uidObject = [NFCObject new];
        _uidObject.sector = 0;
        _uidObject.block = 2;
    }
    return _uidObject;
}

-(NFCObject *)nameObject
{
    if (!_nameObject) {
        _nameObject = [NFCObject new];
        _nameObject.sector = 1;
        _nameObject.block = 0;
    }
    return _nameObject;
}

-(NFCObject *)createDateObject
{
    if (!_createDateObject) {
        _createDateObject = [NFCObject new];
        _createDateObject.sector = 1;
        _createDateObject.block = 1;
    }
    return _createDateObject;
}

-(NFCObject *)pointObject
{
    if (!_pointObject) {
        _pointObject = [NFCObject new];
        _pointObject.sector = 1;
        _pointObject.block = 2;
    }
    return _pointObject;
}

-(NSData *)hashData
{
    NSUInteger hash = self.hash;
    return [[NSData dataWithBytes:&hash length:sizeof(hash)] changeNFCLength];
}

-(NSData *)uidData
{
    NSData *data = [self.uid dataUsingEncoding:NSASCIIStringEncoding];
    if (!data) {
        data = [NSData data];
    }
    return [data changeNFCLength];
}

-(NSData *)nameData
{
//    NSStringEncoding big5 = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingBig5_HKSCS_1999);
    NSData *data = [self.name dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    if (!data) {
        data = [NSData data];
    }
    return [data changeNFCLength];
}

-(NSData *)createDateData
{
    NSUInteger timestamp = [self.createDate timeIntervalSince1970];
    return [[NSData dataWithBytes:&timestamp length:sizeof(timestamp)] changeNFCLength];
}

-(NSData *)pointData
{
    return [NSData createValueBlockWithValue:self.point addr:1];
}

@end

//
//  NFCObject.h
//  RFID_Lab1
//
//  Created by Rex on 2017/10/5.
//  Copyright © 2017年 Rex. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, NFCKeyAB) {
    NFCKeyABA,
    NFCKeyABB,
};

@interface NFCObject : NSObject<NSCopying>

@property(nonatomic) NSInteger sector;
@property(nonatomic) NSInteger block;
@property(nonatomic) NFCKeyAB keyAB;
@property(nonatomic,strong) NSString *key;
@property(nonatomic,strong) NSData *data;

-(NSData *)keyData;
-(NSInteger)authenticate;

@property(nonatomic,strong) NSArray<NSString *> *sectors;
@property(nonatomic,strong) NSArray<NSString *> *blocks;

@end

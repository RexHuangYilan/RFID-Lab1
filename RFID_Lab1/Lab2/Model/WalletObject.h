//
//  WalletObject.h
//  RFID_Lab1
//
//  Created by Rex on 2017/12/9.
//  Copyright © 2017年 Rex. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NFCObject.h"

@interface WalletObject : NSObject

@property (strong, nonatomic) NSString * _Nullable uid;
@property (strong, nonatomic) NSString * _Nullable name;
@property (strong, nonatomic) NSDate * _Nullable createDate;
@property (nonatomic) NSUInteger point;

@property (readonly) NFCObject * _Nonnull pointObject;

@property (readonly) BOOL isCorrectCard;

-(void)createNewCard;
-(void)clearCard;

-(NSArray<NFCObject *> *_Nonnull)nfcs;
-(NSArray<NFCObject *> *_Nonnull)cleanNfcs;

-(void)nfcToData;
-(void)dataToNFC;
@end

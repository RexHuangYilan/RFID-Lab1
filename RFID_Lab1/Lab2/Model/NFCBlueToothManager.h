//
//  NFCBlueToothManager.h
//  RFID_Lab1
//
//  Created by Rex on 2017/12/9.
//  Copyright © 2017年 Rex. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NFCDeviceInfoObject.h"

#import "NFCObject.h"

#import "NSError+NFC.h"

extern NSString * _Nonnull BluetoothDisConnectNotification;
extern NSString * _Nonnull BluetoothConnectNotification;

typedef NS_ENUM(NSUInteger, BLENFCStatus) {
    BLENFCStatusNoConnect,
    BLENFCStatusConnect,
    BLENFCStatusLoading,
};

typedef void(^NFCBlueToothManagerError)(NSError * _Nonnull error);
typedef void(^NFCBlueToothManagerArraySuccess)(NSArray<NFCObject *> * _Nonnull datas);

@protocol NFCBlueToothManagerDelegate<NSObject>

-(void)deviceChangeStatus:(BLENFCStatus)status;

@end

@interface NFCBlueToothManager : NSObject

@property (readonly) BLENFCStatus status;
@property (readonly) NFCDeviceInfoObject * _Nullable info;
@property (nonatomic, weak) id<NFCBlueToothManagerDelegate> _Nullable delegate;

+(instancetype _Nonnull )sharedInstance;

-(void)scanNFC;
-(void)readCardWithNFCs:(NSArray<NFCObject *> *_Nonnull)nfcs
           successBlock:(NFCBlueToothManagerArraySuccess _Nullable )successBlock
             errorBlock:(NFCBlueToothManagerError _Nullable )errorBlock;

-(void)writeCardWithNFCs:(NSArray<NFCObject *> *_Nonnull)nfcs
           successBlock:(NFCBlueToothManagerArraySuccess _Nullable )successBlock
             errorBlock:(NFCBlueToothManagerError _Nullable )errorBlock;

@end


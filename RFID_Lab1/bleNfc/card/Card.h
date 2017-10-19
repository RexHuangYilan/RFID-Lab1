//
//  Card.h
//  ble_nfc_sdk
//
//  Created by lochy on 16/10/23.
//  Copyright © 2016年 Lochy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DKDeviceManager.h"

#define  PH_EXCHANGE_DEFAULT            0x0000
#define  PH_EXCHANGE_LEAVE_BUFFER_BIT   0x4000
#define  PH_EXCHANGE_BUFFERED_BIT       0x8000
#define  PH_EXCHANGE_BUFFER_FIRST       PH_EXCHANGE_DEFAULT | PH_EXCHANGE_BUFFERED_BIT
#define  PH_EXCHANGE_BUFFER_CONT        PH_EXCHANGE_DEFAULT | PH_EXCHANGE_BUFFERED_BIT | PH_EXCHANGE_LEAVE_BUFFER_BIT
#define  PH_EXCHANGE_BUFFER_LAST        PH_EXCHANGE_DEFAULT | PH_EXCHANGE_LEAVE_BUFFER_BIT

//代码块定义
//APDU指令通道回调代码块
typedef void(^onReceiveCloseListener)(BOOL isOk);

@interface Card : NSObject
@property (nonatomic,strong) NSData *uid;
@property (nonatomic,strong) NSData *atr;
@property (nonatomic,strong) DKDeviceManager *deviceManager;

-(id)init:(DKDeviceManager *)deviceManager;
-(id)init:(DKDeviceManager *)deviceManager uid:(NSData *)uid atr:(NSData *)atr;
-(void)close;
-(void)closeWithCallbackBlocl:(onReceiveCloseListener)block;
@end

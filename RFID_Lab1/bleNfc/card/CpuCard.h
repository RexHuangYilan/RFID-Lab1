//
//  CpuCard.h
//  ble_nfc_sdk
//
//  Created by lochy on 16/10/23.
//  Copyright © 2016年 Lochy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Card.h"

//代码块定义
//APDU指令通道回调代码块
typedef void(^onReceiveApduExchangeListener)(BOOL isCmdRunSuc, NSData* apduRtnData);

@interface CpuCard : Card
-(void)apduExchange:(NSData *)apduData callback:(onReceiveApduExchangeListener)block;
@end

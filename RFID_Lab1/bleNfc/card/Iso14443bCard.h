//
//  Iso14443bCard.h
//  ble_nfc_sdk
//
//  Created by lochy on 16/10/23.
//  Copyright © 2016年 Lochy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Card.h"

//代码块定义
//BPDU指令通道回调
typedef void(^onReceiveBpduExchangeListener)(BOOL isSuc, NSData* returnData);

@interface Iso14443bCard : Card
-(void)bpduExchange:(NSData *)bpduData callbackBlock:(onReceiveBpduExchangeListener)block;
@end

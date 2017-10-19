//
//  CpuCard.m
//  ble_nfc_sdk
//
//  Created by lochy on 16/10/23.
//  Copyright © 2016年 Lochy. All rights reserved.
//

#import "CpuCard.h"

onReceiveApduExchangeListener mOnReceiveApduExchangeListenerBlock = nil;

@implementation CpuCard

-(void)apduExchange:(NSData *)apduData callback:(onReceiveApduExchangeListener)block {
    mOnReceiveApduExchangeListenerBlock = block;
    [self.deviceManager requestRfmSentApduCmd:apduData callbackBlock:^(BOOL isSuc, NSData *ApduRtnData) {
        if (mOnReceiveApduExchangeListenerBlock != nil) {
            mOnReceiveApduExchangeListenerBlock(isSuc, ApduRtnData);
        }
    }];
}
@end

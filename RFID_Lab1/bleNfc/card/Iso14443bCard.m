//
//  Iso14443bCard.m
//  ble_nfc_sdk
//
//  Created by lochy on 16/10/23.
//  Copyright © 2016年 Lochy. All rights reserved.
//

#import "Iso14443bCard.h"

onReceiveBpduExchangeListener mOnReceiveBpduExchangeListenerBlock = nil;

@implementation Iso14443bCard
-(void)bpduExchange:(NSData *)bpduData callbackBlock:(onReceiveBpduExchangeListener)block{
    mOnReceiveBpduExchangeListenerBlock = block;
    [self.deviceManager requestRfmSentBpduCmd:bpduData callbackBlock:^(BOOL isSuc, NSData *BpduRtnData) {
        if (mOnReceiveBpduExchangeListenerBlock != nil) {
            mOnReceiveBpduExchangeListenerBlock(isSuc, BpduRtnData);
        }
    }];
}
@end

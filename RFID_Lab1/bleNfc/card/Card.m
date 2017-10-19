//
//  Card.m
//  ble_nfc_sdk
//
//  Created by lochy on 16/10/23.
//  Copyright © 2016年 Lochy. All rights reserved.
//

#import "Card.h"

onReceiveCloseListener mOnReceiveCloseListenerBlock = nil;

@implementation Card
-(id)init:(DKDeviceManager *)deviceManager {
    self = [super init];//获得父类的对象并进行初始化
    if (self){
        self.deviceManager = deviceManager;
    }
    return self;
}

-(id)init:(DKDeviceManager *)deviceManager uid:(NSData *)uid atr:(NSData *)atr {
    self = [super init];//获得父类的对象并进行初始化
    if (self){
        self.deviceManager = deviceManager;
        self.uid = uid;
        self.atr = atr;
    }
    return self;
}

-(void)close {
    [self.deviceManager requestRfmCloseWhitCallbackBlock:nil];
}

-(void)closeWithCallbackBlocl:(onReceiveCloseListener)block {
    mOnReceiveCloseListenerBlock = block;
    [self.deviceManager requestRfmCloseWhitCallbackBlock:^(BOOL blnIsCloseSuc){
        if (mOnReceiveCloseListenerBlock != nil) {
            mOnReceiveCloseListenerBlock(blnIsCloseSuc);
        }
    }];
}
@end

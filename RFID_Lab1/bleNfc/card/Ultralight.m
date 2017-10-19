//
//  Ultralight.m
//  ble_nfc_sdk
//
//  Created by lochy on 16/10/23.
//  Copyright © 2016年 Lochy. All rights reserved.
//

#import "Ultralight.h"

#define  UL_GET_VERSION_CMD         ((Byte)0x60)
#define  UL_READ_CMD                ((Byte)0x30)
#define  UL_FAST_READ_CMD           ((Byte)0x3A)
#define  UL_WRITE_CMD               ((Byte)0xA2)
#define  UL_READ_CNT_CMD            ((Byte)0x39)
#define  UL_PWD_AUTH_CMD            ((Byte)0x1B)
#define  UL_MAX_FAST_READ_BLOCK_NUM (0x20)

onReceiveUltralightGetVersionListener mOnReceiveUltralightGetVersionListenerBlock = nil;
onReceiveUltralightReadListener       mOnReceiveUltralightReadListenerBlock = nil;
onReceiveUltralightFastReadListener   mOnReceiveUltralightFastReadListenerBlock = nil;
onReceiveUltralightWriteListener      mOnReceiveUltralightWriteListenerBlock = nil;
onReceiveUltralightReadCntListener    mOnReceiveUltralightReadCntListenerBlock = nil;
onReceiveUltralightPwdAuthListener    mOnReceiveUltralightPwdAuthListenerBlock = nil;
onReceiveUltralightCmdListener        mOnReceiveUltralightCmdListenerBlock = nil;

@implementation Ultralight
-(void)ultralightGetVersionWithCallbackBlock:(onReceiveUltralightGetVersionListener)block {
    mOnReceiveUltralightGetVersionListenerBlock = block;
    Byte cmdByte[] = {UL_GET_VERSION_CMD};
    NSData *cmdData = [[NSData alloc] initWithBytes:cmdByte length:1];
    [self ultralightCmd:cmdData callbackBlock:^(BOOL isSuc, NSData *returnData) {
        if (mOnReceiveUltralightGetVersionListenerBlock != nil) {
            mOnReceiveUltralightGetVersionListenerBlock(isSuc, returnData);
        }
    }];
}

-(void)ultralightRead:(Byte)address callbackBlock:(onReceiveUltralightReadListener)block{
    mOnReceiveUltralightReadListenerBlock = block;
    Byte cmdByte[] = {UL_READ_CMD, address};
    NSData *cmdData = [[NSData alloc] initWithBytes:cmdByte length:2];
    [self ultralightCmd:cmdData callbackBlock:^(BOOL isSuc, NSData *returnData) {
        if (mOnReceiveUltralightReadListenerBlock != nil) {
            mOnReceiveUltralightReadListenerBlock(isSuc, returnData);
        }
    }];
}

-(void)ultralightFastRead:(Byte)startAddress end:(Byte)endAddress callbackBlock:(onReceiveUltralightFastReadListener)block{
    mOnReceiveUltralightFastReadListenerBlock = block;
    if (startAddress > endAddress) {
        if (mOnReceiveUltralightFastReadListenerBlock != nil) {
            mOnReceiveUltralightFastReadListenerBlock(NO, nil);
        }
        return;
    }
    Byte cmdByte[] = {UL_FAST_READ_CMD, startAddress, endAddress};
    NSData *cmdData = [[NSData alloc] initWithBytes:cmdByte length:3];
    [self ultralightCmd:cmdData callbackBlock:^(BOOL isSuc, NSData *returnData) {
        if (mOnReceiveUltralightFastReadListenerBlock != nil) {
            mOnReceiveUltralightFastReadListenerBlock(isSuc, returnData);
        }
    }];
}

-(void)ultralightWrite:(Byte)address data:(NSData *)data callbackBlock:(onReceiveUltralightWriteListener)block{
    mOnReceiveUltralightWriteListenerBlock = block;
    if (data.length != 4) {
        if (mOnReceiveUltralightWriteListenerBlock != nil) {
            mOnReceiveUltralightWriteListenerBlock(NO, nil);
        }
        return;
    }
    Byte *dataBytes = (Byte *)[data bytes];
    Byte cmdByte[] = {UL_WRITE_CMD, address, dataBytes[0], dataBytes[1], dataBytes[2], dataBytes[3]};
    NSData *cmdData = [[NSData alloc] initWithBytes:cmdByte length:6];
    [self ultralightCmd:cmdData callbackBlock:^(BOOL isSuc, NSData *returnData) {
        if (mOnReceiveUltralightWriteListenerBlock != nil) {
            mOnReceiveUltralightWriteListenerBlock(isSuc, returnData);
        }
    }];
}

-(void)ultralightReadCntWithCallbackBlock:(onReceiveUltralightReadCntListener)block{
    mOnReceiveUltralightReadCntListenerBlock = block;
    Byte cmdByte[] = {UL_READ_CNT_CMD, 0x02};
    NSData *cmdData = [[NSData alloc] initWithBytes:cmdByte length:2];
    [self ultralightCmd:cmdData callbackBlock:^(BOOL isSuc, NSData *returnData) {
        if (mOnReceiveUltralightReadCntListenerBlock != nil) {
            mOnReceiveUltralightReadCntListenerBlock(isSuc, returnData);
        }
    }];
}

-(void)ultralightPwdAuth:(NSData *)password callbackBlock:(onReceiveUltralightPwdAuthListener)block{
    mOnReceiveUltralightPwdAuthListenerBlock = block;
    Byte *pwdBytes = (Byte *)[password bytes];
    if (password.length != 4) {
        if (mOnReceiveUltralightPwdAuthListenerBlock != nil) {
            mOnReceiveUltralightPwdAuthListenerBlock(NO);
        }
        return;
    }
    Byte cmdByte[] = {UL_PWD_AUTH_CMD, pwdBytes[0], pwdBytes[1], pwdBytes[2], pwdBytes[3]};
    NSData *cmdData = [[NSData alloc] initWithBytes:cmdByte length:5];
    [self ultralightCmd:cmdData callbackBlock:^(BOOL isSuc, NSData *returnData) {
        if (mOnReceiveUltralightPwdAuthListenerBlock != nil) {
            mOnReceiveUltralightPwdAuthListenerBlock(isSuc);
        }
    }];
}

-(void)ultralightCmd:(NSData *)cmdData callbackBlock:(onReceiveUltralightCmdListener)block {
    mOnReceiveUltralightCmdListenerBlock = block;
    [self.deviceManager requestRfmUltralightCmd:cmdData callback:^(BOOL isSuc, NSData *ulCmdRtnData) {
        if (mOnReceiveUltralightCmdListenerBlock != nil) {
            mOnReceiveUltralightCmdListenerBlock(isSuc, ulCmdRtnData);
        }
    }];
}
@end








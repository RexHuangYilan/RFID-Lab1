//
//  Mifare.m
//  ble_nfc_sdk
//
//  Created by lochy on 16/10/23.
//  Copyright © 2016年 Lochy. All rights reserved.
//

#import "Mifare.h"

onReceiveMifareAuthenticateListener mOnReceiveMifareAuthenticateListenerBlock = nil;
onReceiveMifareDataExchangeListener mOnReceiveMifareDataExchangeListenerBlock = nil;
onReceiveMifareReadListener mOnReceiveMifareReadListenerBlock = nil;
onReceiveMifareWriteListener mOnReceiveMifareWriteListenerBlock = nil;
onReceiveMifareIncrementTransferListener mOnReceiveMifareIncrementTransferListenerBlock = nil;
onReceiveMifareDecrementTransferListener mOnReceiveMifareDecrementTransferListenerBlock = nil;
onReceiveMifareRestoreTransferListener mOnReceiveMifareRestoreTransferListenerBlock = nil;
onReceiveMifarePersonalizeUidListener mOnReceiveMifarePersonalizeUidListenerBlock = nil;
onReceiveMifareReadValueListener mOnReceiveMifareReadValueListenerBlock = nil;
onReceiveMifareWriteValueListener mOnReceiveMifareWriteValueListenerBlock = nil;

@implementation Mifare

-(void)mifareAuthenticate:(Byte)bBlockNo keyType:(Byte)bKeyType key:(NSData *)pKey callbackBlock:(onReceiveMifareAuthenticateListener)block {
    mOnReceiveMifareAuthenticateListenerBlock = block;
    [self.deviceManager requestRfmMifareAuth:bBlockNo keyType:bKeyType key:pKey uid:self.uid callback:^(BOOL isSuc) {
        if (mOnReceiveMifareAuthenticateListenerBlock != nil) {
            mOnReceiveMifareAuthenticateListenerBlock(isSuc);
        }
    }];
}

-(void)mifareRead:(Byte)blockNo callbackBlock:(onReceiveMifareReadListener)block {
    mOnReceiveMifareReadListenerBlock = block;
    Byte cmdByte[] = {PHAL_MFC_CMD_READ, blockNo};
    NSData *cmdData = [[NSData alloc] initWithBytes:cmdByte length:2];
    [self mifareDataExchange:cmdData callbackBlock:^(BOOL isSuc, NSData *returnData) {
        if (mOnReceiveMifareReadListenerBlock != nil) {
            mOnReceiveMifareReadListenerBlock(isSuc, returnData);
        }
    }];
}

-(void)mifareWrite:(Byte)blockNo data:(NSData *)blockData callbackBlock:(onReceiveMifareWriteListener)block {
    mOnReceiveMifareWriteListenerBlock = block;
    Byte cmdByte[] = {PHAL_MFC_CMD_WRITE, blockNo};
    NSData *cmdData = [[NSData alloc] initWithBytes:cmdByte length:2];
    [self mifareDataExchange:cmdData callbackBlock:^(BOOL isSuc, NSData *returnData) {
        if (isSuc) {
            [self mifareDataExchange:blockData callbackBlock:^(BOOL isSuc, NSData *returnData) {
                if (mOnReceiveMifareWriteListenerBlock != nil) {
                    mOnReceiveMifareWriteListenerBlock(isSuc);
                }
            }];
        }
        else {
            if (mOnReceiveMifareWriteListenerBlock != nil) {
                mOnReceiveMifareWriteListenerBlock(NO);
            }
        }
    }];
}

-(void)mifareIncrementTransfer:(Byte)bSrcBlockNo dstBlockNo:(Byte)bDstBlockNo value:(NSData *)pValue callbackBlock:(onReceiveMifareIncrementTransferListener)block {
    mOnReceiveMifareIncrementTransferListenerBlock = block;
    [self mifareRead:bSrcBlockNo callbackBlock:^(BOOL isSuc, NSData *returnData) {
        if (!isSuc || ![self mifareCheckValueBlockFormat:returnData]) {
            if (mOnReceiveMifareIncrementTransferListenerBlock != nil) {
                mOnReceiveMifareIncrementTransferListenerBlock(NO);
            }
            return;
        }
        NSUInteger value = [self getValue:returnData] & 0x0ffffffffl;

        NSUInteger incrementValue = [self getValue:pValue] & 0x0ffffffffl;
        
        if ( ((long)value + (long)incrementValue) > 0x0ffffffffl ) {
            value = (NSUInteger)((long)value + (long)incrementValue - 0x0ffffffffl);
        }
        else {
            value += incrementValue;
        }
        NSData *valueData = [self getValueData:value];
        NSData *valueBlockData = [self createValueBlock:valueData addr:bDstBlockNo];
        [self mifareWrite:bDstBlockNo data:valueBlockData callbackBlock:^(BOOL isSuc) {
            if (mOnReceiveMifareIncrementTransferListenerBlock != nil) {
                mOnReceiveMifareIncrementTransferListenerBlock(isSuc);
            }
        }];
    }];
}

-(void)mifareDecrementTransfer:(Byte)bSrcBlockNo dstBlockNo:(Byte)bDstBlockNo value:(NSData *)pValue callbackBlock:(onReceiveMifareDecrementTransferListener)block{
    mOnReceiveMifareDecrementTransferListenerBlock = block;
    [self mifareRead:bSrcBlockNo callbackBlock:^(BOOL isSuc, NSData *returnData) {
        if (!isSuc || ![self mifareCheckValueBlockFormat:returnData]) {
            if (mOnReceiveMifareDecrementTransferListenerBlock != nil) {
                mOnReceiveMifareDecrementTransferListenerBlock(NO);
            }
            return;
        }
        NSUInteger value = [self getValue:returnData] & 0x0ffffffffl;
        NSUInteger decrementValue = [self getValue:pValue] & 0x0ffffffffl;
        if ( ((long)value - (long)decrementValue) < 0 ) {
            value = 0x0ffffffffl + (value - decrementValue);
        }
        else {
            value -= decrementValue;
        }
        NSData *valueData = [self getValueData:value];
        NSData *valueBlockData = [self createValueBlock:valueData addr:bDstBlockNo];
        [self mifareWrite:bDstBlockNo data:valueBlockData callbackBlock:^(BOOL isSuc) {
            if (mOnReceiveMifareDecrementTransferListenerBlock != nil) {
                mOnReceiveMifareDecrementTransferListenerBlock(isSuc);
            }
        }];
    }];
}

-(void)mifareRestoreTransfer:(Byte)bSrcBlockNo dstBlockNo:(Byte)bDstBlockNo callbackBlock:(onReceiveMifareRestoreTransferListener)block {
    mOnReceiveMifareRestoreTransferListenerBlock = block;
}

-(void)mifarePersonalizeUid:(Byte)bUidType callbackBlock:(onReceiveMifarePersonalizeUidListener)block {
    mOnReceiveMifarePersonalizeUidListenerBlock = block;
    Byte cmdByte[] = {PHAL_MFC_CMD_PERSOUID, bUidType};
    NSData *cmdData = [[NSData alloc] initWithBytes:cmdByte length:2];
    [self mifareDataExchange:cmdData callbackBlock:^(BOOL isSuc, NSData *returnData) {
        if (mOnReceiveMifarePersonalizeUidListenerBlock != nil) {
            mOnReceiveMifarePersonalizeUidListenerBlock(isSuc);
        }
    }];
}

-(void)mifareReadValue:(Byte)bBlockNo callbackBlock:(onReceiveMifareReadValueListener)block {
    mOnReceiveMifareReadValueListenerBlock = block;
    [self mifareRead:bBlockNo callbackBlock:^(BOOL isSuc, NSData *returnData) {
        if (!isSuc || ![self mifareCheckValueBlockFormat:returnData]) {
            if (mOnReceiveMifareReadValueListenerBlock != nil) {
                mOnReceiveMifareReadValueListenerBlock(isSuc, (Byte)0, nil);
            }
            return;
        }
        if (mOnReceiveMifareReadValueListenerBlock != nil) {
            Byte *returnBytes = (Byte *)[returnData bytes];
            Byte valueBytes[] = {returnBytes[0],returnBytes[1],returnBytes[2],returnBytes[3]};
            NSData *valueData = [[NSData alloc] initWithBytes:valueBytes length:4];
            mOnReceiveMifareReadValueListenerBlock(isSuc, returnBytes[12], valueData);
        }
    }];
}

-(void)mifareWriteValue:(Byte)bBlockNo value:(NSData *)pValue addr:(Byte)pAddrData callbackBlock:(onReceiveMifareWriteValueListener)block {
    mOnReceiveMifareWriteValueListenerBlock = block;
    NSData * writeData = [self createValueBlock:pValue addr:pAddrData];
    [self mifareWrite:bBlockNo data:writeData callbackBlock:^(BOOL isSuc) {
        if (mOnReceiveMifareWriteValueListenerBlock != nil) {
            mOnReceiveMifareWriteValueListenerBlock(isSuc);
        }
    }];
}

-(void)mifareDataExchange:(NSData *)data callbackBlock:(onReceiveMifareDataExchangeListener)block {
    mOnReceiveMifareDataExchangeListenerBlock = block;
    [self.deviceManager requestRfmMifareDataExchange:data callback:^(BOOL isSuc, NSData *returnData) {
        if (mOnReceiveMifareDataExchangeListenerBlock != nil) {
            mOnReceiveMifareDataExchangeListenerBlock(isSuc, returnData);
        }
    }];
}

-(BOOL)mifareCheckValueBlockFormat:(NSData *)pBlockData {
    if ( (pBlockData == nil) || (pBlockData.length != 16) ) {
        return false;
    }
    Byte *pBlock = (Byte *)[pBlockData bytes];
    /* check format of value block */
    if ((pBlock[0] != pBlock[8]) ||
        (pBlock[1] != pBlock[9]) ||
        (pBlock[2] != pBlock[10]) ||
        (pBlock[3] != pBlock[11]) ||
        (pBlock[4] != (Byte)( (pBlock[0] & 0x00ff) ^ 0xFF)) ||
        (pBlock[5] != (Byte)( (pBlock[1] & 0x00ff) ^ 0xFF)) ||
        (pBlock[6] != (Byte)( (pBlock[2] & 0x00ff) ^ 0xFF)) ||
        (pBlock[7] != (Byte)( (pBlock[3] & 0x00ff) ^ 0xFF)) ||
        (pBlock[12] != pBlock[14]) ||
        (pBlock[13] != pBlock[15]) ||
        (pBlock[12] != (Byte)( (pBlock[13] & 0x00ff) ^ 0xFF)))
    {
        return NO;
    }
    return YES;
}

-(NSData *)createValueBlock:(NSData *)pValueData addr:(Byte)bAddrByte {
    if ( (pValueData == nil) || (pValueData.length < 4) ) {
        return nil;
    }
    Byte pBlock[16];
    Byte *pValue = (Byte *)[pValueData bytes];
    pBlock[0]  = pValue[0];
    pBlock[1]  = pValue[1];
    pBlock[2]  = pValue[2];
    pBlock[3]  = pValue[3];
    pBlock[4]  = (Byte) ~((pValue[0] & 0x00ff) & 0x00ff);
    pBlock[5]  = (Byte) ~((pValue[1] & 0x00ff) & 0x00ff);
    pBlock[6]  = (Byte) ~((pValue[2] & 0x00ff) & 0x00ff);
    pBlock[7]  = (Byte) ~((pValue[3] & 0x00ff) & 0x00ff);
    pBlock[8]  = pValue[0];
    pBlock[9]  = pValue[1];
    pBlock[10] = pValue[2];
    pBlock[11] = pValue[3];
    pBlock[12] = bAddrByte;
    pBlock[13] = (Byte) ~((bAddrByte & 0x00ff) & 0x00ff);
    pBlock[14] = bAddrByte;
    pBlock[15] = (Byte) ~((bAddrByte & 0x00ff) & 0x00ff);
    return [[NSData alloc] initWithBytes:pBlock length:16];
}

-(NSUInteger)getValue:(NSData *)valueData {
    NSUInteger value = 0;
    if ( (valueData == nil) || (valueData.length < 4) ) {
        return 0;
    }
    Byte *valueByte = (Byte *)[valueData bytes];
    value = ( ((valueByte[0] & 0x000000ff) << 24) | ((valueByte[1] & 0x000000ff) << 16) | ((valueByte[2] & 0x000000ff) << 8) | (valueByte[3] & 0x000000ff) );
    return value;
}

-(NSData *)getValueData:(NSUInteger)value {
    Byte bytes[] = {(Byte) (((value & 0xff000000) >> 24) & 0xff),
        (Byte) (((value & 0x00ff0000) >> 16) & 0xff),
        (Byte) (((value & 0x0000ff00) >> 8) & 0xff),
        (Byte) (((value & 0x000000ff) >> 0) & 0xff)};
    
    return [[NSData alloc] initWithBytes:bytes length:4];
}

@end











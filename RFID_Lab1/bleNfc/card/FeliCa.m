//
//  FeliCa.m
//  ble_nfc_sdk
//
//  Created by lochy on 16/10/23.
//  Copyright © 2016年 Lochy. All rights reserved.
//

#import "FeliCa.h"

onReceiveFelicaRequestResponseListener mOnReceiveFelicaRequestResponseListenerBlock = nil;
onReceiveFelicaRequestServiceListener mOnReceiveFelicaRequestServiceListenerBlock = nil;
onReceiveFelicaReadListener mOnReceiveFelicaReadListenerBlock = nil;
onReceiveFelicaWriteListener mOnReceiveFelicaWriteListenerBlock = nil;

@implementation FeliCa
//When receiving the RequestResponse command, the VICC shall respond.
-(void)requestFelicaResponseWithCallbackBlock:(onReceiveFelicaRequestResponseListener)block {
    mOnReceiveFelicaRequestResponseListenerBlock = block;
    Byte cmdBytes[] = {PHAL_FELICA_CMD_REQUEST_RESPONSE};
    NSData *cmdData = [[NSData alloc] initWithBytes:cmdBytes length:1];
    [self.deviceManager requestRfmFelicaCmd:PH_EXCHANGE_DEFAULT waitN:0 cmdData:cmdData callback:^(BOOL isSuc, NSData *returnData) {
        if (mOnReceiveFelicaRequestResponseListenerBlock != nil) {
            if ( isSuc && (returnData.length > 0) ) {
                mOnReceiveFelicaRequestResponseListenerBlock(isSuc, ((Byte*)[returnData bytes])[0]);
            }
            else {
                mOnReceiveFelicaRequestResponseListenerBlock(isSuc, 0);
            }
        }
    }];
}

-(void)requestFelicaService:(Byte)bTxNumServices
            serviceListData:(NSData *)pTxServiceList
              callbackBlock:(onReceiveFelicaRequestServiceListener)block {
    mOnReceiveFelicaRequestServiceListenerBlock = block;
    if (pTxServiceList.length != bTxNumServices * 2) {
        if (mOnReceiveFelicaRequestServiceListenerBlock != nil) {
            mOnReceiveFelicaRequestServiceListenerBlock(false, (Byte) 0, nil);
        }
        return;
    }
    
    Byte cmdBytes[] = {PHAL_FELICA_CMD_REQUEST_SERVICE, bTxNumServices};
    NSData *cmdData = [[NSData alloc] initWithBytes:cmdBytes length:2];
    [self.deviceManager requestRfmFelicaCmd:PH_EXCHANGE_BUFFER_FIRST waitN:bTxNumServices cmdData:cmdData callback:^(BOOL isSuc, NSData *returnData) {
        if (!isSuc) {
            if (mOnReceiveFelicaRequestServiceListenerBlock != nil) {
                mOnReceiveFelicaRequestServiceListenerBlock(false, (Byte) 0, nil);
            }
            return;
        }
        [self.deviceManager requestRfmFelicaCmd:PH_EXCHANGE_BUFFER_LAST waitN:bTxNumServices cmdData:pTxServiceList callback:^(BOOL isSuc, NSData *returnData) {
            Byte *returnBytes = (Byte *)[returnData bytes];
            if (!isSuc || (returnData.length < 1) || (returnData.length != (returnBytes[0] * 2) + 1 )) {
                if (mOnReceiveFelicaRequestServiceListenerBlock != nil) {
                    mOnReceiveFelicaRequestServiceListenerBlock(false, (Byte) 0, nil);
                }
                return;
            }
            if (mOnReceiveFelicaRequestServiceListenerBlock != nil) {
                Byte rxServiceList[returnBytes[0] * 2];
                memcpy(rxServiceList, &returnBytes[1], returnBytes[0] * 2);
                NSData *rxServiceListData = [[NSData alloc] initWithBytes:rxServiceList length:returnBytes[0] * 2];
                mOnReceiveFelicaRequestServiceListenerBlock(YES, returnBytes[0], rxServiceListData);
            }
        }];
    }];
}

-(void)felicaRead:(Byte)bNumServices
  serviceListData:(NSData *)pServiceList
        numBlocks:(Byte)bTxNumBlocks
    blockListData:(NSData *)pBlockList
    callbackBlock:(onReceiveFelicaReadListener)block {
    mOnReceiveFelicaReadListenerBlock = block;
    
    if (pServiceList.length != bNumServices * 2) {
        if (mOnReceiveFelicaReadListenerBlock != nil) {
            mOnReceiveFelicaReadListenerBlock(NO, (Byte) 0, nil);
        }
        return;
    }
    
    /* check correct number of services / blocks */
    if ((bNumServices < 1) || (bTxNumBlocks < 1)) {
        if (mOnReceiveFelicaReadListenerBlock != nil) {
            mOnReceiveFelicaReadListenerBlock(NO, (Byte) 0, nil);
        }
        return;
    }
    
    /* check blocklistlength against numblocks */
    if (pBlockList.length < (bTxNumBlocks * 2)  || pBlockList.length > (bTxNumBlocks * 3)) {
        if (mOnReceiveFelicaReadListenerBlock != nil) {
            mOnReceiveFelicaReadListenerBlock(NO, (Byte) 0, nil);
        }
        return;
    }
    
    Byte cmdBytes[] = {PHAL_FELICA_CMD_READ, bNumServices};
    NSData *cmdData = [[NSData alloc] initWithBytes:cmdBytes length:2];
    /* Exchange command and the number of services ... */
    [self.deviceManager requestRfmFelicaCmd:PH_EXCHANGE_BUFFER_FIRST waitN:bTxNumBlocks cmdData:cmdData callback:^(BOOL isSuc, NSData *returnData) {
        if (!isSuc) {
            if (mOnReceiveFelicaReadListenerBlock != nil) {
                mOnReceiveFelicaReadListenerBlock(NO, (Byte) 0, nil);
            }
            return;
        }
        /* ... the service code list ... */
        [self.deviceManager requestRfmFelicaCmd:PH_EXCHANGE_BUFFER_CONT waitN:bTxNumBlocks cmdData:pServiceList callback:^(BOOL isSuc, NSData *returnData) {
            if (!isSuc) {
                if (mOnReceiveFelicaReadListenerBlock != nil) {
                    mOnReceiveFelicaReadListenerBlock(NO, (Byte) 0, nil);
                }
                return;
            }
            /* ... the number of blocks ... */
            Byte bTxNumBlocksBytes[] = {bTxNumBlocks};
            NSData *cmdBlockNumData = [[NSData alloc] initWithBytes:bTxNumBlocksBytes length:1];
            [self.deviceManager requestRfmFelicaCmd:PH_EXCHANGE_BUFFER_CONT waitN:bTxNumBlocks cmdData:cmdBlockNumData callback:^(BOOL isSuc, NSData *returnData) {
                if (!isSuc) {
                    if (mOnReceiveFelicaReadListenerBlock != nil) {
                        mOnReceiveFelicaReadListenerBlock(NO, (Byte) 0, nil);
                    }
                    return;
                }
                /* ... and the block list. */
                [self.deviceManager requestRfmFelicaCmd:PH_EXCHANGE_BUFFER_LAST waitN:bTxNumBlocks cmdData:pBlockList callback:^(BOOL isSuc, NSData *returnData) {
                    Byte *returnBytes = (Byte *)[returnData bytes];
                    if ( !isSuc || (returnData.length < 2) || (returnBytes[0] != 0) || (returnData.length != (3 + (16 * returnBytes[2]))) ) {
                        if (mOnReceiveFelicaReadListenerBlock != nil) {
                            mOnReceiveFelicaReadListenerBlock(NO, (Byte) 0, nil);
                        }
                        return;
                    }
                    if (mOnReceiveFelicaReadListenerBlock != nil) {
                        Byte blockDataBytes[16 * returnBytes[2]];
                        memcpy(blockDataBytes, &returnBytes[3], 16 * returnBytes[2]);
                        NSData *blockData = [[NSData alloc] initWithBytes:blockDataBytes length:16 * returnBytes[2]];
                        mOnReceiveFelicaReadListenerBlock(isSuc, returnBytes[2], blockData);
                    }
                }];
            }];
        }];
    }];
}

-(void)felicaWrite:(Byte)bNumServices
   serviceListData:(NSData *)pServiceList
         numBlocks:(Byte)bNumBlocks
     blockListData:(NSData *)pBlockList
         blockData:(NSData *)pBlockData
     callbackBlock:(onReceiveFelicaWriteListener)block {
    mOnReceiveFelicaWriteListenerBlock = block;
    
    /* check correct number of services / blocks */
    if ((bNumServices < 1) || (bNumBlocks < 1)) {
        if (mOnReceiveFelicaWriteListenerBlock != nil) {
            mOnReceiveFelicaWriteListenerBlock(NO, nil);
        }
        return;
    }
    
    /* check blocklistlength against numblocks */
    if ((pBlockList.length < (bNumBlocks * 2))  || (pBlockList.length > (bNumBlocks * 3))) {
        if (mOnReceiveFelicaWriteListenerBlock != nil) {
            mOnReceiveFelicaWriteListenerBlock(NO, nil);
        }
        return;
    }
    
    Byte cmdBytes[] = {PHAL_FELICA_CMD_WRITE, bNumServices};
    NSData *cmdData = [[NSData alloc] initWithBytes:cmdBytes length:2];
    /* Exchange command and the number of services ... */
    [self.deviceManager requestRfmFelicaCmd:PH_EXCHANGE_BUFFER_FIRST waitN:bNumBlocks cmdData:cmdData callback:^(BOOL isSuc, NSData *returnData) {
        if (!isSuc) {
            if (mOnReceiveFelicaWriteListenerBlock != nil) {
                mOnReceiveFelicaWriteListenerBlock(NO, nil);
            }
            return;
        }
        /* ... the service code list ... */
        [self.deviceManager requestRfmFelicaCmd:PH_EXCHANGE_BUFFER_CONT waitN:bNumBlocks cmdData:pServiceList callback:^(BOOL isSuc, NSData *returnData) {
            if (!isSuc) {
                if (mOnReceiveFelicaWriteListenerBlock != nil) {
                    mOnReceiveFelicaWriteListenerBlock(NO, nil);
                }
                return;
            }
            /* ... the number of blocks ... */
            Byte bNumBlocksBytes[] = {bNumBlocks};
            NSData *cmdBlockNumData = [[NSData alloc] initWithBytes:bNumBlocksBytes length:1];
            [self.deviceManager requestRfmFelicaCmd:PH_EXCHANGE_BUFFER_CONT waitN:bNumBlocks cmdData:cmdBlockNumData callback:^(BOOL isSuc, NSData *returnData) {
                if (!isSuc) {
                    if (mOnReceiveFelicaWriteListenerBlock != nil) {
                        mOnReceiveFelicaWriteListenerBlock(NO, nil);
                    }
                    return;
                }
                /* ... the block list ... */
                [self.deviceManager requestRfmFelicaCmd:PH_EXCHANGE_BUFFER_CONT waitN:bNumBlocks cmdData:pBlockList callback:^(BOOL isSuc, NSData *returnData) {
                    if (!isSuc) {
                        if (mOnReceiveFelicaWriteListenerBlock != nil) {
                            mOnReceiveFelicaWriteListenerBlock(NO, nil);
                        }
                        return;
                    }
                    /* ... and the block data. */
                    [self.deviceManager requestRfmFelicaCmd:PH_EXCHANGE_BUFFER_LAST waitN:bNumBlocks cmdData:pBlockData callback:^(BOOL isSuc, NSData *returnData) {
                        Byte *returnBytes = (Byte *)[returnData bytes];
                        if ( (!isSuc) || (returnData.length < 2) || (returnBytes[0] != 0) ) {
                            if (mOnReceiveFelicaWriteListenerBlock != nil) {
                                mOnReceiveFelicaWriteListenerBlock(NO, nil);
                            }
                            return;
                        }
                        if (mOnReceiveFelicaWriteListenerBlock != nil) {
                            mOnReceiveFelicaWriteListenerBlock(NO, nil);
                        }
                    }];
                    
                }];
            }];
        }];
    }];
}
@end












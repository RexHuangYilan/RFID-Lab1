//
//  Mifare.h
//  ble_nfc_sdk
//
//  Created by lochy on 16/10/23.
//  Copyright © 2016年 Lochy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Card.h"

//Mifare Key type
#ifndef MIFARE_KEY_TYPE_A
#define  MIFARE_KEY_TYPE_A (0x0A)
#endif
#ifndef MIFARE_KEY_TYPE_B
#define  MIFARE_KEY_TYPE_B (0x0B)
#endif

#define  PHAL_MFC_CMD_RESTORE   ((Byte)0xC2)    /**< MIFARE Classic Restore command byte */
#define  PHAL_MFC_CMD_INCREMENT ((Byte)0xC1)    /**< MIFARE Classic Increment command byte */
#define  PHAL_MFC_CMD_DECREMENT ((Byte)0xC0)    /**< MIFARE Classic Decrement command byte */
#define  PHAL_MFC_CMD_TRANSFER  ((Byte)0xB0)    /**< MIFARE Classic Transfer command byte */
#define  PHAL_MFC_CMD_READ      ((Byte)0x30)    /**< MIFARE Classic Read command byte */
#define  PHAL_MFC_CMD_WRITE     ((Byte)0xA0)    /**< MIFARE Classic Write command byte */
#define  PHAL_MFC_CMD_AUTHA     ((Byte)0x60)    /**< MIFARE Classic Authenticate A command byte */
#define  PHAL_MFC_CMD_AUTHB     ((Byte) 0x61)    /**<MIFARE Classic Authenticate B command byte */
#define  PHAL_MFC_CMD_PERSOUID  ((Byte) 0x40)    /**< MIFARE Classic Personalize UID command */

//代码块定义
//验证回调接口
typedef void(^onReceiveMifareAuthenticateListener)(BOOL isSuc);
//数据交换回调接口
typedef void(^onReceiveMifareDataExchangeListener)(BOOL isSuc, NSData* returnData);
//读块回调
typedef void(^onReceiveMifareReadListener)(BOOL isSuc, NSData* returnData);
//写块回调
typedef void(^onReceiveMifareWriteListener)(BOOL isSuc);
//增值操作回调
typedef void(^onReceiveMifareIncrementTransferListener)(BOOL isSuc);
//减值操作回调
typedef void(^onReceiveMifareDecrementTransferListener)(BOOL isSuc);
typedef void(^onReceiveMifareRestoreTransferListener)(BOOL isSuc);
typedef void(^onReceiveMifarePersonalizeUidListener)(BOOL isSuc);
//Mifare读值回调
typedef void(^onReceiveMifareReadValueListener)(BOOL isSuc, Byte address, NSData* valueData);
//Mifare写值回调
typedef void(^onReceiveMifareWriteValueListener)(BOOL isSuc);


@interface Mifare : Card
/*
 * 方 法 名：mifareAuthenticate
 * 功    能：Mifare验证密钥
 * 参    数：byte bBlockNo - 验证的块
 *          byte bKeyType - 验证密码类型：MIFARE_KEY_TYPE_A 或者 MIFARE_KEY_TYPE_B
 *          byte[] pKey - 验证用到的密钥，6个字节
 *          block - 验证结果回调函数
 * 返回值：无
 */
-(void)mifareAuthenticate:(Byte)bBlockNo keyType:(Byte)bKeyType key:(NSData *)pKey callbackBlock:(onReceiveMifareAuthenticateListener)block;

/*
 * 方 法 名： mifareRead
 * 功    能：Mifare读块
 * 参    数：byte bBlockNo - 要读的块
 *          block - 读快结果回调函数
 * 返回值：无
 */
-(void)mifareRead:(Byte)blockNo callbackBlock:(onReceiveMifareReadListener)block;

/*
 * 方 法 名： mifareWrite
 * 功    能：Mifare写块
 * 参    数：byte bBlockNo - 要写的块
 *          blockData - 要写的数据，16byte
 *          block - 读快结果回调函数
 * 返回值：无
 */
-(void)mifareWrite:(Byte)blockNo data:(NSData *)blockData callbackBlock:(onReceiveMifareWriteListener)block;

//Perform MIFARE(R) Increment Transfer command sequence with MIFARE Picc.
//[in]  bSrcBlockNo  block number to be incremented.
//[in]  bDstBlockNo  block number to be transferred to.
//[in]  pValue  pValue[4] containing value (LSB first) to be incremented on the MIFARE(R) card
-(void)mifareIncrementTransfer:(Byte)bSrcBlockNo dstBlockNo:(Byte)bDstBlockNo value:(NSData *)pValue callbackBlock:(onReceiveMifareIncrementTransferListener)block;

//Perform MIFARE(R) Decrement Transfer command sequence with MIFARE Picc.
//[in]  bSrcBlockNo  block number to be decremented.
//[in]  bDstBlockNo  block number to be transferred to.
//[in]  pValue  pValue[4] containing value (LSB first) to be decremented on the MIFARE(R) card
-(void)mifareDecrementTransfer:(Byte)bSrcBlockNo dstBlockNo:(Byte)bDstBlockNo value:(NSData *)pValue callbackBlock:(onReceiveMifareDecrementTransferListener)block;

//Perform MIFARE(R) Restore Transfer command sequence with MIFARE Picc.
//[in]  bSrcBlockNo  block number to be decremented.
//[in]  bDstBlockNo  block number to be transferred to.
-(void)mifareRestoreTransfer:(Byte)bSrcBlockNo dstBlockNo:(Byte)bDstBlockNo callbackBlock:(onReceiveMifareRestoreTransferListener)block;

//Perform MIFARE(R) Personalize UID usage command sequence with MIFARE Picc.
//[in]  bUidType  UID type.
//      PHAL_MFC_UID_TYPE_UIDF0
//      PHAL_MFC_UID_TYPE_UIDF1
//      PHAL_MFC_UID_TYPE_UIDF2
//      PHAL_MFC_UID_TYPE_UIDF3
-(void)mifarePersonalizeUid:(Byte)bUidType callbackBlock:(onReceiveMifarePersonalizeUidListener)block;

/*
 * Perform MIFARE(R) Read Value command with MIFARE Picc.
 * [in]  bBlockNo  block number to be read.
 * [out]  pValue  pValue[4] containing value (LSB first) read from the MIFARE(R) card
 * [out]  pAddrData  pAddrData containing address read from the MIFARE(R) card value block
 */
-(void)mifareReadValue:(Byte)bBlockNo callbackBlock:(onReceiveMifareReadValueListener)block;

//Perform MIFARE(R) Write Value command with MIFARE Picc.
//[in]  bBlockNo  block number to be written.
//[in]  pValue  pValue[4] containing value (LSB first) to be written to the MIFARE(R) card
//[in]  bAddrData  bAddrData containing address written to the MIFARE(R) card value block
-(void)mifareWriteValue:(Byte)bBlockNo value:(NSData *)pValue addr:(Byte)pAddrData callbackBlock:(onReceiveMifareWriteValueListener)block;

/*
 * 方法名：mifareDataExchange
 * 功    能：Mifare数据交换
 * 参    数：data - 用户交换的数据
 *          block：数据交换的结果将通过block回调
 * 返回值：无
 */
-(void)mifareDataExchange:(NSData *)data callbackBlock:(onReceiveMifareDataExchangeListener)block;

-(BOOL)mifareCheckValueBlockFormat:(NSData *)pBlockData;
-(NSData *)createValueBlock:(NSData *)pValueData addr:(Byte)bAddrByte;
-(NSUInteger)getValue:(NSData *)valueData;
-(NSData *)getValueData:(NSUInteger)value;

@end


















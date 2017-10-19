//
//  FeliCa.h
//  ble_nfc_sdk
//
//  Created by lochy on 16/10/23.
//  Copyright © 2016年 Lochy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Card.h"

#define  PHAL_FELICA_CMD_REQUEST_RESPONSE     0x04    /**< Get the PICCs current mode. */
#define  PHAL_FELICA_CMD_REQUEST_SERVICE      0x02    /**< Get area key version and service key version. */
#define  PHAL_FELICA_CMD_READ                 0x06    /**< Read the record value of the specified service. */
#define  PHAL_FELICA_CMD_WRITE                0x08    /**< Write records of the specified service. */
#define  PHAL_FELICA_RSP_REQUEST_RESPONSE     0x05    /**< Response code to the Request Response command. */
#define  PHAL_FELICA_RSP_REQUEST_SERVICE      0x03    /**< Response code to the Request Service command. */
#define  PHAL_FELICA_RSP_READ                 0x07    /**< Response code to the Read command. */
#define  PHAL_FELICA_RSP_WRITE                0x09    /**< Response code to the Write command. */

//代码块定义
//mode - Current Card Mode. (0, 1, 2).
typedef void(^onReceiveFelicaRequestResponseListener)(BOOL isSuc, Byte mode);

//[out]  pRxNumServices  Number of received services or areas.
//[out]  pRxServiceList  Received Service Key version or area version list, max 64 bytes.
typedef void(^onReceiveFelicaRequestServiceListener)(BOOL isSuc, Byte pRxNumServices, NSData* pRxServiceList);

//[out]  pRxNumBlocks  Number of received blocks.
//[out]  pBlockData  Received Block data.
typedef void(^onReceiveFelicaReadListener)(BOOL isSuc, Byte pRxNumBlocks, NSData* pBlockData);

typedef void(^onReceiveFelicaWriteListener)(BOOL isSuc, NSData *returnData);

@interface FeliCa : Card
//When receiving the RequestResponse command, the VICC shall respond.
-(void)requestFelicaResponseWithCallbackBlock:(onReceiveFelicaRequestResponseListener)block;

//When receiving the RequestService command, the VICC shall respond.
//[in]  bTxNumServices  Number of services or areas within the command message.
//[in]  pTxServiceList  Service code or area code list within the command message.
-(void)requestFelicaService:(Byte)bTxNumServices
            serviceListData:(NSData *)pTxServiceList
              callbackBlock:(onReceiveFelicaRequestServiceListener)block;

//When receiving the Read command, the VICC shall respond.
//[in]  bNumServices  Number of Services.
//[in]  pServiceList  List of Services.
//[in]  bTxNumBlocks  Number of Blocks to send.
//[in]  pBlockList  List of Blocks to read.
-(void)felicaRead:(Byte)bNumServices
  serviceListData:(NSData *)pServiceList
        numBlocks:(Byte)bTxNumBlocks
    blockListData:(NSData *)pBlockList
    callbackBlock:(onReceiveFelicaReadListener)block;

//When receiving the Write command, the VICC shall respond.
//[in]  bNumServices  Number of Services.
//[in]  pServiceList  List of Services.
//[in]  bNumBlocks  Number of Blocks to send.
//[in]  pBlockList  List of Blocks to write.
//[in]  pBlockData  Block data to write.
-(void)felicaWrite:(Byte)bNumServices
   serviceListData:(NSData *)pServiceList
         numBlocks:(Byte)bTxNumBlocks
     blockListData:(NSData *)pBlockList
         blockData:(NSData *)pBlockData
     callbackBlock:(onReceiveFelicaWriteListener)block;
@end








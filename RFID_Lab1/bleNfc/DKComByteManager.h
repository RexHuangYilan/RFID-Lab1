//
//  ComByteManager.h
//  ble_nfc_sdk
//
//  Created by Lochy on 16/6/22.
//  Copyright © 2016年 Lochy. All rights reserved.
//

#import <Foundation/Foundation.h>

//Command define
#define  PAL_TEST_CHANNEL        ((Byte)0x00)            //通讯协议测试通道
#define  MIFARE_AUTH_COM         ((Byte)0x40)            //MIFARE卡验证密钥指令
#define  MIFARE_COM              ((Byte)0x41)            //Mifare卡指令通道
#define  ACTIVATE_PICC_COM       ((Byte)0x62)            //激活卡片指令
#define  APDU_COM                ((Byte)0x6F)            //apdu指令
#define  BPDU_COM                ((Byte)0x7F)            //Bpdu指令
#define  ANTENNA_OFF_COM         ((Byte)0x6E)            //关闭天线指令
#define  GET_BT_VALUE_COM        ((Byte)0x70)            //获取电池电量
#define  GET_VERSIONS_COM        ((Byte)0x71)            //获取设备版本号指令
#define  ULTRALIGHT_CMD          ((Byte)0xD0)            //UL卡指令通道
#define  GET_SUICA_BALANCE_COM   ((Byte)0xF0)            //获取suica余额
#define  FELICA_READ_COM         ((Byte)0xF1)            //读FeliCa指令
#define  FELICA_COM              ((Byte)0xF2)            //FeliCa指令通道

//Comand run result define
#define  COMAND_RUN_SUCCESSFUL   ((Byte)0x90)            //命令运行成功
#define  COMAND_RUN_ERROR        ((Byte)0x6E)            //命令运行出错

//Error code defie
#define  NO_ERROR_CODE           ((Byte)0x00)            //运行正确时的错误码
#define  DEFAULT_ERROR_CODE      ((Byte)0x81)            //默认错误码

#define  ISO14443_P3                    1
#define  ISO14443_P4                    2
#define  PH_EXCHANGE_DEFAULT            0x0000
#define  PH_EXCHANGE_LEAVE_BUFFER_BIT   0x4000
#define  PH_EXCHANGE_BUFFERED_BIT       0x8000
#define  PH_EXCHANGE_BUFFER_FIRST       PH_EXCHANGE_DEFAULT | PH_EXCHANGE_BUFFERED_BIT
#define  PH_EXCHANGE_BUFFER_CONT        PH_EXCHANGE_DEFAULT | PH_EXCHANGE_BUFFERED_BIT | PH_EXCHANGE_LEAVE_BUFFER_BIT
#define  PH_EXCHANGE_BUFFER_LAST        PH_EXCHANGE_DEFAULT | PH_EXCHANGE_LEAVE_BUFFER_BIT

//Mifare Key type
#define  MIFARE_KEY_TYPE_A              ((Byte)0x0A)
#define  MIFARE_KEY_TYPE_B              ((Byte)0x0B)

#define  Start_Frame                    0
#define  Follow_Frame                   1

#define  MAX_FRAME_NUM                  63
#define  MAX_FRAME_LEN                  20
#define  MAX_FRAME_DATA_LEN             (MAX_FRAME_NUM * MAX_FRAME_LEN)

#define  Rcv_Status_Idle                0
#define  Rcv_Status_Start               1
#define  Rcv_Status_Follow              2
#define  Rcv_Status_Complete            3

//DKComByteManager代理
@protocol DKComByteManagerDelegate <NSObject>
-(void)comByteManagerCallback:(BOOL)isSuc rcvData:(NSData *)rcvData;
@end

@interface DKComByteManager : NSObject
@property (nonatomic) id<DKComByteManagerDelegate> delegate;

-(id)initWhitDelegate:(id)theDelegate;
-(Byte)getCmd;
-(BOOL)getCmdRunStatus;
-(NSInteger)getRcvDataLen;
-(BOOL)rcvData:(NSData *)rcvData;

//A卡激活指令
+(NSData *)cardActivityComData;
//指定激活卡片到哪一个协议层，例如cpu卡当成m1卡用时必须用此指令进行寻卡
+(NSData *)cardActivityComData:(Byte)protocolLayer;
//去激活指令(关闭天线)
+(NSData *)rfPowerOffComData;
//获取蓝牙读卡器电池电压指令
+(NSData *)getBtValueComData;
//获取设备版本号指令
+(NSData *)getVerisionsComData;
//非接接口Apdu指令
+(NSData *)rfApduCmdData:(NSData *)ApduData;
//Felica读余额指令通道
+(NSData *)requestRfmSuicaBalance;
//Felica读指令通道
+(NSData *)requestRfmFelicaRead:(NSData *)systemCode blockAddr:(NSData *)blockAddr;
//Felica指令通道
//wOption:PH_EXCHANGE_DEFAULT/PH_EXCHANGE_BUFFER_FIRST/PH_EXCHANGE_BUFFER_CONT/PH_EXCHANGE_BUFFER_LAST
//wN:等待时间
//data：指令
+(NSData *)felicaCmdData:(NSInteger)wOption waitN:(NSInteger)wN data:(NSData *)data;
//UL指令通道
+(NSData *)ultralightCmdData:(NSData *)ulCmdData;
//Bpdu指令通道
+(NSData *)rfBpduCmdData:(NSData *)BpduData;
//Mifare卡验证密码指令
+(NSData *)rfMifareAuthCmdData:(Byte)bBlockNo keyType:(Byte)bKeyType key:(NSData *)pKey uid:(NSData *)pUid;
//Mifarek卡数据交换指令
+(NSData *)rfMifareDataExchangeCmdData:(NSData *)data;
//通信协议测试通道指令
+(NSData *)getTestChannelData:(NSData *)data;
@end








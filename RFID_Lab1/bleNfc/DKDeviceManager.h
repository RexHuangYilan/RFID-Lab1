//
//  DeviceManager.h
//  ble_nfc_sdk
//
//  Created by Lochy on 16/6/22.
//  Copyright © 2016年 Lochy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

typedef NSUInteger DKCardType;
NS_ENUM(DKCardType) {
    DKCardTypeDefault = 0,
    DKIso14443A_CPUType = 1,
    DKIso14443B_CPUType = 2,
    DKFeliCa_Type = 3,
    DKMifare_Type = 4,
    DKIso15693_Type = 5,
    DKUltralight_type = 6,
    DKDESFire_type = 7
};

//代码块定义
//获取设备连接回调
typedef void(^onReceiveConnectBtDeviceListener)(BOOL blnIsConnectSuc);
//断开设备连接回调
typedef void(^onReceiveDisConnectDeviceListener)(BOOL blnIsDisConnectDevice);
//检测设备状态回调
typedef void(^onReceiveConnectionStatusListener)(BOOL blnIsConnection);
//获取设备电量回调
typedef void(^onReceiveDeviceBtValueListener)(float btVlueMv);
//获取设备固件版本号回调
typedef void(^onReceiveDeviceVersionListener)(NSUInteger versionNum);
//非接寻卡回调
typedef void(^onReceiveRfnSearchCardListener)(BOOL isblnIsSus, DKCardType cardType, NSData *CardSn, NSData *bytCarATS);
//发送APDU指令回调
typedef void(^onReceiveRfmSentApduCmdListener)(BOOL isSuc, NSData *ApduRtnData);
//发送BPDU指令回调
typedef void(^onReceiveRfmSentBpduCmdListener)(BOOL isSuc, NSData *BpduRtnData);
//关闭天线回调
typedef void(^onReceiveRfmCloseListener)(BOOL blnIsCloseSuc);
//获取suica余额回调
typedef void(^onReceiveRfmSuicaBalanceListener)(BOOL blnIsSuc, NSData *BalanceData);
//读Felica回调
typedef void(^onReceiveRfmFelicaReadListener)(BOOL blnIsReadSuc, NSData *BlockData);
//Felica指令通道回调
typedef void(^onReceiveRfmFelicaCmdListener)(BOOL isSuc, NSData *returnData);
//ul卡指令接口回调
typedef void(^onReceiveRfmUltralightCmdListener)(BOOL isSuc, NSData *ulCmdRtnData);
//Mifare卡验证密码回调
typedef void(^onReceiveRfmMifareAuthListener)(BOOL isSuc);
//Mifare数据交换通道回调
typedef void(^onReceiveRfmMifareDataExchangeListener)(BOOL isSuc, NSData *returnData);
//测试通道回调
typedef void(^onReceivePalTestChannelListener)(NSData *returnData);


@interface DKDeviceManager : NSObject
//回调代码块设置相关接口
-(void)setOnReceiveConnectBtDeviceListenerBlock:(onReceiveConnectBtDeviceListener)block;
-(void)setOnReceiveDisConnectDeviceListenerBlock:(onReceiveDisConnectDeviceListener)block;
-(void)setOnReceiveConnectionStatusListenerBlock:(onReceiveConnectionStatusListener)block;
-(void)setOnReceiveDeviceBtValueListenerBlock:(onReceiveDeviceBtValueListener)block;
-(void)setOnReceiveDeviceVersionListenerBlock:(onReceiveDeviceVersionListener)block;
-(void)setOnReceiveRfnSearchCardListenerBlock:(onReceiveRfnSearchCardListener)block;
-(void)setOnReceiveRfmSentApduCmdListenerBlock:(onReceiveRfmSentApduCmdListener)block;
-(void)setOnReceiveRfmSentBpduCmdListenerBlock:(onReceiveRfmSentBpduCmdListener)block;
-(void)setOnReceiveRfmCloseListenerBlock:(onReceiveRfmCloseListener)block;
-(void)setOnReceiveRfmSuicaBalanceListenerBlock:(onReceiveRfmSuicaBalanceListener)block;
-(void)setOnReceiveRfmFelicaReadListenerBlock:(onReceiveRfmFelicaReadListener)block;
-(void)setOnReceiveRfmUltralightCmdListenerBlock:(onReceiveRfmUltralightCmdListener)block;
-(void)setOnReceiveRfmFelicaCmdListenerBlock:(onReceiveRfmFelicaCmdListener)block;
-(void)setOnReceiveRfmMifareAuthListenerBlock:(onReceiveRfmMifareAuthListener)block;
-(void)setOnReceiveRfmMifareDataExchangeListenerBlock:(onReceiveRfmMifareDataExchangeListener)block;
-(void)setOnReceivePalTestChannelListenerBlock:(onReceivePalTestChannelListener)block;
//-(void)requestConnectBleDevice:(CBPeripheral *)peripheral connectCallbackBlock:(onReceiveConnectBtDeviceListener)block;
//-(void)requestDisConnectDeviceWithCallbackBlock:(onReceiveDisConnectDeviceListener)block;
//-(void)requestConnectionStatusWithCallbackBlock:(onReceiveConnectionStatusListener)block;

/*************************************************************************************
 *  方法名：   getCard
 *  功能：     获取卡片实例
 *  入口参数：  无
 *  返回参数：  卡片的实例
 *  作者：     Lochy.Huang
 *************************************************************************************/
-(id)getCard;

/*************************************************************************************
 *  方法名：   requestDeviceBtValueWithCallbackBlock:
 *  功能：     获取设备电池电压，单位v
 *  入口参数：  block：操作结果会通过block回调
 *  返回参数：  无
 *  作者：     Lochy.Huang
 *************************************************************************************/
-(void)requestDeviceBtValueWithCallbackBlock:(onReceiveDeviceBtValueListener)block;

/*************************************************************************************
 *  方法名：   requestDeviceVersionWithCallbackBlock:
 *  功能：     获取设备版本号 1byte
 *  入口参数：  block：操作结果会通过block回调
 *  返回参数：  无
 *  作者：     Lochy.Huang
 *************************************************************************************/
-(void)requestDeviceVersionWithCallbackBlock:(onReceiveDeviceVersionListener)block;

/*************************************************************************************
 *  方法名：   requestRfmSearchCard: callbackBlock
 *  功能：     寻卡（寻卡成功会自动打开天线，寻卡失败会自动关闭天线）
 *  入口参数：  cardType：寻卡类型 目前支持 DKCardTypeDefault
 *            block：操作结果会通过block回调
 *  返回参数：  无
 *  作者：     Lochy.Huang
 *************************************************************************************/
-(void)requestRfmSearchCard:(DKCardType)cardType callbackBlock:(onReceiveRfnSearchCardListener)block;

/*************************************************************************************
 *  方法名：   requestRfmSentApduCmd: callbackBlock
 *  功能：     发送apdu指令，此命令只对iso14443-a的cpu卡有效
 *  入口参数：  apduData：要发送的apdu指令数据
 *            block：操作结果会通过block回调
 *  返回参数：  无
 *  作者：     Lochy.Huang
 *************************************************************************************/
-(void)requestRfmSentApduCmd:(NSData *)apduData callbackBlock:(onReceiveRfmSentApduCmdListener)block;

/*************************************************************************************
 *  方法名：   requestRfmSentBpduCmd: callbackBlock
 *  功能：     发送apdu指令，此命令只对身份证有效
 *  入口参数：  apduData：要发送的apdu指令数据
 *            block：操作结果会通过block回调
 *  返回参数：  无
 *  作者：     Lochy.Huang
 *************************************************************************************/
-(void)requestRfmSentBpduCmd:(NSData *)apduData callbackBlock:(onReceiveRfmSentBpduCmdListener)block;

/*************************************************************************************
 *  方法名：   requestRfmCloseWhitCallbackBlock:
 *  功能：     关闭天线指令（寻卡成功会自动打开天线）
 *  入口参数：  block：操作结果会通过block回调
 *  返回参数：  无
 *  作者：     Lochy.Huang
 *************************************************************************************/
-(void)requestRfmCloseWhitCallbackBlock:(onReceiveRfmCloseListener)block;

/*************************************************************************************
 *  方法名：   requestRfmSuicaBalanceWhitCallbackBlock:
 *  功能：     读取suica（FeliCa协议）余额
 *  入口参数：  block：操作结果会通过block回调，回调中会返回6个字节数据，前两字节为小数点余数，后四位
 *            为整数位，低位在前。
 *  返回参数：  无
 *  作者：     Lochy.Huang
 *************************************************************************************/
-(void)requestRfmSuicaBalanceWhitCallbackBlock:(onReceiveRfmSuicaBalanceListener)block;

/*************************************************************************************
 *  方法名：   requestRfmFelicaRead:
 *  功能：     读felica块数据
 *  入口参数：  systemCode：系统码，两字节，高位在前
 *            blockAddr：要读的块地址
 *            block：回调，回调中返回读到的块数据，总共16字节
 *  返回参数：  无
 *  作者：     Lochy.Huang
 *************************************************************************************/
-(void)requestRfmFelicaRead:(NSData *)systemCode blockAddr:(NSData *)blockAddr callback:(onReceiveRfmFelicaReadListener)block;

/*************************************************************************************
 *  方法名：   requestRfmUltralightCmd:
 *  功能：     UL卡指令接口
 *  入口参数：  ulCmdData：ul指令
 *            block：回调，回调中返回指令运行的结果
 *  返回参数：  无
 *  作者：     Lochy.Huang
 *************************************************************************************/
-(void)requestRfmUltralightCmd:(NSData *)ulCmdData callback:(onReceiveRfmUltralightCmdListener)block;

/*************************************************************************************
 *  方法名：   requestRfmFelicaCmd:
 *  功能：     Felica卡指令接口
 *  入口参数：  wOption: PH_EXCHANGE_DEFAULT/PH_EXCHANGE_BUFFER_FIRST/PH_EXCHANGE_BUFFER_CONT/
                       PH_EXCHANGE_BUFFER_LAST
 *            wN: 等待时间
 *            data: 指令
 *            block: 指令结果通过block返回
 *  返回参数：  无
 *  作者：     Lochy.Huang
 *************************************************************************************/
-(void)requestRfmFelicaCmd:(NSInteger)wOption waitN:(NSInteger)wN cmdData:(NSData *)data callback:(onReceiveRfmFelicaCmdListener)block;

/*************************************************************************************
 *  方法名：   requestRfmMifareAuth:
 *  功能：     Mifare卡验证密码
 *  入口参数：  bBlockNo：需要验证密码到块地址
 *            keyType: 密码类型 MIFARE_KEY_TYPE_A or MIFARE_KEY_TYPE_B
 *            key: 6字节密码
 *            uid: 4字节uid
 *            block：回调，回调中返回验证的结果
 *  返回参数：  无
 *  作者：     Lochy.Huang
 *************************************************************************************/
-(void)requestRfmMifareAuth:(Byte)bBlockNo keyType:(Byte)bKeyType key:(NSData *)key uid:(NSData *)uid callback:(onReceiveRfmMifareAuthListener)block;

/*************************************************************************************
 *  方法名：   requestRfmMifareDataExchange:
 *  功能：     Mifare卡数据通道
 *  入口参数：  data：需要与卡片交换地数据
 *            block：回调，回调中返回指令运行的结果
 *  返回参数：  无
 *  作者：     Lochy.Huang
 *************************************************************************************/
-(void)requestRfmMifareDataExchange:(NSData *)data callback:(onReceiveRfmMifareDataExchangeListener)block;

/*************************************************************************************
 *  方法名：   requestPalTestChannel:
 *  功能：     通讯协议测试通道
 *  入口参数：  data：从上位机到读卡器到数据
 *            block：回调，回调中返回指令运行的结果
 *  返回参数：  无
 *  作者：     Lochy.Huang
 *************************************************************************************/
-(void)requestPalTestChannel:(NSData *)data callback:(onReceivePalTestChannelListener)block;
@end

















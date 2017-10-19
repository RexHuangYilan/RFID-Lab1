//
//  BleManager.h
//  ble_nfc_sdk
//
//  Created by Lochy on 16/6/22.
//  Copyright © 2016年 Lochy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#define DK_SERVICE_UUID            @"FFF0"
#define DK_APDU_CHANNEL_UUID       @"FFF2"

//代码块定义
typedef void(^onScannerCallbackListener)(
                                         CBCentralManager* central,
                                         CBPeripheral* peripheral,
                                         NSDictionary* advertisementData,
                                         NSNumber* RSSI);
typedef void(^onReceiveDataListener)(NSData* data);
typedef void(^onBleConnectListener)(BOOL isConnectSucceed);
typedef void(^onBleDisconnectListener)(void);
typedef void(^onBleReadListener)(NSData* data);
typedef void(^onWriteSuccessListener)(void);




//BleManager代理
@protocol DKBleManagerDelegate <NSObject>
/*
 * 函数说明：蓝牙搜索回调
 */
-(void)DKScannerCallback:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI;

/*
 * 函数说明：蓝牙状态回调
 */
-(void)DKCentralManagerDidUpdateState:(CBCentralManager *)central;

//蓝牙连接状态回调
//NO:断开连接
//yes:连接成功
-(void)DKCentralManagerConnectState:(CBCentralManager *)central state:(BOOL)state;
@end





@interface DKBleManager : NSObject
@property (nonatomic) id<DKBleManagerDelegate> delegate;
@property (nonatomic,strong) CBCharacteristic  *apduCharacteristic;      //APDU指令通道特征值

-(id)initWithDelegate:(id)theDelegate;
+ (DKBleManager *)sharedInstance;

//代码块设置相关
-(void)setOnScannerCallbackListenerBlock:(onScannerCallbackListener)block;
-(void)setOnReceiveDataListenerBlock:(onReceiveDataListener)block;
-(void)setOnBleConnectListenerBlock:(onBleConnectListener)block;
-(void)setOnBleDisconnectListenerBlock:(onBleDisconnectListener)block;
-(void)setOnBleReadListenerBlock:(onBleReadListener)block;
-(void)setonWriteSuccessListenerBlock:(onWriteSuccessListener)block;

//搜索蓝牙相关
/*************************************************************************************
 *  方法名：   startScan
 *  功能：     启动查询,一直查询，直到连接蓝牙或者调用stopScan；搜索结果会通过代理
 *            DKBleManagerDelegate中的DKScannerCallback回调
 *  入口参数：  无
 *  返回参数：  无
 *  作者：     Lochy.Huang
 *************************************************************************************/
-(void)startScan;

/*************************************************************************************
 *  方法名：   startScanWithCallbackBlock
 *  功能：     启动查询,一直查询，直到连接蓝牙或者调用stopScan；搜索结果会回调到block，同时也会通
 *            过代理DKBleManagerDelegate中的DKScannerCallback回调
 *  入口参数：  block：搜索结果会回调到block
 *  返回参数：  无
 *  作者：     Lochy.Huang
 *************************************************************************************/
-(void)startScanWithCallbackBlock:(onScannerCallbackListener)block;

/*************************************************************************************
 *  方法名：   startScanWithTimeout:
 *  功能：     启动查询,查询超时时间为timeout，单位ms；搜索结果会通
 *            过代理DKBleManagerDelegate中的DKScannerCallback回调
 *  入口参数：  timeout：搜索超时时间，单位ms
 *  返回参数：  无
 *  作者：     Lochy.Huang
 *************************************************************************************/
-(void)startScanWithTimeout:(NSInteger)timeout;

/*************************************************************************************
 *  方法名：   startScanWithTimeout: callbackBlock:
 *  功能：     启动查询,查询超时时间为timeout，单位ms；搜索结果会回调到block，同时也会通
 *            过代理DKBleManagerDelegate中的DKScannerCallback回调
 *  入口参数：  timeout：搜索超时时间，单位ms
 *            block：搜索结果会回调到block
 *  返回参数：  无
 *  作者：     Lochy.Huang
 *************************************************************************************/
-(void)startScanWithTimeout:(NSInteger)timeout callbackBlock:(onScannerCallbackListener)block;

/*************************************************************************************
 *  方法名：   stopScan
 *  功能：     停止搜索
 *  入口参数：  无
 *  返回参数：  无
 *  作者：     Lochy.Huang
 *************************************************************************************/
-(void)stopScan;

/*************************************************************************************
 *  方法名：   isScanning
 *  功能：     返回是否正在搜索
 *  入口参数：  无
 *  返回参数：  YES:正在搜索  NO:已停止搜索
 *  作者：     Lochy.Huang
 *************************************************************************************/
-(Boolean)isScanning;

//连接蓝牙相关
/*************************************************************************************
 *  方法名：   connect:
 *  功能：     连接设备，连接成功／失败会通过DKBleManagerDelegate中的DKCentralManagerConnectState回调
 *  入口参数：  peripheral：需要连接的设备
 *  返回参数：  YES:操作失败  NO:操作成功 （注意：返回到操作成功与失败不是连接成功和失败）
 *  作者：     Lochy.Huang
 *************************************************************************************/
-(Boolean)connect:(CBPeripheral *)peripheral;

/*************************************************************************************
 *  方法名：   connect: callbackBlock:
 *  功能：     连接设备，带回调，连接成功／失败会回调到block，同时也会通过DKBleManagerDelegate中
 *            的DKCentralManagerConnectState回调
 *  入口参数：  peripheral：需要连接的设备
 *  返回参数：  YES:操作失败  NO:操作成功 （注意：返回到操作成功与失败不是连接成功和失败）
 *  作者：     Lochy.Huang
 *************************************************************************************/
-(Boolean)connect:(CBPeripheral *)peripheral callbackBlock:(onBleConnectListener)block;

/*************************************************************************************
 *  方法名：   cancelConnect
 *  功能：     断开连接，断开连接成功/失败会会通过DKBleManagerDelegate中
 *            的DKCentralManagerConnectState回调 （注意：此函数会断开所有连接的设备）
 *  入口参数：  无
 *  返回参数：  YES:操作失败  NO:操作成功 （注意：返回到操作成功与失败不是断开连接成功和失败）
 *  作者：     Lochy.Huang
 *************************************************************************************/
-(Boolean)cancelConnect;

/*************************************************************************************
 *  方法名：   cancelConnectWithCallbackBlock: callbackBlock:
 *  功能：     断开连接设备，带回调，断开连接成功／失败会回调到block，同时也会通过DKBleManagerDelegate中
 *            的DKCentralManagerConnectState回调 （注意：此函数会断开所有连接的设备）
 *  入口参数：  无
 *  返回参数：  YES:操作失败  NO:操作成功 （注意：返回到操作成功与失败不是连接成功和失败）
 *  作者：     Lochy.Huang
 *************************************************************************************/
-(Boolean)cancelConnectWithCallbackBlock:(onBleDisconnectListener)block;

/*************************************************************************************
 *  方法名：   isConnect
 *  功能：     查询当前是否已经连接上设备
 *  入口参数：  无
 *  返回参数：  YES:已经连接  NO:未连接
 *  作者：     Lochy.Huang
 *************************************************************************************/
-(Boolean)isConnect;

//发送数据相关
/*************************************************************************************
 *  方法名：   wtireDataToCharacteristic: writeData:
 *  功能：     通过特征值发生数据，超过20字节的数据将会被分包发生
 *  入口参数：  characteristic：操作的特征值
 *            writeData: 发送的数据
 *  返回参数：  YES:操作成功  NO:操作失败
 *  作者：     Lochy.Huang
 *************************************************************************************/
-(Boolean)wtireDataToCharacteristic:(CBCharacteristic *)characteristic writeData:(NSData *)writeData;

//-(Boolean)wtireDataToCharacteristic:(CBCharacteristic *)characteristic  writeData:(NSData *)writeData onReceiveDataCallbackBlock:(onReceiveDataListener)block;
@end















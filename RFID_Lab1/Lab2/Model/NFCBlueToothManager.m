//
//  NFCBlueToothManager.m
//  RFID_Lab1
//
//  Created by Rex on 2017/12/9.
//  Copyright © 2017年 Rex. All rights reserved.
//

#import "NFCBlueToothManager.h"
#import "DKBleNfc.h"
#import "NFCObject.h"

#import "ConnectViewController.h"

NSString *BluetoothDisConnectNotification = @"BluetoothDisConnectNotification";
NSString *BluetoothConnectNotification = @"BluetoothConnectNotification";

#define SEARCH_BLE_NAME   @"BLE_NFC"

typedef void(^NFCBlueToothManagerDataSuccess)(NSData *data);
typedef void(^NFCBlueToothManagerSuccess)(void);
typedef void(^NFCBlueToothManagerConnectAndCheckKeySuccess)(Mifare *card,NFCBlueToothManagerSuccess connectDone);

@interface NFCBlueToothManager()
<
DKBleManagerDelegate
>

@property (readonly) DKBleManager *bleManager;
@property (nonatomic, strong) DKDeviceManager *deviceManager;

@property (nonatomic) BLENFCStatus status;
@property (nonatomic, strong) NFCDeviceInfoObject *info;
@property (nonatomic, strong) CBPeripheral *mNearestBle;

@end

@implementation NFCBlueToothManager

NSInteger lastRssi = -100;

#pragma mark - init

+(instancetype)sharedInstance {
    static NFCBlueToothManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
        sharedInstance.bleManager.delegate = sharedInstance;
    });
    return sharedInstance;
}

#pragma mark - get

-(DKBleManager *)bleManager
{
    return [DKBleManager sharedInstance];
}

-(DKDeviceManager *)deviceManager
{
    if (!_deviceManager) {
        _deviceManager = [[DKDeviceManager alloc] init];
    }
    return _deviceManager;
}

#pragma mark - set

-(void)setStatus:(BLENFCStatus)status
{
    _status = status;
    if ([self.delegate respondsToSelector:@selector(deviceChangeStatus:)]) {
        [self.delegate deviceChangeStatus:status];
    }
    if (status == BLENFCStatusNoConnect)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:BluetoothDisConnectNotification
                                                            object:nil];
    }
}

#pragma mark - private

//找到最近的NFC並連接
-(void)fineNearBle{
    int searchCnt = 0;
    while ((self.mNearestBle == nil) && (searchCnt++ < 5000) && ([self.bleManager isScanning])) {
        [NSThread sleepForTimeInterval:0.001f];
    }
    [NSThread sleepForTimeInterval:1.0f];
    [self.bleManager stopScan];
    if (self.mNearestBle == nil) {
        //沒找到設備
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"沒找到設備");
            self.status = BLENFCStatusNoConnect;
        });
    }
    else{
        //開始連接NFC
        dispatch_async(dispatch_get_main_queue(), ^{
            self.status = BLENFCStatusLoading;
        });
        [self.bleManager connect:self.mNearestBle callbackBlock:^(BOOL isConnectSucceed) {
            if (isConnectSucceed) {
                //成功
                dispatch_async(dispatch_get_main_queue(), ^{
                    //                    [self.msgBuffer setString:@"設備連接成功！\n"];
                    //                    self.mssage = self.msgBuffer;
                    self.status = BLENFCStatusConnect;
                    //取得設備訊息
                    [self getDeviceMsg];
                });
            }else {
                //失敗
                dispatch_async(dispatch_get_main_queue(), ^{
                    //                    self.mssage = @"設備中斷！";
                    self.status = BLENFCStatusNoConnect;
                });
            }
        }];
    }
}

//取得設備訊息
-(void)getDeviceMsg {
    __weak typeof(self) weakSelf = self;
    [self.deviceManager requestDeviceVersionWithCallbackBlock:^(NSUInteger versionNum) {
        [weakSelf.deviceManager requestDeviceBtValueWithCallbackBlock:^(float btVlueMv) {
            NFCDeviceInfoObject *obj = [NFCDeviceInfoObject initWithVersion:versionNum voltage:btVlueMv];
            weakSelf.info = obj;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:BluetoothConnectNotification
                                                                object:nil];
        }];
    }];
}

-(void)checkKeyWithCard:(Mifare *)card
                    nfc:(NFCObject *)nfcObject
           successBlock:(NFCBlueToothManagerSuccess)successBlock
             errorBlock:(NFCBlueToothManagerError)errorBlock
{
    NSData *keyData = [nfcObject keyData];
    
    [card mifareAuthenticate:nfcObject.authenticate keyType:nfcObject.keyAB == NFCKeyABA? MIFARE_KEY_TYPE_A:MIFARE_KEY_TYPE_B key:keyData callbackBlock:^(BOOL isSuc) {
        if (!isSuc) {
            if (errorBlock) {
                errorBlock([NSError errorWithCode:BLENFCErrorCodePasswordError]);
            }
        }else{
            if (successBlock) {
                successBlock();
            }
        }
    }];
}

-(void)readDataWithCard:(Mifare *)card
                    nfc:(NFCObject *)nfcObject
           successBlock:(NFCBlueToothManagerDataSuccess)successBlock
             errorBlock:(NFCBlueToothManagerError)errorBlock
{
    [card mifareRead:nfcObject.authenticate callbackBlock:^(BOOL isSuc, NSData *returnData) {
        if (!isSuc) {
            if (errorBlock) {
                errorBlock([NSError errorWithCode:BLENFCErrorCodeLoadDataError
                                           object:nfcObject]);
            }
        }else {
            if (successBlock) {
                successBlock(returnData);
            }
        }
    }];
}

-(void)writeDataWithCard:(Mifare *)card
                     nfc:(NFCObject *)nfcObject
            successBlock:(NFCBlueToothManagerSuccess)successBlock
              errorBlock:(NFCBlueToothManagerError)errorBlock
{
    
    [card mifareWrite:nfcObject.authenticate data:nfcObject.data callbackBlock:^(BOOL isSuc) {
        if (!isSuc) {
            if (errorBlock) {
                errorBlock([NSError errorWithCode:BLENFCErrorCodeWriteDataError
                                           object:nfcObject]);
            }
        }else {
            if (successBlock) {
                successBlock();
            }
        }
    }];
}

-(NSArray<NFCObject *> *)readDataWithCard:(Mifare *)card
                                     nfcs:(NSArray<NFCObject *> *)nfcObjects
                               errorBlock:(NFCBlueToothManagerError)errorBlock
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSMutableArray<NFCObject *> *resultArray = [NSMutableArray array];
    __block BOOL stop = NO;
    
    __weak typeof(self) weakSelf = self;
    
    for (NFCObject *nfc in nfcObjects)
    {
        [self checkKeyWithCard:card nfc:nfc successBlock:^{
            NSLog(@"驗證密碼完成");
            [weakSelf readDataWithCard:card nfc:nfc successBlock:^(NSData *data) {
                
                NSLog(@"資料讀取完成 - %@",nfc);
                nfc.data = data;
                [resultArray addObject:nfc];
                dispatch_semaphore_signal(semaphore);
                
            } errorBlock:^(NSError * _Nonnull error) {
                
                NSLog(@"資料讀取失敗 - %@",nfc);
                if (errorBlock) {
                    errorBlock(error);
                }
                stop = YES;
                dispatch_semaphore_signal(semaphore);
            }];
        } errorBlock:^(NSError * _Nonnull error) {
            
            NSLog(@"驗證密碼失敗");
            if (errorBlock) {
                errorBlock(error);
            }
        }];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        if (stop) {
            break;
        }
    }
    if (!stop) {
        return resultArray;
    }else{
        return nil;
    }
}

-(NSArray<NFCObject *> *)writeDataWithCard:(Mifare *)card
                                      nfcs:(NSArray<NFCObject *> *)nfcObjects
                                errorBlock:(NFCBlueToothManagerError)errorBlock
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSMutableArray<NFCObject *> *resultArray = [NSMutableArray array];
    __block BOOL stop = NO;
    __weak typeof(self) weakSelf = self;
    
    for (NFCObject *nfc in nfcObjects)
    {
        [self checkKeyWithCard:card nfc:nfc successBlock:^{
            NSLog(@"驗證密碼完成");
            [weakSelf writeDataWithCard:card nfc:nfc successBlock:^{
                
                NSLog(@"寫入資料完成 - %@",nfc);
                [resultArray addObject:nfc];
                dispatch_semaphore_signal(semaphore);
                
            } errorBlock:^(NSError * _Nonnull error) {
                
                NSLog(@"寫入資料失敗 - %@",nfc);
                if (errorBlock) {
                    errorBlock(error);
                }
                stop = YES;
                dispatch_semaphore_signal(semaphore);
            }];
        } errorBlock:^(NSError * _Nonnull error) {
            
            NSLog(@"驗證密碼失敗");
            if (errorBlock) {
                errorBlock(error);
            }
        }];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        if (stop) {
            break;
        }
    }
    if (!stop) {
        return resultArray;
    }else{
        return nil;
    }
}

-(void)connectSuccessBlock:(NFCBlueToothManagerConnectAndCheckKeySuccess)successBlock
                errorBlock:(NFCBlueToothManagerError)errorBlock
{
    __weak typeof(self) weakSelf = self;
    
    [self.deviceManager requestRfmSearchCard:DKCardTypeDefault callbackBlock:^(BOOL isblnIsSus, DKCardType cardType, NSData *CardSn, NSData *bytCarATS) {
        if (isblnIsSus) {
            if (cardType == DKMifare_Type) { //找到M1卡
                Mifare *card = [weakSelf.deviceManager getCard];
                if (card != nil) {
                    NSLog(@"Get Migare,ID:%@",card.uid);
                    
                    dispatch_queue_t serialQueue = dispatch_queue_create("com.htw.ble.nfc", DISPATCH_QUEUE_SERIAL);
                    dispatch_async(serialQueue, ^{
                        
                        if (successBlock) {
                            successBlock(card,^{
                                [card close];
                            });
                        }
                    });
                }
            }
        }else{
            if (errorBlock) {
                errorBlock([NSError errorWithCode:BLENFCErrorCodeNoCardError]);
            }
        }
    }];
}

#pragma mark - pubic

-(void)scanNFC
{
    self.status = BLENFCStatusLoading;
    self.mNearestBle = nil;
    lastRssi = -100;
    [self.bleManager startScan];
    [NSThread detachNewThreadSelector:@selector(fineNearBle) toTarget:self withObject:nil];
}

-(void)readCardWithNFCs:(NSArray<NFCObject *> *)nfcs
           successBlock:(NFCBlueToothManagerArraySuccess)successBlock
             errorBlock:(NFCBlueToothManagerError)errorBlock
{
    if (nfcs.count == 0) {
        if (successBlock) {
            successBlock(@[]);
        }
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    
    [self connectSuccessBlock:^(Mifare *card,NFCBlueToothManagerSuccess connectDone) {
        
        NSArray *resultArray = [weakSelf readDataWithCard:card
                                                     nfcs:nfcs
                                               errorBlock:errorBlock];
        connectDone();
        dispatch_async(dispatch_get_main_queue(), ^{
            if (successBlock && resultArray) {
                successBlock(resultArray);
            }
        });
        
    } errorBlock:errorBlock];
}

-(void)writeCardWithNFCs:(NSArray<NFCObject *> *)nfcs
            successBlock:(NFCBlueToothManagerArraySuccess)successBlock
              errorBlock:(NFCBlueToothManagerError)errorBlock
{
    if (nfcs.count == 0) {
        if (successBlock) {
            successBlock(@[]);
        }
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    
    [self connectSuccessBlock:^(Mifare *card,NFCBlueToothManagerSuccess connectDone) {
        
        NSArray *resultArray = [weakSelf writeDataWithCard:card
                                                      nfcs:nfcs
                                                errorBlock:errorBlock];
        connectDone();
        dispatch_async(dispatch_get_main_queue(), ^{
            if (successBlock && resultArray) {
                successBlock(resultArray);
            }
        });
    } errorBlock:errorBlock];
}

#pragma mark - DKBleManagerDelegate

-(void)DKScannerCallback:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    if ([peripheral.name isEqualToString:SEARCH_BLE_NAME]) {
        NSLog(@"找到設備：%@ %@", peripheral, RSSI);
        if (self.mNearestBle != nil) {
            if ([RSSI integerValue] > lastRssi) {
                self.mNearestBle = peripheral;
            }
        }
        else {
            self.mNearestBle = peripheral;
            lastRssi = [RSSI integerValue];
        }
    }
}

#pragma mark - DKBleManagerDelegate
-(void)DKCentralManagerDidUpdateState:(CBCentralManager *)central {
    NSError *error = nil;
    switch (central.state) {
        case CBManagerStatePoweredOn://藍牙開啟
        {
            //pendingInit = NO;
            //[self startToGetDeviceList];
        }
            break;
        case CBManagerStatePoweredOff://藍牙關閉
        {
            error = [NSError errorWithDomain:@"CBCentralManagerStatePoweredOff" code:-1 userInfo:nil];
        }
            break;
        case CBManagerStateResetting://藍牙重置
        {
            //pendingInit = YES;
        }
            break;
        case CBManagerStateUnknown://
        {
            error = [NSError errorWithDomain:@"CBCentralManagerStateUnknown" code:-1 userInfo:nil];
        }
            break;
        case CBManagerStateUnsupported://設備不支援
        {
            error = [NSError errorWithDomain:@"CBCentralManagerStateUnsupported" code:-1 userInfo:nil];
        }
            break;
        default:
            break;
    }
}

//藍牙狀態
-(void)DKCentralManagerConnectState:(CBCentralManager *)central state:(BOOL)state{
    if (state) {
        NSLog(@"成功");
        self.status = BLENFCStatusConnect;
    }
    else {
        NSLog(@"失敗");
        dispatch_async(dispatch_get_main_queue(), ^{
            self.status = BLENFCStatusNoConnect;
        });
    }
}

@end


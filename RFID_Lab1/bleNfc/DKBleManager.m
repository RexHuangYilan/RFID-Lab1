//
//  BleManager.m
//  ble_nfc_sdk
//
//  Created by Lochy on 16/6/22.
//  Copyright © 2016年 Lochy. All rights reserved.
//

#import "DKBleManager.h"
#import "NSData+Hex.h"

#define myLog(a, b)  NSLog(a,b)
//#define myLog(a, b) NSLog(@"")

@interface DKBleManager() <CBCentralManagerDelegate, CBPeripheralDelegate>
@property (nonatomic,strong) CBCentralManager  *manager;
@property (nonatomic,strong) NSMutableArray    *peripherals;             //所有蓝牙设备列
@property (nonatomic,strong) CBPeripheral      *currentPeripheral;       //当前活动的蓝牙设备字典（已连接）
@end

@implementation DKBleManager
@synthesize manager;
@synthesize peripherals;
@synthesize currentPeripheral;
@synthesize apduCharacteristic;

static DKBleManager *BLInstance;
static bool scanFlag = NO;
static bool connectFlag = NO;
static bool writeFinishFlag = NO;
static onScannerCallbackListener onScannerCallbackListenerBlock = nil;
static onReceiveDataListener onReceiveDataListenerBlock = nil;
static onBleConnectListener onBleConnectListenerBlock = nil;
static onBleDisconnectListener onBleDisconnectListenerBlock = nil;
static onBleReadListener onBleReadListenerBlock = nil;
static onWriteSuccessListener onWriteSuccessListenerBlock = nil;
+ (DKBleManager *)sharedInstance {   //获取配置信息
    if (!BLInstance) {
        BLInstance = [[DKBleManager alloc] init];
    }
    return BLInstance;
}

//初始化
- (id)init {
    self = [super init];//获得父类的对象并进行初始化
    if (self){
        self.manager = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
        self.peripherals = [[NSMutableArray alloc] init];
    }
    return self;
}

//带代理初始化
-(id)initWithDelegate:(id)theDelegate {
    self = [super init];
    if (self){
        self.delegate = theDelegate;
        self.manager = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
        self.peripherals = [[NSMutableArray alloc] init];
    }
    return self;
}

//代码块设置相关
-(void)setOnScannerCallbackListenerBlock:(onScannerCallbackListener)block {
    onScannerCallbackListenerBlock = block;
}
-(void)setOnReceiveDataListenerBlock:(onReceiveDataListener)block {
    onReceiveDataListenerBlock = block;
}
-(void)setOnBleConnectListenerBlock:(onBleConnectListener)block {
    onBleConnectListenerBlock = block;
}
-(void)setOnBleDisconnectListenerBlock:(onBleDisconnectListener)block {
    onBleDisconnectListenerBlock = block;
}
-(void)setOnBleReadListenerBlock:(onBleReadListener)block {
    onBleReadListenerBlock = block;
}
-(void)setonWriteSuccessListenerBlock:(onWriteSuccessListener)block {
    onWriteSuccessListenerBlock = block;
}

//搜索蓝牙相关
-(void)startScan {
    if (scanFlag) {
        return;
    }
    if (self.manager == nil) {
        return;
    }
    scanFlag = YES;
    [peripherals removeAllObjects];
    [self.manager scanForPeripheralsWithServices:nil options:nil];
}
-(void)startScanWithCallbackBlock:(onScannerCallbackListener)block {
    onScannerCallbackListenerBlock = block;
    [self startScan];
}
-(void)startScanWithTimeout:(NSInteger)timeout {
    if (scanFlag) {
        return;
    }
    [self startScan];
    [NSTimer scheduledTimerWithTimeInterval:timeout target:self selector:@selector(stopSearch:) userInfo:nil repeats:NO];
}
-(void)startScanWithTimeout:(NSInteger)timeout callbackBlock:(onScannerCallbackListener)block {
    if (scanFlag) {
        return;
    }
    onScannerCallbackListenerBlock = block;
    [self startScanWithTimeout:timeout];
}
-(void)stopScan{
    if (self.manager == nil) {
        return;
    }
    [self.manager stopScan];
    scanFlag = NO;
}
-(Boolean)isScanning{
    return scanFlag;
}
-(void)stopSearch:(NSTimer *)t {
    [self stopScan];
}

//连接蓝牙相关
-(Boolean)connect:(CBPeripheral *)peripheral{
    if (self.manager == nil) {
        return NO;
    }
    [self stopScan];
    peripheral.delegate = self;
    [self.manager connectPeripheral:peripheral options:nil];
    return YES;
}
-(Boolean)connect:(CBPeripheral *)peripheral callbackBlock:(onBleConnectListener)block{
    if (self.manager == nil) {
        return NO;
    }
    onBleConnectListenerBlock = block;
    return [self connect:peripheral];
}
-(Boolean)cancelConnect{
    if ( (self.peripherals == nil) || (self.peripherals.count == 0) ) {
        return NO;
    }
    if (self.manager == nil) {
        return NO;
    }
    for (CBPeripheral *thePeripheral in self.peripherals) {
        if (thePeripheral.state == CBPeripheralStateConnected) {
            [self.manager cancelPeripheralConnection:thePeripheral];
        }
    }
    if (self.currentPeripheral != nil) {
        [self.manager cancelPeripheralConnection:self.currentPeripheral];
    }
    return YES;
}
-(Boolean)cancelConnectWithCallbackBlock:(onBleDisconnectListener)block{
    onBleDisconnectListenerBlock = block;
    return [self cancelConnect];
}
-(Boolean)isConnect{
    if ( self.currentPeripheral != nil ) {
        return (self.currentPeripheral.state == CBPeripheralStateConnected);
    }
    return NO;
}

//发送数据相关
-(Boolean)wtireDataToCharacteristic:(CBCharacteristic *)characteristic  writeData:(NSData *)writeData{
    if (self.currentPeripheral == nil) {
        return NO;
    }
    if (self.manager == nil) {
        return NO;
    }
    if (characteristic == nil) {
        return NO;
    }
    //[self.currentPeripheral writeValue:writeData forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int idx = 0;
        for (idx=0; idx+20 <= writeData.length; idx+=20) {
            NSRange range = NSMakeRange(idx, 20);
            NSData *sendTemp = [writeData subdataWithRange:range];
            
            writeFinishFlag = 0;
            [self.currentPeripheral writeValue:sendTemp forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
            
            int i = 0;
            while (!writeFinishFlag && (++i < 20)){
                [NSThread sleepForTimeInterval:0.001f];
                [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
            }
            myLog(@"发送数据：%@", sendTemp);
        }
        
        if (writeData.length % 20 != 0) {
            NSRange range = NSMakeRange(idx, writeData.length % 20);
            NSData *sendTemp = [writeData subdataWithRange:range];
            
            writeFinishFlag = 0;
            [self.currentPeripheral writeValue:sendTemp forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
            int i = 0;
            while (!writeFinishFlag && (++i < 20)){
                [NSThread sleepForTimeInterval:0.001f];
                [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
            }
            myLog(@"发送数据：%@", sendTemp);
        }
    });
    return YES;
}
-(Boolean)wtireDataToCharacteristic:(CBCharacteristic *)characteristic  writeData:(NSData *)writeData onReceiveDataCallbackBlock:(onReceiveDataListener)block{
    onReceiveDataListenerBlock = block;
    return [self wtireDataToCharacteristic:characteristic writeData:writeData];
}

//手机蓝牙状态回调
#pragma mark - CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (self.delegate && [self.delegate respondsToSelector:@selector(DKCentralManagerDidUpdateState:)]) {
        [self.delegate DKCentralManagerDidUpdateState:central];
    }
    
    NSError *error = nil;
    switch (central.state) {
        case CBCentralManagerStatePoweredOn://蓝牙打开
        {
            //pendingInit = NO;
            //[self startToGetDeviceList];
        }
            break;
        case CBCentralManagerStatePoweredOff://蓝牙关闭
        {
            error = [NSError errorWithDomain:@"CBCentralManagerStatePoweredOff" code:-1 userInfo:nil];
        }
            break;
        case CBCentralManagerStateResetting://蓝牙重置
        {
            //pendingInit = YES;
        }
            break;
        case CBCentralManagerStateUnknown://未知状态
        {
            error = [NSError errorWithDomain:@"CBCentralManagerStateUnknown" code:-1 userInfo:nil];
        }
            break;
        case CBCentralManagerStateUnsupported://设备不支持
        {
            error = [NSError errorWithDomain:@"CBCentralManagerStateUnsupported" code:-1 userInfo:nil];
        }
            break;
        default:
            break;
    }
}

//发现蓝牙设备回调
#pragma mark - CBCentralManagerDelegate
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    [peripherals addObject:peripheral];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(DKScannerCallback: didDiscoverPeripheral: advertisementData: RSSI:)]) {
        [self.delegate DKScannerCallback:central
                   didDiscoverPeripheral:peripheral
                       advertisementData:advertisementData
                                    RSSI:RSSI];
    }
    if (onScannerCallbackListenerBlock != nil) {
        onScannerCallbackListenerBlock(central, peripheral, advertisementData, RSSI);
    }
}

//链接成功回调
#pragma mark - CBCentralManagerDelegate
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    //启动搜索服务
    [peripheral discoverServices:nil];
}

//连接失败回调
#pragma mark - CBCentralManagerDelegate
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    if (self.delegate && [self.delegate respondsToSelector:@selector(DKCentralManagerConnectState: state:)]) {
        [self.delegate DKCentralManagerConnectState:central
                                              state:NO];
    }
    
    connectFlag = NO;
    if (onBleConnectListenerBlock != nil) {
        onBleConnectListenerBlock(NO);
    }
}

//连接成功后再断开连接回调
#pragma mark - CBCentralManagerDelegate
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    if (self.delegate && [self.delegate respondsToSelector:@selector(DKCentralManagerConnectState: state:)]) {
        [self.delegate DKCentralManagerConnectState:central
                                              state:NO];
    }
    
    if ( connectFlag ) {
        connectFlag = NO;
        if (onBleDisconnectListenerBlock != nil) {
            onBleDisconnectListenerBlock();
        }
    }
    else {
        if (onBleConnectListenerBlock != nil) {
            onBleConnectListenerBlock(NO);
        }
    }
}

//已发现服务回调
#pragma mark - CBPeripheralDelegate
-(void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    if (!error) {
        myLog(@"发现服务.%@", peripheral.services);
        bool searchFlag = NO;
        for (CBService *theService in peripheral.services) {
            if ([theService.UUID.data isEqualToData:[NSData dataWithHexString:DK_SERVICE_UUID]]) {
                searchFlag = YES;
                [peripheral discoverCharacteristics:nil forService:theService];
                break;
            }
        }
        
        if (!searchFlag) {
            [self cancelConnect];
        }
    }
    else {
        myLog(@"发现服务.%@", error);
        [self cancelConnect];
    }
}

//已搜索到Characteristics回调
#pragma mark - CBPeripheralDelegate
-(void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    if (!error) {
        bool apduFlag = NO;
        for (CBCharacteristic *theCharacteristic in service.characteristics) {
            if ([theCharacteristic.UUID.data isEqualToData:[NSData dataWithHexString:DK_APDU_CHANNEL_UUID]]) {
                self.apduCharacteristic = theCharacteristic;
                //设置notify
                [peripheral setNotifyValue:YES forCharacteristic:theCharacteristic];
                apduFlag = YES;
            }
        }
        
        if (apduFlag) {
            self.currentPeripheral = peripheral;
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(DKCentralManagerConnectState: state:)]) {
                [self.delegate DKCentralManagerConnectState:nil
                                                      state:YES];
            }
            
            connectFlag = YES;
            if (onBleConnectListenerBlock != nil) {
                onBleConnectListenerBlock(YES);
            }
        }
        else {
            [self cancelConnect];
        }
    }
    else {
        [self cancelConnect];
    }
}

//获取外设发来的数据，不论是read和notify,获取数据都是从这个方法中读取。
#pragma mark - CBPeripheralDelegate
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if ( (self.apduCharacteristic != nil) && (self.apduCharacteristic == characteristic) ){
        
    }
    
    myLog(@"接收到数据%@", characteristic.value);
    
    if (onReceiveDataListenerBlock != nil) {
        onReceiveDataListenerBlock(characteristic.value);
    }
}

//写完成回调
#pragma mark - CBPeripheralDelegate
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error; {
    writeFinishFlag = YES;
    if ( (onWriteSuccessListenerBlock != nil) ) {
        onWriteSuccessListenerBlock();
    }
}

//通知开关状态变化回调
#pragma mark - CBPeripheralDelegate
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error; {
    
}

//发现特征值描述回调
#pragma mark - CBPeripheralDelegate
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error; {
    
}

//特征值描述改变回调
#pragma mark - CBPeripheralDelegate
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error; {
    
}

//写特征值描述完成回调
#pragma mark - CBPeripheralDelegate
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error; {
    
}

@end

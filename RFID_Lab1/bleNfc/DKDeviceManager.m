//
//  DeviceManager.m
//  ble_nfc_sdk
//
//  Created by Lochy on 16/6/22.
//  Copyright © 2016年 Lochy. All rights reserved.
//

#import "DKDeviceManager.h"
#import "DKBleManager.h"
#import "DKComByteManager.h"
#import "NSData+Hex.h"
#import "DKBleNfc.h"

@interface DKDeviceManager() <DKComByteManagerDelegate>
@property(nonatomic,strong)DKComByteManager *comByteManager;
@property(nonatomic,strong)CpuCard          *cpuCard;
@property(nonatomic,strong)Ultralight       *ultralight;
@property(nonatomic,strong)Ntag21x          *ntag21x;
@property(nonatomic,strong)Mifare           *mifare;
@property(nonatomic,strong)Iso14443bCard    *iso14443bCard;
@property(nonatomic,strong)FeliCa           *feliCa;
@property(nonatomic,strong)DESFire          *desFire;
@property(nonatomic,strong)Iso15693Card     *iso15693Card;
@end

@implementation DKDeviceManager
@synthesize comByteManager;
static DKCardType mCardType;

//获取设备连接回调
onReceiveConnectBtDeviceListener onReceiveConnectBtDeviceListenerBlock = nil;
//断开设备连接回调
onReceiveDisConnectDeviceListener onReceiveDisConnectDeviceListenerBlock = nil;
//检测设备状态回调
onReceiveConnectionStatusListener onReceiveConnectionStatusListenerBlock = nil;
//获取设备电量回调
onReceiveDeviceBtValueListener onReceiveDeviceBtValueListenerBlock = nil;
//获取设备固件版本号回调
onReceiveDeviceVersionListener onReceiveDeviceVersionListenerBlock = nil;
//非接寻卡回调
onReceiveRfnSearchCardListener onReceiveRfnSearchCardListenerBlock = nil;
//发送APDU指令回调
onReceiveRfmSentApduCmdListener onReceiveRfmSentApduCmdListenerBlock = nil;
//发送BPDU指令回调
onReceiveRfmSentBpduCmdListener onReceiveRfmSentBpduCmdListenerBlock = nil;
//关闭天线回调
onReceiveRfmCloseListener onReceiveRfmCloseListenerBlock = nil;
//获取suica余额回调
onReceiveRfmSuicaBalanceListener onReceiveRfmSuicaBalanceListenerBlock = nil;
//读Felica回调
onReceiveRfmFelicaReadListener onReceiveRfmFelicaReadListenerBlock = nil;
//Felica指令通道回调
onReceiveRfmFelicaCmdListener onReceiveRfmFelicaCmdListenerBlock = nil;
//UL卡指令接口回调
onReceiveRfmUltralightCmdListener onReceiveRfmUltralightCmdListenerBlock = nil;
//Mifare卡验证密码回调
onReceiveRfmMifareAuthListener onReceiveRfmMifareAuthListenerBlock = nil;
//Mifare数据交换通道回调
onReceiveRfmMifareDataExchangeListener onReceiveRfmMifareDataExchangeListenerBlock = nil;
//测试通道回调
onReceivePalTestChannelListener onReceivePalTestChannelListenerBlock = nil;

-(id)init{
    self = [super init];//获得父类的对象并进行初始化
    if (self) {
        self.cpuCard = nil;
        self.ultralight = nil;
        self.ntag21x = nil;
        self.mifare = nil;
        self.iso14443bCard = nil;
        self.feliCa = nil;
        self.desFire = nil;
        self.iso15693Card = nil;
        mCardType = DKCardTypeDefault;
        self.comByteManager = [[DKComByteManager alloc] initWhitDelegate:self];
        [[DKBleManager sharedInstance] setOnReceiveDataListenerBlock:^(NSData *data) {
            [self.comByteManager rcvData:data];
        }];
    }
    return self;
}

//获取卡片
-(id)getCard{
    switch (mCardType) {
        case DKIso14443A_CPUType:
        return self.cpuCard;
        
        case DKIso14443B_CPUType:
        return self.iso14443bCard;
        
        case DKFeliCa_Type:
        return self.feliCa;
        
        case DKMifare_Type:
        return self.mifare;
        
        case DKIso15693_Type:
        return self.iso15693Card;
        
        case DKUltralight_type:
        return self.ultralight;
        
        case DKDESFire_type:
        return self.desFire;
        
        default:
        return nil;
    }
}

//代码块设置
-(void)setOnReceiveConnectBtDeviceListenerBlock:(onReceiveConnectBtDeviceListener)block {
    onReceiveConnectBtDeviceListenerBlock = block;
}
-(void)setOnReceiveDisConnectDeviceListenerBlock:(onReceiveDisConnectDeviceListener)block{
    onReceiveDisConnectDeviceListenerBlock = block;
}
-(void)setOnReceiveConnectionStatusListenerBlock:(onReceiveConnectionStatusListener)block{
    onReceiveConnectionStatusListenerBlock = block;
}
-(void)setOnReceiveDeviceBtValueListenerBlock:(onReceiveDeviceBtValueListener)block{
    onReceiveDeviceBtValueListenerBlock = block;
}
-(void)setOnReceiveDeviceVersionListenerBlock:(onReceiveDeviceVersionListener)block{
    self.OnReceiveDeviceVersionListenerBlock = block;
}
-(void)setOnReceiveRfnSearchCardListenerBlock:(onReceiveRfnSearchCardListener)block{
    onReceiveRfnSearchCardListenerBlock = block;
}
-(void)setOnReceiveRfmSentApduCmdListenerBlock:(onReceiveRfmSentApduCmdListener)block{
    onReceiveRfmSentApduCmdListenerBlock = block;
}
-(void)setOnReceiveRfmSentBpduCmdListenerBlock:(onReceiveRfmSentBpduCmdListener)block{
    onReceiveRfmSentBpduCmdListenerBlock = block;
}
-(void)setOnReceiveRfmCloseListenerBlock:(onReceiveRfmCloseListener)block{
    onReceiveRfmCloseListenerBlock = block;
}
-(void)setOnReceiveRfmSuicaBalanceListenerBlock:(onReceiveRfmSuicaBalanceListener)block{
    onReceiveRfmSuicaBalanceListenerBlock = block;
}
-(void)setOnReceiveRfmFelicaReadListenerBlock:(onReceiveRfmFelicaReadListener)block{
    onReceiveRfmFelicaReadListenerBlock = block;
}
-(void)setOnReceiveRfmUltralightCmdListenerBlock:(onReceiveRfmUltralightCmdListener)block{
    onReceiveRfmUltralightCmdListenerBlock = block;
}
-(void)setOnReceiveRfmFelicaCmdListenerBlock:(onReceiveRfmFelicaCmdListener)block {
    onReceiveRfmFelicaCmdListenerBlock = block;
}
-(void)setOnReceiveRfmMifareAuthListenerBlock:(onReceiveRfmMifareAuthListener)block {
    onReceiveRfmMifareAuthListenerBlock = block;
}
-(void)setOnReceiveRfmMifareDataExchangeListenerBlock:(onReceiveRfmMifareDataExchangeListener)block {
    onReceiveRfmMifareDataExchangeListenerBlock = block;
}
-(void)setOnReceivePalTestChannelListenerBlock:(onReceivePalTestChannelListener)block {
    onReceivePalTestChannelListenerBlock = block;
}


-(void)requestConnectBleDevice:(CBPeripheral *)peripheral
          connectCallbackBlock:(onReceiveConnectBtDeviceListener)block {
    onReceiveConnectBtDeviceListenerBlock = block;
    [[DKBleManager sharedInstance] connect:peripheral callbackBlock:^(BOOL isConnectSucceed) {
        block(isConnectSucceed);
    }];
}
-(void)requestDisConnectDeviceWithCallbackBlock:(onReceiveDisConnectDeviceListener)block {
    onReceiveDisConnectDeviceListenerBlock = block;
    [[DKBleManager sharedInstance] cancelConnectWithCallbackBlock:^{
        block(YES);
    }];
}
-(void)requestConnectionStatusWithCallbackBlock:(onReceiveConnectionStatusListener)block {
    onReceiveConnectionStatusListenerBlock = block;
    block([[DKBleManager sharedInstance] isConnect]);
}
-(void)requestDeviceBtValueWithCallbackBlock:(onReceiveDeviceBtValueListener)block{
    onReceiveDeviceBtValueListenerBlock = block;
    CBCharacteristic * theCharacteristic = [DKBleManager sharedInstance].apduCharacteristic;
    NSData *theData = [DKComByteManager getBtValueComData];
    [[DKBleManager sharedInstance] wtireDataToCharacteristic:theCharacteristic writeData:theData];
}
-(void)requestDeviceVersionWithCallbackBlock:(onReceiveDeviceVersionListener)block{
    onReceiveDeviceVersionListenerBlock = block;
    CBCharacteristic * theCharacteristic = [DKBleManager sharedInstance].apduCharacteristic;
    NSData *theData = [DKComByteManager getVerisionsComData];
    [[DKBleManager sharedInstance] wtireDataToCharacteristic:theCharacteristic writeData:theData];
}
-(void)requestRfmSearchCard:(DKCardType)cardType callbackBlock:(onReceiveRfnSearchCardListener)block{
    onReceiveRfnSearchCardListenerBlock = block;
    CBCharacteristic * theCharacteristic = [DKBleManager sharedInstance].apduCharacteristic;
    NSData *theData = [DKComByteManager cardActivityComData:cardType];
    [[DKBleManager sharedInstance] wtireDataToCharacteristic:theCharacteristic writeData:theData];
}
-(void)requestRfmSentApduCmd:(NSData *)apduData callbackBlock:(onReceiveRfmSentApduCmdListener)block{
    onReceiveRfmSentApduCmdListenerBlock = block;
    CBCharacteristic * theCharacteristic = [DKBleManager sharedInstance].apduCharacteristic;
    NSData *theData = [DKComByteManager rfApduCmdData:apduData];
    [[DKBleManager sharedInstance] wtireDataToCharacteristic:theCharacteristic writeData:theData];
}
-(void)requestRfmSentBpduCmd:(NSData *)apduData callbackBlock:(onReceiveRfmSentBpduCmdListener)block{
    onReceiveRfmSentBpduCmdListenerBlock = block;
    CBCharacteristic * theCharacteristic = [DKBleManager sharedInstance].apduCharacteristic;
    NSData *theData = [DKComByteManager rfBpduCmdData:apduData];
    [[DKBleManager sharedInstance] wtireDataToCharacteristic:theCharacteristic writeData:theData];
}
-(void)requestRfmCloseWhitCallbackBlock:(onReceiveRfmCloseListener)block{
    onReceiveRfmCloseListenerBlock = block;
    CBCharacteristic * theCharacteristic = [DKBleManager sharedInstance].apduCharacteristic;
    NSData *theData = [DKComByteManager rfPowerOffComData];
    [[DKBleManager sharedInstance] wtireDataToCharacteristic:theCharacteristic writeData:theData];
}
-(void)requestRfmSuicaBalanceWhitCallbackBlock:(onReceiveRfmSuicaBalanceListener)block{
    onReceiveRfmSuicaBalanceListenerBlock = block;
    CBCharacteristic * theCharacteristic = [DKBleManager sharedInstance].apduCharacteristic;
    NSData *theData = [DKComByteManager requestRfmSuicaBalance];
    [[DKBleManager sharedInstance] wtireDataToCharacteristic:theCharacteristic writeData:theData];
}
-(void)requestRfmFelicaRead:(NSData *)systemCode blockAddr:(NSData *)blockAddr callback:(onReceiveRfmFelicaReadListener)block{
    onReceiveRfmFelicaReadListenerBlock = block;
    CBCharacteristic * theCharacteristic = [DKBleManager sharedInstance].apduCharacteristic;
    NSData *theData = [DKComByteManager requestRfmFelicaRead:systemCode blockAddr:blockAddr];
    [[DKBleManager sharedInstance] wtireDataToCharacteristic:theCharacteristic writeData:theData];
}
-(void)requestRfmUltralightCmd:(NSData *)ulCmdData callback:(onReceiveRfmUltralightCmdListener)block{
    onReceiveRfmUltralightCmdListenerBlock = block;
    CBCharacteristic * theCharacteristic = [DKBleManager sharedInstance].apduCharacteristic;
    NSData *theData = [DKComByteManager ultralightCmdData:ulCmdData];
    [[DKBleManager sharedInstance] wtireDataToCharacteristic:theCharacteristic writeData:theData];
}

-(void)requestRfmFelicaCmd:(NSInteger)wOption waitN:(NSInteger)wN cmdData:(NSData *)data callback:(onReceiveRfmFelicaCmdListener)block{
    onReceiveRfmFelicaCmdListenerBlock = block;
    CBCharacteristic * theCharacteristic = [DKBleManager sharedInstance].apduCharacteristic;
    NSData *theData = [DKComByteManager felicaCmdData:wOption waitN:wN data:data];
    [[DKBleManager sharedInstance] wtireDataToCharacteristic:theCharacteristic writeData:theData];
}
-(void)requestRfmMifareAuth:(Byte)bBlockNo keyType:(Byte)bKeyType key:(NSData *)key uid:(NSData *)uid callback:(onReceiveRfmMifareAuthListener)block{
    onReceiveRfmMifareAuthListenerBlock = block;
    CBCharacteristic * theCharacteristic = [DKBleManager sharedInstance].apduCharacteristic;
    NSData *theData = [DKComByteManager rfMifareAuthCmdData:bBlockNo keyType:bKeyType key:key uid:uid];
    [[DKBleManager sharedInstance] wtireDataToCharacteristic:theCharacteristic writeData:theData];
}
-(void)requestRfmMifareDataExchange:(NSData *)data callback:(onReceiveRfmMifareDataExchangeListener)block {
    onReceiveRfmMifareDataExchangeListenerBlock = block;
    CBCharacteristic * theCharacteristic = [DKBleManager sharedInstance].apduCharacteristic;
    NSData *theData = [DKComByteManager rfMifareDataExchangeCmdData:data];
    [[DKBleManager sharedInstance] wtireDataToCharacteristic:theCharacteristic writeData:theData];
}
-(void)requestPalTestChannel:(NSData *)data callback:(onReceivePalTestChannelListener)block{
    onReceivePalTestChannelListenerBlock = block;
    CBCharacteristic * theCharacteristic = [DKBleManager sharedInstance].apduCharacteristic;
    NSData *theData = [DKComByteManager getTestChannelData:data];
    [[DKBleManager sharedInstance] wtireDataToCharacteristic:theCharacteristic writeData:theData];
}


#pragma mark - DKComByteManagerDelegate
-(void)comByteManagerCallback:(BOOL)isSuc rcvData:(NSData *)rcvData {
    Byte *rcvBytes = (Byte *)[rcvData bytes];
    switch ([self.comByteManager getCmd] - 1) {
        case GET_VERSIONS_COM:
            if ( [comByteManager getCmdRunStatus] && (onReceiveDeviceVersionListenerBlock != nil) ) {
                onReceiveDeviceVersionListenerBlock((NSInteger)(rcvBytes[0]));
            }
            break;
        case GET_BT_VALUE_COM:
            if ([comByteManager getCmdRunStatus] && (onReceiveDeviceBtValueListenerBlock != nil) ) {
                float btValue = (float)(((unsigned int)rcvBytes[0] << 8) | (unsigned int)rcvBytes[1]) / 100.0;
                onReceiveDeviceBtValueListenerBlock(btValue);
            }
            break;
        case ANTENNA_OFF_COM:
            if (onReceiveRfmCloseListenerBlock != nil) {
                onReceiveRfmCloseListenerBlock(YES);
            }
            break;
        case ACTIVATE_PICC_COM:
            if ( [comByteManager getCmdRunStatus] && (rcvData.length >= 1) ) {
                self.cpuCard = nil;
                self.ultralight = nil;
                self.ntag21x = nil;
                self.mifare = nil;
                self.iso14443bCard = nil;
                self.feliCa = nil;
                self.desFire = nil;
                self.iso15693Card = nil;
                mCardType = DKCardTypeDefault;
                if (onReceiveRfnSearchCardListenerBlock != nil) {
                    DKCardType cardType = (DKCardType)rcvBytes[0];
                    mCardType = cardType;
                    NSData *uidData = [NSData dataWithHexString:@"00000000"];;
                    NSData *atrData;
                    if (cardType == DKIso14443A_CPUType) {
                        uidData = [rcvData subdataWithRange:NSMakeRange(1, 4)];
                        atrData = [rcvData subdataWithRange:NSMakeRange(5, rcvData.length - 5)];
                        self.cpuCard = [[CpuCard alloc] init:self uid:uidData atr:atrData];
                    }
                    else if (cardType == DKMifare_Type) {
                        uidData = [rcvData subdataWithRange:NSMakeRange(1, 4)];
                        atrData = [rcvData subdataWithRange:NSMakeRange(5, rcvData.length - 5)];
                        self.mifare = [[Mifare alloc] init:self uid:uidData atr:atrData];
                    }
                    else if (cardType == DKIso15693_Type) {
                        uidData = [NSData dataWithHexString:@"00000000"];
                        atrData = [NSData dataWithHexString:@"00"];
                        self.iso15693Card = [[Iso15693Card alloc] init:self uid:uidData atr:atrData];
                    }
                    else if (cardType == DKUltralight_type) {
                        uidData = [rcvData subdataWithRange:NSMakeRange(1, 7)];
                        atrData = [rcvData subdataWithRange:NSMakeRange(8, rcvData.length - 8)];
                        self.ultralight = [[Ultralight alloc] init:self uid:uidData atr:atrData];
                        self.ntag21x = [[Ntag21x alloc] init:self uid:uidData atr:atrData];
                    }
                    else if (cardType == DKDESFire_type) {
                        uidData = [rcvData subdataWithRange:NSMakeRange(1, 7)];
                        atrData = [rcvData subdataWithRange:NSMakeRange(8, rcvData.length - 8)];
                        self.desFire = [[DESFire alloc] init:self uid:uidData atr:atrData];
                    }
                    else if (cardType == DKIso14443B_CPUType) {
                        uidData = [NSData dataWithHexString:@"00000000"];
                        atrData = [rcvData subdataWithRange:NSMakeRange(1, rcvData.length - 1)];
                        self.iso14443bCard = [[Iso14443bCard alloc] init:self uid:uidData atr:atrData];
                    }
                    else if (cardType == DKFeliCa_Type) {
                        uidData = [NSData dataWithHexString:@"00000000"];
                        atrData = [rcvData subdataWithRange:NSMakeRange(1, rcvData.length - 1)];
                        self.feliCa = [[FeliCa alloc] init:self uid:uidData atr:atrData];
                    }
                    else {
                        uidData = [NSData dataWithHexString:@"00000000"];
                        atrData = [rcvData subdataWithRange:NSMakeRange(1, rcvData.length - 1)];
                    }
                    
                    if (onReceiveRfnSearchCardListenerBlock != nil) {
                        onReceiveRfnSearchCardListenerBlock(YES, cardType, uidData, atrData);
                    }
                }
            }
            else {
                if (onReceiveRfnSearchCardListenerBlock != nil) {
                    onReceiveRfnSearchCardListenerBlock(NO, 0, nil, nil);
                }
            }
            break;
        case APDU_COM:
            if (onReceiveRfmSentApduCmdListenerBlock != nil) {
                onReceiveRfmSentApduCmdListenerBlock([comByteManager getCmdRunStatus], rcvData);
            }
            break;
            
        case BPDU_COM:
            if (onReceiveRfmSentBpduCmdListenerBlock != nil) {
                onReceiveRfmSentBpduCmdListenerBlock([comByteManager getCmdRunStatus], rcvData);
            }
            break;
            
        case GET_SUICA_BALANCE_COM:
            if (onReceiveRfmSuicaBalanceListenerBlock != nil) {
                onReceiveRfmSuicaBalanceListenerBlock(isSuc, rcvData);
            }
            break;
            
        case FELICA_READ_COM:
            if (onReceiveRfmFelicaReadListenerBlock != nil) {
                onReceiveRfmFelicaReadListenerBlock(isSuc, rcvData);
            }
            break;
            
        case ULTRALIGHT_CMD:
            if (onReceiveRfmUltralightCmdListenerBlock != nil) {
                onReceiveRfmUltralightCmdListenerBlock([comByteManager getCmdRunStatus], rcvData);
            }
            break;
        
        case FELICA_COM:
        if (onReceiveRfmFelicaCmdListenerBlock != nil) {
            onReceiveRfmFelicaCmdListenerBlock([comByteManager getCmdRunStatus], rcvData);
        }
        break;
        
        case MIFARE_AUTH_COM:
        if (onReceiveRfmMifareAuthListenerBlock != nil) {
            onReceiveRfmMifareAuthListenerBlock([comByteManager getCmdRunStatus]);
        }
        break;
        
        case MIFARE_COM:
        if (onReceiveRfmMifareDataExchangeListenerBlock != nil) {
            onReceiveRfmMifareDataExchangeListenerBlock([comByteManager getCmdRunStatus], rcvData);
        }
        break;
        
        case PAL_TEST_CHANNEL:
        if (onReceivePalTestChannelListenerBlock != nil) {
            onReceivePalTestChannelListenerBlock(rcvData);
        }
        break;
        
        default:
            break;
    }
}
@end





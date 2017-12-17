//
//  NFCDeviceInfoObject.m
//  RFID_Lab1
//
//  Created by Rex on 2017/12/9.
//  Copyright © 2017年 Rex. All rights reserved.
//

#import "NFCDeviceInfoObject.h"

@interface NFCDeviceInfoObject()

@property (nonatomic, strong) NSString *version;

/**
 版本
 */
@property (nonatomic, assign) unsigned long versionNumber;

/**
 電壓
 */
@property (nonatomic, assign) float voltage;

/**
 電壓訊息
 */
@property (nonatomic, strong) NSString *voltageMessage;

@end

@implementation NFCDeviceInfoObject

+(instancetype)initWithVersion:(NSUInteger)version
                       voltage:(float)voltage
{
    NFCDeviceInfoObject *obj = [NFCDeviceInfoObject new];
    obj.versionNumber = version;
    obj.voltage = voltage;
    return obj;
}

-(void)setVersionNumber:(unsigned long)versionNumber
{
    _versionNumber = versionNumber;
    self.version = [NSString stringWithFormat:@"%02lx", (unsigned long)versionNumber];
}

-(void)setVoltage:(float)voltage
{
    _voltage = voltage;
    self.voltageMessage = (voltage < 3.4)?@"電壓過低！":@"電量充足！";
}


@end

//
//  NFCDeviceInfoObject.h
//  RFID_Lab1
//
//  Created by Rex on 2017/12/9.
//  Copyright © 2017年 Rex. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NFCDeviceInfoObject : NSObject

/**
 版本
 */
@property (readonly) NSString * _Nonnull version;

/**
 電壓
 */
@property (readonly) float voltage;

/**
 電壓訊息
 */
@property (readonly) NSString * _Nonnull voltageMessage;


+(instancetype _Nonnull )initWithVersion:(NSUInteger)version
                       voltage:(float)voltage;

@end

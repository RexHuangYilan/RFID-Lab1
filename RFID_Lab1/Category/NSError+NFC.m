//
//  NSError+NFC.m
//  RFID_Lab1
//
//  Created by Rex on 2017/12/10.
//  Copyright © 2017年 Rex. All rights reserved.
//

#import "NSError+NFC.h"

NSString *BLENFCDomain = @"com.htw.ble.nfc";

@implementation NSError (NFC)

+(instancetype)errorWithCode:(BLENFCErrorCode)code
{
    NSError *error = [NSError errorWithCode:code object:nil];
    return error;
}

+(instancetype)errorWithCode:(BLENFCErrorCode)code
                      object:(id)object
{
    NSString *errorMessage;
    switch (code) {
        case BLENFCErrorCodePasswordError:
            errorMessage = @"密碼驗證錯誤";
            break;
        case BLENFCErrorCodeLoadDataError:
            errorMessage = @"讀取資料錯誤";
            break;
        case BLENFCErrorCodeNoCardError:
            errorMessage = @"沒有卡片";
            break;
        case BLENFCErrorCodeWriteDataError:
            errorMessage = @"寫入資料錯誤";
            break;
        default:
            errorMessage = @"非預期錯誤";
            break;
    }
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:errorMessage forKey:@"message"];
    if (object) {
        [dict setObject:object forKey:@"object"];
    }
    
    NSError *error = [NSError errorWithCode:code
                                   userInfo:dict];
    return error;
}

+(instancetype)errorWithCode:(BLENFCErrorCode)code
                    userInfo:(NSDictionary *)userInfo
{
    NSError *error = [NSError errorWithDomain:BLENFCDomain
                                         code:code
                                     userInfo:userInfo];
    return error;
}

@end

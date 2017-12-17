//
//  NSError+NFC.h
//  RFID_Lab1
//
//  Created by Rex on 2017/12/10.
//  Copyright © 2017年 Rex. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString *BLENFCDomain;

typedef NS_ENUM(NSUInteger, BLENFCErrorCode) {
    BLENFCErrorCodePasswordError = -1,
    BLENFCErrorCodeLoadDataError = -2,
    BLENFCErrorCodeNoCardError = -3,
    BLENFCErrorCodeWriteDataError = -4,
};
@interface NSError (NFC)

+(instancetype)errorWithCode:(BLENFCErrorCode)code;

+(instancetype)errorWithCode:(BLENFCErrorCode)code
                      object:(id)object;

@end

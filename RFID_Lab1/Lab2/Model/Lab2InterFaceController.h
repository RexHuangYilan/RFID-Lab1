//
//  Lab2InterFaceController.h
//  RFID_Lab1
//
//  Created by Rex on 2017/12/4.
//  Copyright © 2017年 Rex. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WalletObject.h"
#import "NFCDeviceInfoObject.h"

typedef NS_ENUM(NSUInteger, Lab2InterFaceControllerAction) {
    Lab2InterFaceControllerActionCreate,        //發卡
    Lab2InterFaceControllerActionSearch,        //查詢
    Lab2InterFaceControllerActionPointAdd,      //儲值
    Lab2InterFaceControllerActionPointConsume,  //消費
};


@interface Lab2InterFaceController : NSObject

@property (readwrite) NSString * _Nullable uid;
@property (readwrite) NSString * _Nullable name;
@property (readwrite) NSDate * _Nullable createDate;
@property (readwrite) NSUInteger point;
@property (readwrite) NSString *message;
@property (readwrite) Lab2InterFaceControllerAction action;
@property (readonly) WalletObject * _Nonnull walletObject;
@property (readwrite) BOOL isLoading;

-(void)updateWithDeviceInfo:(NFCDeviceInfoObject *_Nonnull)info;
-(void)checkAction;

@end

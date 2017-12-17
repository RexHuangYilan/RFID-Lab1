//
//  Lab2ViewController.m
//  RFID_Lab1
//
//  Created by Rex on 2017/12/4.
//  Copyright © 2017年 Rex. All rights reserved.
//

#import "Lab2ViewController.h"
#import "ConnectViewController.h"

#import "UIViewController+BaseControl.h"

#import "Lab2InterFaceController.h"
#import "NFCBlueToothManager.h"

#import "NSData+Operation.h"

@interface Lab2ViewController ()
<
NFCBlueToothManagerDelegate
>

@property (strong, nonatomic) IBOutlet Lab2InterFaceController *lab2Controller;
@property (readonly) NFCBlueToothManager *bleManager;


@end

@implementation Lab2ViewController

#pragma mark - live cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self scale];
    [self.lab2Controller checkAction];

}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showConnect)
                                                 name:BluetoothDisConnectNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateDeviceInfo)
                                                 name:BluetoothConnectNotification
                                               object:nil];
    [self updateDeviceInfo];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.bleManager.status == BLENFCStatusNoConnect) {
        [self.bleManager scanNFC];
    }
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - get

-(NFCBlueToothManager *)bleManager
{
    [NFCBlueToothManager sharedInstance].delegate = self;
    return [NFCBlueToothManager sharedInstance];
}

#pragma mark - private

-(void)showConnect
{
    self.lab2Controller.isLoading = NO;
    [ConnectViewController showViewController];
}

-(void)updateDeviceInfo
{
    [self.lab2Controller updateWithDeviceInfo:self.bleManager.info];
}

#pragma mark - NFCBlueToothManagerDelegate

-(void)deviceChangeStatus:(BLENFCStatus)status
{
    self.lab2Controller.isLoading = status == BLENFCStatusLoading;
}

@end

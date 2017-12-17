//
//  ConnectViewController.m
//  RFID_Lab1
//
//  Created by Rex on 2017/12/9.
//  Copyright © 2017年 Rex. All rights reserved.
//

#import "ConnectViewController.h"
#import "UIViewController+BaseControl.h"

#import "NFCBlueToothManager.h"

@interface ConnectViewController ()
<
NFCBlueToothManagerDelegate
>

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingView;


@end

@implementation ConnectViewController

#pragma mark - live cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self scale];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hideConnect)
                                                 name:BluetoothConnectNotification
                                               object:nil];
    self.bleManager.delegate = self;
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - get

-(NFCBlueToothManager *)bleManager
{
    return [NFCBlueToothManager sharedInstance];
}

#pragma mark - private

-(void)hideConnect
{
    [UIViewController dismissViewControllerAnimated:YES
                                         completion:nil];
}

#pragma mark - IBAction

-(IBAction)doBtnConnect:(id)sender
{
    [self.bleManager scanNFC];
}

#pragma mark - public

+(instancetype)viewController
{
    return (ConnectViewController *)[self getViewControllerWithMainStoryboardIdentifier:NSStringFromClass(ConnectViewController.class)];
}

+(void)showViewController
{
    UIViewController *vc = [ConnectViewController viewController];
    [UIViewController presendViewController:vc
                                   animated:YES
                                 completion:nil];
}

#pragma mark - NFCBlueToothManagerDelegate

-(void)deviceChangeStatus:(BLENFCStatus)status
{
//    self.loadingView.hidden = status != BLENFCStatusLoading;
    if (status != BLENFCStatusLoading)
    {
        [self.loadingView stopAnimating];
    }
    else
    {
        [self.loadingView startAnimating];
    }
    
}

@end

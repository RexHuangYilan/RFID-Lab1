//
//  ViewController.m
//  RFID_Lab1
//
//  Created by Rex on 2017/10/4.
//  Copyright © 2017年 Rex. All rights reserved.
//

#import "ViewController.h"
#import "DKBleNfc.h"
#import "NSData+Hex.h"
#import "ViewController+PickerView.h"

#import "HTWKeyBoradViewController.h"

#define SEARCH_BLE_NAME   @"BLE_NFC"

typedef NS_ENUM(NSUInteger, BLENFCStatus) {
    BLENFCStatusNoConnect,
    BLENFCStatusConnect,
    BLENFCStatusLoading,
};

@interface ViewController ()<DKBleManagerDelegate,UITextFieldDelegate>

@property (nonatomic, strong) DKBleManager     *bleManager;
@property (nonatomic, strong) DKDeviceManager  *deviceManager;
@property (nonatomic, strong) CBPeripheral     *mNearestBle;
@property (weak, nonatomic) IBOutlet UIButton *searchButton;
@property (weak, nonatomic) IBOutlet UIView *nfcView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingView;
@property (weak, nonatomic) IBOutlet UIButton *readButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *buttonHeight;
@property (weak, nonatomic) IBOutlet UISegmentedControl *keyABSegment;
@property (weak, nonatomic) IBOutlet UITextField *loadKeyTestField;
@property (weak, nonatomic) IBOutlet UILabel *rfidDataLabel;
@property (nonatomic, strong) HTWKeyBoradViewController *keyborad;
@property (nonatomic, strong) NSMutableString  *msgBuffer;
@property (nonatomic) BLENFCStatus status;

-(void)setMssage:(NSString *)mssage;
-(void)setCardMssage:(NSString *)cardmssage;

@end

@implementation ViewController

NSInteger lastRssi = -100;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.keyborad = [HTWKeyBoradViewController new];
    self.keyborad.inputSource = self.loadKeyTestField;
    
    CGFloat width = self.view.frame.size.width;
    CGFloat scale = width/375.0;
    self.view.transform = CGAffineTransformMakeScale(scale,scale);
    self.msgBuffer = [[NSMutableString alloc] init];
    self.bleManager = [DKBleManager sharedInstance];
    self.bleManager.delegate = self;
    self.deviceManager = [[DKDeviceManager alloc] init];
    self.status = BLENFCStatusNoConnect;
    self.nfcObject = [NFCObject new];
    self.loadKeyTestField.text = self.nfcObject.key;
    self.loadKeyTestField.delegate = self;
    [self checkReadButton];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(kbWillShow:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(kbWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - 鍵盤事件相關

- (void)kbWillShow:(NSNotification *)noti {
    NSDictionary *info  = noti.userInfo;
    NSValue      *value = info[UIKeyboardFrameEndUserInfoKey];
    
    CGRect rawFrame      = [value CGRectValue];
    CGRect keyboardFrame = [self.view convertRect:rawFrame fromView:nil];
    
    self.buttonHeight.constant = -CGRectGetHeight(keyboardFrame);
}

- (void)kbWillHide:(NSNotification *)noti {
    self.buttonHeight.constant = 0;
}

#pragma mark - 設定相關

-(void)setStatus:(BLENFCStatus)status
{
    [self.loadingView stopAnimating];
    self.loadingView.hidden = YES;
    self.view.userInteractionEnabled = YES;
    switch (status) {
        case BLENFCStatusNoConnect:
            self.nfcView.hidden = YES;
            break;
        case BLENFCStatusConnect:
            self.nfcView.hidden = NO;
            break;
        case BLENFCStatusLoading:
            [self.loadingView startAnimating];
            self.loadingView.hidden = NO;
            self.view.userInteractionEnabled = NO;
            break;
    }
}

-(void)setMssage:(NSString *)mssage
{
    NSLog(@"%@",mssage);
}

-(void)setCardMssage:(NSString *)cardmssage
{
    
    self.rfidDataLabel.text = [cardmssage uppercaseString];
}

-(void)setSectorPickerView:(UIPickerView *)sectorPickerView
{
    _sectorPickerView = sectorPickerView;
    sectorPickerView.delegate = self;
    sectorPickerView.dataSource = self;
}

-(void)setBlockPickerView:(UIPickerView *)blockPickerView
{
    _blockPickerView = blockPickerView;
    blockPickerView.delegate = self;
    blockPickerView.dataSource = self;
}

-(void)setSearchButtonText:(NSString *)text
{
    [self.searchButton setTitle:text forState:UIControlStateNormal];
}

#pragma mark - 功能相關

-(void)checkKeyWithCard:(Mifare *)card
{
//    Byte keybytes[] = {(Byte) 0xff, (Byte) 0xff,(Byte) 0xff,(Byte) 0xff,(Byte) 0xff,(Byte) 0xff};
//    NSData *keyData = [[NSData alloc] initWithBytes:keybytes length:6];
    NSData *keyData = [self.nfcObject keyData];
    
    [card mifareAuthenticate:self.nfcObject.authenticate keyType:self.nfcObject.keyAB == NFCKeyABA? MIFARE_KEY_TYPE_A:MIFARE_KEY_TYPE_B key:keyData callbackBlock:^(BOOL isSuc) {
        if (!isSuc) {
            [card close];  //關閉天線
            [self setCardMssage:@"密碼驗證錯誤"];
        }else{
            [self readDataWithCard:card];
        }
    }];
}

-(void)readDataWithCard:(Mifare *)card
{
    [card mifareRead:self.nfcObject.authenticate callbackBlock:^(BOOL isSuc, NSData *returnData) {
        if (!isSuc) {
            [self setCardMssage:@"讀取資料錯誤"];
        }else {
            [self setCardMssage:[returnData hexadecimalString]];
        }
        [card close];  //關閉天線
    }];
}

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
                    [self.msgBuffer setString:@"設備連接成功！\n"];
                    self.mssage = self.msgBuffer;
                    self.status = BLENFCStatusConnect;
                    //取得設備訊息
                    [self getDeviceMsg];
                });
            }else {
                //失敗
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.mssage = @"設備中斷！";
                    self.status = BLENFCStatusNoConnect;
                });
            }
        }];
    }
}

//取得設備訊息
-(void)getDeviceMsg {
    [self.deviceManager requestDeviceVersionWithCallbackBlock:^(NSUInteger versionNum) {
        [self.msgBuffer appendString:[NSString stringWithFormat:@"設備版本：%02lx\n", (unsigned long)versionNum]];
        self.mssage = self.msgBuffer;
        [self.deviceManager requestDeviceBtValueWithCallbackBlock:^(float btVlueMv) {
            [self.msgBuffer appendString:[NSString stringWithFormat:@"電壓：%.2fV\n", btVlueMv]];
            if (btVlueMv < 3.4) {
                [self.msgBuffer appendString:@"電壓過低！\r\n"];
            }
            else {
                [self.msgBuffer appendString:@"電量充足！\r\n"];
            }
            self.mssage = self.msgBuffer;
        }];
    }];
}

#pragma mark - 檢查相關

-(void)checkReadButton
{
    self.readButton.enabled = self.loadKeyTestField.text.length == 12;
    NSString *title;
    if (self.readButton.enabled) {
        title = @"Read Data";
    }else{
        title = [NSString stringWithFormat:@"Key還缺%lu個字元",12-self.loadKeyTestField.text.length];
    }
    [self.readButton setTitle:title forState:UIControlStateNormal];
}

#pragma mark - 按鈕事件相關

- (IBAction)doKeyAB:(id)sender {
    self.nfcObject.keyAB = self.keyABSegment.selectedSegmentIndex;
}

- (IBAction)doReadButton:(id)sender {
    [self.deviceManager requestRfmSearchCard:DKCardTypeDefault callbackBlock:^(BOOL isblnIsSus, DKCardType cardType, NSData *CardSn, NSData *bytCarATS) {
        if (isblnIsSus) {
            if (cardType == DKMifare_Type) { //找到M1卡
                Mifare *card = [self.deviceManager getCard];
                if (card != nil) {
                    NSLog(@"Get Migare,ID:%@",card.uid);
                    [self checkKeyWithCard:card];
                }
            }
        }
    }];
}

- (IBAction)doCloseButton:(id)sender {
    if ( [self.bleManager isConnect] ) {
        self.status = BLENFCStatusLoading;
        [self.bleManager cancelConnect];
    }
}

//尋找NFC
- (IBAction)SearchButtonEnter:(id)sender {
    self.status = BLENFCStatusLoading;
    self.mNearestBle = nil;
    lastRssi = -100;
    [self.bleManager startScan];
    [NSThread detachNewThreadSelector:@selector(fineNearBle) toTarget:self withObject:nil];
}

/*
 * 藍牙call back
 */
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
            self.mssage = @"設備中斷！";
            self.status = BLENFCStatusNoConnect;
        });
    }
}

#pragma mark - UITextFieldDelegate
//限定輸入key12字內
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    return textField.text.length + string.length <= 12;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}
//key改變時觸發
- (IBAction)keyChange:(UITextField *)sender {
    self.nfcObject.key = sender.text;
    [self checkReadButton];
}

@end

//
//  Lab2InterFaceController.m
//  RFID_Lab1
//
//  Created by Rex on 2017/12/4.
//  Copyright © 2017年 Rex. All rights reserved.
//

#import "Lab2InterFaceController.h"
#import "NSString+Convert.h"

#import "NFCBlueToothManager.h"

@interface Lab2InterFaceController ()

@property (weak, nonatomic) IBOutlet UILabel *aboutLabel;
@property (weak, nonatomic) IBOutlet UITextField *uidTextField;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *createDateTextField;
@property (weak, nonatomic) IBOutlet UITextField *pointTextField;

@property (weak, nonatomic) IBOutlet UIStackView *stackView;
@property (weak, nonatomic) IBOutlet UIView *uidView;
@property (weak, nonatomic) IBOutlet UIView *nameView;
@property (weak, nonatomic) IBOutlet UIView *createDateView;
@property (weak, nonatomic) IBOutlet UIView *pointView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *actionControl;

@property (weak, nonatomic) IBOutlet UIButton *btnAction;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingView;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;

@property (strong, nonatomic) WalletObject *walletObject;
@property (readonly) NFCBlueToothManager *bleManager;

@end

@implementation Lab2InterFaceController

#pragma mark - public

-(void)updateWithDeviceInfo:(NFCDeviceInfoObject *)info
{
    NSString *infoString = @"";
    if (info) {
        infoString = [NSString stringWithFormat:@"版本:%@ %@",info.version,info.voltageMessage];
    }
    self.aboutLabel.text = infoString;
}

#pragma mark - private

-(void)updateWithWallet:(WalletObject *)wallet
{
    self.uid = wallet.uid;
    self.name = wallet.name;
    self.createDate = wallet.createDate;
    self.point = wallet.point;
}

-(void)updateToWallet:(WalletObject *)wallet
{
    wallet.uid = self.uid;
    wallet.name = self.name;
    wallet.createDate = self.createDate;
    wallet.point = self.point;
}

#pragma mark - set

-(void)setUid:(NSString *)uid
{
    self.uidTextField.text = uid;
}

-(void)setName:(NSString *)name
{
    self.nameTextField.text = name;
}

-(void)setCreateDate:(NSDate *)createDate
{
    self.createDateTextField.text = [NSString stringWithDate:createDate];
}

-(void)setPoint:(NSUInteger)point
{
    self.pointTextField.text = [NSString stringWithInteger:point];
}

-(void)setAction:(Lab2InterFaceControllerAction)action
{
    self.actionControl.selectedSegmentIndex = action;
}

-(void)setIsLoading:(BOOL)isLoading
{
    if (isLoading) {
        [self.loadingView startAnimating];
    }else{
        [self.loadingView stopAnimating];
    }
}

-(void)setMessage:(NSString *)message
{
    self.messageLabel.text = message;
}

#pragma mark - get

-(NSString *)uid
{
    return self.uidTextField.text;
}

-(NSString *)name
{
    return self.nameTextField.text;
}

-(NSDate *)createDate
{
    return [self.createDateTextField.text date];
}

-(NSUInteger)point
{
    return [self.pointTextField.text integerValue];
}

-(Lab2InterFaceControllerAction)action
{
    return self.actionControl.selectedSegmentIndex;
}

-(WalletObject *)walletObject
{
    if (!_walletObject) {
        _walletObject = [WalletObject new];
    }
    return _walletObject;
}

-(NFCBlueToothManager *)bleManager
{
    return [NFCBlueToothManager sharedInstance];
}

-(BOOL)isLoading
{
    return self.loadingView.animating;
}

-(NSString *)message
{
    return self.messageLabel.text;
}

#pragma mark - action

-(void)readCard
{
    __weak typeof(self) weakSelf = self;
    self.isLoading = YES;
    
    NSArray *nfcs = [self.walletObject nfcs];
    [self.bleManager readCardWithNFCs:nfcs successBlock:^(NSArray<NFCObject *> * _Nonnull datas) {
        
        [weakSelf.walletObject nfcToData];
        [weakSelf updateWithWallet:weakSelf.walletObject];
        weakSelf.isLoading = NO;
        weakSelf.message = @"讀取完成";
    } errorBlock:^(NSError * _Nonnull error) {
        
        NSLog(@"error:%@",error);
        weakSelf.isLoading = NO;
        weakSelf.message = error.userInfo[@"message"];
    }];
}

-(void)pointAdd
{
    [self pointOperation:self.point isAdd:YES];
}

-(void)pointConsume
{
    [self pointOperation:self.point isAdd:NO];
}

-(void)pointOperation:(NSUInteger)point isAdd:(BOOL)isAdd
{
    __weak typeof(self) weakSelf = self;
    self.isLoading = YES;
    
    NSArray *nfcs = @[self.walletObject.pointObject];
    [self.bleManager readCardWithNFCs:nfcs successBlock:^(NSArray<NFCObject *> * _Nonnull datas) {
        
        [weakSelf.walletObject nfcToData];
        NSUInteger cardPoint = weakSelf.walletObject.point;
        NSUInteger totalPoint;
        NSUInteger addPoint = 2000;
        NSUInteger addNum = 0;
        
        if (isAdd) {
            totalPoint = cardPoint + point;
            if (![weakSelf checkPoint:totalPoint]) {
                return ;
            }
        }else{
            NSInteger temp = cardPoint - point;
            if (cardPoint < point) {
                while (temp < 0) {
                    addNum++;
                    temp += addPoint;
                }
            }
            totalPoint = temp;
        }
        
        weakSelf.walletObject.point = totalPoint;
        [weakSelf.walletObject dataToNFC];
        
        [weakSelf.bleManager writeCardWithNFCs:nfcs successBlock:^(NSArray<NFCObject *> * _Nonnull datas) {
            
            weakSelf.isLoading = NO;
            NSString *message;
            if (isAdd) {
                message = [NSString stringWithFormat:@"儲值:%lu，可用餘額:%lu",(unsigned long)point,(unsigned long)weakSelf.walletObject.point];
            }else{
                message = [NSString stringWithFormat:@"消費:%lu，可用餘額:%lu",(unsigned long)point,(unsigned long)weakSelf.walletObject.point];
                if (addNum > 0) {
                    message = [NSString stringWithFormat:@"自動加值%lu 次數:%lu\n%@",(unsigned long)addPoint,(unsigned long)addNum,message];
                }
            }
            weakSelf.message = message;
        } errorBlock:^(NSError * _Nonnull error) {
            
            NSLog(@"error:%@",error);
            weakSelf.isLoading = NO;
            weakSelf.message = error.userInfo[@"message"];
        }];
    } errorBlock:^(NSError * _Nonnull error) {
        
        NSLog(@"error:%@",error);
        weakSelf.isLoading = NO;
        weakSelf.message = error.userInfo[@"message"];
    }];
}

#pragma mark - IBAction

-(IBAction)actionChange
{
    [self checkAction];
}

-(IBAction)doBtnCreate:(id)sender
{
    if (![self checkName]) {
        return;
    }
    if (![self checkPoint:self.point]) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    self.isLoading = YES;
    [self updateToWallet:self.walletObject];
    NSArray *nfcs = [self.walletObject nfcs];
    
    [self.bleManager writeCardWithNFCs:nfcs successBlock:^(NSArray<NFCObject *> * _Nonnull datas) {
        
        weakSelf.isLoading = NO;
        weakSelf.message = @"寫入完成";
    } errorBlock:^(NSError * _Nonnull error) {
        
        NSLog(@"error:%@",error);
        weakSelf.isLoading = NO;
        weakSelf.message = error.userInfo[@"message"];
    }];
}

-(IBAction)doBtnClean:(id)sender
{
    __weak typeof(self) weakSelf = self;
    self.isLoading = YES;
    NSArray *nfcs = [self.walletObject cleanNfcs];
    
    [self.bleManager writeCardWithNFCs:nfcs successBlock:^(NSArray<NFCObject *> * _Nonnull datas) {
        
        weakSelf.isLoading = NO;
        weakSelf.message = @"清空完成";
    } errorBlock:^(NSError * _Nonnull error) {
        
        NSLog(@"error:%@",error);
        weakSelf.isLoading = NO;
        weakSelf.message = error.userInfo[@"message"];
    }];
}

//key改變時觸發
- (IBAction)keyChange:(UITextField *)sender {
    if (sender == self.nameTextField) {
        
        [self checkName];
    }else if (sender == self.pointTextField) {
        
        [self checkPoint:self.point];
    }
    
//    self.nfcObject.key = sender.text;
//    [self checkReadButton];
}

#pragma mark - check

-(void)checkAction
{
    self.btnAction.hidden = self.action == Lab2InterFaceControllerActionCreate;
    NSString *btnActionString = @"";
    SEL action = NULL;
    
    self.stackView.userInteractionEnabled = self.action != Lab2InterFaceControllerActionSearch;
    self.message = @"";
    
    switch (self.action) {
        case Lab2InterFaceControllerActionCreate:
        {
            [self.walletObject createNewCard];
            
            [self insetSubView];
            
        }
            break;
        case Lab2InterFaceControllerActionSearch:
        {
            [self.walletObject clearCard];
            
            [self insetSubView];
            btnActionString = @"讀取卡片";
            action = @selector(readCard);
        }
            break;
        case Lab2InterFaceControllerActionPointAdd:
        {
            [self.walletObject clearCard];
            
            [self removeSubView];
            btnActionString = @"加值點數";
            action = @selector(pointAdd);
        }
            break;
        case Lab2InterFaceControllerActionPointConsume:
        {
            [self.walletObject clearCard];
            
            [self removeSubView];
            btnActionString = @"消費點數";
            action = @selector(pointConsume);
        }
            break;
    }
    
    if (btnActionString.length > 0) {
        [self.btnAction setTitle:btnActionString
                        forState:UIControlStateNormal];
        
        [self.btnAction removeTarget:self
                              action:nil
                    forControlEvents:UIControlEventTouchUpInside];
        [self.btnAction addTarget:self
                           action:action
                 forControlEvents:UIControlEventTouchUpInside];
    }
    
    [self updateWithWallet:self.walletObject];
}

-(BOOL)checkName
{
    NSData *data = [self.name dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    BOOL success = data.length <= 16;
    if (!success) {
        self.message = @"姓名長度過長!";
    }
    
    if (data.length == 0) {
        self.message = @"請輸入姓名!";
    }
    
    success = success && data.length > 0;
    
    if (success) {
        self.message = @"";
    }
    
    return success;
}

-(BOOL)checkPoint:(double)point
{
    BOOL success = point <= 0xffffffff;
    if (!success) {
        self.message = [NSString stringWithFormat:@"點數超過%u!",0xffffffff];
    }
    if (success) {
        self.message = @"";
    }
    return success;
}

#pragma mark - stackView opration

-(void)insetSubView
{
    if (self.stackView.arrangedSubviews.count == 2) {
        [self.stackView insertArrangedSubview:self.uidView atIndex:0];
        [self.stackView insertArrangedSubview:self.nameView atIndex:1];
        [self.stackView insertArrangedSubview:self.createDateView atIndex:2];
    }
}

-(void)removeSubView
{
    if (self.stackView.arrangedSubviews.count == 5) {
        [self.stackView removeArrangedSubview:self.uidView];
        [self.stackView removeArrangedSubview:self.nameView];
        [self.stackView removeArrangedSubview:self.createDateView];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}


@end

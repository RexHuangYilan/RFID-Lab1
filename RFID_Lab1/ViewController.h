//
//  ViewController.h
//  RFID_Lab1
//
//  Created by Rex on 2017/10/4.
//  Copyright © 2017年 Rex. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NFCObject.h"

@interface ViewController : UIViewController

@property (nonatomic, strong) NFCObject *nfcObject;

@property (weak, nonatomic) IBOutlet UIPickerView *sectorPickerView;
@property (weak, nonatomic) IBOutlet UIPickerView *blockPickerView;

@end


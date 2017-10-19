//
//  ViewController+PickerView.m
//  RFID_Lab1
//
//  Created by Rex on 2017/10/16.
//  Copyright © 2017年 Rex. All rights reserved.
//

#import "ViewController+PickerView.h"

@implementation ViewController (PickerView)

#pragma mark - UIPickerViewDataSource

// 返回多少列
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

// 返回每列的行数
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return (pickerView == self.sectorPickerView)?self.nfcObject.sectors.count:self.nfcObject.blocks.count;
}

- (nullable NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSArray *data = (pickerView == self.sectorPickerView)?self.nfcObject.sectors:self.nfcObject.blocks;
    return data[row];
}

#pragma mark - UIPickerViewDelegate

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSArray<NSString *> *data = (pickerView == self.sectorPickerView)?self.nfcObject.sectors:self.nfcObject.blocks;
    if (pickerView == self.sectorPickerView) {
        self.nfcObject.sector = data[row].integerValue;
    }else{
        self.nfcObject.block = data[row].integerValue;
    }
}

@end

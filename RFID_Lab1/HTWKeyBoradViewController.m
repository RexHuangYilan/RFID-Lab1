//
//  HTWKeyBoradViewController.m
//  RFID_Lab1
//
//  Created by Rex on 2017/10/15.
//  Copyright © 2017年 Rex. All rights reserved.
//

#import "HTWKeyBoradViewController.h"

@interface HTWKeyBoradViewController ()

@end

@implementation HTWKeyBoradViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

-(void)setInputSource:(UIView *)inputSource
{
    _inputSource = inputSource;
    if ([self.inputSource isKindOfClass:[UITextField class]]) {
        UITextField *tmp = (UITextField *)inputSource;
        tmp.inputView = self.view;
    }
}

- (IBAction)doKeyBoardButton:(UIButton *)sender {
    if (self.inputSource) {
        if ([self.inputSource isKindOfClass:[UITextField class]]) {
            UITextField *tmp = (UITextField *)self.inputSource;
            
            if (sender.tag == 0) {
                NSString *title = sender.currentTitle;
                if (tmp.delegate && [tmp.delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
                    NSRange range = NSMakeRange(tmp.text.length, 1);
                    BOOL ret = [tmp.delegate textField:tmp shouldChangeCharactersInRange:range replacementString:title];
                    if (ret) {
                        [tmp insertText:title];
                    }
                }else{
                    [tmp insertText:title];
                }
            }else if (sender.tag == 1) {
                [tmp deleteBackward];
            }else if (sender.tag == 2) {
                if (tmp.delegate && [tmp.delegate respondsToSelector:@selector(textFieldShouldEndEditing:)]) {
                    BOOL ret = [tmp.delegate textFieldShouldEndEditing:tmp];
                    [tmp endEditing:ret];
                }else{
                    [tmp resignFirstResponder];
                }
            }
        }
    }
}

@end

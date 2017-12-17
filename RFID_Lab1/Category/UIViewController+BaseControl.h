//
//  UIViewController+BaseControl.h
//  RFID_Lab1
//
//  Created by Rex on 2017/12/9.
//  Copyright © 2017年 Rex. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (BaseControl)

-(void)scale;

+(UIViewController * _Nonnull)getViewControllerWithMainStoryboardIdentifier:(NSString *_Nonnull)identifier;

+(void)presendViewController:(UIViewController *_Nonnull)viewController
                    animated:(BOOL)flag
                  completion:(void (^ _Nullable)(void))completion;

+(void)dismissViewControllerAnimated:(BOOL)flag
                          completion:(void (^_Nullable)(void))completion;

@end

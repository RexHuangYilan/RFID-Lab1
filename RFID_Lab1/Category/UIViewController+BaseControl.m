//
//  UIViewController+BaseControl.m
//  RFID_Lab1
//
//  Created by Rex on 2017/12/9.
//  Copyright © 2017年 Rex. All rights reserved.
//

#import "UIViewController+BaseControl.h"

@implementation UIViewController (BaseControl)

-(void)scale
{
    CGFloat width = self.view.frame.size.width;
    CGFloat scale = width/375.0;
    self.view.transform = CGAffineTransformMakeScale(scale,scale);
}

+(UIViewController *)getViewControllerWithMainStoryboardIdentifier:(NSString *)identifier
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *vc = [sb instantiateViewControllerWithIdentifier:identifier];
    return vc;
}

+(UIViewController *)getTopViewController
{
    UIViewController *vc = [UIApplication sharedApplication].delegate.window.rootViewController;
    while (vc.presentedViewController) {
        vc = vc.presentedViewController;
    }
    return vc;
}

+(void)presendViewController:(UIViewController *)viewController
                    animated:(BOOL)flag
                  completion:(void (^)(void))completion
{
    UIViewController *vc = [self getTopViewController];
    [vc presentViewController:viewController
                     animated:flag
                   completion:completion];
}

+(void)dismissViewControllerAnimated:(BOOL)flag
                          completion:(void (^)(void))completion
{
    UIViewController *vc = [self getTopViewController];
    [vc dismissViewControllerAnimated:flag
                           completion:completion];
}

@end

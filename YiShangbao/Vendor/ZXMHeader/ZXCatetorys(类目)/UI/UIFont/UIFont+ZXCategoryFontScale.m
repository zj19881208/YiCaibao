//
//  UIFont+ZXCategoryFontScale.m
//  CollagePicture
//
//  Created by simon on 2019/4/17.
//  Copyright © 2019 simon. All rights reserved.
//

#import "UIFont+ZXCategoryFontScale.h"

static NSInteger const miniScreenFontSizeSpace = 1.5;

@implementation UIFont (ZXCategoryFontScale)

//注意：不能用runtime方法全局改字体；由于系统UIAlertController的字体已经经过适配了，再经过这个runtime方法会变大很多； 或许其它很多系统控件都会发生变化bug；所以不能用runtime交换方法改变UIFont方法来全部设置字体大小；
/*
+ (void)load
{
    Method originalMethod = class_getClassMethod([self class], @selector(systemFontOfSize:));
    Method swizzledMethod = class_getClassMethod([self class], @selector(zx_systemFontOfSize:));
    method_exchangeImplementations(originalMethod, swizzledMethod);


    Method originalMethod_name = class_getClassMethod([self class], @selector(fontWithName:size:));
    Method swizzledMethod_name = class_getClassMethod([self class], @selector(zx_fontWithName:size:));
    method_exchangeImplementations(originalMethod_name, swizzledMethod_name);
}

+ (UIFont *)zx_systemFontOfSize:(CGFloat)fontSize
{
    CGFloat transFontSize = [UIFont transSizeWithFontSize:fontSize];
    return [UIFont zx_systemFontOfSize:transFontSize];
}

+ (UIFont *)zx_fontWithName:(NSString *)fontName size:(CGFloat)fontSize
{
    CGFloat transFontSize = [UIFont transSizeWithFontSize:fontSize];
    return [UIFont zx_fontWithName:fontName size:transFontSize];
}
*/

//+ (UIFont *)zx_systemFontOfSize:(CGFloat)fontSize
//{
//    CGFloat transFontSize = [UIFont transSizeWithFontSize:fontSize];
//    return [UIFont systemFontOfSize:transFontSize];
//}
//
//+ (UIFont *)zx_fontWithName:(NSString *)fontName size:(CGFloat)fontSize
//{
//    CGFloat transFontSize = [UIFont transSizeWithFontSize:fontSize];
//    return [UIFont fontWithName:fontName size:transFontSize];
//}
- (UIFont *)zx_fontWithScaleSize:(CGFloat)fontSize{
    
    CGFloat transFontSize = [UIFont transSizeWithFontSize:fontSize];
    return [self fontWithSize:transFontSize];
}

+ (CGFloat)transSizeWithFontSize:(CGFloat)fontSize
{
    CGFloat transFontSize = fontSize;
    // 4.0inch的屏幕，特殊处理
    if ([UIScreen mainScreen].bounds.size.width == 320)
    {
        if (fontSize <= 12.0)
        {
            transFontSize = fontSize;
        }else{
            transFontSize = fontSize - miniScreenFontSizeSpace;
        }
    }
    // iPhone6，plus，iPhoneX系列
    else
    {
        CGFloat scale = [UIScreen mainScreen].bounds.size.width/375.f;
        transFontSize = scale * fontSize;
    }
    return transFontSize;
}
@end

//
//  MyRadioButton.m
//  WeiboClient
//
//  Created by flame_thupdi on 13-3-4.
//
//
#import "MyRadioButton.h"
#import "MyRadioButtonConstant.h"

@implementation MyRadioButton
@synthesize delegate;
@synthesize autoFitSubSize = _autoFitSubSize;

static const NSUInteger kRadioButtonWidth=32;
static const NSUInteger kRadioButtonHeight=32;

#pragma mark - Observer

-(void)setSelected:(BOOL)selected{
    [_button setSelected:selected];
}

-(id)initWithTitle:(NSString *)title andIndex:(int)index withFrame:(CGRect)frame autoSubSize:(BOOL)autoSize{
    self = [super init];
    if (self) {
        self.userInteractionEnabled = YES;
        self.tag = index;
        _index = index;
        self.frame = frame;
        _autoFitSubSize = autoSize;
        [self defaultInitWithTitle:title];
    }
    return self;
}

-(void)defaultInitWithTitle:(NSString *)title{
    CGRect buttonFrame = CGRectMake(0, 0, kRadioButtonHeight, kRadioButtonHeight);
    CGRect labelFrame = _button.frame;
    labelFrame.origin.x += HButtonSpanLabel + kRadioButtonWidth;
    labelFrame.origin.y -= VButtonSpanLabel -5;
    _button = [UIButton buttonWithType:UIButtonTypeCustom];
    _button.adjustsImageWhenHighlighted = NO;
    _button.userInteractionEnabled = YES;
    [_button setImage:[UIImage imageNamed:@"未选"] forState:UIControlStateNormal];
    [_button setImage:[UIImage imageNamed:@"选中"] forState:UIControlStateSelected];
    
    [_button addTarget:self action:@selector(handleButtonTap) forControlEvents:UIControlEventTouchUpInside];
    [_button setBackgroundColor:[UIColor clearColor]];
    [self addSubview:_button];
    
    _titleLabel = [[UILabel alloc]initWithFrame:labelFrame];
    [_titleLabel setTextColor:WYUISTYLE.colorBTgrey];
    _titleLabel.font = WYUISTYLE.fontWith28;
    [_titleLabel setBackgroundColor:[UIColor clearColor]];
    [_titleLabel setText:title];  
    if (_autoFitSubSize) {
        CGSize size = CGSizeMake(self.frame.size.width/2,self.frame.size.height);
        labelFrame.size = size;
        labelFrame.origin.y = 0;
        labelFrame.origin.x +=  HButtonSpanLabel + kRadioButtonWidth;
        [_titleLabel setFont:[UIFont systemFontOfSize:kRadioButtonWidth-5]];
    }
    else{
        [_titleLabel sizeToFit];
        labelFrame.size.height = _titleLabel.frame.size.height;
        labelFrame.size.width = _titleLabel.frame.size.width;
    }
    _button.frame = buttonFrame;
    _titleLabel.frame = labelFrame;
    if (!_autoFitSubSize){
        CGRect frame = self.frame;
        frame.size.width = labelFrame.size.width + buttonFrame.size.width;
        frame.size.height =labelFrame.size.height < buttonFrame.size.height?labelFrame.size.height:buttonFrame.size.height;
        self.frame = frame;
    }
    [self addSubview:_titleLabel];
}


-(void)handleButtonTap{
    if (!self.delegate) {
        return;
    }
    else if([self.delegate respondsToSelector:@selector(myButton:selectedWithIndex:)]){
        [self.delegate myButton:self selectedWithIndex:_index];
    }
}

@end

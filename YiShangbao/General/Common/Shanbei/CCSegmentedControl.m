//
//  ccSegmentedControl.m
//  SortOut
//
//  Created by light on 2018/3/7.
//  Copyright © 2018年 light. All rights reserved.
//

#import "CCSegmentedControl.h"

@interface CCScrollView : UIScrollView
@end

@implementation CCScrollView

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!self.dragging) {
        [self.nextResponder touchesBegan:touches withEvent:event];
    } else {
        [super touchesBegan:touches withEvent:event];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    if (!self.dragging) {
        [self.nextResponder touchesMoved:touches withEvent:event];
    } else{
        [super touchesMoved:touches withEvent:event];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!self.dragging) {
        [self.nextResponder touchesEnded:touches withEvent:event];
    } else {
        [super touchesEnded:touches withEvent:event];
    }
}

@end

@interface CCSegmentedControl ()

@property (nonatomic, strong) CALayer *selectionIndicatorStripLayer;
@property (nonatomic, strong) CALayer *selectionIndicatorBoxLayer;
@property (nonatomic, strong) CALayer *selectionIndicatorArrowLayer;

@property (nonatomic, readwrite) CGFloat segmentWidth;
@property (nonatomic, readwrite) NSArray<NSNumber *> *segmentWidthsArray;
@property (nonatomic, strong) CCScrollView *scrollView;

@end

@implementation CCSegmentedControl

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        [self commonInit];
    }
    
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.segmentWidth = 0.0f;
}

- (void)commonInit {
    self.scrollView = [[CCScrollView alloc] init];
    self.scrollView.scrollsToTop = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    [self addSubview:self.scrollView];
    
    _backgroundColor = [UIColor whiteColor];
    self.opaque = NO;
    _selectionIndicatorColor = [UIColor colorWithRed:52.0f/255.0f green:181.0f/255.0f blue:229.0f/255.0f alpha:1.0f];
    _selectionIndicatorBoxColor = _selectionIndicatorColor;

    self.selectedSegmentIndex = 0;
    self.segmentEdgeInset = UIEdgeInsetsMake(0, 5, 0, 5);
    self.selectionIndicatorHeight = 5.0f;
    self.selectionIndicatorEdgeInsets = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);
    self.selectionStyle = CCSegmentedControlSelectionStyleTextWidthStripe;
    self.selectionIndicatorLocation = CCSegmentedControlSelectionIndicatorLocationUp;
    self.segmentWidthStyle = CCSegmentedControlSegmentWidthStyleFixed;
    self.userDraggable = YES;
    self.touchEnabled = YES;
    self.verticalDividerEnabled = NO;
    self.type = CCSegmentedControlTypeText;
    self.verticalDividerWidth = 1.0f;
    _verticalDividerColor = [UIColor blackColor];
    self.borderColor = [UIColor blackColor];
    self.borderWidth = 1.0f;

    self.shouldAnimateUserSelection = YES;

    self.selectionIndicatorArrowLayer = [CALayer layer];
    self.selectionIndicatorStripLayer = [CALayer layer];
    self.selectionIndicatorBoxLayer = [CALayer layer];
    self.selectionIndicatorBoxLayer.opacity = self.selectionIndicatorBoxOpacity;
    self.selectionIndicatorBoxLayer.borderWidth = 1.0f;
    self.selectionIndicatorBoxOpacity = 0.2;
    
    
    self.selectionIndicatorStripLayer.masksToBounds = YES;
    self.selectionIndicatorStripLayer.cornerRadius = self.selectionIndicatorHeight / 2.0;
    self.selectionIndicatorBoxLayer.masksToBounds = YES;
    self.selectionIndicatorBoxLayer.cornerRadius = self.selectionIndicatorHeight / 2.0;
    
    self.contentMode = UIViewContentModeRedraw;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self updateSegmentsRects];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    [self updateSegmentsRects];
}

- (void)setSectionTitles:(NSArray<NSString *> *)sectionTitles {
    _sectionTitles = sectionTitles;
    
    [self setNeedsLayout];
    [self setNeedsDisplay];
}

- (void)setSectionImages:(NSArray<UIImage *> *)sectionImages {
    _sectionImages = sectionImages;
    
    [self setNeedsLayout];
    [self setNeedsDisplay];
}


- (void)setSelectionIndicatorLocation:(CCSegmentedControlSelectionIndicatorLocation)selectionIndicatorLocation {
    _selectionIndicatorLocation = selectionIndicatorLocation;
    
    if (selectionIndicatorLocation == CCSegmentedControlSelectionIndicatorLocationNone) {
        self.selectionIndicatorHeight = 0.0f;
    }
}

- (void)setSelectionIndicatorBoxOpacity:(CGFloat)selectionIndicatorBoxOpacity {
    _selectionIndicatorBoxOpacity = selectionIndicatorBoxOpacity;
    
    self.selectionIndicatorBoxLayer.opacity = _selectionIndicatorBoxOpacity;
}

- (void)setSegmentWidthStyle:(CCSegmentedControlSegmentWidthStyle)segmentWidthStyle {
    // Force CCSegmentedControlSegmentWidthStyleFixed when type is CCSegmentedControlTypeImages.
    if (self.type == CCSegmentedControlTypeImages) {
        _segmentWidthStyle = CCSegmentedControlSegmentWidthStyleFixed;
    } else {
        _segmentWidthStyle = segmentWidthStyle;
    }
}

- (void)setBorderType:(CCSegmentedControlBorderType)borderType {
    _borderType = borderType;
    [self setNeedsDisplay];
}

- (void)setSelectedSegmentIndex:(NSInteger)selectedSegmentIndex {
    _selectedSegmentIndex = selectedSegmentIndex;
    [self updateSegmentsRects];
    [self setNeedsDisplay];
}

#pragma mark - Drawing

- (CGSize)measureTitleAtIndex:(NSUInteger)index {
    if (index >= self.sectionTitles.count) {
        return CGSizeZero;
    }
    
    id title = self.sectionTitles[index];
    CGSize size = CGSizeZero;
    BOOL selected = (index == self.selectedSegmentIndex) ? YES : NO;
    if ([title isKindOfClass:[NSString class]] && !self.titleFormatter) {
        NSDictionary *titleAttrs = selected ? [self resultingSelectedTitleTextAttributes] : [self resultingTitleTextAttributes];
        size = [(NSString *)title sizeWithAttributes:titleAttrs];
    } else if ([title isKindOfClass:[NSString class]] && self.titleFormatter) {
        size = [self.titleFormatter(self, title, index, selected) size];
    } else if ([title isKindOfClass:[NSAttributedString class]]) {
        size = [(NSAttributedString *)title size];
    } else {
        NSAssert(title == nil, @"Unexpected type of segment title: %@", [title class]);
        size = CGSizeZero;
    }
    return CGRectIntegral((CGRect){CGPointZero, size}).size;
}

- (NSAttributedString *)attributedTitleAtIndex:(NSUInteger)index {
    id title = self.sectionTitles[index];
    BOOL selected = (index == self.selectedSegmentIndex) ? YES : NO;
    
    if ([title isKindOfClass:[NSAttributedString class]]) {
        return (NSAttributedString *)title;
    } else if (!self.titleFormatter) {
        NSDictionary *titleAttrs = selected ? [self resultingSelectedTitleTextAttributes] : [self resultingTitleTextAttributes];
        
        // the color should be cast to CGColor in order to avoid invalid context on iOS7
        UIColor *titleColor = titleAttrs[NSForegroundColorAttributeName];
        
        if (titleColor) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:titleAttrs];
            
            dict[NSForegroundColorAttributeName] = (id)titleColor.CGColor;
            
            titleAttrs = [NSDictionary dictionaryWithDictionary:dict];
        }
        
        return [[NSAttributedString alloc] initWithString:(NSString *)title attributes:titleAttrs];
    } else {
        return self.titleFormatter(self, title, index, selected);
    }
}

- (void)setArrowFrame {
    self.selectionIndicatorArrowLayer.frame = [self frameForSelectionIndicator];
    
    self.selectionIndicatorArrowLayer.mask = nil;
    
    UIBezierPath *arrowPath = [UIBezierPath bezierPath];
    
    CGPoint p1 = CGPointZero;
    CGPoint p2 = CGPointZero;
    CGPoint p3 = CGPointZero;
    
    if (self.selectionIndicatorLocation == CCSegmentedControlSelectionIndicatorLocationDown) {
        p1 = CGPointMake(self.selectionIndicatorArrowLayer.bounds.size.width / 2, 0);
        p2 = CGPointMake(0, self.selectionIndicatorArrowLayer.bounds.size.height);
        p3 = CGPointMake(self.selectionIndicatorArrowLayer.bounds.size.width, self.selectionIndicatorArrowLayer.bounds.size.height);
    }
    
    if (self.selectionIndicatorLocation == CCSegmentedControlSelectionIndicatorLocationUp) {
        p1 = CGPointMake(self.selectionIndicatorArrowLayer.bounds.size.width / 2, self.selectionIndicatorArrowLayer.bounds.size.height);
        p2 = CGPointMake(self.selectionIndicatorArrowLayer.bounds.size.width, 0);
        p3 = CGPointMake(0, 0);
    }
    
    [arrowPath moveToPoint:p1];
    [arrowPath addLineToPoint:p2];
    [arrowPath addLineToPoint:p3];
    [arrowPath closePath];
    
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.selectionIndicatorArrowLayer.bounds;
    maskLayer.path = arrowPath.CGPath;
    self.selectionIndicatorArrowLayer.mask = maskLayer;
}

- (CGRect)frameForSelectionIndicator {
    CGFloat indicatorYOffset = 0.0f;
    
    if (self.selectionIndicatorLocation == CCSegmentedControlSelectionIndicatorLocationDown) {
        indicatorYOffset = self.bounds.size.height - self.selectionIndicatorHeight - self.selectionIndicatorEdgeInsets.bottom;
    }
    
    if (self.selectionIndicatorLocation == CCSegmentedControlSelectionIndicatorLocationUp) {
        indicatorYOffset = self.selectionIndicatorEdgeInsets.top;
    }
    
    CGFloat sectionWidth = 0.0f;
    
    if (self.type == CCSegmentedControlTypeText) {
        CGFloat stringWidth = [self measureTitleAtIndex:self.selectedSegmentIndex].width;
        sectionWidth = stringWidth;
    } else if (self.type == CCSegmentedControlTypeImages) {
//        UIImage *sectionImage = [self.sectionImages objectAtIndex:self.selectedSegmentIndex];
//        CGFloat imageWidth = sectionImage.size.width;
//        sectionWidth = imageWidth;
    } else if (self.type == CCSegmentedControlTypeTextImages) {
//        CGFloat stringWidth = [self measureTitleAtIndex:self.selectedSegmentIndex].width;
//        UIImage *sectionImage = [self.sectionImages objectAtIndex:self.selectedSegmentIndex];
//        CGFloat imageWidth = sectionImage.size.width;
//        sectionWidth = MAX(stringWidth, imageWidth);
    }
    
    if (self.selectionStyle == CCSegmentedControlSelectionStyleArrow) {
        CGFloat widthToEndOfSelectedSegment = (self.segmentWidth * self.selectedSegmentIndex) + self.segmentWidth;
        CGFloat widthToStartOfSelectedIndex = (self.segmentWidth * self.selectedSegmentIndex);
        
        CGFloat x = widthToStartOfSelectedIndex + ((widthToEndOfSelectedSegment - widthToStartOfSelectedIndex) / 2) - (self.selectionIndicatorHeight/2);
        return CGRectMake(x - (self.selectionIndicatorHeight / 2), indicatorYOffset, self.selectionIndicatorHeight * 2, self.selectionIndicatorHeight);
    } else {
        if (self.selectionStyle == CCSegmentedControlSelectionStyleTextWidthStripe &&
            sectionWidth <= self.segmentWidth &&
            self.segmentWidthStyle != CCSegmentedControlSegmentWidthStyleDynamic) {
            CGFloat widthToEndOfSelectedSegment = (self.segmentWidth * self.selectedSegmentIndex) + self.segmentWidth;
            CGFloat widthToStartOfSelectedIndex = (self.segmentWidth * self.selectedSegmentIndex);
            
            CGFloat x = ((widthToEndOfSelectedSegment - widthToStartOfSelectedIndex) / 2) + (widthToStartOfSelectedIndex - sectionWidth / 2);
            return CGRectMake(x + self.selectionIndicatorEdgeInsets.left, indicatorYOffset, sectionWidth - self.selectionIndicatorEdgeInsets.left - self.selectionIndicatorEdgeInsets.right, self.selectionIndicatorHeight);
        } else {
            if (self.segmentWidthStyle == CCSegmentedControlSegmentWidthStyleDynamic) {
                CGFloat selectedSegmentOffset = 0.0f;
                
                NSInteger i = 0;
                for (NSNumber *width in self.segmentWidthsArray) {
                    if (self.selectedSegmentIndex == i)
                        break;
                    selectedSegmentOffset = selectedSegmentOffset + [width floatValue];
                    i++;
                }
                return CGRectMake(selectedSegmentOffset + self.selectionIndicatorEdgeInsets.left, indicatorYOffset, [[self.segmentWidthsArray objectAtIndex:self.selectedSegmentIndex] floatValue] - self.selectionIndicatorEdgeInsets.right, self.selectionIndicatorHeight + self.selectionIndicatorEdgeInsets.bottom);
            }
            
            return CGRectMake((self.segmentWidth + self.selectionIndicatorEdgeInsets.left) * self.selectedSegmentIndex, indicatorYOffset, self.segmentWidth - self.selectionIndicatorEdgeInsets.right, self.selectionIndicatorHeight);
        }
    }
}

- (CGRect)frameForFillerSelectionIndicator {
    if (self.segmentWidthStyle == CCSegmentedControlSegmentWidthStyleDynamic) {
        CGFloat selectedSegmentOffset = 0.0f;
        
        NSInteger i = 0;
        for (NSNumber *width in self.segmentWidthsArray) {
            if (self.selectedSegmentIndex == i) {
                break;
            }
            selectedSegmentOffset = selectedSegmentOffset + [width floatValue];
            
            i++;
        }
        
        return CGRectMake(selectedSegmentOffset, 0, [[self.segmentWidthsArray objectAtIndex:self.selectedSegmentIndex] floatValue], CGRectGetHeight(self.frame));
    }
    return CGRectMake(self.segmentWidth * self.selectedSegmentIndex, 0, self.segmentWidth, CGRectGetHeight(self.frame));
}

- (void)updateSegmentsRects {
    self.scrollView.contentInset = UIEdgeInsetsZero;
    self.scrollView.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
    
    if ([self sectionCount] > 0) {
        self.segmentWidth = self.frame.size.width / [self sectionCount];
    }
    
    if (self.type == CCSegmentedControlTypeText && self.segmentWidthStyle == CCSegmentedControlSegmentWidthStyleFixed) {
        [self.sectionTitles enumerateObjectsUsingBlock:^(id titleString, NSUInteger idx, BOOL *stop) {
            CGFloat stringWidth = [self measureTitleAtIndex:idx].width + self.segmentEdgeInset.left + self.segmentEdgeInset.right;
            self.segmentWidth = MAX(stringWidth, self.segmentWidth);
        }];
    } else if (self.type == CCSegmentedControlTypeText && self.segmentWidthStyle == CCSegmentedControlSegmentWidthStyleDynamic) {
        NSMutableArray *mutableSegmentWidths = [NSMutableArray array];

        [self.sectionTitles enumerateObjectsUsingBlock:^(id titleString, NSUInteger idx, BOOL *stop) {
            CGFloat stringWidth = [self measureTitleAtIndex:idx].width + self.segmentEdgeInset.left + self.segmentEdgeInset.right;
            [mutableSegmentWidths addObject:[NSNumber numberWithFloat:stringWidth]];
        }];
        self.segmentWidthsArray = [mutableSegmentWidths copy];
    } else if (self.type == CCSegmentedControlTypeImages) {
//        for (UIImage *sectionImage in self.sectionImages) {
//            CGFloat imageWidth = sectionImage.size.width + self.segmentEdgeInset.left + self.segmentEdgeInset.right;
//            self.segmentWidth = MAX(imageWidth, self.segmentWidth);
//        }
    } else if (self.type == CCSegmentedControlTypeTextImages && self.segmentWidthStyle == CCSegmentedControlSegmentWidthStyleFixed){
//        //lets just use the title.. we will assume it is wider then images...
//        [self.sectionTitles enumerateObjectsUsingBlock:^(id titleString, NSUInteger idx, BOOL *stop) {
//            CGFloat stringWidth = [self measureTitleAtIndex:idx].width + self.segmentEdgeInset.left + self.segmentEdgeInset.right;
//            self.segmentWidth = MAX(stringWidth, self.segmentWidth);
//        }];
    } else if (self.type == CCSegmentedControlTypeTextImages && self.segmentWidthStyle == CCSegmentedControlSegmentWidthStyleDynamic) {
//        NSMutableArray *mutableSegmentWidths = [NSMutableArray array];
//
//        int i = 0;
//        [self.sectionTitles enumerateObjectsUsingBlock:^(id titleString, NSUInteger idx, BOOL *stop) {
//            CGFloat stringWidth = [self measureTitleAtIndex:idx].width + self.segmentEdgeInset.right;
//            UIImage *sectionImage = [self.sectionImages objectAtIndex:i];
//            CGFloat imageWidth = sectionImage.size.width + self.segmentEdgeInset.left;
//
//            CGFloat combinedWidth = MAX(imageWidth, stringWidth);
//
//            [mutableSegmentWidths addObject:[NSNumber numberWithFloat:combinedWidth]];
//        }];
//        self.segmentWidthsArray = [mutableSegmentWidths copy];
    }

    self.scrollView.scrollEnabled = self.isUserDraggable;
    self.scrollView.contentSize = CGSizeMake([self totalSegmentedControlWidth], self.frame.size.height);
}

- (NSUInteger)sectionCount {
    if (self.type == CCSegmentedControlTypeText) {
        return self.sectionTitles.count;
    } else if (self.type == CCSegmentedControlTypeImages ||
               self.type == CCSegmentedControlTypeTextImages) {
//        return self.sectionImages.count;
    }

    return 0;
}

- (void)drawRect:(CGRect)rect {
    [self.backgroundColor setFill];
    UIRectFill([self bounds]);
    
    self.selectionIndicatorArrowLayer.backgroundColor = self.selectionIndicatorColor.CGColor;
    
    self.selectionIndicatorStripLayer.backgroundColor = self.selectionIndicatorColor.CGColor;
    
    self.selectionIndicatorBoxLayer.backgroundColor = self.selectionIndicatorBoxColor.CGColor;
    self.selectionIndicatorBoxLayer.borderColor = self.selectionIndicatorBoxColor.CGColor;
    
    // Remove all sublayers to avoid drawing images over existing ones
    self.scrollView.layer.sublayers = nil;

    CGRect oldRect = rect;

    if (self.type == CCSegmentedControlTypeText) {
        [self.sectionTitles enumerateObjectsUsingBlock:^(id titleString, NSUInteger idx, BOOL *stop) {

            CGFloat stringWidth = 0;
            CGFloat stringHeight = 0;
            CGSize size = [self measureTitleAtIndex:idx];
            stringWidth = size.width;
            stringHeight = size.height;
            CGRect rectDiv = CGRectZero;
            CGRect fullRect = CGRectZero;

            // Text inside the CATextLayer will appear blurry unless the rect values are rounded
            BOOL locationUp = (self.selectionIndicatorLocation == CCSegmentedControlSelectionIndicatorLocationUp);
            BOOL selectionStyleNotBox = (self.selectionStyle != CCSegmentedControlSelectionStyleBox);

            CGFloat y = roundf((CGRectGetHeight(self.frame) - selectionStyleNotBox * self.selectionIndicatorHeight) / 2 - stringHeight / 2 + self.selectionIndicatorHeight * locationUp);
            CGRect rect;
            if (self.segmentWidthStyle == CCSegmentedControlSegmentWidthStyleFixed) {
                rect = CGRectMake((self.segmentWidth * idx) + (self.segmentWidth - stringWidth) / 2, y, stringWidth, stringHeight);
                rectDiv = CGRectMake((self.segmentWidth * idx) - (self.verticalDividerWidth / 2), self.selectionIndicatorHeight * 2, self.verticalDividerWidth, self.frame.size.height - (self.selectionIndicatorHeight * 4));
                fullRect = CGRectMake(self.segmentWidth * idx, 0, self.segmentWidth, oldRect.size.height);
            } else {
                // When we are drawing dynamic widths, we need to loop the widths array to calculate the xOffset
                CGFloat xOffset = 0;
                NSInteger i = 0;
                for (NSNumber *width in self.segmentWidthsArray) {
                    if (idx == i)
                        break;
                    xOffset = xOffset + [width floatValue];
                    i++;
                }

                CGFloat widthForIndex = [[self.segmentWidthsArray objectAtIndex:idx] floatValue];
                rect = CGRectMake(xOffset, y, widthForIndex, stringHeight);
                fullRect = CGRectMake(xOffset, 0, widthForIndex, oldRect.size.height);
                rectDiv = CGRectMake(xOffset - (self.verticalDividerWidth / 2), self.selectionIndicatorHeight * 2, self.verticalDividerWidth, self.frame.size.height - (self.selectionIndicatorHeight * 4));
            }

            // Fix rect position/size to avoid blurry labels
            rect = CGRectMake(ceilf(rect.origin.x), ceilf(rect.origin.y), ceilf(rect.size.width), ceilf(rect.size.height));

            CATextLayer *titleLayer = [CATextLayer layer];
            titleLayer.frame = rect;
            titleLayer.alignmentMode = kCAAlignmentCenter;
            if ([UIDevice currentDevice].systemVersion.floatValue < 10.0 ) {
                titleLayer.truncationMode = kCATruncationEnd;
            }
            titleLayer.string = [self attributedTitleAtIndex:idx];
            titleLayer.contentsScale = [[UIScreen mainScreen] scale];

            [self.scrollView.layer addSublayer:titleLayer];

            // Vertical Divider
            if (self.isVerticalDividerEnabled && idx > 0) {
                CALayer *verticalDividerLayer = [CALayer layer];
                verticalDividerLayer.frame = rectDiv;
                verticalDividerLayer.backgroundColor = self.verticalDividerColor.CGColor;

                [self.scrollView.layer addSublayer:verticalDividerLayer];
            }

            [self addBackgroundAndBorderLayerWithRect:fullRect];
        }];
    } else if (self.type == CCSegmentedControlTypeImages) {
//        [self.sectionImages enumerateObjectsUsingBlock:^(id iconImage, NSUInteger idx, BOOL *stop) {
//            UIImage *icon = iconImage;
//            CGFloat imageWidth = icon.size.width;
//            CGFloat imageHeight = icon.size.height;
//            CGFloat y = roundf(CGRectGetHeight(self.frame) - self.selectionIndicatorHeight) / 2 - imageHeight / 2 + ((self.selectionIndicatorLocation == CCSegmentedControlSelectionIndicatorLocationUp) ? self.selectionIndicatorHeight : 0);
//            CGFloat x = self.segmentWidth * idx + (self.segmentWidth - imageWidth)/2.0f;
//            CGRect rect = CGRectMake(x, y, imageWidth, imageHeight);
//
//            CALayer *imageLayer = [CALayer layer];
//            imageLayer.frame = rect;
//
//            if (self.selectedSegmentIndex == idx) {
//                if (self.sectionSelectedImages) {
//                    UIImage *highlightIcon = [self.sectionSelectedImages objectAtIndex:idx];
//                    imageLayer.contents = (id)highlightIcon.CGImage;
//                } else {
//                    imageLayer.contents = (id)icon.CGImage;
//                }
//            } else {
//                imageLayer.contents = (id)icon.CGImage;
//            }
//
//            [self.scrollView.layer addSublayer:imageLayer];
//            // Vertical Divider
//            if (self.isVerticalDividerEnabled && idx>0) {
//                CALayer *verticalDividerLayer = [CALayer layer];
//                verticalDividerLayer.frame = CGRectMake((self.segmentWidth * idx) - (self.verticalDividerWidth / 2), self.selectionIndicatorHeight * 2, self.verticalDividerWidth, self.frame.size.height-(self.selectionIndicatorHeight * 4));
//                verticalDividerLayer.backgroundColor = self.verticalDividerColor.CGColor;
//
//                [self.scrollView.layer addSublayer:verticalDividerLayer];
//            }
//
//            [self addBackgroundAndBorderLayerWithRect:rect];
//        }];
    } else if (self.type == CCSegmentedControlTypeTextImages){
//        [self.sectionImages enumerateObjectsUsingBlock:^(id iconImage, NSUInteger idx, BOOL *stop) {
//            UIImage *icon = iconImage;
//            CGFloat imageWidth = icon.size.width;
//            CGFloat imageHeight = icon.size.height;
//
//            CGFloat stringHeight = [self measureTitleAtIndex:idx].height;
//            CGFloat yOffset = roundf(((CGRectGetHeight(self.frame) - self.selectionIndicatorHeight) / 2) - (stringHeight / 2));
//
//            CGFloat imageXOffset = self.segmentEdgeInset.left; // Start with edge inset
//            CGFloat textXOffset  = self.segmentEdgeInset.left;
//            CGFloat textWidth = 0;
//
//            if (self.segmentWidthStyle == CCSegmentedControlSegmentWidthStyleFixed) {
//                imageXOffset = (self.segmentWidth * idx) + (self.segmentWidth / 2.0f) - (imageWidth / 2.0f);
//                textXOffset = self.segmentWidth * idx;
//                textWidth = self.segmentWidth;
//            } else if (self.segmentWidthStyle == CCSegmentedControlSegmentWidthStyleDynamic) {
//                // When we are drawing dynamic widths, we need to loop the widths array to calculate the xOffset
//                CGFloat xOffset = 0;
//                NSInteger i = 0;
//
//                for (NSNumber *width in self.segmentWidthsArray) {
//                    if (idx == i) {
//                        break;
//                    }
//
//                    xOffset = xOffset + [width floatValue];
//                    i++;
//                }
//
//                imageXOffset = xOffset + ([self.segmentWidthsArray[idx] floatValue] / 2.0f) - (imageWidth / 2.0f); //(self.segmentWidth / 2.0f) - (imageWidth / 2.0f)
//                textXOffset = xOffset;
//                textWidth = [self.segmentWidthsArray[idx] floatValue];
//            }
//
//            CGFloat imageYOffset = roundf((CGRectGetHeight(self.frame) - self.selectionIndicatorHeight) / 2.0f);
//            CGRect imageRect = CGRectMake(imageXOffset, imageYOffset, imageWidth, imageHeight);
//            CGRect textRect = CGRectMake(textXOffset, yOffset, textWidth, stringHeight);
//
//            // Fix rect position/size to avoid blurry labels
//            textRect = CGRectMake(ceilf(textRect.origin.x), ceilf(textRect.origin.y), ceilf(textRect.size.width), ceilf(textRect.size.height));
//
//            CATextLayer *titleLayer = [CATextLayer layer];
//            titleLayer.frame = textRect;
//            titleLayer.alignmentMode = kCAAlignmentCenter;
//            titleLayer.string = [self attributedTitleAtIndex:idx];
//            if ([UIDevice currentDevice].systemVersion.floatValue < 10.0 ) {
//                titleLayer.truncationMode = kCATruncationEnd;
//            }
//            CALayer *imageLayer = [CALayer layer];
//            imageLayer.frame = imageRect;
//
//            if (self.selectedSegmentIndex == idx) {
//                if (self.sectionSelectedImages) {
//                    UIImage *highlightIcon = [self.sectionSelectedImages objectAtIndex:idx];
//                    imageLayer.contents = (id)highlightIcon.CGImage;
//                } else {
//                    imageLayer.contents = (id)icon.CGImage;
//                }
//            } else {
//                imageLayer.contents = (id)icon.CGImage;
//            }
//
//            [self.scrollView.layer addSublayer:imageLayer];
//            titleLayer.contentsScale = [[UIScreen mainScreen] scale];
//            [self.scrollView.layer addSublayer:titleLayer];
//
//            [self addBackgroundAndBorderLayerWithRect:imageRect];
//        }];
    }

    // Add the selection indicators
    if (self.selectedSegmentIndex != CCSegmentedControlNoSegment) {
        if (self.selectionStyle == CCSegmentedControlSelectionStyleArrow) {
            if (!self.selectionIndicatorArrowLayer.superlayer) {
                [self setArrowFrame];
                [self.scrollView.layer addSublayer:self.selectionIndicatorArrowLayer];
            }
        } else {
            if (!self.selectionIndicatorStripLayer.superlayer) {
                self.selectionIndicatorStripLayer.frame = [self frameForSelectionIndicator];
                [self.scrollView.layer addSublayer:self.selectionIndicatorStripLayer];

                if (self.selectionStyle == CCSegmentedControlSelectionStyleBox && !self.selectionIndicatorBoxLayer.superlayer) {
                    self.selectionIndicatorBoxLayer.frame = [self frameForFillerSelectionIndicator];
                    [self.scrollView.layer insertSublayer:self.selectionIndicatorBoxLayer atIndex:0];
                }
            }
        }
    }
}

- (void)addBackgroundAndBorderLayerWithRect:(CGRect)fullRect {
    // Background layer
    CALayer *backgroundLayer = [CALayer layer];
    backgroundLayer.frame = fullRect;
    [self.scrollView.layer insertSublayer:backgroundLayer atIndex:0];
    
    // Border layer
    if (self.borderType & CCSegmentedControlBorderTypeTop) {
        CALayer *borderLayer = [CALayer layer];
        borderLayer.frame = CGRectMake(0, 0, fullRect.size.width, self.borderWidth);
        borderLayer.backgroundColor = self.borderColor.CGColor;
        [backgroundLayer addSublayer: borderLayer];
    }
    if (self.borderType & CCSegmentedControlBorderTypeLeft) {
        CALayer *borderLayer = [CALayer layer];
        borderLayer.frame = CGRectMake(0, 0, self.borderWidth, fullRect.size.height);
        borderLayer.backgroundColor = self.borderColor.CGColor;
        [backgroundLayer addSublayer: borderLayer];
    }
    if (self.borderType & CCSegmentedControlBorderTypeBottom) {
        CALayer *borderLayer = [CALayer layer];
        borderLayer.frame = CGRectMake(0, fullRect.size.height - self.borderWidth, fullRect.size.width, self.borderWidth);
        borderLayer.backgroundColor = self.borderColor.CGColor;
        [backgroundLayer addSublayer: borderLayer];
    }
    if (self.borderType & CCSegmentedControlBorderTypeRight) {
        CALayer *borderLayer = [CALayer layer];
        borderLayer.frame = CGRectMake(fullRect.size.width - self.borderWidth, 0, self.borderWidth, fullRect.size.height);
        borderLayer.backgroundColor = self.borderColor.CGColor;
        [backgroundLayer addSublayer: borderLayer];
    }
}
#pragma mark - Touch

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInView:self];
    
    CGRect enlargeRect =   CGRectMake(self.bounds.origin.x - self.enlargeEdgeInset.left,
                                      self.bounds.origin.y - self.enlargeEdgeInset.top,
                                      self.bounds.size.width + self.enlargeEdgeInset.left + self.enlargeEdgeInset.right,
                                      self.bounds.size.height + self.enlargeEdgeInset.top + self.enlargeEdgeInset.bottom);
    
    if (CGRectContainsPoint(enlargeRect, touchLocation)) {
        NSInteger segment = 0;
        if (self.segmentWidthStyle == CCSegmentedControlSegmentWidthStyleFixed) {
            segment = (touchLocation.x + self.scrollView.contentOffset.x) / self.segmentWidth;
        } else if (self.segmentWidthStyle == CCSegmentedControlSegmentWidthStyleDynamic) {
            // To know which segment the user touched, we need to loop over the widths and substract it from the x position.
            CGFloat widthLeft = (touchLocation.x + self.scrollView.contentOffset.x);
            for (NSNumber *width in self.segmentWidthsArray) {
                widthLeft = widthLeft - [width floatValue];

                // When we don't have any width left to substract, we have the segment index.
                if (widthLeft <= 0)
                    break;

                segment++;
            }
        }
        
        NSUInteger sectionsCount = 0;
        
        if (self.type == CCSegmentedControlTypeImages) {
//            sectionsCount = [self.sectionImages count];
        } else if (self.type == CCSegmentedControlTypeTextImages || self.type == CCSegmentedControlTypeText) {
            sectionsCount = [self.sectionTitles count];
        }
        
        
        if (segment != self.selectedSegmentIndex && segment < sectionsCount) {
            // Check if we have to do anything with the touch event
            if (self.isTouchEnabled)
                [self setSelectedSegmentIndex:segment animated:self.shouldAnimateUserSelection notify:YES];
//        [self setSelectedSegmentIndex:segment animated:YES notify:YES];
        }
    }
}

- (void)setSelectedSegmentIndex:(NSUInteger)index animated:(BOOL)animated{
    [self setSelectedSegmentIndex:index animated:animated notify:NO];
}

- (void)setSelectedSegmentIndex:(NSUInteger)index animated:(BOOL)animated notify:(BOOL)notify {
    _selectedSegmentIndex = index;
    [self updateSegmentsRects];
    [self setNeedsDisplay];
    
    if (index == CCSegmentedControlNoSegment) {
        [self.selectionIndicatorArrowLayer removeFromSuperlayer];
        [self.selectionIndicatorStripLayer removeFromSuperlayer];
        [self.selectionIndicatorBoxLayer removeFromSuperlayer];
    } else {
        [self scrollToSelectedSegmentIndex:animated];
        
        if (animated) {
            // If the selected segment layer is not added to the super layer, that means no
            // index is currently selected, so add the layer then move it to the new
            // segment index without animating.
            if(self.selectionStyle == CCSegmentedControlSelectionStyleArrow) {
                if ([self.selectionIndicatorArrowLayer superlayer] == nil) {
                    [self.scrollView.layer addSublayer:self.selectionIndicatorArrowLayer];

                    [self setSelectedSegmentIndex:index animated:NO notify:YES];
                    return;
                }
            }else {
                if ([self.selectionIndicatorStripLayer superlayer] == nil) {
                    [self.scrollView.layer addSublayer:self.selectionIndicatorStripLayer];

                    if (self.selectionStyle == CCSegmentedControlSelectionStyleBox && [self.selectionIndicatorBoxLayer superlayer] == nil)
                        [self.scrollView.layer insertSublayer:self.selectionIndicatorBoxLayer atIndex:0];

                    [self setSelectedSegmentIndex:index animated:NO notify:YES];
                    return;
                }
            }
            
            if (notify)
                [self notifyForSegmentChangeToIndex:index];
            
            // Restore CALayer animations
            self.selectionIndicatorArrowLayer.actions = nil;
            self.selectionIndicatorStripLayer.actions = nil;
            self.selectionIndicatorBoxLayer.actions = nil;
            
            // Animate to new position
            [CATransaction begin];
            [CATransaction setAnimationDuration:0.15f];
            [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
            [self setArrowFrame];
            self.selectionIndicatorBoxLayer.frame = [self frameForSelectionIndicator];
            self.selectionIndicatorStripLayer.frame = [self frameForSelectionIndicator];
            self.selectionIndicatorBoxLayer.frame = [self frameForFillerSelectionIndicator];
            [CATransaction commit];
        } else {
            // Disable CALayer animations
            NSMutableDictionary *newActions = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNull null], @"position", [NSNull null], @"bounds", nil];
            self.selectionIndicatorArrowLayer.actions = newActions;
            [self setArrowFrame];

            self.selectionIndicatorStripLayer.actions = newActions;
            self.selectionIndicatorStripLayer.frame = [self frameForSelectionIndicator];

            self.selectionIndicatorBoxLayer.actions = newActions;
            self.selectionIndicatorBoxLayer.frame = [self frameForFillerSelectionIndicator];
            
            if (notify)
                [self notifyForSegmentChangeToIndex:index];
        }
    }
}


- (void)notifyForSegmentChangeToIndex:(NSInteger)index {
    if (self.superview)
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    
    if (self.indexChangeBlock)
        self.indexChangeBlock(index);
}


#pragma mark - Scrolling

- (CGFloat)totalSegmentedControlWidth {
    if (self.type == CCSegmentedControlTypeText && self.segmentWidthStyle == CCSegmentedControlSegmentWidthStyleFixed) {
        return self.sectionTitles.count * self.segmentWidth;
    } else if (self.segmentWidthStyle == CCSegmentedControlSegmentWidthStyleDynamic) {
        return [[self.segmentWidthsArray valueForKeyPath:@"@sum.self"] floatValue];
    } else {
        return self.sectionImages.count * self.segmentWidth;
    }
}

- (void)scrollToSelectedSegmentIndex:(BOOL)animated {
    CGRect rectForSelectedIndex = CGRectZero;
    CGFloat selectedSegmentOffset = 0;
    if (self.segmentWidthStyle == CCSegmentedControlSegmentWidthStyleFixed) {
        rectForSelectedIndex = CGRectMake(self.segmentWidth * self.selectedSegmentIndex,
                                          0,
                                          self.segmentWidth,
                                          self.frame.size.height);

        selectedSegmentOffset = (CGRectGetWidth(self.frame) / 2) - (self.segmentWidth / 2);
    } else {
        NSInteger i = 0;
        CGFloat offsetter = 0;
        for (NSNumber *width in self.segmentWidthsArray) {
            if (self.selectedSegmentIndex == i)
                break;
            offsetter = offsetter + [width floatValue];
            i++;
        }

        rectForSelectedIndex = CGRectMake(offsetter,
                                          0,
                                          [[self.segmentWidthsArray objectAtIndex:self.selectedSegmentIndex] floatValue],
                                          self.frame.size.height);

        selectedSegmentOffset = (CGRectGetWidth(self.frame) / 2) - ([[self.segmentWidthsArray objectAtIndex:self.selectedSegmentIndex] floatValue] / 2);
    }
    
    CGRect rectToScrollTo = rectForSelectedIndex;
    rectToScrollTo.origin.x -= selectedSegmentOffset;
    rectToScrollTo.size.width += selectedSegmentOffset * 2;
    [self.scrollView scrollRectToVisible:rectToScrollTo animated:animated];
}

#pragma mark - Styling Support

- (NSDictionary *)resultingTitleTextAttributes {
    NSDictionary *defaults = @{
                               NSFontAttributeName : [UIFont systemFontOfSize:19.0f],
                               NSForegroundColorAttributeName : [UIColor blackColor],
                               };
    
    NSMutableDictionary *resultingAttrs = [NSMutableDictionary dictionaryWithDictionary:defaults];
    
    if (self.titleTextAttributes) {
        [resultingAttrs addEntriesFromDictionary:self.titleTextAttributes];
    }
    
    return [resultingAttrs copy];
}

- (NSDictionary *)resultingSelectedTitleTextAttributes {
    NSMutableDictionary *resultingAttrs = [NSMutableDictionary dictionaryWithDictionary:[self resultingTitleTextAttributes]];
    
    if (self.selectedTitleTextAttributes) {
        [resultingAttrs addEntriesFromDictionary:self.selectedTitleTextAttributes];
    }
    
    return [resultingAttrs copy];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end

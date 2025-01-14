//
//  XLPhotoBrowser.m
//  XLPhotoBrowserDemo
//
//  Created by Liushannoon on 16/7/16.
//  Copyright © 2016年 LiuShannoon. All rights reserved.
//

#import "XLPhotoBrowser.h"
#import "XLZoomingScrollView.h"
#import "TAPageControl.h"
#import "FSActionSheetConfig.h"
#import "FSActionSheet.h"

#import "XLPhotoBrowserConfig.h"

@implementation XLPhotoUrlModel

@end

@interface XLPhotoBrowser () <XLZoomingScrollViewDelegate , UIScrollViewDelegate>

/**
 *  存放所有图片的容器
 */
@property (nonatomic , strong) UIScrollView  *scrollView;
/**
 *   保存图片的过程指示菊花
 */
@property (nonatomic , strong) UIActivityIndicatorView  *indicatorView;
/**
 *   保存图片的结果指示label
 */
@property (nonatomic , strong) UILabel *savaImageTipLabel;
/**
 *  正在使用的XLZoomingScrollView对象集
 */
@property (nonatomic , strong) NSMutableSet  *visibleZoomingScrollViews;
/**
 *  循环利用池中的XLZoomingScrollView对象集,用于循环利用
 */
@property (nonatomic , strong) NSMutableSet  *reusableZoomingScrollViews;
/**
 *  pageControl
 */
@property (nonatomic , strong) UIControl  *pageControl;
/**
 *  index label
 */
@property (nonatomic , strong) UILabel  *indexLabel;
/**
 *  保存按钮
 */
@property (nonatomic , strong) UIButton *saveButton;

/**
 查看产品详情按钮
 */
@property (nonatomic, strong) UIButton *detailButton;
/**
 *  ActionSheet的otherbuttontitles
 */
@property (nonatomic , strong) NSArray  *actionOtherButtonTitles;
/**
 *  ActionSheet的title
 */
@property (nonatomic , strong) NSString  *actionSheetTitle;
/**
 *  actionSheet的取消按钮title
 */
@property (nonatomic , strong) NSString  *actionSheetCancelTitle;
/**
 *  actionSheet的高亮按钮title
 */
@property (nonatomic , strong) NSString  *actionSheetDeleteButtonTitle;
@property (nonatomic, assign) CGSize pageControlDotSize;
@property(nonatomic, strong) NSArray *images;

@property (nonatomic, weak) UIViewController *showVC;
@property (nonatomic, strong) NSArray *goodsUrlList;

@end

@implementation XLPhotoBrowser

#pragma mark    -   set / get

- (UILabel *)savaImageTipLabel
{
    if (_savaImageTipLabel == nil) {
        _savaImageTipLabel = [[UILabel alloc] init];
        _savaImageTipLabel.textColor = [UIColor whiteColor];
        _savaImageTipLabel.backgroundColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:0.90f];
        _savaImageTipLabel.textAlignment = NSTextAlignmentCenter;
        _savaImageTipLabel.font = [UIFont boldSystemFontOfSize:17];
    }
    return _savaImageTipLabel;
}

- (UIActivityIndicatorView *)indicatorView
{
    if (!_indicatorView) {
        _indicatorView = [[UIActivityIndicatorView alloc] init];
        _indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    }
    return _indicatorView;
}

- (void)setBrowserStyle:(XLPhotoBrowserStyle)browserStyle
{
    _browserStyle = browserStyle;
    [self setUpBrowserStyle];
}

- (void)setShowPageControl:(BOOL)showPageControl
{
    _showPageControl = showPageControl;
    _pageControl.hidden = !showPageControl;
}

- (void)setCurrentPageDotColor:(UIColor *)currentPageDotColor
{
    _currentPageDotColor = currentPageDotColor;
    if ([self.pageControl isKindOfClass:[TAPageControl class]]) {
        TAPageControl *pageControl = (TAPageControl *)_pageControl;
        pageControl.dotColor = currentPageDotColor;
    } else {
        UIPageControl *pageControl = (UIPageControl *)_pageControl;
        pageControl.currentPageIndicatorTintColor = currentPageDotColor;
    }
}

- (void)setPageDotColor:(UIColor *)pageDotColor
{
    _pageDotColor = pageDotColor;
    if ([self.pageDotColor isKindOfClass:[UIPageControl class]]) {
        UIPageControl *pageControl = (UIPageControl *)_pageControl;
        pageControl.pageIndicatorTintColor = pageDotColor;
    }
}

- (void)setCurrentPageDotImage:(UIImage *)currentPageDotImage
{
    _currentPageDotImage = currentPageDotImage;
    [self setCustomPageControlDotImage:currentPageDotImage isCurrentPageDot:YES];
}

- (void)setPageDotImage:(UIImage *)pageDotImage
{
    _pageDotImage = pageDotImage;
    [self setCustomPageControlDotImage:pageDotImage isCurrentPageDot:NO];
}

- (void)setCustomPageControlDotImage:(UIImage *)image isCurrentPageDot:(BOOL)isCurrentPageDot
{
    if (!image || !self.pageControl) return;
    if ([self.pageControl isKindOfClass:[TAPageControl class]]) {
        TAPageControl *pageControl = (TAPageControl *)_pageControl;
        if (isCurrentPageDot) {
            pageControl.currentDotImage = image;
        } else {
            pageControl.dotImage = image;
        }
    } else {
        UIPageControl *pageControl = (UIPageControl *)_pageControl;
        if (isCurrentPageDot) {
            [pageControl setValue:image forKey:@"_currentPageImage"];
        } else {
            [pageControl setValue:image forKey:@"_pageImage"];
        }
    }
}

- (void)setPageControlStyle:(XLPhotoBrowserPageControlStyle)pageControlStyle
{
    _pageControlStyle = pageControlStyle;
    [self setUpPageControl];
}

- (UIImage *)placeholderImage
{
    if (!_placeholderImage) {
        _placeholderImage = [UIImage xl_imageWithColor:[UIColor grayColor] size:CGSizeMake(100, 100)];
    }
    return _placeholderImage;
}

#pragma mark    -   initial

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self initial];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self initial];
    }
    return self;
}

- (void)initial
{
    self.backgroundColor = XLPhotoBrowserBackgrounColor;
    self.visibleZoomingScrollViews = [[NSMutableSet alloc] init];
    self.reusableZoomingScrollViews = [[NSMutableSet alloc] init];
    [self placeholderImage];
    
    _pageControlAliment = XLPhotoBrowserPageControlAlimentCenter;
    _showPageControl = YES;
    _pageControlDotSize = CGSizeMake(10, 10);
    _pageControlStyle = XLPhotoBrowserPageControlStyleAnimated;
    _hidesForSinglePage = YES;
    _currentPageDotColor = [UIColor whiteColor];
    _pageDotColor = [UIColor lightGrayColor];
    _browserStyle = XLPhotoBrowserStylePageControl;
    
    self.currentImageIndex = 0;
    self.imageCount = 0;
}

- (void)iniaialUI
{
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self setUpScrollView];
    [self setUpPageControl];
    [self setUpToolBars];
    [self setUpBrowserStyle];
    [self showFirstImage];
    [self updatePageControlIndex];
}

- (void)setUpScrollView
{
    CGRect rect = self.bounds;
    rect.size.width += XLPhotoBrowserImageViewMargin;
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.frame = rect;
    self.scrollView.xl_x = 0;
    self.scrollView.delegate = self;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.backgroundColor = [UIColor clearColor];
    self.scrollView.contentSize = CGSizeMake((self.scrollView.frame.size.width) * self.imageCount, 0);
    [self addSubview:self.scrollView];
    self.scrollView.contentOffset = CGPointMake(self.currentImageIndex * (self.scrollView.frame.size.width), 0);
    if (self.currentImageIndex == 0) { // 修复bug , 如果刚进入的时候是0,不会调用scrollViewDidScroll:方法,不会展示第一张图片
        [self showPhotos];
    }
}

/**
 *  设置pageControl
 */
- (void)setUpPageControl
{
    if (_pageControl) [_pageControl removeFromSuperview]; // 重新加载数据时调整
    
    if ((self.imageCount <= 1) && self.hidesForSinglePage) {
        return;
    }
    
    switch (self.pageControlStyle) {
        case XLPhotoBrowserPageControlStyleAnimated:
        {
            TAPageControl *pageControl = [[TAPageControl alloc] init];
            pageControl.numberOfPages = self.imageCount;
            pageControl.dotColor = self.currentPageDotColor;
            pageControl.currentPage = self.currentImageIndex;
            pageControl.userInteractionEnabled = NO;
            [self addSubview:pageControl];
            _pageControl = pageControl;
        }
            break;
        case XLPhotoBrowserPageControlStyleClassic:
        {
            UIPageControl *pageControl = [[UIPageControl alloc] init];
            _pageControl = pageControl;
            pageControl.numberOfPages = self.imageCount;
            pageControl.currentPageIndicatorTintColor = self.currentPageDotColor;
            pageControl.pageIndicatorTintColor = self.pageDotColor;
            pageControl.userInteractionEnabled = NO;
            [self addSubview:pageControl];
            pageControl.currentPage = self.currentImageIndex;
        }
            break;
        default:
            break;
    }
    
    // 重设pagecontroldot图片
    self.currentPageDotImage = self.currentPageDotImage;
    self.pageDotImage = self.pageDotImage;

    CGSize size = CGSizeZero;
    if ([self.pageControl isKindOfClass:[TAPageControl class]]) {
        TAPageControl *pageControl = (TAPageControl *)_pageControl;
        size = [pageControl sizeForNumberOfPages:self.imageCount];
    } else {
        size = CGSizeMake(self.imageCount * self.pageControlDotSize.width * 1.2, self.pageControlDotSize.height);
    }
    CGFloat x = (self.xl_width - size.width) * 0.5;
    if (self.pageControlAliment == XLPhotoBrowserPageControlAlimentRight) {
        x = self.xl_width - size.width - 10;
    }
    
    //iphoneX适配
    float safeBottom = 0;
    if (@available(iOS 11.0, *)) {
        safeBottom = self.safeAreaInsets.bottom;
    } else {
        // Fallback on earlier versions
    }
    
    CGFloat y = self.xl_height - size.height - 10 - safeBottom;
    if ([self.pageControl isKindOfClass:[TAPageControl class]]) {
        TAPageControl *pageControl = (TAPageControl *)_pageControl;
        [pageControl sizeToFit];
    }
    self.pageControl.frame = CGRectMake(x, y, size.width, size.height);
    self.pageControl.hidden = !self.showPageControl;
}

- (void)setUpToolBars
{
    UILabel *indexLabel = [[UILabel alloc] init];
    indexLabel.bounds = CGRectMake(0, 0, 80, 30);
    indexLabel.xl_centerX = self.xl_width * 0.5;
    indexLabel.xl_centerY = 35;
    indexLabel.textAlignment = NSTextAlignmentCenter;
    indexLabel.textColor = [UIColor whiteColor];
    indexLabel.font = [UIFont systemFontOfSize:18];
    indexLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    indexLabel.layer.cornerRadius = indexLabel.bounds.size.height * 0.5;
    indexLabel.clipsToBounds = YES;
    self.indexLabel = indexLabel;
    [self addSubview:indexLabel];
    
    UIButton *saveButton = [[UIButton alloc] init];
    [saveButton setTitle:@"保存图片" forState:UIControlStateNormal];
    saveButton.titleLabel.font = [UIFont systemFontOfSize:17];
    [saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    saveButton.backgroundColor = [UIColor colorWithHex:0x959595 alpha:0.5];
    saveButton.layer.cornerRadius = 22.5f;
    saveButton.layer.borderWidth = 1.0;
    saveButton.layer.borderColor = [UIColor whiteColor].CGColor;
    saveButton.clipsToBounds = YES;
    [saveButton addTarget:self action:@selector(saveImage) forControlEvents:UIControlEventTouchUpInside];
//    saveButton.frame = CGRectMake(self.bounds.size.width/2-45, self.bounds.size.height - 70, 90, 35);
//    saveButton.frame = CGRectMake(self.bounds.size.width/2-68, self.bounds.size.height - 70, 136, 45);
    
    //查看产品详情按钮
    UIButton *detailButton = [[UIButton alloc] init];
    [detailButton setTitle:@"查看产品详情" forState:UIControlStateNormal];
    detailButton.titleLabel.font = [UIFont systemFontOfSize:17];
    [detailButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    //    saveButton.backgroundColor = [UIColor colorWithRed:0.4f green:0.4f blue:0.4f alpha:0.5f];
    detailButton.layer.cornerRadius = 22.5f;
    detailButton.clipsToBounds = YES;
    [detailButton addTarget:self action:@selector(goodsDetailButtonAction) forControlEvents:UIControlEventTouchUpInside];
//    detailButton.frame = CGRectMake(self.bounds.size.width/2-136-35, self.bounds.size.height - 70, 180, 45);
    
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.startPoint = CGPointMake(0, 0);
    gradientLayer.endPoint = CGPointMake(1, 0);
    gradientLayer.frame = CGRectMake(0, 0, SCREEN_WIDTH - 136 - 50 , 45);
    gradientLayer.colors = [NSArray arrayWithObjects:(id)[UIColor colorWithHex:0xFDAB53].CGColor,(id)[UIColor colorWithHex:0xFD7953].CGColor, nil];
    [detailButton.layer insertSublayer:gradientLayer atIndex:0];
    
    self.saveButton = saveButton;
    self.detailButton = detailButton;
    [self addSubview:saveButton];
    [self addSubview:detailButton];
    [self isGoodsType];
}

//根据图片是不是产品，进行布局
- (void)isGoodsType{
    BOOL isGoods = NO;
    if (self.currentImageIndex < self.goodsUrlList.count) {
        XLPhotoUrlModel *model = self.goodsUrlList[self.currentImageIndex];
        if(model.goodsUrl.length > 0){
            isGoods = YES;
        }
    }
    
    //iphoneX适配
    float safeBottom = 0;
    if (@available(iOS 11.0, *)) {
        safeBottom = self.safeAreaInsets.bottom;
    } else {
        // Fallback on earlier versions
    }
    
    if (isGoods) {
        self.detailButton.hidden = NO;
        [self.saveButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(15);
            make.width.equalTo(@136.0);
            make.height.equalTo(@45.0);
            make.bottom.equalTo(self).offset(-safeBottom - 60);
        }];
        
    }else{
        self.detailButton.hidden = YES;
        [self.saveButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self);
            make.width.equalTo(@136.0);
            make.height.equalTo(@45.0);
            make.bottom.equalTo(self).offset(-safeBottom - 60);
        }];

    }
    
    [self.detailButton mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.saveButton.mas_right).offset(20);
        make.right.equalTo(self).offset(-15);
        make.height.equalTo(@45.0);
        make.bottom.equalTo(self).offset(-safeBottom - 60);
    }];
}

- (void)setUpBrowserStyle
{
    switch (self.browserStyle) {
        case XLPhotoBrowserStylePageControl:
        {
            self.pageControl.hidden = NO;
            self.indexLabel.hidden = YES;
            self.saveButton.hidden = YES;
        }
            break;
        case XLPhotoBrowserStyleIndexLabel:
        {
            self.indexLabel.hidden = NO;
            self.pageControl.hidden = YES;
            self.saveButton.hidden = YES;
        }
            break;
        case XLPhotoBrowserStyleSimple:
        {
            self.indexLabel.hidden = NO;
            self.saveButton.hidden = NO;
            self.pageControl.hidden = YES;
        }
            break;
            
        case XLPhotoBrowserStyleCustom:
        {
            self.indexLabel.hidden = YES;
            self.saveButton.hidden = NO;
            self.pageControl.hidden = NO;
        }
            break;
        default:
            break;
    }
}

- (void)dealloc
{
    [self.reusableZoomingScrollViews removeAllObjects];
    [self.visibleZoomingScrollViews removeAllObjects];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _savaImageTipLabel.layer.cornerRadius = 5;
    _savaImageTipLabel.clipsToBounds = YES;
    [_savaImageTipLabel sizeToFit];
    _savaImageTipLabel.xl_height = 30;
    _savaImageTipLabel.xl_width += 20;
    _savaImageTipLabel.center = self.center;

    _indicatorView.center = self.center;
}

#pragma mark    -   private method

- (UIWindow *)findTheMainWindow
{
    NSEnumerator *frontToBackWindows = [UIApplication.sharedApplication.windows reverseObjectEnumerator];
    for (UIWindow *window in frontToBackWindows) {
        BOOL windowOnMainScreen = window.screen == UIScreen.mainScreen;
        BOOL windowIsVisible = !window.hidden && window.alpha > 0 && window.opaque != NO;
        BOOL windowLevelSupported = (window.windowLevel >= UIWindowLevelNormal);
        BOOL windowSizeIsEqualToScreen = (window.xl_width == XLScreenW && window.xl_height == XLScreenH);
        if(windowOnMainScreen && windowIsVisible && windowLevelSupported && windowSizeIsEqualToScreen) {
            return window;
        }
    }
    
    XLPBLog(@"XLPhotoBrowser在当前工程未匹配到合适的window,请根据工程架构酌情调整此方法,匹配最优窗口");
    if (XLPhotoBrowserDebug) {
        NSAssert(false, @"XLPhotoBrowser在当前工程未匹配到window,请根据工程架构酌情调整findTheMainWindow方法,匹配最优窗口");
    }
    
    UIWindow * delegateWindow = [[[UIApplication sharedApplication] delegate] window];
    return delegateWindow;
}

#pragma mark    -   private -- 长按图片相关

- (void)longPress:(UILongPressGestureRecognizer *)longPress
{
    XLZoomingScrollView *currentZoomingScrollView = [self zoomingScrollViewAtIndex:self.currentImageIndex];
    if (longPress.state == UIGestureRecognizerStateBegan) {
        XLPBLog(@"UIGestureRecognizerStateBegan , currentZoomingScrollView.progress %f",currentZoomingScrollView.progress);
        if (currentZoomingScrollView.progress < 1.0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self longPress:longPress];
            });
            return;
        }

        if (self.actionOtherButtonTitles.count <= 0 && self.actionSheetDeleteButtonTitle.length <= 0 && self.actionSheetTitle.length <= 0) {
            return;
        }
        FSActionSheet *actionSheet = [[FSActionSheet alloc] initWithTitle:self.actionSheetTitle delegate:nil cancelButtonTitle:self.actionSheetCancelTitle highlightedButtonTitle:self.actionSheetDeleteButtonTitle otherButtonTitles:self.actionOtherButtonTitles];
        __weak typeof(self) weakSelf = self;
        // 展示并绑定选择回调
        [actionSheet showWithSelectedCompletion:^(NSInteger selectedIndex) {
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(photoBrowser:clickActionSheetIndex:currentImageIndex:)]) {
                [weakSelf.delegate photoBrowser:weakSelf clickActionSheetIndex:selectedIndex currentImageIndex:weakSelf.currentImageIndex];
            }
        }];
    }
}

/**
 具体的删除逻辑,请根据自己项目的实际情况,自行处理
 */
//- (void)delete
//{
//    if (self.currentImageIndex == 0) {
//        XLZoomingScrollView *currentZoomingScrollView = [self zoomingScrollViewAtIndex:self.currentImageIndex];
//        [self.reusableZoomingScrollViews addObject:currentZoomingScrollView];
//        [currentZoomingScrollView prepareForReuse];
//        [currentZoomingScrollView removeFromSuperview];
//        [self.visibleZoomingScrollViews minusSet:self.reusableZoomingScrollViews];
//    }
//    self.currentImageIndex --;
//    self.imageCount --;
//    if (self.currentImageIndex == -1 && self.imageCount == 0) {
//        [self dismiss];
//    } else {
//        self.currentImageIndex = (self.currentImageIndex == (-1) ? 0 : self.currentImageIndex);
//        if (self.currentImageIndex == 0) {
//            [self setUpImageForZoomingScrollViewAtIndex:0];
//            [self updatePageControlIndex];
//            [self showPhotos];
//        }
//        
//        self.scrollView.contentSize = CGSizeMake((self.scrollView.frame.size.width) * self.imageCount, 0);
//        self.scrollView.contentOffset = CGPointMake(self.currentImageIndex * (self.scrollView.frame.size.width), 0);
//    }
//    UIPageControl *pageControl = (UIPageControl *)self.pageControl;
//    pageControl.numberOfPages = self.imageCount;
//    [self updatePageControlIndex];
//}

#pragma mark -----查看产品详情------
- (void)goodsDetailButtonAction{
    if (self.currentImageIndex < self.goodsUrlList.count) {
        XLPhotoUrlModel *model = self.goodsUrlList[self.currentImageIndex];
        if(model.goodsUrl.length > 0){
            [[WYUtility dataUtil]routerWithName:model.goodsUrl withSoureController:self.showVC];
            [self dismiss];
        }
    }
}

#pragma mark    -   private -- save image

- (void)saveImage
{
    XLZoomingScrollView *zoomingScrollView = [self zoomingScrollViewAtIndex:self.currentImageIndex];
    if (zoomingScrollView.progress < 1.0) {
        self.savaImageTipLabel.text = XLPhotoBrowserLoadingImageText;
        [self addSubview:self.savaImageTipLabel];
        [self.savaImageTipLabel performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:1.0];
        return;
    }
    UIImageWriteToSavedPhotosAlbum(zoomingScrollView.currentImage, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
    [self addSubview:self.indicatorView];
    [self.indicatorView startAnimating];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo;
{
    [self.indicatorView removeFromSuperview];
    [self addSubview:self.savaImageTipLabel];
    if (error) {
        self.savaImageTipLabel.text = XLPhotoBrowserSaveImageFailText;
    } else {
        self.savaImageTipLabel.text = XLPhotoBrowserSaveImageSuccessText;
    }
    [self.savaImageTipLabel performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:1.0];
}

#pragma mark    -   private ---loadimage

- (void)showPhotos
{
    // 只有一张图片
    if (self.imageCount == 1) {
        [self setUpImageForZoomingScrollViewAtIndex:0];
        return;
    }
    
    CGRect visibleBounds = self.scrollView.bounds;
    NSInteger firstIndex = floor((CGRectGetMinX(visibleBounds)) / CGRectGetWidth(visibleBounds));
    NSInteger lastIndex  = floor((CGRectGetMaxX(visibleBounds)-1) / CGRectGetWidth(visibleBounds));
    
    if (firstIndex < 0) {
        firstIndex = 0;
    }
    if (firstIndex >= self.imageCount) {
        firstIndex = self.imageCount - 1;
    }
    if (lastIndex < 0){
        lastIndex = 0;
    }
    if (lastIndex >= self.imageCount) {
        lastIndex = self.imageCount - 1;
    }
    
    // 回收不再显示的zoomingScrollView
    NSInteger zoomingScrollViewIndex = 0;
    for (XLZoomingScrollView *zoomingScrollView in self.visibleZoomingScrollViews) {
        zoomingScrollViewIndex = zoomingScrollView.tag - 100;
        if (zoomingScrollViewIndex < firstIndex || zoomingScrollViewIndex > lastIndex) {
            [self.reusableZoomingScrollViews addObject:zoomingScrollView];
            [zoomingScrollView prepareForReuse];
            [zoomingScrollView removeFromSuperview];
        }
    }
    
    // _visiblePhotoViews 减去 _reusablePhotoViews中的元素
    [self.visibleZoomingScrollViews minusSet:self.reusableZoomingScrollViews];
    while (self.reusableZoomingScrollViews.count > 2) { // 循环利用池中最多保存两个可以用对象
        [self.reusableZoomingScrollViews removeObject:[self.reusableZoomingScrollViews anyObject]];
    }
    
    // 展示图片
    for (NSInteger index = firstIndex; index <= lastIndex; index++) {
        if (![self isShowingZoomingScrollViewAtIndex:index]) {
            [self setUpImageForZoomingScrollViewAtIndex:index];
        }
    }
}

/**
 *  判断指定的某个位置图片是否在显示
 */
- (BOOL)isShowingZoomingScrollViewAtIndex:(NSInteger)index
{
    for (XLZoomingScrollView* view in self.visibleZoomingScrollViews) {
        if ((view.tag - 100) == index) {
            return YES;
        }
    }
    return NO;
}

/**
 *  获取指定位置的XLZoomingScrollView , 三级查找,正在显示的池,回收池,创建新的并赋值
 *
 *  @param index 指定位置索引
 */
- (XLZoomingScrollView *)zoomingScrollViewAtIndex:(NSInteger)index
{
    for (XLZoomingScrollView* zoomingScrollView in self.visibleZoomingScrollViews) {
        if ((zoomingScrollView.tag - 100) == index) {
            return zoomingScrollView;
        }
    }
    XLZoomingScrollView* zoomingScrollView = [self dequeueReusableZoomingScrollView];
    [self setUpImageForZoomingScrollViewAtIndex:index];
    return zoomingScrollView;
}

/**
 *   加载指定位置的图片
 */
- (void)setUpImageForZoomingScrollViewAtIndex:(NSInteger)index
{
    XLZoomingScrollView *zoomingScrollView = [self dequeueReusableZoomingScrollView];
    zoomingScrollView.zoomingScrollViewdelegate = self;
    [zoomingScrollView addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)]];
    zoomingScrollView.tag = 100 + index;
    zoomingScrollView.frame = CGRectMake((self.scrollView.xl_width) * index, 0, self.xl_width, self.xl_height);
    self.currentImageIndex = index;
    if (zoomingScrollView.hasLoadedImage == NO) {
        if ([self highQualityImageURLForIndex:index]) { // 如果提供了高清大图数据源,就去加载
            [zoomingScrollView setShowHighQualityImageWithURL:[self highQualityImageURLForIndex:index] placeholderImage:[self placeholderImageForIndex:index]];
        } else if ([self assetForIndex:index]) {
            ALAsset *asset = [self assetForIndex:index];
            CGImageRef imageRef = asset.defaultRepresentation.fullScreenImage;
            [zoomingScrollView setShowImage:[UIImage imageWithCGImage:imageRef]];
            CGImageRelease(imageRef);
        } else {
            [zoomingScrollView setShowImage:[self placeholderImageForIndex:index]];
        }
        zoomingScrollView.hasLoadedImage = YES;
    }
    
    [self.visibleZoomingScrollViews addObject:zoomingScrollView];
    [self.scrollView addSubview:zoomingScrollView];
}

/**
 *  从缓存池中获取一个XLZoomingScrollView对象
 */
- (XLZoomingScrollView *)dequeueReusableZoomingScrollView
{
    XLZoomingScrollView *photoView = [self.reusableZoomingScrollViews anyObject];
    if (photoView) {
        [self.reusableZoomingScrollViews removeObject:photoView];
    } else {
        photoView = [[XLZoomingScrollView alloc] init];
    }
    return photoView;
}

/**
 *  获取指定位置的占位图片,和外界的数据源交互
 */
- (UIImage *)placeholderImageForIndex:(NSInteger)index
{
    if (self.datasource && [self.datasource respondsToSelector:@selector(photoBrowser:placeholderImageForIndex:)]) {
        return [self.datasource photoBrowser:self placeholderImageForIndex:index];
    } else if(self.images.count>index) {
        if ([self.images[index] isKindOfClass:[UIImage class]]) {
            return self.images[index];
        } else {
            return self.placeholderImage;
        }
    }
    return self.placeholderImage;
}

/**
 *  获取指定位置的高清大图URL,和外界的数据源交互
 */
- (NSURL *)highQualityImageURLForIndex:(NSInteger)index
{
    if (self.datasource && [self.datasource respondsToSelector:@selector(photoBrowser:highQualityImageURLForIndex:)]) {
        NSURL *url = [self.datasource photoBrowser:self highQualityImageURLForIndex:index];
        if (!url) {
            XLPBLog(@"高清大图URL数据 为空,请检查代码 , 图片索引:%zd",index);
            return nil;
        }
        if ([url isKindOfClass:[NSString class]]) {
            url = [NSURL URLWithString:(NSString *)url];
        }
        if (![url isKindOfClass:[NSURL class]]) {
            XLPBLog(@"高清大图URL数据有问题,不是NSString也不是NSURL , 错误数据:%@ , 图片索引:%zd",url,index);
        }
//        NSAssert([url isKindOfClass:[NSURL class]], @"高清大图URL数据有问题,不是NSString也不是NSURL");
        return url;
    } else if(self.images.count>index) {
        if ([self.images[index] isKindOfClass:[NSURL class]]) {
            return self.images[index];
        } else if ([self.images[index] isKindOfClass:[NSString class]]) {
            NSURL *url = [NSURL URLWithString:self.images[index]];
            return url;
        } else {
            return nil;
        }
    }
    return nil;
}

/**
 *  获取指定位置的 ALAsset,获取图片
 */
- (ALAsset *)assetForIndex:(NSInteger)index
{
    if (self.datasource && [self.datasource respondsToSelector:@selector(photoBrowser:assetForIndex:)]) {
        return [self.datasource photoBrowser:self assetForIndex:index];
    } else if (self.images.count > index) {
        if ([self.images[index] isKindOfClass:[ALAsset class]]) {
            return self.images[index];
        } else {
            return nil;
        }
    }
    return nil;
}

/**
 *  获取多图浏览,指定位置图片的UIImageView视图,用于做弹出放大动画和回缩动画
 */
- (UIView *)sourceImageViewForIndex:(NSInteger)index
{
    if (self.datasource && [self.datasource respondsToSelector:@selector(photoBrowser:sourceImageViewForIndex:)]) {
        return [self.datasource photoBrowser:self sourceImageViewForIndex:index];
    }
    return nil;
}

/**
 *  第一个展示的图片 , 点击图片,放大的动画就是从这里来的
 */
- (void)showFirstImage
{
    // 获取到用户点击的那个UIImageView对象,进行坐标转化
    CGRect startRect;
    if (self.sourceImageView) {
        
    } else if(self.datasource && [self.datasource respondsToSelector:@selector(photoBrowser:sourceImageViewForIndex:)]) {
        self.sourceImageView = [self.datasource photoBrowser:self sourceImageViewForIndex:self.currentImageIndex];
    } else {
        [UIView animateWithDuration:0.25 animations:^{
            self.alpha = 1.0;
        }];
        XLPBLog(@"需要提供源视图才能做弹出/退出图片浏览器的缩放动画");
        return;
    }
    startRect = [self.sourceImageView.superview convertRect:self.sourceImageView.frame toView:self];
    
    UIImageView *tempView = [[UIImageView alloc] init];
    tempView.image = [self placeholderImageForIndex:self.currentImageIndex];
    tempView.frame = startRect;
    [self addSubview:tempView];
    
    CGRect targetRect; // 目标frame
    UIImage *image = self.sourceImageView.image;
    
//#warning 完善image为空的闪退
    if (image == nil) {
        ///objc[1903]: Class PLBuildVersion is implemented in both /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/PrivateFrameworks/AssetsLibraryServices.framework/AssetsLibraryServices (0x1110ec998) and /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/PrivateFrameworks/PhotoLibraryServices.framework/PhotoLibraryServices (0x110e6b880). One of the two will be used. Which one is undefined.
        //(lldb)  po tempView.frame
//        (origin = (x = 15, y = 100), size = (width = 100, height = 100))
//        
//        (lldb) po targetRect
//        (origin = (x = 0, y = NaN), size = (width = 414, height = NaN))
        

        XLPBLog(@"需要提供源视图才能做弹出/退出图片浏览器的缩放动画");
        return;
    }
    CGFloat imageWidthHeightRatio = image.size.width / image.size.height;
    CGFloat width = XLScreenW;
    CGFloat height = XLScreenW / imageWidthHeightRatio;
    CGFloat x = 0;
    CGFloat y;
    if (height > XLScreenH) {
        y = 0;
    } else {
        y = (XLScreenH - height ) * 0.5;
    }
    targetRect = CGRectMake(x, y, width, height);
    self.scrollView.hidden = YES;
    self.alpha = 1.0;

    // 动画修改图片视图的frame , 居中同时放大
    [UIView animateWithDuration:XLPhotoBrowserShowImageAnimationDuration animations:^{
        tempView.frame = targetRect;
    } completion:^(BOOL finished) {
        [tempView removeFromSuperview];
        self.scrollView.hidden = NO;
    }];
}

#pragma mark    -   XLZoomingScrollViewDelegate

/**
 *  单击图片,退出浏览
 */
- (void)zoomingScrollView:(XLZoomingScrollView *)zoomingScrollView singleTapDetected:(UITapGestureRecognizer *)singleTap
{
    [UIView animateWithDuration:0.15 animations:^{
        self.savaImageTipLabel.alpha = 0.0;
        self.indicatorView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.savaImageTipLabel removeFromSuperview];
        [self.indicatorView removeFromSuperview];
    }];
    NSInteger currentIndex = zoomingScrollView.tag - 100;
    UIView *sourceView = [self sourceImageViewForIndex:currentIndex];
    if (sourceView == nil) {
        [self dismiss];
        return;
    }
    self.scrollView.hidden = YES;
    self.pageControl.hidden = YES;
    self.indexLabel.hidden = YES;
    self.saveButton.hidden = YES;

    CGRect targetTemp = [sourceView.superview convertRect:sourceView.frame toView:self];
    
    UIImageView *tempView = [[UIImageView alloc] init];
    tempView.contentMode = sourceView.contentMode;
    tempView.clipsToBounds = YES;
    tempView.image = zoomingScrollView.currentImage;
    tempView.frame = CGRectMake( - zoomingScrollView.contentOffset.x + zoomingScrollView.imageView.xl_x,  - zoomingScrollView.contentOffset.y + zoomingScrollView.imageView.xl_y, zoomingScrollView.imageView.xl_width, zoomingScrollView.imageView.xl_height);
    [self addSubview:tempView];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [UIView animateWithDuration:XLPhotoBrowserHideImageAnimationDuration animations:^{
        tempView.frame = targetTemp;
        self.backgroundColor = [UIColor clearColor];
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self showPhotos];
    NSInteger pageNum = floor((scrollView.contentOffset.x + scrollView.bounds.size.width * 0.5) / scrollView.bounds.size.width);
    self.currentImageIndex = pageNum == self.imageCount ? pageNum - 1 : pageNum;
    [self updatePageControlIndex];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSInteger pageNum = floor((scrollView.contentOffset.x + scrollView.bounds.size.width * 0.5) / scrollView.bounds.size.width);
    self.currentImageIndex = pageNum == self.imageCount ? pageNum - 1 : pageNum;
    [self updatePageControlIndex];
}

/**
 *  修改图片指示索引label
 */
- (void)updatePageControlIndex
{
    if (self.imageCount == 1 && self.hidesForSinglePage == YES) {
        self.indexLabel.hidden = YES;
        self.pageControl.hidden = YES;
        return;
    }
    UIPageControl *pageControl = (UIPageControl *)self.pageControl;
    pageControl.currentPage = self.currentImageIndex;
    NSString *title = [NSString stringWithFormat:@"%zd / %zd",self.currentImageIndex+1,self.imageCount];
    self.indexLabel.text = title;
    
    [self setUpBrowserStyle];
    
    [self isGoodsType];
}

#pragma mark    -   public method

/**
 *  快速创建并进入图片浏览器
 *
 *  @param currentImageIndex 开始展示的图片索引
 *  @param imageCount        图片数量
 *  @param datasource        数据源
 *
 */
+ (instancetype)showPhotoBrowserWithCurrentImageIndex:(NSInteger)currentImageIndex imageCount:(NSUInteger)imageCount datasource:(id<XLPhotoBrowserDatasource>)datasource
{
    XLPhotoBrowser *browser = [[XLPhotoBrowser alloc] init];
    browser.imageCount = imageCount;
    browser.currentImageIndex = currentImageIndex;
    browser.datasource = datasource;
    [browser show];
    return browser;
}

+ (instancetype)showPhotoAndProductBrowserWithCurrentImageIndex:(NSInteger)currentImageIndex imageCount:(NSUInteger)imageCount goodsUrlList:(NSArray<XLPhotoUrlModel *> *)goodsUrlList datasource:(id)datasource{
    XLPhotoBrowser *browser = [XLPhotoBrowser showPhotoBrowserWithCurrentImageIndex:currentImageIndex imageCount:imageCount datasource:datasource];
    browser.showVC = datasource;
    browser.goodsUrlList = goodsUrlList;
    [browser isGoodsType];
    return browser;
}

///**
// *  进入图片浏览器
// *
// *  @param index      从哪一张开始浏览,默认第一章
// *  @param imageCount 要浏览图片的总个数
// */
//- (void)showWithImageIndex:(NSInteger)index imageCount:(NSInteger)imageCount datasource:(id<XLPhotoBrowserDatasource>)datasource
//{
//    self.currentImageIndex = index;
//    self.imageCount = imageCount;
//    self.datasource = datasource;
//    [self show];
//}

- (void)show
{
    if (self.imageCount <= 0) {
        return;
    }
    if (self.currentImageIndex >= self.imageCount) {
        self.currentImageIndex = self.imageCount - 1;
    }
    if (self.currentImageIndex < 0) {
        self.currentImageIndex = 0;
    }
    UIWindow *window = [self findTheMainWindow];
    
    self.frame = window.bounds;
    self.alpha = 0.0;
    [window addSubview:self];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    [self iniaialUI];
}

/**
 *  退出
 */
- (void)dismiss
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [UIView animateWithDuration:XLPhotoBrowserHideImageAnimationDuration animations:^{
        self.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

/**
 *  初始化底部ActionSheet弹框数据
 *
 *  @param title                  ActionSheet的title
 *  @param delegate               XLPhotoBrowserDelegate
 *  @param cancelButtonTitle      取消按钮文字
 *  @param deleteButtonTitle      删除按钮文字
 *  @param otherButtonTitle      其他按钮数组
 */
- (void)setActionSheetWithTitle:(nullable NSString *)title delegate:(nullable id<XLPhotoBrowserDelegate>)delegate cancelButtonTitle:(nullable NSString *)cancelButtonTitle deleteButtonTitle:(nullable NSString *)deleteButtonTitle otherButtonTitles:(nullable NSString *)otherButtonTitle, ...
{
    NSMutableArray *otherButtonTitlesArray = [NSMutableArray array];
    NSString *buttonTitle;
    va_list argumentList;
    if (otherButtonTitle) {
        [otherButtonTitlesArray addObject:otherButtonTitle];
        va_start(argumentList, otherButtonTitle);
        while ((buttonTitle = va_arg(argumentList, id))) {
            [otherButtonTitlesArray addObject:buttonTitle];
        }
        va_end(argumentList);
    }
    self.actionOtherButtonTitles = otherButtonTitlesArray;
    self.actionSheetTitle = title;
    self.actionSheetCancelTitle = cancelButtonTitle;
    self.actionSheetDeleteButtonTitle = deleteButtonTitle;
    if (delegate) {
        self.delegate = delegate;
    }
}

/**
 *  保存当前展示的图片
 */
- (void)saveCurrentShowImage
{
    [self saveImage];
}

#pragma mark    -   public method  -->  XLPhotoBrowser简易使用方式:一行代码展示

/**
 一行代码展示(在某些使用场景,不需要做很复杂的操作,例如不需要长按弹出actionSheet,从而不需要实现数据源方法和代理方法,那么可以选择这个方法,直接传数据源数组进来,框架内部做处理)
 
 @param images            图片数据源数组(,内部可以是UIImage/NSURL网络图片地址/ALAsset)
 @param currentImageIndex 展示第几张
 
 @return XLPhotoBrowser实例对象
 */
+ (instancetype)showPhotoBrowserWithImages:(NSArray *)images currentImageIndex:(NSInteger)currentImageIndex
{
    if (images.count <=0 || images ==nil) {
        XLPBLog(@"一行代码展示图片浏览的方法,传入的数据源为空,不进入图片浏览,请检查传入数据源");
        return nil;
    }
    
    //检查数据源对象是否一直，如有需要自行打开
//    Class imageClass = [images.firstObject class];
//    for (id image in images) {
//        if (![image isKindOfClass:imageClass]) {
//            XLPBLog(@"传入的数据源数组内对象类型不一致,暂不支持,请检查");
//            return nil;
//        }
//    }
    
    XLPhotoBrowser *browser = [[XLPhotoBrowser alloc] init];
    browser.imageCount = images.count;
    browser.currentImageIndex = currentImageIndex;
    browser.images = images;
    [browser show];
    return browser;
}

@end

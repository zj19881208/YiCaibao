//
//  WYRefreshTableView.h
//  YiShangbao
//
//  Created by Lance on 16/12/6.
//  Copyright © 2016年 com.Microants. All rights reserved.
//

#import <UIKit/UIKit.h>

//刷新类型
typedef NS_ENUM(int,YHRefreshType){
    YHRefreshType_LoadNew = 1,  //下拉刷新
    YHRefreshType_LoadMore      //上拉加载
};

@class WYRefreshTableView;

@protocol YHRefreshTableViewDelegate <NSObject>

- (void)refreshTableViewLoadNew:(WYRefreshTableView*)view;
- (void)refreshTableViewLoadmore:(WYRefreshTableView*)view;

@end


@interface WYRefreshTableView : UITableView

@property (nonatomic,assign )   IBInspectable   BOOL enableLoadNew;
@property (nonatomic, assign)  IBInspectable   BOOL enableLoadMore;
@property (nonatomic, assign)   BOOL noData;            //无数据
@property (nonatomic, assign)   BOOL noMoreData;//上拉加载无更多数据

//开始加载
- (void)loadBegin:(YHRefreshType)type;
//结束加载
- (void)loadFinish:(YHRefreshType)type;

//无数据
- (void)setNoData:(BOOL)noData withText:(NSString *)tips;

- (void)setNoDataInAllSections:(BOOL)showNoDataInAllSections noData:(BOOL)noData withText:(NSString *)tips;
/**
 显示Loading
 与setLoadFailed互斥，不会同时显示
 且当table中有内容时也不显示
 */
- (void)showLoadingView:(BOOL)isShow;

/**
 显示加载失败
 与showLoadingView互斥，不会同时显示
 */
- (void)setLoadFailed:(BOOL)isFailed;
@end

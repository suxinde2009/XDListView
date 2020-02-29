//
//  XDTableView.h
//  XDTableView
//
//  Created by Su XinDe on 16/1/24.
//  Copyright © 2016年 com.su. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

extern NSInteger XDListViewCountDirty;
extern NSInteger XDListViewCacheSize;
extern NSString *const XDListViewSetNeedsReloadNotification;

@protocol XDListViewDataSource;
@protocol XDListViewDelegate;

@interface XDListView : UIView <UIScrollViewDelegate>

@property (nonatomic,assign) id<XDListViewDataSource> dataSource;
@property (nonatomic,assign) id<XDListViewDelegate> delegate;
@property (nonatomic,assign) BOOL stickToBottom;
@property (nonatomic,assign) BOOL clearCellCacheOnReload;
@property (nonatomic,assign) BOOL animateStickToBottom;

- (void)setNeedsReload;
- (void)reloadData;
- (id)dequeueReusableCellWithIdentifier:(NSString*) aString;

@end

@protocol XDListViewDelegate <NSObject>

@optional

- (void)listView:(XDListView*)aView
 willDisplayCell:(id)aCell
   forRowAtIndex:(NSUInteger)aRow;

- (CGFloat)listView:(XDListView *)aView
heightForRowAtIndex:(NSUInteger) aRow;

- (void)listView:(XDListView*)aView
didSelectRowAtIndex:(NSUInteger) aRow;

@end

@protocol XDListViewDataSource <NSObject>

- (id)listView:(XDListView*)aListView
cellForRowAtIndex:(NSUInteger)aRow;

- (NSUInteger)numberOfRowsInListView:(XDListView*)aView;

@end




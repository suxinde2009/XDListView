//
//  ViewController.h
//  XDListView
//
//  Created by Su XinDe on 16/1/24.
//  Copyright © 2016年 com.su. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XDListView.h"

@interface ViewController : UIViewController<XDListViewDataSource,XDListViewDelegate>{
    NSUInteger	mCount;
}
@property (nonatomic, retain) IBOutlet XDListView *listView;

@end


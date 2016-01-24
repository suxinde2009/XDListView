//
//  ViewController.m
//  XDListView
//
//  Created by Su XinDe on 16/1/24.
//  Copyright © 2016年 com.su. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor purpleColor];
    
    mCount = 100;
    self.listView = [[XDListView alloc] initWithFrame:self.view.bounds];
    self.listView.stickToBottom = YES;
    
    self.listView.dataSource = self;
    self.listView.delegate = self;
    
    [self.view addSubview:self.listView];
}
-(void) update{
    
    mCount++;
    
    [self.listView setNeedsReload];
}

#pragma mark - DataSource
- (id)listView:(XDListView *) aListView cellForRowAtIndex:(NSUInteger) aRow{
    
    UITableViewCell *cell;
    
    if( !(cell = [aListView dequeueReusableCellWithIdentifier:@"cell"]) ){
        NSLog(@"Created cell");
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:@"cell"];
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"Cell %d",aRow];
    
    if( aRow % 2 ){
        [[cell textLabel] setBackgroundColor:[UIColor greenColor]];
    }
    else{
        [[cell textLabel] setBackgroundColor:[UIColor blueColor]];
    }
    
    return cell;
}

- (NSUInteger) numberOfRowsInListView:(XDListView*) aView{
    return mCount;
}

-(CGFloat) listView:(XDListView *) aView heightForRowAtIndex:(NSUInteger) aRow{
    
    if( aRow % 2 ){
        return 150.0f;
    }
    else{
        return 50.0f;
    }
    
}

-(void) listView:(XDListView*) aView didSelectRowAtIndex:(NSUInteger) aRow;
{
    NSLog(@"%s: %ld", __func__, aRow);
}

@end

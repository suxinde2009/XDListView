//
//  XDTableView.m
//  XDTableView
//
//  Created by Su XinDe on 16/1/24.
//  Copyright © 2016年 com.su. All rights reserved.
//

#import "XDListView.h"

NSInteger XDListViewCountDirty = -1;
NSInteger XDListViewCacheSize = 15;
NSString *const XDListViewSetNeedsReloadNotification = @"__kListViewSetNeedsReloadNotification";

@interface XDListView()

- (UIScrollView*)scrollView;
- (void) setupView;

- (void) registerForNotifications;
- (void) unregisterForNotifications;

- (CGRect) visibleRect;

//Caching
- (void) clearCaches;

- (NSCache*) cellCache;
- (NSMutableArray*) cellCacheForIdentifier:(NSString*) aName;

- (CGRect) cachedRectForRowAtIndex:(NSUInteger) aRow;
- (void) cacheRect:(CGRect)aRect forRowAtIndex:(NSUInteger)aRow;

- (NSMutableArray*) rectCache;

//Delegate
- (CGFloat) heightForRowAtIndex:(NSUInteger) aRow;
- (void) didSelectRowAtIndex:(NSUInteger) aRow;
- (void) willDisplayCell:(id) aCell forRowAtIndex:(NSUInteger) aRow;

//Datasource
- (id) cellForRowAtIndex:(NSUInteger) aRow;
- (NSInteger) numberOfRowsInList;

@end

@implementation XDListView

@synthesize delegate = mDelegate;
@synthesize dataSource = mDataSource;
@synthesize stickToBottom = mStickToBottom;
@synthesize clearCellCacheOnReload = mClearCellCacheOnReload;
@synthesize animateStickToBottom = mAnimateStickToBottom;

#pragma mark - Object Lifecycle
- (id) initWithFrame:(CGRect)frame{
    
    if( !(self = [super initWithFrame:frame]) ) return nil;
    
    [self setupView];
    
    return self;
}

- (void) dealloc{

    [self unregisterForNotifications];
    
    mScrollView = nil;
    mCellsCache = nil;
    mRectCache = nil;
    
    mDataSource = nil;
    mDelegate = nil;
    
}

- (void) awakeFromNib{
    
    [super awakeFromNib];
    
    [self setupView];
}

/**
 *	Create the sub view heirarchy
 */
- (void) setupView{
    //Add the scroll view
    [self addSubview:[self scrollView]];
    
    mStickToBottom = NO;
    
    mClearCellCacheOnReload = NO;
    
    mAnimateStickToBottom = YES;
    
    mCacheRowCount = 0;
    
    [self registerForNotifications];
    
}

#pragma mark - KVO & Notifications
- (void) registerForNotifications{
    
    [self addObserver:self
           forKeyPath:@"dataSource"
              options:NSKeyValueObservingOptionNew
              context:NULL
     ];
    
    [self addObserver:self
           forKeyPath:@"bounds"
              options:NSKeyValueObservingOptionNew
              context:NULL
     ];
    
    [self addObserver:self
           forKeyPath:@"frame"
              options:NSKeyValueObservingOptionNew
              context:NULL
     ];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadData)
                                                 name:XDListViewSetNeedsReloadNotification
                                               object:self
     ];
    
    //Touch recognizers
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self
                                                                       action:@selector(didTouch:)]];
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if( [keyPath isEqualToString:@"dataSource"] ){
        [self setNeedsReload];
    }
    else if( [keyPath isEqualToString:@"bounds"]){
        [[self scrollView] setBounds:[[change objectForKey:NSKeyValueChangeNewKey] CGRectValue]];
    }
    else if( [keyPath isEqualToString:@"frame"]){
        [[self scrollView] setFrame:[[change objectForKey:NSKeyValueChangeNewKey] CGRectValue]];
        
        [[self scrollView] setNeedsLayout];
    }
    
}

- (void)unregisterForNotifications {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self removeObserver:self
              forKeyPath:@"dataSource"
     ];
    
    [self removeObserver:self
              forKeyPath:@"bounds"
     ];
    
    [self removeObserver:self
              forKeyPath:@"frame"
     ];
}

#pragma mark - Private accessors
/**
 *	Internal view to get the scroll view
 */
- (UIScrollView*) scrollView{
    
    if( !mScrollView ){
        mScrollView = [[UIScrollView alloc] initWithFrame:[self frame]];
        
        [mScrollView setAutoresizingMask:[self autoresizingMask]];
        
        [mScrollView setAlwaysBounceVertical:YES];
        
        [mScrollView setDelegate:self];
        
//        if( DEBUGMODE ){
//            [mScrollView setBackgroundColor:[UIColor purpleColor]];
//        }
    }
    
    return mScrollView;
}

#pragma mark - Reload management
/**
 *	Queue requests to have the view reloaded
 *
 */
- (void) setNeedsReload{
    
    NSNotification *notification;
    notification = [NSNotification notificationWithName:XDListViewSetNeedsReloadNotification
                                                 object:self];
    
    [[NSNotificationQueue defaultQueue] enqueueNotification:notification
                                               postingStyle:NSPostASAP];
    
}

/**
 *	Reload the data immediately
 *
 */
- (void) reloadData{
    
    CGSize		contentSize;
    CGFloat		cellHeight;
    CGFloat		yOffset;
    CGRect		cellFrame;
    
    NSLog(@"Reloading");
    
    [self clearCaches];
    
    //Get the context size
    contentSize = [[self scrollView] contentSize];
    
    //Reset the height
    contentSize.height = 0.0f;
    contentSize.width  = [self bounds].size.width;
    
    yOffset = 0.0f;
    
    //Calculate the total heights && and get the cell rects
    for( int i=0; i < [self numberOfRowsInList]; i++ ){
        
        cellHeight = [self heightForRowAtIndex:i];
        
        cellFrame = CGRectMake(0.0f,yOffset,[self bounds].size.width, cellHeight);
        
        [self cacheRect:cellFrame
          forRowAtIndex:i
         ];
        
        yOffset += cellHeight;
        
        contentSize.height += cellHeight;
    }
    
    [[self scrollView] setContentSize:contentSize];
    
    //Stick to the bottom
    if( [self stickToBottom] ){
        
        if( contentSize.height > CGRectGetHeight([self bounds]) ){
            
            [[self scrollView] setContentOffset:CGPointMake(0.0f, contentSize.height-[[self scrollView] bounds].size.height)
                                       animated:[self animateStickToBottom]
             ];
        }
        else{
            
            //For some reason if we set the offset to have y of 0.0f, the first cell appears off the screen
            [[self scrollView] setContentOffset:CGPointMake(0.0f, -0.1f)];
            
        }
        
    }
    
    //NSLog(@"Set content size to %@",NSStringFromCGSize(contentSize));
    
}

/**
 *
 *
 */
- (void)loadCellsForRect:(CGRect) visibleRect{
    
    id			cell;
    CGRect		cellRect;
    CGFloat		viewWidth = CGRectGetWidth([self bounds]);
    
    //Loop over the cells and see if we have any overlap
    for( int i=0; i < [self numberOfRowsInList]; i++ ){
        
        
        cellRect = [self cachedRectForRowAtIndex:i];
        
        //NSLog(@"Comparing %@ && %@", NSStringFromCGRect(cellRect), NSStringFromCGRect(visibleRect));
        
        if( CGRectIntersectsRect(cellRect, visibleRect) ){
            //Load cell
            //NSLog(@"Loading cell At index %d",i);
            
            //Adjust the cell width to the width of the view
            
            cell = [self cellForRowAtIndex:i];
            
            //NSLog(@"Frame %@",NSStringFromCGRect(cellRect));
            
            cellRect.size.width = viewWidth;
            
            [cell setFrame:cellRect];
            
            [self willDisplayCell:cell
                    forRowAtIndex:i
             ];
            
            [[self scrollView] addSubview:cell];
        };
    }
}

/**
 *	Create the current visible rect
 *	Move this to a category on UIScrollView
 */
- (CGRect) visibleRect{
    
    CGRect	retVal;
    CGSize	size;
    CGPoint origin;
    
    size = [[self scrollView] bounds].size;
    origin = [[self scrollView] contentOffset];
    
    retVal = CGRectMake(origin.x, origin.y, size.width, size.height);
    
    return retVal;
}

#pragma mark - Caching
/**
 *	Remove all caches
 */
- (void) clearCaches{
    
    mCacheRowCount = XDListViewCountDirty;
    
    [[self rectCache] removeAllObjects];
    
    //Should we clear the cell cache on reload
    if( [self clearCellCacheOnReload] ){
        [[self cellCache] removeAllObjects];
    }
    
}

/**
 *	Get a rect from the cache
 */
- (CGRect) cachedRectForRowAtIndex:(NSUInteger) aRow{
    return [[[self rectCache] objectAtIndex:aRow] CGRectValue];
}

/**
 *	Cache a rect
 */
- (void) cacheRect:(CGRect)aRect forRowAtIndex:(NSUInteger)aRow{
    
    [[self rectCache] insertObject:[NSValue valueWithCGRect:aRect]
                           atIndex:aRow
     ];
    
}

/**
 *	A cache for all the rects in the view
 *
 */
- (NSMutableArray*) rectCache{
    
    if( !mRectCache ){
        mRectCache = [[NSMutableArray alloc] initWithCapacity:[self numberOfRowsInList]];
    }
    
    return mRectCache;
}

/**
 *	Create the cell cache
 */
- (NSCache*) cellCache{
    
    if( !mCellsCache ){
        mCellsCache = [[NSCache alloc] init];
        
        [mCellsCache setName:@"com.FRListView.cellCache"];
    }
    return mCellsCache;
}

/**
 *	Create cell cache's for a given id
 *	@param aName The name of the cache
 *
 *	@return aCache
 */
- (NSMutableArray*) cellCacheForIdentifier:(NSString*) aName{
    
    NSMutableArray *cache = nil;
    
    if( !(cache = (NSMutableArray*)[[self cellCache] objectForKey:aName]) ){
        
        cache = [[NSMutableArray alloc] initWithCapacity:XDListViewCacheSize];
        
        [[self cellCache] setObject:cache
                             forKey:aName];
    }
    
    return cache;
}

#pragma mark - Cell reuse
/**
 *	Get the cell from the internal cell cache
 *	@param the id
 */
- (id)dequeueReusableCellWithIdentifier:(NSString*) aString{
    
    id cell = nil;
    NSMutableArray *cache = nil;
    
    if( aString ){
        cache = [self cellCacheForIdentifier:aString];

        //If the cache full
        if( [cache count] >= XDListViewCacheSize ){
            
            //NSLog(@"Cache Hit!");
            //Dequeue a cell
            cell = [cache xd_list_dequeue];
            
            //Prepare it for reuse
            [cell prepareForReuse];
        }
    }
    
    //return it
    return cell;
}

#pragma mark - Touch handling
/**
 *	Handle touches on the view, and call didSelectRowAtIndex where needed.
 *	@depreciated USE touchesShouldBegin:withEvent:inContentView: instead
 */
- (void) didTouch:(UIGestureRecognizer*) aGesture{
    
    CGPoint				touch;
    UIView				*view;
    NSUInteger			index;
    
    touch = [aGesture locationInView:[self scrollView]];
    
    if( (view = [[self scrollView] hitTest:touch withEvent:nil]) ){
        
        if( [view isKindOfClass:[NSClassFromString(@"UITableViewCellContentView") class]] ){
            
            index  = [[self rectCache] indexOfObject:[NSValue valueWithCGRect:[[view superview] frame]]];
            
            //NSLog(@"Touched Cell %d",index);
            
            [self didSelectRowAtIndex:index];
        }
        else if( [view isKindOfClass:[UITableViewCell class]] ){
            
            index  = [[self rectCache] indexOfObject:[NSValue valueWithCGRect:[view frame]]];
            
            [self didSelectRowAtIndex:index];
        }
        
    }
    
}

#pragma mark - FRListViewDelegate wrapper methods
/**
 *
 */
- (void) willDisplayCell:(id) aCell forRowAtIndex:(NSUInteger) aRow{
    
    if( [[self delegate] respondsToSelector:@selector(listView:willDisplayCell:forRowAtIndex:)]){
        
        [[self delegate] listView:self
                  willDisplayCell:aCell
                    forRowAtIndex:aRow
         ];
    }
}

/**
 *
 */
- (void) didSelectRowAtIndex:(NSUInteger) aRow{
    
    if( [[self delegate] respondsToSelector:@selector(listView:didSelectRowAtIndex:)] ){
        [[self delegate] listView:self
              didSelectRowAtIndex:aRow
         ];
    }
}

/**
 *
 */
- (CGFloat) heightForRowAtIndex:(NSUInteger) aRow{
    
    if( [[self delegate] respondsToSelector:@selector(listView:heightForRowAtIndex:)] ){
        return [[self delegate] listView:self
                     heightForRowAtIndex:aRow
                ];
    }
    
    return 44.0f;
}

#pragma mark - FRListViewDataSource wrapper methods
/**
 *	Get the total numbers of the cells
 */
- (NSInteger) numberOfRowsInList{
    
    if( [[self dataSource] respondsToSelector:@selector(numberOfRowsInListView:)] && mCacheRowCount == XDListViewCountDirty ){
        mCacheRowCount =  [[self dataSource] numberOfRowsInListView:self];
    }
    
    return mCacheRowCount;
}

/**
 *	Internal Cell for row at index path method
 *	@param aPath NSIndexPath of the cell 
 *	
 *	@return a Newly configured cell
 */
- (id) cellForRowAtIndex:(NSUInteger) aRow{
    
    UITableViewCell	*cell = nil;
    NSString *cellIdentifier = nil;
    
    //Create a cache for the cell
    if( [[self dataSource] respondsToSelector:@selector(listView:cellForRowAtIndex:)] ){
        
        cell = [[self dataSource] listView:self
                         cellForRowAtIndex:aRow
                ];
        
        //Add the cell to the cache
        if( (cellIdentifier = [cell reuseIdentifier]) ){
            [[self cellCacheForIdentifier:cellIdentifier] xd_list_enqueue:cell];
        }
        
        //Ensure the cell responds correctly to resize events
        [cell setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    }
    
    return cell;
}

#pragma mark - UIScrollViewDelegate
/**
 *	Reload the cells as we scroll
 */
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    [self loadCellsForRect:[self visibleRect]];
    
}

@end

@implementation NSMutableArray (XDListViewDequeueReusable)

/**
 *	Enqueue an an object
 *	@param aObject an object to be added to the end of the queue
 */
- (void)xd_list_enqueue:(id)aObject {
    [self addObject:aObject];
}

/**
 *	Return the object at the head of the queue
 *
 *	@return aObject the object at the top of the enqueue
 */
- (id)xd_list_dequeue {
    
    id element = nil;
    if( [self count] > 0 ){
        element = [self objectAtIndex:0];
        [self removeObjectAtIndex:0];
    }
    return element;
}


@end
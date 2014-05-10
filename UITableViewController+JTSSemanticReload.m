//
//  UITableViewController+JTSSemanticReload.m
//
//
//  Created by Jared Sinclair on 3/9/14.
//  Copyright (c) 2014 Nice Boy LLC. All rights reserved.
//

#import "UITableViewController+JTSSemanticReload.h"

#if RELEASE == 0
#define JTSSemanticReloadLog(format, ...) NSLog((@"%s [Line %d]\n" format @"\n\n"), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define JTSSemanticReloadLog(...)
#endif

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@interface JTSSemanticReloadItem : NSObject

@property (strong, nonatomic) id dataSourceItem;
@property (assign, nonatomic) CGFloat relativeYOffset;
@property (copy, nonatomic) NSIndexPath *originalIndexPath;

@end

#define ENABLE_LOGGING 0

@implementation JTSSemanticReloadItem

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@> %p originalIndexPath: %@ relativeYOffset: %g dataSourceItem: %@ ",
            NSStringFromClass(self.class),
            self,
            self.originalIndexPath,
            self.relativeYOffset,
            self.dataSourceItem];
}

@end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@implementation UITableViewController (JTSSemanticReload)

- (void)JTS_logThis:(NSString *)statement {
#if ENABLE_LOGGING == 1
    JTSSemanticReloadLog(@"%@", statement);
#endif
}

- (void)JTS_reloadDataPreservingSemanticContentOffset:(JTSSemanticReloadItemForIndexPath)itemForPathBlock
                                     pathForItemBlock:(JTSSemanticReloadIndexPathForItem)pathForItemBlock {
    
    NSArray *visibleCells = [self.tableView visibleCells];
    
    if (visibleCells.count == 0) {
        [self JTS_logThis:@"No visible cells. Will reloadData only."];
        [self.tableView reloadData];
    }
    else {
        UIEdgeInsets contentInsets = self.tableView.contentInset;
        CGFloat contentInsetTop = contentInsets.top;
        CGFloat priorContentOffset = self.tableView.contentOffset.y;
        NSMutableArray *visibleItems = [[NSMutableArray alloc] init];
        
        for (UITableViewCell *cell in visibleCells) {
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
            id dataSourceItem = itemForPathBlock(indexPath, cell);
            if (dataSourceItem) {
                JTSSemanticReloadItem *reloadItem = [[JTSSemanticReloadItem alloc] init];
                [reloadItem setDataSourceItem:dataSourceItem];
                [reloadItem setRelativeYOffset:priorContentOffset - cell.frame.origin.y];
                [reloadItem setOriginalIndexPath:indexPath];
                [visibleItems addObject:reloadItem];
            }
        }
        
        [self.tableView reloadData];
        
        if (visibleItems.count == 0) {
            [self JTS_logThis:@"No data source items found for visible cells. Will reloadData only."];
        }
        else {
            [self JTS_logThis:[NSString stringWithFormat:@"Found %lu data source items prior to reloading data: \n%@", (unsigned long)visibleItems.count, visibleItems]];
        
            NSIndexPath *targetIndexPath = nil;
            JTSSemanticReloadItem *targetReloadItem = nil;
            
            for (JTSSemanticReloadItem *reloadItem in visibleItems) {
                NSIndexPath *indexPath = pathForItemBlock(reloadItem.dataSourceItem);
                if (indexPath) {
                    targetIndexPath = indexPath;
                    targetReloadItem = reloadItem;
                    break;
                }
            }
            
            if (targetIndexPath == nil) {
                [self JTS_logThis:@"Unable to find an item whose offset can still be preserved. Will reloadData only."];
            } else {
                [self JTS_logThis:[NSString stringWithFormat:@"Will preserve offset for item at new indexPath row: %lu section: %lu \nitem: %@", (long)targetIndexPath.row, (long)targetIndexPath.section, targetReloadItem]];
                
                [self.tableView scrollToRowAtIndexPath:targetIndexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
                
                CGPoint newOffset = self.tableView.contentOffset;
                newOffset.y += targetReloadItem.relativeYOffset;
                newOffset.y += contentInsetTop;
                
                if (targetIndexPath.section == 0 && targetIndexPath.row == 0) {
                    // Fix UIKit scrollToRowAtIndexPath:atScrollPosition:animated: inconsistency when
                    // applied to the first cell.
                    UITableViewCell *targetCell = [self.tableView cellForRowAtIndexPath:targetIndexPath];
                    newOffset.y += targetCell.frame.origin.y;
                }
                
                // Fix possible overscrolling at the top or bottom.
                
                CGFloat contentHeight = self.tableView.contentSize.height;
                CGFloat visibleHeight = self.tableView.bounds.size.height;

                if (visibleHeight >= contentHeight) {
                    newOffset.y = 0 - contentInsetTop;
                }
                else if (newOffset.y < 0 - contentInsetTop) {
                    newOffset.y = 0 - contentInsetTop;
                }
                else if (newOffset.y + visibleHeight > contentHeight + contentInsets.bottom) {
                    newOffset.y = contentHeight + contentInsets.bottom - visibleHeight;
                }
                
                [self.tableView setContentOffset:newOffset];
                
            }
        }
    }
}

@end

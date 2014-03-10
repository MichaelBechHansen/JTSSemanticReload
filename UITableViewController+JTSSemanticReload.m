//
//  UITableViewController+JTSSemanticReload.m
//
//
//  Created by Jared Sinclair on 3/9/14.
//  Copyright (c) 2014 Nice Boy LLC. All rights reserved.
//

#import "UITableViewController+JTSSemanticReload.h"

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@interface JTSSemanticReloadItem : NSObject

@property (strong, nonatomic) id dataSourceItem;
@property (assign, nonatomic) CGFloat relativeYOffset;

@end

@implementation JTSSemanticReloadItem

@end

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@implementation UITableViewController (JTSSemanticReload)

- (void)JTS_reloadDataPreservingSemanticContentOffset:(JTSSemanticReloadItemForIndexPath)itemForPathBlock
                                     pathForItemBlock:(JTSSemanticReloadIndexPathForItem)pathForItemBlock {
    
    NSArray *visibleCells = [self.tableView visibleCells];
    
    if (visibleCells.count == 0) {
        [self.tableView reloadData];
    }
    else {
        CGFloat contentInsetTop = self.tableView.contentInset.top;
        CGFloat priorContentOffset = self.tableView.contentOffset.y;
        NSMutableArray *visibleItems = [[NSMutableArray alloc] init];
        
        for (UITableViewCell *cell in visibleCells) {
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
            id dataSourceItem = itemForPathBlock(indexPath);
            if (dataSourceItem) {
                JTSSemanticReloadItem *reloadItem = [[JTSSemanticReloadItem alloc] init];
                [reloadItem setDataSourceItem:dataSourceItem];
                [reloadItem setRelativeYOffset:priorContentOffset - cell.frame.origin.y];
                [visibleItems addObject:reloadItem];
            }
        }
        
        [self.tableView reloadData];
        
        if (visibleItems.count) {
            
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
            
            if (targetIndexPath) {
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
                
                [self.tableView setContentOffset:newOffset];
                
            }
        }
    }
}

@end

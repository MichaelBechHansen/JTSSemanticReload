//
//  UITableViewController+JTSSemanticReload.h
//
//
//  Created by Jared Sinclair on 3/9/14.
//  Copyright (c) 2014 Nice Boy LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef id (^JTSSemanticReloadItemForIndexPath)(NSIndexPath *indexPathPriorToReload, UITableViewCell *cellPriorToReload);
typedef NSIndexPath * (^JTSSemanticReloadIndexPathForItem)(id dataSourceItem);

@interface UITableViewController (JTSSemanticReload)

- (void)JTS_reloadDataPreservingSemanticContentOffset:(JTSSemanticReloadItemForIndexPath)itemForPathBlock
                                     pathForItemBlock:(JTSSemanticReloadIndexPathForItem)pathForItemBlock;
@end

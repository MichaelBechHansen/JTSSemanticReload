JTSSemanticReload
=================

A category method on UITableViewController for calling "reloadData" while preserving semantic content offset.

## Why You’d Want This

Many times you **don’t** want to use an animated table view update, but you **do** want to insert new rows above the current content offset. The problem with using `reloadData` is that it loses the user’s current place in the content. In these situations, use the JTSSemanticReload category instead. 

## Usage

Anywhere you would use:

```objc
- (void)reloadData;
```

replace it with a call to:

```objc
- (void)JTS_reloadDataPreservingSemanticContentOffset:(JTSSemanticReloadItemForIndexPath)itemForPathBlock
                                     pathForItemBlock:(JTSSemanticReloadIndexPathForItem)pathForItemBlock;
```

Here's an example implementation:

```objc
- (void)someDataModelDidUpdate:(id)model andStuff:(id)stuff {

  [self JTS_reloadDataPreservingSemanticContentOffset:^id(NSIndexPath *indexPathPriorToReload, UITableViewCell *cellPriorToReload) {
    return [self.tweetController tweetForIndexPath:indexPath];
  } pathForItemBlock:^NSIndexPath *(id dataSourceItem) {
    return [self.tweetController indexPathForTweet:(SomeTweet *)dataSourceItem];
  }];
}
```

The method accepts two block arguments. The two blocks are called synchronously and may be called multiple times. One of them takes an `NSIndexPath` and returns a data source item, and the other takes a data source item and returns an `NSIndexPath`. The data source item can be any object you wish. It's up to your application to be able to derive an index path from the data source item and vice versa. For example, if you were writing a Twitter client, the data source item would probably be a tweet.

This method is safe to use with table views that have non-zero content insets, header views, and footer views.

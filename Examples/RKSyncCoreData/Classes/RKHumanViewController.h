//
//  RKHumanViewController.h
//  RKSyncCoreData
//
//  Created by Juan C. Mendez on 3/15/12.
//  Copyright RestKit 2012. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RestKit/RestKit.h>

@interface RKHumanViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, RKObjectLoaderDelegate> {
	UITableView* _tableView;
	NSArray* _humans;
}
- (void)loadObjectsFromDataStore;
@end

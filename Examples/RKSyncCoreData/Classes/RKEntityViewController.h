//
//  RKEntityViewController.h
//  RKSyncCoreData
//
//  Created by Juan C. Mendez on 3/15/12.
//  Copyright RestKit 2012. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RestKit/RestKit.h>

@interface RKEntityViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, RKSyncManagerDelegate> {
	UITableView* _tableView;
	NSArray* _objects;
}
- (NSEntityDescription *) entityToShow;
- (void) populateCell:(UITableViewCell *) cell withObject:(NSManagedObject *) object;

- (void)loadObjectsFromDataStore;
@end

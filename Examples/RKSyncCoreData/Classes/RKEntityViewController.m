//
//  RKEntityViewController.m
//  RKSyncCoreData
//
//  Created by Juan C. Mendez on 3/15/12.
//  Copyright RestKit 2012. All rights reserved.
//
#import "RKEntityViewController.h"
#import "RKHuman.h"

/**
 * Abstract class to show a CoreData entity in this boilerplate
 */
@implementation RKEntityViewController

- (void)loadView {
    [super loadView];
	
	// Setup View and Table View	
	self.title = [[self entityToShow] managedObjectClassName];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackTranslucent;
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadButtonWasPressed:)] autorelease];
  
	_tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 480-64) style:UITableViewStylePlain];
	_tableView.dataSource = self;
	_tableView.delegate = self;	
  _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
  _tableView.separatorColor = [UIColor colorWithHue:0.7f saturation:1.0f brightness:0.2f alpha:0.4f];
	_tableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_tableView];
	
  [_tableView becomeFirstResponder];
	// Load statuses from core data
	[self loadObjectsFromDataStore];
}

- (void)viewWillAppear:(BOOL)animated {
  [_tableView reloadData];
  [super viewWillAppear: animated];
}

- (void)dealloc {
	[_tableView release];
	[_objects release];
    [super dealloc];
}

- (NSEntityDescription *) entityToShow {
  NSAssert(NO,@"Implement this method... this class is abstract");  
  return nil;
}

- (void) populateCell:(UITableViewCell *) cell withObject:(NSManagedObject *) object {
  NSAssert(NO,@"Implement this method... this class is abstract");  
}

- (void)loadObjectsFromDataStore {
  NSAssert(NO,@"Implement this method... this class is abstract");
}

- (void)loadData {
  // The following call to the syncManager will replace a regular loadObjects call like
  //     [objectManager loadObjectsAtResourcePath:@"/humans" delegate:self];
  RKManagedObjectSyncManager *syncManager = [RKManagedObjectSyncManager sharedSyncManager];
  [syncManager syncObjectsForEntity:[self entityToShow] delegate:self];
}

- (void)reloadButtonWasPressed:(id)sender {
	// Load the object model via RestKit
	[self loadData];
}

#pragma mark RKSyncManagerDelegate methods

- (void) syncManagerFinishedSync:(RKManagedObjectSyncManager *)manager {
	[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"LastUpdatedAt"];
	[[NSUserDefaults standardUserDefaults] synchronize];  
  NSLog(@"Synced successfully");
  [self loadObjectsFromDataStore];
  [_tableView reloadData];

}

// #pragma mark RKObjectLoaderDelegate methods
//- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray*)objects {
//	[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"LastUpdatedAt"];
//	[[NSUserDefaults standardUserDefaults] synchronize];
//	NSLog(@"Loaded humans: %@", objects);
//	[self loadObjectsFromDataStore];
//	[_tableView reloadData];
//}
//
//- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error {
//	UIAlertView* alert = [[[UIAlertView alloc] initWithTitle:@"Error" 
//                                                     message:[error localizedDescription] 
//                                                    delegate:nil 
//                                           cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
//	[alert show];
//	NSLog(@"Hit error: %@", error);
//}

#pragma mark UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
	return [_objects count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSDate* lastUpdatedAt = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastUpdatedAt"];
	NSString* dateString = [NSDateFormatter localizedStringFromDate:lastUpdatedAt dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterMediumStyle];
	if (nil == dateString) {
		dateString = @"Never";
	}
	return [NSString stringWithFormat:@"Last Load: %@", dateString];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString* reuseIdentifier = @"Cell";
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
	if (nil == cell) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier] autorelease];
		cell.textLabel.font = [UIFont systemFontOfSize:16];
		cell.textLabel.numberOfLines = 0;
		cell.textLabel.backgroundColor = [UIColor clearColor];
	}
  [self populateCell:cell withObject:[_objects objectAtIndex:indexPath.row]];
  
	return cell;
}

@end

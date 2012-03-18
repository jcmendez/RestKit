//
//  RKHumanViewController.m
//  RKSyncCoreData
//
//  Created by Juan C. Mendez on 3/15/12.
//  Copyright RestKit 2012. All rights reserved.
//
#import "RKHumanViewController.h"
#import "RKHuman.h"

@implementation RKHumanViewController

- (void)loadView {
    [super loadView];
	
	// Setup View and Table View	
	self.title = @"Humans";
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackTranslucent;
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadButtonWasPressed:)] autorelease];
  
	_tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 480-64) style:UITableViewStylePlain];
	_tableView.dataSource = self;
	_tableView.delegate = self;		
	_tableView.backgroundColor = [UIColor clearColor];
	_tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:_tableView];
	
	// Load statuses from core data
	[self loadObjectsFromDataStore];
}

- (void)dealloc {
	[_tableView release];
	[_humans release];
    [super dealloc];
}

- (void)loadObjectsFromDataStore {
	[_humans release];
	NSFetchRequest* request = [RKHuman fetchRequest];
	NSSortDescriptor* descriptor = [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO];
	[request setSortDescriptors:[NSArray arrayWithObject:descriptor]];
	_humans = [[RKHuman objectsWithFetchRequest:request] retain];
}

- (void)loadData {
  // The following call to the syncManager will replace a regular loadObjects call like
  //     [objectManager loadObjectsAtResourcePath:@"/humans" delegate:self];
  RKManagedObjectSyncManager *syncManager = [RKManagedObjectSyncManager sharedSyncManager];
  [syncManager syncObjectsForEntity:[RKHuman entity] delegate:self];
}

- (void)reloadButtonWasPressed:(id)sender {
	// Load the object model via RestKit
	[self loadData];
}

#pragma mark RKSyncManagerDelegate methods

- (void) syncManagerFinishedSync:(RKManagedObjectSyncManager *)manager {
	[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"LastUpdatedAt"];
	[[NSUserDefaults standardUserDefaults] synchronize];  
  NSLog(@"Synced humans successfully");
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

#pragma mark UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	CGSize size = [[[_humans objectAtIndex:indexPath.row] name] sizeWithFont:[UIFont systemFontOfSize:16] constrainedToSize:CGSizeMake(300, 9000)];
	return size.height + 10;
}

#pragma mark UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
	return [_humans count];
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
	NSString* reuseIdentifier = @"Human Cell";
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
	if (nil == cell) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier] autorelease];
		cell.textLabel.font = [UIFont systemFontOfSize:16];
		cell.textLabel.numberOfLines = 0;
		cell.textLabel.backgroundColor = [UIColor clearColor];
		cell.contentView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"listbg.png"]];
	}
    RKHuman* status = [_humans objectAtIndex:indexPath.row];
	cell.textLabel.text = status.name;
	return cell;
}

@end

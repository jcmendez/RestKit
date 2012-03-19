//
//  RKHumanViewController.m
//  RKSyncCoreData
//
//  Created by Juan C. Mendez on 3/15/12.
//  Copyright RestKit 2012. All rights reserved.
//
#import "RKHumanViewController.h"
#import "RKCatViewController.h"
#import "RKHuman.h"

@implementation RKHumanViewController

- (NSEntityDescription *) entityToShow {
  return [RKHuman entity];
}

- (void)loadObjectsFromDataStore {
	[_objects release];
	NSFetchRequest* request = [RKHuman fetchRequest];
	NSSortDescriptor* descriptor = [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO];
	[request setSortDescriptors:[NSArray arrayWithObject:descriptor]];
	_objects = [[RKHuman objectsWithFetchRequest:request] retain];
}

- (void) populateCell:(UITableViewCell *) cell withObject:(NSManagedObject *) object {
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
  [dateFormatter setDateStyle:NSDateFormatterNoStyle];
  RKHuman* human = (RKHuman *) object;
  NSString *dateString = [dateFormatter stringFromDate: human.createdAt];
	cell.textLabel.text = [NSString stringWithFormat: @"%@(%@) %@", human.name, human.railsID, dateString];
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  RKHuman *selectedHuman = [_objects objectAtIndex:[indexPath row]];
  
  if (!catViewController)
    catViewController = [[[RKCatViewController alloc] initWithNibName:nil bundle:nil] retain];
  
  catViewController.human = selectedHuman;
  [self.navigationController pushViewController:catViewController animated:YES];
}

- (void)dealloc {
  if (catViewController) [catViewController release];
  catViewController = nil;
  [super dealloc];
}

@end

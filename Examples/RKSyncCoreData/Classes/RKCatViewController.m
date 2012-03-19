//
//  RKCatViewController.m
//  RKSyncCoreData
//
//  Created by Juan C. Mendez on 3/15/12.
//  Copyright RestKit 2012. All rights reserved.
//
#import "RKCatViewController.h"
#import "RKHuman.h"
#import "RKCat.h"

@implementation RKCatViewController

@synthesize human = _human;

- (NSEntityDescription *) entityToShow {
  return [RKCat entity];
}

- (void)setHuman:(RKHuman *)aHuman {
  if (aHuman != _human) {
    _human = aHuman;
    [self loadObjectsFromDataStore];
    [_tableView reloadData];
  }
}

- (void)loadObjectsFromDataStore {
	[_objects release];
  NSMutableArray *a = [[[NSMutableArray alloc] init] autorelease];
  for (RKCat *cat in [_human cats])
    [a addObject: cat];
  _objects = [[NSArray arrayWithArray:a] retain];
}


- (void) populateCell:(UITableViewCell *) cell withObject:(NSManagedObject *) object {
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
  [dateFormatter setDateStyle:NSDateFormatterNoStyle];
  RKCat* cat = (RKCat *) object;
  NSString *dateString = [dateFormatter stringFromDate: cat.createdAt];
	cell.textLabel.text = [NSString stringWithFormat: @"%@(%@) %@", cat.name, cat.railsID, dateString];
}

@end

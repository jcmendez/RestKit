//
//  RKManagedObjectSyncManager.h
//  RestKit
//
//  Created by Juan C Mendez on 3/16/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "RKManagedObjectMapping.h"

/**
 * Creates a two-way synchronization mechanism between the back end and the Core Data Store
 */
@interface RKManagedObjectSyncManager : NSObject

/*
 * Returns the shared observer
 */
+ (RKManagedObjectSyncManager *)sharedSyncManager;

- (void) setSyncMode:(NSUInteger) theSyncMode forEntity:(NSEntityDescription *) theEntity;
- (NSUInteger) syncModeForEntity:(NSEntityDescription *) theEntity;

- (void) setSyncCreateStampAttribute: theSyncCreateStampAttribute forEntity:(NSEntityDescription *) theEntity;
- (NSString *) syncCreateStampAttributeForEntity:(NSEntityDescription *) theEntity;

- (void) setSyncUpdateStampAttribute: theSyncUpdateStampAttribute forEntity:(NSEntityDescription *) theEntity;
- (NSString *) syncUpdateStampAttributeForEntity:(NSEntityDescription *) theEntity;

- (void) setObjectMapping:(RKManagedObjectMapping *)theMapping forEntity:(NSEntityDescription *) theEntity;


@end

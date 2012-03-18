//
//  RKManagedObjectSyncManager.m
//  RestKit
//
//  Created by Juan C Mendez on 3/16/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "RKLog.h"
#import "RKManagedObjectSyncManager.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitCoreDataSyncManager

static RKManagedObjectSyncManager *_sharedSyncManager = nil;

@interface RKManagedObjectSyncManager() {
  NSMutableDictionary *_syncedEntities;
}
@end

@interface RKManagedObjectSyncRecord : NSObject 
@property (assign,atomic) NSUInteger syncMode;
@property (strong,atomic) NSString *createStampAttribute;
@property (strong,atomic) NSString *updateStampAttribute;
@property (assign,atomic) RKManagedObjectMapping *objectMapping;
@end

@implementation RKManagedObjectSyncRecord
@synthesize syncMode, createStampAttribute, updateStampAttribute, objectMapping;
@end

@implementation RKManagedObjectSyncManager

+ (RKManagedObjectSyncManager *)sharedSyncManager {
  if (! _sharedSyncManager) {
    _sharedSyncManager = [[RKManagedObjectSyncManager alloc] init];
  }
  return _sharedSyncManager;
}

- (id)init {
  self = [super init];
  if (self) {
    _syncedEntities = [[NSMutableDictionary alloc] init];
    [_syncedEntities retain]; 
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(managedObjectContextDidSaveNotification:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:nil];
  }
  
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  for (id syncRecord in _syncedEntities) {
    [syncRecord release];
  }
  [_syncedEntities release];
  [super dealloc];
}

/**
 * Utility method to create sync records on the dictionary
 */
- (RKManagedObjectSyncRecord *) syncRecordForEntity:(NSEntityDescription *) theEntity {
  RKManagedObjectSyncRecord *syncRecord;
  syncRecord = [_syncedEntities objectForKey:[theEntity managedObjectClassName]];
  if (!syncRecord) {
    syncRecord = [[RKManagedObjectSyncRecord alloc] init];
    [syncRecord retain];
    [_syncedEntities setObject:syncRecord forKey:[theEntity managedObjectClassName]];
    RKLogInfo(@"Creating sync record %@", syncRecord);
  }
  return syncRecord;
}

/**
 * Store the mapping on the sync record for the entity
 */
- (void) setObjectMapping:(RKManagedObjectMapping *)theMapping forEntity:(NSEntityDescription *) theEntity {
  RKManagedObjectSyncRecord *syncRecord = [self syncRecordForEntity:theEntity];
  syncRecord.objectMapping = theMapping;  
}

/**
 * Store the sync mode on the sync record for the entity
 */
- (void) setSyncMode:(NSUInteger) theSyncMode forEntity:(NSEntityDescription *) theEntity {
  RKManagedObjectSyncRecord *syncRecord = [self syncRecordForEntity:theEntity];
  syncRecord.syncMode = theSyncMode;
}

/**
 * Retrieve the sync mode from the sync record for the entity
 */
- (NSUInteger) syncModeForEntity:(NSEntityDescription *) theEntity {
  RKManagedObjectSyncRecord *syncRecord = [self syncRecordForEntity:theEntity];
  return syncRecord.syncMode;
}

/**
 * Store on the sync record for the entity the name of the attribute to be used as create timestamp 
 */
- (void) setSyncCreateStampAttribute: theSyncCreateStampAttribute forEntity:(NSEntityDescription *) theEntity {
  RKManagedObjectSyncRecord *syncRecord = [self syncRecordForEntity:theEntity];
  syncRecord.createStampAttribute = theSyncCreateStampAttribute;
}

/**
 * Retrieve from the sync record for the entity the name of the attribute to be used as create timestamp 
 */
- (NSString *) syncCreateStampAttributeForEntity:(NSEntityDescription *) theEntity {
  RKManagedObjectSyncRecord *syncRecord = [self syncRecordForEntity:theEntity];
  return syncRecord.createStampAttribute;
}

/**
 * Store on the sync record for the entity the name of the attribute to be used as update timestamp 
 */
- (void) setSyncUpdateStampAttribute: theSyncUpdateStampAttribute forEntity:(NSEntityDescription *) theEntity {
  RKManagedObjectSyncRecord *syncRecord = [self syncRecordForEntity:theEntity];
  syncRecord.updateStampAttribute = theSyncUpdateStampAttribute;
}

/**
 * Retrieve from the sync record for the entity the name of the attribute to be used as update timestamp 
 */
- (NSString *) syncUpdateStampAttributeForEntity:(NSEntityDescription *) theEntity {
  RKManagedObjectSyncRecord *syncRecord = [self syncRecordForEntity:theEntity];
  return syncRecord.updateStampAttribute;  
}

- (void)managedObjectContextDidSaveNotification:(NSNotification *)notification {
  NSManagedObjectContext *context = [notification object];
  NSSet *insertedObjects = [NSSet setWithSet:context.insertedObjects];
  NSSet *updatedObjects = [NSSet setWithSet:context.updatedObjects];
  NSSet *deletedObjects = [NSSet setWithSet:context.deletedObjects];
  
  RKLogDebug(@"Managed object context will save notification received. Checking changed and inserted objects for searchable entities...");
  
}



@end

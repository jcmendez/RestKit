//
//  RKManagedObjectSyncManager.m
//  RestKit
//
//  Created by Juan C Mendez on 3/16/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "RKLog.h"
#import "RKObjectManager.h"
#import "RKManagedObjectSyncManager.h"
#import "RKManagedObjectMapping+RKSyncManager.m"
#import "NSManagedObject+ActiveRecord.h"

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
@property (strong,atomic) NSString *syncResourcePath;
@property (strong,atomic) NSString *createStampAttribute;
@property (strong,atomic) NSString *updateStampAttribute;
@property (assign,atomic) RKManagedObjectMapping *objectMapping;
@end

@implementation RKManagedObjectSyncRecord
@synthesize syncMode, syncResourcePath, createStampAttribute, updateStampAttribute, objectMapping;
@end

@implementation RKManagedObjectSyncManager

@synthesize delegate = _delegate;

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
 * Retrieve the object mapping from the sync record for the entity
 */
- (RKManagedObjectMapping *) objectMappingForEntity:(NSEntityDescription *) theEntity {
  RKManagedObjectSyncRecord *syncRecord = [self syncRecordForEntity:theEntity];
  return syncRecord.objectMapping;  
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
  if ([_syncedEntities objectForKey:[theEntity managedObjectClassName]] == nil) return RKSyncModeNoSync;
  RKManagedObjectSyncRecord *syncRecord = [self syncRecordForEntity:theEntity];
  return syncRecord.syncMode;
}

/**
 * Store the sync resource path on the sync record for the entity
 */
- (void) setSyncResourcePath:(NSString *) theResourcePath forEntity:(NSEntityDescription *) theEntity {
  RKManagedObjectSyncRecord *syncRecord = [self syncRecordForEntity:theEntity];
  syncRecord.syncResourcePath = theResourcePath;  
}

/**
 * Retrieve from the sync record for the entity the sync resource path 
 */
- (NSString *) syncResourcePathForEntity:(NSEntityDescription *) theEntity {
  RKManagedObjectSyncRecord *syncRecord = [self syncRecordForEntity:theEntity];
  return syncRecord.syncResourcePath;  
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

- (void) syncObjectsForEntity:(NSEntityDescription *)theEntity delegate:(NSObject<RKSyncManagerDelegate> *)delegate {
  RKObjectManager *manager = [RKObjectManager sharedManager];
  NSString *resourcePath = [self syncResourcePathForEntity:theEntity]; 
  if ([self syncModeForEntity:theEntity] == RKSyncModePullFromServer) {    
    NSFetchRequest *toDelete = [[[NSFetchRequest alloc] init] autorelease];
    [toDelete setEntity:theEntity];
    [toDelete setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    NSManagedObjectContext *context = [RKObjectManager sharedManager].objectStore.managedObjectContextForCurrentThread;
    NSError *error = nil;
    NSArray *objectsToDelete = [context executeFetchRequest:toDelete error:&error];
    NSAssert(!error, @"Error occurred fetching objects to delete");
    for (NSManagedObject *object in objectsToDelete) {
      [context deleteObject:object];
    }
    NSError *saveError = nil;
    [context save:&saveError];
    NSAssert(!saveError, @"Error occurred saving context while deleting objects");
  }
  self.delegate = delegate;
  [manager loadObjectsAtResourcePath:resourcePath delegate:self];
}

- (void)managedObjectContextDidSaveNotification:(NSNotification *)notification {
  NSManagedObjectContext *context = [notification object];
  NSSet *insertedObjects = [NSSet setWithSet:context.insertedObjects];
  NSSet *updatedObjects = [NSSet setWithSet:context.updatedObjects];
  NSSet *deletedObjects = [NSSet setWithSet:context.deletedObjects];
  
  RKLogDebug(@"Managed object context will save notification received. Checking changed and inserted objects for searchable entities...");
  
}

#pragma mark -
#pragma mark Object Loader delegate methods

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
  RKLogInfo(@"Sync Manager got didFailWithError call");
}

/**
 * Scan the array of results to determine which entities will be affected by the sync
 * TODO: right now it just looks at the entity for the objects returned, will need to
 * look at the dependencies
 */
- (NSSet *) entitiesAffectedSyncingObjects:(NSArray *)objects {
  NSMutableSet *entities = [[[NSMutableSet alloc] init] autorelease];
  for (NSManagedObject *object in objects) {
    NSEntityDescription *entity = [object entity];
    [entities addObject:entity];
  }
  return [NSSet setWithSet:entities];
}

- (NSArray *)localObjectsForLoadedObjects:(NSArray *)remoteObjects {
  NSSet *entities = [self entitiesAffectedSyncingObjects:remoteObjects];
  NSMutableSet *localObjects = [[[NSMutableSet alloc] init] autorelease];
  for (NSEntityDescription *entity in entities) {
    NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
    [fetchRequest setEntity:entity];
    [localObjects addObjectsFromArray:[NSManagedObject objectsWithFetchRequest:fetchRequest]];
  }
  return [localObjects allObjects];
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects {
  RKLogInfo(@"Sync Manager got didLoadObjects call");
  
  NSArray *localObjects = [self localObjectsForLoadedObjects:objects];

  for (NSManagedObject *object in objects) {
    NSEntityDescription *entity = [object entity];
    NSUInteger syncMode = [self syncModeForEntity:entity];
    
    if (syncMode == RKSyncModePullFromServer) {
      RKLogInfo(@"Done syncing %@", object);
      continue;
    } else {
      RKManagedObjectMapping *mapping = [self objectMappingForEntity:entity];

    }
  }
  if (_delegate && [_delegate respondsToSelector:@selector(syncManagerFinishedSync:)])
    [_delegate syncManagerFinishedSync:self];
}

- (void)objectLoaderDidFinishLoading:(RKObjectLoader *)objectLoader {
  RKLogInfo(@"Sync Manager got didFinishLoading call");
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didSerializeSourceObject:(id)sourceObject toSerialization:(inout id<RKRequestSerializable> *)serialization {
  RKLogInfo(@"Sync Manager got didSerializeSourceObject call");
}

- (void)objectLoaderDidLoadUnexpectedResponse:(RKObjectLoader *)objectLoader {
  RKLogInfo(@"Sync Manager got didLoadUnexpectedResponse call");
}

- (void)objectLoader:(RKObjectLoader *)loader willMapData:(inout id *)mappableData {
  RKLogInfo(@"Sync Manager got willMapData call");
}



@end

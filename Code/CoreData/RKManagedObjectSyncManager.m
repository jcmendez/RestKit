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
  NSMutableDictionary *_syncedRecordDictionary;
  NSDictionary *_localObjectsBeforeLoad;
}
@end

@interface RKManagedObjectSyncRecord : NSObject 
@property (assign,atomic) NSUInteger syncMode;
@property (strong,atomic) NSString *syncResourcePath;
@property (strong,atomic) NSString *createStampAttribute;
@property (strong,atomic) NSString *updateStampAttribute;
@property (strong,atomic) NSString *lastSyncStampAttribute;
@property (assign,atomic) RKManagedObjectMapping *objectMapping;
@end

@implementation RKManagedObjectSyncRecord
@synthesize syncMode, syncResourcePath, createStampAttribute, updateStampAttribute, lastSyncStampAttribute, objectMapping;
@end

@implementation RKManagedObjectSyncManager

@synthesize delegate = _delegate;
@synthesize mainEntitySyncing, syncing, deleteLocalsBeforeSync;

+ (RKManagedObjectSyncManager *)sharedSyncManager {
  if (! _sharedSyncManager) {
    _sharedSyncManager = [[RKManagedObjectSyncManager alloc] init];
  }
  return _sharedSyncManager;
}

- (id)init {
  self = [super init];
  if (self) {
    _syncedRecordDictionary = [[NSMutableDictionary alloc] init];
    [_syncedRecordDictionary retain]; 
    _localObjectsBeforeLoad = nil;
    mainEntitySyncing = nil;
    syncing = NO;
    deleteLocalsBeforeSync = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(managedObjectContextDidSaveNotification:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:nil];
  }
  
  return self;
}

- (void) deallocLocalObjectsDictIfNeeded {
  if (_localObjectsBeforeLoad) {
    [_localObjectsBeforeLoad release];
    _localObjectsBeforeLoad = nil;
  }
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  for (id syncRecord in _syncedRecordDictionary) {
    [syncRecord release];
  }
  [_syncedRecordDictionary release];
  [self deallocLocalObjectsDictIfNeeded];
  [super dealloc];
}


/**
 * Utility method to create sync records on the dictionary
 */
- (RKManagedObjectSyncRecord *) syncRecordForEntity:(NSEntityDescription *) theEntity {
  RKManagedObjectSyncRecord *syncRecord;
  syncRecord = [_syncedRecordDictionary objectForKey:[theEntity managedObjectClassName]];
  if (!syncRecord) {
    syncRecord = [[RKManagedObjectSyncRecord alloc] init];
    [syncRecord retain];
    [_syncedRecordDictionary setObject:syncRecord forKey:[theEntity managedObjectClassName]];
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
  if ([_syncedRecordDictionary objectForKey:[theEntity managedObjectClassName]] == nil) return RKSyncModeNoSync;
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

/**
 * Store on the sync record for the entity the name of the attribute to be used as update timestamp 
 */
- (void) setSyncLastSyncStampAttribute: theSyncLastSyncStampAttribute forEntity:(NSEntityDescription *) theEntity {
  RKManagedObjectSyncRecord *syncRecord = [self syncRecordForEntity:theEntity];
  syncRecord.lastSyncStampAttribute = theSyncLastSyncStampAttribute;
}

/**
 * Retrieve from the sync record for the entity the name of the attribute to be used as update timestamp 
 */
- (NSString *) syncLastSyncStampAttributeForEntity:(NSEntityDescription *) theEntity {
  RKManagedObjectSyncRecord *syncRecord = [self syncRecordForEntity:theEntity];
  return syncRecord.lastSyncStampAttribute;  
}

- (void) deleteLocalObjectsIfNeeded {
  if (deleteLocalsBeforeSync) {    
    NSFetchRequest *toDelete = [[[NSFetchRequest alloc] init] autorelease];
    [toDelete setEntity:mainEntitySyncing];
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
  deleteLocalsBeforeSync = NO;
}

/**
 * Returns a set of entity descriptions that we must sync
 */
- (NSSet *) entitiesToSyncForEntity: (NSEntityDescription *) mainEntity {
  NSMutableSet *resultSet = [[[NSMutableSet alloc] init] autorelease];
  if ([self syncModeForEntity:mainEntity] != RKSyncModeNoSync)
    [resultSet addObject:mainEntity];
  NSDictionary *relationships = [mainEntity relationshipsByName];
  // TODO: Do a full depth navigation of the relationship graph.  For now it is enough for
  // my needs, but this gotta be generic
  for (NSRelationshipDescription* relationship in [relationships allValues]) {
    if ([self syncModeForEntity:relationship.destinationEntity] != RKSyncModeNoSync)
      [resultSet addObject:relationship.destinationEntity];
  }
  return [NSSet setWithSet:resultSet];
}

/**
 * Returns a structure with nested dictionaries.  At first level, the keys are the entity
 * names, and the values are dictionaries.  At this second level, the keys are the primary
 * keys for the item, the values the objects
 * NOTE: These second level dictionaries are retained!
 */
- (NSDictionary *)localObjectsForEntities:(NSSet *)entities {
  NSMutableDictionary *resultDictionary = [[[NSMutableDictionary alloc] initWithCapacity:[entities count]] autorelease];
  
  for (NSEntityDescription *entity in entities) {
    RKManagedObjectMapping *mapping = [self objectMappingForEntity:entity];
    NSString *primaryKeyAttribute = mapping.primaryKeyAttribute;
    NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
    [fetchRequest setEntity:entity];
    //    [fetchRequest setSortDescriptors:[[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:primaryKeyAttribute ascending:YES]] autorelease]];
    NSMutableDictionary *dictForEntity = [[[NSMutableDictionary alloc] init] retain];
    for (NSManagedObject *object in [NSManagedObject objectsWithFetchRequest:fetchRequest])
      [dictForEntity setObject:object forKey:[object valueForKey:primaryKeyAttribute]];
    [resultDictionary setObject:dictForEntity forKey:[entity managedObjectClassName]];
  }
  return [NSDictionary dictionaryWithDictionary:resultDictionary];
}

- (void) syncObjectsForEntity:(NSEntityDescription *)theEntity delegate:(NSObject<RKSyncManagerDelegate> *)delegate {
  NSAssert(!syncing, @"Can't process - a sync is ongoing");
  syncing = YES;
  RKObjectManager *manager = [RKObjectManager sharedManager];
  NSString *resourcePath = [self syncResourcePathForEntity:theEntity]; 
  mainEntitySyncing = theEntity;
  
  if ([self syncModeForEntity:theEntity] & RKSyncModePullFromServer)
    deleteLocalsBeforeSync = YES;
  else {
    [self deallocLocalObjectsDictIfNeeded];
    _localObjectsBeforeLoad = [self localObjectsForEntities:[self entitiesToSyncForEntity:mainEntitySyncing]];
    [_localObjectsBeforeLoad retain];
  }
  self.delegate = delegate;
  [manager loadObjectsAtResourcePath:resourcePath delegate:self];
}

- (void)managedObjectContextDidSaveNotification:(NSNotification *)notification {
  if (syncing) return; // If we are already in a sync operation, we don't want to process here
  
  NSManagedObjectContext *context = [notification object];
  NSSet *insertedObjects = [NSSet setWithSet:context.insertedObjects];
  NSSet *updatedObjects = [NSSet setWithSet:context.updatedObjects];
  NSSet *deletedObjects = [NSSet setWithSet:context.deletedObjects];
  
  // TODO: We need to collect all the changed objects, and iff we are doing a fast sync, then
  // we use the changes to either try to propagate, or add to a queue to replay later.
  RKLogDebug(@"Managed object context will save notification received. Checking changed and inserted objects for searchable entities...");
  
}

#pragma mark -
#pragma mark Object Loader delegate methods

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
  RKLogInfo(@"Sync Manager got didFailWithError call");
  if (_delegate && [_delegate respondsToSelector:@selector(syncManagerFailedSync:)])
    [_delegate syncManagerFailedSync:self];
  [self deallocLocalObjectsDictIfNeeded];
  syncing = NO;
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

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects {
  RKLogInfo(@"Sync Manager got didLoadObjects call");
  
  NSMutableSet *onlyLocal = [[[NSMutableSet alloc] init] autorelease];
  NSMutableSet *onlyRemote = [[[NSMutableSet alloc] init] autorelease];
  NSMutableSet *bothLocalAndRemote = [[[NSMutableSet alloc] init] autorelease];
  
  for (NSManagedObject *object in objects) {
    NSEntityDescription *entity = [object entity];
    NSUInteger syncMode = [self syncModeForEntity:entity];
    
    if (syncMode & RKSyncModePullFromServer) {
      continue;
    } else {
      RKManagedObjectMapping *mapping = [self objectMappingForEntity:entity];
      NSString *primaryKeyAttribute = mapping.primaryKeyAttribute;
      id primaryKeyValue = [object valueForKey:primaryKeyAttribute];
      NSMutableDictionary *dictForEntity = [_localObjectsBeforeLoad objectForKey:[entity managedObjectClassName]];
      NSManagedObject *localObject = nil;
      if (dictForEntity) localObject = [dictForEntity objectForKey:primaryKeyValue];
      if (localObject) {
        // Found the object in both local and remote
        [bothLocalAndRemote addObject:[NSArray arrayWithObjects:localObject, object, nil]];
        [dictForEntity removeObjectForKey:primaryKeyValue];
      } else {
        // Its only present on the remote
        [onlyRemote addObject:object];
      }
    }
  }
  // Anything that is left on the localObjects dictionary is local only  
  NSEnumerator * myDictEnumerator = [_localObjectsBeforeLoad keyEnumerator];
  NSString *entityClassName;
  while (entityClassName = [myDictEnumerator nextObject]) {
    NSMutableDictionary *dictForEntity = [_localObjectsBeforeLoad objectForKey:entityClassName];
    [onlyLocal addObjectsFromArray:[dictForEntity allValues]];
  }
  // Let's process the local ones
  NSLog(@"onlyLocal: %@", onlyLocal);
  for (NSManagedObject *object in onlyLocal) {
    NSEntityDescription *entity = [object entity];
    NSUInteger syncMode = [self syncModeForEntity:entity];

    if ((syncMode & RKSyncModePushFromDevice) || (syncMode & RKSyncModeTwoWay)) {
      NSDate *creationDate = [object valueForKey:[self syncCreateStampAttributeForEntity:entity]];
      NSDate *lastSyncDate = [object valueForKey:[self syncLastSyncStampAttributeForEntity:entity]];
      
    }
  }
  NSLog(@"onlyRemote: %@", onlyRemote);
  NSLog(@"bothLocalAndRemote: %@", bothLocalAndRemote);
//  NSString *createDateAttribute = [self syncCreateStampAttributeForEntity:entity];
//  NSString *updateDateAttribute = [self syncUpdateStampAttributeForEntity:entity];
  

  if (_delegate && [_delegate respondsToSelector:@selector(syncManagerFinishedSync:)])
    [_delegate syncManagerFinishedSync:self];
  [self deallocLocalObjectsDictIfNeeded];
  syncing = NO;
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didSerializeSourceObject:(id)sourceObject toSerialization:(inout id<RKRequestSerializable> *)serialization {
  RKLogInfo(@"Sync Manager got didSerializeSourceObject call");
}

- (void)objectLoaderDidLoadUnexpectedResponse:(RKObjectLoader *)objectLoader {
  RKLogInfo(@"Sync Manager got didLoadUnexpectedResponse call");
  if (_delegate && [_delegate respondsToSelector:@selector(syncManagerFailedSync:)])
    [_delegate syncManagerFailedSync:self];
  [self deallocLocalObjectsDictIfNeeded];
  syncing = NO;
}

/**
 * This method is called by the object loader, and we know at this point the json response
 * was received and parsed, so it is safe to delete the local objects if that is needed in
 * the current sync mode
 */
- (void)objectLoader:(RKObjectLoader *)loader willMapData:(inout id *)mappableData {
  [self deleteLocalObjectsIfNeeded];
}



@end

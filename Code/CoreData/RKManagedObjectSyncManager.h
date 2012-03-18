//
//  RKManagedObjectSyncManager.h
//  RestKit
//
//  Created by Juan C Mendez on 3/16/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "RKManagedObjectMapping.h"
#import "RKObjectLoader.h"

@class RKManagedObjectSyncManager;

@protocol RKSyncManagerDelegate 
@optional
- (void) syncManagerFinishedSync: (RKManagedObjectSyncManager *) manager;
@end


/**
 * Creates a two-way synchronization mechanism between the back end and the Core Data Store
 */
@interface RKManagedObjectSyncManager : NSObject<RKObjectLoaderDelegate>

/*
 * Returns the shared observer
 */
+ (RKManagedObjectSyncManager *)sharedSyncManager;

- (void) setSyncMode:(NSUInteger) theSyncMode forEntity:(NSEntityDescription *) theEntity;
- (NSUInteger) syncModeForEntity:(NSEntityDescription *) theEntity;

- (void) setSyncResourcePath:(NSString *) theResourcePath forEntity:(NSEntityDescription *) theEntity;
- (NSString *) syncResourcePathForEntity:(NSEntityDescription *) theEntity;

- (void) setSyncCreateStampAttribute: (NSString *) theSyncCreateStampAttribute forEntity:(NSEntityDescription *) theEntity;
- (NSString *) syncCreateStampAttributeForEntity:(NSEntityDescription *) theEntity;

- (void) setSyncUpdateStampAttribute: (NSString *) theSyncUpdateStampAttribute forEntity:(NSEntityDescription *) theEntity;
- (NSString *) syncUpdateStampAttributeForEntity:(NSEntityDescription *) theEntity;

- (void) setObjectMapping:(RKManagedObjectMapping *)theMapping forEntity:(NSEntityDescription *) theEntity;
- (RKManagedObjectMapping *) objectMappingForEntity:(NSEntityDescription *) theEntity;

/**
 * The main call for this class if one wants to do manual sync
 */
- (void) syncObjectsForEntity:(NSEntityDescription *)theEntity delegate:(NSObject<RKSyncManagerDelegate> *)delegate;

@property (strong,nonatomic) NSObject<RKSyncManagerDelegate> *delegate;
@end


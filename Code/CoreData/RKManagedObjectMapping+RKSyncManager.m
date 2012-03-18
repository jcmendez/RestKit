//
//  RKManagedObjectMapping+RKSyncManager.m
//  RestKit
//
//  Created by Juan C Mendez on 3/16/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKManagedObjectSyncManager.h"
#import "RKManagedObjectMapping+RKSyncManager.h"

@implementation RKManagedObjectMapping(RKSyncManager)

- (void)setSyncModeForEntity:(NSUInteger)syncModeForEntity {
  [[RKManagedObjectSyncManager sharedSyncManager] setObjectMapping: self 
                                                         forEntity:[self entity]];
  [[RKManagedObjectSyncManager sharedSyncManager] setSyncMode: syncModeForEntity 
                                                    forEntity:[self entity]];
}

- (void)setSyncCreateStampAttribute:(NSString *)theSyncCreateStampAttribute {
  [[RKManagedObjectSyncManager sharedSyncManager] setObjectMapping: self 
                                                         forEntity:[self entity]];
  [[RKManagedObjectSyncManager sharedSyncManager] setSyncCreateStampAttribute: theSyncCreateStampAttribute 
                                                                    forEntity:[self entity]];
}

- (void)setSyncUpdateStampAttribute:(NSString *)theSyncUpdateStampAttribute {
  [[RKManagedObjectSyncManager sharedSyncManager] setObjectMapping: self 
                                                         forEntity:[self entity]];
  [[RKManagedObjectSyncManager sharedSyncManager] setSyncUpdateStampAttribute: theSyncUpdateStampAttribute 
                                                                    forEntity:[self entity]];  
}

- (NSUInteger)syncModeForEntity {
  return [[RKManagedObjectSyncManager sharedSyncManager] syncModeForEntity:[self entity]];
}

- (NSString *)syncCreateStampAttribute {
  return [[RKManagedObjectSyncManager sharedSyncManager] syncCreateStampAttributeForEntity:[self entity]];  
}

- (NSString *)syncUpdateStampAttribute {
  return [[RKManagedObjectSyncManager sharedSyncManager] syncUpdateStampAttributeForEntity:[self entity]];  
}

- (NSString *)syncBackendCreateStampAttribute {
  return [self mappingForAttribute:[self syncCreateStampAttribute]].sourceKeyPath;
}

- (NSString *)syncBackendUpdateStampAttribute {
  return [self mappingForAttribute:[self syncUpdateStampAttribute]].sourceKeyPath;
}

@end

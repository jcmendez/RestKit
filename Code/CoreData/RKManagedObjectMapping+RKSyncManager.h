//
//  RKManagedObjectMapping+RKSyncManager.h
//  RestKit
//
//  Created by Juan C Mendez on 3/16/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKManagedObjectMapping.h"

@interface RKManagedObjectMapping(RKSyncManager)

enum {
  RKSyncModeNoSync                     = 0,
  RKSyncModePullFromServer             = 1,
  RKSyncModePushFromDevice             = 2,
  RKSyncModeTwoWay                     = 3,
  RKSyncModeAllowFastSyncsFlag         = 4,
  RKSyncModeRequireChecksumFlag        = 5,
};

@property (assign,nonatomic) NSUInteger syncModeForEntity;
@property (strong,nonatomic) NSString *syncCreateStampAttribute;
@property (strong,nonatomic) NSString *syncUpdateStampAttribute;

@property (readonly) NSString* syncBackendCreateStampAttribute;
@property (readonly) NSString* syncBackendUpdateStampAttribute;

@end

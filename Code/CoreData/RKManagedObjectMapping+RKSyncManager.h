//
//  RKManagedObjectMapping+RKSyncManager.h
//  RestKit
//
//  Created by Juan C Mendez on 3/16/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKManagedObjectMapping.h"

@interface RKManagedObjectMapping(RKSyncManager)

/**
 * The different sync modes supported.  The semantics are as follows:
 * RKSyncModeNoSync - the sync manager won't do anything for the user.  If objects were added
 *                    to the CoreData store, these will stay after a sync and won't get uploaded 
 *                    to the server by the sync manager (the user can of course upload them 
 *                    manually, of course).  Objects added on the server will be loaded in the 
 *                    CoreData store, following the RKCache strategy selected.  In most cases,
 *                    that means checking the primary key and using the cached copy if present.
 * 
 * RKSyncModePullFromServer - the sync manager will fully replace the objects in the CoreData
 *                            store with those loaded by the server
 *
 * RKSyncModePushFromDevice - the sync manager will fully replace the objects in the server with
 *                            the ones on the device, meaning that immediately after the load,
 *                            the sync manager will start issuing DELETE and POSTs to the server
 *                            with the updated objects.  The sync manager will block any other
 *                            sync attempts until it verifies the push is done
 *
 * RKSyncModeTwoWay - the sync manager will reconcile the objects on the server and the ones on
 *                    the device.  By default, it will use creation and update dates to perform
 *                    the sync, unless RKSyncModeRequireChecksumFlag is specified
 *
 * RKSyncModeAllowFastSyncsFlag - NOT YET IMPLEMENTED: to allow offline updates, any changes on
 *                                the local store, if can't be propagated to the server right
 *                                away (i.e. we are offline) will be stored in a local queue and
 *                                replayed later when connection is restored.  This will not
 *                                load any changes from the server to the device
 */
enum {
  RKSyncModeNoSync                     = 0,
  RKSyncModePullFromServer             = 1,
  RKSyncModePushFromDevice             = 2,
  RKSyncModeTwoWay                     = 3,
  RKSyncModeAllowFastSyncsFlag         = 4,
  RKSyncModeRequireChecksumFlag        = 5,
};

@property (assign,nonatomic) NSUInteger syncModeForEntity;
@property (strong,nonatomic) NSString *syncResourcePathForEntity;
@property (strong,nonatomic) NSString *syncCreateStampAttribute;
@property (strong,nonatomic) NSString *syncUpdateStampAttribute;
@property (strong,nonatomic) NSString *syncLastSyncStampAttribute;

@property (readonly) NSString* syncBackendCreateStampAttribute;
@property (readonly) NSString* syncBackendUpdateStampAttribute;

@end

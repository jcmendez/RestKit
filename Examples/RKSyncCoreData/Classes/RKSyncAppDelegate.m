//
//  RKSyncAppDelegate.m
//  RKSyncCoreData
//
//  Created by Juan C. Mendez on 3/15/12.
//  Copyright RestKit 2012. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>
#import "RKSyncAppDelegate.h"
#import "RKHumanViewController.h"
#import "RKHuman.h"
#import "RKCat.h"

@implementation RKSyncAppDelegate

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Initialize RestKit
	RKObjectManager* objectManager = [RKObjectManager managerWithBaseURLString:@"http://127.0.0.1:9292"];
    
  // Enable automatic network activity indicator management
  objectManager.client.requestQueue.showsNetworkActivityIndicatorWhenBusy = YES;
    
    // Initialize object store
    #ifdef RESTKIT_GENERATE_SEED_DB
        NSString *seedDatabaseName = nil;
        NSString *databaseName = RKDefaultSeedDatabaseFileName;
    #else
        NSString *seedDatabaseName = RKDefaultSeedDatabaseFileName;
        NSString *databaseName = @"RKSyncCoreDataDB.sqlite";
    #endif

    objectManager.objectStore = [RKManagedObjectStore objectStoreWithStoreFilename:databaseName usingSeedDatabaseName:seedDatabaseName managedObjectModel:nil delegate:self];
    
  objectManager.objectStore.cacheStrategy = [[RKFetchRequestMappingCache alloc] init];

    // Setup our object mappings    
    /*!
     Mapping by entity. Here we are configuring a mapping by targetting a Core Data entity with a specific
     name. This allows us to map back Twitter user objects directly onto NSManagedObject instances --
     there is no backing model class!
     */
    RKManagedObjectMapping* catMapping = [RKManagedObjectMapping mappingForClass:[RKCat class] inManagedObjectStore:objectManager.objectStore];
    catMapping.primaryKeyAttribute = @"railsID";
    [catMapping mapKeyPathsToAttributes:@"id", @"railsID",
     @"created_at", @"createdAt",
     @"updated_at", @"updatedAt",
     @"name", @"name",
     nil];
    // The next four statements instruct the sync manager to sync the RKHumans entity, and instruct it to use the
    // fields updatedAt and createdAt to compare instances.  We want full two way sync 
    catMapping.syncModeForEntity = RKSyncModePullFromServer;
    catMapping.syncResourcePathForEntity = @"/cats";
    catMapping.syncUpdateStampAttribute = @"updatedAt";
    catMapping.syncCreateStampAttribute = @"createdAt";

    
    /*!
     Map to a target object class -- just as you would for a non-persistent class. The entity is resolved
     for you using the Active Record pattern where the class name corresponds to the entity name within Core Data.
     Twitter status objects will be mapped onto RKTStatus instances.
     */
    RKManagedObjectMapping* humanMapping = [RKManagedObjectMapping mappingForClass:[RKHuman class] inManagedObjectStore:objectManager.objectStore];
    humanMapping.primaryKeyAttribute = @"railsID";
  
    // Here we do the regular RestKit mapping
    [humanMapping mapKeyPathsToAttributes:@"id", @"railsID",
     @"created_at", @"createdAt",
     @"updated_at", @"updatedAt",
     @"name", @"name",
     @"sex", @"sex",
     @"age", @"age",
     @"birthday", @"birthday", 
     nil];
    [humanMapping mapRelationship:@"cats" withMapping:catMapping];
  
    // The next four statements instruct the sync manager to sync the RKHumans entity, and instruct it to use the
    // fields updatedAt and createdAt to compare instances.  We want full two way sync 
    humanMapping.syncModeForEntity = RKSyncModePullFromServer;
    humanMapping.syncResourcePathForEntity = @"/humans";
    humanMapping.syncUpdateStampAttribute = @"updatedAt";
    humanMapping.syncCreateStampAttribute = @"createdAt";
  NSLog(@"Looking at fields %@, %@ for sync", humanMapping.syncBackendCreateStampAttribute, humanMapping.syncBackendUpdateStampAttribute);

    
    // Update date format so that we can parse Twitter dates properly
	// Wed Sep 29 15:31:08 +0000 2010
    [RKObjectMapping addDefaultDateFormatterForString:@"E MMM d HH:mm:ss Z y" inTimeZone:nil];
    
    // Register our mappings with the provider
  //[objectManager.mappingProvider setObjectMapping:humanMapping forResourcePathPattern:@"/humans"];
  [objectManager.mappingProvider setObjectMapping:humanMapping forKeyPath:@"humans"];
  [objectManager.mappingProvider setObjectMapping:humanMapping forKeyPath:@"human"];
    
    // Uncomment this to use XML, comment it to use JSON
    //  objectManager.acceptMIMEType = RKMIMETypeXML;
    //  [objectManager.mappingProvider setMapping:statusMapping forKeyPath:@"statuses.status"];
    
    // Database seeding is configured as a copied target of the main application. There are only two differences
    // between the main application target and the 'Generate Seed Database' target:
    //  1) RESTKIT_GENERATE_SEED_DB is defined in the 'Preprocessor Macros' section of the build setting for the target
    //      This is what triggers the conditional compilation to cause the seed database to be built
    //  2) Source JSON files are added to the 'Generate Seed Database' target to be copied into the bundle. This is required
    //      so that the object seeder can find the files when run in the simulator.
#ifdef RESTKIT_GENERATE_SEED_DB
    RKLogConfigureByName("RestKit/ObjectMapping", RKLogLevelInfo);
    RKLogConfigureByName("RestKit/CoreData", RKLogLevelTrace);
    RKManagedObjectSeeder* seeder = [RKManagedObjectSeeder objectSeederWithObjectManager:objectManager];
    
    // Seed the database with instances of RKTStatus from a snapshot of the RestKit Twitter timeline
    // [seeder seedObjectsFromFile:@"restkit.json" withObjectMapping:statusMapping];
    
    // Seed the database with RKHuman objects. The class will be inferred via element registration
    [seeder seedObjectsFromFiles:@"humans.json", nil];
    
    // Finalize the seeding operation and output a helpful informational message
    [seeder finalizeSeedingAndExit];
    
    // NOTE: If all of your mapped objects use keyPath -> objectMapping registration, you can perform seeding in one line of code:
    // [RKManagedObjectSeeder generateSeedDatabaseWithObjectManager:objectManager fromFiles:@"users.json", nil];
#endif
    
    // Create Window and View Controllers
    RKHumanViewController* viewController = [[[RKHumanViewController alloc] initWithNibName:nil bundle:nil] autorelease];
    UINavigationController* controller = [[UINavigationController alloc] initWithRootViewController:viewController];
    UIWindow* window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
  [window setBackgroundColor:[UIColor whiteColor]];
    [window addSubview:controller.view];
    [window makeKeyAndVisible];

    return YES;
}

- (void)dealloc {
    [super dealloc];
}

- (void)managedObjectStore:(RKManagedObjectStore *)objectStore didFailToCreatePersistentStoreCoordinatorWithError:(NSError *)error {
  RKLogError(@"%@",error);
}

- (void)managedObjectStore:(RKManagedObjectStore *)objectStore didFailToDeletePersistentStore:(NSString *)pathToStoreFile error:(NSError *)error {
  RKLogError(@"%@",error);
}

- (void)managedObjectStore:(RKManagedObjectStore *)objectStore didFailToCopySeedDatabase:(NSString *)seedDatabase error:(NSError *)error {
  RKLogError(@"%@",error);  
}

- (void)managedObjectStore:(RKManagedObjectStore *)objectStore didFailToSaveContext:(NSManagedObjectContext *)context error:(NSError *)error exception:(NSException *)exception {
  RKLogError(@"%@",error);  
}


@end

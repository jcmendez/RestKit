//
//  RKCatViewController.h
//  RKSyncCoreData
//
//  Created by Juan C. Mendez on 3/15/12.
//  Copyright RestKit 2012. All rights reserved.
//

#import "RKEntityViewController.h"

@class RKHuman;

@interface RKCatViewController : RKEntityViewController
@property (strong,nonatomic) RKHuman *human;
@end


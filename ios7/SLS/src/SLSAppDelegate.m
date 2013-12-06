//
//  SLSAppDelegate.m
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 4/1/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import <AddressBook/AddressBook.h>

#import "SLSAppDelegate.h"
#import "PersonalDataController.h"
#import "ProviderMasterViewController.h"
#import "ConsumerMasterViewController.h"
#import "ConsumerListController.h"
#import "ProviderListController.h"
#import "Principal.h"                        // SIMULATOR HACK: needed for debugging w/bogus entry
#import "NSData+Base64.h"


static const int kDebugLevel = 3;

@implementation SLSAppDelegate

@synthesize window = _window;

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    if (kDebugLevel > 2)
        NSLog(@"SLSAppDelegate:didFinishLaunchingWithOptions: called.");
    
    // Override point for customization after application launch.
    
#if 0
    // Checks for which interface we should be using.
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        CGRect  rect = [[UIScreen mainScreen] bounds];
        [window setFrame:rect];
    } else {
        CGRect  rect = [[UIScreen mainScreen] bounds];
        [_window setFrame:rect];
    }
#endif
    
    // Get root viewController.
    UITabBarController* tabController = (UITabBarController*)self.window.rootViewController;
    
    // Check each viewController, initializing our data controllers within the view controllers as we walk through them ...
    
    int i = 0;
    for (id tabItem in tabController.viewControllers) {
        if ([tabItem isMemberOfClass:[ProviderMasterViewController class]]) {
            if (kDebugLevel > 3)
                NSLog(@"Found ProviderMasterViewController Class at index %d!", i);
        } else if ([tabItem isMemberOfClass:[ConsumerMasterViewController class]]) {
            if (kDebugLevel > 3)
                NSLog(@"Found ConsumerMasterViewController Class at index %d!", i);
        } else if ([tabItem isMemberOfClass:[UINavigationController class]]) {
            //NSLog(@"UINavigationController Class at index %d!", i);
            
            // Look inside the NavigationController's viewControllers.
            UINavigationController* navController = (UINavigationController*)tabItem;
            int k = 0;
            for (id navItem in navController.viewControllers) {
                if ([navItem isMemberOfClass:[ProviderMasterViewController class]]) {
                    if (kDebugLevel > 2)
                        NSLog(@"Found ProviderMasterViewController Class at index %d:%d!", i, k);
                    
                    // Setup the data members within the Provider's master controller.
                    ProviderMasterViewController* master_controller = (ProviderMasterViewController*)navItem;
                    [master_controller loadState];
                    
                    // For debugging: See whose phone this is, and load in temporary keys if necessary.
                    NSLog(@"SLSAppDelegate:didFinishLaunchingWithOptions: DEBUG: Provider loading static information based on device name!");
                    
                    UIDevice* ui_device = [UIDevice currentDevice];
                    if (ui_device.name == nil) {
                        NSLog(@"SLSAppDelegate:didFinishLaunchingWithOptions: nil device name.");
                    } else if ([ui_device.name caseInsensitiveCompare:@"iPhone Simulator"] == NSOrderedSame) {
                        if (kDebugLevel > 0)
                            NSLog(@"SLSAppDelegate:didFinishLaunchingWithOptions: Found device iPhone Simulator.");
                        
#if 1  // SIMULATOR HACK:
                        {
                            NSLog(@"SLSAppDelegate:didFinishLaunchingWithOptions: Seeing if we need to add entry for iPhone Simulator to AddressBook.");
                            
                            // Fetch the address book
                            CFErrorRef status = NULL;
                            ABAddressBookRef address_book = ABAddressBookCreateWithOptions(NULL, &status);
                            
                            // Search for the person named "Simulator" in our address book.
                            CFArrayRef people_ref = ABAddressBookCopyPeopleWithName(address_book, CFSTR("Simulator"));
                            NSArray* people = CFBridgingRelease(people_ref);  // no need to release people_ref now
                            
                            /* Neat iterator hack!
                            if (people != nil && [people count] > 0) {
                                for (id object in people) {
                                    ABRecordRef person = (__bridge ABRecordRef)object;
                                    NSLog(@"Deleting record: %@.", (__bridge NSString*)ABRecordCopyCompositeName(person));
                                }
                            }
                            */
                            
                            if (people == nil || ([people count] == 0)) {
                                NSLog(@"SLSAppDelegate:didFinishLaunchingWithOptions: Adding entry for iPhone Simulator to AddressBook.");
                            
                                // Let's add an entry for the iPhone Simulator.
                                CFErrorRef error = NULL;
                                ABAddressBookRef iPhoneAddressBook = ABAddressBookCreateWithOptions(NULL, &error);
                                
                                ABRecordRef newPerson = ABPersonCreate();
                                ABRecordSetValue(newPerson, kABPersonFirstNameProperty, @"iPhone", &error);
                                ABRecordSetValue(newPerson, kABPersonLastNameProperty, @"Simulator", &error);
                                
                                ABMutableMultiValueRef multiPhone = ABMultiValueCreateMutable(kABMultiStringPropertyType);
                                ABMultiValueAddValueAndLabel(multiPhone, @"1-412-555-5555", kABPersonPhoneMobileLabel, NULL);
                                ABRecordSetValue(newPerson, kABPersonPhoneProperty, multiPhone, nil);
                                ABAddressBookAddRecord(iPhoneAddressBook, newPerson, &error);
                                if (!ABAddressBookSave(iPhoneAddressBook, &error)) {
                                    NSLog(@"SLSAppDelegate:didFinishLaunchingWithOptions: ABAddressBookSave: error!");
                                }
                                
                                CFRelease(multiPhone);
                            }
                            CFRelease(address_book);
                        }
#endif
                        
#if 0  // SIMULATOR HACK:
                        // Send a copy of our high precision symmetric key to storage, so any "iPhone Simulator" consumers can get it (as the simulator can not send SMS!).
                        
                        // XXX No longer necessary, as it's the file-store URL that's sent via SMS.
                        
                        if ([master_controller.symmetric_keys_controller count] > 0) {
                            
                            NSLog(@"SLSAppDelegate:didFinishLaunchingWithOptions: symmetric keys: %lu.", (unsigned long)master_controller.symmetric_keys_controller.count);
                            
                            NSData* sym_key = [master_controller.symmetric_keys_controller objectForKey:[NSNumber numberWithInt:SKC_PRECISION_HIGH]];
                            NSString* sym_key_b64 = [sym_key base64EncodedString];
                            NSString* err_msg = [master_controller.our_data amazonS3Upload:sym_key_b64 bucketName:@"aka-tmp-sls-iphone-simulator" filename:@"symmetric-key.b64"];
                            if (err_msg != nil) {
                                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"SLSAppDelegate:didFinishLaunchingWithOptions:" message:err_msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                                [alert show];
                            }
                        }
#endif
#if 0  // SIMULATOR HACK:
                        {
                            // Setup one fake consumer (actually ourselves as the simulator).
                            Principal* tmp_consumer = [[Consumer alloc] initWithIdentity:@"iPhone Simulator"];
                            tmp_consumer.precision = [NSNumber numberWithInt:SKC_PRECISION_HIGH];
                            NSMutableDictionary* deposit = [[NSMutableDictionary alloc] initWithCapacity:5];
                            [PersonalDataController setDeposit:deposit type:@"SMS"];
                            [PersonalDataController setDeposit:deposit phoneNumber:@"4126547499"];
                            tmp_consumer.deposit = deposit;
                            
                            // Note, we don't need to set the public key now, as we'll get it from the key chain when we need.
                            
                            if (![master_controller.consumer_list_controller containsObject:tmp_consumer]) {
                                // We don't have ourselves, yet, so add it (i.e., we didn't load it in via state).
                                
                                NSLog(@"SLSAppDelegate:didFinishLaunchingWithOptions: DEBUG: Adding bogus Consumer: %s.", [[tmp_consumer absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                                
                                NSString* error_msg = [master_controller.consumer_list_controller addConsumer:tmp_consumer];
                                if (error_msg != nil)
                                    NSLog(@"SLSAppDelegate:didFinishLaunchingWithOptions: DEBUG: Adding bogus Consumer failed: %s.", [error_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                            }
                        }
#endif
                    } else if ([ui_device.name caseInsensitiveCompare:@"mistwraith"] == NSOrderedSame) {
                        if (kDebugLevel > 0)
                            NSLog(@"SLSAppDelegate:didFinishLaunchingWithOptions: Found device mistwraith.");
#if 0  // SIMULATOR HACK:
                        {
                            // Send a copy of our high precision symmetric key to storage, so the consumer on the simulator can get it (as the simulator can not read SMS!).
                            
                            // XXX Not needed, file-store is sent via SMS!
                            
                            if (master_controller.symmetric_keys_controller != nil && [master_controller.symmetric_keys_controller count] > 0) {
                                NSData* sym_key = [master_controller.symmetric_keys_controller objectForKey:[NSNumber numberWithInt:SKC_PRECISION_HIGH]];
                                NSString* sym_key_b64 = [sym_key base64EncodedString];
                                NSString* err_msg = [master_controller.our_data amazonS3Upload:sym_key_b64 bucketName:@"aka-tmp-sls-mistwraith" filename:@"symmetric-key.b64"];
                                if (err_msg != nil) {
                                    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"SLSAppDelegate:didFinishLaunchingWithOptions:" message:err_msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                                    [alert show];
                                }
                            }
                        }
#endif
#if 1  // SIMULATOR HACK:
                        {
                            // Send a copy of our public key to storage, so the consumer on the simulator can get it (as the simulator can not scan the encoded key!).
                            
                            if (master_controller.our_data != nil && master_controller.our_data.identity != nil && [master_controller.our_data.identity length] > 0) {
                                // Setup application tag for key-chain query and attempt to get a key.
                                NSString* public_key_identity = [NSString stringWithFormat:@"Andrew K. Adams.publickey"];
                                NSData* application_tag = [public_key_identity dataUsingEncoding:[NSString defaultCStringEncoding]];
                                NSData* public_key = nil;
                                NSString* error_msg = [PersonalDataController queryKeyData:application_tag keyData:&public_key];
                                if (error_msg != nil)
                                    NSLog(@"SLSAppDelegate:didFinishLaunchingWithOptions: queryKeyData() failed: %s.", [error_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                                NSString* public_key_b64 = [public_key base64EncodedString];
                                error_msg = [master_controller.our_data amazonS3Upload:public_key_b64 bucketName:@"aka-tmp-sls-mistwraith" filename:@"public-key.b64"];
                                if (error_msg != nil) {
                                    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"SLSAppDelegate:didFinishLaunchingWithOptions:" message:error_msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                                    [alert show];
                                }
                            }
                        }
#endif
#if 0  // For Debugging: key-chain testing!
                        {
                            // TODO(aka) See if we can add a key.
                            Principal* tmp_consumer = [[Consumer alloc] initWithIdentity:@"Key Test"];
                            
                            // Setup application tag for key-chain query and attempt to get a key.
                            NSString* public_key_identity = [NSString stringWithFormat:@"Andrew K. Adams.publickey"];
                            NSData* application_tag = [public_key_identity dataUsingEncoding:[NSString defaultCStringEncoding]];
                            NSData* public_key = nil;
                            NSString* error_msg = [PersonalDataController queryKeyData:application_tag keyData:&public_key];
                            if (error_msg != nil)
                                NSLog(@"SLSAppDelegate:didFinishLaunchingWithOptions: queryKeyData() failed: %s.", [error_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                            if (public_key != nil) {
                                // Okay, key save worked, so now delete the key.
                                [PersonalDataController deleteKeyRef:application_tag];
#if 0
                                [tmp_consumer setPublicKey:public_key];
                                NSLog(@"SLSAppDelegate:didFinishLaunchingWithOptions: setPublicKey() test status: %d.", ([tmp_consumer publicKeyRef] == NULL) ? false : true);
#endif
                            }
                        }
#endif
                    } else if ([ui_device.name caseInsensitiveCompare:@"monita"] == NSOrderedSame) {
                        if (kDebugLevel > 2)
                            NSLog(@"SLSAppDelegate:didFinishLaunchingWithOptions: TOOD(aka) Found device monita.");
                    } else {
                        if (kDebugLevel > 0)
                            NSLog(@"SLSAppDelegate:didFinishLaunchingWithOptions: unknown device name: %s.", [ui_device.name cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                    }
                    
                    if (kDebugLevel > 0)
                        NSLog(@"SLSAppDelegate:didFinishLaunchingWithOptions: Provider VC using identity of %s, file store service of %s.", [master_controller.our_data.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [[PersonalDataController absoluteStringFileStore:master_controller.our_data.file_store] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                    
                } else if ([navItem isMemberOfClass:[ConsumerMasterViewController class]]) {
                    if (kDebugLevel > 3)
                        NSLog(@"Found ConsumerMasterViewController Class at index %d:%d!", i, k);
                    
                    // Setup the data members within the Consumer's master controller.
                    ConsumerMasterViewController* master_controller = (ConsumerMasterViewController*)navItem;
                    [master_controller loadState];
                    
                    // For debugging: See whose phone this is, and load in temporary keys.
                    if (kDebugLevel > 3)
                        NSLog(@"SLSAppDelegate:didFinishLaunchingWithOptions: Consumer loading static information based on device name!");
                    
                    UIDevice* ui_device = [UIDevice currentDevice];
                    if (ui_device.name == nil) {
                        NSLog(@"SLSAppDelegate:didFinishLaunchingWithOptions: nil device name.");
                    } else if ([ui_device.name caseInsensitiveCompare:@"iPhone Simulator"] == NSOrderedSame) {
                        if (kDebugLevel > 2)
                            NSLog(@"SLSAppDelegate:didFinishLaunchingWithOptions: Found device iPhone Simulator.");
#if 0  // SIMULATOR HACK:
                        {
                            // XXX I think this is done via the "track self" button ...
                            
                            // Setup a bogus provider (of ourselves) for the simulator.
                            Principal* tmp_provider = [[Provider alloc] initWithIdentity:@"iPhone Simulator"];
                            
                            // Get our bogus symmetric keys (supposedly deposited in Provider section!).
                            NSURL* key_url = [[NSURL alloc] initWithString:@"https://s3.amazonaws.com/aka-tmp-sls-iphone-simulator/symmetric-key.b64"];
                            NSError* status = nil;
                            NSString* sym_key_b64 = [[NSString alloc] initWithContentsOfURL:key_url encoding:[NSString defaultCStringEncoding] error:&status];
                            if (status) {
                                NSString* err_msg = [[status localizedDescription] stringByAppendingString:([status localizedFailureReason] ? [status localizedFailureReason] :@"")];
                                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"SLSAppDelegate:didFinishLaunchingWithOptions: initWithContentsOfURL()" message:err_msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                                [alert show];    
                            } else {
                                NSData* sym_key = [NSData dataFromBase64String:sym_key_b64];
                                [tmp_provider setKey:sym_key];
                                
                                // Setup the file store as us, as a Provider (using high precision).
                                NSString* bucket_name = [[NSString alloc] initWithFormat:@"%s3", [tmp_provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
                                NSString* file_store_str = [[NSString alloc] initWithFormat:@"https://s3.amazonaws.com/%s/location-data.b64", [[PersonalDataController hashMD5String:bucket_name] cStringUsingEncoding:[NSString defaultCStringEncoding]]];
                                NSURL* file_store = [[NSURL alloc] initWithString:file_store_str];
                                [tmp_provider setFile_store:file_store];
                                
                                if (![master_controller.provider_list_controller containsObject:tmp_provider]) {
                                    NSLog(@"SLSAppDelegate:didFinishLaunchingWithOptions: Bogus Provider not set, so adding ourselves!");
                                    
                                    // We don't have our bogus provider, so add it.
                                    NSString* error_msg = [master_controller.provider_list_controller addProvider:tmp_provider];
                                    if (error_msg != nil) {
                                        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"SLSAppDelegate:didFinishLaunchingWithOptions: addProvider()" message:error_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                                        [alert show];
                                    }
                                }
                            } 
                        }
#endif
#if 0  // SIMULATOR HACK:
                        {
                            // Setup a bogus provider (of my cell phone) for the simulator.
                            Principal* tmp_provider = [[Provider alloc] initWithIdentity:@"Andrew K. Adams"];
                            
                            // Get my symmetric keys (hopefully deposited by now from upabove)!
                            NSURL* key_url = [[NSURL alloc] initWithString:@"https://s3.amazonaws.com/aka-tmp-sls-mistwraith/symmetric-key.b64"];  // use my cell phone!
                            NSError* status = nil;
                            NSString* sym_key_b64 = [[NSString alloc] initWithContentsOfURL:key_url encoding:[NSString defaultCStringEncoding] error:&status];
                            if (status) {
                                NSString* err_msg = [[status localizedDescription] stringByAppendingString:([status localizedFailureReason] ? [status localizedFailureReason] :@"")];
                                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"SLSAppDelegate:didFinishLaunchingWithOptions: initWithContentsOfURL()" message:err_msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                                [alert show];    
                            } else {
                                NSData* sym_key = [NSData dataFromBase64String:sym_key_b64];
                                [tmp_provider setKey:sym_key];
                                NSString* bucket_name = [[NSString alloc] initWithFormat:@"%s3", [tmp_provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
                                NSString* file_store_str = [[NSString alloc] initWithFormat:@"https://s3.amazonaws.com/%s/location-data.b64", [[PersonalDataController hashMD5String:bucket_name] cStringUsingEncoding:[NSString defaultCStringEncoding]]];
                                NSURL* file_store = [[NSURL alloc] initWithString:file_store_str];
                                [tmp_provider setFile_store:file_store];
                                
                                // No need to set the public key, as we'll get it from the key-chain when we need it.
                                
                                if (![master_controller.provider_list_controller containsObject:tmp_provider]) {
                                    NSLog(@"SLSAppDelegate:didFinishLaunchingWithOptions: XXX Bogus Provider not set, so adding ourselves!");
                                    
                                    // We don't have our bogus provider, so add it.
                                    NSString* error_msg = [master_controller.provider_list_controller addProvider:tmp_provider];
                                    if (error_msg != nil) {
                                        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"SLSAppDelegate:didFinishLaunchingWithOptions: addProvider()" message:error_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                                        [alert show];
                                    }
                                }
                            } 
                        }
#endif
                    } else if ([ui_device.name caseInsensitiveCompare:@"mistwraith"] == NSOrderedSame) {
                        if (kDebugLevel > 0)
                            NSLog(@"SLSAppDelegate:didFinishLaunchingWithOptions: Found device mistwraith.");
#if 0  // SIMULATOR HACK:
                        {
                            // Add myself as a provider.  TODO(aka) This should really happen for free (or with a button click).  But I don't know how to get the Consumer our symmetric key!  What if we only had one PersonalDataController?
                            
                            NSLog(@"SLSAppDelegate:didFinishLaunchingWithOptions: TOOD(aka) XXX Why do I need this now?  Can't I just send myself an SMS as the Provider?");
                            
                            Principal* tmp_provider = [[Provider alloc] initWithIdentity:@"Andrew K. Adams"];
                            
                            // Get our bogus symmetric key (should have been deposited in Provider section!).
                            NSURL* key_url = [[NSURL alloc] initWithString:@"https://s3.amazonaws.com/aka-tmp-sls-shadow/symmetric-key.b64"];
                            NSError* status = nil;
                            NSString* sym_key_b64 = [[NSString alloc] initWithContentsOfURL:key_url encoding:[NSString defaultCStringEncoding] error:&status];
                            if (status) {
                                NSString* err_msg = [[status localizedDescription] stringByAppendingString:([status localizedFailureReason] ? [status localizedFailureReason] :@"")];
                                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"SLSAppDelegate:didFinishLaunchingWithOptions: initWithContentsOfURL()" message:err_msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                                [alert show];    
                            } else {
                                NSData* sym_key = [NSData dataFromBase64String:sym_key_b64];
                                [tmp_provider setKey:sym_key];
                                
                                // Setup the file store as us, as the Provider (using high precision).
                                NSString* bucket_name = [[NSString alloc] initWithFormat:@"%s3", [tmp_provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
                                NSString* file_store_str = [[NSString alloc] initWithFormat:@"https://s3.amazonaws.com/%s/location-data.b64", [[PersonalDataController hashMD5String:bucket_name] cStringUsingEncoding:[NSString defaultCStringEncoding]]];
                                NSURL* file_store = [[NSURL alloc] initWithString:file_store_str];
                                [tmp_provider setFile_store:file_store];
                                
                                if (![master_controller.provider_list_controller containsObject:tmp_provider]) {
                                    NSLog(@"SLSAppDelegate:didFinishLaunchingWithOptions: XXX Bogus Provider not set, so adding ourselves!");
                                    
                                    // We don't have our bogus provider, so add it.
                                    NSString* error_msg = [master_controller.provider_list_controller addProvider:tmp_provider];
                                    if (error_msg != nil) {
                                        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"SLSAppDelegate:didFinishLaunchingWithOptions: addProvider()" message:error_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                                        [alert show];
                                    }
                                }
                            }
                        }
#endif
                    } else if ([ui_device.name caseInsensitiveCompare:@"monita"] == NSOrderedSame) {
                        NSLog(@"SLSAppDelegate:didFinishLaunchingWithOptions: TOOD(aka) Found device monita.");
                    } else {
                        NSLog(@"SLSAppDelegate:didFinishLaunchingWithOptions: unknown device name: %s.", [ui_device.name cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                    }
                    
                    if (kDebugLevel > 0)
                        NSLog(@"SLSAppDelegate:didFinishLaunchingWithOptions: Consumer View controller using identity of %s, deposit of %s, public key hash: %s.", [master_controller.our_data.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [[PersonalDataController absoluteStringDeposit:master_controller.our_data.deposit] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[PersonalDataController hashAsymmetricKey:[master_controller.our_data getPublicKey]] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                  } else {
                    NSLog(@"Unknown viewController Class at index %d:%d!", i, k);
                }
                
                k++;
            }
        } else {
            NSLog(@"Unknown viewController Class at index %d!", i);
        }
        
        i++;
    }
    
    [tabController setSelectedIndex:1];  // set default view to Consumer mode
    
    return YES;
}

- (void) applicationWillResignActive:(UIApplication *)application {
    NSLog(@"SLSAppDelegate:applicationWillResignActive: called.");
    
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void) applicationDidEnterBackground:(UIApplication*)application {
    NSLog(@"SLSAppDelegate:applicationDidEnterBackground: called.");
    
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void) applicationWillEnterForeground:(UIApplication*)application {
    NSLog(@"SLSAppDelegate:applicationWillEnterForeground: called.");
    
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void) applicationDidBecomeActive:(UIApplication*)application {
    NSLog(@"SLSAppDelegate:applicationDidBecomeActive: called.");
    
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    NSLog(@"SLSAppDelegate:applicationDidBecomeActive: TODO(aka) Need to figure out how to refresh Consumer mode screen!.");
}

- (void) applicationWillTerminate:(UIApplication*)application {
    NSLog(@"SLSAppDelegate:applicationWillTerminate: called.");
    
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    UITabBarController* tabController = (UITabBarController*)self.window.rootViewController;
    
    // Check each viewController, de-initializing our data controllers as we need ...
    int i = 0;
    for (id tabItem in tabController.viewControllers) {
        if ([tabItem isMemberOfClass:[ProviderMasterViewController class]]) {
            NSLog(@"Found ProviderMasterViewController Class at index %d!", i);
        } else if ([tabItem isMemberOfClass:[ConsumerMasterViewController class]]) {
            NSLog(@"Found ConsumerMasterViewController Class at index %d!", i);
        } else if ([tabItem isMemberOfClass:[UINavigationController class]]) {
            //NSLog(@"UINavigationController Class at index %d!", i);
            
            // Look inside the NavigationController's viewControllers.
            UINavigationController* navController = (UINavigationController*)tabItem;
            int k = 0;
            for (id navItem in navController.viewControllers) {
                if ([navItem isMemberOfClass:[ProviderMasterViewController class]]) {
                    NSLog(@"Found ProviderMasterViewController Class at index %d:%d!", i, k);
                    
                    ProviderMasterViewController* master_controller = (ProviderMasterViewController*)navItem;
                    
                    // If we started location services, stop them.
                    [master_controller.location_controller.locationMgr stopMonitoringSignificantLocationChanges];
                } else if ([navItem isMemberOfClass:[ConsumerMasterViewController class]]) {
                    NSLog(@"Found ConsumerMasterViewController Class at index %d:%d!", i, k);
                    
                    //ConsumerMasterViewController* master_controller = (ConsumerMasterViewController*)navItem;
                } else {
                    NSLog(@"Unknown viewController Class at index %d:%d!", i, k);
                }
                
                k++;
            }
        } else {
            NSLog(@"Unknown viewController Class at index %d!", i);
        }
        
        i++;
    }
}

- (BOOL) application:(UIApplication *)application handleOpenURL:(NSURL*)url {
    NSLog(@"SLSAppDelegate:handleOpenURL: called.");
    
    if (!url)
        return NO;
    
    NSString* incoming_url_str = [url absoluteString];  // grab the incoming URL (as a string)
    
    // See if we already have a URL message waiting to be processed.
    NSString* queued_url_str = nil;
    queued_url_str = [[NSUserDefaults standardUserDefaults] objectForKey:@"url"];
    if (queued_url_str != nil) {
        // TODO(aka) We can either make the object an array or add another key ...
        NSString* message = @"TODO(aka) There is already a URL waiting to be processed within the NSUserDefaults dictionary!";
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"SLSAppDelegate:handleOpenURL:" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];

        return NO;
    }

    // All fine, nothing in the queue already.
    [[NSUserDefaults standardUserDefaults] setObject:incoming_url_str forKey:@"url"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return YES;
}

- (void) application:(UIApplication*)application didReceiveLocalNotification:(UILocalNotification*)notification {
    NSLog(@"SLSAppDelegate:didReceiveLocalNotification: %@", notification.userInfo);
    
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Alarm" message:notification.alertBody delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
    application.applicationIconBadgeNumber = 0;
}

@end

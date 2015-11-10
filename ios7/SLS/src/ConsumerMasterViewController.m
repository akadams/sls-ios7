//
//  ConsumerMasterViewController.m
//  SLS
//
//  Created by Andrew K. Adams on 11/19/13.
//  Copyright (c) 2013 Andrew K. Adams. All rights reserved.
//

#import <CommonCrypto/CommonCryptor.h>

#import "NSData+Base64.h"

#import "ConsumerMasterViewController.h"
#import "ConsumerDataViewController.h"         // needed for segue & unwind
#import "AddProviderViewController.h"          // needed for segue & unwind
#import "AddProviderCTViewController.h"        // needed for unwind
#import "AddProviderHCCViewController.h"       // needed for unwind
#import "KeyBundleController.h"
#import "LocationBundleController.h"
#import "Principal.h"
#import "ProviderAnnotation.h"

#import "sls-url-defines.h"
#import "security-defines.h"


static const int kDebugLevel = 2;

// ACCESS_GROUPS:
static const char* kAccessGroupHCC = KC_ACCESS_GROUP_HCC;

static const char* kPathFileStore = URI_PATH_FILE_STORE;
static const char* kPathHCCMsg2 = URI_PATH_HCC_MSG2;  // provider's HCC encrypted nonce challenge
static const char* kPathHCCMsg4 = URI_PATH_HCC_MSG4;  // provider's HCC pubkey, identity-token & encrypted secret-question
static const char* kPathHCCMsg6 = URI_PATH_HCC_MSG6;  // provider's HCC encrypted nonce response & secret-question reply
static const char* kPathHCCMsg8 = URI_PATH_HCC_MSG8;  // provider's HCC encrypted deposit
static const char* kPathHCCMsg1 = URI_PATH_HCC_MSG1;  // consumer's HCC pubkey & identity-token

static const char kPathDelimiter = URI_PATH_DELIMITER;

static const char* kQueryKeyID = URI_QUERY_KEY_ID;
static const char* kQueryKeyPubKey = URI_QUERY_KEY_PUB_KEY;
static const char* kQueryKeyChallenge = URI_QUERY_KEY_CHALLENGE;
static const char* kQueryKeyResponse = URI_QUERY_KEY_CHALLENGE_RESPONSE;
static const char* kQueryKeySecretQuestion = URI_QUERY_KEY_SECRET_QUESTION;
static const char* kQueryKeyAnswer = URI_QUERY_KEY_SQ_ANSWER;
static const char* kQueryKeyDeposit = URI_QUERY_KEY_DEPOSIT;

static const char* kQueryKeyFileStoreURL = URI_QUERY_KEY_FS_URL;
static const char* kQueryKeyKeyBundleURL = URI_QUERY_KEY_KB_URL;
static const char* kQueryKeyTimeStamp = URI_QUERY_KEY_TIME_STAMP;
static const char* kQueryKeySignature = URI_QUERY_KEY_SIGNATURE;

static const char* kDownloadDataFilename = "fetch_data_toggle.txt";  // state filename on local disk

static const int kHistoryLogSize = 7;  // TODO(aka) need to add to a define file

static const char kArraySerializerDelimiter = ' ';  // TODO(aka) need to add to a define file

static const char* kAlertButtonCancelPairingMessage = "No, cancel pairing!";
static const char* kAlertButtonContinuePairingMessage = "Yes, continue with pairing.";

static const char* kStateDataUpdate = "stateDataUpdate";  // TODO(aka) need to add to a define file


@interface ConsumerMasterViewController ()
@end

@implementation ConsumerMasterViewController

#pragma mark - Local variables
@synthesize our_data = _our_data;
@synthesize provider_list = _provider_list;
@synthesize potential_providers = _potential_providers;
@synthesize potential_provider = _potential_provider;
@synthesize map_view = _map_view;
@synthesize fetch_data_toggle = _fetch_data_toggle;

#pragma mark - Initialization

- (id) init {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerMVC:init: called.");
    
    self = [super init];
    if (self) {
        _our_data = nil;
        _provider_list = nil;
        _potential_providers = nil;
        _potential_provider = nil;
        _fetch_data_toggle = true;
        
        return self;
    }
    
    return nil;
}

- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerMVC:initWithNibName:bundle: called, but not implemented.");
    
    self = [super initWithNibName:nib_name_or_nil bundle:nib_bundle_or_nil];
    if (self) {
        // Custom initialization
        _our_data = nil;
        _provider_list = nil;
        _potential_providers = nil;
        _potential_provider = nil;
        _fetch_data_toggle = true;
    }
    
    return self;
}

- (void) loadState {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerMVC:loadState: called.");
    
    if (_our_data == nil) {
        if (kDebugLevel > 2)
            NSLog(@"ConsumerMVC:loadState: _our_data is nil.");
        
        _our_data = [[PersonalDataController alloc] init];
    }
    
    // Populate (or generate) the data associated with our class' data members' controllers.
    
    [_our_data loadState];  // note, if state was not previously saved, we could just have a bunch of nils
    
    // Build our provider list and potential (via HCC) providers controllers.
    _provider_list = [[ProviderListController alloc] init];
    [_provider_list loadState];
    
    NSString* potential_providers_filename = [NSString stringWithFormat:@"%s.consumer", HCC_PRINCIPALS_STATE_FILENAME];
    NSDictionary* tmp_potential_providers = [PersonalDataController loadStateDictionary:potential_providers_filename];
    if (tmp_potential_providers != nil && [tmp_potential_providers count] > 0)
        _potential_providers = [tmp_potential_providers mutableCopy];
    
    // Figure out if location sharing was turned on or not.
    NSString* tmp_string = [PersonalDataController loadStateString:[NSString stringWithCString:kDownloadDataFilename encoding:[NSString defaultCStringEncoding]]];
    _fetch_data_toggle = [tmp_string boolValue];
}

#pragma mark - View management

- (void) viewDidLoad {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerMVC:viewDidLoad: called.");
    
    [super viewDidLoad];
    
	// Do any additional setup after loading the view, typically from a nib.
    
#if 0  // For Debugging: REGEX
    NSString* foobar = @"foo=bar=";
    /*
     NSError* error = NULL;
     NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"=" options:NSRegularExpressionCaseInsensitive error:&error];
     NSTextCheckingResult* match = [regex firstMatchInString:foobar options:0 range:NSMakeRange(0, [foobar length])];
     if (match) {
     NSRange foo_range = [match rangeAtIndex:1];
     NSRange bar_range = [match rangeAtIndex:2];
     NSString* foo = [foobar substringWithRange:NSMakeRange(0, foo_range.location)];
     NSLog(@"ConsumerMVC:viewDidLoad: DEBUG: foobar length %d, foo range location: %d, foo length %d, bar range location: %d.", [foobar length], foo_range.location, [foo length], bar_range.location);
     //NSString* bar = [foobar substringWithRange:NSMakeRange(bar_range.location, -1)];
     NSString* bar = @"";
     NSLog(@"ConsumerMVC:viewDidLoad: DEBUG: foo: %s, bar: %s, foobar: %s.", [foo cStringUsingEncoding:[NSString defaultCStringEncoding]], [bar cStringUsingEncoding:[NSString defaultCStringEncoding]], [foobar cStringUsingEncoding:[NSString defaultCStringEncoding]]);
     }
     */
    
    NSRange delimiter = [foobar rangeOfString:@"="];
    NSString* foo = [foobar substringWithRange:NSMakeRange(0, delimiter.location)];
    NSString* bar = [foobar substringWithRange:NSMakeRange(delimiter.location + 1, ([foobar length] - delimiter.location) - 1)];
    NSLog(@"ConsumerMVC:viewDidLoad: DEBUG: foo: %s, bar: %s, foobar: %s.", [foo cStringUsingEncoding:[NSString defaultCStringEncoding]], [bar cStringUsingEncoding:[NSString defaultCStringEncoding]], [foobar cStringUsingEncoding:[NSString defaultCStringEncoding]]);
#endif
}

- (void) viewDidAppear:(BOOL)animated {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerMVC:viewDidAppear: called.");
    
    [super viewDidAppear:animated];
    
    // Call configureView: to get the work done (note, this sets a timer for updateAllProviderData:).
    [self configureView:true];  // first time in, set the map focus
}

/*
// XXXX Test to fix unwind to segues ...
- (UIViewController*) viewControllerForUnwindSegueAction:(SEL)action fromViewController:(UIViewController*)fromViewController withSender:(id)sender {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerMVC:viewControllerForUnwindSegueAction: called.");
    
    
    for (UIViewController* vc in self.childViewControllers) {
        // Always use -canPerformUnwindSegueAction:fromViewController:withSender:
        // to determine if a view controller wants to handle an unwind action.
        if ([vc canPerformUnwindSegueAction:action fromViewController:fromViewController withSender:sender])
            return vc;
    }
    
    return [super viewControllerForUnwindSegueAction:action fromViewController:fromViewController withSender:sender];
}
*/

- (void) configureView:(BOOL)set_map_focus {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerMVC:configureView: called.");
    
    static bool first_time_in = true;
    static bool identity_help = true;
    static bool asymmetric_keys_help = true;
    static bool deposit_help = true;
    static bool pairing_help = true;
    
    if (self.isViewLoaded && self.view.window) {
        // USER-HELP:
        NSString* help_msg = nil;
        if (_our_data == nil || _our_data.identity == nil || [_our_data.identity length] == 0) {
            if (first_time_in) {
                help_msg = [NSString stringWithFormat:@"A \"Consumer\" is one that views, tracks or consumes others' location data.  You are currently in the CONSUMER's VIEW."];
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Consumer Help" message:help_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
            } else if (identity_help) {
                help_msg = [NSString stringWithFormat:@"In order to view others' location data, you first must set your identity (click on the Config button)."];
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Consumer Help" message:help_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
                identity_help = false;
            }
        } else if (_our_data.privateKeyRef == NULL || _our_data.publicKeyRef == NULL) {
            if (asymmetric_keys_help) {
                help_msg = [NSString stringWithFormat:@"In order to view others' secure data, you must generate a private/public key pair (click on the Config button)."];
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Consumer Help" message:help_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
                asymmetric_keys_help = false;
            }
        } else if (_our_data.deposit == nil || [_our_data.deposit count] == 0) {
            if (deposit_help) {
                help_msg = [NSString stringWithFormat:@"In order to pair with others, you must have an out-of-band deposit (click on the Config button)."];
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Consumer Help" message:help_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
                deposit_help = false;
            }
        } else if (_provider_list == nil || [_provider_list countOfList] == 0) {
            if (pairing_help) {
                help_msg = [NSString stringWithFormat:@"In order to view someone's location, you must first pair with them (click on the + button)."];
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Consumer Help" message:help_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
                pairing_help = false;
            }
        }
    }
    
#if 0  // ENCRYPTION_TEST:
    static bool encryption_test = true;
    if (_our_data.privateKeyRef != NULL && _our_data.publicKeyRef != NULL && encryption_test) {
        int challenge = arc4random() % 9999;  // get a four digit challenge
        NSString* challenge_str = [NSString stringWithFormat:@"%d", challenge];
        NSString* encrypted_challenge = nil;
        NSString* err_msg = [PersonalDataController asymmetricEncryptString:challenge_str publicKeyRef:_our_data.publicKeyRef encryptedString:&encrypted_challenge];
        if (err_msg != nil) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Provider Help" message:err_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
            [alert show];
        } else {
            if (kDebugLevel > 0)
                NSLog(@"ConsumerMVC:configureView: Attempting to decrypt (%ldB): %@.", (unsigned long)[encrypted_challenge length], encrypted_challenge);
            
            NSString* decrypted_challenge = nil;
            err_msg = [PersonalDataController asymmetricDecryptString:encrypted_challenge privateKeyRef:_our_data.privateKeyRef string:&decrypted_challenge];
            if (err_msg != nil) {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Consumer Help" message:err_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
            } else {
                if ([challenge_str compare:decrypted_challenge] == NSOrderedSame) {
                    help_msg = [NSString stringWithFormat:@"Asymmetric encryption test succeeded."];
                    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Consumer Help" message:help_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                    [alert show];
                } else {
                    NSString* failure_msg = [NSString stringWithFormat:@"Asymmetric encryption test failed: %@ != %@.", challenge_str, decrypted_challenge];
                    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Consumer Help" message:failure_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                    [alert show];
                }
            }
        }
        encryption_test = false;
    }
#endif
    
    // Refresh UIMapView.  TODO(aka) What are we doing here?  Clearing all pins?
    NSMutableArray* annotation_list = [[NSMutableArray alloc] init];
    for (id annotation in _map_view.annotations) {
        if (annotation != _map_view.userLocation) {
            [annotation_list addObject:annotation];  // collect all our pins
        }
    }
    [_map_view removeAnnotations:annotation_list];
    
    NSLog(@"ConsumerMVC:configureView: TODO(aka) We need to center map on current location, if first_time_in is set!");
    
    CLLocationCoordinate2D map_focus_location = [self plotProviderLocations:nil];  // attempt to plot all providers
    
    if (set_map_focus) {
        if (kDebugLevel > 0)
            NSLog(@"ConsumerMVC:configureView: using center lon: %f, lat: %f.", map_focus_location.longitude, map_focus_location.latitude);
        
        [_map_view setCenterCoordinate:map_focus_location animated:true];
    }
    
    /*  TODO(aka) Instead of using setCenterCoordinate, here's a way using visibleRect:
     MKMapRect current_view = [self plotProviderLocations:nil];  // attempt to plot all providers
     
     // Position the map so that all overlays and annotations are visible on screen.
     if (!MKMapRectEqualToRect(current_view, MKMapRectNull)) {
     if (kDebugLevel > 1)
     NSLog(@"ConsumerMVC:configureView: focus set to: .");
     _map_view.visibleMapRect = current_view;
     }
     */
    
    // See if we have any new SLS URLs hanging around in NSUserDefaults.
    NSString* err_msg = [self checkNSUserDefaults];
    if (err_msg != nil) {
        NSString* msg = [[NSString alloc] initWithFormat:@"ConsumerMasterVC:configureView: %s.", [err_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        UILocalNotification* notice = [[UILocalNotification alloc] init];
        notice.alertBody = msg;
        notice.alertAction = @"Show";
        [[UIApplication sharedApplication] presentLocalNotificationNow:notice];
    }
    
    // Finally, setup a periodic alarm for calling updateAllProviderData: (for fetching provider history logs).
    if (first_time_in) {
        // We want to finish loading before any network fetches, but everyone's next-timer is now, hence, we force a default wait of 60s the first time in to this routine!
        
        first_time_in = false;
        
        if (kDebugLevel > 0)
            NSLog(@"ConsumerMVC:configureView: setting timer for 60s.");
        
        NSTimeInterval timeout = 60.0;
        [NSTimer scheduledTimerWithTimeInterval:timeout target:self selector:@selector(updateAllProviderData) userInfo:nil repeats:NO];
    } else {
        [self setTimerForFetchingData];  // figure out next time-out via Provider's meta-data
    }
}

- (CLLocationCoordinate2D) plotProviderLocations:(Principal*)sole_provider {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerMVC:plotProviderLocations: called.");
    
    // Get an arbitrary center (so we have something to focus on in lieu of a provider).
    CLLocationCoordinate2D center_map;   // set it to the center of US (TODO(aka) move this to @interface!)
	center_map.latitude = 37.250556;
	center_map.longitude = -96.358333;
    
    NSLog(@"ConsumerMVC:plotProviderLocations: TODO(aka) How do we degrade history via color or diffusion?");
    
    // Get the location data we currently have for all providers ...
    for (int i = 0; i < [_provider_list countOfList]; ++i) {
        // Get the provider's information.
        Principal* provider = [_provider_list objectInListAtIndex:i];
        
        // See if we are only to operate on a single provider.
        if (sole_provider != nil) {
            if (![provider isEqual:sole_provider])
                if (kDebugLevel > 1)
                    NSLog(@"ConsumerMVC:plotProviderLocations: sole_provider (%s) in use, skipping %s because they don't match.", [sole_provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            continue;
        }
        
        if (kDebugLevel > 2)
            NSLog(@"ConsumerMVC:plotProviderLocations: provider[%d]: %s, history-log size: %ld.", i, [[provider serialize] cStringUsingEncoding:[NSString defaultCStringEncoding]], (unsigned long)[provider.history_log count]);
        
        // Plot the location data history (in time-ascending order).
        CLLocation* previous_location = nil;
        //for (int j = 0; j < [provider.locations count]; ++j) {
        for (int j = (int)[provider.history_log count]; j > 0; --j) {
            NSUInteger index = j - 1;
            LocationBundleController* location_bundle = [provider.history_log objectAtIndex:index];
            CLLocation* new_location = [location_bundle generateCLLocation];
            
            // Figure out the bearing.
            if (previous_location == nil)
                previous_location = new_location;
            
            if (kDebugLevel > 3)
                NSLog(@"ConsumerMVC:plotProviderLocations: index %lu, loop counter %d, new location: %s (%fx%f %f), previous location: %s (%fx%f %f).", (unsigned long)index, j, [new_location.description cStringUsingEncoding:[NSString defaultCStringEncoding]], new_location.coordinate.longitude, new_location.coordinate.latitude, new_location.course, [previous_location.description cStringUsingEncoding:[NSString defaultCStringEncoding]], previous_location.coordinate.longitude, previous_location.coordinate.latitude, previous_location.course);
            
            // Math functions take radians, so convert degrees to radians for the values we need.
            double delta_lon = fabs(previous_location.coordinate.longitude - new_location.coordinate.longitude) * M_PI / 180.0;
            double lat_prev = previous_location.coordinate.latitude * M_PI / 180.0;
            double lat_new = new_location.coordinate.latitude * M_PI / 180.0;
            
            double y = sin(delta_lon) * cos(lat_new);
            double x = cos(lat_prev) * sin(lat_new) - sin(lat_prev) * cos(lat_new) * cos(delta_lon);
            double bearing_rads = atan2(y, x);
            
            // Finally, convert our bearing in radians to degrees, and normalize for 0 - 359.
            
            int bearing = ((int)(bearing_rads * 180.0 / M_PI) + 360) % 360;
            
            if (kDebugLevel > 1) {
                NSString* msg = [[NSString alloc] initWithFormat:@"%@ location[%lu]: %+.7fx%+.7f vs %+.7fx%+.7f, delta-lon: %fR, lat-prev: %fR, lat-new: %fR, y: %fR, x: %fR, bearing: %fR, bearing in degrees: %d, received course: %f",  [provider identity], (unsigned long)index, new_location.coordinate.longitude, new_location.coordinate.latitude, previous_location.coordinate.longitude, previous_location.coordinate.latitude,delta_lon, lat_prev, lat_new, y, x, bearing_rads, bearing, new_location.course];
                NSLog(@"ConsumerMVC:plotProviderLocations: %s.", [msg cStringUsingEncoding:[NSString defaultCStringEncoding]]);
#if 0
                if (index == 0 || index == 1) {
                    UILocalNotification* notice = [[UILocalNotification alloc] init];
                    notice.alertBody = msg;
                    notice.alertAction = @"Show";
                    [[UIApplication sharedApplication] presentLocalNotificationNow:notice];
                }
#endif
            }
            
            // Figure out which direction to pass our annotation delegate.
            NSString* image_filename = nil;
            NSString* reuse_id = nil;
            if (bearing >= 357 || bearing < 22) {
                // North.
                if (index == 0) {
                    image_filename = @"feet-north";
                    reuse_id = @"FeetNorth";
                } else if ((index % 2) == 0) {
                    image_filename = @"right-north";
                    reuse_id = @"RightNorth";
                    
                } else {
                    image_filename = @"left-north";
                    reuse_id = @"LeftNorth";
                }
            } else if (bearing >= 22 && bearing < 67) {
                // North-east.
                if (index == 0) {
                    image_filename = @"feet-north-east";
                    reuse_id = @"FeetNorthEast";
                } else if ((index % 2) == 0) {
                    image_filename = @"right-north-east";
                    reuse_id = @"RightNorthEast";
                    
                } else {
                    image_filename = @"left-north-east";
                    reuse_id = @"LeftNorthEast";
                }
            } else if (bearing >= 67 && bearing < 112) {
                // East.
                if (index == 0) {
                    image_filename = @"feet-east";
                    reuse_id = @"FeetEast";
                } else if ((index % 2) == 0) {
                    image_filename = @"right-east";
                    reuse_id = @"RightEast";
                } else {
                    image_filename = @"left-east";
                    reuse_id = @"LeftEast";
                }
            } else if (bearing >= 112 && bearing < 157) {
                // South-east.
                if (index == 0) {
                    image_filename = @"feet-south-east";
                    reuse_id = @"FeetSouthEast";
                } else if ((index % 2) == 0) {
                    image_filename = @"right-south-east";
                    reuse_id = @"RightSouthEast";
                } else {
                    image_filename = @"left-south-east";
                    reuse_id = @"LeftSouthEast";
                }
            } else if (bearing >= 157 && bearing < 202) {
                // South.
                if (index == 0) {
                    image_filename = @"feet-south";
                    reuse_id = @"FeetSouth";
                } else if ((index % 2) == 0) {
                    image_filename = @"right-south";
                    reuse_id = @"RightSouth";
                } else {
                    image_filename = @"left-south";
                    reuse_id = @"LeftSouth";
                }
            } else if (bearing >= 202 && bearing < 247) {
                // South-west.
                if (index == 0) {
                    image_filename = @"feet-south-west";
                    reuse_id = @"FeetSouthWest";
                } else if ((index % 2) == 0) {
                    image_filename = @"right-south-west";
                    reuse_id = @"RightSouthWest";
                } else {
                    image_filename = @"left-south-west";
                    reuse_id = @"LeftSouthWest";
                }
            } else if (bearing >= 247 && bearing < 292) {
                // West.
                if (index == 0) {
                    image_filename = @"feet-west";
                    reuse_id = @"FeetWest";
                } else if ((index % 2) == 0) {
                    image_filename = @"right-west";
                    reuse_id = @"RightWest";
                } else {
                    image_filename = @"left-west";
                    reuse_id = @"LeftWest";
                }
            } else if (bearing >= 292 && bearing < 337) {
                // North-west.
                if (index == 0) {
                    image_filename = @"feet-north-west";
                    reuse_id = @"FeetNorthWest";
                } else if ((index % 2) == 0) {
                    image_filename = @"right-north-west";
                    reuse_id = @"RightNorthWest";
                } else {
                    image_filename = @"left-north-west";
                    reuse_id = @"LeftNorthWest";
                }
            }
            
            ProviderAnnotation* annotation = [[ProviderAnnotation alloc] initWithIdentity:provider.identity coordinate:new_location.coordinate title:provider.identity subtitle:@"" index:index color:MKPinAnnotationColorPurple imageFilename:image_filename reuseID:reuse_id];
            
            // See if this provider gets the focus!
            if (index == 0 && provider.is_focus) {
                if (kDebugLevel > 2)
                    NSLog(@"ConsumerMVC:plotProviderLocations: center-map changed to lon: %f, lat: %f", center_map.longitude, center_map.latitude);

                center_map = new_location.coordinate;
                
                /* Alternate way using MKMapRect ...
                 MKMapPoint map_point = MKMapPointForCoordinate(new_location.coordinate);
                 focus_map_rect = MKMapRectMake(map_point.x, map_point.y, 0, 0);
                 */
                
                NSLog(@"ConsumerMVC:plotProviderLocations: TODO(aka) We need to figure out how to set the zoom appropriately!");
            }
            
            previous_location = new_location;
            
            if (kDebugLevel > 3)
                NSLog(@"ConsumerMVC:plotProviderLocations: calling UIMapView delegate addAnnotation() at index %lu.", (unsigned long)index);
            
            [_map_view addAnnotation:annotation];  // this will trigger the MKMapView delegate
        }  // for (int j = [provider.locations count]; j > 0; --j) {
    } // for (int i = 0; i < [_provider_list countOfList]; ++i) {
    
    return center_map;
}

# pragma mark - Memory management

- (void) didReceiveMemoryWarning {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerMVC:didReceiveMemoryWarning: called.");

    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

- (void) prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerMVC:prepareForSeque: called.");
    
    if (kDebugLevel > 1)
        NSLog(@"ConsumerMVC:prepareForSegue: our identity: %s, deposit: %s, public-key: %s.", [_our_data.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [[_our_data.deposit description] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[_our_data.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    if ([[segue identifier] isEqualToString:@"ShowConsumerDataViewID"]) {
        if (kDebugLevel > 1)
            NSLog(@"ConsumerMVC:prepareForSeque: Segue'ng to ShowConsumerDataView.");
        
        // Set ourselves up as the delegate and pass in *our_data*.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        ConsumerDataViewController* view_controller = (ConsumerDataViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        view_controller.our_data = _our_data;
        view_controller.provider_list = _provider_list;
        view_controller.fetch_data_toggle = _fetch_data_toggle;
        
        if (kDebugLevel > 0)
            NSLog(@"ConsumerMVC:prepareForSegue: the ConsumerDataView controller's identity: %s, key-deposit: %s, and public-key: %s.", [view_controller.our_data.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [[view_controller.our_data.deposit description] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[view_controller.our_data.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    } else if ([[segue identifier] isEqualToString:@"ShowAddProviderViewID"]) {
        if (kDebugLevel > 1)
            NSLog(@"ConsumerMVC:prepareForSeque: Segue'ng to ShowAddProviderView.");
        
        // Set ourselves up as the delegate and pass in *our_data*.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        AddProviderCTViewController* view_controller =
        (AddProviderCTViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        
        view_controller.our_data = _our_data;
        
        if (kDebugLevel > 0)
            NSLog(@"ConsumerMVC:prepareForSegue: ShowAddProviderView controller's identity: %s, key-deposit: %s, and public-key: %s.", [view_controller.our_data.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [[view_controller.our_data.deposit description] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[view_controller.our_data.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    } else if ([[segue identifier] isEqualToString:@"ShowAddProviderHCCViewID"]) {
        if (kDebugLevel > 1)
            NSLog(@"ConsumerMVC:prepareForSeque: Segue'ng to ShowAddProviderHCCView.");
        
        // Set ourselves up as the delegate and pass in *our_data*.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        AddProviderHCCViewController* view_controller = (AddProviderHCCViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        view_controller.our_data = _our_data;
        
        // Get the potential consumer's data from our dictionary (note, dictionary indexed by identity).
        for (id key in _potential_providers) {
            if ([key isEqualToString:_potential_provider.identity]) {
                HCCPotentialPrincipal* potential_principal = [_potential_providers objectForKey:key];
                view_controller.potential_provider = potential_principal;
            }
        }
    } else {
        if (kDebugLevel > 0)
            NSLog(@"ConsumerMVC:prepareForSeque: TODO(aka) unknown segue: %s.", [[segue identifier] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    }
}

- (IBAction) unwindToConsumerMaster:(UIStoryboardSegue*)segue {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerMVC:unwindToConsumerMaster: called.");
    
    UIViewController* sourceViewController = segue.sourceViewController;
    
    if ([sourceViewController isKindOfClass:[ConsumerDataViewController class]]) {
        if (kDebugLevel > 2)
            NSLog(@"ConsumerMVC:unwindToConsumerMaster: ConsumerDataViewController callback.");
        
        ConsumerDataViewController* source = [segue sourceViewController];
        if (source.identity_changed || source.pub_keys_changed || source.deposit_changed) {
            if (source.our_data == nil) {
                NSLog(@"ConsumerMVC:unwindToConsumerMaster: TODO(aka) ERROR: PersonalDataController is nil!");
                return;
            }
            
            _our_data = source.our_data;  // get the changes
            
            // Now save state, where needed.
            if (source.deposit_changed)
                [_our_data saveDepositState];
            
            if (source.identity_changed) {
                [_our_data saveIdentityState];
                [_our_data saveDepositState];
            }
            
            // Now tell Provider MVC to slurp up new data.
            NSString* name = [NSString stringWithFormat:@"%s", kStateDataUpdate];
            NSLog(@"ConsumerMVC:unwindToConsumerMaster: XXXXX Issuing notification for %@", name);
            [[NSNotificationCenter defaultCenter] postNotificationName:name object:nil];
        }
        
        if (source.fetch_toggle_changed) {
            // Update our fetch data flag and write it out to disk.
            _fetch_data_toggle = source.fetch_data_toggle;
            NSString* tmp_string = [NSString stringWithFormat:@"%d", _fetch_data_toggle];
            [PersonalDataController saveState:[NSString stringWithCString:kDownloadDataFilename encoding:[NSString defaultCStringEncoding]] string:tmp_string];
        }
    } else if ([sourceViewController isKindOfClass:[AddProviderCTViewController class]]) {
        if (kDebugLevel > 2)
            NSLog(@"ConsumerMVC:unwindToConsumerMaster: AddProviderCTViewController callback.");
        
        AddProviderCTViewController* source = [segue sourceViewController];
        if (source.provider != nil) {
            // Add the new provider to our ProviderListController (and update our state files).
            if (kDebugLevel > 0)
                NSLog(@"ConsumerMVC:unwindToConsumerMaster: adding new provider: %s, public-key: %s.", [source.provider.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [[source.provider.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            
#if 1  // SIMULATOR HACK: The simulator can't receive the file-store via its deposit, so fake the URL for this new provider.
            UIDevice* ui_device = [UIDevice currentDevice];
            if ([ui_device.name caseInsensitiveCompare:@"iPhone Simulator"] == NSOrderedSame) {
                NSLog(@"ConsumerMasterVC:addConsumerToProvider: Found device iPhone Simulator.");
                NSURL* file_store_url = [NSURL URLWithString:@""];
                [source.provider setFile_store_url:file_store_url];
            }
#endif

            NSString* err_msg = [_provider_list addProvider:source.provider];
            if (err_msg != nil) {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ConsumerMasterVC:unwindToConsumerMaster:" message:err_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
            }
        }
    } else if ([sourceViewController isKindOfClass:[AddProviderHCCViewController class]]) {
        if (kDebugLevel > 2)
            NSLog(@"ConsumerMVC:unwindToConsumerMaster: AddProviderHCCViewController callback.");
        
        AddProviderHCCViewController* source = [segue sourceViewController];
        HCCPotentialPrincipal* potential_principal = source.potential_provider;
        
        if (kDebugLevel > 1)
            NSLog(@"ConsumerMVC:unwindToConsumerMaster: HCC Pairing with provider (%s) currently at mode: %d.", [potential_principal.principal.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [potential_principal.mode intValue]);
        
#if 1  // For Debugging:
        // See if we already have this (potential) provider in our local dictionary.
        HCCPotentialPrincipal* prev_pp = [_potential_providers objectForKey:potential_principal.principal.identity];
        if (prev_pp != nil)
            NSLog(@"ConsumerMVC:unwindToConsumerMaster: DEBUG: HCC Pairing with provider (%s), previously, mode at: %d.", [prev_pp.principal.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [prev_pp.mode intValue]);
#endif

        // Update our local state with this potential provider.
        [_potential_providers setObject:potential_principal forKey:potential_principal.principal.identity];
        
        // And finally, save our state.
        NSString* potential_providers_filename = [NSString stringWithFormat:@"%s.consumer", HCC_PRINCIPALS_STATE_FILENAME];
        [PersonalDataController saveState:potential_providers_filename dictionary:_potential_providers];
        
        /*  TODO(aka) Alternate method ...
        if (source.current_state == HCC_MODE_CONSUMER_KEY_SENT) {
            NSString* err_msg = nil;
            if (err_msg != nil) {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ConsumerMasterVC:unwindToConsumerMaster:" message:err_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
            }
        }
         */
    } else if ([sourceViewController isKindOfClass:[AddProviderViewController class]]) {
        if (kDebugLevel > 2)
            NSLog(@"ConsumerMVC:unwindToConsumerMaster: AddProviderViewController callback.");
        
        // If we reached here, the user hit CANCEL in AddProviderViewController.
    } else {
        NSLog(@"ConsumerMVC:unwindToConsumerMaster: TODO(aka) Called from unknown ViewController!");
    }
    
    // No need to dismiss the view controller in an unwind segue.
    
    // XXX [self configureView:true];  // I don't think we need this, as viewDidAppear: will get called!
}

#pragma mark - Cloud operations

- (NSString*) fetchKeyBundle:(Principal*)provider keyBundle:(KeyBundleController**)key_bundle {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerMVC:fetchKeyBundle:keyBundle: called.");
    
    NSString* err_msg = nil;
    
    if (![provider isKeyBundleURLValid]) {
        // We probably have not  received the file-store deposit message, yet.  Just log it and return.
        err_msg = [NSString stringWithFormat:@"INVALID_KEYBUNDLE"];
        return err_msg;
    }
    
    // Fetch the key-bundle, which is built via the Provider MVC using:
    /*
     [PersonalDataController asymmetricEncryptData:symmetric_key publicKeyRef:[consumer publicKeyRef] encryptedData:&encrypted_key];
     NSString* encrypted_key_b64 = [encrypted_key base64EncodedString];
     KeyBundleController* key_bundle = [[KeyBundleController alloc] init];
     [key_bundle build:encrypted_key_b64 privateKeyRef:[_our_data privateKeyRef]];
     [_our_data uploadData:[key_bundle serialize] bucketName:bucket_name filename:filename];
     */
    
    NSError* status = nil;
    NSString* serialized_key_bundle = [[NSString alloc] initWithContentsOfURL:provider.key_bundle_url encoding:[NSString defaultCStringEncoding] error:&status];
    if (status) {
        NSString* description = [[status localizedDescription] stringByAppendingString:([status localizedFailureReason] ? [status localizedFailureReason] :@"")];
        err_msg = [[NSString alloc] initWithFormat:@"ConsumerMasterVC:fetchKeyBundle: %s, file-store: %s, initWithContentsOfURL() failed: %s", [provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [[provider.key_bundle_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], [description cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        return err_msg;
    }
    
    if (kDebugLevel > 2)
        NSLog(@"ConsumerMVC:fetchKeyBundle: %s, url: %s, fetched serialized data: %s.", [provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [[provider.key_bundle_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], [serialized_key_bundle cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
   *key_bundle = [[KeyBundleController alloc] init];
    err_msg = [*key_bundle generateWithString:serialized_key_bundle];
    if (err_msg != nil) {
        NSString* msg = [[NSString alloc] initWithFormat:@"ConsumerMasterVC:fetchKeyBundle: %s: %s", [provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [err_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        return msg;
    }
    
    if (kDebugLevel > 1)
        NSLog(@"ConsumerMVC:fetchKeyBundle: de-serialized %s\'s key-bundle, time-stamp: %d, history-log path: %s, base64'd encrypted symmetric key: %s.", [provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [[*key_bundle time_stamp] intValue], [[*key_bundle history_log_path] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[*key_bundle symmetric_key] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    // Verify the signature over key-bundle.
    if (![*key_bundle verifySignature:[provider publicKeyRef]]) {
        provider.last_fetch = [[NSDate alloc] init];  // make sure we don't keep trying this provider
        err_msg = [[NSString alloc] initWithFormat:@"ConsumerMasterVC:fetchKeyBundle: unable to verify signature over key-bundle for %s!", [provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        return err_msg;
    }
    
    // Unencrypt the b64 symmetric key.
    NSData* encrypted_key = [NSData dataFromBase64String:[*key_bundle symmetric_key]];
    NSData* symmetric_key = nil;
    err_msg = [PersonalDataController asymmetricDecryptData:encrypted_key privateKeyRef:[_our_data privateKeyRef] data:&symmetric_key];
    if (err_msg != nil) {
        provider.last_fetch = [[NSDate alloc] init];  // make sure we don't keep trying this provider
        NSString* msg = [[NSString alloc] initWithFormat:@"ConsumerMasterVC:fetchKeyBundle: %s.", [err_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        return msg;
    }
    provider.key = symmetric_key;
    
    // Add the history-log path onto our existing file-store URL (via a temporary one, so we lose any previous declared path).
    NSURL* tmp_url = [[NSURL alloc] initWithScheme:[provider.file_store_url scheme] host:[provider.file_store_url host] path:[*key_bundle history_log_path]];
    provider.file_store_url = tmp_url;
    
    if (kDebugLevel > 0)
        NSLog(@"ConsumerMVC:fetchKeyBundle: %s\'s file-store: %s, and key hash: %s.", [provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [[provider.file_store_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[PersonalDataController hashSHA256Data:provider.key] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    return nil;
}

- (NSString*) fetchHistoryLog:(Principal*)provider stateChanged:(BOOL*)state_change {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerMVC:fetchHistoryLog:historyLog: called.");
    
    NSString* err_msg = nil;
    
    if (![provider isFileStoreURLValid]) {
        err_msg = [[NSString alloc] initWithFormat:@"ConsumerMasterVC:fetchHistoryLog: history-log URL not set for: %s", [provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        return err_msg;
    }
    
    if (provider.key == nil || ([provider.key length] == 0)) {
        err_msg = [[NSString alloc] initWithFormat:@"ConsumerMasterVC:fetchHistoryLog: no symmetric key for: %s", [provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        return err_msg;
    }
    
    if (kDebugLevel > 3)
        NSLog(@"ConsumerMVC:fetchHistoryLog: %s, checking file-store: %@.", [provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [provider.file_store_url absoluteString]);
    
    // Fetch the location data, which is built via the Provider MVC using:
    /*
     NSData* serialized_history_log = [NSKeyedArchiver archivedDataWithRootObject:history_log];
     [PersonalDataController symmetricEncryptData:serialized_history_log symmetricKey:[_symmetric_keys_controller objectForKey:policy] encryptedData:&encrypted_data];
     NSString* encrypted_data_b64 = [encrypted_data base64EncodedString];
     */
    
    NSError* status = nil;
    NSString* encrypted_data_b64 = [[NSString alloc] initWithContentsOfURL:provider.file_store_url encoding:[NSString defaultCStringEncoding] error:&status];
    if (status) {
        NSString* description = [[status localizedDescription] stringByAppendingString:([status localizedFailureReason] ? [status localizedFailureReason] :@"")];
        err_msg = [[NSString alloc] initWithFormat:@"ConsumerMasterVC:fetchHistoryLog: %s, file-store: %s, initWithContentsOfURL() failed: %s", [provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [[provider.file_store_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], [description cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        return err_msg;
    }
    
    if (kDebugLevel > 2)
        NSLog(@"ConsumerMVC:fetchHistoryLog: file-store: %s, fetched base64 history log: %s.", [[provider.file_store_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], [encrypted_data_b64 cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    // Unencrypt it.
    NSData* encrypted_data = [NSData dataFromBase64String:encrypted_data_b64];
    NSData* serialized_history_log = nil;
    err_msg = [PersonalDataController symmetricDecryptData:encrypted_data symmetricKey:provider.key data:&serialized_history_log];
    if (err_msg != nil) {
        NSString* msg = [[NSString alloc] initWithFormat:@"ConsumerMasterVC:fetchHistoryLog: %s: %s", [provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [err_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        return msg;
    }
    
    if (kDebugLevel > 1)
        NSLog(@"ConsumerMVC:fetchHistoryLog: %s\'s url: %s, produced %ldb serialized log.", [provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [[provider.file_store_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], (unsigned long)[serialized_history_log length]);
    
    // And unserialize it.
    NSString* serialized_history_log_str = [[NSString alloc] initWithData:serialized_history_log encoding:NSUTF8StringEncoding];
    NSArray* entries = [serialized_history_log_str componentsSeparatedByString:[NSString stringWithFormat:@"%c", kArraySerializerDelimiter]];
    
    if (kDebugLevel > 1)
        NSLog(@"ConsumerMVC:fetchHistoryLog: unserialized \"%s\" into %lu components.", [serialized_history_log_str cStringUsingEncoding:[NSString defaultCStringEncoding]], (unsigned long)[entries count]);
    
    // Add any new serialized LocationBundleControllers to this provider's history-log.  Note, we operate in reverse over the incoming history-log, because as we insert into the NSArray, we push the old entries to the back ...
    
    int cnt = 0;
    LocationBundleController* most_recent = nil;
    int most_recent_time_stamp = 0;
    if ([provider.history_log count]) {
        most_recent = [provider.history_log objectAtIndex:0];  // grab existing most recent location-bundle
        most_recent_time_stamp = [most_recent.time_stamp intValue];
    }
    
    for (int i = (int)[entries count]; i > 0; --i) {
        NSUInteger index = i - 1;
        NSString* serialized_location_bundle = [entries objectAtIndex:index];
        LocationBundleController* location_bundle = [[LocationBundleController alloc] init];
        [location_bundle generateWithString:serialized_location_bundle];
        
        if (kDebugLevel > 0)
            NSLog(@"ConsumerMVC:fetchHistoryLog: at %lu of %d, comparing fetched (%@): %d, to most recent in history-log (%@): %d.", (unsigned long)index, (int)[entries count], location_bundle.serialized_location, [location_bundle.time_stamp intValue], most_recent.serialized_location, most_recent_time_stamp);
        
        if ([location_bundle.time_stamp intValue] <= most_recent_time_stamp)
            continue;  // new material is older than our most recent
        
        // This is newer, if the signature checks out, add it to the front of our queue.
        if (![location_bundle verifySignature:[provider publicKeyRef]]) {
            // Hmm, failed signature.  Log it, but continue with the next entry.
            NSString* err_msg = [[NSString alloc] initWithFormat:@"ConsumerMasterVC:fetchHistoryLog: signature check failed for %s.", [provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            UILocalNotification* notice = [[UILocalNotification alloc] init];
            notice.alertBody = err_msg;
            notice.alertAction = @"Show";
            [[UIApplication sharedApplication] presentLocalNotificationNow:notice];
            continue;
        }
        
        if (kDebugLevel > 1)
            NSLog(@"ConsumerMVC:fetchHistoryLog: adding entries[%lu] to history_log: %@.", (unsigned long)index, [location_bundle description]);
        
        [provider.history_log insertObject:location_bundle atIndex:0];
        cnt++;
        
        // And if this gave us more than our allotted queue size, delete the last object.
        while ([provider.history_log count] > kHistoryLogSize)
            [provider.history_log removeLastObject];
    }
    
    if (kDebugLevel > 0)
        NSLog(@"ConsumerMVC:fetchHistoryLog: %s\'s history-log updated with %d entries.", [provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], cnt);

    if (cnt > 0)
        *state_change = true;

    return nil;
}

- (void) updateProviderData:(Principal*)provider stateChanged:(BOOL*)state_change {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerMVC:updateProviderData: called: %d.", _fetch_data_toggle);
    
    // In case we figure out how to background fetching data here, let's make sure that we use UILocalNotification as opposed to UIAlertView for errors!
    
    NSString* err_msg = nil;
    
    if (!_fetch_data_toggle)
        return;  // we've globally turned off data fetching, so nothing to do ...
    
    // Make sure we have a symmetric key for this provider (if not, try to fetch it).
    if (provider.key == nil || ([provider.key length] == 0)) {
        KeyBundleController* key_bundle = nil;
        err_msg = [self fetchKeyBundle:provider keyBundle:&key_bundle];
        if (err_msg != nil) {
            provider.last_fetch = [[NSDate alloc] init];  // make sure we don't keep trying this provider
            if ([err_msg isEqual:@"INVALID_KEYBUNDLE"]) {
                // Just log the fact that we have not yet received their file-store information.
                if (kDebugLevel > 0)
                    NSLog(@"ConsumerMasterVC:updateProviderData: key-bundle URL invalid, or not yet set.");
                return;
            } else {
                // A real error ...
                NSString* msg = [[NSString alloc] initWithFormat:@"ConsumerMasterVC:updateProviderData: %s.", [err_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]];
                UILocalNotification* notice = [[UILocalNotification alloc] init];
                notice.alertBody = msg;
                notice.alertAction = @"Show";
                [[UIApplication sharedApplication] presentLocalNotificationNow:notice];
                return;
            }
        }
        
        // Remember to save our state.
        err_msg = [_provider_list saveState];
        if (err_msg != nil) {
            provider.last_fetch = [[NSDate alloc] init];  // make sure we don't keep trying this provider
            NSString* msg = [[NSString alloc] initWithFormat:@"ConsumerMasterVC:updateProviderData: %s.", [err_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            UILocalNotification* notice = [[UILocalNotification alloc] init];
            notice.alertBody = msg;
            notice.alertAction = @"Show";
            [[UIApplication sharedApplication] presentLocalNotificationNow:notice];
            return;
        }
        
        if (kDebugLevel > 2)
            NSLog(@"ConsumerMVC:updateProviderData: Fetched key-bundle for %s.", [provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        
        // Fall-through and attempt to grab history log!
    }  // if (provider.key == nil || ([provider.key length] == 0)) {
    
    // Get history log.
    if (![provider isFileStoreURLValid]) {
        provider.last_fetch = [[NSDate alloc] init];  // make sure we don't keep trying this provider
        NSString* msg = [[NSString alloc] initWithFormat:@"ConsumerMasterVC:updateProviderData: %s\'s file-store not valid: %s.", [provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [[provider.file_store_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        if (self.isViewLoaded && self.view.window) {
            UILocalNotification* notice = [[UILocalNotification alloc] init];
            notice.alertBody = msg;
            notice.alertAction = @"Show";
            [[UIApplication sharedApplication] presentLocalNotificationNow:notice];
        } else {
            NSLog(@"%@", msg);
        }
        return;
    }
    
    err_msg = [self fetchHistoryLog:provider stateChanged:state_change];
    if (err_msg != nil) {
        provider.last_fetch = [[NSDate alloc] init];  // make sure we don't keep trying this provider
        NSString* msg = [[NSString alloc] initWithFormat:@"ConsumerMasterVC:updateProviderData: %s.", [err_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        if (self.isViewLoaded && self.view.window) {
            UILocalNotification* notice = [[UILocalNotification alloc] init];
            notice.alertBody = msg;
            notice.alertAction = @"Show";
            [[UIApplication sharedApplication] presentLocalNotificationNow:notice];
        } else {
            NSLog(@"%@", msg);
        }
        return;
    }
}

- (void) updateAllProviderData {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerMVC:updateAllProviderData: called.");
    
    // In case we figure out how to background fetching data here, let's make sure that we use UILocalNotification as opposed to UIAlertView for errors!
    
    // Grab new location data for all providers that we have ...
    BOOL state_changed = false;
    for (int i = 0; i < [_provider_list countOfList]; ++i) {
        Principal* provider = [_provider_list objectInListAtIndex:i];
        
        // Call updateProviderData: to get the work done.
        [self updateProviderData:provider stateChanged:&state_changed];
        
        [provider updateLastFetch];  // show that we recently fetched something ...
        
        continue;
    }  // for (int i = 0; i < [_provider_list countOfList]; ++i) {
    
    if (state_changed)
        [_provider_list saveState];
    
    // Plot any new data.
    [self configureView:false];
}

#pragma mark - Location data management

- (void) setTimerForFetchingData {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerMVC:setTimerForFetchingData: called.");
    
    NSTimeInterval next_timeout = [_provider_list getNextTimeInterval];
    
    if (kDebugLevel > 1)
        NSLog(@"ConsumerMVC:setTimerForFetchingData: setting timer for %fs.", next_timeout);
    
    [NSTimer scheduledTimerWithTimeInterval:next_timeout target:self selector:@selector(updateAllProviderData) userInfo:nil repeats:NO];
}

#pragma mark - NSUserDefaults management

- (NSString*) checkNSUserDefaults {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerMVC:checkNSUserDefaults: called.");

    NSString* url_string = [[NSUserDefaults standardUserDefaults] objectForKey:@"url"];
    if (url_string == nil)
        return nil;  // nothing in NSUserDefaults
    
    if ([url_string length] == 0) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove URL so no one attempts to processes it again
        return @"ConsumerMasterVC:checkNSUserDefaults: url_string is empty!";
    }
    
    NSLog(@"ConsumerMVC:checkNSUserDefaults: TOOD(aka) How do we tell if there are multiple NSUserDefaults (i.e., symmetric keys) waiting for us?  While () loop?");
    
    if (kDebugLevel > 1)
        NSLog(@"ConsumerMVC:checkNSUserDefaults: received NSUserDefault string: %s.", [url_string cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    NSString* err_msg = nil;
    
    NSURL* url = [[NSURL alloc] initWithString:url_string];
    if (url == nil) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove URL so no one attempts to processes it again
        err_msg = [NSString stringWithFormat:@"ConsumerMasterVC:checkNSUserDefaults: unable to convert %@ to a URL!", url_string];
        return err_msg;
    }
    
    // Make sure we have a nine character path (*all* SLS paths are 8 chars + '/').
    NSString* path = [url path];
    if (path == nil || [path length] != (strlen(kPathHCCMsg1) + 1)) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove URL so no one attempts to processes it again
        err_msg = [NSString stringWithFormat:@"ConsumerMasterVC:checkNSUserDefaults: URL does not contain a SLS path: %s!", [path cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        return err_msg;
    }
    
    if (kDebugLevel > 0)
        NSLog(@"ConsumerMVC:checkNSUserDefaults: from NSDefaults got scheme: %s, fragment: %s, query: %s, path: %s, parameterString: %s.", [url.scheme cStringUsingEncoding:[NSString defaultCStringEncoding]], [url.fragment cStringUsingEncoding:[NSString defaultCStringEncoding]], [url.query cStringUsingEncoding:[NSString defaultCStringEncoding]], [url.path cStringUsingEncoding:[NSString defaultCStringEncoding]], [url.parameterString cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    // See if this URL was meant for the provider MVC ...
    NSString* processor = [path substringWithRange:NSMakeRange(1, 9)];
    if ([processor isEqualToString:[NSString stringWithFormat:@"provider"]]) {
        if (kDebugLevel > 0)
            NSLog(@"ConsumerMVC:checkNSUserDefaults: switching to provider's tab so NSUserDefauls can be processed: %@.", url_string);
        
        UITabBarController* tab_controller = (UITabBarController*)self.tabBarController;
        if (tab_controller == nil) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove URL so no one attempts to processes it again
            err_msg = [[NSString alloc] initWithFormat:@"ConsumerMasterVC:checkNSUserDefaults: unable to switch tab bars."];
            return err_msg;
        }
        
        [tab_controller setSelectedIndex:0];
        
        return [NSString stringWithFormat:@"ConsumerMasterVC:checkNSUserDefaults: message destined for provider mode: %@", url_string];
    }
    
    // Process the URL depending on its path.
    if ([path isEqualToString:[NSString stringWithFormat:@"/%s", kPathFileStore]]) {
        // Process the cloud file-store query, which is built in the Provider's MVC via the following command:
        /*
         path = [[NSString alloc] initWithFormat:@"/%s?%s=%s&%s=%s&%s=%s&%s=%ld&%s=%s", kPathFileStore, kQueryKeyID, [_our_data.identity_hash cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyFileStoreURL, [[file_store_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyKeyBundleURL, [[key_bundle_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyTimeStamp, now.tv_sec, kQueryKeySignature, [signature cStringUsingEncoding:[NSString defaultCStringEncoding]]];
         */
        
        NSString* identity_hash = nil;
        NSURL* file_store_url = nil;
        NSURL* key_bundle_url = nil;
        time_t time_stamp = 0;
        NSData* signature = nil;
        
        // TODO(aka) We may want to see if we can make a function of parsing the query, e.g., having it return an NSDictionary of key/value pairs.  Of course, we'd still need to test each key/value pair afterwords, so I don't know how much space we'd save ...
        
        NSString* query = [url query];
        NSArray* key_value_pairs = [query componentsSeparatedByString:[NSString stringWithFormat:@"%c", kPathDelimiter]];
        for (int i = 0; i < [key_value_pairs count]; ++i) {
            NSString* key_value_pair = [key_value_pairs objectAtIndex:i];
            
            // Note, the base64 representation of the signature can legally have the character '='.  Thus, we need to *only* get the *first* instance of "=" in key_value_pair.
            
            NSRange delimiter = [key_value_pair rangeOfString:@"="];
            NSString* key = [key_value_pair substringWithRange:NSMakeRange(0, delimiter.location)];
            NSString* value = [key_value_pair substringWithRange:NSMakeRange(delimiter.location + 1, ([key_value_pair length] - delimiter.location) - 1)];
            
            if (kDebugLevel > 1)
                NSLog(@"ConsumerMVC:checkNSUserDefaults: working with key: %s, value: %s, from pair: %s.", [key cStringUsingEncoding:[NSString defaultCStringEncoding]], [value cStringUsingEncoding:[NSString defaultCStringEncoding]], [key_value_pair cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            
            if ([key caseInsensitiveCompare:[NSString stringWithCString:kQueryKeyID encoding:[NSString defaultCStringEncoding]]] == NSOrderedSame) {
                if (kDebugLevel > 3)
                    NSLog(@"ConsumerMVC:checkNSUserDefaults: processing identity hash: %s", [value cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                
                // TODO(aka) Not really necessary, as identity-hash should never have whitespace.
                NSString* de_urlified = [value stringByReplacingPercentEscapesUsingEncoding:[NSString defaultCStringEncoding]];
                
                if (kDebugLevel > 1)
                    NSLog(@"ConsumerMVC:checkNSUserDefaults: Setting identity-hash to %s", [de_urlified cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                
                identity_hash = [[NSString alloc] initWithString:de_urlified];
            } else if ([key caseInsensitiveCompare:[NSString stringWithCString:kQueryKeyFileStoreURL encoding:[NSString defaultCStringEncoding]]] == NSOrderedSame) {
                if (kDebugLevel > 3)
                    NSLog(@"ConsumerMVC:checkNSUserDefaults: processing history-log URL: %s", [value cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                
                file_store_url = [[NSURL alloc] initWithString:value];  // note, URL will *not* have path component (see fetchKeyBundle:)
            } else if ([key caseInsensitiveCompare:[NSString stringWithCString:kQueryKeyKeyBundleURL encoding:[NSString defaultCStringEncoding]]] == NSOrderedSame) {
                if (kDebugLevel > 3)
                    NSLog(@"ConsumerMVC:checkNSUserDefaults: processing key-bundel URL: %s", [value cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                
                key_bundle_url = [[NSURL alloc] initWithString:value];
            } else if ([key caseInsensitiveCompare:[NSString stringWithCString:kQueryKeyTimeStamp encoding:[NSString defaultCStringEncoding]]] == NSOrderedSame) {
                if (kDebugLevel > 3)
                    NSLog(@"ConsumerMVC:checkNSUserDefaults: processing time-stamp: %s", [value cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                
                time_stamp = [value intValue];
            } else if ([key caseInsensitiveCompare:[NSString stringWithCString:kQueryKeySignature encoding:[NSString defaultCStringEncoding]]] == NSOrderedSame) {
                if (kDebugLevel > 3)
                    NSLog(@"ConsumerMVC:checkNSUserDefaults: processing base64 signature: %s", [value cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                
                signature = [NSData dataFromBase64String:value];
            } else {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove URL so no one attempts to processes it again
                err_msg = [NSString stringWithFormat:@"ConsumerMasterVC:checkNSUserDefaults: unknown query key: %s.", [key cStringUsingEncoding:[NSString defaultCStringEncoding]]];
                return err_msg;
            }
        }  // for (int i = 0; i < [key_value_pairs count]; ++i) {
        
        // If we didn't get everything, notify the user, than move on with life.
        if (identity_hash == nil || file_store_url == nil || key_bundle_url == nil || time_stamp == 0 || signature == nil) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove URL so no one attempts to processes it again
            err_msg = [[NSString alloc] initWithFormat:@"ConsumerMasterVC:checkNSUserDefaults: Failed to parse: %s.", [url_string cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            return err_msg;
        }
        
        // Find this provider in our list.
        Principal* provider = [_provider_list getProvider:identity_hash];
        if (provider == nil) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove URL so no one attempts to processes it again
            err_msg = [[NSString alloc] initWithFormat:@"ConsumerMasterVC:checkNSUserDefaults: Unable to find provider using identity-hash: %s.", [identity_hash cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            return err_msg;
        }
        
        // Verify the signature over the meta-data, which was built via the Provider MVC via:
        /*
         NSString* four_tuple = [[NSString alloc] initWithFormat:@"%s%s%s%ld", [_our_data.identity_hash cStringUsingEncoding:[NSString defaultCStringEncoding]], [[history_log_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[key_bundle_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], now.tv_sec];
         NSData* hash = [PersonalDataController hashSHA256StringToData:four_tuple];
         NSString* signature = nil;
         [PersonalDataController signHashData:four_tuple privateKeyRef:_our_data.privateKeyRef signedHash:&signature];
         */
        
        NSString* four_tuple = [[NSString alloc] initWithFormat:@"%s%s%s%ld", [identity_hash cStringUsingEncoding:[NSString defaultCStringEncoding]], [[file_store_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[key_bundle_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], time_stamp];
        NSData* hash = [PersonalDataController hashSHA256StringToData:four_tuple];
        
        if (![PersonalDataController verifySignatureData:hash secKeyRef:[provider publicKeyRef] signature:signature]) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove URL so no one attempts to processes it again
            err_msg = [[NSString alloc] initWithFormat:@"ConsumerMasterVC:checkNSUserDefaults: Unable to verify signature for provider: %s.", [provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            return err_msg;
        }
        
        NSLog(@"ConsumerMVC:checkNSUserDefaults: TODO(aka) we are not checking time-stamp (%ld)!", time_stamp);
        
        // Update meta-data in our provider.
        [provider setKey_bundle_url:key_bundle_url];
        [provider setFile_store_url:file_store_url];
        
#if 1
        // For Debugging:
        for (id object in _provider_list.provider_list) {
            Principal* principal = (Principal*)object;
            if ([principal.identity_hash isEqualToString:identity_hash]) {
                if ([[principal.key_bundle_url absoluteString] isEqualToString:[provider.key_bundle_url absoluteString]])
                    NSLog(@"ConsumerMVC:checkNSUserDefaults: DEBUG: XXXX Pointer check worked!");
                else
                    NSLog(@"ConsumerMVC:checkNSUserDefaults: DEBUG: XXXX Pointer check FAILED, so we'll need to pass URLs back through parameter list!");
            }
        }
#endif
        
        // Fetch the shared key bundle back in [self updateAllProviderData].
    } else if ([path isEqualToString:[NSString stringWithFormat:@"/%s", kPathHCCMsg2]]) {
        // Process the HCC msg2 query, which is built in the Provider's HCC VC via the following command:
        /*
         _potential_consumer.challenge = [NSNumber numberWithInt:(arc4random() % 9999)];  // get a four digit challenge (response will have + 1, so <= 9998)
         [PersonalDataController asymmetricEncryptString:[NSString stringWithFormat:@"%d", [_potential_consumer.challenge intValue]] publicKeyRef:[consumer publicKeyRef] encryptedString:&encrypted_challenge];
         NSString* path = [[NSString alloc] initWithFormat:@"/%s?%s=%s", kPathHCCMsg2, kQueryKeyChallenge, [encrypted_challenge cStringUsingEncoding:[NSString defaultCStringEncoding]]];
         */
        
        NSString* challenge = nil;
        
        NSString* query = [url query];
        NSArray* key_value_pairs = [query componentsSeparatedByString:[NSString stringWithFormat:@"%c", kPathDelimiter]];
        for (int i = 0; i < [key_value_pairs count]; ++i) {
            NSString* key_value_pair = [key_value_pairs objectAtIndex:i];
            
            // Note, the base64 representation of the public key can legally have the character '='.  Thus, we need to *only* get the *first* instance of "=" in key_value_pair.
            
            NSRange delimiter = [key_value_pair rangeOfString:@"="];
            NSString* key = [key_value_pair substringWithRange:NSMakeRange(0, delimiter.location)];
            NSString* value = [key_value_pair substringWithRange:NSMakeRange(delimiter.location + 1, ([key_value_pair length] - delimiter.location) - 1)];
            
            if (kDebugLevel > 1)
                NSLog(@"ConsumerMVC:checkNSUserDefaults: working with key: %s, value: %s, from pair: %s.", [key cStringUsingEncoding:[NSString defaultCStringEncoding]], [value cStringUsingEncoding:[NSString defaultCStringEncoding]], [key_value_pair cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            
            if ([key caseInsensitiveCompare:[NSString stringWithCString:kQueryKeyChallenge encoding:[NSString defaultCStringEncoding]]] == NSOrderedSame) {
                if (kDebugLevel > 3)
                    NSLog(@"ConsumerMVC:checkNSUserDefaults: processing challenge: %s", [value cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                
                err_msg = [PersonalDataController asymmetricDecryptString:value privateKeyRef:[_our_data privateKeyRef] string:&challenge];
                if (err_msg != nil) {
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove URL so no one attempts to processes it again
                    return err_msg;
                }
            } else {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove URL so no one attempts to processes it again
                err_msg = [NSString stringWithFormat:@"ConsumerMasterVC:checkNSUserDefaults: unknown query key: %s.", [key cStringUsingEncoding:[NSString defaultCStringEncoding]]];
                return err_msg;
            }
        }  // for (int i = 0; i < [key_value_pairs count]; ++i) {
        
        // If we didn't get everything, notify the user, than move on with life.
        if (challenge == nil) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove URL so no one attempts to processes it again
            err_msg = [[NSString alloc] initWithFormat:@"ConsumerMasterVC:checkNSUserDefaults: Failed to parse: %s.", [url_string cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            return err_msg;
        }
        
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove the processed URL
        
        // At this point, the user must choose which AddressBook entry to use for this message (to lookup in _potential_providers).
        err_msg = [self getProviderIdentity:HCC_MODE_PROVIDER_CHALLENGE_SENT];  // XXX TODO(aka) should we return message or bool?  getConsumer handles errors, right?
        if (err_msg != nil)
            return err_msg;

        HCCPotentialPrincipal* potential_principal = [_potential_providers objectForKey:_potential_provider.identity];
        if (potential_principal == nil) {
            err_msg = [[NSString alloc] initWithFormat:@"ConsumerMasterVC:checkNSUserDefaults: no entry in _potential_providers for: %s.", [_potential_provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            return err_msg;
        }
    
        NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
        [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
        potential_principal.their_challenge = [NSNumber numberWithInt:[[formatter numberFromString:challenge] intValue] + 1];  // note '+1'
        potential_principal.mode = [NSNumber numberWithInt:HCC_MODE_CONSUMER_CHALLENGE_RECEIVED];
        
        // Save this potential consumer to our local dictionary and save its state.
        [_potential_providers setObject:potential_principal forKey:_potential_provider.identity];  // XXX do we need this?  Well, if originally nil ..
        NSString* potential_providers_filename = [NSString stringWithFormat:@"%s.consumer", HCC_PRINCIPALS_STATE_FILENAME];
        [PersonalDataController saveState:potential_providers_filename dictionary:_potential_providers];
        
        // Setup next message by segue'ng to AddConsumerHCCVC.
        [self performSegueWithIdentifier:@"ShowAddProviderHCCViewID" sender:nil];
    } else if ([path isEqualToString:[NSString stringWithFormat:@"/%s", kPathHCCMsg4]]) {
        // Process the HCC msg4 query, which is built in the Provider's HCC VC via the following command:
        /*
         PersonalDataController asymmetricEncryptString:_potential_consumer.our_secret_question publicKeyRef:[consumer publicKeyRef] encryptedString:&encrypted_question];
         NSString* public_key = [[_our_data getPublicKey] base64EncodedString];
         NSString* path = [[NSString alloc] initWithFormat:@"/%s?%s=%s?%s=%s?%s=%s", kPathHCCMsg4, kQueryKeyID, [_our_data.identity_hash cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyPublicKey, [public_key cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeySecretQuestion, [encrypted_question cStringUsingEncoding:[NSString defaultCStringEncoding]]];
         */
        
        NSString* identity_hash = nil;
        NSData* pub_key = nil;
        NSString* secret_question = nil;
        
        NSString* query = [url query];
        NSArray* key_value_pairs = [query componentsSeparatedByString:[NSString stringWithFormat:@"%c", kPathDelimiter]];
        for (int i = 0; i < [key_value_pairs count]; ++i) {
            NSString* key_value_pair = [key_value_pairs objectAtIndex:i];
            
            // Note, the base64 representation of the public key can legally have the character '='.  Thus, we need to *only* get the *first* instance of "=" in key_value_pair.
            
            NSRange delimiter = [key_value_pair rangeOfString:@"="];
            NSString* key = [key_value_pair substringWithRange:NSMakeRange(0, delimiter.location)];
            NSString* value = [key_value_pair substringWithRange:NSMakeRange(delimiter.location + 1, ([key_value_pair length] - delimiter.location) - 1)];
            
            if (kDebugLevel > 1)
                NSLog(@"ConsumerMVC:checkNSUserDefaults: working with key: %s, value: %s, from pair: %s.", [key cStringUsingEncoding:[NSString defaultCStringEncoding]], [value cStringUsingEncoding:[NSString defaultCStringEncoding]], [key_value_pair cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            
            if ([key caseInsensitiveCompare:[NSString stringWithCString:kQueryKeyID encoding:[NSString defaultCStringEncoding]]] == NSOrderedSame) {
                if (kDebugLevel > 3)
                    NSLog(@"ConsumerMVC:checkNSUserDefaults: processing identity hash: %s", [value cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                
                // TODO(aka) Not really necessary, as identity-hash should never have whitespace.
                NSString* de_urlified = [value stringByReplacingPercentEscapesUsingEncoding:[NSString defaultCStringEncoding]];
                
                if (kDebugLevel > 1)
                    NSLog(@"ConsumerMVC:checkNSUserDefaults: Setting identity-hash to %s", [de_urlified cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                
                identity_hash = [[NSString alloc] initWithString:de_urlified];
            } else if ([key caseInsensitiveCompare:[NSString stringWithCString:kQueryKeyPubKey encoding:[NSString defaultCStringEncoding]]] == NSOrderedSame) {
                if (kDebugLevel > 3)
                    NSLog(@"ConsumerMVC:checkNSUserDefaults: processing base64 pubkey: %s", [value cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                
                pub_key = [NSData dataFromBase64String:value];
            } else if ([key caseInsensitiveCompare:[NSString stringWithCString:kQueryKeySecretQuestion encoding:[NSString defaultCStringEncoding]]] == NSOrderedSame) {
                if (kDebugLevel > 3)
                    NSLog(@"ConsumerMVC:checkNSUserDefaults: processing base64 secret-question: %s", [value cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                
                err_msg = [PersonalDataController asymmetricDecryptString:value privateKeyRef:[_our_data privateKeyRef] string:&secret_question];
                if (err_msg != nil) {
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove URL so no one attempts to processes it again
                    return err_msg;
                }
            } else {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove URL so no one attempts to processes it again
                err_msg = [NSString stringWithFormat:@"ConsumerMasterVC:checkNSUserDefaults: unknown query key: %s.", [key cStringUsingEncoding:[NSString defaultCStringEncoding]]];
                return err_msg;
            }
        }  // for (int i = 0; i < [key_value_pairs count]; ++i) {
        
        // If we didn't get everything, notify the user, than move on with life.
        if (identity_hash == nil || pub_key == nil || secret_question == nil) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove URL so no one attempts to processes it again
            err_msg = [[NSString alloc] initWithFormat:@"ConsumerMasterVC:checkNSUserDefaults: Failed to parse: %s.", [url_string cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            return err_msg;
        }
        
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove the processed URL
        
        // At this point, the user must choose which AddressBook entry to use for this message (to lookup in _potential_providers).
        err_msg = [self getProviderIdentity:HCC_MODE_PROVIDER_PUBKEY_SENT];  // XXX TODO(aka) should we return message or bool?  getConsumer handles errors, right?
        if (err_msg != nil)
            return err_msg;

        // Get our potential provider from our dictionary and update it.
        HCCPotentialPrincipal* potential_principal = [_potential_providers objectForKey:_potential_provider.identity];
        if (potential_principal == nil) {
            err_msg = [[NSString alloc] initWithFormat:@"ConsumerMasterVC:checkNSUserDefaults: no entry in _potential_providers for: %s.", [_potential_provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            return err_msg;
        }
        
        potential_principal.principal.identity_hash = identity_hash;

        // TODO(aka) Note, in-order to get a SecKeyRef of our NSData pubkey, we need to first put it in the keychain (stupid iOS API!), so if we don't add this Principal as a consumer later on, we'll need to eventually delete the key from our keychain!
        
#if 1  // ACCESS_GROUP: TODO(aka) This doesn't work!
        err_msg = [potential_principal.principal setPublicKey:pub_key accessGroup:[NSString stringWithFormat:@"%s", kAccessGroupHCC]];
#else
        err_msg = [potential_principal.principal setPublicKey:pub_key accessGroup:nil];
#endif
        if (err_msg != nil)
            return err_msg;
        
        potential_principal.their_secret_question = secret_question;
        potential_principal.mode = [NSNumber numberWithInt:HCC_MODE_CONSUMER_PUBKEY_RECEIVED];
        
        // Save this potential consumer to our local dictionary and save its state.
        [_potential_providers setObject:potential_principal forKey:_potential_provider.identity];  // XXX do we need this?
        NSString* potential_providers_filename = [NSString stringWithFormat:@"%s.consumer", HCC_PRINCIPALS_STATE_FILENAME];
        [PersonalDataController saveState:potential_providers_filename dictionary:_potential_providers];
        
        // Setup next message by segue'ng to AddConsumerHCCVC.
        [self performSegueWithIdentifier:@"ShowAddProviderHCCViewID" sender:nil];
    } else if ([path isEqualToString:[NSString stringWithFormat:@"/%s", kPathHCCMsg6]]) {
        // Process the HCC msg6 query, which is built in the Provider's HCC VC via the following command:
        /*
         [PersonalDataController asymmetricEncryptString:answer publicKeyRef:[consumer publicKeyRef] encryptedString:&encrypted_answer];
         NSString* path = [[NSString alloc] initWithFormat:@"/%s?%s=%d?%s=%s", kPathHCCMsg6, kQueryKeyResponse, [_potential_consumer.their_challenge intValue], kQueryKeyAnswer, [encrypted_answer cStringUsingEncoding:[NSString defaultCStringEncoding]]];
         */
        
        int response = -1;
        NSString* answer = nil;
        
        NSString* query = [url query];
        NSArray* key_value_pairs = [query componentsSeparatedByString:[NSString stringWithFormat:@"%c", kPathDelimiter]];
        for (int i = 0; i < [key_value_pairs count]; ++i) {
            NSString* key_value_pair = [key_value_pairs objectAtIndex:i];
            
            // Note, the base64 representation of the public key can legally have the character '='.  Thus, we need to *only* get the *first* instance of "=" in key_value_pair.
            
            NSRange delimiter = [key_value_pair rangeOfString:@"="];
            NSString* key = [key_value_pair substringWithRange:NSMakeRange(0, delimiter.location)];
            NSString* value = [key_value_pair substringWithRange:NSMakeRange(delimiter.location + 1, ([key_value_pair length] - delimiter.location) - 1)];
            
            if (kDebugLevel > 1)
                NSLog(@"ConsumerMVC:checkNSUserDefaults: working with key: %s, value: %s, from pair: %s.", [key cStringUsingEncoding:[NSString defaultCStringEncoding]], [value cStringUsingEncoding:[NSString defaultCStringEncoding]], [key_value_pair cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            
            if ([key caseInsensitiveCompare:[NSString stringWithCString:kQueryKeyResponse encoding:[NSString defaultCStringEncoding]]] == NSOrderedSame) {
                if (kDebugLevel > 3)
                    NSLog(@"ConsumerMVC:checkNSUserDefaults: processing response: %s", [value cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                
                response = [value intValue];
            } else if ([key caseInsensitiveCompare:[NSString stringWithCString:kQueryKeyAnswer encoding:[NSString defaultCStringEncoding]]] == NSOrderedSame) {
                if (kDebugLevel > 3)
                    NSLog(@"ConsumerMVC:checkNSUserDefaults: processing base64 answer: %s", [value cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                
                err_msg = [PersonalDataController asymmetricDecryptString:value privateKeyRef:[_our_data privateKeyRef] string:&answer];
                if (err_msg != nil) {
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove URL so no one attempts to processes it again
                    return err_msg;
                }
            } else {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove URL so no one attempts to processes it again
                err_msg = [NSString stringWithFormat:@"ConsumerMasterVC:checkNSUserDefaults: unknown query key: %s.", [key cStringUsingEncoding:[NSString defaultCStringEncoding]]];
                return err_msg;
            }
        }  // for (int i = 0; i < [key_value_pairs count]; ++i) {
        
        // If we didn't get everything, notify the user, than move on with life.
        if (response == -1 || answer == nil) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove URL so no one attempts to processes it again
            err_msg = [[NSString alloc] initWithFormat:@"ConsumerMasterVC:checkNSUserDefaults: Failed to parse: %s.", [url_string cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            return err_msg;
        }
        
       [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove the processed URL
        
        // At this point, the user must choose which AddressBook entry to use for this message (to lookup in _potential_providers).
        err_msg = [self getProviderIdentity:HCC_MODE_PROVIDER_RESPONSE_SENT];  // XXX TODO(aka) should we return message or bool?  getConsumer handles errors, right?
        if (err_msg != nil)
            return err_msg;
        
        HCCPotentialPrincipal* potential_principal = [_potential_providers objectForKey:_potential_provider.identity];
        if (potential_principal == nil) {
            err_msg = [[NSString alloc] initWithFormat:@"ConsumerMasterVC:checkNSUserDefaults: no entry in _potential_providers for: %s.", [_potential_provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            return err_msg;
        }
        
        // Check to see if their response matches our challenge.
        if ([potential_principal.our_challenge intValue] != (response - 1)) {
            err_msg = [[NSString alloc] initWithFormat:@"ConsumerMasterVC:checkNSUserDefaults: response (%d) from %s does not match our challenge: %d.", response, [_potential_provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [potential_principal.our_challenge intValue]];
            [_potential_providers removeObjectForKey:_potential_provider.identity];  // games over; blow away potential consumer
            return err_msg;
        }
        
        // Update our potential provider's info.
        potential_principal.mode = [NSNumber numberWithInt:HCC_MODE_CONSUMER_RESPONSE_VETTED];

        // Save this potential consumer to our local dictionary and save its state.
        [_potential_providers setObject:potential_principal forKey:_potential_provider.identity];  // XXX do we need this?
        NSString* potential_providers_filename = [NSString stringWithFormat:@"%s.consumer", HCC_PRINCIPALS_STATE_FILENAME];
        [PersonalDataController saveState:potential_providers_filename dictionary:_potential_providers];
        
        
        // Finally, see if the received answer is acceptable (in the UIAlert delegate, we'll segue to HCC VC if user answers yes).
        NSString* msg = [[NSString alloc] initWithFormat:@"Does \"%s\" answer \"%s\"?", [answer cStringUsingEncoding:[NSString defaultCStringEncoding]], [potential_principal.our_secret_question cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ConsumerMasterVC:checkNSUserDefaults:" message:msg delegate:self cancelButtonTitle:[NSString stringWithCString:kAlertButtonCancelPairingMessage encoding:[NSString defaultCStringEncoding]] otherButtonTitles:[NSString stringWithCString:kAlertButtonContinuePairingMessage encoding:[NSString defaultCStringEncoding]], nil];
        [alert show];
    } else if ([path isEqualToString:[NSString stringWithFormat:@"/%s", kPathHCCMsg8]]) {
        // Process the HCC msg6 query, which is built in the Provider's HCC VC via the following command:
        /*
         NSString* path = [[NSString alloc] initWithFormat:@"/%s?%s=%s", kPathHCCMsg8, kQueryKeyDeposit, [[PersonalDataController absoluteStringDeposit:_our_data.deposit] cStringUsingEncoding:[NSString defaultCStringEncoding]]];
         */
        
        NSString* query = [url query];
        NSArray* key_value_pairs = [query componentsSeparatedByString:[NSString stringWithFormat:@"%c", kPathDelimiter]];
        for (int i = 0; i < [key_value_pairs count]; ++i) {
            NSString* key_value_pair = [key_value_pairs objectAtIndex:i];
            
            // Note, the base64 representation of the public key can legally have the character '='.  Thus, we need to *only* get the *first* instance of "=" in key_value_pair.
            
            NSRange delimiter = [key_value_pair rangeOfString:@"="];
            NSString* key = [key_value_pair substringWithRange:NSMakeRange(0, delimiter.location)];
            NSString* value = [key_value_pair substringWithRange:NSMakeRange(delimiter.location + 1, ([key_value_pair length] - delimiter.location) - 1)];
            
            if (kDebugLevel > 1)
                NSLog(@"ConsumerMVC:checkNSUserDefaults: working with key: %s, value: %s, from pair: %s.", [key cStringUsingEncoding:[NSString defaultCStringEncoding]], [value cStringUsingEncoding:[NSString defaultCStringEncoding]], [key_value_pair cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            
            if ([key caseInsensitiveCompare:[NSString stringWithCString:kQueryKeyDeposit encoding:[NSString defaultCStringEncoding]]] == NSOrderedSame) {
                if (kDebugLevel > 3)
                    NSLog(@"ConsumerMVC:checkNSUserDefaults: processing challenge: %s", [value cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                
                // TODO(aka) Not really necessary, as deposit (in string form) should not have whitespace.
                NSString* de_urlified = [value stringByReplacingPercentEscapesUsingEncoding:[NSString defaultCStringEncoding]];
                
                if (kDebugLevel > 1)
                    NSLog(@"ConsumerMVC:checkNSUserDefaults: building deposit from: %s", [de_urlified cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                
                _potential_provider.deposit = [PersonalDataController stringToDeposit:de_urlified];
            } else {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove URL so no one attempts to processes it again
                err_msg = [NSString stringWithFormat:@"ConsumerMasterVC:checkNSUserDefaults: unknown query key: %s.", [key cStringUsingEncoding:[NSString defaultCStringEncoding]]];
                return err_msg;
            }
        }  // for (int i = 0; i < [key_value_pairs count]; ++i) {
        
        // If we didn't get everything, notify the user, than move on with life.
        if (![PersonalDataController isDepositComplete:_potential_provider.deposit]) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove URL so no one attempts to processes it again
            err_msg = [[NSString alloc] initWithFormat:@"ConsumerMasterVC:checkNSUserDefaults: Failed to parse: %s.", [url_string cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            return err_msg;
        }
        
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove the processed URL
        
        // At this point, the user must choose which AddressBook entry to use for this message (to lookup in _potential_providers).
        err_msg = [self getProviderIdentity:HCC_MODE_PROVIDER_DEPOSIT_SENT];  // XXX TODO(aka) should we return message or bool?  getConsumer handles errors, right?
        if (err_msg != nil)
            return err_msg;
        
        HCCPotentialPrincipal* potential_principal = [_potential_providers objectForKey:_potential_provider.identity];
        if (potential_principal == nil) {
            err_msg = [[NSString alloc] initWithFormat:@"ConsumerMasterVC:checkNSUserDefaults: no entry in _potential_providers for: %s.", [_potential_provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            return err_msg;
        }
        
        // HCC pairing is complete, so add this potential provider to our list of providers!
        err_msg = [_provider_list addProvider:potential_principal.principal];
        if (err_msg != nil)
            return err_msg;

        // Finally, remove the potential consumer from our dictionary.
        [_potential_providers removeObjectForKey:potential_principal.principal.identity];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove it processed URL
        err_msg = [[NSString alloc] initWithFormat:@"ConsumerMasterVC:checkNSUserDefaults: unknown processor: %s, or path: %s.", [processor cStringUsingEncoding:[NSString defaultCStringEncoding]], [path cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        return err_msg;
    }
    
#if 0
    // For Profiling: Find elapsed time and convert to milliseconds, since NSDate start is earlier than now, we negate (-) our modifier in conversion.
    
    NSString* msg = [[NSString alloc] initWithFormat:@"ConsumerMasterVC:checkNSUserDefaults: PROFILING SMS receipt time: %s.", [[[NSDate date] description] cStringUsingEncoding:[NSString defaultCStringEncoding]]];
    UILocalNotification* notice = [[UILocalNotification alloc] init];
    notice.alertBody = msg;
    notice.alertAction = @"Show";
    [[UIApplication sharedApplication] presentLocalNotificationNow:notice];
#endif
    
    return nil;
}

#pragma mark - Actions

- (IBAction) showProviderDetails:(id)sender {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerMVC:showProviderDetails: called.");
    
    [self performSegueWithIdentifier:@"ShowProviderListDataView" sender:self];
}

#pragma mark - Consumer's utility functions

- (NSString*) getProviderIdentity:(int)mode {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerMVC:getProviderIdentity: called.");
    
    NSString* err_msg = nil;
    
    // First request authorization to Address Book (note, don't make static, as address book could change, no?).
    ABAddressBookRef address_book_ref = ABAddressBookCreateWithOptions(NULL, NULL);
    
    __block BOOL access_explicitly_granted = NO;
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        /* if (ABAddressBookRequestAccessWithCompletion != NULL) { */ // TODO(aka) check for if we're on iOS 6
        dispatch_semaphore_t status = dispatch_semaphore_create(0);
        ABAddressBookRequestAccessWithCompletion(address_book_ref,
                                                 ^(bool granted, CFErrorRef error) {
                                                     access_explicitly_granted = granted;
                                                     dispatch_semaphore_signal(status);
                                                 });
        dispatch_semaphore_wait(status, DISPATCH_TIME_FOREVER);  // wait until user gives us access
    }
    
    CFRelease(address_book_ref);
    
    if (!access_explicitly_granted &&
        ((ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied) ||
         (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined))) {
            err_msg = [[NSString alloc] initWithFormat:@"ConsumerMasterVC:getProviderIdentity: Unable to respond to pairing request without access to Address Book."];
            return err_msg;
        }
    
    // Second, launch the people picker, so user can choose correct contact.
    ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
    picker.peoplePickerDelegate = self;
    
    switch (mode) {
        case HCC_MODE_PROVIDER_CHALLENGE_SENT :
            picker.navigationBar.topItem.title = @"Choose Contact That Sent Challenge";
            picker.navigationBar.topItem.prompt = @"Prompt";
            break;
        case HCC_MODE_PROVIDER_PUBKEY_SENT :
            picker.navigationBar.topItem.title = @"Choose Contact That Sent Public Key";
            picker.navigationBar.topItem.prompt = @"Prompt";
            break;
        case HCC_MODE_PROVIDER_RESPONSE_SENT :
            picker.navigationBar.topItem.title = @"Choose Contact That Sent Response";
            picker.navigationBar.topItem.prompt = @"Prompt";
            break;
        case HCC_MODE_PROVIDER_DEPOSIT_SENT :
            picker.navigationBar.topItem.title = @"Choose Contact That Sent Deposit";
            picker.navigationBar.topItem.prompt = @"Prompt";
            break;
        default:
            picker.navigationBar.topItem.title = @"Choose Contact That Sent Pairing Request";
            picker.navigationBar.topItem.prompt = @"Prompt";
    }
    
    [self presentViewController:picker animated:YES completion:nil];  // TODO(aka) hopefully, this isn't called asynchronously ...
    
    NSLog(@"ConsumerMVC:getProviderIdentity: DEBUG: Checking that the delegate peoplePickerNavigationController: does indeed block!");
    
    // Make sure we got the data we need from the Address Book ...
    if (_potential_provider == nil) {
        NSString* err_msg = [NSString stringWithFormat:@"ConsumerMasterVC:getProviderIdentity: _potential_provider is nil."];
        return err_msg;
    } else if (_potential_provider.identity == nil || [_potential_provider.identity length] == 0) {
        NSString* err_msg = [NSString stringWithFormat:@"Either no Address Book entry chosen or entry does not have an identity, so ignoring pairing message."];
#if 0  // XXX TODO(aka) Should we offer the user another attempt at choosing the correct entry?  Perhaps a retry-count? We'd need to set the otherButtonTitle and delegate routine!  How would this work?  The delegate coudn't get back here, could it?
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ConsumerMasterVC:getProviderIdentity:" message:err_msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
#endif
        return err_msg;
    } else if (_potential_provider.email_address == nil || [_potential_provider.email_address length] == 0) {
        NSString* err_msg = [NSString stringWithFormat:@"Address Book entry for %s does not contain an e-mail address.", [_potential_provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        return err_msg;
    } else if (_potential_provider.mobile_number == nil || [_potential_provider.mobile_number length] == 0) {
        NSString* err_msg = [NSString stringWithFormat:@"Address Book entry for %s does not contain a mobile phone number.", [_potential_provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        return err_msg;
    }
    
    return nil;
}

#pragma mark - Delegate callbacks

// ABPeoplePicker delegate functions.
- (BOOL) peoplePickerNavigationController:(ABPeoplePickerNavigationController*)people_picker shouldContinueAfterSelectingPerson:(ABRecordRef)person {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerMVC:peoplePickerNavigationController:shouldContinueAfterSelectingPerson: called.");
    
    NSString* first_name = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonFirstNameProperty);
    NSString* last_name = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonLastNameProperty);
    NSString* middle_name = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonMiddleNameProperty);
    
    // Build our identity (from the contact selection).
    NSString* identity = [[NSString alloc] init];
    if (first_name != nil) {
        identity = [identity stringByAppendingFormat:@"%s", [first_name cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        if (middle_name != nil)
            identity = [identity stringByAppendingFormat:@" %s", [middle_name cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        if (last_name != nil)
            identity = [identity stringByAppendingFormat:@" %s", [last_name cStringUsingEncoding:[NSString defaultCStringEncoding]]];
    } else if (last_name != nil) {
        identity = [identity stringByAppendingFormat:@"%s", [last_name cStringUsingEncoding:[NSString defaultCStringEncoding]]];
    } else {
        if (kDebugLevel > 0)
            NSLog(@"ConsumerMVC:peoplePickerNavigationController:shouldContinueAfterSelectingPerson: identity not set.");
        
        // Fall-through to wipe global _potential_provider.
    }
    
    // Build our temporary Principal using the identity we just retrieved.
    if (_potential_provider == nil)
        _potential_provider = [[Principal alloc] init];
    _potential_provider.identity = identity;
    
    if (kDebugLevel > 1)
        NSLog(@"ConsumerMVC:peoplePickerNavigationController:shouldContinueAfterSelectingPerson: identity set to: %s.", [_potential_provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    // Look for the additional data we need, specifically; mobile phone number and e-mail address.
    NSString* mobile_number = nil;
    ABMultiValueRef phone_numbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
    for (int i = 0; i < ABMultiValueGetCount(phone_numbers); ++i) {
        CFStringRef label = ABMultiValueCopyLabelAtIndex(phone_numbers, i);
        if (CFStringCompare(kABPersonPhoneMobileLabel, label, kCFCompareCaseInsensitive) == 0)
            mobile_number = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(phone_numbers, i);
    }
    _potential_provider.mobile_number = mobile_number;
    
    // Unlike our cell phone, we'll take the first e-mail address specified.
    NSString* email_address = nil;
    NSString* email_label = nil;
    ABMultiValueRef email_addresses = ABRecordCopyValue(person, kABPersonEmailProperty);
    if (ABMultiValueGetCount(email_addresses) > 0) {
        email_address = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(email_addresses, 0);
        email_label = (__bridge_transfer NSString*)ABMultiValueCopyLabelAtIndex(email_addresses, 0);
    }
    _potential_provider.email_address = email_address;
    
    if (kDebugLevel > 0)
        NSLog(@"ConsumerMVC:peoplePickerNavigationController:shouldContinueAfterSelectingPerson: Got phone (%s): %s, e-mail (%s): %s.", [(NSString*)kABPersonPhoneMobileLabel cStringUsingEncoding:[NSString defaultCStringEncoding]], [mobile_number cStringUsingEncoding:[NSString defaultCStringEncoding]], [email_label cStringUsingEncoding:[NSString defaultCStringEncoding]], [email_address cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    if ([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] == NSOrderedAscending) {
        [self dismissViewControllerAnimated:YES completion:nil];  // in 8.0+ people picker dismisses by itself
    }
    
    return NO;
}

- (BOOL) peoplePickerNavigationController:(ABPeoplePickerNavigationController*)people_picker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerMVC:peoplePickerNavigationController:shouldContinueAfterSelectingPerson:property:identifier: called.");
    
    return NO;
}

- (void) peoplePickerNavigationController:(ABPeoplePickerNavigationController*)people_picker didSelectPerson:(ABRecordRef)person {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerMVC:peoplePickerNavigationController:didSelectingPerson: called (%d).", [NSThread isMainThread]);
    
    [self peoplePickerNavigationController:people_picker shouldContinueAfterSelectingPerson:person];
}

- (void) peoplePickerNavigationController:(ABPeoplePickerNavigationController*)people_picker didSelectPerson:(ABRecordRef)person     property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerMVC:peoplePickerNavigationController:didSelectingPerson:property:identifier: called (%d).", [NSThread isMainThread]);
    
    [self peoplePickerNavigationController:people_picker shouldContinueAfterSelectingPerson:person property:property identifier:identifier];
}

- (void) peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController*)people_picker {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerMVC:peoplePickerNavigationControllerDidCancel: called.");
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

// MKMapView delegate functions.
- (MKAnnotationView*) mapView:(MKMapView*)map_view viewForAnnotation:(id <MKAnnotation>)annotation {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerMVC:mapView:viewForAnnotation: called.");
    
    // If we are plotting the user's location, just return.
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    // Use a MKAnnotationView w/image for the pin.
    ProviderAnnotation* our_annotation = (ProviderAnnotation*)annotation;
    if (kDebugLevel > 2)
        NSLog(@"ConsumerMVC:mapView:viewForAnnotation: custom annotation using index: %ld, color: %lu, image: %s and reuse id: %s.", (long)our_annotation.index, (unsigned long)our_annotation.color, [our_annotation.image_filename cStringUsingEncoding:[NSString defaultCStringEncoding]], [our_annotation.reuse_id cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    MKAnnotationView* custom_view = (MKAnnotationView*)[map_view dequeueReusableAnnotationViewWithIdentifier:our_annotation.reuse_id];
    if (custom_view == nil)
        custom_view = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:our_annotation.reuse_id];
    else
        custom_view.annotation = annotation;
    
    UIImage* pin_image = [UIImage imageNamed:our_annotation.image_filename];
    [custom_view setImage:pin_image];
    custom_view.canShowCallout = YES;
    
    // Add our disclosure button (programmatically).
    UIButton* disclosure_button = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    //[disclosure_button setFrame:CGRectMake(0, 0, 30, 30)];
    [disclosure_button setTitle:annotation.title forState:UIControlStateNormal];
    [disclosure_button addTarget:self action:@selector(showProviderDetails:) forControlEvents:UIControlEventTouchUpInside];
    custom_view.rightCalloutAccessoryView = disclosure_button;
    
    return custom_view;
}

// UIAlertView delegate functions.
- (void) alertView:(UIAlertView*)alert_view clickedButtonAtIndex:(NSInteger)button_index {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerMVC:alertView:clickedButtonAtIndex: called.");
    
 	NSString* title = [alert_view buttonTitleAtIndex:button_index];
	if([title isEqualToString:[NSString stringWithCString:kAlertButtonContinuePairingMessage encoding:[NSString defaultCStringEncoding]]]) {
        if (kDebugLevel > 0)
            NSLog(@"ConsumerMVC:alertView:clickedButtonAtIndex: matched ContinuePairingMessage.");
        
        // Segue to AddProviderHCC VC, to continue with pairing protocol.
        [self performSegueWithIdentifier:@"ShowAddProviderHCCViewID" sender:nil];
	} else if([title isEqualToString:[NSString stringWithCString:kAlertButtonCancelPairingMessage encoding:[NSString defaultCStringEncoding]]]) {
        if (kDebugLevel > 0)
            NSLog(@"ConsumerMVC:alertView:clickedButtonAtIndex: matched CancelPairingMessage.");
        
        // Hmm, we need to remove the potential consumer from our dictionary.
        [_potential_providers removeObjectForKey:_potential_provider.identity];  // TODO(aka) not thread safe
	} else {
        NSLog(@"ConsumerMVC:alertView:clickedButtonAtIndex: TODO(aka) unknown title: %s", [title cStringUsingEncoding:[NSString defaultCStringEncoding]]);
	}
    
    NSLog(@"ConsumerMVC:alertView:clickedButtonAtIndex: DEBUG: XXX Does ViewDidAppear get called next?");
    [self configureView:YES];  // XXX Do we need this?  Won't viewDidAppear: get called?
}

// ProviderMasterViewController
- (void) updateIdentity:(NSString*)identity {
    if (kDebugLevel > 3)
        NSLog(@"ConsumerMVC:updateIdentity: called.");
    
    // XXX TODO(aka) I don't think this call is used anymore!
    
    if (identity != nil && [identity length] > 0) {
        _our_data.identity = identity;
        _our_data.identity_hash = [PersonalDataController hashMD5String:_our_data.identity];
    }
    
    // TODO(aka) I don't think I need a configureView here, and besides, I think hashMD5* is asnchronous
}

- (void) updatePersonalDataController {
    if (kDebugLevel > 3)
        NSLog(@"ConsumerMVC:updatePersonalDataController: called.");
    
    // The Provider MVC generated new info, but hopefully it saved state, so we can just slurp in the data from the state saved on disc.
    [_our_data loadState];
}

- (void) addSelfToProviders:(NSString*)identity fileStoreURL:(NSURL*)file_store keyBundleURL:(NSURL*)key_bundle {
    if (kDebugLevel > 3)
        NSLog(@"ConsumerMVC:addSelfToProviders: called.");

    Principal* tmp_provider = [[Principal alloc] initWithIdentity:identity];
    
    [tmp_provider setFile_store_url:file_store];
    [tmp_provider setKey_bundle_url:key_bundle];
    
    // If we already exist, delete us first.
    if ([_provider_list containsObject:tmp_provider]) {
        if (kDebugLevel > 2)
            NSLog(@"ConsumerMVC:addSelfToProviders: We alraedy exist, need to delete first!");
        
        [_provider_list deleteProvider:tmp_provider saveState:NO];
    }
    
    // Next, fetch our key-bundle and the history logs (if available).
    BOOL state_changed = false;
    [self updateProviderData:tmp_provider stateChanged:&state_changed];
    
    // Finally, add ourselves as a provider.
    if (kDebugLevel > 0)
        NSLog(@"ConsumerMVC:addSelfToProviders: adding %@ to provider list.", [tmp_provider serialize]);
    
    NSString* err_msg = [_provider_list addProvider:tmp_provider];
    if (err_msg != nil) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ConsumerMasterVC:addSelfToProviders: addProvider()" message:err_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
        [alert show];
    }
    
    NSLog(@"ConsumerMVC:addSelfToProviders: DEBUG: XXX Do we need this configureView here?  Won't viewDidAppear: get called?");
    [self configureView:YES];
}

- (void) addConsumerToProviders:(Principal*)consumer {
    if (kDebugLevel > 3)
        NSLog(@"ConsumerMVC:addConsumerToProviders: called.");
    
    // Add this consumer as a provider.  Note, if this consumer already exists in our list, then we don't add it (as important information like symmetric keys or file-stores could be overwritten, i.e., the ConsumerMaster VC gets that info, the ProviderMaster VC does not have it!).
    
#if 1  // SIMULATOR HACK:
    // The stupid simulator can't scroll up to the "delete principal" button in ProviderListDataViewController!
    UIDevice* ui_device = [UIDevice currentDevice];
    if ([ui_device.name caseInsensitiveCompare:@"iPhone Simulator"] == NSOrderedSame) {
        NSLog(@"ConsumerMasterVC:addConsumerToProvider: Found device iPhone Simulator.");
        
        if ([_provider_list containsObject:consumer])
            [_provider_list deleteProvider:consumer saveState:NO];
    }
#endif
    
    if (![_provider_list containsObject:consumer]) {
        if (kDebugLevel > 0)
            NSLog(@"ConsumerMVC:addConsumerToProviders: Adding %@ to provider list.", [consumer serialize]);
        
        NSString* err_msg = [_provider_list addProvider:consumer];
        if (err_msg != nil) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ConsumerMasterVC:addConsumerToProviders: addProvider()" message:err_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
            [alert show];
        }
        
        NSLog(@"ConsumerMVC:addSelfToProviders: DEBUG: XXX Do we need this configureView here?  Won't viewDidAppear: get called?");
        [self configureView:YES];  // XXX Do we need this?  Won't viewDidAppear: get called?
    }
}

@end

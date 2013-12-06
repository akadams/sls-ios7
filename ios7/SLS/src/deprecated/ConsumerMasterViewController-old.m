//
//  ConsumerMasterViewController.m
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 4/1/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import <CommonCrypto/CommonCryptor.h>

#import "ConsumerMasterViewController.h"
#import "ProviderAnnotation.h"
#import "Provider.h"
#import "NSData+Base64.h"
#import "security-defines.h"


static const int kDebugLevel = 5;

static const size_t kChosenCipherKeySize = CIPHER_KEY_SIZE;
static const size_t kChosenCipherBlockSize = CIPHER_BLOCK_SIZE;

static const char* kQueryKeyEncryptedKey = URI_QUERY_KEY_ENCRYPTED_KEY;
static const char* kQueryKeyFileStoreURL = URI_QUERY_KEY_FS_URL;
static const char* kQueryKeyIdentity = URI_QUERY_KEY_IDENTITY;

static const char* kDownloadDataFilename = "fetch_data_toggle.txt";

static const float kFetchDataTimeout = 300.0;


@interface ConsumerMasterViewController ()
@end

@implementation ConsumerMasterViewController

@synthesize our_data = _our_data;
@synthesize provider_list_controller = _provider_list_controller;
@synthesize map_view = _map_view;
@synthesize fetch_data_toggle = _fetch_data_toggle;

static BOOL _add_self_status = false;

- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerMasterViewController:init: called.");
    
    self = [super init];
    if (self) {
        _our_data = nil;
        _provider_list_controller = nil;
        _fetch_data_toggle = true;
        
        return self;
    }
    
    return nil;
}

- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerMasterViewController:initWithNibName:bundle: called, but not implemented.");
    
    self = [super initWithNibName:nib_name_or_nil bundle:nib_bundle_or_nil];
    if (self) {
        // Custom initialization
        _our_data = nil;
        _provider_list_controller = nil;
        _fetch_data_toggle = true;
    }
    
    return self;
}

- (void) loadState {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerMasterViewController:loadState: called.");
    
    if (_our_data == nil) {
        if (kDebugLevel > 0)
            NSLog(@"ConsumerMasterViewController:loadState: _our_data is nil.");

        _our_data = [[PersonalDataController alloc] init];
    }
    
    // Populate (or generate) the data associated with our class' data member's controllers.
    
    [_our_data loadState:PDC_CONSUMER_MODE];
    
    // Note, _our_data may still be empty at this point if state was not previously saved.
    
    // Build our provider list controller.
    _provider_list_controller = [[ProviderListController alloc] init];
    [_provider_list_controller loadState]; // grab any previous state
    
    for (int i = 0; i < [_provider_list_controller countOfList]; ++i) {
        if (kDebugLevel > 1)
            NSLog(@"ConsumerMasterViewController:loadState: provider[%d]: %s.", i, [[[_provider_list_controller objectInListAtIndex:i] absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        
        if ([[[_provider_list_controller objectInListAtIndex:i] identity] caseInsensitiveCompare:_our_data.identity] == NSOrderedSame)
            _add_self_status = true;
    }
    
    // Figure out if location sharing was turned on or not.
    NSString* tmp_string = [PersonalDataController loadStateString:[NSString stringWithCString:kDownloadDataFilename encoding:[NSString defaultCStringEncoding]]];
    _fetch_data_toggle = [tmp_string boolValue];
}

- (void) viewDidLoad {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerMasterViewController:viewDidLoad: called.");
    
    [super viewDidLoad];
    
	// Do any additional setup after loading the view, typically from a nib.
    
    // Attempt to fetch any new location data (for all our providers), which then calls configureView()!
#if 0
    // XXX This may be causing us to not load fast enough!
    [self updateProviderData];
#else
    NSLog(@"ConsumerMasterViewController:viewDidLoad: TODO(aka) We want our time-out to updateProviderData() to be very short when we call configureView from viewDidLoad(), but I think that happens for free, because last_fetch in all our providers will be nil ...");
    
    [self configureView:true];  // first time in, set the map focus
#endif
    
    
#if 0
    // XXX Testing NSString and regex routines.
    NSString* foobar = @"foo=bar=";
    /*
    NSError* error = NULL;
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"=" options:NSRegularExpressionCaseInsensitive error:&error];
    NSTextCheckingResult* match = [regex firstMatchInString:foobar options:0 range:NSMakeRange(0, [foobar length])];
   if (match) {
        NSRange foo_range = [match rangeAtIndex:1];
        NSRange bar_range = [match rangeAtIndex:2];
            NSString* foo = [foobar substringWithRange:NSMakeRange(0, foo_range.location)];
       NSLog(@"ConsumerMasterViewController:viewDidLoad: XXXXX foobar length %d, foo range location: %d, foo length %d, bar range location: %d.", [foobar length], foo_range.location, [foo length], bar_range.location);
        //NSString* bar = [foobar substringWithRange:NSMakeRange(bar_range.location, -1)];
        NSString* bar = @"";
       NSLog(@"ConsumerMasterViewController:viewDidLoad: XXXXX foo: %s, bar: %s, foobar: %s.", [foo cStringUsingEncoding:[NSString defaultCStringEncoding]], [bar cStringUsingEncoding:[NSString defaultCStringEncoding]], [foobar cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    }
    */
    
    NSRange delimiter = [foobar rangeOfString:@"="];
    NSString* foo = [foobar substringWithRange:NSMakeRange(0, delimiter.location)];
      NSString* bar = [foobar substringWithRange:NSMakeRange(delimiter.location + 1, ([foobar length] - delimiter.location) - 1)];
    NSLog(@"ConsumerMasterViewController:viewDidLoad: XXXXX foo: %s, bar: %s, foobar: %s.", [foo cStringUsingEncoding:[NSString defaultCStringEncoding]], [bar cStringUsingEncoding:[NSString defaultCStringEncoding]], [foobar cStringUsingEncoding:[NSString defaultCStringEncoding]]);
#endif
    
}

- (void) viewDidUnload {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerMasterViewController:viewDidLoad: called.");
    
    [self setOur_data:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void) configureView:(BOOL)set_map_focus {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerMasterViewController:configureView: called.");
    
    // Make sure we have an identity
    // Refresh UIMapView.
    NSMutableArray* annotation_list = [[NSMutableArray alloc] init];
    for (id annotation in _map_view.annotations) {
        if (annotation != _map_view.userLocation) {
            [annotation_list addObject:annotation];  // collect all our pins
        }
    }
    [_map_view removeAnnotations:annotation_list];
    
    CLLocationCoordinate2D center_view = [self plotProviderLocations:nil];  // attempt to plot all providers
    
    if (set_map_focus) {
        if (kDebugLevel > 0)
            NSLog(@"ConsumerMasterViewController:configureView: using center lon: %f, lat: %f.", center_view.longitude, center_view.latitude);
        
        [_map_view setCenterCoordinate:center_view animated:true];
    }
    
    /*
     MKMapRect current_view = [self plotProviderLocations:nil];  // attempt to plot all providers
     
     // Position the map so that all overlays and annotations are visible on screen.
     if (!MKMapRectEqualToRect(current_view, MKMapRectNull)) {
    if (kDebugLevel > 1)
        NSLog(@"ConsumerMasterViewController:configureView: focus set to: .");
     _map_view.visibleMapRect = current_view;
    }
*/
    // Finally, setup a periodic alarm to fetch provider location data.
    [self setTimerForFetchingData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerMasterViewController:shouldAutorotateToInterfaceOrientation: called.");
    
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void) prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerMasterViewController:prepareForSeque: called.");
    
    if ([[segue identifier] isEqualToString:@"ShowAddProviderView"]) {
        if (kDebugLevel > 0)
            NSLog(@"ConsumerMasterViewController:prepareForSeque: Segue'ng to ShowAddProviderView.");
        
        // Set ourselves up as the delegate and pass in *our_data*.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        AddProviderViewController* view_controller = 
        (AddProviderViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        
        view_controller.our_data = _our_data;
        view_controller.delegate = self;
        
        if (kDebugLevel > 0)
            NSLog(@"ConsumerMasterViewController:prepareForSegue: ShowAddProviderView controller's identity: %s, key-deposit: %s, and public-key: %s.", [view_controller.our_data.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [[PersonalDataController absoluteStringKeyDeposit:view_controller.our_data.key_deposit] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[view_controller.our_data.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    } else if ([[segue identifier] isEqualToString:@"ShowConsumerDataView"]) {
        if (kDebugLevel > 0)
            NSLog(@"ConsumerMasterViewController:prepareForSeque: Segue'ng to ShowConsumerDataView.");
        
        // Set ourselves up as the delegate and pass in *our_data*.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        ConsumerDataViewController* view_controller = (ConsumerDataViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        view_controller.our_data = _our_data;
        view_controller.provider_list_controller = _provider_list_controller;
        view_controller.fetch_data_toggle = _fetch_data_toggle;
        view_controller.add_self_status = _add_self_status;
        view_controller.delegate = self;
        
        if (kDebugLevel > 0)
            NSLog(@"ConsumerMasterViewController:prepareForSegue: the ConsumerDataView controller's identity: %s, key-deposit: %s, and public-key: %s.", [view_controller.our_data.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [[PersonalDataController absoluteStringKeyDeposit:view_controller.our_data.key_deposit] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[view_controller.our_data.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    } else if ([[segue identifier] isEqualToString:@"ShowProviderListDataView"]) {
        if (kDebugLevel > 0)
            NSLog(@"ConsumerMasterViewController:prepareForSeque: Segue'ng to ShowProviderListDataView.");
        
        // Get the provider in the annotation ...
        Provider* tmp_provider = [_provider_list_controller objectInListAtIndex:0];
        
        // Send *our data* and set ourselves up as the delegate.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        ProviderListDataViewController* view_controller = (ProviderListDataViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        view_controller.provider = tmp_provider;
        view_controller.delegate = self;
        
        if (kDebugLevel > 0)
            NSLog(@"ConsumerMasterViewController:prepareForSegue: the ProviderListDataView controller's identity: %s, file-store: %s.", [view_controller.provider.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [[view_controller.provider.file_store absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    } else {
        if (kDebugLevel > 0)
            NSLog(@"ConsumerMasterViewController:prepareForSeque: TODO(aka) unknown segue: %s.", [[segue identifier] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    }
}

- (IBAction) unwindToConsumerMaster:(UIStoryboardSegue*)segue {
    // XXX TODO(aka) If we use the unwind segue, which we can with a Navigation Bar, then we don't need a delegate!
    
    if (kDebugLevel > 2)
        NSLog(@"ConsumerMasterViewController:unwindToConsumerMaster: called.");
    
    UIViewController* sourceViewController = segue.sourceViewController;
    
    if ([sourceViewController isKindOfClass:[ConsumerDataViewController class]]) {
        if (kDebugLevel > 2)
            NSLog(@"ConsumerMasterViewController:unwindToConsumerMaster: called from ConsumerDataViewController.");
        
        ConsumerDataViewController* source = [segue sourceViewController];
        if (source.identity_changed || source.pub_keys_changed || source.deposit_changed) {
            if (source.our_data == nil) {
                NSLog(@"ConsumerMasterViewController:unwindToConsumerMaster: TODO(aka) ERROR: PersonalDataController is nil!");
                // XXX [self dismissViewControllerAnimated:YES completion:nil];
                return;
            }
            
            _our_data = source.our_data;  // get the changes
            
            // Now save state, where needed.
            if (source.deposit_changed)
                [_our_data saveKeyDepositState];
            
            if (source.identity_changed)
                [_our_data saveIdentityState];
        }
        
        if (source.fetch_toggle_changed) {
            // Update our fetch data flag and write it out to disk.
            _fetch_data_toggle = source.fetch_data_toggle;
            NSString* tmp_string = [NSString stringWithFormat:@"%d", _fetch_data_toggle];
            [PersonalDataController saveState:[NSString stringWithCString:kDownloadDataFilename encoding:[NSString defaultCStringEncoding]] string:tmp_string];
        }
        
        // XXX TODO(aka) We need to check for a new provider list!
        /*
         if (source.provider_list_changed) {
         if (kDebugLevel > 0)
         NSLog(@"ConsumerMasterViewController:unwindToConsumerMaster: received %lu count provider list and fetch-data: %d.", (unsigned long)[provider_list countOfList], fetch_data_toggle);
         
         if (kDebugLevel > 1) {
         for (int i = 0; i < [provider_list countOfList]; ++i) {
         NSLog(@"ConsumerMasterViewController:unwindToConsumerMaster: provider[%d]: %s.", i, [[[provider_list objectInListAtIndex:i] absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
         }
         }
         
         _provider_list_controller = source.provider_list_controller;
         }
         */
        
        // XXX TODO(aka) We need to check add_self!
        /*
         if (source.add_self_changed) {
         if (_add_self_status) {
         // TODO(aka) Remove ourselves from the provider list!
         } else {
         // We didn't have ourselves loaded in our provider list *and* we requested it, so add ourselves.
         if (kDebugLevel > 1)
         NSLog(@"ConsumerMasterViewController:unwindToConsumerMaster: adding ourselves to the provider list.");
         
         NSLog(@"ConsumerMasterViewController:unwindToConsumerMaster: TODO(aka) How do we set or get the symmetric key and file store?");
         
         Provider* ourselves = [[Provider alloc] initWithIdentity:[NSString stringWithFormat:@"%s", kOurselves]];
         
         _add_self_status = true;
         }
         }
         */
    } else if ([sourceViewController isKindOfClass:[AddProviderViewController class]]) {
        if (kDebugLevel > 2)
            NSLog(@"ConsumerMasterViewController:unwindToConsumerMaster: called from AddProviderViewController.");
        
        AddProviderViewController* source = [segue sourceViewController];
    } else {
            NSLog(@"ConsumerMasterViewController:unwindToConsumerMaster: TODO(aka) Called from unknown ViewController!");
    }
    
    // No need to dismiss the view controller in an unwind segue.
    
    [self configureView:true];
}

- (void) setTimerForFetchingData {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerMasterViewController:setTimerForFetchingData: called.");
    
    NSTimeInterval next_timeout = [_provider_list_controller getNextTimeInterval];
    
    NSLog(@"ConsumerMasterViewController:setTimerForFetchingData: setting timer for %fs.", next_timeout);
    
    [NSTimer scheduledTimerWithTimeInterval:next_timeout target:self selector:@selector(updateProviderData) userInfo:nil repeats:NO];
}    

- (void) updateProviderData {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerMasterViewController:updateProviderData: called: %d.", _fetch_data_toggle);
    
    // First, see if we have any new URLs hanging around from NSUserDefaults.
    [self checkNSUserDefaults];
    
    if (!_fetch_data_toggle)
        return;
    
    // Grab new location data for all providers that we have ...
    for (int i = 0; i < [_provider_list_controller countOfList]; ++i) {
        // Get the provider's information.
        Provider* provider = [_provider_list_controller objectInListAtIndex:i];
        
        // If we don't have a valid file store, might as well skip this provider.
        if (provider.file_store == nil) {
            if (kDebugLevel > 0)
                NSLog(@"ConsumerMasterViewController:updateProviderData: skipping provider[%d]: %s, due to nil file store.", i, [[provider absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            continue;
        }
        
        NSString* error_msg = [provider fetchLocationData];
        if (error_msg != nil) {
            NSString* msg = [[NSString alloc] initWithFormat:@"ConsumerMasterViewController:updateProviderData: %s.", [error_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            //NSLog(@"ConsumerMasterViewController:plotProviderLocations: %s.", [msg cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            
            // In case we figure out how to background fetching data on consumer.
            UILocalNotification* notice = [[UILocalNotification alloc] init];
            notice.alertBody = msg;
            notice.alertAction = @"Show";
            [[UIApplication sharedApplication] presentLocalNotificationNow:notice];
        }
    }
    
    // Plot any new data.
    [self configureView:false];
}

//XXX - (MKMapRect) plotProviderLocations:(Provider*)sole_provider {
- (CLLocationCoordinate2D) plotProviderLocations:(Provider*)sole_provider {
        if (kDebugLevel > 2)
        NSLog(@"ConsumerMasterViewController:plotProviderLocations: called.");
    
    //XXX MKMapRect focus_map_rect = MKMapRectNull;
    CLLocationCoordinate2D center_map;   // set it to the center of US (TODO(aka) move this to @interface!)
	center_map.latitude = 37.250556;
	center_map.longitude = -96.358333;
    
    // Get the location data we currently have for all providers ...
    for (int i = 0; i < [_provider_list_controller countOfList]; ++i) {
        // Get the provider's information.
        Provider* provider = [_provider_list_controller objectInListAtIndex:i];
        
#if 0
        // XXX TODO(aka) Do we really want to do this?  What if there is still history in location list?
        // If we don't have a valid file store, might as well skip this provider.
        if (provider.file_store == nil) {
            if (kDebugLevel > 0)
                NSLog(@"ConsumerMasterViewController:plotProviderLocations: TODO(aka) skipping provider[%d]: %s, due to nil file store.", i, [[provider absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            continue;
        }
#endif        
        if (kDebugLevel > 1)
            NSLog(@"ConsumerMasterViewController:plotProviderLocations: provider[%d]: %s.", i, [[provider absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        
        // See if we are only to operate on a single provider.
        if (sole_provider != nil) {
            if (![provider isEqual:sole_provider])
                if (kDebugLevel > 1)
                    NSLog(@"ConsumerMasterViewController:plotProviderLocations: sole_provider (%s) in use, skipping %s because they don't match.", [sole_provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            continue;
        }
        
        NSLog(@"ConsumerMasterViewController:plotProviderLocations: TODO(aka) How do we degrade history via color or diffusion?");
        
        // Plot the location data history (in time-ascending order).
        CLLocation* previous_location = nil;
        //for (int j = 0; j < [provider.locations count]; ++j) {
        for (int j = (int)[provider.locations count]; j > 0; --j) {
            NSUInteger index = j - 1;
            CLLocation* new_location = [provider.locations objectAtIndex:index];
            
            // Figure out the bearing.
            if (previous_location == nil)
                previous_location = new_location;
            
            if (kDebugLevel > 1)
                NSLog(@"ConsumerMasterViewController:plotProviderLocations: at loop counter %d, index %lu, new location: %s (%fx%f), previous location: %s (%fx%f).", j, (unsigned long)index, [new_location.description cStringUsingEncoding:[NSString defaultCStringEncoding]], new_location.coordinate.longitude, new_location.coordinate.latitude, [previous_location.description cStringUsingEncoding:[NSString defaultCStringEncoding]], previous_location.coordinate.longitude, previous_location.coordinate.latitude );
            
            // Math functions take radians, so convert degrees to radians for the values we need.
            double delta_lon = abs(previous_location.coordinate.longitude - new_location.coordinate.longitude) * M_PI / 180.0;
            double lat_prev = previous_location.coordinate.latitude * M_PI / 180.0;
            double lat_new = new_location.coordinate.latitude * M_PI / 180.0;
            
            double y = sin(delta_lon) * cos(lat_new);
            double x = cos(lat_prev) * sin(lat_new) - sin(lat_prev) * cos(lat_new) * cos(delta_lon);
            double bearing_rads = atan2(y, x);
            
            // Finally, convert our bearing in radians to degrees, and normalize for 0 - 359.
            
            int bearing = ((int)(bearing_rads * 180.0 / M_PI) + 360) % 360;
            
            if (kDebugLevel > 0) {
                NSString* msg = [[NSString alloc] initWithFormat:@"%@ location[%lu]: delta-lon: %f, lat-prev: %f, lat-new: %f, y: %f, x: %f, bearing: %f, bearing in degrees: %d, received course: %f.", [provider identity], (unsigned long)index, delta_lon, lat_prev, lat_new, y, x, bearing_rads, bearing, new_location.course];
                NSLog(@"ConsumerMasterViewController:plotProviderLocations: %s.", [msg cStringUsingEncoding:[NSString defaultCStringEncoding]]);
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
            if (provider.is_focus) {
                center_map = new_location.coordinate;
                
                if (kDebugLevel > 1)
                    NSLog(@"ConsumerMasterViewController:plotProviderLocations: center-map changed to lon: %f, lat: %f", center_map.longitude, center_map.latitude);
                /* XXX
                 MKMapPoint map_point = MKMapPointForCoordinate(new_location.coordinate);
                 focus_map_rect = MKMapRectMake(map_point.x, map_point.y, 0, 0);
                 */
                NSLog(@"ConsumerMasterViewController:plotProviderLocations: TODO(aka) We need to figure out how to set the zoom appropriately!");
            }
            
            previous_location = new_location;
            
            if (kDebugLevel > 2)
                NSLog(@"ConsumerMasterViewController:plotProviderLocations: calling UIMapView delegate addAnnotation() with index %lu.", (unsigned long)index);
            
            [_map_view addAnnotation:annotation];  // this will trigger the MKMapView delegate
        }  // for (int j = [provider.locations count]; j > 0; --j) {
    } // for (int i = 0; i < [_provider_list_controller countOfList]; ++i) {
    
    return center_map;
}

- (void) checkNSUserDefaults {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerMasterViewController:checkNSUserDefaults: called.");
    
    NSString* url_string = [[NSUserDefaults standardUserDefaults] objectForKey:@"url"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // and remove it
    
    if (url_string == nil)
        return;
    
    NSLog(@"ConsumerMasterViewController:checkNSUserDefaults: TOOD(aka) How do we tell if there are multiple NSUserDefaults (i.e., symmetric keys) waiting for us?  While () loop?");
    
    if (kDebugLevel > 0)
        NSLog(@"ConsumerMasterViewController:checkNSUserDefaults: received NSUserDefault string: %s.", [url_string cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    NSURL* url = [[NSURL alloc] initWithString:url_string];
    
    if (kDebugLevel > 0)
        NSLog(@"ConsumerMasterViewController:checkNSUserDefaults: from NSDefaults got scheme: %s, fragment: %s, query: %s, path: %s, parameterString: %s.", [url.scheme cStringUsingEncoding:[NSString defaultCStringEncoding]], [url.fragment cStringUsingEncoding:[NSString defaultCStringEncoding]], [url.query cStringUsingEncoding:[NSString defaultCStringEncoding]], [url.path cStringUsingEncoding:[NSString defaultCStringEncoding]], [url.parameterString cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    // Process the query.
    NSData* encrypted_symmetric_key = nil;
    NSURL* file_store = nil;
    NSString* identity = nil;
    
    // XXX TODO(aka) Make a kURIPathDelimiter!
    NSString* query = [url query];
    NSArray* key_value_pairs = [query componentsSeparatedByString:@"&"];
    for (int i = 0; i < [key_value_pairs count]; ++i) {
        NSString* key_value_pair = [key_value_pairs objectAtIndex:i];
        
        // Note, the base64 representation of the encrypted-key can legally have the character '='.  Thus, we need to *only* get the *first* instance of "=" in the string.
        
        NSRange delimiter = [key_value_pair rangeOfString:@"="];
        NSString* key = [key_value_pair substringWithRange:NSMakeRange(0, delimiter.location)];
        NSString* value = [key_value_pair substringWithRange:NSMakeRange(delimiter.location + 1, ([key_value_pair length] - delimiter.location) - 1)];
        
        if (kDebugLevel > 0)
            NSLog(@"ConsumerMasterViewController:checkNSUserDefaults: working with key: %s, value: %s, from pair: %s.", [key cStringUsingEncoding:[NSString defaultCStringEncoding]], [value cStringUsingEncoding:[NSString defaultCStringEncoding]], [key_value_pair cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        
        if ([key caseInsensitiveCompare:[NSString stringWithCString:kQueryKeyEncryptedKey encoding:[NSString defaultCStringEncoding]]] == NSOrderedSame) {
            if (kDebugLevel > 3)
                NSLog(@"ConsumerMasterViewController:checkNSUserDefaults: processing base64 encrypted symmetric key: %s", [value cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            
            encrypted_symmetric_key = [NSData dataFromBase64String:value];
        } else if ([key caseInsensitiveCompare:[NSString stringWithCString:kQueryKeyFileStoreURL encoding:[NSString defaultCStringEncoding]]] == NSOrderedSame) {
            if (kDebugLevel > 3)
                NSLog(@"ConsumerMasterViewController:checkNSUserDefaults: processing file-store: %s", [value cStringUsingEncoding:[NSString defaultCStringEncoding]]);  
            
            file_store = [[NSURL alloc] initWithString:value];
        } else if ([key caseInsensitiveCompare:[NSString stringWithCString:kQueryKeyIdentity encoding:[NSString defaultCStringEncoding]]] == NSOrderedSame) {
            if (kDebugLevel > 3)
                NSLog(@"ConsumerMasterViewController:checkNSUserDefaults: processing identity: %s", [value cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            
            NSString* de_urlified = [value stringByReplacingPercentEscapesUsingEncoding:[NSString defaultCStringEncoding]];
            
            if (kDebugLevel > 1)
                NSLog(@"ConsumerMasterViewController:checkNSUserDefaults: Setting identity to %s", [de_urlified cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            
            identity = [[NSString alloc] initWithString:de_urlified];
        } else {
            NSLog(@"ConsumerMasterViewController:checkNSUserDefaults: ERROR: unknown Query key: %s.", [key cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        }
    }  // for (int i = 0; i < [key_value_pairs count]; ++i) {
    
    // If we got an identity, key & file-store, add them to our provider.
    if (identity == nil || encrypted_symmetric_key == nil || file_store == nil) {
        NSLog(@"ConsumerMasterViewController:checkNSUserDefaults: WARN: either identity, key or file-store not found in %s.", [url_string cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        return;
    }
    
    // Unencrypt the symmetric key.
    NSData* symmetric_key = [_our_data decryptSymmetricKey:encrypted_symmetric_key];
    if (symmetric_key == nil) {
        NSLog(@"ConsumerMasterViewController:checkNSUserDefaults: ERROR: unable to decrypt symmetric key.");
        return;
    }
    
    // Build our new Provider object.
    Provider* tmp_provider = [[Provider alloc] initWithIdentity:identity];
    tmp_provider.file_store = file_store;  // TODO(aka) convertFileStore()?
    tmp_provider.key = symmetric_key;
    
    // Add our new provider (and update our state files).
    NSString* error_msg = [_provider_list_controller addProvider:tmp_provider];
    if (error_msg != nil) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ConsumerMasterViewController:checkNSUserDefaults" message:error_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
        [alert show];
    }
    
    // For Debugging: Find elapsed time and convert to milliseconds, since NSDate start is earlier than now, we negate (-) our modifier in conversion.

    NSString* msg = [[NSString alloc] initWithFormat:@"ConsumerMasterViewController:checkNSUserDefaults: PROFILING SMS receipt time: %s.", [[[NSDate date] description] cStringUsingEncoding:[NSString defaultCStringEncoding]]];
    UILocalNotification* notice = [[UILocalNotification alloc] init];
    notice.alertBody = msg;
    notice.alertAction = @"Show";
    [[UIApplication sharedApplication] presentLocalNotificationNow:notice];
}

- (IBAction) showProviderDetails:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerMasterViewController:showProviderDetails: called.");
    
    [self performSegueWithIdentifier:@"ShowProviderListDataView" sender:self];
}


// Delegate functions.

// ConsumerDataViewController delegate functions.
- (void) consumerDataViewControllerDidFinish:(PersonalDataController*)our_data providerList:(ProviderListController*)provider_list fetchDataToggle:(BOOL)fetch_data_toggle addSelfStatus:(BOOL)add_self_status {
    if (kDebugLevel > 2)        NSLog(@"ConsumerMasterViewController:consumerDataViewControllerDidFinish:providerList:focusIdentity:fetchDataToggle: called.");
    
    if (our_data == nil) {
        NSLog(@"ConsumerMasterViewController:consumerDataViewControllerDidFinish:providerList: TODO(aka) ERROR: PersonalDataController is nil!");
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    if (kDebugLevel > 0)
        NSLog(@"ConsumerMasterViewController:consumerDataViewControllerDidFinish: received %lu count provider list and fetch-data: %d.", (unsigned long)[provider_list countOfList], fetch_data_toggle);
    
    if (kDebugLevel > 1) {
        for (int i = 0; i < [provider_list countOfList]; ++i) {
            NSLog(@"ConsumerMasterViewController:consumerDataViewControllerDidFinish: provider[%d]: %s.", i, [[[provider_list objectInListAtIndex:i] absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        }
    }
    
    // Okay, overwrite our PersonalDataController and ProviderListController.  Note, their state *should* have been saved when their data was updated within the ComsuerDataViewController.
    
    _our_data = our_data;
    _provider_list_controller = provider_list;
    
    // If we didn't have ourselves loaded in our provider list *and* we requested it, add ourselves.
    if (!_add_self_status && add_self_status) {
        if (kDebugLevel > 1)
            NSLog(@"ConsumerMasterViewController:consumerDataViewControllerDidFinish: adding ourselves to the provider list.");
        
        NSLog(@"ConsumerMasterViewController:consumerDataViewControllerDidFinish: TODO(aka) How do we set or get the symmetric key and file store?");

#if 0
        Provider* ourselves = [[Provider alloc] initWithIdentity:[NSString stringWithFormat:@"%s", kOurselves]];
#endif       
        _add_self_status = true;
    }
    
    // Update our fetch data flag and write it out to disk.
    _fetch_data_toggle = fetch_data_toggle;
    NSString* tmp_string = [NSString stringWithFormat:@"%d", _fetch_data_toggle];
    [PersonalDataController saveState:[NSString stringWithCString:kDownloadDataFilename encoding:[NSString defaultCStringEncoding]] string:tmp_string];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [self configureView:true];
}

- (void) consumerDataViewControllerDidCancel:(ConsumerDataViewController*)controller {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerMasterViewController:consumerDataViewControllerDidCancel: called.");
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

// AddProviderViewController delegate functions.
- (void) addProviderViewControllerDidFinish:(Provider*)provider {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerMasterViewController:addProviderViewControllerDidFinish: called.");
 
#if 0
    // XXX addProvider delets if necessary now
    // If we all ready have one in our list for this provider, remove it.
    if ([_provider_list_controller containsObject:provider]) {
        if (kDebugLevel > 0)
            NSLog(@"ConsumerMasterViewController:addProviderViewControllerDidFinish: new provider indentity (%s) exists in list, deleting it first.", [provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
        NSString* error_msg = [_provider_list_controller deleteProvider:provider];
        if (error_msg != nil) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ConsumerMasterViewController:addProviderViewControllerDidFinish:" message:error_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
            [alert show];
        }
    }
#endif
    
    // Add our new provider (and update our state files).
    NSString* error_msg = [_provider_list_controller addProvider:provider];
    if (error_msg != nil) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ConsumerMasterViewController:addProviderViewControllerDidFinish:" message:error_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
        [alert show];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) addProviderViewControllerDidCancel:(AddProviderViewController*)controller {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerMasterViewController:addProviderViewControllerDidCancel: called.");
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

// ProviderListDataViewController delegate functions.
- (void) providerListDataViewControllerDidFinish:(Provider*)provider {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerMasterViewController:providerListDataViewControllerDidFinish: called.");
    
    if (kDebugLevel > 0)
        NSLog(@"ConsumerMasterViewController:providerListDataViewControllerDidFinish: updating provider \"%s\".", [provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    // Update our provider list (via addProvider which deletes than re-adds).
    NSString* error_msg = [_provider_list_controller addProvider:provider];
    if (error_msg != nil) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ConsumerMasterViewController:providerListDataViewControllerDidFinish:" message:error_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
        [alert show];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [self configureView:false];
}

- (void) providerListDataViewControllerDidCancel:(ProviderListDataViewController*)controller {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerMasterViewController:providerListDataViewControllerDidCancel: called.");
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void) providerListDataViewControllerDidDelete:(Provider*)provider {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerMasterViewController:providerListDataViewControllerDidDelete: called.");
    
    if (![_provider_list_controller containsObject:provider])
        return;
    
    if (kDebugLevel > 0)
        NSLog(@"ConsumerMasterViewController:providerListDataViewControllerDidDelete: deleting provider \"%s\".", [provider.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    NSString* error_msg = [_provider_list_controller deleteProvider:provider saveState:true];
    if (error_msg != nil) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ConsumerMasterViewController:providerListDataViewControllerDidDelete:" message:error_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
        [alert show];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [self configureView:true];
}

// MKMapView delegate functions.
- (MKAnnotationView*) mapView:(MKMapView*)map_view viewForAnnotation:(id <MKAnnotation>)annotation {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerMasterViewController:mapView:viewForAnnotation: called.");
    
    // If we are plotting the user's location, just return.
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;

#if 0
    // Attempt to deque an existing pin first.
    NSString* annotation_id = @"AnnotationID";
    MKPinAnnotationView* pin_view = (MKPinAnnotationView*)[map_view dequeueReusableAnnotationViewWithIdentifier:annotation_id];
    if (pin_view == nil)
        pin_view = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotation_id];
    else
        pin_view.annotation = annotation;
    
    // XXX Add color to annotation class!
    pin_view.pinColor = 0;
    //pin_view.pinColor = MKPinAnnotationColorPurple;
    //pin_view.pinColor = MKPinAnnotationColorGreen;
    [pin_view setCanShowCallout:YES];    
    //pin_view.calloutOffset = CGPointMake(-5, 5);
    //pin_view.userInteractionEnabled = YES;
    //pin_view.animatesDrop = YES;
    //[pin_view setEnabled:YES];

    // Add our disclosure button (programmatically).
    UIButton* disclosure_button = [UIButton buttonWithType:UIButtonTypeDetailDisclosure]; 
    //[disclosure_button setFrame:CGRectMake(0, 0, 30, 30)];
    [disclosure_button setTitle:annotation.title forState:UIControlStateNormal];
    [disclosure_button addTarget:self action:@selector(showProviderInfo) forControlEvents:UIControlEventTouchUpInside];    
    pin_view.rightCalloutAccessoryView = disclosure_button;

    return pin_view;
#else
    // Use a MKAnnotationView w/image for the pin.
    ProviderAnnotation* our_annotation = (ProviderAnnotation*)annotation;
    if (kDebugLevel > 0)
        NSLog(@"ConsumerMasterViewController:mapView:viewForAnnotation: custom annotation using index: %ld, color: %lu, image: %s and reuse id: %s.", (long)our_annotation.index, (unsigned long)our_annotation.color, [our_annotation.image_filename cStringUsingEncoding:[NSString defaultCStringEncoding]], [our_annotation.reuse_id cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
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
    [disclosure_button addTarget:self action:@selector(ShowProviderInfoView) forControlEvents:UIControlEventTouchUpInside];
    custom_view.rightCalloutAccessoryView = disclosure_button;

    return custom_view;
#endif
}

// NSURLConnection delegate functions.
- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerMasterViewController:connection:didReceiveResponse: called.");
    
    // This method is called when the server has determined that it has enough information to create the NSURLResponse.  Note, it can be called multiple times, for example in the case of a redirect, so each time we reset the data.
    
    // TOOD(aka) Figure out which provider this connection belongs to.
    
    // TODO(aka) initialize provider's buffer.

}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerMasterViewController:connection:didReceiveData: called.");
    
    // TOOD(aka) Figure out which provider this connection belongs to.
    
    // TODO(aka) Append the newly received data to the provider's buffer.
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerMasterViewController:connection:didFinishLoading: called.");
    
    // TOOD(aka) Figure out which provider this connection belongs to.
    
    // TODO(aka Do something with the data.
    
    // TODO(aka) Clean up resources.
    connection = nil;    
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError *)error {
    if (kDebugLevel > 2)
        NSLog(@"ConsumerMasterViewController:connection:didFailWithError: called.");
    
    // TOOD(aka) Figure out which provider this connection belongs to.
    
    // TODO(aka) Abort connection and receive data buffer.
    connection = nil;
    
    // Report error.
    NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
}

@end

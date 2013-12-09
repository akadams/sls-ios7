//
//  ProviderMasterViewController.m
//  SLS
//
//  Created by Andrew K. Adams on 11/19/13.
//  Copyright (c) 2013 Andrew K. Adams. All rights reserved.
//

#import "ProviderMasterViewController.h"
#import "ProviderDataViewController.h"
#import "ConsumerListDataViewController.h"
#import "AddConsumerViewController.h"
#import "AddConsumerCTViewController.h"
#import "Principal.h"
#import "NSData+Base64.h"
#import "security-defines.h"  // XXX TODO(aka) Break up SLS URL processing & security defines!

#import "ConsumerMasterViewController.h"  // XXX Just to debug delegate stuff

static const int kDebugLevel = 1;

static const char* kSchemeSLS = URI_SCHEME_SLS;
static const char* kQueryKeyEncryptedKey = URI_QUERY_KEY_ENCRYPTED_KEY;
static const char* kQueryKeyFileStoreURL = URI_QUERY_KEY_FS_URL;
static const char* kQueryKeyIdentity = URI_QUERY_KEY_IDENTITY;


@interface ProviderMasterViewController ()

@end

@implementation ProviderMasterViewController

#pragma mark - Local variables
@synthesize our_data = _our_data;
@synthesize consumer_list_controller = _consumer_list_controller;
@synthesize location_controller = _location_controller;
@synthesize symmetric_keys_controller = _symmetric_keys_controller;
@synthesize delegate = _delegate;

#pragma mark - Outlets
@synthesize table_view = _table_view;

BOOL location_gathering_on_startup;
static BOOL _track_self_status = false;

// Enum CSSM_ALGID_AES taken from SecKeyWrapper.m in CryptoExercises.

// TOOD(aka) I have no idea what value CSSM_ALGID_AES is being set to, i.e, 0x8000000L + 1, 0x8000000L * 2, or just 2?

enum {
    CSSM_ALGID_NONE = 0x00000000L,
    CSSM_ALGID_VENDOR_DEFINED = CSSM_ALGID_NONE + 0x80000000L,
    CSSM_ALGID_AES
};

#pragma mark - Initialization

- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:init: called.");
    
    if (self = [super init]) {
        _our_data = nil;
        _consumer_list_controller = nil;
        _location_controller = nil;
        _symmetric_keys_controller = nil;
        _delegate = nil;
        location_gathering_on_startup = false;
        
        return self;
    }
    
    return nil;
}

- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:initWithNibName: called.");
    
    self = [super initWithNibName:nib_name_or_nil bundle:nib_bundle_or_nil];
    if (self) {
        // Custom initialization
        _our_data = nil;
        _consumer_list_controller = nil;
        _location_controller = nil;
        _symmetric_keys_controller = nil;
        _delegate = nil;
        location_gathering_on_startup = false;
    }
    
    return self;
}

- (id) initWithStyle:(UITableViewStyle)style {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:initWithStyle: called.");
    
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        _our_data = nil;
        _consumer_list_controller = nil;
        _location_controller = nil;
        _symmetric_keys_controller = nil;
        _delegate = nil;
        location_gathering_on_startup = false;
    }

    return self;
}

- (void) loadState {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:loadState: called.");
    
    if (_our_data == nil) {
        if (kDebugLevel > 0)
            NSLog(@"ProviderMasterViewController:loadState: _our_data is nil.");
        
        _our_data = [[PersonalDataController alloc] init];
    }
    
    // Populate (or generate) the data associated with our data member's controllers.
    
    [_our_data loadState];
    
    // Note, my_data may still be empty at this point if state was not previously saved.
    
    // Build our consumer list controller.
    _consumer_list_controller = [[ConsumerListController alloc] init];
    [_consumer_list_controller loadState];  // grab previous state
    
    // Make sure we didn't load any bogus entries ...
    for (int i = 0; i < [_consumer_list_controller countOfList]; ++i) {
        if (kDebugLevel > 4)
            NSLog(@"ProviderMasterViewController:loadState: Consumer[%d]: %s.", i,  [[[_consumer_list_controller objectInListAtIndex:i] absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        
        Principal* consumer = [_consumer_list_controller objectInListAtIndex:i];

        if (consumer.identity == nil) {
            [_consumer_list_controller removeObjectAtIndex:i];
            if (kDebugLevel > 0)
                NSLog(@"ProviderMasterViewController:loadState: Removing NULL entry at index: %d, new count: %lu!", i, (unsigned long)[_consumer_list_controller countOfList]);
            NSString* err_msg = [_consumer_list_controller saveState];
            if (err_msg != nil)
                NSLog(@"ProviderMasterViewController:loadState: %@.", err_msg);
            continue;
        }
    }
    
    // Build our CLLocation controller and set the CoreLocation controller's delegate to us.
    _location_controller = [[CoreLocationController alloc] init];
    _location_controller.delegate = self;
    
    // Load in any previously saved state, and start up location services (if previously on).
    [_location_controller loadState];
    
    if (_location_controller.location_sharing_toggle) {
#if 0
        NSLog(@"ProviderMasterViewController:loadState: TODO(aka) To cut down on possible initial work, we don't start location sharing until viewDidLoad().  The problem with this, is that SLS starts up in consumer mode!");
        
        // To cut down on our pre-viewDidLoad() workload, hold off starting location gathering services *until* viewDidLoad().
        location_gathering_on_startup = true;
#else
        // Note, we want to start up in *power saving* mode, as the *full accuracy* mode can actually prevent us from loading!
        [_location_controller setPower_saving_toggle:true];
        [_location_controller enableLocationGathering];
#endif
    }
    
    // Build our symmetric keys controller.
    // XXX TODO(aka) Why am I using a temp controller here?
    SymmetricKeysController* tmp_keys_controller = [[SymmetricKeysController alloc] init];
    NSArray* new_keys = [tmp_keys_controller loadState];
    
    if (kDebugLevel > 0)
        NSLog(@"ProviderMasterViewController:loadState: loaded %lu symmetric keys into the tmp controller, %lu into new keys.", (unsigned long)[tmp_keys_controller count], (unsigned long)[new_keys count]);
    
    _symmetric_keys_controller = tmp_keys_controller;
    
    // XXX Finally, if we had to generate any new keys, notify the consumers (provided, of course, that our file-store in our personal data is complete!
    
    if ([PersonalDataController isFileStoreComplete:_our_data.file_store]) {
        for (int i = 0; i < [new_keys count]; ++i) {
            NSLog(@"ProviderMasterViewController:loadState: Sending symmetric key for precision level %d.", [[new_keys objectAtIndex:i] intValue]);
            [self sendSymmetricKey:[new_keys objectAtIndex:i] consumer:nil];
        }
        
#if 0
        // XXX TOOD(aka) Code to send our symmetric keys to everyone (if we decide that starting up is a good time to remind all our consumers ...
        
        NSEnumerator* enumerator = [_symmetric_keys_controller keyEnumerator];
        id key;
        while ((key = [enumerator nextObject])) {
            if (kDebugLevel > 0)
                NSLog(@"ProviderMasterViewController:loadState: Sending symmetric key for precision level %d.", [key intValue]);
            [self sendSymmetricKey:key consumer:nil];
        }
#endif
    } else {
        if (kDebugLevel > 0)
            NSLog(@"ProviderMasterViewController:loadState: file-store not complete.");
    }
}

#pragma mark - View management

- (void) viewDidLoad {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:viewDidLoad: called.");
    
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];
    
    if (location_gathering_on_startup)
        [_location_controller enableLocationGathering];
}

- (void) configureView {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:configureView: called.");
}

# pragma mark - Memory management

- (void) didReceiveMemoryWarning {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:didReceiveMemoryWarning: called.");

    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Data source

// UITableView
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView {
    // Return the number of sections.
    return 1;  // using dynamic prototype
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.consumer_list_controller countOfList];
}

- (UITableViewCell *) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:tableView:cellForRowAtIndexPath: called.");
    
    Principal* consumer = [_consumer_list_controller objectInListAtIndex:indexPath.row];
    
    NSLog(@"ProviderMasterViewController:tableView:cellForRowAtIndexPath: working on cell with consumer: %s, precision: %d, with index path: %ld.", [consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [consumer.precision intValue], (long)indexPath.row);
    
#if 0  // TODO(aka) Method with custom cell ...
    static NSString* cell_identifier = @"ConsumerCell";
    static NSString* cell_nib = @"ConsumerCell";
    
    ConsumerCellController* cell = (ConsumerCellController*)[tableView dequeueReusableCellWithIdentifier:cell_identifier];
    if (cell == nil) {
        NSArray* nib_objects = [[NSBundle mainBundle] loadNibNamed:cell_nib owner:self options:nil];
        cell = (ConsumerCellController*)[nib_objects objectAtIndex:0];
        cell.delegate = self;
        // XXX Do I need to nil out our view?
    }
    
    // Add data to cell.
    cell.label.text = consumer.identity;
    cell.label.tag = indexPath.row;
    
    cell.slider.value = (float)[consumer.precision floatValue];
    NSLog(@"ProviderMasterViewController:tableView:cellForRowAtIndexPath: setting slider tag to: %ld.", (long)indexPath.row);
    cell.slider.tag = indexPath.row;
    
    // For now, give button a label representing our tag number.
    NSString* button_title = [[NSString alloc] initWithFormat:@"%ld", (long)indexPath.row];
    [cell.button setTitle:button_title forState:UIControlStateNormal];
    cell.button.tag = indexPath.row;
    return cell;
#else
    // Grab a cell.
    static NSString* pmvc_identifier = @"PMVCCellReuseID";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:pmvc_identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault  reuseIdentifier:pmvc_identifier];
    }
    
    // Set its identity and trust level.
    cell.textLabel.text = consumer.identity;
    [cell.detailTextLabel setText:[NSString stringWithFormat:@"%d", [consumer.precision intValue]]];
    return cell;
#endif
}

/*
// Override to support conditional editing of the table view.
- (BOOL) tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void) tableView:(UITableView )tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void) tableView:(UITableView*)tableView moveRowAtIndexPath:(NSIndexPath*)fromIndexPath toIndexPath:(NSIndexPath*)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL) tableView:(UITableView*)tableView canMoveRowAtIndexPath:(NSIndexPath*)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void) prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:prepareForSeque: called.");
    
    if ([[segue identifier] isEqualToString:@"ShowProviderDataViewID"]) {
        if (kDebugLevel > 1)
            NSLog(@"ProviderMasterViewController:prepareForSeque: Segue'ng to ProviderDataViewController.");
        
        // Set ourselves up as the delegate and pass in *our_data*.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        ProviderDataViewController* view_controller = (ProviderDataViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        view_controller.our_data = _our_data;
        view_controller.location_controller = _location_controller;
        view_controller.symmetric_keys = _symmetric_keys_controller;
        
        // See if we are already tracking ourselves ...
        _track_self_status = false;
        for (int i = 0; i < [_consumer_list_controller countOfList]; ++i) {
            Principal* consumer = [_consumer_list_controller objectInListAtIndex:i];
            if (consumer.identity != nil && [consumer.identity caseInsensitiveCompare:_our_data.identity] == NSOrderedSame) {
                _track_self_status = true;
            }
        }
        view_controller.track_self_status = _track_self_status;
    } else if ([[segue identifier] isEqualToString:@"ShowAddConsumerViewID"]) {
        if (kDebugLevel > 1)
            NSLog(@"ProviderMasterViewController:prepareForSeque: Segue'ng to AddConsumerView Controller.");
        
        // Set ourselves up as the delegate and pass in *our_data*.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        AddConsumerViewController* view_controller = (AddConsumerViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        view_controller.our_data = _our_data;
    } else if ([[segue identifier] isEqualToString:@"ShowConsumerListDataViewID"]) {
        if (kDebugLevel > 1)
            NSLog(@"ProviderMasterViewController:prepareForSeque: Segue'ng to ConsumerListDataView Controller.");
        
        // Set ourselves up as the delegate and pass in *our_data*.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        ConsumerListDataViewController* view_controller = (ConsumerListDataViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        Principal* principal = (Principal*)sender;
        view_controller.consumer = principal;
    } else {
        if (kDebugLevel > 0)
            NSLog(@"ProviderMasterViewController:prepareForSeque: TODO(aka) unknown segue: %s.", [[segue identifier] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

- (IBAction) unwindToProviderMaster:(UIStoryboardSegue*)segue {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:unwindToProviderMaster: called.");
    
    UIViewController* sourceViewController = segue.sourceViewController;
    
    if ([sourceViewController isKindOfClass:[ProviderDataViewController class]]) {
        if (kDebugLevel > 2)
            NSLog(@"ProviderMasterViewController:unwindToProviderMaster: ProviderDataViewController callback.");
        
        ProviderDataViewController* source = [segue sourceViewController];
        if (source.identity_changed || source.pub_keys_changed || source.file_store_changed) {
            if (source.our_data == nil) {
                NSLog(@"ProviderMasterViewController:unwindToProviderMaster: TODO(aka) ERROR: PersonalDataController is nil!");
                return;
            }
            
            _our_data = source.our_data;  // get the changes
            
            // Now save state, where needed.
            if (source.file_store_changed)
                [_our_data saveFileStoreState];
            
            if (source.identity_changed)
                [_our_data saveIdentityState];
        }
     
        if (!_track_self_status && source.track_self_status) {
            if (kDebugLevel > 2)
                NSLog(@"ProviderMasterViewController:unwindToProviderMaster: track self requested.");
            
            NSLog(@"ProviderMasterViewController:unwindToProviderMaster: Us: %@, %@.", _our_data.identity, _our_data.identity_hash);
            
            // First, add ourselves to our consumer list.
            Principal* tmp_consumer = [[Principal alloc] initWithIdentity:_our_data.identity];
            [tmp_consumer setDeposit:_our_data.deposit];
            tmp_consumer.precision = [NSNumber numberWithInt:SKC_PRECISION_HIGH];
            
            NSLog(@"ProviderMasterViewController:unwindToProviderMaster: tmp consumer: %@, %@, %@.", tmp_consumer.identity, tmp_consumer.identity_hash, tmp_consumer.precision);
            
            // Note, we don't need to set the public key now, we'll retrieve it from the key chain when we need it (since it's already in under our identity!).
            
            if (![_consumer_list_controller containsObject:tmp_consumer]) {
                // We don't have ourselves, yet, so add us (i.e., we didn't load it in via state).
                if (kDebugLevel > 0)
                    NSLog(@"ProviderMasterViewController:unwindToProviderMaster: Adding to our consumer list: %s.", [[tmp_consumer absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                
                [_consumer_list_controller addConsumer:tmp_consumer];
                [self.tableView reloadData];
            }
            
            // Tell the ConsumerMaster VC to add ourselves to their provider list at high precision!
            NSString* bucket_name = [[NSString alloc] initWithFormat:@"%s3", [_our_data.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            
            if (![[self delegate] isKindOfClass:[ConsumerMasterViewController class]])
                NSLog(@"ProviderMasterViewController:unwindToProviderMaster: ERROR: Delegate not found!");

            [[self delegate] addSelfToProviders:_our_data withBucket:bucket_name withKey:[_symmetric_keys_controller objectForKey:[NSNumber numberWithInt:SKC_PRECISION_HIGH]]];
        }
    } else if ([sourceViewController isKindOfClass:[ConsumerListDataViewController class]]) {
        if (kDebugLevel > 2)
            NSLog(@"ProviderMasterViewController:unwindToProviderMaster: ConsumerListDataViewController callback.");
        
        ConsumerListDataViewController* source = [segue sourceViewController];
        if (source.delete_principal) {
            // Delete the consumer.
            if (kDebugLevel > 0)
                NSLog(@"ProviderMasterViewController:unwindToProviderMaster: deleting consumer: %s, public-key: %s.", [source.consumer.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [[source.consumer.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            
            // Remove the consumer (and update our state files).
            NSString* error_msg = [_consumer_list_controller deleteConsumer:source.consumer saveState:YES];
            if (error_msg != nil) {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMasterViewController:unwindToProviderMaster:" message:error_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
            }
            
            [self.tableView reloadData];
        } else {
            if (source.precision_changed) {
                // Update the consumer in our master list.
                NSString* err_msg = [_consumer_list_controller addConsumer:source.consumer];
                if (err_msg != nil) {
                    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMasterViewController:unwindToProviderMaster:" message:err_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                    [alert show];
                }
                
                [self.tableView reloadData];
            }
            
            if (source.track_consumer) {
                if (kDebugLevel > 2)
                    NSLog(@"ProviderMasterViewController:unwindToProviderMaster: track consumer requested.");
                
                // Send our consumer over to the ConsumerMaster VC to be a Provider.
                Principal* new_provider = source.consumer;
                
                // Note, we don't need to set the public key now, we'll retrieve it from the key chain when we need it (since it's already in under the consumer's identity!).
                
                if (kDebugLevel > 0)
                    NSLog(@"ProviderMasterViewController:unwindToProviderMaster: new provider: %@, %@, %@.", new_provider.identity, new_provider.identity_hash, [PersonalDataController absoluteStringDeposit:new_provider.deposit]);
                
                if (![[self delegate] isKindOfClass:[ConsumerMasterViewController class]])
                    NSLog(@"ProviderMasterViewController:unwindToProviderMaster: ERROR: Delegate not found!");

               [[self delegate] addConsumerToProviders:new_provider];
            }
        }
    } else if ([sourceViewController isKindOfClass:[AddConsumerCTViewController class]]) {
        if (kDebugLevel > 2)
            NSLog(@"ProviderMasterViewController:unwindToProviderMaster: AddConsumerCTViewController callback.");
        
        AddConsumerCTViewController* source = [segue sourceViewController];
        if (source.our_data != nil) {
            // Add the new consumer to our ProviderListController.
            if (kDebugLevel > 0)
                NSLog(@"ProviderMasterViewController:unwindToProviderMaster: adding new consumer: %s, public-key: %s.", [source.consumer.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [[source.consumer.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            
            // Add our new consumer (and update our state files).
            NSString* error_msg = [_consumer_list_controller addConsumer:source.consumer];
            if (error_msg != nil) {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMasterViewController:unwindToProviderMaster:" message:error_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
            }
        }
    } else if ([sourceViewController isKindOfClass:[AddConsumerViewController class]]) {
        if (kDebugLevel > 2)
            NSLog(@"ProviderMasterViewController:unwindToProviderMaster: AddConsumerViewController callback.");
        
        // If we reached here, the user hit CANCEL in AddConsumerViewController.
    } else {
        NSLog(@"ProviderMasterViewController:unwindToProviderMaster: TODO(aka) Called from unknown ViewController!");
    }
    
    // No need to dismiss the view controller in an unwind segue.
    
    [self configureView];
}

#pragma mark - Cryptographic management

- (void) sendSymmetricKey:(NSNumber*)precision consumer:(Principal*)sole_consumer {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:sendSymmetricKey:consumer: called: %d.", [precision intValue]);
    
    // Get the symmetric key for this precision level.
    NSData* symmetric_key = [_symmetric_keys_controller objectForKey:precision];
    
    // Loop over each consumer and encrypt & send the key and file store *if* precision levels match ...
    
    for (int i = 0; i < [_consumer_list_controller countOfList]; i++) {
        Principal* consumer = [_consumer_list_controller objectInListAtIndex:i];
        
        if (sole_consumer != nil) {
            if (![consumer isEqual:sole_consumer]) {
                if (kDebugLevel > 0)
                    NSLog(@"ProviderMasterViewController:sendSymmetricKey: skipping %s due to sole consumer %s.", [consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [sole_consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                continue;
            }
        }
        
        if ([consumer.precision intValue] != [precision intValue]) {
            if (kDebugLevel > 0)
                NSLog(@"ProviderMasterViewController:sendSymmetricKey: skipping %s due to consumer's precision %d not matching routines: %d.", [consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [consumer.precision intValue], [precision intValue]);
            continue;  // skip this consumer
        }
        
        // For Debugging:
        NSDate* start = [NSDate date];
        
        // Encrypt a copy of the symmetric key with the Consumer's public key.
        NSData* encrypted_key = [PersonalDataController encryptSymmetricKey:symmetric_key publicKeyRef:[consumer publicKeyRef]];
        NSString* encrypted_key_b64 = [encrypted_key base64EncodedString];
        
        // For Debugging: Find elapsed time and convert to milliseconds, since NSDate start is earlier than now, we negate (-) our modifier in conversion.
        
        double end_ms = [start timeIntervalSinceNow] * -1000.0;
        NSString* msg = [[NSString alloc] initWithFormat:@"ProviderMasterViewController:sendSymmetricKey: PROFILING Signature: %fms, PROFILING SMS Sending time: %s.", end_ms, [[[NSDate date] description] cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        UILocalNotification* notice = [[UILocalNotification alloc] init];
        notice.alertBody = msg;
        notice.alertAction = @"Show";
        [[UIApplication sharedApplication] presentLocalNotificationNow:notice];
        
        // Get our file store.
        NSString* bucket_name = [[NSString alloc] initWithFormat:@"%s%d", [_our_data.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [consumer.precision intValue]];
        NSURL* file_store_url = [PersonalDataController absoluteURLFileStore:_our_data.file_store withBucket:[PersonalDataController hashMD5String:bucket_name]];
        
        if (kDebugLevel > 1)
            NSLog(@"ProviderMasterViewController:sendSymmetricKey: Using file store URL: %s.", [[file_store_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        
        // See what type of key deposit this consumer is using.
        if ([PersonalDataController isDepositTypeSMS:consumer.deposit]) {
            // Loop over the number of messages we need to send ...
#if 1
            int num_messages = 1;
#else
            int num_messages = 2;
#endif
            int cnt = 0;
            for (int j = 0; j < num_messages; ++j) {
                // Build our app's custom URI to send to our consumer.
                NSString* scheme = [[NSString alloc] initWithFormat:@"%s", kSchemeSLS];
                NSString* host = @"";  // app processing doesn't use host
                NSString* path = nil;
                
#if 1
                path = [[NSString alloc] initWithFormat:@"/?%s=%s&%s=%s&%s=%s", kQueryKeyEncryptedKey, [encrypted_key_b64 cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyFileStoreURL, [[file_store_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyIdentity, [_our_data.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
#else
                if (j == 0)
                    path = [[NSString alloc] initWithFormat:@"/?%s=%s&%s=%s", kQueryKeyEncryptedKey, [encrypted_key_b64 cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyIdentity, [_our_data.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
                else if (j == 1)
                    path = [[NSString alloc] initWithFormat:@"/?%s=%s&%s=%s",  kQueryKeyFileStoreURL, [[file_store_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyIdentity, [_our_data.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
#endif
                NSURL* sls_url = [[NSURL alloc] initWithScheme:scheme host:host path:path];
                
                NSString* phone_number = [PersonalDataController getDepositPhoneNumber:consumer.deposit];
                
                if (kDebugLevel > 0)
                    NSLog(@"ProviderMasterViewController:sendSymmetricKey: sending phone number:%s SMS message[%d]: %s.", [phone_number cStringUsingEncoding:[NSString defaultCStringEncoding]], j, [[sls_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                
                // Send our custom URI as the body of the SMS message (so the consumer can install it when reading the SMS message).
                
                MFMessageComposeViewController* msg_controller =
                [[MFMessageComposeViewController alloc] init];
                if([MFMessageComposeViewController canSendText]) {
                    msg_controller.body = [sls_url absoluteString];
                    msg_controller.recipients = [NSArray arrayWithObjects:phone_number, nil];
                    msg_controller.messageComposeDelegate = self;
                    [self presentViewController:msg_controller animated:YES completion:nil];
                } else {
                    NSLog(@"ProviderMasterViewController:sendSymmetricKey:precision: ERROR: TODO(aka) hmm, we can't send SMS messages!");
                    break;  // leave inner for loop
                }
                
                cnt++;
            }  // for (int j = 0; j < num_messages; ++j) {
        } else if ([PersonalDataController isDepositTypeEMail:consumer.deposit]) {
            // Build our app's custom URI to send to our consumer.
            NSString* scheme = [[NSString alloc] initWithFormat:@"%s", kSchemeSLS];
            NSString* host = @"";  // app processing doesn't use host
            NSString* path = [[NSString alloc] initWithFormat:@"/?%s=%s&%s=%s&%s=%s", kQueryKeyEncryptedKey, [encrypted_key_b64 cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyFileStoreURL, [[file_store_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyIdentity, [_our_data.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            NSURL* sls_url = [[NSURL alloc] initWithScheme:scheme host:host path:path];
            
            NSString* address = [PersonalDataController getDepositAddress:consumer.deposit];
            
            if (kDebugLevel > 0)
                NSLog(@"ProviderMasterViewController:sendSymmetricKey: sending address:%s e-mail message: %s.", [address cStringUsingEncoding:[NSString defaultCStringEncoding]], [[sls_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            
            // Send our custom URI as the body of the e-mail message (so the consumer can install it when reading the message).
            
            MFMailComposeViewController* msg_controller =
            [[MFMailComposeViewController alloc] init];
            if([MFMailComposeViewController canSendMail]) {
                [msg_controller setToRecipients:[NSArray arrayWithObjects:address, nil]];
                [msg_controller setSubject:@"SLS symmetric key and file store"];
                [msg_controller setMessageBody:[sls_url absoluteString] isHTML:NO];
                msg_controller.mailComposeDelegate = self;
                [self presentViewController:msg_controller animated:YES completion:nil];
            } else {
                NSLog(@"ProviderMasterViewController:sendSymmetricKey:precision: ERROR: TODO(aka) hmm, we can't send SMS messages!");
                break;  // leave inner for loop
            }
        } else {
            NSLog(@"ProviderMasterViewController:sendSymmetricKey:precision: WARN: TODO(aka) key deposit type: %s, not supported yet!", [[PersonalDataController getDepositType:consumer.deposit] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        }
    }
}

#pragma mark - Data management

- (NSString*) uploadLocationData:(CLLocation*)location {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:uploadLocationData: called.");
    
    // TODO(aka) Note, currently we simply serialize the CLLocation object using NSCoder, however, this will have to change when we support other location objects, e.g., Andriod's API, and more importantly, we want to *degrade* coordinates based on precision!
    
    double latitude = location.coordinate.latitude;
    double longitude = location.coordinate.longitude;
    double course = location.course;
    
    if (kDebugLevel > 1)
        NSLog(@"ProviderMasterViewController:uploadLocationData: description: %s, latitude %+.6f, longitude %+.6f, course: %+.6f\n", [location.description cStringUsingEncoding:[NSString defaultCStringEncoding]], latitude, longitude, course);
    
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:uploadLocationData: operating over %lu key(s).", (unsigned long)[_symmetric_keys_controller count]);
    
    // For Debugging:
    NSDate* start = [NSDate date];
    
    // Loop over each symmetric key and encrypt the location data for each precision ...
    NSEnumerator* enumerator = [_symmetric_keys_controller keyEnumerator];
    id key;
    while ((key = [enumerator nextObject])) {
        NSData* symmetric_key = [_symmetric_keys_controller objectForKey:key];
        if (symmetric_key == nil || ([symmetric_key length] <= 0)) {
            NSLog(@"ProviderMasterViewController:uploadLocationData: ERROR: TODO(aka) unable to find symmetric key for precision: %s.", [[key description] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            continue;
        }
        
        // Generate an ASCII representation of the coordinate and put it in a suitable buffer.
        
        NSLog(@"ProviderMasterViewController:uploadLocationData: TODO(aka) Need to figure out how to degrade coordinates (which are doubles!) by precision, as well as creating a generic format for them!");
#if 0
        NSString* location_str = [[NSString alloc] initWithFormat:@"%+.6f:%+.6f:%+.6f", latitude, longitude, course];
        NSData* serialized_location_data = [location_str dataUsingEncoding:[NSString defaultCStringEncoding]];
        
        if (kDebugLevel > 1)
            NSLog(@"ProviderMasterViewController:uploadLocationData: encrypting %s for precision %s.", [location_str cStringUsingEncoding:[NSString defaultCStringEncoding]], [[key description] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
#else
        // For simplicity, we are going to serialize the CLLocation object (as it conforms to NSCoding).
        NSData* serialized_location_data = [NSKeyedArchiver archivedDataWithRootObject:location];
#endif
        if (kDebugLevel > 0)
            NSLog(@"ProviderMasterViewController:uploadLocationData: after serialization, location data is %lub.", (unsigned long)[serialized_location_data length]);
        
        // Encrypt the location data with our symmetric key (for this precision), and base64 it.
        NSData* encrypted_location_data = [PersonalDataController encryptLocationData:serialized_location_data dataSize:[serialized_location_data length] symmetricKey:symmetric_key];
        NSString* encrypted_location_data_b64 = [encrypted_location_data base64EncodedString];
        
        // To build our *bucket* name for this precision, we hash a combination of our identity and precision.
        
        NSString* bucket_name = [[NSString alloc] initWithFormat:@"%s%d", [_our_data.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [key intValue]];
        
        if (kDebugLevel > 0)
            NSLog(@"ProviderMasterViewController:uploadLocationData: sending %s to our file store using key %s.", [encrypted_location_data_b64 cStringUsingEncoding:[NSString defaultCStringEncoding]], [[key description] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        
        // Export the encypted location data to our file store.
        NSString* err_msg = [_our_data uploadLocationData:encrypted_location_data_b64 bucketName:[PersonalDataController hashMD5String:bucket_name]];
        if (err_msg)
            return err_msg;
    }  // while ((key = [enumerator nextObject])) {
    
    // For Debugging: Find elapsed time and convert to milliseconds, since NSDate start is earlier than now, we negate (-) our modifier in conversion.
    
    double end_ms = [start timeIntervalSinceNow] * -1000.0;
    NSString* msg = [[NSString alloc] initWithFormat:@"ProviderMasterViewController:uploadLocationData: PROFILING upload and encryption: %fms.", end_ms];
    UILocalNotification* notice = [[UILocalNotification alloc] init];
    notice.alertBody = msg;
    notice.alertAction = @"Show";
    [[UIApplication sharedApplication] presentLocalNotificationNow:notice];
    
    //free(plain_text);
    return nil;
}

#pragma mark - Delegate callbacks

// UITableView
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:tableView:didSelectRowAtIndexPath: called.");
    
    NSUInteger section = [indexPath section];
    NSUInteger row = [indexPath row];
    
    if (kDebugLevel > 1)
        NSLog(@"ProviderMasterViewController:tableView:didSelectRowAtIndexPath: row %ld in section %ld selected.", (long)row, (long)section);
    
    // Show consumer details.
    [self performSegueWithIdentifier:@"ShowConsumerListDataViewID" sender:[_consumer_list_controller objectInListAtIndex:row]];
}

- (void) tableView:(UITableView*)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath {
    if (kDebugLevel > 2)
        NSLog(@"ProvderMasterViewController:tableView:accessoryButtonTappedForRowWithIndexPath: called.");

    // For now, we do the same this as if we touched the row (as opposed to the detail disclosure icon).
    NSUInteger section = [indexPath section];
    NSUInteger row = [indexPath row];
    
    if (kDebugLevel > 1)
        NSLog(@"ProviderMasterViewController:tableView:accessoryButtonTappedForRowWithIndexPath:: row %ld in section %ld selected.", (long)row, (long)section);
    
    // TODO(aka) Might want to return the cell to prepareForSegue:sender via [[self tableView] cellForRowAtIndexPath:indexPath]; Or     [[self tableView] indexPathForSelectedRow];
    
    [self performSegueWithIdentifier:@"ShowConsumerListDataViewID" sender:[_consumer_list_controller objectInListAtIndex:row]];
}

// CorelocationController delegate functions.
- (void) locationManager:(CLLocationManager*)manager didUpdateToLocation:(CLLocation*)new_location fromLocation:(CLLocation*)old_location {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:locationManager:didUpdateToLocation:fromLocation: called.");
    
    NSLog(@"TODO(aka) Check location date.");
    
    /*
     // If it's a relatively recent event, turn off updates to save power
     NSDate* eventDate = newLocation.timestamp;
     NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
     if (abs(howRecent) < 15.0)
     {
     NSLog(@"latitude %+.6f, longitude %+.6f\n",
     newLocation.coordinate.latitude,
     newLocation.coordinate.longitude);
     }
     // else skip the event and process the next one.
     */
    
    // Send the encrypted location data to our file store.
    NSString* err_msg = [self uploadLocationData:new_location];
    UILocalNotification* notice = [[UILocalNotification alloc] init];
    if (err_msg != nil) {
        err_msg = [err_msg stringByAppendingFormat:@"locationManger:didUpdateLocation:"];
        notice.alertBody = err_msg;
    } else {
        NSString* msg = [[NSString alloc] initWithFormat:@"locationManger:didUpdateLocation: Uploaded new location: %+.6f, %+.6f", new_location.coordinate.latitude, new_location.coordinate.longitude];
        notice.alertBody = msg;
    }
    notice.alertAction = @"Show";
    [[UIApplication sharedApplication] presentLocalNotificationNow:notice];
}

- (void) locationUpdate:(CLLocation*)location {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:locationUpdate: called.");
    
    if (kDebugLevel > 0)
        NSLog(@"ProviderMasterViewController:locationUpdate: Location description: %s.", [[location description] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
#if 0
    // XXX Problem is, this code won't work anymore!
    // For Debugging: TODO(aka) Test out encryption routines.
    
    // Generate an ASCII representation of the coordinate and put it in a suitable buffer.
    NSString* location_str = [[NSString alloc] initWithFormat:@"%+.6f:%+.6f", location.coordinate.latitude, location.coordinate.longitude];
    NSData* serialized_location_data = [location_str dataUsingEncoding:[NSString defaultCStringEncoding]];
    
    NSLog(@"ProviderMasterViewController:locationUpdate:location: TODO(aka) testing encryption of: %s.", [location_str cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    // Grab the low precision symmetric key.
    NSData* symmetric_key = nil;
    if ((symmetric_key = [_key_list_controller objectInListAtIndex:SKC_PRECISION_LOW]) == nil) {
        // Create a symmetric key for this precision level.
        symmetric_key = [self genSymmetricKey];
        
        // Install it in our symmetric key list controller.
        [_key_list_controller insertObject:symmetric_key atIndex:SKC_PRECISION_LOW];
        
        // Finally, send the new symmetric key to each Consumer who uses this precision level.
        //[self sendSymmetricKey:SKC_PRECISION_LOW];
    }
    
    // Encrypt the location data with our symmetric key (for this precision).
    NSData* encrypted_location_data = [self encryptLocationData:location_data dataSize:[location_data length] symmetricKey:symmetric_key];
    
    // Base64 the encrypted data.
    NSString* encrypted_location_data_b64 = [encrypted_location_data base64EncodedString];
    
    NSLog(@"ProviderMasterViewController:locationUpdate:location: TODO(aka) encrypted location data bundle b64: %s.", [encrypted_location_data_b64 cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    // Decrypt the location data bundle.
    NSData* encrypted_location_data_2 = [NSData dataFromBase64String:encrypted_location_data_b64];
    NSData* location_data_2 = [self decryptLocationData:encrypted_location_data_2 bundleSize:[encrypted_location_data_2 length] symmetricKey:symmetric_key];
    NSString* location_str_2 = [[NSString alloc] initWithData:location_data_2 encoding:[NSString defaultCStringEncoding]];
    
    NSLog(@"ProviderMasterViewController:locationUpdate:location: TODO(aka) decryption result: %s.", [location_str_2 cStringUsingEncoding:[NSString defaultCStringEncoding]]);
#endif
    
    // Send the encrypted location data to our file store.
    NSString* err_msg = [self uploadLocationData:location];
    UILocalNotification* notice = [[UILocalNotification alloc] init];
    if (err_msg != nil) {
        err_msg = [err_msg stringByAppendingFormat:@"locationUpdate:"];
        notice.alertBody = err_msg;
    } else {
        NSString* msg = [[NSString alloc] initWithFormat:@"locationUpdate: Uploaded new location: %+.6f, %+.6f", location.coordinate.latitude, location.coordinate.longitude];
        notice.alertBody = msg;
    }
    notice.alertAction = @"Show";
    [[UIApplication sharedApplication] presentLocalNotificationNow:notice];
}

- (void) locationError:(NSError*)error {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:locationError:error: called.");
	
    UILocalNotification* notice = [[UILocalNotification alloc] init];
    NSString* msg = [[NSString alloc] initWithFormat:@"locationError: %s", [[error description] cStringUsingEncoding:[NSString defaultCStringEncoding]]];
    notice.alertBody = msg;
    notice.alertAction = @"Show";
    [[UIApplication sharedApplication] presentLocalNotificationNow:notice];
}

// MFMessageComposeViewController delegate functions.
- (void) messageComposeViewController:(MFMessageComposeViewController*)controller didFinishWithResult:(MessageComposeResult)result {
	switch (result) {
		case MessageComposeResultCancelled:
            if (kDebugLevel > 0)
                NSLog(@"ProviderMasterViewController:messageComposeViewController:didFinishWithResult: Cancelled.");
			break;
            
		case MessageComposeResultFailed:
        {
			NSLog(@"ProviderMasterViewController:messageComposeViewController:didFinishWithResult: Failed!");
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"SMS Error" message:@"Unknown Error" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
        }
			break;
            
		case MessageComposeResultSent:
            if (kDebugLevel > 0)
                NSLog(@"ProviderMasterViewController:messageComposeViewController:didFinishWithResult: Sent.");
			break;
            
		default:
			NSLog(@"ProviderMasterViewController:messageComposeViewController:didFinishWithResult: ERROR: unknown result: %d.", result);
			break;
	}
    
	[self dismissViewControllerAnimated:YES completion:nil];
}

// MFMailComposeViewController delegate functions.
- (void) mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    if (error != nil) {
        NSLog(@"ProviderMasterViewController:mailComposeController:didFinishWithResult: ERROR: TODO(aka) received: %s.", [[error description] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
	switch (result) {
        case MFMailComposeResultCancelled:
            if (kDebugLevel > 0)
                NSLog(@"ProviderMasterViewController:mailComposeController:didFinishWithResult: Cancelled.");
			break;
            
        case MFMailComposeResultFailed:
        {
			NSLog(@"ProviderMasterViewController:mailComposeController:didFinishWithResult: Failed!");
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"SMS Error" message:@"Unknown Error" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
        }
			break;
            
        case MFMailComposeResultSent:
            if (kDebugLevel > 0)
                NSLog(@"ProviderMasterViewController:mailComposeController:didFinishWithResult: Sent.");
			break;
            
        case MFMailComposeResultSaved:
            NSLog(@"ProviderMasterViewController:mailComposeController:didFinishWithResult: Saved: TODO(aka) What do we do?.");
			break;
            
		default:
			NSLog(@"ProviderMasterViewController:mailComposeController:didFinishWithResult: ERROR: unknown result: %d.", result);
			break;
	}
    
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end

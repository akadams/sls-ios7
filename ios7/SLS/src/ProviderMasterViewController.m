//
//  ProviderMasterViewController.m
//  SLS
//
//  Created by Andrew K. Adams on 11/19/13.
//  Copyright (c) 2013 Andrew K. Adams. All rights reserved.
//

#import <sys/time.h>

#import "NSData+Base64.h"

#import "ProviderMasterViewController.h"
#import "ProviderDataViewController.h"
#import "ConsumerListDataViewController.h"
#import "AddConsumerViewController.h"
#import "AddConsumerCTViewController.h"
#import "KeyBundleController.h"
#import "LocationBundleController.h"
#import "Principal.h"

#import "sls-url-defines.h"
#import "security-defines.h"

#import "ConsumerMasterViewController.h"  // XXX Just to debug delegate stuff

static const int kDebugLevel = 1;

static const char* kKeyBundleExt = KEY_BUNDLE_EXTENSION;

static const char* kSchemeSLS = URI_SCHEME_SLS;
static const char* kQueryKeyID = URI_QUERY_KEY_ID;
static const char* kQueryKeyHistoryLogURL = URI_QUERY_KEY_HL_URL;
static const char* kQueryKeyKeyBundleURL = URI_QUERY_KEY_KB_URL;
static const char* kQueryKeyTimeStamp = URI_QUERY_KEY_TIME_STAMP;
static const char* kQueryKeySignature = URI_QUERY_KEY_SIGNATURE;
static const char* kPathHistoryLogFilename = URI_HISTORY_LOG_FILENAME;  // filename for history log in file-store

static const int kHistoryLogSize = 8;  // TODO(aka) need to add to a define file
static const char* kHistoryLogFilename = "history-log";  // filename for history log state on local disk (not file-store!)


@interface ProviderMasterViewController ()

@end

@implementation ProviderMasterViewController

#pragma mark - Local variables
@synthesize our_data = _our_data;
@synthesize consumer_list_controller = _consumer_list_controller;
@synthesize symmetric_keys_controller = _symmetric_keys_controller;
@synthesize location_controller = _location_controller;
@synthesize history_logs = _history_logs;
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
        _symmetric_keys_controller = nil;
        _location_controller = nil;
        _history_logs = nil;
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
        _symmetric_keys_controller = nil;
        _location_controller = nil;
        _history_logs = nil;
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
        _symmetric_keys_controller = nil;
        _location_controller = nil;
        _history_logs = nil;
        _delegate = nil;
        location_gathering_on_startup = false;
    }

    return self;
}

- (void) loadState {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:loadState: called.");
    
    if (_our_data == nil) {
        if (kDebugLevel > 2)
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
    
    // Load in any previously saved state for location services, and start up (if previously on).
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
    NSLog(@"ProviderMasterViewController:loadState: TODO(aka) Why am I using a temp controller here?  _symmetric_keys_controller is <strong>, so I don't think I need to worry about the setter ...");
    
    SymmetricKeysController* tmp_keys_controller = [[SymmetricKeysController alloc] init];
    NSString* err_msg = [tmp_keys_controller loadState];
    if (err_msg != nil)
        NSLog(@"ProviderMasterViewController:loadState: %@.", err_msg);
    
    if (kDebugLevel > 0)
        NSLog(@"ProviderMasterViewController:loadState: loaded %lu symmetric keys into the tmp controller.", (unsigned long)[tmp_keys_controller count]);
    
    _symmetric_keys_controller = tmp_keys_controller;
    
    // Load in any previous locations (history logs) for any policy levels we have.
    _history_logs = [[PersonalDataController loadStateDictionary:[[NSString alloc] initWithCString:kHistoryLogFilename encoding:[NSString defaultCStringEncoding]]] mutableCopy];
    
    if (kDebugLevel > 0)
        NSLog(@"ProviderMasterViewController:loadState: loaded %lu different policy levels into our history logs.", (unsigned long)[_history_logs count]);
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

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:tableView:cellForRowAtIndexPath: called.");
    
    Principal* consumer = [_consumer_list_controller objectInListAtIndex:indexPath.row];
    
    NSLog(@"ProviderMasterViewController:tableView:cellForRowAtIndexPath: working on cell with consumer: %s, policy: %@, with index path: %ld.", [consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], consumer.policy, (long)indexPath.row);
    
#if 0  // TODO(aka) Method using a custom cell we create ...
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
    
    xxx;  // policy handled wrong
    
    cell.slider.value = (float)[consumer.policy floatValue];
    NSLog(@"ProviderMasterViewController:tableView:cellForRowAtIndexPath: setting slider tag to: %ld.", (long)indexPath.row);
    cell.slider.tag = indexPath.row;
    
    // For now, give button a label representing our tag number.
    NSString* button_title = [[NSString alloc] initWithFormat:@"%ld", (long)indexPath.row];
    [cell.button setTitle:button_title forState:UIControlStateNormal];
    cell.button.tag = indexPath.row;
    return cell;
#else
    // Method using standard cells.
    static NSString* pmvc_identifier = @"PMVCCellReuseID";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:pmvc_identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault  reuseIdentifier:pmvc_identifier];
    }
    
    // Set its identity and trust level.
    cell.textLabel.text = consumer.identity;
    [cell.detailTextLabel setText:consumer.policy];
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
            
            // First, add ourselves to our consumer list.
            Principal* tmp_consumer = [[Principal alloc] initWithIdentity:_our_data.identity];
            [tmp_consumer setDeposit:_our_data.deposit];
            tmp_consumer.policy = [PolicyController precisionLevelName:[[NSNumber alloc] initWithInt:PC_PRECISION_IDX_EXACT]];

            if (kDebugLevel > 2)
                NSLog(@"ProviderMasterViewController:unwindToProviderMaster: tmp consumer: %@, %@, %@.", tmp_consumer.identity, tmp_consumer.identity_hash, tmp_consumer.policy);
            
            // Note, we don't need to set the public key now, we'll retrieve it from the key chain when we need it (since it's already in under our identity!).
            
            if (![_consumer_list_controller containsObject:tmp_consumer]) {
                // We don't have ourselves, yet, so add us (i.e., we didn't load it in via state).
                if (kDebugLevel > 0)
                    NSLog(@"ProviderMasterViewController:unwindToProviderMaster: Adding to our consumer list: %s.", [[tmp_consumer absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                
                [_consumer_list_controller addConsumer:tmp_consumer];
                [self.tableView reloadData];
            }
            
            // Tell the ConsumerMaster VC to add ourselves to their provider list at highest policy!
            
            // Note, the *bucket* name is a MD5 hash of a concatenation of our identity and this policy (or precision).
            NSString* bucket_name = [PersonalDataController hashMD5String:[[NSString alloc] initWithFormat:@"%s%s", [_our_data.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], PC_PRECISION_EXACT]];
            
            if (![[self delegate] isKindOfClass:[ConsumerMasterViewController class]])
                NSLog(@"ProviderMasterViewController:unwindToProviderMaster: ERROR: Delegate not found!");
            
            // TODO(aka) We may want to send over the key-bundle & history-log URLs instead of just the bucket ...
            [[self delegate] addSelfToProviders:_our_data withBucket:bucket_name withKey:[_symmetric_keys_controller objectForKey:tmp_consumer.policy]];
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
            NSString* err_msg = [_consumer_list_controller deleteConsumer:source.consumer saveState:YES];
            if (err_msg != nil) {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMasterViewController:unwindToProviderMaster:" message:err_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
            }
            
            [self.tableView reloadData];
        } else {
            if (source.policy_changed) {
                if (kDebugLevel > 0)
                    NSLog(@"ProviderMasterViewController:unwindToProviderMaster: New policy: %@, re-keying for old policy: %@.", source.desired_policy, source.consumer.policy);
                
                // If the old policy is not PC_PRECISION_IDX_NONE, delete the symmetric key associated with that policy (it's now considered public), re-key for that policy, and then update everyone else's shared key bundle that is assigned to that policy.
                
                NSString* policy = source.consumer.policy;
                if (policy != nil && ![policy isEqualToString:[PolicyController precisionLevelName:[NSNumber numberWithInt:PC_PRECISION_IDX_NONE]]]) {
                    [_symmetric_keys_controller deleteSymmetricKey:policy];
                    NSString* err_msg = [_symmetric_keys_controller generateSymmetricKey:policy];
                    if (err_msg != nil) {
                        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMasterViewController:unwindToProviderMaster:" message:err_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                        [alert show];
                    }
                    [self uploadKeyBundle:policy consumer:nil];
                }
                
                // Now upload our consumer's new shared key bundle, and send them the updated cloud meta-data.
                [self uploadKeyBundle:source.desired_policy consumer:source.consumer];
                [self sendCloudMetaData:source.desired_policy consumer:source.consumer];
                source.consumer.file_store_sent = true;
                
                // And finally, update this consumer in the master list with the new policy level.
                [source.consumer setPolicy:source.desired_policy];
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
                
                // Send our consumer over to the ConsumerMaster VC, so they'll be treated as a provider too!
                Principal* new_provider = source.consumer;
                
                // Note, we don't need to set the public key now, we'll retrieve it from the key chain when we need it (since it's already in under the consumer's identity!).  However, we won't have a symmetric key or even a file-store for this consumer until they send us one, so this just adds a Principal on the Consumer MVC for us.
                
                if (kDebugLevel > 0)
                    NSLog(@"ProviderMasterViewController:unwindToProviderMaster: new provider: %@, %@, %@.", new_provider.identity, new_provider.identity_hash, [PersonalDataController absoluteStringDeposit:new_provider.deposit]);
                
                if (![[self delegate] isKindOfClass:[ConsumerMasterViewController class]])
                    NSLog(@"ProviderMasterViewController:unwindToProviderMaster: ERROR: Delegate not found!");

               [[self delegate] addConsumerToProviders:new_provider];
            }
            
            if (source.send_file_store_info) {
                if (kDebugLevel > 0)
                    NSLog(@"ProviderMasterViewController:unwindToProviderMaster: sending file-store meta-data to %s.", [source.consumer.identity cStringUsingEncoding: [NSString defaultCStringEncoding]]);
                
                [self sendCloudMetaData:source.consumer.policy consumer:source.consumer];
            }
        }
    } else if ([sourceViewController isKindOfClass:[AddConsumerCTViewController class]]) {
        if (kDebugLevel > 2)
            NSLog(@"ProviderMasterViewController:unwindToProviderMaster: AddConsumerCTViewController callback.");
        
        AddConsumerCTViewController* source = [segue sourceViewController];
        if (source.consumer != nil) {
            // Add the new consumer to our ConsumerListController.
            if (kDebugLevel > 0)
                NSLog(@"ProviderMasterViewController:unwindToProviderMaster: adding new consumer: %s, public-key: %s.", [source.consumer.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [[source.consumer.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            
            // Add our new consumer (and update our state files).
            NSString* err_msg = [_consumer_list_controller addConsumer:source.consumer];
            if (err_msg != nil) {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMasterViewController:unwindToProviderMaster:" message:err_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
            } else {
                // Remind the Provider to set the new consumer's policy & send the file-store meta-data out!
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"New Consumer Added" message:@"Remember to set policy for the new consumer!" delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
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

#pragma mark - Cloud management

- (void) sendCloudMetaData:(NSString*)policy consumer:(Principal*)sole_consumer {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:sendCloudMetaData:consumer: called: %@, %@.", policy, sole_consumer);
    
    // Loop over each consumer and encrypt & send our file store meta-data *if* policy levels match ...
    for (int i = 0; i < [_consumer_list_controller countOfList]; i++) {
        Principal* consumer = [_consumer_list_controller objectInListAtIndex:i];
        
        // Note, if we specified a consumer as a parameter, only send to them!
        if (sole_consumer != nil) {
            if (![consumer isEqual:sole_consumer]) {
                if (kDebugLevel > 1)
                    NSLog(@"ProviderMasterViewController:sendCloudMetaData: skipping %s due to sole consumer %s.", [consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [sole_consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                continue;
            }
        }
        
        if (![policy isEqualToString:consumer.policy]) {
            if (kDebugLevel > 1)
                NSLog(@"ProviderMasterViewController:sendCloudMetaData: skipping %s due to consumer's policy %@ not matching routines: %@.", [consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], consumer.policy, policy);
            continue;  // skip this consumer
        }
        
#if 0
        // For Profiling:
        NSDate* start = [NSDate date];
#endif
        
        // Build the File-store meta data *path*, which includes; (i) our identity token, (ii) the URI of the history log in our File-store for this policy, (iii) the URI for this consumer's key-bundle (currently, only difference between this and the history-log URI is the path component of the URI, i.e., the final filename), (iv) a time stamp, and (v) a signature across the preceeding four fields concatenated together.
        
        // Note, the *bucket* name is a MD5 hash of a concatenation of our identity and this policy (or precision).
        NSString* bucket_name = [PersonalDataController hashMD5String:[[NSString alloc] initWithFormat:@"%s%s", [_our_data.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [policy cStringUsingEncoding:[NSString defaultCStringEncoding]]]];
        NSString* history_log_filename = [[NSString alloc] initWithFormat:@"%s", kPathHistoryLogFilename];
        NSString* key_bundle_filename = [[NSString alloc] initWithFormat:@"%s%s", [consumer.identity_hash cStringUsingEncoding:[NSString defaultCStringEncoding]], URI_KEY_BUNDLE_EXT];
        NSURL* history_log_url = [PersonalDataController absoluteURLFileStore:_our_data.file_store withBucket:bucket_name withFile:history_log_filename];
        NSURL* key_bundle_url = [PersonalDataController absoluteURLFileStore:_our_data.file_store withBucket:bucket_name withFile:key_bundle_filename];
        struct timeval now;
        gettimeofday(&now, NULL);
        
        // Generate signature of four tuple.
        NSString* four_tuple = [[NSString alloc] initWithFormat:@"%s%s%s%ld", [_our_data.identity_hash cStringUsingEncoding:[NSString defaultCStringEncoding]], [[history_log_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[key_bundle_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], now.tv_sec];
        
        if (kDebugLevel > 2)
            NSLog(@"PersonalDataController:sendCloudMetaData: four tuple: %@.", four_tuple);
        
        NSString* signature = nil;
        NSString* err_msg = [PersonalDataController signHashString:four_tuple privateKeyRef:_our_data.privateKeyRef signedHash:&signature];
        if (err_msg != nil) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMasterViewController:sendCloudMetaData:" message:err_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
            [alert show];
            continue;  // nothing we can do for this consumer
        }
        
        if (kDebugLevel > 0)
            NSLog(@"PersonalDataController:sendCloudMetaData: four tuple: %@, signature: %@.", four_tuple, signature);
        
#if 0
        // For Profiling: Find elapsed time and convert to milliseconds, since NSDate start is earlier than now, we negate (-) our modifier in conversion.
        
        double end_ms = [start timeIntervalSinceNow] * -1000.0;
        NSString* msg = [[NSString alloc] initWithFormat:@"ProviderMasterViewController:sendCloudMetaData: PROFILING Signature: %fms, PROFILING SMS Sending time: %s.", end_ms, [[[NSDate date] description] cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        UILocalNotification* notice = [[UILocalNotification alloc] init];
        notice.alertBody = msg;
        notice.alertAction = @"Show";
        [[UIApplication sharedApplication] presentLocalNotificationNow:notice];
#endif
        
        // See what type of deposit this consumer is using.
        if ([PersonalDataController isDepositTypeSMS:consumer.deposit]) {
            // Loop over the number of messages we need to send ...
            
            // TODO(aka) I'm not sure if there's a size limit for URL processing, on the other hand, it may prove to difficult to keep state on the consumer to deal with multiple messages!
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
                path = [[NSString alloc] initWithFormat:@"/?%s=%s&%s=%s&%s=%s&%s=%ld&%s=%s", kQueryKeyID, [_our_data.identity_hash cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyHistoryLogURL, [[history_log_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyKeyBundleURL, [[key_bundle_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyTimeStamp, now.tv_sec, kQueryKeySignature, [signature cStringUsingEncoding:[NSString defaultCStringEncoding]]];
#else
                if (j == 0)
                    path = [[NSString alloc] initWithFormat:@"/?%s=%s&%s=%s", kQueryKeyEncryptedKey, [encrypted_key_b64 cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyIdentity, [_our_data.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
                else if (j == 1)
                    path = [[NSString alloc] initWithFormat:@"/?%s=%s&%s=%s",  kQueryKeyFileStoreURL, [[file_store_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyIdentity, [_our_data.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
#endif
                NSURL* sls_url = [[NSURL alloc] initWithScheme:scheme host:host path:path];
                
                NSString* phone_number = [PersonalDataController getDepositPhoneNumber:consumer.deposit];
                
                if (kDebugLevel > 0)
                    NSLog(@"ProviderMasterViewController:sendCloudMetaData: sending phone number:%s SMS message[%d]: %s.", [phone_number cStringUsingEncoding:[NSString defaultCStringEncoding]], j, [[sls_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                
                // Send our custom URI as the body of the SMS message (so the consumer can install it when reading the SMS message).
                
                MFMessageComposeViewController* msg_controller =
                [[MFMessageComposeViewController alloc] init];
                if([MFMessageComposeViewController canSendText]) {
                    msg_controller.body = [sls_url absoluteString];
                    msg_controller.recipients = [NSArray arrayWithObjects:phone_number, nil];
                    msg_controller.messageComposeDelegate = self;
                    [self presentViewController:msg_controller animated:YES completion:nil];
                } else {
                    NSLog(@"ProviderMasterViewController:sendCloudMetaData:policy: ERROR: TODO(aka) hmm, we can't send SMS messages!");
                    break;  // leave inner for loop
                }
                
                cnt++;
            }  // for (int j = 0; j < num_messages; ++j) {
        } else if ([PersonalDataController isDepositTypeEMail:consumer.deposit]) {
            // Build our app's custom URI to send to our consumer.
            NSString* scheme = [[NSString alloc] initWithFormat:@"%s", kSchemeSLS];
            NSString* host = @"";  // app processing doesn't use host
            NSString* path = [[NSString alloc] initWithFormat:@"/?%s=%s&%s=%s&%s=%s&%s=%ld&%s=%s", kQueryKeyID, [_our_data.identity_hash cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyHistoryLogURL, [[history_log_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyKeyBundleURL, [[key_bundle_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyTimeStamp, now.tv_sec, kQueryKeySignature, [signature cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            NSURL* sls_url = [[NSURL alloc] initWithScheme:scheme host:host path:path];
            
            NSString* address = [PersonalDataController getDepositAddress:consumer.deposit];
            
            if (kDebugLevel > 0)
                NSLog(@"ProviderMasterViewController:sendCloudMetaData: sending address:%s e-mail message: %s.", [address cStringUsingEncoding:[NSString defaultCStringEncoding]], [[sls_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            
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
                NSLog(@"ProviderMasterViewController:sendCloudMetaData: ERROR: TODO(aka) hmm, we can't send SMS messages!");
                break;  // leave inner for loop
            }
        } else {
            NSLog(@"ProviderMasterViewController:sendCloudMetaData: WARN: TODO(aka) deposit type: %s, not supported yet!", [[PersonalDataController getDepositType:consumer.deposit] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        }
    }
}
                                                                         
#pragma mark - Cloud operations

- (void) uploadKeyBundle:(NSString*)policy consumer:(Principal*)sole_consumer {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:uploadKeyBundle:consumer: called: %@.", policy);
    
    NSString* err_msg = nil;
    
    // Get the symmetric key for this policy level.
    NSData* symmetric_key = [_symmetric_keys_controller objectForKey:policy];
    if (symmetric_key == nil) {
        err_msg = [[NSString alloc] initWithFormat:@"No symmetric key for policy: %s.", [policy cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMasterViewController:uploadKeyBundle:" message:err_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
        [alert show];
        return;  // nothing we can do for this consumer
    }
    
    // Loop over each consumer and generate & upload their key-bundle, *if* policy levels match ...
    for (int i = 0; i < [_consumer_list_controller countOfList]; i++) {
        Principal* consumer = [_consumer_list_controller objectInListAtIndex:i];
        
        if (sole_consumer != nil) {
            if (![consumer isEqual:sole_consumer]) {
                if (kDebugLevel > 0)
                    NSLog(@"ProviderMasterViewController:uploadKeyBundle: skipping %s due to sole consumer %s.", [consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [sole_consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                continue;
            }
        }
        
        if (![policy isEqualToString:consumer.policy]) {
            if (kDebugLevel > 1)
                NSLog(@"ProviderMasterViewController:uploadKeyBundle: skipping %s due to consumer's policy %@ not matching routines: %@.", [consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], consumer.policy, policy);
            continue;  // skip this consumer
        }
        
#if 0
        // For Profiling:
        NSDate* start = [NSDate date];
#endif
        
        // Encrypt a copy of the symmetric key with the Consumer's public key and base64 it.
        NSData* encrypted_key = nil;
        err_msg = [PersonalDataController asymmetricEncryptData:symmetric_key publicKeyRef:[consumer publicKeyRef] encryptedData:&encrypted_key];
        if (err_msg != nil) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMasterViewController:uploadKeyBundle:" message:err_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
            [alert show];
            continue;  // nothing we can do for this consumer
        }
        NSString* encrypted_key_b64 = [encrypted_key base64EncodedString];
        
        // Build our key-bundle for this Consumer.
        KeyBundleController* key_bundle = [[KeyBundleController alloc] init];
        err_msg = [key_bundle build:encrypted_key_b64 privateKeyRef:[_our_data privateKeyRef]];
        if (err_msg != nil) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMasterViewController:uploadKeyBundle:" message:err_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
            [alert show];
            continue;  // nothing we can do for this consumer
        }
        
        // Upload the key-bundle to our file-store.
        
        // Note, the *bucket* name is a MD5 hash of a concatenation of our identity and this policy (or precision).
        NSString* bucket_name = [PersonalDataController hashMD5String:[[NSString alloc] initWithFormat:@"%s%s", [_our_data.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [policy cStringUsingEncoding:[NSString defaultCStringEncoding]]]];
        NSString* filename = [[NSString alloc] initWithFormat:@"%s%s", [consumer.identity_hash cStringUsingEncoding:[NSString defaultCStringEncoding]], kKeyBundleExt];
        
        if (kDebugLevel > 0)
            NSLog(@"ProviderMasterViewController:uploadKeyBundle: uploading key-bundle to %s/%s for %s.", [bucket_name cStringUsingEncoding:[NSString defaultCStringEncoding]], [filename cStringUsingEncoding:[NSString defaultCStringEncoding]], [consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        
        err_msg = [_our_data uploadData:[key_bundle serialize] bucketName:bucket_name filename:filename];
        if (err_msg != nil) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMasterViewController:uploadKeyBundle:" message:err_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
            [alert show];
            continue;  // nothing we can do for this consumer
        }
        
#if 0
        // For Profiling: Find elapsed time and convert to milliseconds, since NSDate start is earlier than now, we negate (-) our modifier in conversion.
        
        double end_ms = [start timeIntervalSinceNow] * -1000.0;
        NSString* msg = [[NSString alloc] initWithFormat:@"ProviderMasterViewController:uploadKeyBundle: PROFILING Signature: %fms, PROFILING SMS Sending time: %s.", end_ms, [[[NSDate date] description] cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        UILocalNotification* notice = [[UILocalNotification alloc] init];
        notice.alertBody = msg;
        notice.alertAction = @"Show";
        [[UIApplication sharedApplication] presentLocalNotificationNow:notice];
#endif
    }  // for (int i = 0; i < [_consumer_list_controller countOfList]; i++) {
}

- (NSString*) uploadHistoryLog:(NSArray*)history_log policy:(NSString*)policy {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:uploadHistoryLog: called.");
    
    // Note, we can return an error message here, as this routine is called by CLLocation's delegate functions.
    
    if (kDebugLevel > 0)
        NSLog(@"ProviderMasterViewController:uploadHistoryLog: operating over key %@.", policy);
    
    // For this policy (i.e., precision), we want to serialize the history log, encrypt if with the associated symmetric key, base64 it, and then upload it to the appropriate directory.  Note, each individual LocationBundle within each history log should already have a timestamp and signature.
    
    // Encrypt a serialized version of the history log and base64 it.
    NSString* err_msg = nil;
    
    NSData* serialized_history_log = nil;
#if 0
    // XXX TODO(aka) We need to develop an O/S agnostic framing/encoding scheme for the location, course data!
    NSString* serialized_history_log_str = [[NSString alloc] init];
    for (id object in history_log) {
        LocationBundleController* lbc = (LocationBundleController*)object;
        // NSString* serialized_location = [[NSString alloc] initWithFormat:@"%+.6f:%+.6f:%+.6f", latitude, longitude, course];
        [serialized_history_log_str stringByAppendString:[lbc serialize]];
    }
    if (kDebugLevel > 1)
        NSLog(@"ProviderMasterViewController:uploadHistoryLog: encrypting %s using key at policy %@.", [serialized_history_log_str cStringUsingEncoding:[NSString defaultCStringEncoding]], policy);
    
    serialized_history_log = [serialized_history_log_str dataUsingEncoding:[NSString defaultCStringEncoding]];
#else
    NSLog(@"ProviderMasterViewController:uploadHistoryLog: TODO(aka) We need to develop an O/S agnosticframing/encoding scheme for the location and course data!");
    
    // For simplicity, we are going to serialize the NSArray of LocationBundleControllers object (as they conform to NSCoding).
    serialized_history_log = [NSKeyedArchiver archivedDataWithRootObject:history_log];
    // XXX NSData* serialized_data = [NSKeyedArchiver archivedDataWithRootObject:history_log];
#endif

    if (kDebugLevel > 0)
        NSLog(@"ProviderMasterViewController:uploadHistoryLog: after serialization, history log is %lub.", (unsigned long)[serialized_history_log length]);
    
    NSData* encrypted_data = nil;
    err_msg = [PersonalDataController symmetricEncryptData:serialized_history_log symmetricKey:[_symmetric_keys_controller objectForKey:policy] encryptedData:&encrypted_data];
    if (err_msg != nil)
        return err_msg;
    NSString* encrypted_data_b64 = [encrypted_data base64EncodedString];
    
#if 0
    // For Profiling:
    NSDate* start = [NSDate date];
#endif
    
    // Note, the *bucket* name is a MD5 hash of a concatenation of our identity and this policy (or precision).
    NSString* bucket_name = [PersonalDataController hashMD5String:[[NSString alloc] initWithFormat:@"%s%s", [_our_data.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [policy cStringUsingEncoding:[NSString defaultCStringEncoding]]]];
    NSString* history_log_filename = [[NSString alloc] initWithFormat:@"%s", kPathHistoryLogFilename];
    
    if (kDebugLevel > 0)
        NSLog(@"ProviderMasterViewController:uploadHistoryLog: uploading %s to our file store (%@/%@) using key %s.", [encrypted_data_b64 cStringUsingEncoding:[NSString defaultCStringEncoding]], bucket_name, history_log_filename, [policy cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    // Export the encypted location data to our file store.
    err_msg = [_our_data uploadData:encrypted_data_b64 bucketName:bucket_name filename:history_log_filename];
    if (err_msg)
        return err_msg;

#if 0
    // For Debugging: Find elapsed time and convert to milliseconds, since NSDate start is earlier than now, we negate (-) our modifier in conversion.

    double end_ms = [start timeIntervalSinceNow] * -1000.0;
    NSString* msg = [[NSString alloc] initWithFormat:@"ProviderMasterViewController:uploadHistoryLog: PROFILING upload and encryption: %fms.", end_ms];
    UILocalNotification* notice = [[UILocalNotification alloc] init];
    notice.alertBody = msg;
    notice.alertAction = @"Show";
    [[UIApplication sharedApplication] presentLocalNotificationNow:notice];
#endif
    
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
    
    NSLog(@"ProviderMasterViewController:locationManager:didUpdateToLocation:fromLocation: TODO(aka) Check location date to make sure it's not stale.");
    
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
    
    // TODO(aka) We may want to ignore this fetch (or replace our last) if the distance between this and our last coordinate is within some distance filter.  (Note, however, that the consumer knows nothing of the provider's current distance filter ... so, we're just going to look at the timestamp.
    
    if (kDebugLevel > 0)
        NSLog(@"ProviderMasterViewController:locationManager:didUpdateToLocation: Location description: %s.", [[new_location description] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    // Modify the location data for each policy (precision), then append it (as a LocationBundle) to that policy's history log.
    
    // Note, we can loop either on polcies or symmetric_keys (in our _symmetric_keys_controller), as once is simply the index into the other!
    
#if 0
    // NSEnumerator example.
    NSEnumerator* enumerator = [_symmetric_keys_controller keyEnumerator];
    id key;
    while ((key = [enumerator nextObject])) {
        NSString* policy = (NSString*)key;
    }
#endif

    NSArray* policies = _symmetric_keys_controller.policies;
    for (id object in policies) {
        NSString* policy = (NSString*)object;
        
        // Since Amazon S3 (at least) does not have an API for *appending* to a file, we actually upload the entire history log, as opposed to just this new location update.  As it turn out, this isn't a big problem, because we keep an NSMutableArray of our location bundles, i.e., the history log!
        
        // Get the NSMutableArray for this policy, if one exists.
        NSMutableArray* history_log = [_history_logs objectForKey:policy];
        if (history_log == nil)
            history_log = [[NSMutableArray alloc] initWithCapacity:kHistoryLogSize];
        
        // Generate the new location bundle for this policy.
        LocationBundleController* location_bundle = [[LocationBundleController alloc] init];
        [location_bundle build:new_location privateKeyRef:[_our_data privateKeyRef]];
        
        NSLog(@"ProviderMasterViewController:locationManager:didUpdateToLocation: TODO(aka) Need to figure out how to degrade coordinates (which are doubles!) by precision!");
        
        // TODO(aka) It's arguable that we should encrypt the LocationBundle now, but (i) that would require us to pass in the symmetric key, and (ii) we wouldnl't be able to read it locally again, easily!  (Not sure how important either of these really is, though on the Provider.)
        
        // Push the new location bundle to this history log queue.
        [history_log insertObject:location_bundle atIndex:0];
        
        // If this gave us more than our allotted queue size, delete the last object.
        if ([history_log count] > kHistoryLogSize)
            [history_log removeLastObject];
        
        // Add the updated history log back to our dictionary.
        [_history_logs setObject:history_log forKey:policy];
        
        if (kDebugLevel > 0)
            NSLog(@"ProviderMasterViewController:locationManager:didUpdateToLocation: %@ history log at %lu objects.", policy, (unsigned long)[history_log count]);
        
        // Serialzie, encrypt, base64 then upload the history log for this policy.
        NSString* err_msg = [self uploadHistoryLog:history_log policy:policy];
        
        if (err_msg != nil || [policy isEqualToString:[PolicyController precisionLevelName:[[NSNumber alloc] initWithInt:0]]]) {
            UILocalNotification* notice = [[UILocalNotification alloc] init];
            if (err_msg != nil) {
                err_msg = [err_msg stringByAppendingFormat:@"locationManger:didUpdateLocation:"];
                notice.alertBody = err_msg;
            } else {
                NSString* msg = [[NSString alloc] initWithFormat:@"locationManger:didUpdateLocation: Uploaded: %+.6f, %+.6f, %f", new_location.coordinate.latitude, new_location.coordinate.longitude, new_location.course];
                notice.alertBody = msg;
            }
            notice.alertAction = @"Show";
            [[UIApplication sharedApplication] presentLocalNotificationNow:notice];
        }
    }  // for (id object in policies) {
    
    // Finally, save our current state (of all our history logs).
    [PersonalDataController saveState:[[NSString alloc] initWithCString:kHistoryLogFilename encoding:[NSString defaultCStringEncoding]] dictionary:_history_logs];
}

- (void) locationUpdate:(CLLocation*)location {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:locationUpdate: called.");
    
    // Note, this routine is the same as locationManager:didUpdateToLocation:fromLocation: above.
    
    NSLog(@"ProviderMasterViewController:locationUpdate: TODO(aka) Check location date to make sure it's not stale.");
    
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
    
    // TODO(aka) We may want to ignore this fetch (or replace our last) if the distance between this and our last coordinate is within some distance filter.  (Note, however, that the consumer knows nothing of the provider's current distance filter ... so, we're just going to look at the timestamp.

    if (kDebugLevel > 0)
        NSLog(@"ProviderMasterViewControllerlocationUpdate: Location description: %s.", [[location description] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    // Modify the location data for each policy (precision), then append it (as a LocationBundle) to that policy's history log.
    
    // Note, we can loop either on polcies or symmetric_keys (in our _symmetric_keys_controller), as once is simply the index into the other!
    
#if 0
    // NSEnumerator example.
    NSEnumerator* enumerator = [_symmetric_keys_controller keyEnumerator];
    id key;
    while ((key = [enumerator nextObject])) {
        NSString* policy = (NSString*)key;
    }
#endif
    
    NSArray* policies = _symmetric_keys_controller.policies;
    for (id object in policies) {
        NSString* policy = (NSString*)object;
        
        // Since Amazon S3 (at least) does not have an API for *appending* to a file, we actually upload the entire history log, as opposed to just this new location update.  As it turn out, this isn't a big problem, because we keep an NSMutableArray of our location bundles, i.e., the history log!
        
        // Get the NSMutableArray for this policy, if one exists.
        NSMutableArray* history_log = [_history_logs objectForKey:policy];
        if (history_log == nil)
            history_log = [[NSMutableArray alloc] initWithCapacity:kHistoryLogSize];
        
        // Generate the new location bundle for this policy.
        LocationBundleController* location_bundle = [[LocationBundleController alloc] init];
        [location_bundle build:location privateKeyRef:[_our_data privateKeyRef]];
        
        NSLog(@"ProviderMasterViewController:locationUpdate: TODO(aka) Need to figure out how to degrade coordinates (which are doubles!) by precision!");
        
        // TODO(aka) It's arguable that we should encrypt the LocationBundle now, but (i) that would require us to pass in the symmetric key, and (ii) we wouldnl't be able to read it locally again, easily!  (Not sure how important either of these really is, though on the Provider.)
        
        // Push the new location bundle to this history log queue.
        [history_log insertObject:location_bundle atIndex:0];
        
        // If this gave us more than our allotted queue size, delete the last object.
        if ([history_log count] > kHistoryLogSize)
            [history_log removeLastObject];
        
        // Add the updated history log back to our dictionary.
        [_history_logs setObject:history_log forKey:policy];
        
        if (kDebugLevel > 0)
            NSLog(@"ProviderMasterViewControllerlocationUpdate: %@ history log at %lu objects.", policy, (unsigned long)[history_log count]);
        
        // Serialzie, encrypt, base64 then upload the history log for this policy.
        NSString* err_msg = [self uploadHistoryLog:history_log policy:policy];
        
        if (err_msg != nil || [policy isEqualToString:[PolicyController precisionLevelName:[[NSNumber alloc] initWithInt:0]]]) {
            UILocalNotification* notice = [[UILocalNotification alloc] init];
            if (err_msg != nil) {
                err_msg = [err_msg stringByAppendingFormat:@"locationUpdate:"];
                notice.alertBody = err_msg;
            } else {
                NSString* msg = [[NSString alloc] initWithFormat:@"locationUpdate: Uploaded: %+.6f, %+.6f, %f", location.coordinate.latitude, location.coordinate.longitude, location.course];
                notice.alertBody = msg;
            }
            notice.alertAction = @"Show";
            [[UIApplication sharedApplication] presentLocalNotificationNow:notice];
        }
    }  // for (id object in policies) {
    
    // Finally, save our current state (of all our history logs).
    [PersonalDataController saveState:[[NSString alloc] initWithCString:kHistoryLogFilename encoding:[NSString defaultCStringEncoding]] dictionary:_history_logs];
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

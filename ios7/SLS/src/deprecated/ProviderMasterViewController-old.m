//
//  ProviderMasterViewController.m
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 4/1/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import <MessageUI/MFMessageComposeViewController.h>
#import <MessageUI/MFMailComposeViewController.h>

#import "ProviderMasterViewController.h"
#import "KeyDeposit.h"
#import "Consumer.h"
#import "NSData+Base64.h"
#import "security-defines.h"  // XXX TODO(aka) Break up SLS URL processing & security defines!


#define SMS_SEND_ONE_MSG 1    // HACK: TODO(aka) not sure if we should bundle up the key, file-store, identity & signature in one SMS message, or three!?! 

static const int kDebugLevel = 0;

// XXX static const size_t kChosenCipherKeySize = CIPHER_KEY_SIZE;
// XXX static const size_t kChosenCipherBlockSize = CIPHER_BLOCK_SIZE;

static const char* kSchemeSLS = URI_SCHEME_SLS;
static const char* kQueryKeyEncryptedKey = URI_QUERY_KEY_ENCRYPTED_KEY;
static const char* kQueryKeyFileStoreURL = URI_QUERY_KEY_FS_URL;
static const char* kQueryKeyIdentity = URI_QUERY_KEY_IDENTITY;


@interface ProviderMasterViewController ()
@end


@implementation ProviderMasterViewController

@synthesize our_data = _our_data;
@synthesize consumer_list_controller = _consumer_list_controller;
@synthesize location_controller = _location_controller;
@synthesize symmetric_keys_controller = _symmetric_keys_controller;
@synthesize cell = _cell;
@synthesize table_view = _table_view;

BOOL location_gathering_on_startup;
static BOOL _add_self_status = false;

// Enum CSSM_ALGID_AES taken from SecKeyWrapper.m in CryptoExercises.

// TOOD(aka) I have no idea what value CSSM_ALGID_AES is being set to, i.e, 0x8000000L + 1, 0x8000000L * 2, or just 2?

enum {
    CSSM_ALGID_NONE = 0x00000000L,
    CSSM_ALGID_VENDOR_DEFINED = CSSM_ALGID_NONE + 0x80000000L,
    CSSM_ALGID_AES
};

- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:init: called.");
    
    if (self = [super init]) {
        _our_data = nil;
        _consumer_list_controller = nil;
        _location_controller = nil;
        _symmetric_keys_controller = nil;
        location_gathering_on_startup = false;
        
        return self;
    }
    
    return nil;
}

- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil {
    if (kDebugLevel > 2)
        NSLog(@"AddProviderQRViewController:initWithNibName: called.");
    
    self = [super initWithNibName:nib_name_or_nil bundle:nib_bundle_or_nil];
    if (self) {
        // Custom initialization
        _our_data = nil;
        _consumer_list_controller = nil;
        _location_controller = nil;
        _symmetric_keys_controller = nil;
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
    
    [_our_data loadState:PDC_PROVIDER_MODE];
    
    // Note, my_data may still be empty at this point if state was not previously saved.
    
    // Build our consumer list controller.
    _consumer_list_controller = [[ConsumerListController alloc] init];
    [_consumer_list_controller loadState];  // grab previous state
    
    for (int i = 0; i < [_consumer_list_controller countOfList]; ++i) {
        if (kDebugLevel > 0)
            NSLog(@"ProviderMasterViewController:loadState: Consumer[%d]: %s.", i,  [[[_consumer_list_controller objectInListAtIndex:i] absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        
        if ([[[_consumer_list_controller objectInListAtIndex:i] identity] caseInsensitiveCompare:_our_data.identity] == NSOrderedSame)
            _add_self_status = true;
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
    
    // Finally, if we had to generate any new keys, notify the consumers (provided, of course, that our file-store in our personal data is complete!
    
    if ([PersonalDataController isFileStoreComplete:_our_data.file_store]) {
        for (int i = 0; i < [new_keys count]; ++i) {
            NSLog(@"ProviderMasterViewController:loadState: Sending symmetric key for precision level %d.", [[new_keys objectAtIndex:i] intValue]);
            [self sendSymmetricKey:[new_keys objectAtIndex:i] consumer:nil];
        }
        
#if 1
        // TOOD(aka) Code to send our symmetric keys to everyone (if we decide that starting up is a good time to remind all our consumers ...
        
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

- (void) viewDidLoad {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:viewDidLoad: called.");
    
    [super viewDidLoad];
    
	// Do any additional setup after loading the view, typically from a nib.
    
    [self configureView];
    
    if (location_gathering_on_startup)
        [_location_controller enableLocationGathering];
}

- (void) viewDidUnload {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:viewDidUnload: called.");
    
    // Note, this is where we clean up any *strong* references.
    [self setTable_view:nil];
    [super viewDidUnload];
}

- (void) configureView {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:configureView: called.");
    
    
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:shouldAutorotateToInterfaceOrientation: called.");
    
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

// UITableView data source functions.
- (NSInteger) tableView:(UITableView*)table_view numberOfRowsInSection:(NSInteger)section {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:tableView:numberOfRowsInSection: called.");
    
    return [self.consumer_list_controller countOfList];
}

- (UITableViewCell*) tableView:(UITableView*)table_view cellForRowAtIndexPath:(NSIndexPath*)index_path {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:tableView:cellForRowAtIndexPath: called.");

    Consumer* consumer = [_consumer_list_controller objectInListAtIndex:index_path.row];
    
    NSLog(@"ProviderMasterViewController:tableView:cellForRowAtIndexPath: working on cell with consumer: %s, precision: %d, with index path: %ld.", [consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [consumer.precision intValue], (long)index_path.row);
    
#if 0  // XXX Old way where we coudn't get slider to work.
    static NSString* cell_identifier = @"ConsumerCell";
    UITableViewCell* cell = 
        [table_view dequeueReusableCellWithIdentifier:cell_identifier];
    UILabel* label = (UILabel*)[cell viewWithTag:1];  // 1 is set in IB
    label.text = consumer.identity;
    // label.tag = index_path.row;
    
    UISlider* slider = (UISlider*)[cell viewWithTag:2];  // 2 is set in IB
    slider.value = (float)[consumer.precision floatValue];
    NSLog(@"ProviderMasterViewController:tableView:cellForRowAtIndexPath: setting slider tag to: %d.", index_path.row);
    slider.tag = index_path.row;
#endif
    
    static NSString* cell_identifier = @"ConsumerCell";
    static NSString* cell_nib = @"ConsumerCell";
    
    ConsumerCellController* cell = (ConsumerCellController*)[table_view dequeueReusableCellWithIdentifier:cell_identifier];
    if (cell == nil) {
        NSArray* nib_objects = [[NSBundle mainBundle] loadNibNamed:cell_nib owner:self options:nil];
        cell = (ConsumerCellController*)[nib_objects objectAtIndex:0];
        cell.delegate = self;
        // XXX Do I need to nil out our view?
     }
     
    // Add data to cell.
    cell.label.text = consumer.identity;
    cell.label.tag = index_path.row;

    cell.slider.value = (float)[consumer.precision floatValue];
    NSLog(@"ProviderMasterViewController:tableView:cellForRowAtIndexPath: setting slider tag to: %ld.", (long)index_path.row);
    cell.slider.tag = index_path.row;
    
    // For now, give button a label representing our tag number.
    NSString* button_title = [[NSString alloc] initWithFormat:@"%ld", (long)index_path.row];
    [cell.button setTitle:button_title forState:UIControlStateNormal];
    cell.button.tag = index_path.row;
    
    return cell;
}

- (void) prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:prepareForSeque: called.");
    
    if ([[segue identifier] isEqualToString:@"ShowConsumerListDataView"]) {
        /*
         NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
         NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
         [[segue destinationViewController] setDetailItem:object];
         */
        
        NSLog(@"ProviderMasterViewController:prepareForSeque: Segue'ng to ShowConsumerListDataView.");
        
        // Set ourselves up as the delegate and pass in *our_data*.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        ConsumerListDataViewController* view_controller = (ConsumerListDataViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        view_controller.consumer = sender;
        view_controller.delegate = self;
    } else if ([[segue identifier] isEqualToString:@"ShowAddConsumerView"]) {
        if (kDebugLevel > 0)
            NSLog(@"ProviderMasterViewController:prepareForSeque: Segue'ng to ShowAddConsumerView.");
        
        // Set ourselves up as the delegate and pass in *our_data*.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        AddConsumerViewController* view_controller = (AddConsumerViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        view_controller.our_data = _our_data;
        view_controller.delegate = self;
    } else if ([[segue identifier] isEqualToString:@"ShowProviderDataView"]) {
        if (kDebugLevel > 0)
            NSLog(@"ProviderMasterViewController:prepareForSeque: Segue'ng to ShowProviderDataView.");
        
        // Set ourselves up as the delegate and pass in *our_data*.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        ProviderDataViewController* view_controller = (ProviderDataViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        view_controller.our_data = _our_data;
        view_controller.location_controller = _location_controller;
        view_controller.symmetric_keys = _symmetric_keys_controller;
        view_controller.add_self_status = _add_self_status;
        view_controller.delegate = self;
    } else {
        if (kDebugLevel > 0)
            NSLog(@"ProviderMasterViewController:prepareForSeque: TODO(aka) unknown segue: %s.", [[segue identifier] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    }
}

- (void) sendSymmetricKey:(NSNumber*)precision consumer:(Consumer*)sole_consumer {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:sendSymmetricKey:consumer: called: %d.", [precision intValue]);
    
    // Get the symmetric key for this precision level.
    NSData* symmetric_key = [_symmetric_keys_controller objectForKey:precision];
    
    // Loop over each consumer and encrypt & send the key and file store *if* precision levels match ...

    for (int i = 0; i < [_consumer_list_controller countOfList]; i++) {
        Consumer* consumer = [_consumer_list_controller objectInListAtIndex:i];
        
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
        if ([PersonalDataController isKeyDepositTypeSMS:consumer.key_deposit]) {
            // Loop over the number of messages we need to send ...
#if SMS_SEND_ONE_MSG == 1
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
                
#if SMS_SEND_ONE_MSG == 1
                path = [[NSString alloc] initWithFormat:@"/?%s=%s&%s=%s&%s=%s", kQueryKeyEncryptedKey, [encrypted_key_b64 cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyFileStoreURL, [[file_store_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyIdentity, [_our_data.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
#else
                if (j == 0)
                    path = [[NSString alloc] initWithFormat:@"/?%s=%s&%s=%s", kQueryKeyEncryptedKey, [encrypted_key_b64 cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyIdentity, [_our_data.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
                else if (j == 1)
                    path = [[NSString alloc] initWithFormat:@"/?%s=%s&%s=%s",  kQueryKeyFileStoreURL, [[file_store_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyIdentity, [_our_data.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
#endif
                NSURL* sls_url = [[NSURL alloc] initWithScheme:scheme host:host path:path];

                NSString* phone_number = [PersonalDataController getKeyDepositPhoneNumber:consumer.key_deposit];
                
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
        } else if ([PersonalDataController isKeyDepositTypeEMail:consumer.key_deposit]) {
            // Build our app's custom URI to send to our consumer.
            NSString* scheme = [[NSString alloc] initWithFormat:@"%s", kSchemeSLS];
            NSString* host = @"";  // app processing doesn't use host
            NSString* path = [[NSString alloc] initWithFormat:@"/?%s=%s&%s=%s&%s=%s", kQueryKeyEncryptedKey, [encrypted_key_b64 cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyFileStoreURL, [[file_store_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyIdentity, [_our_data.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            NSURL* sls_url = [[NSURL alloc] initWithScheme:scheme host:host path:path];
            
            NSString* address = [PersonalDataController getKeyDepositAddress:consumer.key_deposit];
            
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
            NSLog(@"ProviderMasterViewController:sendSymmetricKey:precision: WARN: TODO(aka) key deposit type: %s, not supported yet!", [[PersonalDataController getKeyDepositType:consumer.key_deposit] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        }
    }
}

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


// Delegate functions.

// ConsumerCell delegate functions.
- (void) consumerCellSliderValueChanged:(UISlider*)slider {
    if (kDebugLevel > 2)
        NSLog(@"ProvderMasterViewController:consumerCellSliderValueChanged: called.");
    
    for (int i = 0; i < [self tableView:_table_view numberOfRowsInSection:0]; ++i) { 
        NSLog(@"ProvderMasterViewController:consumerCellSliderValueChanged: XXX Checking row %d, slider's tag = %ld, value = %f", i, (long)slider.tag, slider.value);
        
        if (i == slider.tag) {
            // Get the Cell's Consumer object and update the precision.
            Consumer* consumer = [_consumer_list_controller objectInListAtIndex:i];
            consumer.precision = [NSNumber numberWithFloat:slider.value];
            
            if (kDebugLevel > 0)
                NSLog(@"ProvderMasterViewController:consumerCellSliderValueChanged: Changed %s's precision to %d.", [consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [consumer.precision intValue]);
            
            break;
        }
    }
}

- (void) consumerCellButtonPressed:(UIButton*)button {
    if (kDebugLevel > 2)
        NSLog(@"ProvderMasterViewController:consumerCellButtonPressed: called.");
    
    for (int i = 0; i < [self tableView:_table_view numberOfRowsInSection:0]; ++i) {
        if (kDebugLevel > 0)
        NSLog(@"ProvderMasterViewController:consumerCellButtonPressed: comparing row %d to button's tag = %ld.", i, (long)button.tag);
        
        if (i == button.tag) {
            // Get the Cell's Consumer object and attempt to call ShowConsumerListDataView.
            Consumer* consumer = [_consumer_list_controller objectInListAtIndex:i];
            [self performSegueWithIdentifier:@"ShowConsumerListDataView" sender:consumer];
            
            break;
        }
    }
}

// ProviderDataViewController delegate functions.
- (void) providerDataViewControllerDidFinish:(PersonalDataController*)our_data coreLocationController:(CoreLocationController*)location_controller symmetricKeys:(SymmetricKeysController*)symmetric_keys addSelf:(BOOL)add_self {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:providerDataViewControllerDidFinish: called.");

    if (our_data == nil) {
        NSLog(@"ProviderMasterViewController:providerDataViewControllerDidFinish: ERROR: TODO(aka) PersonalDataController is nil!");
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    // See if our *Add Self to Consumers* status changed (and more importantly, is true!).
    if (add_self && !_add_self_status) {
        NSLog(@"ProviderMasterViewController:providerDataViewControllerDidFinish: TODO(aka) I can't think of any reason why we would want to add ourselves as a consumer?");
        
#if 0
        Consumer* tmp_consumer = [[Consumer alloc] initWithIdentity:[NSString stringWithFormat:@"%s",  kOurselves]];
#endif
        _add_self_status = add_self;
    }
    
    // Okay, overwrite our PersonalDataController, CoreLocationController and our symmetric keys controller.  Note, if new keys were generated in either view controller, state would have been saved then.
    
    _our_data = our_data;
    _symmetric_keys_controller = symmetric_keys;
    
    // We have to be careful updating any changes to the CoreLocationManager, as the CLLocationManager within that class is actually a *strong* reference.  Hence, we only want to update each flag individually.
    
    // See if either of our location sharing toggles changed.
    if (_location_controller.location_sharing_toggle != location_controller.location_sharing_toggle) {
        if (location_controller.location_sharing_toggle) {
            _location_controller.location_sharing_toggle = location_controller.location_sharing_toggle;
            _location_controller.power_saving_toggle = location_controller.power_saving_toggle;
            _location_controller.distance_filter = location_controller.distance_filter;
            [_location_controller enableLocationGathering];  // simply turn on sharing       
        } else {
            _location_controller.location_sharing_toggle = location_controller.location_sharing_toggle;
            _location_controller.power_saving_toggle = location_controller.power_saving_toggle;
            _location_controller.distance_filter = location_controller.distance_filter;
            [_location_controller disableLocationGathering];  // simply turn off sharing
        }
        
        // Update core location controller's state.
        [_location_controller saveState];
    } else {
        // Check and see if the accuracy changed.
        if (_location_controller.power_saving_toggle != location_controller.power_saving_toggle ||
            _location_controller.distance_filter != location_controller.distance_filter) {
            if (location_controller.location_sharing_toggle) {
                // Sharing is running, but at a different accuracy, so shut it down, reset our flags, and then restart it.
                
                [_location_controller disableLocationGathering];
                _location_controller.power_saving_toggle = location_controller.power_saving_toggle;
                _location_controller.distance_filter = location_controller.distance_filter;
                [_location_controller enableLocationGathering];
            } else {
                // It's not running, but we did change some variables (for when it does run again).
                _location_controller.power_saving_toggle = location_controller.power_saving_toggle;
                _location_controller.distance_filter = location_controller.distance_filter;
            }
            
            // Update core location controller's state.
            [_location_controller saveState];
        }
    } // if (_location_controller.location_sharing_toggle != location_controller.location_sharing_toggle) {
    
    // Since our file-store may have changed, notify our consumers (provided, of course, that our file-store in our personal data is complete)!
    
    NSLog(@"ProviderMasterViewController:providerDataViewControllerDidFinish: TODO(aka) we are sending out our the symmetric keys, regardless, here!");
    
    // Yes, so we have to stop this, but how?  (i) we can try to send them in ProviderDataViewController done: (assuming we can tell that the file store was indeed changed.  (ii) we can pop up a message that says *if you changed the file store, please resend the symmetric keys*?
    
    if ([PersonalDataController isFileStoreComplete:_our_data.file_store]) {
        NSEnumerator* enumerator = [_symmetric_keys_controller keyEnumerator];
        id key;
        while ((key = [enumerator nextObject])) {
            if (kDebugLevel > 0)
                NSLog(@"ProviderMasterViewController:providerDataViewControllerDidFinish: sending symmetric key for precision: %d.", [key intValue]);
            [self sendSymmetricKey:key consumer:nil];
        }
    } else {
        if (kDebugLevel > 0)
            NSLog(@"ProviderMasterViewController:providerDataViewControllerDidFinish:sharingToggle:accuracyToggle: file store not complete.");
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) providerDataViewControllerDidCancel:(ProviderDataViewController*)controller {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:providerDataViewControllerDidCancel: called.");
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

// ConsumerListDataViewController delegate functions.
- (void) consumerListDataViewControllerDidFinish:(Consumer*)consumer sendKey:(BOOL)send_key {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:consumerListDataViewControllerDidFinish: called: %d.", send_key);
    
    if (kDebugLevel > 0)
        NSLog(@"ProviderMasterViewController:consumerListDataViewControllerDidFinish: updating consumer \"%s\".", [consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    // Update our consumer list (via addConsumer, which deletes, than re-adds).
    NSString* error_msg = [_consumer_list_controller addConsumer:consumer];
    if (error_msg != nil) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMasterViewController:consumerListDataViewControllerDidFinish:" message:error_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
        [alert show];
    }
    
    if (send_key) {
        [self sendSymmetricKey:consumer.precision consumer:consumer];
        
        if (kDebugLevel > 0)
            NSLog(@"ProvderMasterViewController:consumerListDataViewControllerDidFinish: Sent %s their symmetric key at precision: %d.", [consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [consumer.precision intValue]);
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    NSLog(@"ProvderMasterViewController:consumerListDataViewControllerDidFinish: TODO(aka) We are currently reloading the entire table, what we want to do is save the indexPath of the selected row, and only reload that row!");
    
    [_table_view reloadData];
}

- (void) consumerListDataViewControllerDidCancel:(ConsumerListDataViewController*)controller {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:consumerListDataViewControllerDidCancel: called.");
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void) consumerListDataViewControllerDidDelete:(Consumer*)consumer {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:consumerListDataViewControllerDidDelete: called.");
    
    if (![_consumer_list_controller containsObject:consumer])
        return;
    
    if (kDebugLevel > 0)
        NSLog(@"ProviderMasterViewController:consumerListDataViewControllerDidDelete: deleting consumer \"%s\".", [consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    NSString* error_msg = [_consumer_list_controller deleteConsumer:consumer saveState:true];
    if (error_msg != nil) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMasterViewController:consumerListDataViewControllerDidDelete:" message:error_msg delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
        [alert show];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [_table_view reloadData];
}

// AddConsumerViewController delegate functions.
- (void) addConsumerViewControllerDidFinish:(Consumer*)consumer {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:addConsumerViewControllerDidFinish: called.");
    
    if (consumer.identity.length) {
        consumer.precision = 0;  // by default, everyone starts with the least precision
        
        [self.consumer_list_controller addConsumer:consumer];
        
        NSLog(@"ProviderMasterViewController:addConsumerViewControllerDidFinish: TODO(aka) Figure out how to reload data!");
        
        // XXX [[self tableView] reloadData];   // TODO(aka) worked when controller was UITableViewController
       
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"New Consumer" message:@"Don't forget to set the new consumer's precision leve!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];    
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) addConsumerViewControllerDidCancel:(AddConsumerViewController*)controller {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:addConsumerViewControllerDidCancel: called.");
    
    [self dismissViewControllerAnimated:YES completion:NULL];
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

- (void) didReceiveMemoryWarning {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:didReceiveMemoryWarning: called.");
    
    [super didReceiveMemoryWarning];
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


#if 0 // XXX
- (NSData*) encryptSymmetricKey:(NSData*)symmetric_key publicKey:(SecKeyRef)public_key {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:encryptSymmetricKey:keyRef: called.");
    
    if (symmetric_key == nil) {
        NSLog(@"ProviderMasterViewController:encryptSymmetricKey:keyRef: ERROR: Symmetric key is nil.");
        return nil;
    } else {
        if (kDebugLevel > 0)
            NSLog(@"ProviderMasterViewController:encryptSymmetricKey:keyRef: symmetric key: %dB.", [symmetric_key length]);
    }
    
    if (public_key == nil) {
        NSLog(@"ProviderMasterViewController:encryptSymmetricKey:keyRef: ERROR: Public key is nil.");
        return nil;
    }
    
    // Calculate the buffer sizes.
    size_t plain_text_buf_size = [symmetric_key length];
    size_t cipher_block_size = SecKeyGetBlockSize(public_key);
    
    // Note, when using pkcs1 padding (which we are), the maximum amount of data we can encrypt is 11 bytes less than the block length associated with the public key.
    if (plain_text_buf_size > (cipher_block_size - 11)) {
        NSLog(@"ProviderMasterViewController:encryptSymmetricKey:keyRef: TODO(aka) symmetric key (%ld) is too large for the public key's block size %ld (- 11).", plain_text_buf_size, cipher_block_size);
        return nil;    
    }
    
    size_t cipher_text_buf_size = cipher_block_size;  // to avoid confusion later on
    
    // Allocate the cipher text buffer.
    uint8_t* cipher_text_buf = NULL;
    cipher_text_buf = (uint8_t*)malloc(cipher_text_buf_size * sizeof(uint8_t));
    if (cipher_text_buf == NULL) {
        NSLog(@"ProviderMasterViewController:encryptSymmetricKey:keyRef: unable to malloc cipher text buffer.");
        return nil;    
    }
    memset((void*)cipher_text_buf, 0x0, cipher_text_buf_size);
    
    // Encrypt using the public key.
    OSStatus sanityCheck = noErr;
    sanityCheck = SecKeyEncrypt(public_key,
                                kSecPaddingPKCS1,
                                (const uint8_t*)[symmetric_key bytes],
                                plain_text_buf_size,
                                cipher_text_buf,
                                &cipher_text_buf_size
                                );
    if (sanityCheck != noErr) {
        NSLog(@"ProviderMasterViewController:encryptSymmetricKey:keyRef: Error encrypting symmetric key, OSStatus == %ld.", sanityCheck);
        return nil;
    }
    
    // Encode cipher text as a NSData object.
    NSData* cipher = [NSData dataWithBytes:(const void*)cipher_text_buf length:(NSUInteger)cipher_text_buf_size];
    
    if (cipher_text_buf) 
        free(cipher_text_buf);
    
    return cipher;
}

- (NSData*) encryptLocationData:(NSData*)location_data dataSize:(size_t)data_size symmetricKey:(NSData*) symmetric_key {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:encryptLocationData:dataSize:symmetricKey: called.");
    
    // Encrypt with symmetric key (using the CommonCrypto library).
    if (kDebugLevel > 0)
        NSLog(@"ProviderMasterViewController:encryptLocationData:dataSize:symmetricKey: cipher block size: %ld, plain text size: %ld.", kChosenCipherBlockSize, data_size);
    
    // Setup an initialization vector.
    uint8_t iv[kChosenCipherBlockSize];
    if (SecRandomCopyBytes(kSecRandomDefault, kChosenCipherBlockSize, iv) != 0) {
        NSLog(@"ProviderMasterViewController:encryptLocationData:dataSize:symmetricKey: Unable to generate IV!");
        memset((void*)iv, 0x0, (size_t)sizeof(iv));  // make it all zeros, for now
    }
    
    // Set aside space for the cipher-text buffer.  Note, this is guarenteed to be no bigger than the plain-text size plus one cipher-block size (for a block cipher).  
    
    // TODO(aka) We can use CCCryptorGetOutputLength() to get the exact amount we need, but that requires setting up a CCCryptor reference first (via CCCryptorCreate()).
    
    size_t cipher_buf_size = [location_data length] + kChosenCipherBlockSize;
    uint8_t* cipher_text = (uint8_t*)malloc(cipher_buf_size * sizeof(uint8_t));
    if (cipher_text == NULL) {
        NSLog(@"ProviderMasterViewController:encryptLocationData:dataSize:symmetricKey: unable to malloc cipher-text buffer for encryption!");
        return nil;
    }
    
    size_t bytes_encrypted = 0;  // number of bytes moved into cipher-text buffer
    CCCryptorStatus ccStatus = kCCSuccess;
    ccStatus = CCCrypt(kCCEncrypt,
                       kCCAlgorithmAES128,
                       kCCOptionPKCS7Padding,
                       (const void*)[symmetric_key bytes],
                       kChosenCipherKeySize,
                       iv,
                       (const void*)[location_data bytes],
                       [location_data length],
                       (void*)cipher_text,
                       cipher_buf_size,
                       &bytes_encrypted
                       );
    
    switch (ccStatus) {
        case kCCSuccess:
            if (kDebugLevel > 0)
                NSLog(@"ProviderMasterViewController:encryptLocationData:dataSize:symmetricKey: Encrypted %ld bytes of cipher text.", bytes_encrypted);
            break;
        case kCCParamError: // illegal parameter value
            NSLog(@"ProviderMasterViewController:encryptLocationData:dataSize:symmetricKey: CCCrypt() status kCCParamError!");
            break;
        case kCCBufferTooSmall: // insufficent buffer provided for specified operation
            NSLog(@"ProviderMasterViewController:encryptLocationData:dataSize:symmetricKey: CCCrypt() status kCCBufferTooSmall!");
            break;
        case kCCMemoryFailure:  // memory allocation failure
            NSLog(@"ProviderMasterViewController:encryptLocationData:dataSize:symmetricKey: CCCrypt() status kCCMemoryFailure!");
            break;
        case kCCAlignmentError:  // input size was not aligned properly
            NSLog(@"ProviderMasterViewController:encryptLocationData:dataSize:symmetricKey: CCCrypt() status kCCAlignmentError!");
            break;
        case kCCDecodeError:  // input data did not decode or decrypt properly
            NSLog(@"ProviderMasterViewController:encryptLocationData:dataSize:symmetricKey: CCCrypt() unknown status: %d.", ccStatus);
            break;
        case kCCUnimplemented:  // function not implemented for the current algorithm
            NSLog(@"ProviderMasterViewController:encryptLocationData:dataSize:symmetricKey: CCCrypt() unknown status: %d.", ccStatus);
            break;
        default:
            NSLog(@"ProviderMasterViewController:encryptLocationData:dataSize:symmetricKey: CCCrypt() unknown status: %d.", ccStatus);
            break;
    }
    
    /* 
     // TODO(aka) Here's the block-by-block method.
     CCCryptorRef thisEncipher = NULL;  // symmetric crypto reference
     NSData* cipherOrPlainText = nil;  // cipher Text container
     uint8_t* bufferPtr = NULL;  // Pointer to output buffer
     size_t bufferPtrSize = 0;  // Total size of the buffer.
     size_t remainingBytes = 0;  // Remaining bytes to be performed on.
     size_t totalBytesWritten = 0;  // Placeholder for total written.
     uint8_t* ptr;  // A friendly helper pointer.
     size_t movedBytes = 0;  // Number of bytes moved to buffer.
     
     // We don't want to toss padding on if we don't need to
     if (encryptOrDecrypt == kCCEncrypt) {
     if (*pkcs7 != kCCOptionECBMode) {
     if ((plainTextBufferSize % kChosenCipherBlockSize) == 0) {
     *pkcs7 = 0x0000;
     } else {
     *pkcs7 = kCCOptionPKCS7Padding;
     }
     }
     } else if (encryptOrDecrypt != kCCDecrypt) {
     LOGGING_FACILITY1( 0, @"Invalid CCOperation parameter [%d] for cipher context.", *pkcs7 );
     } 
     
     // Create and Initialize the crypto reference.
     CCCryptorStatus ccStatus = kCCSuccess;
     ccStatus = CCCryptorCreate(kCCEncrypt, 
     kCCAlgorithmAES128, 
     *pkcs7, 
     (const void *)[symmetricKey bytes], 
     kChosenCipherKeySize, 
     (const void *)iv, 
     &thisEncipher
     );
     
     LOGGING_FACILITY1( ccStatus == kCCSuccess, @"Problem creating the context, ccStatus == %d.", ccStatus );
     
     // Calculate byte block alignment for all calls through to and including final.
     bufferPtrSize = CCCryptorGetOutputLength(thisEncipher, plainTextBufferSize, true);
     
     // Allocate buffer.
     bufferPtr = malloc( bufferPtrSize * sizeof(uint8_t) );
     
     // Zero out buffer.
     memset((void *)bufferPtr, 0x0, bufferPtrSize);
     
     // Initialize some necessary book keeping.
     
     ptr = bufferPtr;
     
     // Set up initial size.
     remainingBytes = bufferPtrSize;
     
     // Actually perform the encryption or decryption.
     ccStatus = CCCryptorUpdate( thisEncipher,
     (const void *) [plainText bytes],
     plainTextBufferSize,
     ptr,
     remainingBytes,
     &movedBytes
     );
     
     LOGGING_FACILITY1( ccStatus == kCCSuccess, @"Problem with CCCryptorUpdate, ccStatus == %d.", ccStatus );
     
     // Handle book keeping.
     ptr += movedBytes;
     remainingBytes -= movedBytes;
     totalBytesWritten += movedBytes;
     
     // Finalize everything to the output buffer.
     ccStatus = CCCryptorFinal(  thisEncipher,
     ptr,
     remainingBytes,
     &movedBytes
     );
     
     totalBytesWritten += movedBytes;
     
     if (thisEncipher) {
     (void) CCCryptorRelease(thisEncipher);
     thisEncipher = NULL;
     }
     
     LOGGING_FACILITY1( ccStatus == kCCSuccess, @"Problem with encipherment ccStatus == %d", ccStatus );
     
     cipherOrPlainText = [NSData dataWithBytes:(const void *)bufferPtr length:(NSUInteger)totalBytesWritten];
     
     if (bufferPtr) free(bufferPtr);
     
     return cipherOrPlainText;
     */
    
    /*
     // TODO(aka) And here's another method ...
     OSStatus status = noErr;
     status = SecKeyEncrypt(key, kSecPaddingPKCS1, plain_text, locationStr.length, cipher_text, &cipher_len);
     if (status != noErr) {
     NSLog(@"ProviderMasterViewController:locationManager:didUpdateToLocation:fromLocation: SecKeyEncrypt failed: %ld.", status);
     }
     */
    
    // Prefix the IV to the encrypted location data and format the bundle as an NSData object.
    size_t bundle_size = kChosenCipherBlockSize + bytes_encrypted;
    NSMutableData* bundle = [NSMutableData dataWithLength:bundle_size];
    [bundle setData:[[NSData alloc] initWithBytes:(const void*)iv length:kChosenCipherBlockSize]];
    [bundle appendBytes:(const void*)cipher_text length:bytes_encrypted];
    
    if (cipher_text)
        free(cipher_text);
    
    if (kDebugLevel > 0)
        NSLog(@"ProviderMasterViewController:encryptLocationData:dataSize:symmetricKey: returning %ld byte iv + cipher-text bundle.\n", bundle_size);
    
    return bundle;
}

// XXX TODO(aka) Just used for testing encryption on one phone.
- (NSData*) decryptLocationData:(NSData*)encrypted_bundle bundleSize:(NSInteger)bundle_size symmetricKey:(NSData*)symmetric_key {
    if (kDebugLevel > 2)
        NSLog(@"ProviderMasterViewController:decryptLocationData:dataSize:symmetricKey: called.");
    
    // Decrypt the location data with the symmetric key (using the CommonCrypto library).
    
    if (kDebugLevel > 0)
        NSLog(@"ProviderMasterViewController:decryptLocationData:dataSize:symmetricKey: cipher block size: %ld, cipher buf size: %d.", kChosenCipherBlockSize, bundle_size);
    
    // Set aside space for the plain-text buffer.  Note, this is guarenteed to be no bigger than the cipher-text size plus one cipher-block size (for a block cipher).  
    
    size_t plain_text_buf_size = bundle_size + kChosenCipherBlockSize;  // TOOD(aka) bundle_size has IV!
    uint8_t* plain_text = (uint8_t*)malloc(plain_text_buf_size * sizeof(uint8_t));
    if (plain_text == NULL) {
        NSLog(@"ProviderMasterViewController:decryptLocationData:dataSize:symmetricKey: unable to malloc plain-text buffer for decryption!");
        return nil;
    }
    
    const uint8_t* cipher_text = [encrypted_bundle bytes];  // move encrypted data to uint_8 buffer
    size_t bytes_decrypted = 0;  // number of bytes moved into plain-text buffer
    CCCryptorStatus ccStatus = kCCSuccess;
    ccStatus = CCCrypt(kCCDecrypt,
                       kCCAlgorithmAES128,
                       kCCOptionPKCS7Padding,
                       (const void*)[symmetric_key bytes],
                       kChosenCipherKeySize,
                       cipher_text,  /* first kChosenCipherBlockSize is the IV */
                       (const void*)(cipher_text + kChosenCipherBlockSize),
                       bundle_size - kChosenCipherBlockSize,
                       (void*)plain_text,
                       plain_text_buf_size,
                       &bytes_decrypted
                       );
    
    switch (ccStatus) {
        case kCCSuccess:
            if (kDebugLevel > 0)
                NSLog(@"ProviderMasterViewController:decryptLocationData:dataSize:symmetricKey: Decrypted %ld bytes of plain text.", bytes_decrypted);
            break;
        case kCCParamError: // illegal parameter value
            NSLog(@"ProviderMasterViewController:decryptLocationData:dataSize:symmetricKey: CCCrypt() status kCCParamError!");
            break;
        case kCCBufferTooSmall: // insufficent buffer provided for specified operation
            NSLog(@"ProviderMasterViewController:decryptLocationData:dataSize:symmetricKey: CCCrypt() status kCCBufferTooSmall!");
            break;
        case kCCMemoryFailure:  // memory allocation failure
            NSLog(@"ProviderMasterViewController:decryptLocationData:dataSize:symmetricKey: CCCrypt() status kCCMemoryFailure!");
            break;
        case kCCAlignmentError:  // input size was not aligned properly
            NSLog(@"ProviderMasterViewController:decryptLocationData:dataSize:symmetricKey: CCCrypt() status kCCAlignmentError!");
            break;
        case kCCDecodeError:  // input data did not decode or decrypt properly
            NSLog(@"ProviderMasterViewController:decryptLocationData:dataSize:symmetricKey: CCCrypt() unknown status: %d.", ccStatus);
            break;
        case kCCUnimplemented:  // function not implemented for the current algorithm
            NSLog(@"ProviderMasterViewController:decryptLocationData:dataSize:symmetricKey: CCCrypt() unknown status: %d.", ccStatus);
            break;
        default:
            NSLog(@"ProviderMasterViewController:decryptLocationData:dataSize:symmetricKey: CCCrypt() unknown status: %d.", ccStatus);
            break;
    }
    
    // Convert the plain-text buffer to a NSData object.
    NSData* plain_text_data = [[NSData alloc] initWithBytes:(const void*)plain_text length:plain_text_buf_size];
    
    if (plain_text)
        free(plain_text);
    
    if (kDebugLevel > 0)
        NSLog(@"ProviderMasterViewController:decryptLocationData:dataSize:symmetricKey: returning %ld byte plain text.", bytes_decrypted);
    
    return plain_text_data;
}
#endif

@end

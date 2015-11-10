//
//  ProviderMasterViewController.m
//  SLS
//
//  Created by Andrew K. Adams on 11/19/13.
//  Copyright (c) 2013 Andrew K. Adams. All rights reserved.
//

#import <sys/time.h>

#import <AddressBook/AddressBook.h>

#import "GTMOAuth2ViewControllerTouch.h"
#import "NSData+Base64.h"

#import "ProviderMasterViewController.h"
#import "ProviderDataViewController.h"
#import "ConsumerListDataViewController.h"
#import "AddConsumerViewController.h"
#import "AddConsumerCTViewController.h"
#import "AddConsumerHCCViewController.h"
#import "KeyBundleController.h"
#import "LocationBundleController.h"
#import "Principal.h"

#import "sls-url-defines.h"
#import "security-defines.h"

#import "ConsumerMasterViewController.h"  // XXX Just to debug delegate stuff

static const int kDebugLevel = 3;

// ACCESS_GROUPS:
static const char* kAccessGroupHCC = KC_ACCESS_GROUP_HCC;

static const char* kSchemeSLS = URI_SCHEME_SLS;

static const char* kPathFileStore = URI_PATH_FILE_STORE;
static const char* kPathHCCMsg1 = URI_PATH_HCC_MSG1;  // consumer's HCC pubkey & identity-token
static const char* kPathHCCMsg3 = URI_PATH_HCC_MSG3;  // consumer's HCC nonce response
static const char* kPathHCCMsg5 = URI_PATH_HCC_MSG5;  // consumer's HCC encrypted nonce challenge, secret-question reply & secret-question
static const char* kPathHCCMsg7 = URI_PATH_HCC_MSG7;  // consumer's HCC encrypted deposit & both nonces

static const char kPathDelimiter = URI_PATH_DELIMITER;

static const char* kQueryKeyID = URI_QUERY_KEY_ID;
static const char* kQueryKeyPubKey = URI_QUERY_KEY_PUB_KEY;
static const char* kQueryKeyChallenge = URI_QUERY_KEY_CHALLENGE;
static const char* kQueryKeyResponse = URI_QUERY_KEY_CHALLENGE_RESPONSE;
static const char* kQueryKeySecretQuestion = URI_QUERY_KEY_SECRET_QUESTION;
static const char* kQueryKeyAnswer = URI_QUERY_KEY_SQ_ANSWER;
static const char* kQueryKeyOurChallenge = URI_QUERY_KEY_OUR_CHALLENGE;
static const char* kQueryKeyTheirChallenge = URI_QUERY_KEY_THEIR_CHALLENGE;
static const char* kQueryKeyDeposit = URI_QUERY_KEY_DEPOSIT;

static const char* kQueryKeyFileStoreURL = URI_QUERY_KEY_FS_URL;
static const char* kQueryKeyKeyBundleURL = URI_QUERY_KEY_KB_URL;
static const char* kQueryKeyTimeStamp = URI_QUERY_KEY_TIME_STAMP;
static const char* kQueryKeySignature = URI_QUERY_KEY_SIGNATURE;

static const char* kFSKeyService = "service";
static const char* kFSKeyNonce = "nonce";                         // unique tag created when file-store is chosen

static const char* kFSRootFolderName = PDC_ROOT_FOLDER_NAME;      // root folder to store SLS data in file-store
static const char* kFSHistoryLogFile = PDC_HISTORY_LOG_FILENAME;  // filename for history-log in file-store
static const char* kFSKeyBundleExt = PDC_KEY_BUNDLE_EXTENSION;    // extension of key-bundle in file-store

static const char* kFSAsyncOpDone = PDC_ASYNC_OP_DONE;    // NSNotification flag

static const char* kGDriveIDsFilename = "drive-ids.dict";         // filename to store the drive_ids dictionary on local disk
static const char* kGDriveWVLsFilename = "drive-wvls.dict";       // filename to store the drive_wvls dictionary on local disk

static const int kHistoryLogSize = 3;  // TODO(aka) need to add to a define file
static const char* kHistoryLogFilename = "history-log.dict";  // filename for history log state on local disk (not file-store!)

static const char kArraySerializerDelimiter = ' ';  // TODO(aka) need to add to a define file

static const char* kAlertButtonCancelPairingMessage = "No, cancel pairing!";
static const char* kAlertButtonContinuePairingMessage = "Yes, continue with pairing.";

static const char* kStateDataUpdate = "stateDataUpdate";  // TODO(aka) need to add to a define file

static Principal* us_as_consumer = nil;     // us, and a flag used during asynchronous file-store track-self operations


@interface ProviderMasterViewController ()

@end

@implementation ProviderMasterViewController

#pragma mark - Local variables
@synthesize our_data = _our_data;
@synthesize consumer_list = _consumer_list;
@synthesize symmetric_keys_controller = _symmetric_keys_controller;
@synthesize location_controller = _location_controller;
@synthesize history_logs = _history_logs;
@synthesize potential_consumers = _potential_consumers;
@synthesize potential_consumer = _potential_consumer;
@synthesize delegate = _delegate;

#pragma mark - Outlets
@synthesize table_view = _table_view;

BOOL location_gathering_on_startup;
BOOL continue_pairing;

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
    if (kDebugLevel > 4)
        NSLog(@"ProviderMVC:init: called.");
    
    if (self = [super init]) {
        _our_data = nil;
        _consumer_list = nil;
        _symmetric_keys_controller = nil;
        _location_controller = nil;
        _history_logs = nil;
        _potential_consumers = nil;
        _potential_consumer = nil;
        _delegate = nil;
        location_gathering_on_startup = false;
        continue_pairing = false;
        
        return self;
    }
    
    return nil;
}

- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil {
    if (kDebugLevel > 4)
        NSLog(@"ProviderMVC:initWithNibName: called.");
    
    self = [super initWithNibName:nib_name_or_nil bundle:nib_bundle_or_nil];
    if (self) {
        // Custom initialization
        _our_data = nil;
        _consumer_list = nil;
        _symmetric_keys_controller = nil;
        _location_controller = nil;
        _history_logs = nil;
        _potential_consumers = nil;
        _potential_consumer = nil;
        _delegate = nil;
        location_gathering_on_startup = false;
        continue_pairing = false;
    }
    
    return self;
}

- (id) initWithStyle:(UITableViewStyle)style {
    if (kDebugLevel > 4)
        NSLog(@"ProviderMVC:initWithStyle: called.");
    
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        _our_data = nil;
        _consumer_list = nil;
        _symmetric_keys_controller = nil;
        _location_controller = nil;
        _history_logs = nil;
        _potential_consumers = nil;
        _potential_consumer = nil;
        _delegate = nil;
        location_gathering_on_startup = false;
        continue_pairing = false;
    }

    return self;
}

- (void) loadState {
    if (kDebugLevel > 4)
        NSLog(@"ProviderMVC:loadState: called.");
    
    if (_our_data == nil) {
        if (kDebugLevel > 3)
            NSLog(@"ProviderMVC:loadState: _our_data is nil.");
        
        _our_data = [[PersonalDataController alloc] init];
    }
    
    // Set us up to listen for state-update messages from the Consumer.
    NSString* name = [NSString stringWithFormat:@"%s", kStateDataUpdate];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateOurDataState:) name:name object:nil];
    
    // And for any asynchronous file-store operations.
    // Set us up to listen for state-update messages from the Consumer.
    name = [NSString stringWithFormat:@"%s", kFSAsyncOpDone];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendConsumerVCSelf:) name:name object:nil];
    if (kDebugLevel > 0)
        NSLog(@"ProviderMVC:loadState: Added notification for %s, %s.", kStateDataUpdate, kFSAsyncOpDone);
    
    // Populate (or generate) the data associated with our data member's controllers.
    
    [_our_data loadState];
    
    // Note, our_data may still be empty at this point if state was not previously saved.
    
    // Build our consumer list and potential consumers controllers.
    _consumer_list = [[ConsumerListController alloc] init];
    [_consumer_list loadState];  // grab previous state
    
    NSString* potential_consumers_filename = [NSString stringWithFormat:@"%s.provider", HCC_PRINCIPALS_STATE_FILENAME];
    NSDictionary* tmp_potential_consumers = [PersonalDataController loadStateDictionary:potential_consumers_filename];
    if (tmp_potential_consumers != nil && [tmp_potential_consumers count] > 0)
        _potential_consumers = [tmp_potential_consumers mutableCopy];
    
    // Make sure we didn't load any bogus entries ...
    for (int i = 0; i < [_consumer_list countOfList]; ++i) {
        if (kDebugLevel > 4)
            NSLog(@"ProviderMVC:loadState: Consumer[%d]: %s.", i,  [[[_consumer_list objectInListAtIndex:i] serialize] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        
        Principal* consumer = [_consumer_list objectInListAtIndex:i];

        if (consumer.identity == nil) {
            [_consumer_list removeObjectAtIndex:i];
            if (kDebugLevel > 0)
                NSLog(@"ProviderMVC:loadState: Removing NULL entry at index: %d, new count: %lu!", i, (unsigned long)[_consumer_list countOfList]);
            NSString* err_msg = [_consumer_list saveState];
            if (err_msg != nil)
                NSLog(@"ProviderMVC:loadState: %@.", err_msg);
            continue;
        }
    }
    
    // Build our symmetric keys controller.
    NSLog(@"ProviderMVC:loadState: XXXXX TODO(aka) Why am I using a temp controller here?  _symmetric_keys_controller is <strong>, so I don't think I need to worry about the setter ...");
    
    SymmetricKeysController* tmp_keys_controller = [[SymmetricKeysController alloc] init];
    NSString* err_msg = [tmp_keys_controller loadState];
    if (err_msg != nil)
        NSLog(@"ProviderMVC:loadState: TODO(aka): %@.", err_msg);
    
    if (kDebugLevel > 2)
        NSLog(@"ProviderMVC:loadState: loaded %lu symmetric keys into the tmp controller.", (unsigned long)[tmp_keys_controller count]);
    
    _symmetric_keys_controller = tmp_keys_controller;
    
    // XXXX HACK!
    /*
    NSString* policy = @"exact";
    [_symmetric_keys_controller deleteSymmetricKey:policy];
     */
    
    // Build our CLLocation controller and set the CoreLocation controller's delegate to us.
    _location_controller = [[CoreLocationController alloc] init];
    _location_controller.delegate = self;  // note, if we change the MVC (e.g., adding symmetric keys) we need to rewrite the delegate  (XXX You mean it's not a pointer?  This doesn't sound right to me ...)
    
    // Load in any previously saved state for location services, and start up (if previously on).
    [_location_controller loadState];
    
    if (_location_controller.location_sharing_toggle) {
#if 0
        NSLog(@"ProviderMVC:loadState: TODO(aka) To cut down on possible initial work, we don't start location sharing until viewDidLoad().  The problem with this, is that SLS starts up in consumer mode!");
        
        // To cut down on our pre-viewDidLoad() workload, hold off starting location gathering services *until* viewDidLoad().
        location_gathering_on_startup = true;
#else
        // Note, we want to start up in *power saving* mode, as the *full accuracy* mode can actually prevent us from loading!
        [_location_controller setPower_saving_toggle:true];
        [_location_controller enableLocationGathering];
#endif
    }
    
    // Load in any previous locations (history logs) for any policy levels we have (and make sure each individual log is not over our allocated size!).
    _history_logs = [[PersonalDataController loadStateDictionary:[[NSString alloc] initWithCString:kHistoryLogFilename encoding:[NSString defaultCStringEncoding]]] mutableCopy];
    if (_history_logs == nil)
        _history_logs = [[NSMutableDictionary alloc] initWithCapacity:kHistoryLogSize];  // TODO(aka) should be number of policies!
    
    for (id key in _history_logs) {
        NSMutableArray* history_log = [_history_logs objectForKey:key];
        while ([history_log count] > kHistoryLogSize) {
            NSLog(@"ProviderMVC:loadState: reducing %lu count \'%@\' history_log by one.", (unsigned long)[_history_logs count], key);
            [history_log removeLastObject];
        }
    }
    
    if (kDebugLevel > 1)
        NSLog(@"ProviderMVC:loadState: loaded %lu different policy-level history-logs into _history_logs.", (unsigned long)[_history_logs count]);
}

#pragma mark - View management

- (void) viewDidLoad {
    if (kDebugLevel > 4)
        NSLog(@"ProviderMVC:viewDidLoad: called.");
    
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

	// Do any additional setup after loading the view, typically from a nib.
    if (location_gathering_on_startup)
        [_location_controller enableLocationGathering];
}

- (void) viewDidAppear:(BOOL)animated {
    if (kDebugLevel > 4)
        NSLog(@"ProviderMVC:viewDidAppear: called.");
    
    [super viewDidAppear:animated];

    [self configureView];

#if 1  // SIMULATOR HACK:
    // For Debugging: the simulator can't tell if we've moved, so force location updates everytime we go to provider-mode.
    UIDevice* ui_device = [UIDevice currentDevice];
    if ([ui_device.name caseInsensitiveCompare:@"iPhone Simulator"] == NSOrderedSame) {
        // Starting point, Apple HQ?
        static float lat = 37.7858340;
        static float lon = -122.4064169;
        static int direction = 2;  // head east!
        
        // Let's get cute, and build the lat/lon with current time, use only the least significant bits (we want roughly the last four digits in seconds (0 - 9999).
        time_t now = time(NULL);
        uint32_t lsb = (uint32_t)now & 0x07FF;
        float precision = (float)lsb / 100000.0;  // make the lsb change the coordinate slightly
        
        // [0,1] stay the same, 2 we add 1 to previous direction, 3 we subtract 1 from previous direction.
        u_int32_t modifier = arc4random() % 4;
        if (modifier == 2)
            direction = (direction + 1) % 8;
        else if (modifier == 3)
            direction = (direction - 1) % 8;
        
        // Choose which direction we walk, at random (0 - 8 represent directions: N, NE, E, SE, S, SW, W, NW)
        if (direction == 0) {  // N
            lat += precision;
        } else if (direction == 1) {  // NE
            lat += precision;
            lon += precision;
        } else if (direction == 2) {  // E
            lon += precision;
        } else if (direction == 3) {  // SE
            lon += precision;
            lat -= precision;
        } else if (direction == 4) {  // S
            lat -= precision;
        } else if (direction == 5) {  // SW
            lat -= precision;
            lon -= precision;
        } else if (direction == 6) {  // W
            lon -= precision;
        } else {  // NW
            lat += precision;
            lon -= precision;
        }

        CLLocation* tmp_location = [[CLLocation alloc] initWithLatitude:lat longitude:lon];
        NSLog(@"ProviderMasterVC:viewDidAppear: DEBUG: Found device iPhone Simulator: from lsb (%d), using prec: %+.7f, direction: %d, plotting: %@.", lsb, precision, direction, [tmp_location description]);
        
        [self locationUpdate:tmp_location];
    }
#endif
}

-(void) viewWillAppear:(BOOL)animated {
    if (kDebugLevel > 4)
        NSLog(@"ProviderMVC:viewWillAppear: called (%d).", [NSThread isMainThread]);
    
    [super viewWillAppear:animated];
}

- (void) configureView {
    if (kDebugLevel > 4)
        NSLog(@"ProviderMVC:configureView: called.");
    
    if (kDebugLevel > 0) {
        // For Debugging: Get all the attributes associated with our key(s).
        
        const char* kPublicKeyExt = KC_QUERY_KEY_PUBLIC_KEY_EXT;
        NSString* pubkey_identity = [_our_data.identity stringByAppendingFormat:@"%s", kPublicKeyExt];
        NSData* pubkey_tag = [pubkey_identity dataUsingEncoding:[NSString  defaultCStringEncoding]];
        
        // XXX What's the minimum you need to search (and find) the key?
        NSMutableDictionary* pubkey_dict = [[NSMutableDictionary alloc] init];
        [pubkey_dict setObject:pubkey_tag forKey:(__bridge id)kSecAttrApplicationTag];
        [pubkey_dict setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
#if 0
        [pubkey_dict setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
        [pubkey_dict setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
        [pubkey_dict setObject:[NSNumber numberWithUnsignedInt:CSSM_ALGID_AES] forKey:(__bridge id)kSecAttrKeyType];
        [pubkey_dict setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnAttributes];
        [pubkey_dict setObject:(__bridge id)kSecAttrAccessibleAfterFirstUnlock forKey:(__bridge id)kSecAttrAccessible];
        
        [dict setObject:[NSNumber numberWithInt:kChosenKeyBitSize] forKey:(__bridge id)kSecAttrKeySizeInBits];
        [dict setObject:(__bridge id)(kSecAttrAccessibleAfterFirstUnlock) forKey:(__bridge id)(kSecAttrAccessible)];
        [public_key_dict setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecAttrIsPermanent];


        if (access_group != nil && [access_group length] > 0)
            [key_dict setObject:access_group forKey:(__bridge id)kSecAttrAccessGroup];
#endif
        
        // Attempt to get the key's attributes from the key chain.
        CFDictionaryRef return_dict_ref = NULL;
        OSStatus status = noErr;
        status = SecItemCopyMatching((__bridge CFDictionaryRef)pubkey_dict, (CFTypeRef*)&return_dict_ref);
        if (status != noErr) {
            NSLog(@"XXXX: key for %s not found!", [[[NSString alloc] initWithData:pubkey_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        } else {
            if (kDebugLevel > 0)
                NSLog(@"XXXX: saveKeyData: %s SecItemCopyMatching(%@) -> %@", [[[NSString alloc] initWithData:pubkey_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]], [pubkey_dict description], return_dict_ref);
        }
        
#if 0  // XXX
        // Setup the asymmetric key query dictionary.
        static const char* kSymmetricKey = "symmetric-key";  // prefix in key-chain
        NSString* policy = @"exact";
        NSString* application_tag_str = [[NSString alloc] initWithFormat:@"%s.%s", kSymmetricKey, [policy cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        NSData* application_tag = [application_tag_str dataUsingEncoding:[NSString  defaultCStringEncoding]];

        // XXX What's the minimum you need to search (and find) the key?
        NSMutableDictionary* key_dict = [[NSMutableDictionary alloc] init];
        [key_dict setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
        [key_dict setObject:[NSNumber numberWithUnsignedInt:CSSM_ALGID_AES] forKey:(__bridge id)kSecAttrKeyType];
        [key_dict setObject:application_tag forKey:(__bridge id)kSecAttrApplicationTag];
        [key_dict setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnAttributes];
        [key_dict setObject:(__bridge id)kSecAttrAccessibleAfterFirstUnlock forKey:(__bridge id)kSecAttrAccessible];

        //[key_dict setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnData];
        /*
        [key_dict setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
                         [kc_dict setObject:[NSNumber numberWithUnsignedInt:CSSM_ALGID_AES] forKey:(__bridge id)kSecAttrKeyType];
         [kc_dict setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnData];
         
         // Get the key.
         CFTypeRef symmetric_key_ref = nil;
         OSStatus status = noErr;
         status = SecItemCopyMatching((__bridge CFDictionaryRef)kc_dict, (CFTypeRef*)&symmetric_key_ref);
         */
#if 0
        if (access_group != nil && [access_group length] > 0)
            [key_dict setObject:access_group forKey:(__bridge id)kSecAttrAccessGroup];
#endif
        
        // Attempt to get the key's attributes from the key chain.
        CFDictionaryRef return_dict_ref = NULL;
        OSStatus status = noErr;
        status = SecItemCopyMatching((__bridge CFDictionaryRef)key_dict, (CFTypeRef*)&return_dict_ref);
        if (status != noErr) {
            NSLog(@"XXXX: key for %s not found!", [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        } else {
            if (kDebugLevel > 0)
                NSLog(@"XXXX: saveKeyData: %s SecItemCopyMatching(%@) -> %@", [[[NSString alloc] initWithData:application_tag encoding:[NSString defaultCStringEncoding]] cStringUsingEncoding:[NSString defaultCStringEncoding]], [key_dict description], return_dict_ref);
        }
#endif
    }
    
    static bool first_time_in = true;
    static bool identity_help = true;
    static bool asymmetric_keys_help = true;
    static bool file_store_help = true;
    static bool deposit_help = true;
    static bool pairing_help = true;
    
    if (self.isViewLoaded && self.view.window) {
        // USER-HELP:
        NSString* help_msg = nil;
        if (_our_data == nil || _our_data.identity == nil || [_our_data.identity length] == 0) {
            if (first_time_in) {
                help_msg = [NSString stringWithFormat:@"A \"Provider\" is one that shares or provides their location data to others.  You are currently in the PROVIDER's VIEW."];
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Provider Help" message:help_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
                first_time_in = false;
            } else if (identity_help) {
                help_msg = [NSString stringWithFormat:@"In order to share your location data with others, you first must set your identity (click on the Config button)."];
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Provider Help" message:help_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
                identity_help = false;
            }
        } else if (_our_data.privateKeyRef == NULL || _our_data.publicKeyRef == NULL) {
            if (asymmetric_keys_help) {
                help_msg = [NSString stringWithFormat:@"In order to securely share your location data, you first need to generate a private/public key pair (click on the Config button)."];
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Provider Help" message:help_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
                asymmetric_keys_help = false;
            }
        } else if (_our_data.file_store == nil || ![PersonalDataController isFileStoreComplete:_our_data.file_store]) {
            if (file_store_help) {
                help_msg = [NSString stringWithFormat:@"In order to share your location data, you must setup a cloud file-store (click on the Config button)."];
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Provider Help" message:help_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
                file_store_help = false;
            }
        } else if (_our_data.deposit == nil || [_our_data.deposit count] == 0) {
            if (deposit_help) {
                help_msg = [NSString stringWithFormat:@"In order to pair with others, you must setup a out-of-band deposit (click on the Config button)."];
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Provider Help" message:help_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
                deposit_help = false;
            }
        } else if (_consumer_list == nil || [_consumer_list countOfList] == 0) {
            if (pairing_help) {
                help_msg = [NSString stringWithFormat:@"In order to share your location, you must first pair with someone (click on the + button)."];
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Provider Help" message:help_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
                pairing_help = false;
            }
        }
    }
    
    if ([PersonalDataController isFileStoreComplete:_our_data.file_store]) {
        // Make sure we are authorized to use our file-store.
        NSString* err_msg = nil;
        if (![_our_data isFileStoreAuthorized]) {
            // Try once to get authorized.  Note, since some SDKs require a view controller, we need to check each separately here ...
            if ([PersonalDataController isFileStoreServiceAmazonS3:_our_data.file_store]) {
                err_msg = [_our_data amazonS3Auth:[PersonalDataController getFileStoreAccessKey:_our_data.file_store] secretKey:[PersonalDataController getFileStoreSecretKey:_our_data.file_store]];
            } else if ([PersonalDataController isFileStoreServiceGoogleDrive:_our_data.file_store]) {
                err_msg = [_our_data googleDriveKeychainAuth:[PersonalDataController getFileStoreKeychainTag:_our_data.file_store] clientID:[PersonalDataController getFileStoreClientID:_our_data.file_store] clientSecret:[PersonalDataController getFileStoreClientSecret:_our_data.file_store]];
                if (err_msg == nil && ![_our_data googleDriveIsAuthorized]) {
                    // Prompt the user for the credentials.
                    GTMOAuth2ViewControllerTouch* auth_controller = [[GTMOAuth2ViewControllerTouch alloc] initWithScope:@"https://www.googleapis.com/auth/drive.file" clientID:[PersonalDataController getFileStoreClientID:_our_data.file_store] clientSecret:[PersonalDataController getFileStoreClientSecret:_our_data.file_store] keychainItemName:[PersonalDataController getFileStoreKeychainTag:_our_data.file_store] delegate:self finishedSelector:@selector(viewController:finishedWithAuth:error:)];
                    
                    [self presentViewController:auth_controller animated:YES completion:nil];
                }
            } else {
                err_msg = [[NSString alloc] initWithFormat:@"Unknown file-store service: %s.", [[PersonalDataController getFileStoreService:_our_data.file_store] cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            }
            
            if (err_msg != nil) {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMasterVC:configureView:" message:err_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
            }
            
            if (![_our_data isFileStoreAuthorized]) {
                err_msg = [[NSString alloc] initWithFormat:@"Not authorized for file-store service: %s.", [[PersonalDataController getFileStoreService:_our_data.file_store] cStringUsingEncoding:[NSString defaultCStringEncoding]]];
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMasterVC:configureView:" message:err_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
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
                NSLog(@"ProviderMVC:configureView: Attempting to decrypt (%ldB): %@.", (unsigned long)[encrypted_challenge length], encrypted_challenge);
            
            NSString* decrypted_challenge = nil;
            err_msg = [PersonalDataController asymmetricDecryptString:encrypted_challenge privateKeyRef:_our_data.privateKeyRef string:&decrypted_challenge];
            if (err_msg != nil) {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Provider Help" message:err_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
            } else {
                if ([challenge_str compare:decrypted_challenge] == NSOrderedSame) {
                    help_msg = [NSString stringWithFormat:@"Asymmetric encryption test succeeded."];
                    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Provider Help" message:help_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                    [alert show];
                } else {
                    NSString* failure_msg = [NSString stringWithFormat:@"Asymmetric encryption test failed: %@ != %@.", challenge_str, decrypted_challenge];
                    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Provider Help" message:failure_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                    [alert show];
                }
            }
        }
        encryption_test = false;
    }
#endif
    
    // See if we have any SLS URLs hanging around in NSUserDefaults.
    NSString* err_msg = [self checkNSUserDefaults];
    if (err_msg != nil) {
        NSString* msg = [[NSString alloc] initWithFormat:@"ProviderMasterVC:configureView: %s.", [err_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        UILocalNotification* notice = [[UILocalNotification alloc] init];
        notice.alertBody = msg;
        notice.alertAction = @"Show";
        [[UIApplication sharedApplication] presentLocalNotificationNow:notice];
    }
}

# pragma mark - Memory management

- (void) didReceiveMemoryWarning {
    if (kDebugLevel > 4)
        NSLog(@"ProviderMVC:didReceiveMemoryWarning: called.");

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
    return [self.consumer_list countOfList];
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    if (kDebugLevel > 4)
        NSLog(@"ProviderMVC:tableView:cellForRowAtIndexPath: called.");
    
    Principal* consumer = [_consumer_list objectInListAtIndex:indexPath.row];
    
    NSLog(@"ProviderMVC:tableView:cellForRowAtIndexPath: working on cell with consumer: %s, policy: %@, with index path: %ld.", [consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], consumer.policy, (long)indexPath.row);
    
#if 0  // TODO(aka) Method using a custom cell we create ...
    static NSString* cell_identifier = @"ConsumerCell";
    static NSString* cell_nib = @"ConsumerCell";
    
    ConsumerCellController* cell = (ConsumerCellController*)[tableView dequeueReusableCellWithIdentifier:cell_identifier];
    if (cell == nil) {
        NSArray* nib_objects = [[NSBundle mainBundle] loadNibNamed:cell_nib owner:self options:nil];
        cell = (ConsumerCellController*)[nib_objects objectAtIndex:0];
        cell.delegate = self;
        // Do I need to nil out our view?
    }
    
    // Add data to cell.
    cell.label.text = consumer.identity;
    cell.label.tag = indexPath.row;
    
    xxx;  // policy handled wrong
    
    cell.slider.value = (float)[consumer.policy floatValue];
    NSLog(@"ProviderMVC:tableView:cellForRowAtIndexPath: setting slider tag to: %ld.", (long)indexPath.row);
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
    if (kDebugLevel > 4)
        NSLog(@"ProviderMVC:prepareForSeque: called.");
    
    if (kDebugLevel > 1)
        NSLog(@"ProviderMVC:prepareForSegue: our identity: %s, deposit: %s, public-key: %s.", [_our_data.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [[_our_data.deposit description] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[_our_data.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    if ([[segue identifier] isEqualToString:@"ShowProviderDataViewID"]) {
        if (kDebugLevel > 1)
            NSLog(@"ProviderMVC:prepareForSeque: Segue'ng to ProviderDataViewController.");
        
        // ProviderData VC *unwinds*, so no need for a delegate, just pass in *our_data*.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        ProviderDataViewController* view_controller = (ProviderDataViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        view_controller.our_data = _our_data;
        view_controller.location_controller = _location_controller;
        view_controller.symmetric_keys = _symmetric_keys_controller;
        
        // See if we are already tracking ourselves ...
        _track_self_status = false;
        for (int i = 0; i < [_consumer_list countOfList]; ++i) {
            Principal* consumer = [_consumer_list objectInListAtIndex:i];
            if (consumer.identity != nil && [consumer.identity caseInsensitiveCompare:_our_data.identity] == NSOrderedSame) {
                _track_self_status = true;
            }
        }
        view_controller.track_self_status = _track_self_status;
        
        if (kDebugLevel > 0)
            NSLog(@"ProviderMVC:prepareForSegue: the DataView controller's identity: %s, key-deposit: %s, and public-key: %s.", [view_controller.our_data.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [[view_controller.our_data.deposit description] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[view_controller.our_data.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    } else if ([[segue identifier] isEqualToString:@"ShowAddConsumerViewID"]) {
        if (kDebugLevel > 1)
            NSLog(@"ProviderMVC:prepareForSeque: Segue'ng to AddConsumerView Controller.");
        
        // AddConsumer VC *unwinds*, so need for a delegate, just pass in *our_data*.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        AddConsumerViewController* view_controller = (AddConsumerViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        view_controller.our_data = _our_data;
    } else if ([[segue identifier] isEqualToString:@"ShowAddConsumerHCCViewID"]) {
        if (kDebugLevel > 1)
            NSLog(@"ProviderMVC:prepareForSeque: Segue'ng to AddConsumerHCCView Controller.");
        
        // AddConsumerHCC VC *unwinds*, so no need for a delegate, just pass in *our_data*.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        AddConsumerHCCViewController* view_controller = (AddConsumerHCCViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        view_controller.our_data = _our_data;
        
        // Get the potential consumer's data from our dictionary (note, dictionary indexed by identity_hash).
        for (id key in _potential_consumers) {
            if ([key isEqualToString:_potential_consumer.identity]) {
                HCCPotentialPrincipal* potential_principal = [_potential_consumers objectForKey:key];
                view_controller.potential_consumer = potential_principal;
            }
        }
    } else if ([[segue identifier] isEqualToString:@"ShowConsumerListDataViewID"]) {
        if (kDebugLevel > 1)
            NSLog(@"ProviderMVC:prepareForSeque: Segue'ng to ConsumerListDataView Controller.");
        
        // ConsumerListData VC *unwinds*, so no need for a delegate, just pass in *our_data*.
        UINavigationController* nav_controller = (UINavigationController*)segue.destinationViewController;
        ConsumerListDataViewController* view_controller = (ConsumerListDataViewController*)[[nav_controller viewControllers] objectAtIndex:0];
        Principal* principal = (Principal*)sender;
        view_controller.consumer = principal;
    } else {
        if (kDebugLevel > 0)
            NSLog(@"ProviderMVC:prepareForSeque: TODO(aka) unknown segue: %s.", [[segue identifier] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

- (IBAction) unwindToProviderMaster:(UIStoryboardSegue*)segue {
    if (kDebugLevel > 4)
        NSLog(@"ProviderMVC:unwindToProviderMaster: called.");
    
    UIViewController* sourceViewController = segue.sourceViewController;
    
    if ([sourceViewController isKindOfClass:[ProviderDataViewController class]]) {
        if (kDebugLevel > 2)
            NSLog(@"ProviderMVC:unwindToProviderMaster: ProviderDataViewController callback.");
        
        ProviderDataViewController* source = [segue sourceViewController];
        
        // Check all possible changes, and act accordingly ...
        if (source.identity_changed || source.pub_keys_changed || source.file_store_changed) {
            if (source.our_data == nil) {
                NSLog(@"ProviderMVC:unwindToProviderMaster: TODO(aka) ERROR: PersonalDataController is nil!");
                return;
            }
            
            _our_data = source.our_data;  // get the changes ...
            
            // ... and save state (and other stuff), where needed.
            if (source.file_store_changed) {
                [_our_data saveFileStoreState];
                
                for (int i = 0; i < [_consumer_list countOfList]; i++) {
                    Principal* consumer = [_consumer_list objectInListAtIndex:i];

                    NSLog(@"ProviderMVC:unwindToProviderMaster: XXX TODO(aka) And we need to check if one of the consumers is us, if so, we need to call addSelfToProviders: again!");
                    
                    [self sendCloudMetaData:consumer];
                }
            }
            
            if (source.identity_changed) {
                [_our_data saveIdentityState];
                [_our_data saveDepositState];
            }
            
            if (source.identity_changed || source.pub_keys_changed) {
                // Tell the ConsumerMaster VC to look for the new information about ourselves!
                if (![[self delegate] isKindOfClass:[ConsumerMasterViewController class]])
                    NSLog(@"ProviderMVC:unwindToProviderMaster: ERROR: Delegate not found!");
                
                if (kDebugLevel > 0)
                    NSLog(@"ProviderMVC:unwindToProviderMaster: Telling consumer to re-load state.");
                
                [[self delegate] updatePersonalDataController];
            }
        }
        
        if (source.location_sharing_toggle_changed) {
            if (kDebugLevel > 2)
                NSLog(@"ProviderMVC:unwindToProviderMaster: location sharing toggled.");
            
            if (_location_controller.location_sharing_toggle)
                _location_controller.location_sharing_toggle = false;
            else
                _location_controller.location_sharing_toggle = true;
            [_location_controller saveState];
            [_location_controller enableLocationGathering];
        }
     
        if (!_track_self_status && source.track_self_status) {
            if (kDebugLevel > 2)
                NSLog(@"ProviderMVC:unwindToProviderMaster: track self requested.");
            
            us_as_consumer = [[Principal alloc] initWithIdentity:_our_data.identity];
            [us_as_consumer setDeposit:_our_data.deposit];
            us_as_consumer.policy = [PolicyController precisionLevelName:[[NSNumber alloc] initWithInt:PC_PRECISION_IDX_EXACT]];
            
            if (kDebugLevel > 2)
                NSLog(@"ProviderMVC:unwindToProviderMaster: tmp consumer: %@, %@, %@.", us_as_consumer.identity, us_as_consumer.identity_hash, us_as_consumer.policy);
            
            // Make sure we have a symmetric key for policy EXACT.
            if (![_symmetric_keys_controller haveKey:[PolicyController precisionLevelName:[NSNumber numberWithInt:PC_PRECISION_IDX_EXACT]]]) {
                NSString* err_msg = [_symmetric_keys_controller generateSymmetricKey:[PolicyController precisionLevelName:[NSNumber numberWithInt:PC_PRECISION_IDX_EXACT]]];
                if (err_msg != nil) {
                    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMasterVC:unwindToProviderMaster:" message:err_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                    [alert show];
                    
                    return;
                } else {
                    _location_controller.delegate = self;  // reset CLLocationManager delegate
                }
            }

           // Before we can ship our meta-data to the consumer (via our delegate method, since the consumer won't receive a deposit message from us), we need to make sure the bucket exists in our file-store.  (Un)fortunately, some file-store operations are asynchronous, so all we can really do here is call the method, set a flag, and wait in configureView for the bucket to be made (before adding the ourselves as a consumer, uploading our key-bundle and informing consumer-mode that we're ready to be tracked!).
            
            // Build this consumer's (our's) personal bucket.
            NSString* root_folder_name = [NSString stringWithFormat:@"%s", kFSRootFolderName];
            NSNumber* nonce = [_our_data.file_store objectForKey:[NSString stringWithCString:kFSKeyNonce encoding:[NSString defaultCStringEncoding]]];
            NSString* consumer_bucket = [PersonalDataController hashMD5String:[[NSString alloc] initWithFormat:@"%s%d", [us_as_consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [nonce intValue]]];
            
            BOOL asynchronous = false;
            NSString* err_msg = [_our_data genFileStoreBucket:consumer_bucket rootFolder:root_folder_name asynchronous:&asynchronous];
            if (err_msg != nil) {
                // Something bad happend, report it and clear our meta-data.
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMVC:unwindToProviderMaster:" message:err_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
                us_as_consumer = nil;
                return;
            }
            
            // And make sure that this policy's (EXACT) history log bucket exists.
            NSString* policy_bucket = [PersonalDataController hashMD5String:[[NSString alloc] initWithFormat:@"%s%s%d", [_our_data.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [us_as_consumer.policy cStringUsingEncoding:[NSString defaultCStringEncoding]], [nonce intValue]]];
            err_msg = [_our_data genFileStoreBucket:policy_bucket rootFolder:root_folder_name asynchronous:&asynchronous];
            if (err_msg != nil) {
                // Something bad happend, report it and clear our meta-data.
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMVC:unwindToProviderMaster:" message:err_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
                us_as_consumer = nil;
                return;
            }
            
            NSLog(@"ProviderMVC:unwindToProviderMaster: XXXX track_self, ansync: %d, consumer bucket: %@, policy bucket: %@.", asynchronous, consumer_bucket, policy_bucket);
            
            // If we're not in asynchronous mode, then we should be good to finish up ...
            if (!asynchronous) {
                // First, add ourselves to our consumer list.
                
                // Note, we don't need to set the public key now, we'll retrieve it from the key chain when we need it (since it's already in under our identity!).
                
                if (![_consumer_list containsObject:us_as_consumer]) {
                    // We don't have ourselves, yet, so add us (i.e., we didn't load it in via state).
                    if (kDebugLevel > 0)
                        NSLog(@"ProviderMVC:unwindToProviderMaster: Adding to our consumer list: %s.", [[us_as_consumer serialize] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                    
                    [_consumer_list addConsumer:us_as_consumer];
                    [self.tableView reloadData];
                }
                
                // Note, the key-bundle upload may be asynchronous (if using Google Drive, e.g.).
                [self uploadKeyBundle:us_as_consumer.policy consumer:us_as_consumer];
                
                // Build our meta-data.
                NSURL* file_store_url = [PersonalDataController genFileStoreURLAuthority:_our_data.file_store];
                NSURL* key_bundle_url = nil;
                err_msg = [_our_data genFileStoreKeyBundle:us_as_consumer URL:&key_bundle_url];
                if (err_msg != nil) {
                    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMVC:unwindToProviderMaster: TODO(aka) " message:err_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                    [alert show];
                    return;
                }
                
                // And tell the Consumer MVC to add ourselves to their provider list!
                if (![[self delegate] isKindOfClass:[ConsumerMasterViewController class]])
                    NSLog(@"ProviderMVC:unwindToProviderMaster: ERROR: Delegate not found!");
                
                if (kDebugLevel > 0)
                    NSLog(@"ProviderMVC:unwindToProviderMaster: Sending consumer file-store URL: %s, key-bundle URL: %s.", [[file_store_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[key_bundle_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                
                [[self delegate] addSelfToProviders:_our_data.identity fileStoreURL:file_store_url keyBundleURL:key_bundle_url];
                
                _track_self_status = true;
                us_as_consumer = nil;  // clean up
            }
        }
        
#if 0 // For Debugging:
        // See if the root "SLS" folder exists in Drive.
        NSString* sls_folder_id = [_our_data.drive_ids objectForKey:[NSString stringWithFormat:@"%s", kFSRootFolderName]];
        if (sls_folder_id == nil || [sls_folder_id length] == 0) {
            NSLog(@"DEBUG: %s's root folder: %s, does NOT exist after unwind to Provider MVC", [[PersonalDataController getFileStoreService:_our_data.file_store] cStringUsingEncoding:[NSString defaultCStringEncoding]], kFSRootFolderName);
        } else {
            NSLog(@"DEBUG: %s's root folder: %s, does EXISTS after unwind to Provider MVC", [[PersonalDataController getFileStoreService:_our_data.file_store] cStringUsingEncoding:[NSString defaultCStringEncoding]], kFSRootFolderName);
        }
#endif
    } else if ([sourceViewController isKindOfClass:[ConsumerListDataViewController class]]) {
        if (kDebugLevel > 2)
            NSLog(@"ProviderMVC:unwindToProviderMaster: ConsumerListDataViewController callback.");
        
        ConsumerListDataViewController* source = [segue sourceViewController];
        
        if (kDebugLevel > 0)
            NSLog(@"ProviderMVC:unwindToProviderMaster: ConsumerListDataViewController callback: delete principal: %d, policy_changed: %d, track consumer: %d, send file-store: %d.", source.delete_principal, source.policy_changed, source.track_consumer, source.send_file_store_info);
        
        if (source.delete_principal) {
            // Delete the consumer.
            if (kDebugLevel > 0)
                NSLog(@"ProviderMVC:unwindToProviderMaster: deleting consumer: %s, public-key: %s.", [source.consumer.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [[source.consumer.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            
            // Remove the consumer (and update our state files).
            NSString* policy = source.consumer.policy;
            NSString* err_msg = [_consumer_list deleteConsumer:source.consumer saveState:YES];
            if (err_msg != nil) {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMVC:unwindToProviderMaster:" message:err_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
            }
            
            if (policy != nil && ![policy isEqualToString:[PolicyController precisionLevelName:[NSNumber numberWithInt:PC_PRECISION_IDX_NONE]]]) {
                [_symmetric_keys_controller deleteSymmetricKey:policy];
                
                if ([_consumer_list countOfPolicy:policy] > 0) {
                    NSString* err_msg = [_symmetric_keys_controller generateSymmetricKey:policy];
                    if (err_msg != nil) {
                        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMVC:unwindToProviderMaster:" message:err_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                        [alert show];
                        
                        return;
                    } else {
                        _location_controller.delegate = self;  // reset CLLocationManager delegate
                    }
                    
                    [self uploadKeyBundle:policy consumer:nil];
                }
            }

            [self.tableView reloadData];
        } else {
            if (source.policy_changed) {
                if (kDebugLevel > 0)
                    NSLog(@"ProviderMVC:unwindToProviderMaster: New policy: %@, re-keying for old policy: %@.", source.desired_policy, source.consumer.policy);
                
                // If the old policy is not PC_PRECISION_IDX_NONE, delete the symmetric key associated with that policy (it's now considered public), re-key for that policy if we have users still at the policy level, and then update those users' shared key bundle that are assigned to that policy.
                
                NSString* old_policy = source.consumer.policy;
                if (old_policy != nil && ![old_policy isEqualToString:[PolicyController precisionLevelName:[NSNumber numberWithInt:PC_PRECISION_IDX_NONE]]]) {
                    [_symmetric_keys_controller deleteSymmetricKey:old_policy];
                    
                    if ([_consumer_list countOfPolicy:old_policy] > 0) {
                        NSString* err_msg = [_symmetric_keys_controller generateSymmetricKey:old_policy];
                        if (err_msg != nil) {
                            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMVC:unwindToProviderMaster:" message:err_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                            [alert show];
                            
                            return;
                        } else {
                            _location_controller.delegate = self;  // reset CLLocationManager delegate
                        }
                        
                        [self uploadKeyBundle:old_policy consumer:nil];
                    }
                }
                
                // Make sure we have a symmetric key at the new policy.
                if (![_symmetric_keys_controller haveKey:source.desired_policy]) {
                    NSString* err_msg = [_symmetric_keys_controller generateSymmetricKey:source.desired_policy];
                    if (err_msg != nil) {
                        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMasterVC:unwindToProviderMaster:" message:err_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                        [alert show];
                        
                        return;
                    } else {
                        _location_controller.delegate = self;  // reset CLLocationManager delegate
                    }
                }
                
                // Now upload our consumer's new shared key bundle, and send them the updated cloud meta-data.
                [self uploadKeyBundle:source.desired_policy consumer:source.consumer];
                NSLog(@"ProviderMVC:unwindToProviderMaster: XXX TODO(aka) we need to check if consumer is us, if so, we need to call addSelfToProviders: again!");
                [self sendCloudMetaData:source.consumer];
                source.consumer.file_store_sent = true;
                
                // And finally, update this consumer in the master list with the new policy level.
                [source.consumer setPolicy:source.desired_policy];
                NSString* err_msg = [_consumer_list addConsumer:source.consumer];
                if (err_msg != nil) {
                    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMasterVC:unwindToProviderMaster:" message:err_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                    [alert show];
                }
                
                [self.tableView reloadData];
            }
            
            if (source.track_consumer) {
                if (kDebugLevel > 2)
                    NSLog(@"ProviderMVC:unwindToProviderMaster: track consumer requested.");
                
                // Send our consumer over to the ConsumerMaster VC, so they'll be treated as a provider too!
                Principal* new_provider = source.consumer;
                
                // Note, we don't need to set the public key now, we'll retrieve it from the key chain when we need it (since it's already in under the consumer's identity!).  However, we won't have a symmetric key or even a file-store for this consumer until they send us one, so this just adds a Principal on the Consumer MVC for us.
                
                if (kDebugLevel > 0)
                    NSLog(@"ProviderMVC:unwindToProviderMaster: new provider: %@, %@, %@.", new_provider.identity, new_provider.identity_hash, [new_provider.deposit description]);
                
                if (![[self delegate] isKindOfClass:[ConsumerMasterViewController class]])
                    NSLog(@"ProviderMVC:unwindToProviderMaster: ERROR: Delegate not found!");

               [[self delegate] addConsumerToProviders:new_provider];
            }
            
            if (source.send_file_store_info) {
                if (kDebugLevel > 0)
                    NSLog(@"ProviderMVC:unwindToProviderMaster: sending file-store meta-data to %s.", [source.consumer.identity cStringUsingEncoding: [NSString defaultCStringEncoding]]);
                
                [self sendCloudMetaData:source.consumer];
            }
            
            if (source.upload_key_bundle) {
                if (kDebugLevel > 0)
                    NSLog(@"ProviderMVC:unwindToProviderMaster: uploading key-bundle for %s.", [source.consumer.identity cStringUsingEncoding: [NSString defaultCStringEncoding]]);
                
                [self uploadKeyBundle:source.consumer.policy consumer:source.consumer];
            }
        }
    } else if ([sourceViewController isKindOfClass:[AddConsumerCTViewController class]]) {
        if (kDebugLevel > 2)
            NSLog(@"ProviderMVC:unwindToProviderMaster: AddConsumerCTViewController callback.");
        
        AddConsumerCTViewController* source = [segue sourceViewController];
        if (source.consumer != nil) {
            // Add the new consumer to our ConsumerListController.
            if (kDebugLevel > 0)
                NSLog(@"ProviderMVC:unwindToProviderMaster: adding new consumer: %s, public-key: %s.", [source.consumer.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [[source.consumer.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            
            // Make sure our policy is set to NONE.
            [source.consumer setPolicy:[PolicyController precisionLevelName:[NSNumber numberWithInt:0]]];
            
            // Add our new consumer (and update our state files).
            NSString* err_msg = [_consumer_list addConsumer:source.consumer];
            if (err_msg != nil) {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMVC:unwindToProviderMaster:" message:err_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
            } else {
                [self sendCloudMetaData:source.consumer];

                // Remind the provider to set the new consumer's policy!
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"New Consumer Added" message:@"Remember to set policy for the new consumer!" delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
                
                [self.tableView reloadData];  // get the new consumer in our table view
            }
        }
    } else if ([sourceViewController isKindOfClass:[AddConsumerHCCViewController class]]) {
        if (kDebugLevel > 2)
            NSLog(@"ProviderMVC:unwindToProviderMaster: AddConsumerHCCViewController callback.");
        
        AddConsumerHCCViewController* source = [segue sourceViewController];
        if (source.potential_consumer != nil) {
            HCCPotentialPrincipal* potential_principal = source.potential_consumer;
            if ([potential_principal.mode intValue] == HCC_MODE_PROVIDER_DEPOSIT_SENT) {
                Principal* consumer = potential_principal.principal;
                
                // Add the new consumer to our ConsumerListController.
                if (kDebugLevel > 0)
                    NSLog(@"ProviderMVC:unwindToProviderMaster: adding new consumer: %s, public-key: %s.", [consumer.identity cStringUsingEncoding: [NSString defaultCStringEncoding]], [[consumer.getPublicKey base64EncodedString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                
                // Make sure our policy is set to NONE.
                [consumer setPolicy:[PolicyController precisionLevelName:[NSNumber numberWithInt:0]]];
                
                // Add our new consumer (and update our state files).
                NSString* err_msg = [_consumer_list addConsumer:consumer];
                if (err_msg != nil) {
                    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMasterVC:unwindToProviderMaster:" message:err_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                    [alert show];
                } else {
                    // Remind the provider to set the new consumer's policy & send the file-store meta-data out!
                    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"New Consumer Added" message:@"Remember to set policy for the new consumer!" delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                    [alert show];
                    
                    [self.tableView reloadData];  // get the new consumer in our table view
                }
                
                // Finally, remove the potential consumer from our dictionary.
                [_potential_consumers removeObjectForKey:consumer.identity];
            } else {
                // Still working on HCC pairing ...
                if (kDebugLevel > 2)
                    NSLog(@"ProviderMVC:unwindToProviderMaster: potential consumer (%s) current state: %d.", [potential_principal.principal.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [potential_principal.mode intValue]);
            }
        }
    } else if ([sourceViewController isKindOfClass:[AddConsumerViewController class]]) {
        if (kDebugLevel > 2)
            NSLog(@"ProviderMVC:unwindToProviderMaster: AddConsumerViewController callback.");
        
        // If we reached here, the user hit CANCEL in AddConsumerViewController.
    } else {
        NSLog(@"ProviderMVC:unwindToProviderMaster: TODO(aka) Called from unknown ViewController!");
    }
    
    // No need to dismiss the view controller in an unwind segue.
    
    [self configureView];
}

#pragma mark - NSNotification handlers

- (void) updateOurDataState:(NSNotification*)notification {
    if (kDebugLevel > 4)
        NSLog(@"ProviderMVC:updateOurDataState: called.");
    
    if (_our_data == nil) {
        if (kDebugLevel > 3)
            NSLog(@"ProviderMVC:updateOurDataState: _our_data is nil.");
        
        _our_data = [[PersonalDataController alloc] init];
    }
    
    NSLog(@"ProviderMVC:updateOurState: XXXX updating!");
    [_our_data loadState];
}

- (void) sendConsumerVCSelf:(NSNotification*)notification {
    if (kDebugLevel > 4)
        NSLog(@"ProviderMVC:sendConsumerVCSelf: called.");
    
    NSLog(@"ProviderMVC:sendConsumerVCSelf: XXXX updating!");
    
    // See if we're waiting on bucket creation prior to tracking self ...
    if (us_as_consumer != nil) {
        // Build this consumer's (our's) personal bucket.
        NSNumber* nonce = [_our_data.file_store objectForKey:[NSString stringWithCString:kFSKeyNonce encoding:[NSString defaultCStringEncoding]]];
        NSString* bucket = [PersonalDataController hashMD5String:[[NSString alloc] initWithFormat:@"%s%d", [us_as_consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [nonce intValue]]];
        
        // See if we have a web-view link.
        if ([_our_data.drive_wvls objectForKey:bucket] == nil) {
            // Hmm, still don't have the web-view link.  For now, just send a notification ...
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMVC:configureView:" message:@"Web View Link not found yet, we'll check again at next location update." delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
            [alert show];
        } else {
            // First, add ourselves to our consumer list.
            
            // Note, we don't need to set the public key now, we'll retrieve it from the key chain when we need it (since it's already in under our identity!).
            
            if (![_consumer_list containsObject:us_as_consumer]) {
                // We don't have ourselves, yet, so add us (i.e., we didn't load it in via state).
                if (kDebugLevel > 0)
                    NSLog(@"ProviderMVC:unwindToProviderMaster: Adding to our consumer list: %s.", [[us_as_consumer serialize] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                
                [_consumer_list addConsumer:us_as_consumer];
                [self.tableView reloadData];
            }
            
            // Note, the key-bundle upload may be asynchronous (if using Google Drive, e.g.).
            [self uploadKeyBundle:us_as_consumer.policy consumer:us_as_consumer];
            
            // Build our meta-data.
            NSURL* file_store_url = [PersonalDataController genFileStoreURLAuthority:_our_data.file_store];
            NSURL* key_bundle_url = nil;
            NSString* err_msg = [_our_data genFileStoreKeyBundle:us_as_consumer URL:&key_bundle_url];
            if (err_msg != nil) {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMVC:unwindToProviderMaster: TODO(aka) " message:err_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
                return;
            }
            
            // And tell the Consumer MVC to add ourselves to their provider list!
            if (![[self delegate] isKindOfClass:[ConsumerMasterViewController class]])
                NSLog(@"ProviderMVC:unwindToProviderMaster: ERROR: Delegate not found!");
            
            if (kDebugLevel > 0)
                NSLog(@"ProviderMVC:unwindToProviderMaster: Sending consumer file-store URL: %s, key-bundle URL: %s.", [[file_store_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[key_bundle_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            
            [[self delegate] addSelfToProviders:_our_data.identity fileStoreURL:file_store_url keyBundleURL:key_bundle_url];
            
            _track_self_status = true;
            us_as_consumer = nil;  // clean up
        }
    }
}

#pragma mark - NSUserDefaults management

- (NSString*) checkNSUserDefaults {
    if (kDebugLevel > 4)
        NSLog(@"ProviderMVC:checkNSUserDefaults: called.");
    
    NSString* url_string = [[NSUserDefaults standardUserDefaults] objectForKey:@"url"];
    if (url_string == nil)
        return nil;  // nothing in NSUserDefaults for  us
    
    if ([url_string length] == 0) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove URL so no one attempts to processes it again
        return @"ProviderMasterVC:checkNSUserDefaults: url_string is empty!";
    }
    
    NSLog(@"ProviderMVC:checkNSUserDefaults: TOOD(aka) How do we tell if there are multiple NSUserDefaults (i.e., symmetric keys) waiting for us?  While () loop?");
    
    if (kDebugLevel > 1)
        NSLog(@"ProviderMVC:checkNSUserDefaults: received NSUserDefault string: %s.", [url_string cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    NSString* err_msg = nil;
    
    NSURL* url = [[NSURL alloc] initWithString:url_string];
    if (url == nil) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove URL so no one attempts to processes it again
        err_msg = [NSString stringWithFormat:@"ProviderMasterVC:checkNSUserDefaults: unable to convert %@ to a URL!", url_string];
        return err_msg;
    }
    
    // Make sure we have a nine character path (*all* SLS paths are 8 chars + '/').
    NSString* path = [url path];
    if (path == nil || [path length] != (strlen(kPathHCCMsg1) + 1)) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove URL so no one attempts to processes it again
        err_msg = [NSString stringWithFormat:@"ProviderMasterVC:checkNSUserDefaults: URL does not contain a SLS path: %s!", [path cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        return err_msg;
    }
    
    if (kDebugLevel > 0)
        NSLog(@"ProviderMVC:checkNSUserDefaults: from NSDefaults got scheme: %s, fragment: %s, query: %s, path: %s, parameterString: %s.", [url.scheme cStringUsingEncoding:[NSString defaultCStringEncoding]], [url.fragment cStringUsingEncoding:[NSString defaultCStringEncoding]], [url.query cStringUsingEncoding:[NSString defaultCStringEncoding]], [url.path cStringUsingEncoding:[NSString defaultCStringEncoding]], [url.parameterString cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    
    // See if this URL was meant for the consumer MVC ...
    NSString* processor = [path substringWithRange:NSMakeRange(1, 9)];
    if ([processor isEqualToString:[NSString stringWithFormat:@"consumer"]]) {
        if (kDebugLevel > 0)
            NSLog(@"ProviderMVC:checkNSUserDefaults: switching to consumer's tab so NSUserDefauls can be processed: %@.", url_string);
        
        UITabBarController* tab_controller = (UITabBarController*)self.tabBarController;
        if (tab_controller == nil) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove URL so no one attempts to processes it again
            err_msg = [[NSString alloc] initWithFormat:@"ProviderMasterVC:checkNSUserDefaults: unable to switch tab bars."];
            return err_msg;
        }
        
        [tab_controller setSelectedIndex:1];
        
        return [NSString stringWithFormat:@"ProviderMasterVC:checkNSUserDefaults: message destined for consumer mode: %@", url_string];
    }
    
    // Process the URL depending on its path.
    if ([path isEqualToString:[NSString stringWithFormat:@"/%s", kPathHCCMsg1]]) {
        // Process the HCC msg1 query, which is built in the Consumer's HCC VC via the following command:
        /*
         NSString* public_key = [[_our_data getPublicKey] base64EncodedString];
         NSString* path = [[NSString alloc] initWithFormat:@"/%s?%s=%s&%s=%s", kPathHCCMsg1, kQueryKeyID, [_our_data.identity_hash cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyPublicKey, [public_key cStringUsingEncoding:[NSString defaultCStringEncoding]]];
         */
        
        NSString* identity_hash = nil;
        NSData* pub_key = nil;
        
        NSString* query = [url query];
        NSArray* key_value_pairs = [query componentsSeparatedByString:[NSString stringWithFormat:@"%c", kPathDelimiter]];
        for (int i = 0; i < [key_value_pairs count]; ++i) {
            NSString* key_value_pair = [key_value_pairs objectAtIndex:i];
            
            // Note, the base64 representation of the public key can legally have the character '='.  Thus, we need to *only* get the *first* instance of "=" in key_value_pair.
            
            NSRange delimiter = [key_value_pair rangeOfString:@"="];
            NSString* key = [key_value_pair substringWithRange:NSMakeRange(0, delimiter.location)];
            NSString* value = [key_value_pair substringWithRange:NSMakeRange(delimiter.location + 1, ([key_value_pair length] - delimiter.location) - 1)];
            
            if (kDebugLevel > 1)
                NSLog(@"ProviderMVC:checkNSUserDefaults: working with key: %s, value: %s, from pair: %s.", [key cStringUsingEncoding:[NSString defaultCStringEncoding]], [value cStringUsingEncoding:[NSString defaultCStringEncoding]], [key_value_pair cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            
            if ([key caseInsensitiveCompare:[NSString stringWithCString:kQueryKeyID encoding:[NSString defaultCStringEncoding]]] == NSOrderedSame) {
                if (kDebugLevel > 3)
                    NSLog(@"ProviderMVC:checkNSUserDefaults: processing identity hash: %s", [value cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                
                // TODO(aka) Not really necessary, as identity-hash should never have whitespace.
                NSString* de_urlified = [value stringByReplacingPercentEscapesUsingEncoding:[NSString defaultCStringEncoding]];
                
                if (kDebugLevel > 1)
                    NSLog(@"ProviderMVC:checkNSUserDefaults: Setting identity-hash to %s", [de_urlified cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                
                identity_hash = [[NSString alloc] initWithString:de_urlified];
            } else if ([key caseInsensitiveCompare:[NSString stringWithCString:kQueryKeyPubKey encoding:[NSString defaultCStringEncoding]]] == NSOrderedSame) {
                if (kDebugLevel > 3)
                    NSLog(@"ProviderMVC:checkNSUserDefaults: processing base64 pubkey: %s", [value cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                
                pub_key = [NSData dataFromBase64String:value];
            } else {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove URL so no one attempts to processes it again
                err_msg = [NSString stringWithFormat:@"ProviderMasterVC:checkNSUserDefaults: unknown query key: %s.", [key cStringUsingEncoding:[NSString defaultCStringEncoding]]];
                return err_msg;
            }
        }  // for (int i = 0; i < [key_value_pairs count]; ++i) {
        
        // If we didn't get everything, notify the user, than move on with life.
        if (identity_hash == nil || pub_key == nil) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove URL so no one attempts to processes it again
            err_msg = [[NSString alloc] initWithFormat:@"ProviderMasterVC:checkNSUserDefaults: Failed to parse: %s.", [url_string cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            return err_msg;
        }
        
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove the processed URL
        
        // At this point, the user must choose which AddressBook entry to use for this message (to build our _potential_consumers entry).
        err_msg = [self getConsumerIdentity:HCC_MODE_CONSUMER_PUBKEY_SENT];  // XXX TODO(aka) should we return message or bool?  getConsumer handles errors, right?
        if (err_msg != nil)
            return err_msg;
        
        // Add the parsed identity token and public key.  Note, we MUST add the identity token to _potential_consumer, as that's how we index our NSDictionary _potential_consumers, and we need to compare _potential_consumer to _potential_consumers in prepareForSegue:!
        
        _potential_consumer.identity_hash = identity_hash;
        
        // TODO(aka) Note, in-order to get a SecKeyRef of our NSData pubkey, we need to first put it in the keychain (stupid iOS API!), so if we don't add this Principal as a consumer later on, we'll need to eventually delete the key from our keychain!
        
#if 1  // ACCESS_GROUP: TODO(aka) This doesn't work!
        err_msg = [_potential_consumer setPublicKey:pub_key accessGroup:[NSString stringWithFormat:@"%s", kAccessGroupHCC]];
#else
        err_msg = [_potential_consumer setPublicKey:pub_key accessGroup:nil];
#endif
        if (err_msg != nil)
            return err_msg;
        
        // Generate an HCCPotentialPrincipal object using our _potential_consumer and set its HCC status (mode), i.e., show that we are waiting to send challenge over alt channel.
        
        HCCPotentialPrincipal* potential_principal = [[HCCPotentialPrincipal alloc] initWithPrincipal:_potential_consumer];
        potential_principal.mode = [NSNumber numberWithInt:HCC_MODE_PROVIDER_PUBKEY_RECEIVED];
        
        // Save this potential consumer to our local dictionary and save its state.
        [_potential_consumers setObject:potential_principal forKey:_potential_consumer.identity];
        NSString* potential_consumers_filename = [NSString stringWithFormat:@"%s.provider", HCC_PRINCIPALS_STATE_FILENAME];
        [PersonalDataController saveState:potential_consumers_filename dictionary:_potential_consumers];
        
        // Setup next message by segue'ng to AddConsumerHCCVC.
        [self performSegueWithIdentifier:@"ShowAddConsumerHCCViewID" sender:nil];
    } else if ([path isEqualToString:[NSString stringWithFormat:@"/%s", kPathHCCMsg3]]) {
        // Process the HCC msg3 query, which is built in the Consumer's HCC VC via the following command:
        /*
         NSString* path = [[NSString alloc] initWithFormat:@"/%s?%s=%d", kPathHCCMsg3, kQueryKeyResponse, [_potential_provider.response intValue]];
         */
        
        int response = -1;
        
        NSString* query = [url query];
        NSArray* key_value_pairs = [query componentsSeparatedByString:[NSString stringWithFormat:@"%c", kPathDelimiter]];
        for (int i = 0; i < [key_value_pairs count]; ++i) {
            NSString* key_value_pair = [key_value_pairs objectAtIndex:i];
            
            // Note, the base64 representation of the public key can legally have the character '='.  Thus, we need to *only* get the *first* instance of "=" in key_value_pair.
            
            NSRange delimiter = [key_value_pair rangeOfString:@"="];
            NSString* key = [key_value_pair substringWithRange:NSMakeRange(0, delimiter.location)];
            NSString* value = [key_value_pair substringWithRange:NSMakeRange(delimiter.location + 1, ([key_value_pair length] - delimiter.location) - 1)];
            
            if (kDebugLevel > 1)
                NSLog(@"ProviderMVC:checkNSUserDefaults: working with key: %s, value: %s, from pair: %s.", [key cStringUsingEncoding:[NSString defaultCStringEncoding]], [value cStringUsingEncoding:[NSString defaultCStringEncoding]], [key_value_pair cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            
            if ([key caseInsensitiveCompare:[NSString stringWithCString:kQueryKeyResponse encoding:[NSString defaultCStringEncoding]]] == NSOrderedSame) {
                if (kDebugLevel > 3)
                    NSLog(@"ProviderMVC:checkNSUserDefaults: processing response: %s", [value cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                
                response = [value intValue];
            } else {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove URL so no one attempts to processes it again
                err_msg = [NSString stringWithFormat:@"ProviderMasterVC:checkNSUserDefaults: unknown query key: %s.", [key cStringUsingEncoding:[NSString defaultCStringEncoding]]];
                return err_msg;
            }
        }  // for (int i = 0; i < [key_value_pairs count]; ++i) {
        
        // If we didn't get everything, notify the user, than move on with life.
        if (response == -1) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove URL so no one attempts to processes it again
            err_msg = [[NSString alloc] initWithFormat:@"ProviderMasterVC:checkNSUserDefaults: Failed to parse: %s.", [url_string cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            return err_msg;
        }
        
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove the processed URL
        
        // At this point, the user must choose which AddressBook entry to use for this message (to lookup in _potential_consumers).
        err_msg = [self getConsumerIdentity:HCC_MODE_CONSUMER_RESPONSE_SENT];  // XXX TODO(aka) should we return message or bool?  getConsumer handles errors, right?
        if (err_msg != nil)
            return err_msg;
        
        // Get our potential provider from our dictionary and update it.
        HCCPotentialPrincipal* potential_principal = [_potential_consumers objectForKey:_potential_consumer.identity];
        if (potential_principal == nil) {
            err_msg = [[NSString alloc] initWithFormat:@"ProviderMasterVC:checkNSUserDefaults: no entry in _potential_consumers for: %s.", [_potential_consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            return err_msg;
        }
        
        // Check to see if their response matches our challenge.
        if ([potential_principal.our_challenge intValue] != (response - 1)) {
            err_msg = [[NSString alloc] initWithFormat:@"ProviderMasterVC:checkNSUserDefaults: response (%d) from %s does not match our challenge: %d.", response, [_potential_consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [potential_principal.our_challenge intValue]];
            [_potential_consumers removeObjectForKey:_potential_consumer.identity];  // games over; blow away potential consumer
            return err_msg;
        }
        
       potential_principal.mode = [NSNumber numberWithInt:HCC_MODE_PROVIDER_RESPONSE_VETTED];
        
        // Save this potential consumer to our local dictionary and save its state.
        [_potential_consumers setObject:potential_principal forKey:_potential_consumer.identity];  // XXX TODO(aka) Is this needed?
        NSString* potential_consumers_filename = [NSString stringWithFormat:@"%s.provider", HCC_PRINCIPALS_STATE_FILENAME];
        [PersonalDataController saveState:potential_consumers_filename dictionary:_potential_consumers];
        
        // Setup next message by segue'ng to AddConsumerHCCVC.
        [self performSegueWithIdentifier:@"ShowAddConsumerHCCViewID" sender:nil];
    } else if ([path isEqualToString:[NSString stringWithFormat:@"/%s", kPathHCCMsg5]]) {
        // Process the HCC msg5 query, which is built in the HCC VC via the following command:
        /*
         _potential_provider.our_challenge = [NSNumber numberWithInt:(arc4random() % 9999)];  // get a four digit challenge (response will have + 1, so <= 9998)
         [PersonalDataController asymmetricEncryptString:[NSString stringWithFormat:@"%d", [_potential_provider.our_challenge intValue]] publicKeyRef:[provider publicKeyRef] encryptedString:&encrypted_challenge];
         [PersonalDataController asymmetricEncryptString:answer publicKeyRef:[provider publicKeyRef] encryptedString:&encrypted_answer];
         [PersonalDataController asymmetricEncryptString:_potential_provider.our_secret_question publicKeyRef:[provider publicKeyRef] encryptedString:&encrypted_question];
         NSString* path = [[NSString alloc] initWithFormat:@"/%s?%s=%s?%s=%s?%s=%s", kPathHCCMsg5, kQueryKeyChallenge, [encrypted_challenge cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyAnswer, [encrypted_answer cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeySecretQuestion, [encrypted_question cStringUsingEncoding:[NSString defaultCStringEncoding]]];
         */
        
        NSString* challenge = nil;
        NSString* answer = nil;
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
                NSLog(@"ProviderMVC:checkNSUserDefaults: working with key: %s, value: %s, from pair: %s.", [key cStringUsingEncoding:[NSString defaultCStringEncoding]], [value cStringUsingEncoding:[NSString defaultCStringEncoding]], [key_value_pair cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            
            if ([key caseInsensitiveCompare:[NSString stringWithCString:kQueryKeyChallenge encoding:[NSString defaultCStringEncoding]]] == NSOrderedSame) {
                if (kDebugLevel > 3)
                    NSLog(@"ProviderMVC:checkNSUserDefaults: processing challenge: %s", [value cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                
                err_msg = [PersonalDataController asymmetricDecryptString:value privateKeyRef:[_our_data privateKeyRef] string:&challenge];
                if (err_msg != nil) {
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove URL so no one attempts to processes it again
                    return err_msg;
                }
            } else if ([key caseInsensitiveCompare:[NSString stringWithCString:kQueryKeyAnswer encoding:[NSString defaultCStringEncoding]]] == NSOrderedSame) {
                if (kDebugLevel > 3)
                    NSLog(@"ProviderMVC:checkNSUserDefaults: processing base64 answer: %s", [value cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                
                err_msg = [PersonalDataController asymmetricDecryptString:value privateKeyRef:[_our_data privateKeyRef] string:&answer];
                if (err_msg != nil) {
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove URL so no one attempts to processes it again
                    return err_msg;
                }
            } else if ([key caseInsensitiveCompare:[NSString stringWithCString:kQueryKeySecretQuestion encoding:[NSString defaultCStringEncoding]]] == NSOrderedSame) {
                if (kDebugLevel > 3)
                    NSLog(@"ProviderMVC:checkNSUserDefaults: processing base64 secret-question: %s", [value cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                
                err_msg = [PersonalDataController asymmetricDecryptString:value privateKeyRef:[_our_data privateKeyRef] string:&secret_question];
                if (err_msg != nil) {
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove URL so no one attempts to processes it again
                    return err_msg;
                }
            } else {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove URL so no one attempts to processes it again
                err_msg = [NSString stringWithFormat:@"ProviderMasterVC:checkNSUserDefaults: unknown query key: %s.", [key cStringUsingEncoding:[NSString defaultCStringEncoding]]];
                return err_msg;
            }
        }  // for (int i = 0; i < [key_value_pairs count]; ++i) {
        
        // If we didn't get everything, notify the user, than move on with life.
        if (challenge == nil || answer == nil || secret_question == nil) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove URL so no one attempts to processes it again
            err_msg = [[NSString alloc] initWithFormat:@"ProviderMasterVC:checkNSUserDefaults: Failed to parse: %s.", [url_string cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            return err_msg;
        }
        
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove the processed URL
        
        // At this point, the user must choose which AddressBook entry to use for this message (to lookup in _potential_consumers).
        err_msg = [self getConsumerIdentity:HCC_MODE_CONSUMER_CHALLENGE_SENT];  // XXX TODO(aka) should we return message or bool?  getConsumer handles errors, right?
        if (err_msg != nil)
            return err_msg;
        
        HCCPotentialPrincipal* potential_principal = [_potential_consumers objectForKey:_potential_consumer.identity];
        if (potential_principal == nil) {
            err_msg = [[NSString alloc] initWithFormat:@"ProviderMasterVC:checkNSUserDefaults: no entry in _potential_consumers for: %s.", [_potential_consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            return err_msg;
        }
        
        // Update our potential consumer's info.
        NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
        [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
        potential_principal.their_challenge = [NSNumber numberWithInt:[[formatter numberFromString:challenge] intValue] + 1];  // note '+1'
        potential_principal.their_secret_question = secret_question;
        potential_principal.mode = [NSNumber numberWithInt:HCC_MODE_PROVIDER_CHALLENGE_RECEIVED];
        
        // Save this potential consumer to our local dictionary and save its state.
        [_potential_consumers setObject:potential_principal forKey:_potential_consumer.identity];  // XXX TODO(aka) Is this needed?
        NSString* potential_consumers_filename = [NSString stringWithFormat:@"%s.provider", HCC_PRINCIPALS_STATE_FILENAME];
        [PersonalDataController saveState:potential_consumers_filename dictionary:_potential_consumers];
        
        // Finally, see if the received answer is acceptable (in the UIAlert delegate, we'll segue to HCC VC if user answers yes).
        NSString* msg = [[NSString alloc] initWithFormat:@"Does \"%s\" answer \"%s\"?", [answer cStringUsingEncoding:[NSString defaultCStringEncoding]], [potential_principal.our_secret_question cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMasterVC:checkNSUserDefaults:" message:msg delegate:self cancelButtonTitle:[NSString stringWithCString:kAlertButtonCancelPairingMessage encoding:[NSString defaultCStringEncoding]] otherButtonTitles:[NSString stringWithCString:kAlertButtonContinuePairingMessage encoding:[NSString defaultCStringEncoding]], nil];
        [alert show];
    } else if ([path isEqualToString:[NSString stringWithFormat:@"/%s", kPathHCCMsg7]]) {
        // Process the HCC msg7 query, which is built in the HCC VC via the following command:
        /*
         [PersonalDataController asymmetricEncryptString:answer publicKeyRef:[provider publicKeyRef] encryptedString:&our_challenge_encrypted];
         [PersonalDataController asymmetricEncryptString:answer publicKeyRef:[provider publicKeyRef] encryptedString:&their_challenge_encrypted];
         NSString* path = [[NSString alloc] initWithFormat:@"/%s?%s=%s&%s=%s&%s=%s", kPathHCCMsg7, kQueryKeyDeposit, [[PersonalDataController absoluteStringDeposit:_our_data.deposit] cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyOurChallenge, [our_challenge_encrypted cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyTheirChallenge, [their_challenge_encrypted cStringUsingEncoding:[NSString defaultCStringEncoding]]];
         */
        
        NSString* our_challenge = nil;
        NSString* their_challenge = nil;
        
        NSString* query = [url query];
        NSArray* key_value_pairs = [query componentsSeparatedByString:[NSString stringWithFormat:@"%c", kPathDelimiter]];
        for (int i = 0; i < [key_value_pairs count]; ++i) {
            NSString* key_value_pair = [key_value_pairs objectAtIndex:i];
            
            // Note, the base64 representation of the public key can legally have the character '='.  Thus, we need to *only* get the *first* instance of "=" in key_value_pair.
            
            NSRange delimiter = [key_value_pair rangeOfString:@"="];
            NSString* key = [key_value_pair substringWithRange:NSMakeRange(0, delimiter.location)];
            NSString* value = [key_value_pair substringWithRange:NSMakeRange(delimiter.location + 1, ([key_value_pair length] - delimiter.location) - 1)];
            
            if (kDebugLevel > 1)
                NSLog(@"ProviderMVC:checkNSUserDefaults: working with key: %s, value: %s, from pair: %s.", [key cStringUsingEncoding:[NSString defaultCStringEncoding]], [value cStringUsingEncoding:[NSString defaultCStringEncoding]], [key_value_pair cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            
            if ([key caseInsensitiveCompare:[NSString stringWithCString:kQueryKeyDeposit encoding:[NSString defaultCStringEncoding]]] == NSOrderedSame) {
                if (kDebugLevel > 3)
                    NSLog(@"ProviderMVC:checkNSUserDefaults: processing challenge: %s", [value cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                
                // TODO(aka) Not really necessary, as deposit (in string form) should not have whitespace.
                NSString* de_urlified = [value stringByReplacingPercentEscapesUsingEncoding:[NSString defaultCStringEncoding]];
                
                if (kDebugLevel > 1)
                    NSLog(@"ProviderMVC:checkNSUserDefaults: building deposit from: %s", [de_urlified cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                
                _potential_consumer.deposit = [PersonalDataController stringToDeposit:de_urlified];
            } else if ([key caseInsensitiveCompare:[NSString stringWithCString:kQueryKeyOurChallenge encoding:[NSString defaultCStringEncoding]]] == NSOrderedSame) {
                if (kDebugLevel > 3)
                    NSLog(@"ProviderMVC:checkNSUserDefaults: processing base64 our challenge: %s", [value cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                
                err_msg = [PersonalDataController asymmetricDecryptString:value privateKeyRef:[_our_data privateKeyRef] string:&our_challenge];
                if (err_msg != nil) {
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove URL so no one attempts to processes it again
                    return err_msg;
                }
            } else if ([key caseInsensitiveCompare:[NSString stringWithCString:kQueryKeyTheirChallenge encoding:[NSString defaultCStringEncoding]]] == NSOrderedSame) {
                if (kDebugLevel > 3)
                    NSLog(@"ProviderMVC:checkNSUserDefaults: processing base64 their challenge: %s", [value cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                
                err_msg = [PersonalDataController asymmetricDecryptString:value privateKeyRef:[_our_data privateKeyRef] string:&their_challenge];
                if (err_msg != nil) {
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove URL so no one attempts to processes it again
                    return err_msg;
                }
            } else {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove URL so no one attempts to processes it again
                err_msg = [NSString stringWithFormat:@"ProviderMasterVC:checkNSUserDefaults: unknown query key: %s.", [key cStringUsingEncoding:[NSString defaultCStringEncoding]]];
                return err_msg;
            }
        }  // for (int i = 0; i < [key_value_pairs count]; ++i) {
        
        // If we didn't get everything, notify the user, than move on with life.
        if (![PersonalDataController isDepositComplete:_potential_consumer.deposit] || our_challenge == nil || their_challenge == nil) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove URL so no one attempts to processes it again
            err_msg = [[NSString alloc] initWithFormat:@"ProviderMasterVC:checkNSUserDefaults: Failed to parse: %s.", [url_string cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            return err_msg;
        }
        
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove the processed URL
        
        // At this point, the user must choose which AddressBook entry to use for this message (to lookup in _potential_consumers).
        err_msg = [self getConsumerIdentity:HCC_MODE_CONSUMER_DEPOSIT_SENT];  // XXX TODO(aka) should we return message or bool?  getConsumer handles errors, right?
        if (err_msg != nil)
            return err_msg;
        
        HCCPotentialPrincipal* potential_principal = [_potential_consumers objectForKey:_potential_consumer.identity];
        if (potential_principal == nil) {
            err_msg = [[NSString alloc] initWithFormat:@"ProviderMasterVC:checkNSUserDefaults: no entry in _potential_consumers for: %s.", [_potential_consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            return err_msg;
        }
        
        // See if potential consumer does indeed possess the nonces used over the alternate channel.
        NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
        [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
        if ([potential_principal.their_challenge intValue] != [[formatter numberFromString:our_challenge] intValue] ||
            [potential_principal.our_challenge intValue] != [[formatter numberFromString:their_challenge] intValue]) {
            err_msg = [[NSString alloc] initWithFormat:@"ProviderMasterVC:checkNSUserDefaults: %s failed nonce ownership check: %d != %d, or %d != %d.", [_potential_consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [potential_principal.our_challenge intValue], [[formatter numberFromString:their_challenge] intValue], [potential_principal.their_challenge intValue], [[formatter numberFromString:our_challenge] intValue]];
            [_potential_consumers removeObjectForKey:_potential_consumer.identity];  // games over; blow away potential consumer
            return err_msg;
        }
        
        // Update our potential consumer's info.  (Note, deposit dictionary was already set.)
        potential_principal.mode = [NSNumber numberWithInt:HCC_MODE_PROVIDER_DEPOSIT_RECEIVED];
        
        // Save this potential consumer to our local dictionary and save its state.
        [_potential_consumers setObject:potential_principal forKey:_potential_consumer.identity];  // XXX TODO(aka) Is this needed?
        NSString* potential_consumers_filename = [NSString stringWithFormat:@"%s.provider", HCC_PRINCIPALS_STATE_FILENAME];
        [PersonalDataController saveState:potential_consumers_filename dictionary:_potential_consumers];
        
        // Setup last message of HCC by segue'ng to AddConsumerHCCVC.
        [self performSegueWithIdentifier:@"ShowAddConsumerHCCViewID" sender:nil];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"url"];  // remove URL so no one attempts to processes it again
        err_msg = [[NSString alloc] initWithFormat:@"ProviderMasterVC:checkNSUserDefaults: unknown processor: %s, or path: %s.", [processor cStringUsingEncoding:[NSString defaultCStringEncoding]], [path cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        return err_msg;
    }
    
    return nil;
}

#pragma mark - Cloud management

- (void) sendCloudMetaData:(Principal*)sole_consumer {
    if (kDebugLevel > 4)
        NSLog(@"ProviderMVC:sendCloudMetaData:consumer: called: %@.", sole_consumer);
    
    // Loop over each consumer and encrypt & send our file store meta-data; if sole_consumer is set, only for that consumer ...
    for (int i = 0; i < [_consumer_list countOfList]; i++) {
        Principal* consumer = [_consumer_list objectInListAtIndex:i];
        
        // Note, if we specified a consumer as a parameter, only send to them!
        if (sole_consumer != nil) {
            if (![consumer isEqual:sole_consumer]) {
                if (kDebugLevel > 1)
                    NSLog(@"ProviderMVC:sendCloudMetaData: skipping %s due to sole consumer %s.", [consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [sole_consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                continue;
            }
        }
        
#if 0
        // For Profiling:
        NSDate* start = [NSDate date];
#endif
        
        // Build the File-store meta data *path*, which includes; (i) our identity token, (ii) the URL of our file-store (sans the history-log path, i.e., the scheme & authority), (iii) the URL for this consumer's key-bundle (currently, only difference between this and the file-store URL is the path component of the URL, which never changes for this consumer on this file-store!), (iv) a time stamp, and (v) a signature across the preceeding four fields concatenated together.
        
        NSURL* file_store_url = [PersonalDataController genFileStoreURLAuthority:_our_data.file_store];
        NSURL* key_bundle_url = nil;
        NSString* err_msg = [_our_data genFileStoreKeyBundle:consumer URL:&key_bundle_url];
        if (err_msg != nil) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMasterVC:sendCloudMetaData:" message:err_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
            [alert show];
            continue;  // nothing we can do for this consumer
        }
        
        struct timeval now;
        gettimeofday(&now, NULL);
        
        // Generate signature of four tuple.
        NSString* four_tuple = [[NSString alloc] initWithFormat:@"%s%s%s%ld", [_our_data.identity_hash cStringUsingEncoding:[NSString defaultCStringEncoding]], [[file_store_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], [[key_bundle_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], now.tv_sec];
        NSData* hash = [PersonalDataController hashSHA256StringToData:four_tuple];
        
        if (kDebugLevel > 2)
            NSLog(@"ProviderMVC:sendCloudMetaData: four tuple: %@, hash size: %ld.", four_tuple, (unsigned long)[hash length]);
        
        NSString* signature = nil;
        err_msg = [PersonalDataController signHashData:hash privateKeyRef:_our_data.privateKeyRef signedHash:&signature];
        if (err_msg != nil) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMasterVC:sendCloudMetaData:" message:err_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
            [alert show];
            continue;  // nothing we can do for this consumer
        }
        
        if (kDebugLevel > 0)
            NSLog(@"ProviderMVC:sendCloudMetaData: four tuple: %@, signature: %@.", four_tuple, signature);
        
#if 0
        // For Profiling: Find elapsed time and convert to milliseconds, since NSDate start is earlier than now, we negate (-) our modifier in conversion.
        
        double end_ms = [start timeIntervalSinceNow] * -1000.0;
        NSString* msg = [[NSString alloc] initWithFormat:@"ProviderMasterVC:sendCloudMetaData: PROFILING Signature: %fms, PROFILING SMS Sending time: %s.", end_ms, [[[NSDate date] description] cStringUsingEncoding:[NSString defaultCStringEncoding]]];
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
                path = [[NSString alloc] initWithFormat:@"/%s?%s=%s&%s=%s&%s=%s&%s=%ld&%s=%s", kPathFileStore, kQueryKeyID, [_our_data.identity_hash cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyFileStoreURL, [[file_store_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyKeyBundleURL, [[key_bundle_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyTimeStamp, now.tv_sec, kQueryKeySignature, [signature cStringUsingEncoding:[NSString defaultCStringEncoding]]];
#else
                xxx;  // XXX TODO(aka) Multi-part messages have not been updated with new file-store meta-data!
                if (j == 0)
                    path = [[NSString alloc] initWithFormat:@"/?%s=%s&%s=%s", kQueryKeyEncryptedKey, [encrypted_key_b64 cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyIdentity, [_our_data.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
                else if (j == 1)
                    path = [[NSString alloc] initWithFormat:@"/?%s=%s&%s=%s",  kQueryKeyFileStoreURL, [[file_store_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyIdentity, [_our_data.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
#endif
                NSURL* sls_url = [[NSURL alloc] initWithScheme:scheme host:host path:path];
                
                NSString* phone_number = [PersonalDataController getDepositPhoneNumber:consumer.deposit];
                
                if (kDebugLevel > 0)
                    NSLog(@"ProviderMVC:sendCloudMetaData: sending phone number:%s SMS message[%d]: %s.", [phone_number cStringUsingEncoding:[NSString defaultCStringEncoding]], j, [[sls_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                
                // Send our custom URI as the body of the SMS message (so the consumer can install it when reading the SMS message).
                
                MFMessageComposeViewController* msg_controller =
                [[MFMessageComposeViewController alloc] init];
                if([MFMessageComposeViewController canSendText]) {
                    msg_controller.body = [sls_url absoluteString];
                    msg_controller.recipients = [NSArray arrayWithObjects:phone_number, nil];
                    msg_controller.messageComposeDelegate = self;
                    [self presentViewController:msg_controller animated:YES completion:nil];
                } else {
                    NSLog(@"ProviderMVC:sendCloudMetaData:policy: ERROR: TODO(aka) hmm, we can't send SMS messages!");
                    break;  // leave inner for loop
                }
                
                cnt++;
            }  // for (int j = 0; j < num_messages; ++j) {
        } else if ([PersonalDataController isDepositTypeEMail:consumer.deposit]) {
            // Build our app's custom URI to send to our consumer.
            NSString* scheme = [[NSString alloc] initWithFormat:@"%s", kSchemeSLS];
            NSString* host = @"";  // app processing doesn't use host
            NSString* path = [[NSString alloc] initWithFormat:@"/?%s=%s&%s=%s&%s=%s&%s=%ld&%s=%s", kQueryKeyID, [_our_data.identity_hash cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyFileStoreURL, [[file_store_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyKeyBundleURL, [[key_bundle_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]], kQueryKeyTimeStamp, now.tv_sec, kQueryKeySignature, [signature cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            NSURL* sls_url = [[NSURL alloc] initWithScheme:scheme host:host path:path];
            
            NSString* address = [PersonalDataController getDepositAddress:consumer.deposit];
            
            if (kDebugLevel > 0)
                NSLog(@"ProviderMVC:sendCloudMetaData: sending address:%s e-mail message: %s.", [address cStringUsingEncoding:[NSString defaultCStringEncoding]], [[sls_url absoluteString] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            
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
                NSLog(@"ProviderMVC:sendCloudMetaData: ERROR: TODO(aka) hmm, we can't send SMS messages!");
                break;  // leave inner for loop
            }
        } else {
            NSLog(@"ProviderMVC:sendCloudMetaData: WARN: TODO(aka) deposit type: %s, not supported yet!", [[PersonalDataController getDepositType:consumer.deposit] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        }
    }
}
                                                                         
#pragma mark - Cloud operations

// Routine to upload the key-bundle to the consumer's bucket.  TODO(aka) The sole_consumer must be in _consumer_list, which feels wrong.

- (void) uploadKeyBundle:(NSString*)policy consumer:(Principal*)sole_consumer {
    if (kDebugLevel > 4)
        NSLog(@"ProviderMVC:uploadKeyBundle:consumer: called: %@.", policy);
    
    NSString* err_msg = nil;
    
    // Get the symmetric key for this policy level.
    NSData* symmetric_key = [_symmetric_keys_controller objectForKey:policy];
    if (symmetric_key == nil) {
        if (kDebugLevel > 0)
            NSLog(@"No symmetric key for policy: %s.", [policy cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        
        [_symmetric_keys_controller generateSymmetricKey:policy];
        _location_controller.delegate = self;  // reset CLLocationManager delegate

        symmetric_key = [_symmetric_keys_controller objectForKey:policy];
    }
    
    // Loop over each consumer and generate & upload their key-bundle, *if* policy levels match ...
    for (int i = 0; i < [_consumer_list countOfList]; i++) {
        Principal* consumer = [_consumer_list objectInListAtIndex:i];
        
        if (sole_consumer != nil) {
            if (![consumer isEqual:sole_consumer]) {
                if (kDebugLevel > 0)
                    NSLog(@"ProviderMVC:uploadKeyBundle: skipping %s due to sole consumer %s.", [consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [sole_consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]);
                continue;
            }
        }
        
        if (![policy isEqualToString:consumer.policy]) {
            if (kDebugLevel > 1)
                NSLog(@"ProviderMVC:uploadKeyBundle: skipping %s due to consumer's policy %@ not matching routines: %@.", [consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], consumer.policy, policy);
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
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMasterVC:uploadKeyBundle:" message:err_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
            [alert show];
            continue;  // nothing we can do for this consumer
        }
        NSString* encrypted_key_b64 = [encrypted_key base64EncodedString];
        
        // Get the history-log path, so consumer can append it to the file-store URL they already have (via cloud meta-data).
        NSString* history_log_path = nil;
        err_msg = [_our_data genFileStoreHistoryLog:policy path:&history_log_path];
        if (err_msg != nil) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMasterVC:uploadKeyBundle:" message:err_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
            [alert show];
            continue;  // nothing we can do for this consumer
        }
        
        // Build our key-bundle for this Consumer.
        KeyBundleController* key_bundle = [[KeyBundleController alloc] init];
        err_msg = [key_bundle build:encrypted_key_b64 privateKeyRef:[_our_data privateKeyRef] historyLogPath:history_log_path];
        if (err_msg != nil) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMasterVC:uploadKeyBundle:" message:err_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
            [alert show];
            continue;  // nothing we can do for this consumer
        }
        
        // Upload the key-bundle to our file-store.

        // Build any meta-data we need to upload the key-bundle via our file-store's API.
        NSString* filename = [[NSString alloc] initWithFormat:@"%s.%s", [consumer.identity_hash cStringUsingEncoding:[NSString defaultCStringEncoding]], kFSKeyBundleExt];
        
        // Build this consumer's personal bucket.
        NSNumber* nonce = [_our_data.file_store objectForKey:[NSString stringWithCString:kFSKeyNonce encoding:[NSString defaultCStringEncoding]]];
        NSString* bucket = [PersonalDataController hashMD5String:[[NSString alloc] initWithFormat:@"%s%d", [consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [nonce intValue]]];
        
        if (kDebugLevel > 0)
            NSLog(@"ProviderMVC:uploadKeyBundle: uploading \'%s\' key-bundle to %s: %s.", [consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [bucket cStringUsingEncoding:[NSString defaultCStringEncoding]], [encrypted_key_b64 cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        
        // Depending on the file-store type, add any additional path elements and upload the data.
        if ([PersonalDataController isFileStoreServiceAmazonS3:_our_data.file_store]) {
            // S3 simply uses the bucket and filename, can is handled within the PersonalDataController.
            err_msg = [_our_data amazonS3Upload:[key_bundle serialize] bucket:bucket filename:filename];
        } else if ([PersonalDataController isFileStoreServiceGoogleDrive:_our_data.file_store]) {
             // Drive stores stuff in buckets under the SLS the root folder, which is managed in googleDriveUpload: with _drive_ids & _drive_wvls.
            NSString* dict_key = filename;  // key-bundle filenames are unique
            err_msg = [self googleDriveUpload:[key_bundle serialize] bucket:bucket filename:filename idKey:dict_key];
            
            if (kDebugLevel > 0) {
                if ([_our_data.drive_wvls objectForKey:bucket] != nil)
                    NSLog(@"ProviderMVC:uploadKeyBundle: DEBUG: Use %@ to fetch key-bundle!", [_our_data.drive_wvls objectForKey:bucket]);
                else
                    NSLog(@"ProviderMVC:uploadKeyBundle: DEBUG: WVL to fetch key-bundle not yet installed for %@.", bucket);
            }
        } else {
            err_msg = [[NSString alloc] initWithFormat:@"Unknown service: %s", [[_our_data.file_store objectForKey:[NSString stringWithCString:kFSKeyService encoding:[NSString defaultCStringEncoding]]] cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            NSLog(@"ProviderMVC:uploadKeyBundle: %s.", [err_msg cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        }
        if (err_msg != nil) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMasterVC:uploadKeyBundle:" message:err_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
            [alert show];
            continue;  // nothing we can do for this consumer
        }
        
#if 0
        // For Profiling: Find elapsed time and convert to milliseconds, since NSDate start is earlier than now, we negate (-) our modifier in conversion.
        
        double end_ms = [start timeIntervalSinceNow] * -1000.0;
        NSString* msg = [[NSString alloc] initWithFormat:@"ProviderMasterVC:uploadKeyBundle: PROFILING Signature: %fms, PROFILING SMS Sending time: %s.", end_ms, [[[NSDate date] description] cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        UILocalNotification* notice = [[UILocalNotification alloc] init];
        notice.alertBody = msg;
        notice.alertAction = @"Show";
        [[UIApplication sharedApplication] presentLocalNotificationNow:notice];
#endif
    }  // for (int i = 0; i < [_consumer_list countOfList]; i++) {
    
    if (kDebugLevel > 4)
        NSLog(@"ProviderMVC:uploadKeyBundle: exiting.");
}

- (NSString*) uploadHistoryLog:(NSArray*)history_log policy:(NSString*)policy {
    if (kDebugLevel > 4)
        NSLog(@"ProviderMVC:uploadHistoryLog: called.");
    
    // Note, we can return an error message here, as this routine is called by CLLocation's delegate functions.
    
    if (kDebugLevel > 2)
        NSLog(@"ProviderMVC:uploadHistoryLog: operating over key: %@.", policy);
    
    NSString* err_msg = nil;
    
    // Make sure we are authorized to use our file-store.  Technically, this is done in configureView, but I guess it's possible that the locationManager delegate callback could be called prior to this routine ...
    
    if (![_our_data isFileStoreAuthorized]) {
        // Try once to get authorized.  Note, since some SDKs require a view controller, we need to check each separately here ...
        if ([PersonalDataController isFileStoreServiceAmazonS3:_our_data.file_store]) {
            err_msg = [_our_data amazonS3Auth:[PersonalDataController getFileStoreAccessKey:_our_data.file_store] secretKey:[PersonalDataController getFileStoreSecretKey:_our_data.file_store]];
        } else if ([PersonalDataController isFileStoreServiceGoogleDrive:_our_data.file_store]) {
            err_msg = [_our_data googleDriveKeychainAuth:[PersonalDataController getFileStoreKeychainTag:_our_data.file_store] clientID:[PersonalDataController getFileStoreClientID:_our_data.file_store] clientSecret:[PersonalDataController getFileStoreClientSecret:_our_data.file_store]];
            if (err_msg == nil && ![_our_data googleDriveIsAuthorized]) {
                // Prompt the user for the credentials.
                GTMOAuth2ViewControllerTouch* auth_controller = [[GTMOAuth2ViewControllerTouch alloc] initWithScope:@"https://www.googleapis.com/auth/drive.file" clientID:[PersonalDataController getFileStoreClientID:_our_data.file_store] clientSecret:[PersonalDataController getFileStoreClientSecret:_our_data.file_store] keychainItemName:[PersonalDataController getFileStoreKeychainTag:_our_data.file_store] delegate:self finishedSelector:@selector(viewController:finishedWithAuth:error:)];
                
                [self presentViewController:auth_controller animated:YES completion:nil];
            }
        } else {
            err_msg = [[NSString alloc] initWithFormat:@"Unknown file-store service: %s.", [[PersonalDataController getFileStoreService:_our_data.file_store] cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        }
        
        if (err_msg != nil)
            return err_msg;
        
        if (![_our_data isFileStoreAuthorized]) {
            err_msg = [[NSString alloc] initWithFormat:@"Not authorized for file-store service: %s.", [[PersonalDataController getFileStoreService:_our_data.file_store] cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            return err_msg;
        }
    }
    
    // For this policy (i.e., precision), we want to serialize the history log, encrypt if with the associated symmetric key, base64 it, and then upload it to the appropriate directory.  Note, each individual serialized LocationBundleController within each history log should already have a timestamp and signature.
    
    if (kDebugLevel > 0)
        NSLog(@"ProviderMVC:uploadHistoryLog: key controller size: %lu, checking policy %@.", (unsigned long)[_symmetric_keys_controller count], policy);
    
    // Get the symmetric key for this policy level.
    NSData* symmetric_key = [_symmetric_keys_controller objectForKey:policy];
    if (symmetric_key == nil) {
        NSLog(@"ProviderMVC:uploadHistoryLog: XXX objectForKey really did fail!");
        
        err_msg = [NSString stringWithFormat:@"ProviderMVC:uploadHistoryLog: No symmetric key for policy: %s.", [policy cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        return err_msg;
    }
    
    // Serialize the current (serialized) LocationBundleControllers within the history log and convert it to an NSData object ...
#if 1
    NSString* serialized_history_log_str = [[NSString alloc] init];
    for (int i = 0; i < [history_log count]; ++i) {
        serialized_history_log_str = [serialized_history_log_str stringByAppendingFormat:@"%s", [[history_log objectAtIndex:i] cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        if ((i + 1) < (int)[history_log count]) {
            serialized_history_log_str = [serialized_history_log_str stringByAppendingFormat:@"%c", kArraySerializerDelimiter];
        }
    }
    if (kDebugLevel > 3)
        NSLog(@"ProviderMVC:uploadHistoryLog: encrypting %s using key at policy %@.", [serialized_history_log_str cStringUsingEncoding:[NSString defaultCStringEncoding]], policy);
    
    NSData* serialized_history_log = [serialized_history_log_str dataUsingEncoding:[NSString defaultCStringEncoding]];
#else  // XXX Deprecated!
    NSLog(@"ProviderMVC:uploadHistoryLog: TODO(aka) We need to develop an O/S agnosticframing/encoding scheme for the location and course data!");
    
    // For simplicity, we are going to serialize the NSArray of [LocationBundleController serialize] objects (as they conform to NSCoding).
    NSData* serialized_history_log = [NSKeyedArchiver archivedDataWithRootObject:history_log];
#endif
    
    if (kDebugLevel > 2)
        NSLog(@"ProviderMVC:uploadHistoryLog: after serialization, history log is %lub.", (unsigned long)[serialized_history_log length]);
    
    // ... then encrypt & base64 the NSData.
    NSData* encrypted_data = nil;
    err_msg = [PersonalDataController symmetricEncryptData:serialized_history_log symmetricKey:symmetric_key encryptedData:&encrypted_data];
    if (err_msg != nil)
        return err_msg;
    NSString* encrypted_data_b64 = [encrypted_data base64EncodedString];
    
#if 0
    // For Profiling:
    NSDate* start = [NSDate date];
#endif
    
    // Build any meta-data we need to upload the history-log via our file-store's API.
    NSString* filename = [NSString stringWithFormat:@"%s", kFSHistoryLogFile];
    
    // Build this policy's personal bucket.
    NSNumber* nonce = [_our_data.file_store objectForKey:[NSString stringWithCString:kFSKeyNonce encoding:[NSString defaultCStringEncoding]]];
    NSString* bucket = [PersonalDataController hashMD5String:[[NSString alloc] initWithFormat:@"%s%s%d", [_our_data.identity cStringUsingEncoding:[NSString defaultCStringEncoding]], [policy cStringUsingEncoding:[NSString defaultCStringEncoding]], [nonce intValue]]];
    
    if (kDebugLevel > 2)
        NSLog(@"ProviderMVC:uploadHistoryLog: uploading \'%s\' history-log to %s: %s.", [policy cStringUsingEncoding:[NSString defaultCStringEncoding]], [bucket cStringUsingEncoding:[NSString defaultCStringEncoding]], [encrypted_data_b64 cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    // Export the encypted location data to our file store.
    if ([PersonalDataController isFileStoreServiceAmazonS3:_our_data.file_store]) {
        // S3 simply uses the bucket and filename.
        err_msg = [_our_data amazonS3Upload:encrypted_data_b64 bucket:bucket filename:filename];
    } else if ([PersonalDataController isFileStoreServiceGoogleDrive:_our_data.file_store]) {
        // Drive stores stuff in buckets under the SLS the root folder, which is managed in googleDriveUpload: with _drive_ids & _drive_wvls.
        NSString* dict_key = [NSString stringWithFormat:@"%s-%s", [policy cStringUsingEncoding:[NSString defaultCStringEncoding]], [filename cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        err_msg = [self googleDriveUpload:encrypted_data_b64 bucket:bucket filename:filename idKey:dict_key];
        
        if (kDebugLevel > 0) {
            if ([_our_data.drive_wvls objectForKey:bucket] != nil)
                NSLog(@"ProviderMVC:uploadHistoryLog: DEBUG: Use %@ to fetch history-log!", [_our_data.drive_wvls objectForKey:bucket]);
            else {
                NSString* buf = [[NSString alloc] init];
                for (id key in _our_data.drive_wvls) {
                    NSString* wvl = [_our_data.drive_wvls objectForKey:key];
                    buf = [buf stringByAppendingFormat:@"%@:%@ ", key, wvl];
                }
                NSLog(@"ProviderMVC:uploadHistoryLog: DEBUG: WVL to fetch history-log not yet installed for %@, current dict: %@.", bucket, buf);
            }
        }
    } else {
        err_msg = [[NSString alloc] initWithFormat:@"Unknown service: %s", [[_our_data.file_store objectForKey:[NSString stringWithCString:kFSKeyService encoding:[NSString defaultCStringEncoding]]] cStringUsingEncoding:[NSString defaultCStringEncoding]]];
    }
    if (err_msg != nil)
        return err_msg;
    
#if 0
    // For Debugging: Find elapsed time and convert to milliseconds, since NSDate start is earlier than now, we negate (-) our modifier in conversion.
    
    double end_ms = [start timeIntervalSinceNow] * -1000.0;
    NSString* msg = [[NSString alloc] initWithFormat:@"ProviderMasterVC:uploadHistoryLog: PROFILING upload and encryption: %fms.", end_ms];
    UILocalNotification* notice = [[UILocalNotification alloc] init];
    notice.alertBody = msg;
    notice.alertAction = @"Show";
    [[UIApplication sharedApplication] presentLocalNotificationNow:notice];
#endif
    
    return nil;
}

// We keep a set of the GoogleDrive file-store operations as instance methods of the ProviderMVC in order to better handle the asynchronous behavior of Google's SDK (i.e., we want to execute configureView when done).

- (NSString*) googleDriveUpload:(NSString*)data bucket:(NSString*)bucket filename:(NSString*)filename idKey:(NSString*)id_key {
    if (kDebugLevel > 4)
        NSLog(@"ProviderMVC:googleDriveUpload:: called.");
    
    NSString* err_msg = nil;
    
    // See if the root "SLS" folder exists in Drive.
    NSString* sls_folder_id = [_our_data.drive_ids objectForKey:[NSString stringWithFormat:@"%s", kFSRootFolderName]];
    if (sls_folder_id == nil || [sls_folder_id length] == 0) {
        err_msg = [[NSString alloc] initWithFormat:@"%s's root folder: %s, does not exist, check file-store in Config", [[PersonalDataController getFileStoreService:_our_data.file_store] cStringUsingEncoding:[NSString defaultCStringEncoding]], kFSRootFolderName];
        return err_msg;  // user will have to address the problem in FileStoreDataView
    }
    
    // Next, make sure the bucket folder exists.
    NSString* bucket_id = [_our_data.drive_ids objectForKey:bucket];
    if (bucket_id == nil || [bucket_id length] == 0) {
        // Try to fetch the bucket folder ID (and create it, if necessary).
        [self googleDriveQueryFolder:bucket rootID:sls_folder_id];
        
        // Record that we're attempting to fetch/create the bucket.
        err_msg = [[NSString alloc] initWithFormat:@"Google Drive upload skipped: %s/%s does not exist, creating ...", kFSRootFolderName, [bucket cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        return err_msg;  // nothing more we can do
    } else {
        // Make sure we have the *public* webviewlink.
        if ([_our_data.drive_wvls objectForKey:bucket] == nil) {
            [self googleDriveQueryFileId:bucket_id];
            
            // Record that we're attempting to fetch the bucket's public URL.
            err_msg = [[NSString alloc] initWithFormat:@"Google Drive upload skipped: no web view link for %s, requesting ...", [bucket cStringUsingEncoding:[NSString defaultCStringEncoding]]];
            return err_msg;  // nothing more we can do
        }
    }
    
    if (kDebugLevel > 3)
        NSLog(@"ProviderMVC:googleDriveUpload: Using bucket id: %@.", bucket_id);
    
    // And finally, see if the file already exists.
    NSString* file_id = [_our_data.drive_ids objectForKey:id_key];
    if (file_id == nil) {
        // Upload the file, as it doesn't exist (yet).
        GTLDriveParentReference* parent = [GTLDriveParentReference object];
        parent.identifier = bucket_id;
        
        GTLDriveFile* tmp_file = [GTLDriveFile object];
        tmp_file.title = filename;
        tmp_file.parents = @[parent];
        NSData* data_as_data = [data dataUsingEncoding:NSUTF8StringEncoding];
        
        GTLUploadParameters* parameters = [GTLUploadParameters uploadParametersWithData:data_as_data MIMEType:@"application/octet-stream"];
        GTLQueryDrive* upload_query = [GTLQueryDrive queryForFilesInsertWithObject:tmp_file uploadParameters:parameters];
        
        UIAlertView* progress_alert = [[UIAlertView alloc] initWithTitle:@"Uploading Data to Drive" message:@"Please wait ..." delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
        [progress_alert show];
        UIActivityIndicatorView* activity_view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        activity_view.center = CGPointMake(progress_alert.bounds.size.width / 2, progress_alert.bounds.size.height - 45);
        [progress_alert addSubview:activity_view];
        [activity_view startAnimating];
        
        if (kDebugLevel > 1)
            NSLog(@"ProviderMVC:googleDriveUpload: Attempting upload query of %@ (id: %@, key: %@), in %@.", filename, file_id, id_key, bucket);
        
        [_our_data.drive executeQuery:upload_query completionHandler:^(GTLServiceTicket* ticket, GTLDriveFile* updated_file, NSError* gtl_err) {
            [progress_alert dismissWithClickedButtonIndex:0 animated:YES];
            if (gtl_err != nil) {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMVC:googleDriveUpload:" message:gtl_err.localizedDescription delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
                
                [self configureView];
            } else {
                [_our_data.drive_ids setObject:updated_file.identifier forKey:id_key];
                [PersonalDataController saveState:[NSString stringWithFormat:@"%s", kGDriveIDsFilename] dictionary:_our_data.drive_ids];

#if 0 // XXX Not needed for files, right?
                // See if it's public.
                if ([updated_file.userPermission.role isEqual:[NSString stringWithFormat:@"reader"]] && [updated_file.userPermission.type isEqual:[NSString stringWithFormat:@"anyone"]]) {
                    
                    [self configureView];  // all done
                } else {
                    [self googleDriveUpdateFolderPermission:updated_file];  // make it public
                }
#endif
           }
        }];
    } else {
        // File already exists, so we need to update it.
        GTLDriveParentReference* parent = [GTLDriveParentReference object];
        parent.identifier = bucket_id;
        
        GTLDriveFile* tmp_file = [GTLDriveFile object];
        tmp_file.title = filename;
        tmp_file.parents = @[parent];
        NSData* data_as_data = [data dataUsingEncoding:NSUTF8StringEncoding];
        
        GTLUploadParameters* parameters = [GTLUploadParameters uploadParametersWithData:data_as_data MIMEType:@"application/octet-stream"];
        GTLQueryDrive* update_query = [GTLQueryDrive queryForFilesUpdateWithObject:tmp_file fileId:file_id uploadParameters:parameters];
        
        UIAlertView* progress_alert = [[UIAlertView alloc] initWithTitle:@"Uploading Data to Drive" message:@"Please wait ..." delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
        [progress_alert show];
        UIActivityIndicatorView* activity_view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        activity_view.center = CGPointMake(progress_alert.bounds.size.width / 2, progress_alert.bounds.size.height - 45);
        [progress_alert addSubview:activity_view];
        [activity_view startAnimating];
        
        if (kDebugLevel > 0)
            NSLog(@"ProviderMVC:googleDriveUpload: Attempting update query of %@ (id:%@, key:%@, wvl:%@), in %@.", filename, file_id, id_key, [_our_data.drive_wvls objectForKey:bucket], bucket);
        
        [_our_data.drive executeQuery:update_query completionHandler:^(GTLServiceTicket* ticket, GTLDriveFile* updated_file, NSError* gtl_err) {
            [progress_alert dismissWithClickedButtonIndex:0 animated:YES];
            if (gtl_err != nil) {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMVC:googleDriveUpload:" message:gtl_err.localizedDescription delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                [alert show];
                
                [self configureView];
            } else {
                if (![updated_file.identifier isEqual:[_our_data.drive_ids objectForKey:id_key]]) {
                    [_our_data.drive_ids setObject:updated_file.identifier forKey:id_key];
                    [PersonalDataController saveState:[NSString stringWithFormat:@"%s", kGDriveIDsFilename] dictionary:_our_data.drive_ids];
                }
                
#if 0 // XXX Not needed, right?
                // See if it's public.
                if ([updated_file.userPermission.role isEqual:[NSString stringWithFormat:@"reader"]] && [updated_file.userPermission.type isEqual:[NSString stringWithFormat:@"anyone"]]) {
                    
                    [self configureView];  // all done
                } else {
                    [self googleDriveUpdateFolderPermission:updated_file];  // make it public
                }
#endif
            }
        }];
    }
    
    return nil;
}

- (void) googleDriveQueryFolder:(NSString*)folder rootID:(NSString*)root_id {
    if (kDebugLevel > 4)
        NSLog(@"ProviderMVC:googleDriveQueryFolder: called.");
    
    // Query Drive for the specified folder (within the root "SLS" folder).
    GTLQueryDrive* search_query = [GTLQueryDrive queryForFilesList];
    search_query.q = [NSString stringWithFormat:@"'%@' in parents", root_id];
    
    UIAlertView* progress_alert = [[UIAlertView alloc] initWithTitle:@"Querying Google Drive" message:@"Please wait ..." delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    [progress_alert show];
    UIActivityIndicatorView* activity_view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    activity_view.center = CGPointMake(progress_alert.bounds.size.width / 2, progress_alert.bounds.size.height - 45);
    [progress_alert addSubview:activity_view];
    [activity_view startAnimating];
    
    if (kDebugLevel > 1)
        NSLog(@"ProviderMVC:googleDriveQueryFolder: Attempting folder (%@) search query in parent id: %@.", folder, root_id);
    
    [_our_data.drive executeQuery:search_query completionHandler:^(GTLServiceTicket* ticket, GTLDriveFileList* files, NSError* gtl_err) {
        [progress_alert dismissWithClickedButtonIndex:0 animated:YES];
        if (gtl_err != nil) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMVC:googleDriveQueryFolder:" message:gtl_err.localizedDescription delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
            [alert show];
            
            [self configureView];
        } else {
            BOOL found = false;
            for (id object in files.items) {
                GTLDriveFile* file = (GTLDriveFile*)object;
                if ([file.title isEqual:folder]) {
                    if (kDebugLevel > 2) {
                        NSString* msg = [NSString stringWithFormat:@"DEBUG: Found file: %@, id: %@.", file.title, file.identifier];
                        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMVC:googleDriveQueryFolder:" message:msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                        [alert show];
                    }
                    
                    [_our_data.drive_ids setObject:file.identifier forKey:folder];
                    [PersonalDataController saveState:[NSString stringWithFormat:@"%s", kGDriveIDsFilename] dictionary:_our_data.drive_ids];
                    found = true;
                    
                    // See if it's public.
                    if (file.webViewLink != nil) {
                        [_our_data.drive_wvls setObject:file.webViewLink forKey:folder];
                        [PersonalDataController saveState:[NSString stringWithFormat:@"%s", kGDriveWVLsFilename] dictionary:_our_data.drive_wvls];
                        
                        if (kDebugLevel > 2) {
                            NSString* msg = [NSString stringWithFormat:@"DEBUG: Added %@ into driveWVLs using key: %@", file.webViewLink, folder];
                            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMasterVC:googleDriveQueryFolder:" message:msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                            [alert show];
                        }
                        
                        [self configureView];  // all done
                    } else {
                        [self googleDriveUpdateFolderPermission:file];  // make it public (note, can this cause infinite recusion?)
                    }
                }
            }
            if (!found) {
                // Didn't find the file.
                [_our_data.drive_ids removeObjectForKey:folder];  // just in-case
                
                if (kDebugLevel > 2) {
                    NSString* msg = [NSString stringWithFormat:@"DEBUG: Issuing create for %@", folder];
                    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMVC:googleDriveQueryFolder:" message:msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                    [alert show];
                }
                
                // Create it.
                [self googleDriveInsertFolder:folder rootID:root_id];
            }
        }
    }];
}

- (void) googleDriveInsertFolder:(NSString*)folder rootID:(NSString*)root_id {
    if (kDebugLevel > 4)
        NSLog(@"ProviderMVC:googleDriveInsertFolder: called.");
    
    // Create a folder within a folder (the root "SLS" folder) in Drive.
    GTLDriveParentReference* parent = [GTLDriveParentReference object];
    parent.identifier = root_id;
    
    GTLDriveFile* tmp_folder = [GTLDriveFile object];
    tmp_folder.title = folder;
    tmp_folder.mimeType = @"application/vnd.google-apps.folder";
    tmp_folder.parents = @[parent];
    
#if 0  // XXX Doesn't seem to work
    // Make sure the folder is a public folder.
    GTLDrivePermission* permissions = [GTLDrivePermission object];
    permissions.role = @"reader";
    permissions.type = @"anyone";
    permissions.value = @"";
    sls_folder.userPermission = permissions;
#endif
    
    GTLQueryDrive* insert_query = [GTLQueryDrive queryForFilesInsertWithObject:tmp_folder uploadParameters:nil];
    
    UIAlertView* progress_alert = [[UIAlertView alloc] initWithTitle:@"Creating Folder in Google Drive" message:@"Please wait ..." delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    [progress_alert show];
    UIActivityIndicatorView* activity_view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    activity_view.center = CGPointMake(progress_alert.bounds.size.width / 2, progress_alert.bounds.size.height - 45);
    [progress_alert addSubview:activity_view];
    [activity_view startAnimating];
    
    if (kDebugLevel > 1)
        NSLog(@"ProviderMVC:googleDriveInsertFolder: Attempting insert query of %@ into %@.", folder, root_id);
    
    [_our_data.drive executeQuery:insert_query completionHandler:^(GTLServiceTicket* ticket, GTLDriveFile* updated_file, NSError* gtl_err) {
        [progress_alert dismissWithClickedButtonIndex:0 animated:YES];
        if (gtl_err != nil) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMasterVC:googleDriveInsertFolder:" message:gtl_err.localizedDescription delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
            [alert show];
            
            [self configureView];
        } else {
            [_our_data.drive_ids setObject:updated_file.identifier forKey:folder];
            [PersonalDataController saveState:[NSString stringWithFormat:@"%s", kGDriveIDsFilename] dictionary:_our_data.drive_ids];
            
            // See if it's public.
            if (updated_file.webViewLink != nil) {
                [_our_data.drive_wvls setObject:updated_file.webViewLink forKey:folder];
                [PersonalDataController saveState:[NSString stringWithFormat:@"%s", kGDriveWVLsFilename] dictionary:_our_data.drive_wvls];
                
                if (kDebugLevel > 1) {
                    NSString* msg = [NSString stringWithFormat:@"DEBUG: Added %@ into driveWVLs using key: %@", updated_file.webViewLink, folder];
                    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMasterVC:googleDriveInsertFolder:" message:msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                    [alert show];
                }
                
                [self configureView];  // all done
            } else {
                [self googleDriveUpdateFolderPermission:updated_file];  // make it public (note, can this cause infinite recusion with Query?)
            }
        }
    }];
}

- (void) googleDriveQueryFileId:(NSString*)file_id {
    if (kDebugLevel > 4)
        NSLog(@"ProviderMVC:googleDriveQueryFileId: called.");
    
    GTLQueryDrive* search_query = [GTLQueryDrive queryForFilesGetWithFileId:file_id];
    
    UIAlertView* progress_alert = [[UIAlertView alloc] initWithTitle:@"Querying Google Drive" message:@"Please wait ..." delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    [progress_alert show];
    UIActivityIndicatorView* activity_view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    activity_view.center = CGPointMake(progress_alert.bounds.size.width / 2, progress_alert.bounds.size.height - 45);
    [progress_alert addSubview:activity_view];
    [activity_view startAnimating];
    
    if (kDebugLevel > 1)
        NSLog(@"ProviderMVC:googleDriveQueryFileId: Attempting folder query using ID: %@.", file_id);
    
    // GTLServiceTicket can be used to track the status of the request.
    [_our_data.drive executeQuery:search_query completionHandler:^(GTLServiceTicket* ticket, GTLDriveFile* updated_file, NSError* gtl_err) {
        [progress_alert dismissWithClickedButtonIndex:0 animated:YES];
        if (gtl_err != nil) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMasterVC:googleDriveQueryFileId:" message:gtl_err.localizedDescription delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
            [alert show];
            
            [self configureView];
        } else {
            // Folder found.
            if (updated_file.webViewLink != nil) {
                [_our_data.drive_wvls setObject:updated_file.webViewLink forKey:updated_file.title];
                [PersonalDataController saveState:[NSString stringWithFormat:@"%s", kGDriveWVLsFilename] dictionary:_our_data.drive_wvls];
                
                if (kDebugLevel > 2) {
                    NSString* msg = [NSString stringWithFormat:@"DEBUG: Added %@ into driveWVLs using key: %@",  updated_file.webViewLink, updated_file.title];
                    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMasterVC:googleDriveQueryFileId:" message:msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
                    [alert show];
                }
            }
            
            [self configureView];
        }
    }];
}

- (void) googleDriveUpdateFolderPermission:(GTLDriveFile*)folder {
    if (kDebugLevel > 4)
        NSLog(@"ProviderMVC:googleDriveUpdateFolderPermission: called.");
    
    GTLDrivePermission* new_permission = [GTLDrivePermission object];
    new_permission.role = @"reader";
    new_permission.type = @"anyone";
    new_permission.value = nil;
    
    GTLQueryDrive* update_query = [GTLQueryDrive queryForPermissionsInsertWithObject:new_permission fileId:folder.identifier];
    
    UIAlertView* progress_alert = [[UIAlertView alloc] initWithTitle:@"Updating Folder in Google Drive" message:@"Please wait ..." delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    [progress_alert show];
    UIActivityIndicatorView* activity_view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    activity_view.center = CGPointMake(progress_alert.bounds.size.width / 2, progress_alert.bounds.size.height - 45);
    [progress_alert addSubview:activity_view];
    [activity_view startAnimating];
    
    if (kDebugLevel > 1)
        NSLog(@"ProviderMVC:googleDriveUpdateFolderPermission: Attempting folder permission update query on %@.", folder.title);
    
    [_our_data.drive executeQuery:update_query completionHandler:^(GTLServiceTicket* ticket, GTLDrivePermission* permission, NSError* gtl_err) {
        [progress_alert dismissWithClickedButtonIndex:0 animated:YES];
        if (gtl_err != nil) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMasterVC:googleDriveUpdateFolderPermission:" message:gtl_err.localizedDescription delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
            [alert show];
            
            [self configureView];
        } else {
            // Update worked, get new meta-data.
            [self googleDriveQueryFileId:folder.identifier];
        }
    }];
}

#pragma mark - Provider's utility functions

- (NSString*) getConsumerIdentity:(int)mode {
    if (kDebugLevel > 4)
        NSLog(@"ProviderMVC:getConsumerIdentity: called.");
    
    NSString* err_msg = nil;
    
    // First request authorization to Address Book (note, don't make static, as address book could change, no?).
    ABAddressBookRef address_book_ref = ABAddressBookCreateWithOptions(NULL, NULL);
    
    __block BOOL access_explicitly_granted = NO;
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        /* if (ABAddressBookRequestAccessWithCompletion != NULL) { */ // TODO(aka) check to see if we're on iOS 6
        dispatch_semaphore_t status = dispatch_semaphore_create(0);
        ABAddressBookRequestAccessWithCompletion(address_book_ref,
                                                 ^(bool granted, CFErrorRef error) {
                                                     access_explicitly_granted = granted;
                                                     dispatch_semaphore_signal(status);
                                                 });
        dispatch_semaphore_wait(status, DISPATCH_TIME_FOREVER);  // wait until user gives us access
    }
    
    CFRelease(address_book_ref);
    
    if (!access_explicitly_granted && (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined)) {
        err_msg = [[NSString alloc] initWithFormat:@"ProviderMVC:getConsumerIdentity: Unable to respond to pairing request without access to Address Book."];
        return err_msg;
    } else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied) {
        err_msg = [[NSString alloc] initWithFormat:@"ProviderMVC:getConsumerIdentity: Please allow SLS to access Address Book in order to get Consumer contact info."];
        return err_msg;
    }
    
    // Second, launch the people picker, so user can choose correct contact.
    ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
    picker.peoplePickerDelegate = self;
    
    switch (mode) {
        case HCC_MODE_CONSUMER_PUBKEY_SENT :
            picker.navigationBar.topItem.title = @"Choose Contact That Sent Public Key";
            picker.navigationBar.topItem.prompt = @"Prompt";
            break;
        case HCC_MODE_CONSUMER_RESPONSE_SENT :
            picker.navigationBar.topItem.title = @"Choose Contact That Sent Response";
            picker.navigationBar.topItem.prompt = @"Prompt";
            break;
        case HCC_MODE_CONSUMER_CHALLENGE_SENT :
            picker.navigationBar.topItem.title = @"Choose Contact That Sent Challenge";
            picker.navigationBar.topItem.prompt = @"Prompt";
            break;
        case HCC_MODE_CONSUMER_DEPOSIT_SENT :
            picker.navigationBar.topItem.title = @"Choose Contact That Sent Deposit";
            picker.navigationBar.topItem.prompt = @"Prompt";
            break;
        default:
            picker.navigationBar.topItem.title = @"Choose Contact That Sent Pairing Request";
            picker.navigationBar.topItem.prompt = @"Prompt";
    }
    
    [self presentViewController:picker animated:YES completion:nil];
    
    // Make sure we got the data we need from the Address Book ...
    if (_potential_consumer == nil) {
        NSString* err_msg = [NSString stringWithFormat:@"ProviderMVC:getConsumerIdentity: _potential_consumer is nil."];
        return err_msg;
    } else if (_potential_consumer.identity == nil || [_potential_consumer.identity length] == 0) {
        NSString* err_msg = [NSString stringWithFormat:@"Either no Address Book entry chosen or entry does not have an identity, so ignoring pairing message."];
#if 0  // XXX TODO(aka) Should we offer the user another attempt at choosing the correct entry?  Perhaps a retry-count? We'd need to set the otherButtonTitle and delegate routine!
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMVC:getConsumerIdentity:" message:err_msg delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
        [alert show];
#endif
        return err_msg;
    } else if (_potential_consumer.email_address == nil || [_potential_consumer.email_address length] == 0) {
        NSString* err_msg = [NSString stringWithFormat:@"Address Book entry for %s does not contain an e-mail address.", [_potential_consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        return err_msg;
    } else if (_potential_consumer.mobile_number == nil || [_potential_consumer.mobile_number length] == 0) {
        NSString* err_msg = [NSString stringWithFormat:@"Address Book entry for %s does not contain a mobile phone number.", [_potential_consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]];
        return err_msg;
    }
    
    return nil;
}

#pragma mark - Delegate callbacks

// UITableView
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    if (kDebugLevel > 4)
        NSLog(@"ProviderMVC:tableView:didSelectRowAtIndexPath: called.");
    
    NSUInteger section = [indexPath section];
    NSUInteger row = [indexPath row];
    
    if (kDebugLevel > 1)
        NSLog(@"ProviderMVC:tableView:didSelectRowAtIndexPath: row %ld in section %ld selected.", (long)row, (long)section);
    
    // Show consumer details.
    [self performSegueWithIdentifier:@"ShowConsumerListDataViewID" sender:[_consumer_list objectInListAtIndex:row]];
}

- (void) tableView:(UITableView*)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath {
    if (kDebugLevel > 4)
        NSLog(@"ProvderMasterViewController:tableView:accessoryButtonTappedForRowWithIndexPath: called.");

    // For now, we do the same this as if we touched the row (as opposed to the detail disclosure icon).
    NSUInteger section = [indexPath section];
    NSUInteger row = [indexPath row];
    
    if (kDebugLevel > 1)
        NSLog(@"ProviderMVC:tableView:accessoryButtonTappedForRowWithIndexPath:: row %ld in section %ld selected.", (long)row, (long)section);
    
    // TODO(aka) Might want to return the cell to prepareForSegue:sender via [[self tableView] cellForRowAtIndexPath:indexPath]; Or     [[self tableView] indexPathForSelectedRow];
    
    [self performSegueWithIdentifier:@"ShowConsumerListDataViewID" sender:[_consumer_list objectInListAtIndex:row]];
}

// ABPeoplePicker delegate functions.
- (BOOL) peoplePickerNavigationController:(ABPeoplePickerNavigationController*)people_picker shouldContinueAfterSelectingPerson:(ABRecordRef)person {
    if (kDebugLevel > 4)
        NSLog(@"ProviderMVC:peoplePickerNavigationController:shouldContinueAfterSelectingPerson: called.");
    
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
            NSLog(@"ProviderMVC:peoplePickerNavigationController:shouldContinueAfterSelectingPerson: identity not set.");
        
        // Fall-through to wipe global _potential_consumer.
    }
    
    // Build our temporary Principal using the identity we just retrieved.
    if (_potential_consumer == nil)
        _potential_consumer = [[Principal alloc] init];
    _potential_consumer.identity = identity;
    
    if (kDebugLevel > 1)
        NSLog(@"ProviderMVC:peoplePickerNavigationController:shouldContinueAfterSelectingPerson: identity set to: %s.", [_potential_consumer.identity cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    // Look for the additional data we need, specifically; mobile phone number and e-mail address.
    NSString* mobile_number = nil;
    ABMultiValueRef phone_numbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
    for (int i = 0; i < ABMultiValueGetCount(phone_numbers); ++i) {
        CFStringRef label = ABMultiValueCopyLabelAtIndex(phone_numbers, i);
        if (CFStringCompare(kABPersonPhoneMobileLabel, label, kCFCompareCaseInsensitive) == 0)
            mobile_number = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(phone_numbers, i);
    }
    _potential_consumer.mobile_number = mobile_number;
    
    // Unlike our cell phone, we'll take the first e-mail address specified.
    NSString* email_address = nil;
    NSString* email_label = nil;
    ABMultiValueRef email_addresses = ABRecordCopyValue(person, kABPersonEmailProperty);
    if (ABMultiValueGetCount(email_addresses) > 0) {
        email_address = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(email_addresses, 0);
        email_label = (__bridge_transfer NSString*)ABMultiValueCopyLabelAtIndex(email_addresses, 0);
    }
    _potential_consumer.email_address = email_address;
    
    if (kDebugLevel > 0)
        NSLog(@"ProviderMVC:peoplePickerNavigationController:shouldContinueAfterSelectingPerson: Got phone (%s): %s, e-mail (%s): %s.", [(NSString*)kABPersonPhoneMobileLabel cStringUsingEncoding:[NSString defaultCStringEncoding]], [mobile_number cStringUsingEncoding:[NSString defaultCStringEncoding]], [email_label cStringUsingEncoding:[NSString defaultCStringEncoding]], [email_address cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    if ([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] == NSOrderedAscending) {
        [self dismissViewControllerAnimated:YES completion:nil];  // in 8.0+ people picker dismisses by itself
    }
    
    return NO;
}

- (BOOL) peoplePickerNavigationController:(ABPeoplePickerNavigationController*)people_picker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
    if (kDebugLevel > 4)
        NSLog(@"ProviderMVC:peoplePickerNavigationController:shouldContinueAfterSelectingPerson:property:identifier: called.");
    
    return NO;
}

- (void) peoplePickerNavigationController:(ABPeoplePickerNavigationController*)people_picker didSelectPerson:(ABRecordRef)person {
    if (kDebugLevel > 4)
        NSLog(@"ProviderMVC:peoplePickerNavigationController:didSelectingPerson: called (%d).", [NSThread isMainThread]);
    
    [self peoplePickerNavigationController:people_picker shouldContinueAfterSelectingPerson:person];
}

- (void) peoplePickerNavigationController:(ABPeoplePickerNavigationController*)people_picker didSelectPerson:(ABRecordRef)person     property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
    if (kDebugLevel > 4)
        NSLog(@"ProviderMVC:peoplePickerNavigationController:didSelectingPerson:property:identifier: called (%d).", [NSThread isMainThread]);
    
    [self peoplePickerNavigationController:people_picker shouldContinueAfterSelectingPerson:person property:property identifier:identifier];
}

- (void) peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController*)people_picker {
    if (kDebugLevel > 4)
        NSLog(@"ProviderMVC:peoplePickerNavigationControllerDidCancel: called.");
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

// CLLocationManger delegate functions.
- (void) locationManager:(CLLocationManager*)manager didUpdateToLocation:(CLLocation*)new_location fromLocation:(CLLocation*)old_location {
    // TODO(aka) This routine is if the provider MVC would handle CLLocationManager updates locally, instead of through the CoreLocationManger.
    
    if (kDebugLevel > 4)
        NSLog(@"ProviderMVC:locationManager:didUpdateToLocation:fromLocation: called.");
    
    if (![PersonalDataController isFileStoreComplete:_our_data.file_store])
        return;
    
    NSLog(@"ProviderMVC:locationManager:didUpdateToLocation:fromLocation: TODO(aka) Check location date to make sure it's not stale.");
    NSLog(@"ProviderMVC:locationManager:didUpdateToLocation:fromLocation: XXXX In locaitonManger, symmetricKeyController is %lu.", (unsigned long)[_symmetric_keys_controller count]);
    
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
        NSLog(@"ProviderMVC:locationManager:didUpdateToLocation: Location description: %s.", [[new_location description] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    // Modify the location data for each policy (precision), then append it (as a LocationBundle) to that policy's history log.
    
    // Note, we can loop either on polcies or symmetric_keys (in our _symmetric_keys_controller), as one is simply the index into the other!
    
#if 0
    // NSEnumerator example.
    NSEnumerator* enumerator = [_symmetric_keys_controller keyEnumerator];
    id key;
    while ((key = [enumerator nextObject])) {
        NSString* policy = (NSString*)key;
    }
#endif

    NSArray* policies = _symmetric_keys_controller.policies;
    
#if 0
    // For Debugging: XXX
    UILocalNotification* notice = [[UILocalNotification alloc] init];
    NSString* msg = [[NSString alloc] initWithFormat:@"locationManger:didUpdateLocation: Uploaded: %+.6f, %+.6f, %f, policies: %d", new_location.coordinate.latitude, new_location.coordinate.longitude, new_location.course, (unsigned int)[policies count]];
    notice.alertBody = msg;
    notice.alertAction = @"Show";
    [[UIApplication sharedApplication] presentLocalNotificationNow:notice];
#endif
    for (id object in policies) {
        NSString* policy = (NSString*)object;
        
        // Since Amazon S3 (at least) does not have an API for *appending* to a file, we actually upload the entire history log, as opposed to just this new location update.  As it turn out, this isn't a big problem, because we keep an NSMutableArray of our location bundles, i.e., the history log!
        
        // Get the NSMutableArray for this policy, if one exists.
        NSMutableArray* history_log = [_history_logs objectForKey:policy];
        if (history_log == nil)
            history_log = [[NSMutableArray alloc] initWithCapacity:kHistoryLogSize];
        
        // Generate the new location bundle for this policy.
        LocationBundleController* location_bundle = [[LocationBundleController alloc] init];
        [location_bundle build:new_location privateKeyRef:[_our_data privateKeyRef] policy:[PolicyController precisionLevelIndex:policy]];
        
        // TODO(aka) It's arguable that we should encrypt the LocationBundle now, but (i) that would require us to pass in the symmetric key, and (ii) we wouldnl't be able to read it locally again, easily!  (Not sure how important either of these really is, though, on the Provider.)
        
        // Push the new location bundle to this history log queue.
        [history_log insertObject:[location_bundle serialize] atIndex:0];
        
        // If this gave us more than our allotted queue size, delete the last object.
        if ([history_log count] > kHistoryLogSize)
            [history_log removeLastObject];
        
        NSLog(@"ProviderMVC:locationManager:didUpdateToLocation: XXXXXX TODO(aka) Is it necessary to add our pointer back to the dict???.");
        // Add the updated history log back to our dictionary.
        [_history_logs setObject:history_log forKey:policy];
        
        if (kDebugLevel > 1)
            NSLog(@"ProviderMVC:locationManager:didUpdateToLocation: \'%@\' history-log has %lu objects.", policy, (unsigned long)[history_log count]);
        
        // Serialzie, encrypt, base64 then upload the history log for this policy.
        NSString* err_msg = [self uploadHistoryLog:history_log policy:policy];
        if (err_msg != nil || [policy isEqualToString:[PolicyController precisionLevelName:[[NSNumber alloc] initWithInt:0]]]) {
            UILocalNotification* notice = [[UILocalNotification alloc] init];
            if (err_msg != nil) {
                NSString* msg = @"locationManger:didUpdateLocation: ";
                msg = [msg stringByAppendingString:err_msg];
                notice.alertBody = msg;
            } else {
                NSString* msg = [[NSString alloc] initWithFormat:@"locationManger:didUpdateLocation: Uploaded: %+.6f, %+.6f, %f", new_location.coordinate.latitude, new_location.coordinate.longitude, new_location.course];
                notice.alertBody = msg;
            }
            notice.alertAction = @"Show";
            [[UIApplication sharedApplication] presentLocalNotificationNow:notice];
        }
    }  // for (id object in policies) {
    
    // Finally, save our current state (of all our history logs).
    if (kDebugLevel > 1)
        NSLog(@"ProviderMVC:locationManager:didUpdateToLocation: _history_logs has %lu objects.", (unsigned long)[_history_logs count]);
    
    [PersonalDataController saveState:[[NSString alloc] initWithCString:kHistoryLogFilename encoding:[NSString defaultCStringEncoding]] dictionary:_history_logs];
    
    [self configureView];
}

// CorelocationController delegate functions.
- (void) locationsUpdate:(NSArray*)locations {
    if (kDebugLevel > 4)
        NSLog(@"ProviderMVC:locationsUpdate: called.");
    
    if (![PersonalDataController isFileStoreComplete:_our_data.file_store])
        return;
    
    NSLog(@"ProviderMVC:locationssUpdate: TODO(aka) Check location date to make sure it's not stale: %@.", [[locations objectAtIndex:0] description]);
    NSLog(@"ProviderMVC:locationsUpdate: XXXX In locaitonManger, symmetricKeyController is %lu.", (unsigned long)[_symmetric_keys_controller count]);
    
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

    if (kDebugLevel > 2)
        NSLog(@"ProviderMVC:locationsUpdate: Location description: %s.", [[[locations objectAtIndex:0] description] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
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

#if 0
    // For Debugging: XXX
    UILocalNotification* notice = [[UILocalNotification alloc] init];
    NSString* msg = [[NSString alloc] initWithFormat:@"locationManger:locationUpdate: Got %+.6f, %+.6f, %f, policies: %d", location.coordinate.latitude, location.coordinate.longitude, location.course, (unsigned int)[policies count]];
    notice.alertBody = msg;
    notice.alertAction = @"Show";
    [[UIApplication sharedApplication] presentLocalNotificationNow:notice];
#endif
    for (id object in policies) {
        NSString* policy = (NSString*)object;
        
        // Since Amazon S3 (at least) does not have an API for *appending* to a file, we actually upload the entire history log, as opposed to just this new location update.  As it turn out, this isn't a big problem, because we keep an NSMutableArray of our location bundles, i.e., the history log!
        
        // Get the NSMutableArray for this policy, if one exists.
        NSMutableArray* history_log = [_history_logs objectForKey:policy];
        if (history_log == nil)
            history_log = [[NSMutableArray alloc] initWithCapacity:kHistoryLogSize];
        
        // Loop over all possible CLLocaitons in our array ...
        CLLocation* location = nil;
        for (id object in [locations reverseObjectEnumerator]) {
            location = (CLLocation*)object;
            
            // Generate the new location bundle for this policy.
            LocationBundleController* location_bundle = [[LocationBundleController alloc] init];
            [location_bundle build:location privateKeyRef:[_our_data privateKeyRef] policy:[PolicyController precisionLevelIndex:policy]];
            
            // TODO(aka) It's arguable that we should encrypt the LocationBundle now, but (i) that would require us to pass in the symmetric key, and (ii) we wouldnl't be able to read it locally again, easily!  (Not sure how important either of these really is, though on the Provider.)
            
            if (kDebugLevel > 1)
                NSLog(@"ProviderMVC:locationsUpdate: Inserting %s at index 0.", [[location_bundle serialize] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
            
#if 1  // For Debugging:  Sanity check previous timestamps.
            if ([history_log count] > 0) {
                LocationBundleController* prev_location_bundle = [[LocationBundleController alloc] init];
                [prev_location_bundle generateWithString:[history_log objectAtIndex:0]];
                if ([prev_location_bundle.time_stamp intValue] >= [location_bundle.time_stamp intValue]) {
                    NSLog(@"ProviderMVC:locationUpdate: DEBUG: Not adding location, because timestamp: %d, is older than last: %d.", [prev_location_bundle.time_stamp intValue], [location_bundle.time_stamp intValue]);
                    return;
                }
            }
#endif
            
            // Push the new location bundle to this history log queue.
            [history_log insertObject:[location_bundle serialize] atIndex:0];
            
            // If this gave us more than our allotted queue size, delete the last object.
            if ([history_log count] > kHistoryLogSize)
                [history_log removeLastObject];
        }
        
        NSLog(@"ProviderMVC:locationsUpdate: XXXXX TODO(aka) Is it necessary to add our pointer back to the dict???.");
        // Add the updated history log back to our dictionary.
        [_history_logs setObject:history_log forKey:policy];
        
        if (kDebugLevel > 2)
            NSLog(@"ProviderMVC:locationsUpdate: \'%@\' history-log has %lu objects.", policy, (unsigned long)[history_log count]);
        
        // Serialzie, encrypt, base64 then upload the history log for this policy.
        NSString* err_msg = [self uploadHistoryLog:history_log policy:policy];
        if (err_msg != nil || [policy isEqualToString:[PolicyController precisionLevelName:[[NSNumber alloc] initWithInt:0]]]) {
            UILocalNotification* notice = [[UILocalNotification alloc] init];
            if (err_msg != nil) {
                NSString* msg = @"locationsUpdate: ";
                msg = [msg stringByAppendingString:err_msg];
                notice.alertBody = msg;
            } else {
                NSString* msg = [[NSString alloc] initWithFormat:@"locationsUpdate: Uploaded: %+.6f, %+.6f, %f", location.coordinate.latitude, location.coordinate.longitude, location.course];
                notice.alertBody = msg;
            }
            notice.alertAction = @"Show";
            [[UIApplication sharedApplication] presentLocalNotificationNow:notice];
        }
    }  // for (id object in policies) {
    
    // Finally, save our current state (of all our history logs).
    if (kDebugLevel > 1)
        NSLog(@"ProviderMVC:locationsUpdate: uploaded %lu history-log(s), now saving state.", (unsigned long)[_history_logs count]);
    
#if 0  // For Debugging:
    for (id key in _history_logs) {
        NSString* policy = (NSString*)key;
        NSArray* array = [_history_logs objectForKey:policy];
        int cnt = 0;
        for (id object in array) {
            NSString* location_bundle = (NSString*)object;
            NSLog(@"ProviderMVC:locationsUpdate: DEBUG: _history_log[%@][%i]: %@.", policy, cnt, location_bundle);
            cnt++;
        }
    }
#endif
    
    [PersonalDataController saveState:[[NSString alloc] initWithCString:kHistoryLogFilename encoding:[NSString defaultCStringEncoding]] dictionary:_history_logs];
    
    [self configureView];
}

- (void) locationUpdate:(CLLocation*)location {
    if (kDebugLevel > 4)
        NSLog(@"ProviderMVC:locationUpdate: called.");
    
    // Note, this routine is the same as locationManager:didUpdateToLocation:fromLocation: above.
    
    if (![PersonalDataController isFileStoreComplete:_our_data.file_store])
        return;
    
    NSLog(@"ProviderMVC:locationUpdate: TODO(aka) Check location date to make sure it's not stale: %@.", [location description]);
    NSLog(@"ProviderMVC:locationManager:didUpdateToLocation:fromLocation: XXXX In locaitonManger, symmetricKeyController is %lu.", (unsigned long)[_symmetric_keys_controller count]);
    
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
    
    if (kDebugLevel > 2)
        NSLog(@"ProviderMVC:locationUpdate: Location description: %s.", [[location description] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
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
    
#if 0
    // For Debugging: XXX
    UILocalNotification* notice = [[UILocalNotification alloc] init];
    NSString* msg = [[NSString alloc] initWithFormat:@"locationManger:locationUpdate: Got %+.6f, %+.6f, %f, policies: %d", location.coordinate.latitude, location.coordinate.longitude, location.course, (unsigned int)[policies count]];
    notice.alertBody = msg;
    notice.alertAction = @"Show";
    [[UIApplication sharedApplication] presentLocalNotificationNow:notice];
#endif
    for (id object in policies) {
        NSString* policy = (NSString*)object;
        
        // Since Amazon S3 (at least) does not have an API for *appending* to a file, we actually upload the entire history log, as opposed to just this new location update.  As it turn out, this isn't a big problem, because we keep an NSMutableArray of our location bundles, i.e., the history log!
        
        // Get the NSMutableArray for this policy, if one exists.
        NSMutableArray* history_log = [_history_logs objectForKey:policy];
        if (history_log == nil)
            history_log = [[NSMutableArray alloc] initWithCapacity:kHistoryLogSize];
        
        // Generate the new location bundle for this policy.
        LocationBundleController* location_bundle = [[LocationBundleController alloc] init];
        [location_bundle build:location privateKeyRef:[_our_data privateKeyRef] policy:[PolicyController precisionLevelIndex:policy]];
        
        // TODO(aka) It's arguable that we should encrypt the LocationBundle now, but (i) that would require us to pass in the symmetric key, and (ii) we wouldnl't be able to read it locally again, easily!  (Not sure how important either of these really is, though on the Provider.)
        
        if (kDebugLevel > 1)
            NSLog(@"ProviderMVC:locationUpdate: Inserting %s at index 0.", [[location_bundle serialize] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        
#if 1  // For Debugging:  Sanity check previous timestamps.
        if ([history_log count] > 0) {
            LocationBundleController* prev_location_bundle = [[LocationBundleController alloc] init];
            [prev_location_bundle generateWithString:[history_log objectAtIndex:0]];
            if ([prev_location_bundle.time_stamp intValue] >= [location_bundle.time_stamp intValue]) {
                NSLog(@"ProviderMVC:locationUpdate: DEBUG: Not adding location, because timestamp: %d, is older than last: %d.", [prev_location_bundle.time_stamp intValue], [location_bundle.time_stamp intValue]);
                return;
            }
        }
#endif
        
        // Push the new location bundle to this history log queue.
        [history_log insertObject:[location_bundle serialize] atIndex:0];
        
        // If this gave us more than our allotted queue size, delete the last object.
        if ([history_log count] > kHistoryLogSize)
            [history_log removeLastObject];
        
        NSLog(@"ProviderMVC:locationUpdate: XXXXX TODO(aka) Is it necessary to add our pointer back to the dict???.");
        // Add the updated history log back to our dictionary.
        [_history_logs setObject:history_log forKey:policy];
        
        if (kDebugLevel > 2)
            NSLog(@"ProviderMVC:locationUpdate: \'%@\' history-log has %lu objects.", policy, (unsigned long)[history_log count]);
        
        // Serialzie, encrypt, base64 then upload the history log for this policy.
        NSString* err_msg = [self uploadHistoryLog:history_log policy:policy];
        if (err_msg != nil || [policy isEqualToString:[PolicyController precisionLevelName:[[NSNumber alloc] initWithInt:0]]]) {
            UILocalNotification* notice = [[UILocalNotification alloc] init];
            if (err_msg != nil) {
                NSString* msg = @"locationUpdate: ";
                msg = [msg stringByAppendingString:err_msg];
                notice.alertBody = msg;
            } else {
                NSString* msg = [[NSString alloc] initWithFormat:@"locationUpdate: Uploaded: %+.6f, %+.6f, %f", location.coordinate.latitude, location.coordinate.longitude, location.course];
                notice.alertBody = msg;
            }
            notice.alertAction = @"Show";
            [[UIApplication sharedApplication] presentLocalNotificationNow:notice];
        }
    }  // for (id object in policies) {
    
    // Finally, save our current state (of all our history logs).
    if (kDebugLevel > 1)
        NSLog(@"ProviderMVC:locationUpdate: uploaded %lu history-log(s), now saving state.", (unsigned long)[_history_logs count]);
    
#if 0  // For Debugging:
    for (id key in _history_logs) {
        NSString* policy = (NSString*)key;
        NSArray* array = [_history_logs objectForKey:policy];
        int cnt = 0;
        for (id object in array) {
            NSString* location_bundle = (NSString*)object;
            NSLog(@"ProviderMVC:locationUpdate: DEBUG: _history_log[%@][%i]: %@.", policy, cnt, location_bundle);
            cnt++;
        }
    }
#endif
    
    [PersonalDataController saveState:[[NSString alloc] initWithCString:kHistoryLogFilename encoding:[NSString defaultCStringEncoding]] dictionary:_history_logs];
    
    [self configureView];
}

- (void) locationError:(NSError*)error {
    if (kDebugLevel > 4)
        NSLog(@"ProviderMVC:locationError:error: called.");
	
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
                NSLog(@"ProviderMVC:messageComposeViewController:didFinishWithResult: Cancelled.");
			break;
            
		case MessageComposeResultFailed:
        {
			NSLog(@"ProviderMVC:messageComposeViewController:didFinishWithResult: Failed!");
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"SMS Error" message:@"Unknown Error" delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
			[alert show];
        }
			break;
            
		case MessageComposeResultSent:
            if (kDebugLevel > 0)
                NSLog(@"ProviderMVC:messageComposeViewController:didFinishWithResult: Sent.");
			break;
            
		default:
			NSLog(@"ProviderMVC:messageComposeViewController:didFinishWithResult: ERROR: unknown result: %d.", result);
			break;
	}
    
	[self dismissViewControllerAnimated:YES completion:nil];
}

// MFMailComposeViewController delegate functions.
- (void) mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    if (error != nil) {
        NSLog(@"ProviderMVC:mailComposeController:didFinishWithResult: ERROR: TODO(aka) received: %s.", [[error description] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
        
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
	switch (result) {
        case MFMailComposeResultCancelled:
            if (kDebugLevel > 0)
                NSLog(@"ProviderMVC:mailComposeController:didFinishWithResult: Cancelled.");
			break;
            
        case MFMailComposeResultFailed:
        {
			NSLog(@"ProviderMVC:mailComposeController:didFinishWithResult: Failed!");
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"SMS Error" message:@"Unknown Error" delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
			[alert show];
        }
			break;
            
        case MFMailComposeResultSent:
            if (kDebugLevel > 0)
                NSLog(@"ProviderMVC:mailComposeController:didFinishWithResult: Sent.");
			break;
            
        case MFMailComposeResultSaved:
            NSLog(@"ProviderMVC:mailComposeController:didFinishWithResult: Saved: TODO(aka) What do we do?.");
			break;
            
		default:
			NSLog(@"ProviderMVC:mailComposeController:didFinishWithResult: ERROR: unknown result: %d.", result);
			break;
	}
    
	[self dismissViewControllerAnimated:YES completion:nil];
}

// GTMOAuth2ViewControllerTouch delegate functions.
- (void)viewController:(GTMOAuth2ViewControllerTouch*)viewController finishedWithAuth:(GTMOAuth2Authentication*)auth_result error:(NSError*)error {
    if (kDebugLevel > 4)
        NSLog(@"ProviderMVC:viewController:finishedWithAuth: called.");
    
    if (error != nil) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMasterVC:viewController:finishedWithResult:" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
        [alert show];
    } else {
        // Auth successful
        _our_data.drive.authorizer = auth_result;
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ProviderMasterVC:viewController:finishedWithResult:" message:@"Authentication Successful" delegate:nil cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
        [alert show];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];  // remove GTMOAuth2ViewController
}

// UIAlertView delegate functions.
- (void) alertView:(UIAlertView*)alert_view clickedButtonAtIndex:(NSInteger)button_index {
    if (kDebugLevel > 4)
        NSLog(@"ProviderMVC:alertView:clickedButtonAtIndex: called.");
    
 	NSString* title = [alert_view buttonTitleAtIndex:button_index];
	if([title isEqualToString:[NSString stringWithCString:kAlertButtonContinuePairingMessage encoding:[NSString defaultCStringEncoding]]]) {
        if (kDebugLevel > 0)
            NSLog(@"ProviderMVC:alertView:clickedButtonAtIndex: matched ContinuePairingMessage.");
        
        // Segue to AddConsumerHCCVC, to continue with pairing protocol.
        [self performSegueWithIdentifier:@"ShowAddConsumerHCCViewID" sender:nil];
	} else if([title isEqualToString:[NSString stringWithCString:kAlertButtonCancelPairingMessage encoding:[NSString defaultCStringEncoding]]]) {
        if (kDebugLevel > 0)
            NSLog(@"ProviderMVC:alertView:clickedButtonAtIndex: matched CancelPairingMessage.");
        
        // Hmm, we need to remove the potential consumer from our dictionary.
        [_potential_consumers removeObjectForKey:_potential_consumer.identity];  // TODO(aka) not thread safe
	} else {
        NSLog(@"ProviderMVC:alertView:clickedButtonAtIndex: TODO(aka) unknown title: %s", [title cStringUsingEncoding:[NSString defaultCStringEncoding]]);
	}
    
    [self configureView];
}

@end

//
//  ConsumerListDataViewController.m
//  SLS
//
//  Created by Andrew K. Adams on 12/5/13.
//  Copyright (c) 2013 Andrew K. Adams. All rights reserved.
//

#import "NSData+Base64.h"

#import "ConsumerListDataViewController.h"
#import "PersonalDataController.h"
#import "PolicyController.h"


static const int kDebugLevel = 4;

static const char* kAlertButtonCancelMessage = "No, cancel operation!";
static const char* kAlertButtonDeleteConsumerMessage = "Yes, delete this consumer.";


@interface ConsumerListDataViewController ()
@end

@implementation ConsumerListDataViewController

#pragma mark - Inherited data
@synthesize consumer = _consumer;

#pragma mark - Local variables
@synthesize desired_policy = _desired_policy;
@synthesize policy_changed = _policy_changed;
@synthesize track_consumer = _track_consumer;
@synthesize delete_principal = _delete_principal;
@synthesize send_file_store_info = _send_file_store_info;
@synthesize upload_key_bundle = _upload_key_bundle;

#pragma mark - Outlets
@synthesize identity_label = _identity_label;
@synthesize token_label = _token_label;
@synthesize deposit_label = _deposit_label;
@synthesize pub_key_label = _pub_key_label;
@synthesize precision_slider = _precision_slider;
@synthesize precision_label = _precision_label;
@synthesize send_file_store_button = _send_file_store_button;
@synthesize track_consumer_button = _track_consumer_button;
@synthesize delete_button = _delete_button;

#pragma mark - Initialization

- (id) init {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerListDataViewController:init: called.");
    
    if (self = [super init]) {
        _consumer = nil;
        _desired_policy = nil;
        _policy_changed = false;
        _track_consumer = false;
        _delete_principal = false;
        _send_file_store_info = false;
        _upload_key_bundle = false;
    }
    
    return self;
}

- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerListDataViewController:initWithNibName:bundle: called.");
    
    self = [super initWithNibName:nib_name_or_nil bundle:nib_bundle_or_nil];
    if (self) {
        // Custom initialization
        _consumer = nil;
        _desired_policy = nil;
        _policy_changed = false;
        _track_consumer = false;
        _delete_principal = false;
        _send_file_store_info = false;
        _upload_key_bundle = false;
    }
    
    return self;
}

- (id) initWithStyle:(UITableViewStyle)style {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerListDataViewController:initWithStyle: called.");
    
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        _consumer = nil;
        _desired_policy = nil;
        _policy_changed = false;
        _track_consumer = false;
        _delete_principal = false;
        _send_file_store_info = false;
        _upload_key_bundle = false;
    }
    return self;
}

#pragma mark - View management

- (void) viewDidLoad {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerListDataViewController:viewDidLoad: called.");
    
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    
    [self configureView];
}

- (void) configureView {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerListDataViewController:configureView: called.");
    
    _identity_label.text = _consumer.identity;
    _token_label.text = _consumer.identity_hash;
    _deposit_label.text = [PersonalDataController serializeDeposit:_consumer.deposit];
    _pub_key_label.text = [PersonalDataController hashAsymmetricKey:[_consumer getPublicKey]];
    
    // Setup the slider value.
    if (_desired_policy == nil)
        _precision_slider.value = [[PolicyController precisionLevelIndex:_consumer.policy] floatValue];
    else
        _precision_slider.value = [[PolicyController precisionLevelIndex:_desired_policy] floatValue];
    [_precision_label setText:[NSString stringWithFormat:@"%d", (int)_precision_slider.value]];
    
    if (_consumer.file_store_sent) {
        [_send_file_store_button setAlpha:0.5];
    } else {
        [_send_file_store_button setAlpha:1.0];
    }
    
    // TODO(aka) Would be nice if we knew if this consumer was already being tracked, but that would require the ConsumerMaster VC contacting us (and keeping state up), and I'm not sure that's worth it.
    
    if (_track_consumer) {
        [_track_consumer_button setAlpha:0.5];
    } else {
        [_track_consumer_button setAlpha:1.0];
    }
    
    if (_delete_principal) {
        [_delete_button setAlpha:0.5];
    } else {
        [_delete_button setAlpha:1.0];
    }
    
    if (_send_file_store_info) {
        [_send_file_store_button setAlpha:0.5];
    } else {
        [_send_file_store_button setAlpha:1.0];
    }

    if (_upload_key_bundle) {
        [_upload_key_bundle_button setAlpha:0.5];
    } else {
        [_upload_key_bundle_button setAlpha:1.0];
    }
}

#pragma mark - Memory management

- (void) didReceiveMemoryWarning {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerListDataViewController:didReceiveMemoryWarning: called.");
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Data source routines

// UITableView
/*  Using static prototype, so use the super methods ...
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 0;  // using dynamic prototype
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 0;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
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
- (void) tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL) tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Navigation

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerListDataViewController:prepareForSeque: called.");
    
    if ([[segue identifier] isEqualToString:@"UnwindToProviderMasterViewID"]) {
        if (kDebugLevel > 2)
            NSLog(@"ConsumerListDataViewController:prepareForSeque: unwinding to ProviderMasterViewController.");
        
        if (sender != self.done_button) {
            // User hit CANCEL.
            if (kDebugLevel > 0)
                NSLog(@"ConsumerListDataViewController:prepareForSeque: User hit CANCEL (delete_principal: %d).", _delete_principal);
            
            // Unset any state flags, if they were set.
            _delete_principal = false;
            _track_consumer = false;
            _policy_changed = false;
        } else {
            // User hit DONE.
            if (kDebugLevel > 0)
                NSLog(@"ConsumerListDataViewController:prepareForSeque: User hit DONE.");
            
            // Nothing to do ...
        }
    } else {
        NSLog(@"ConsumerListDataViewController:prepareForSeque: TODO(aka) unknown segue: %s.", [[segue identifier] cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    }
}

#pragma mark - Actions

- (IBAction) precisionValueChanged:(id)sender {
    if (kDebugLevel > 0)
        NSLog(@"ConsumerListDataViewController:precisionValueChanged: called.");
    
    UISlider* slider = (UISlider*)sender;
    _desired_policy = [PolicyController precisionLevelName:[[NSNumber alloc] initWithFloat:slider.value]];
    
    _policy_changed = true;
    
    [self configureView];
}

- (IBAction) sendFileStore:(id)sender {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerListDataViewController:sendFileStore: called.");
    
    _send_file_store_info = true;  // handle back in Provider MVC!

    [self configureView];
}

- (IBAction)uploadKeyBundle:(id)sender {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerListDataViewController:uploadKeyBundle: called.");
    
    _upload_key_bundle = true;
    
    [self configureView];
}

- (IBAction) makeConsumerAProvider:(id)sender {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerListDataViewController:makeConsumerAProvider: called.");
    
    /*
     UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"ConsumerListDataViewController:makeConsumerAProvider:" message:@"Note, It's up to this person to send you location data" delegate:self cancelButtonTitle:@"OKAY" otherButtonTitles:nil];
     [alert show];
     */
    
    _track_consumer = true;
    [self configureView];
}

- (IBAction) deletePrincipal:(id)sender {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerListDataViewController:deletePrincipal: called.");
    
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Consumer Removal" message:@"Are you sure you want to delete this consumer?" delegate:self cancelButtonTitle:[NSString stringWithCString:kAlertButtonCancelMessage encoding:[NSString defaultCStringEncoding]] otherButtonTitles:[NSString stringWithCString:kAlertButtonDeleteConsumerMessage encoding:[NSString defaultCStringEncoding]], nil];
    [alert show];
}

#pragma mark - Delegate functions

// UIAlertView
- (void)alertView:(UIAlertView*)alert_view clickedButtonAtIndex:(NSInteger)button_index {
    if (kDebugLevel > 4)
        NSLog(@"ConsumerDataViewController:alertView:clickedButtonAtIndex: called.");
    
 	NSString* title = [alert_view buttonTitleAtIndex:button_index];
	if([title isEqualToString:[NSString stringWithCString:kAlertButtonDeleteConsumerMessage encoding:[NSString defaultCStringEncoding]]]) {
        if (kDebugLevel > 0)
            NSLog(@"ConsumerDataViewController:alertView:clickedButtonAtIndex: matched GenKeysMessage.");
        _delete_principal = true;
	} else if([title isEqualToString:[NSString stringWithCString:kAlertButtonCancelMessage encoding:[NSString defaultCStringEncoding]]]) {
        if (kDebugLevel > 0)
            NSLog(@"ConsumerDataViewController:alertView:clickedButtonAtIndex: matched CancelMessage.");
	} else {
        NSLog(@"ConsumerDataViewController:alertView:clickedButtonAtIndex: TODO(aka) unknown title: %s", [title cStringUsingEncoding:[NSString defaultCStringEncoding]]);
	}
    
    [self configureView];
}

@end

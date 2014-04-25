//
//  ConsumerMasterViewController.h
//  SLS
//
//  Created by Andrew K. Adams on 11/19/13.
//  Copyright (c) 2013 Andrew K. Adams. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBookUI/AddressBookUI.h>        // needed for delegation
#import <MapKit/MapKit.h>

#import "ProviderMasterViewController.h"       // for delegation

// Data members.
#import "PersonalDataController.h"
#import "ProviderListController.h"
#import "HCCPotentialPrincipal.h"

@class Principal;
@class KeyBundleController;

@interface ConsumerMasterViewController : UIViewController <ABPeoplePickerNavigationControllerDelegate, MKMapViewDelegate, ProviderMasterViewControllerDelegate>

#pragma mark - Local variables
@property (strong, nonatomic) PersonalDataController* our_data;
@property (strong, nonatomic) ProviderListController* provider_list;
@property (strong, nonatomic) NSMutableDictionary* potential_providers;  // HCCPotentialPrincipal objects indexed by identity
@property (strong, nonatomic) Principal* potential_provider;  // a temporary Principal used by ABPeoplePickerNavigationController's delegate
@property (nonatomic) BOOL fetch_data_toggle;

#pragma mark - Outlets
@property (nonatomic, retain) IBOutlet MKMapView* map_view;

#pragma mark - Initialization
- (id) init;
- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil;
- (void) loadState;

#pragma mark - View management
- (CLLocationCoordinate2D) plotProviderLocations:(Principal*)sole_provider; // plots location history

#pragma mark - Cloud operations
- (NSString*) fetchKeyBundle:(Principal*)provider keyBundle:(KeyBundleController**)key_bundle;
- (NSString*) fetchHistoryLog:(Principal*)provider stateChanged:(BOOL*)state_change;
- (void) updateAllProviderData;
- (void) updateProviderData:(Principal*)provider stateChanged:(BOOL*)state_change;

#pragma mark - Location data management
- (void) setTimerForFetchingData;

#pragma mark - NSUserDefaults management
- (NSString*) checkNSUserDefaults;

#pragma mark - Actions
- (IBAction) showProviderDetails:(id)sender;

#pragma mark - Consumer's utility functions
- (NSString*) getProviderIdentity:(int)mode;

@end

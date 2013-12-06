//
//  ConsumerMasterViewController.h
//  SLS
//
//  Created by Andrew K. Adams on 11/19/13.
//  Copyright (c) 2013 Andrew K. Adams. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

#import "ProviderMasterViewController.h"         // for delegation

// Data members.
#import "PersonalDataController.h"
#import "ProviderListController.h"

@class Principal;

@interface ConsumerMasterViewController : UIViewController <MKMapViewDelegate, ProviderMasterViewControllerDelegate>

#pragma mark - Local variables
@property (strong, nonatomic) PersonalDataController* our_data;
@property (strong, nonatomic) ProviderListController* provider_list;
@property (nonatomic) BOOL fetch_data_toggle;

#pragma mark - Outlets
@property (nonatomic, retain) IBOutlet MKMapView* map_view;

#pragma mark - Initialization
- (id) init;
- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil;
- (void) loadState;

#pragma mark - Actions
- (IBAction) showProviderDetails:(id)sender;

#pragma mark - Location data management
- (void) setTimerForFetchingData;
- (void) checkNSUserDefaults;
- (void) updateProviderData;  // fetch providers' data
- (CLLocationCoordinate2D) plotProviderLocations:(Principal*)sole_provider; // plots location history

@end

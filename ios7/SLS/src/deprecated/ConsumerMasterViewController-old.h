//
//  ConsumerMasterViewController.h
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 4/1/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

#import "ConsumerDataViewController.h"       // needed for unwind segue
#import "AddProviderViewController.h"        // needed for delegation
#import "ProviderListDataViewController.h"   // needed for delegation

// Data members.
#import "PersonalDataController.h"
#import "ProviderListController.h"


// XXX TODO(aka) I don't think we need DataView or AddProvider delegates anymore (as we're using unwind segues!
@interface ConsumerMasterViewController : UIViewController <MKMapViewDelegate, ProviderListDataViewControllerDelegate>
// XXX @interface ConsumerMasterViewController : UIViewController <MKMapViewDelegate, ConsumerDataViewControllerDelegate, AddProviderViewControllerDelegate, ProviderListDataViewControllerDelegate>

#pragma mark - Our Data
@property (strong, nonatomic) PersonalDataController* our_data;
@property (strong, nonatomic) ProviderListController* provider_list_controller;
@property (nonatomic) BOOL fetch_data_toggle;

#pragma mark - Outlets
@property (nonatomic, retain) IBOutlet MKMapView* map_view;

#pragma mark - Initialization
- (id) init;
- (id) initWithNibName:(NSString*)nib_name_or_nil bundle:(NSBundle*)nib_bundle_or_nil;
- (void) loadState;

#pragma mark - Actions
- (IBAction) showProviderDetails:(id)sender;

#pragma mark - Data Management
- (void) setTimerForFetchingData;
- (void) checkNSUserDefaults;
- (void) updateProviderData;        // fetches all providers' data
//XXX - (MKMapRect) plotProviderLocations:(Provider*)sole_provider; // plots location history
- (CLLocationCoordinate2D) plotProviderLocations:(Provider*)sole_provider; // plots location history

#pragma mark - Delegate Routines

#pragma mark - NSURLConnection
// TODO(aka) NSURLConnnection routines not currently used.
- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response;
- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data;
- (void)connectionDidFinishLoading:(NSURLConnection*)connection;
- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError *)error;

@end

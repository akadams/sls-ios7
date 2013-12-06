//
//  BluetoothRequestViewController.h
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 4/2/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import <UIKit/UIKit.h>

// Data members.
#import "PersonalDataController.h"
#import "Consumer.h"


@protocol BluetoothRequestViewControllerDelegate;

@interface BluetoothRequestViewController : UITableViewController

@property (copy, nonatomic) PersonalDataController* our_data;
@property (copy, nonatomic) Consumer* consumer;
@property (weak, nonatomic) id <BluetoothRequestViewControllerDelegate> delegate;

- (id) init;
- (id) initWithStyle:(UITableViewStyle)style;
- (IBAction)cancel:(id)sender;
- (IBAction)done:(id)sender;

@end

@protocol BluetoothRequestViewControllerDelegate <NSObject>
- (void) bluetoothRequestViewControllerDidFinish:(Consumer*)consumer;
- (void) bluetoothRequestViewControllerDidCancel:(BluetoothRequestViewController*)controller;
@end

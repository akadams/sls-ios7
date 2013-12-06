//
//  BluetoothRequestViewController.m
//  Secure Location Sharing
//
//  Created by Andrew K. Adams on 4/2/12.
//  Copyright (c) 2012 Andrew K. Adams. All rights reserved.
//

#import "BluetoothRequestViewController.h"


static const int kDebugLevel = 1;

@interface BluetoothRequestViewController ()
@end

@implementation BluetoothRequestViewController

@synthesize our_data = _our_data;
@synthesize consumer = _consumer;
@synthesize delegate = _delegate;

- (id) init {
    if (kDebugLevel > 2)
        NSLog(@"BluetoothRequestViewController:init: called.");
    
    if (self = [super init]) {
        NSLog(@"BluetoothRequestViewController:init: TODO(aka) Setting members to nil.");

        _our_data = nil;
        _consumer = nil;
        _delegate = nil;
    }
    
    return self;
}

- (id) initWithStyle:(UITableViewStyle)style {
    if (kDebugLevel > 2)
        NSLog(@"BluetoothRequestViewController:initWithStyle: called.");
    
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        _our_data = nil;
        _consumer = nil;
        _delegate = nil;
    }
    
    return self;
}

- (void) viewDidLoad {
    if (kDebugLevel > 2)
        NSLog(@"BluetoothRequestViewController:viewDidLoad: called.");
    
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Bluetooth Request" message:@"Bluetooth communionable trust not implemented yet!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

- (void) viewDidUnload {
    if (kDebugLevel > 2)
        NSLog(@"BluetoothRequestViewController:viewDidUnload: called.");
    
    // Note, this is where we clean up any *strong* references.
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    NSLog(@"BluetoothRequestViewController:numberOfSectionsInTableView: TODO(aka) not implemented correctly!");
    
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    NSLog(@"BluetoothRequestViewController:numberOfRowsInSection: TODO(aka) Not implemented correctly!");

    return 0;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"BluetoothRequestViewController:cellForRowAtIndexPath: TODO(aka) Not implemented correctly!");
    
    static NSString* CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
    
    NSLog(@"BluetoothRequestViewController:didSelectRowAtIndexPath: TODO(aka) Not implemented correctly.");
    
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

- (IBAction) done:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"BluetoothRequestViewController:done: called.");
    
    NSLog(@"BluetoothRequestViewController:done: TODO(aka) must assign received Consumer elements!");

    [[self delegate] bluetoothRequestViewControllerDidCancel:self];
    //[[self delegate] bluetoothRequestViewControllerDidFinish:_consumer];
}

- (IBAction) cancel:(id)sender {
    if (kDebugLevel > 2)
        NSLog(@"BluetoothRequestViewController:init: called.");
    
    [[self delegate] bluetoothRequestViewControllerDidCancel:self];
}


// Delegate functions.

@end

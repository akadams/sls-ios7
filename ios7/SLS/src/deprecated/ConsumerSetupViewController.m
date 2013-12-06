//
//  ConsumerSetupViewController.m
//  SLS
//
//  Created by Andrew K. Adams on 11/13/13.
//  Copyright (c) 2013 Andrew K. Adams. All rights reserved.
//

#import "ConsumerSetupViewController.h"

@interface ConsumerSetupViewController ()

@end

@implementation ConsumerSetupViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSLog(@"ConsumerSetupViewController:numberOfSectionsInTableView: TODO(aka) not implemented correctly!");
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 7;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
NSLog(@"ConsumerSetupViewController:numberOfRowsInSection:%ld TODO(aka) not implemented correctly!", (long)section);
    switch (section) {
        case 0: return 1;
            break;
        case 1: return 2;
            break;
        case 2: return 1;
            break;
        case 3: return 1;
            break;
        case 4: return 1;
            break;
        case 5: return 1;
            break;
        case 6: return 1;
            break;
        default:
            break;
    }
    
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
 NSLog(@"ConsumerSetupViewController:cellForRowAtIndexPath: TODO(aka) not implemented correctly!");
    UITableViewCell* cell = [super tableView:tableView
                       cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    NSUInteger section = [indexPath section];
    NSUInteger row = [indexPath row];
 
    NSLog(@"ConsumerSetupViewController:cellForRowAtIndexPath: configuring %ld:%ld!", (long)section, (long)row);

    // Configure the cell...
    switch (section)
    {
            break;
    }
    
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
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
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

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end

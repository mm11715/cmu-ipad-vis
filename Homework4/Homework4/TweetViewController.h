//
//  TweetViewController.h
//  Homework4
//
//  Created by Al Wold on 2/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TweetViewController : UIViewController <UITableViewDelegate,UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSMutableSet *annotations;
- (IBAction)filterEntered:(UITextField *)sender;
- (IBAction)sortChanged:(UISegmentedControl *)sender;
- (IBAction)batchSizeChanged:(UISlider *)sender;
- (IBAction)filterByMap;
- (void)reloadTweets;

@end

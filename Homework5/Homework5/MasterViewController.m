//
//  MasterViewController.m
//  Homework5
//
//  Created by Al Wold on 3/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "AppDelegate.h"
#import "Tweet.h"

@implementation MasterViewController

@synthesize detailViewController = _detailViewController;
@synthesize tableView = _tableView;
@synthesize datePicker = _datePicker;
@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize timerRunning = _timerRunning;
@synthesize dispatchSource = _dispatchSource;

- (void)awakeFromNib
{
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
	    self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
	}
    [super awakeFromNib];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (void)updateTweetFilter
{
	NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSLog(@"datePicker date: %@", self.datePicker.date);
	NSDateComponents *comps = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:self.datePicker.date];
	NSDate *startDate = [calendar dateFromComponents:comps];
	NSLog(@"startDate = %@", startDate);
	[comps setMinute:comps.minute+1];
	NSDate *endDate = [calendar dateFromComponents:comps];
	NSLog(@"endDate = %@", endDate);
	[self.fetchedResultsController.fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"timestamp BETWEEN { %@, %@ }", startDate, endDate]];
	NSError *error;
	[self.fetchedResultsController performFetch:&error];
	[self.tableView reloadData];
	// add pins to map
	AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	NSLog(@"clear annotations");
	[delegate.mapView removeAnnotations:delegate.mapView.annotations];
	__block NSUInteger counter = 0;
	NSLog(@"number of tweets: %d", self.fetchedResultsController.fetchedObjects.count);
	[self.fetchedResultsController.fetchedObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		Tweet *tweet = (Tweet *)obj;
		NSLog(@"tweet number: %d", counter++);
		// for some reason this crashes if you let it do much over 100 tweets
		if (counter < 100 && tweet.latitude && tweet.longitude) {
			// add a pin
			MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
			annotation.coordinate = CLLocationCoordinate2DMake([tweet.latitude doubleValue], [tweet.longitude doubleValue]);
			NSLog(@"found a location: %@, %@", tweet.latitude, tweet.longitude);
			[delegate.mapView addAnnotation:annotation];
		}
	}];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
	
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Tweet"];
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO];
	[fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
	NSManagedObjectContext *managedObjectContext = [appDelegate managedObjectContext];
	self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:managedObjectContext sectionNameKeyPath:nil cacheName:nil];
	
	
	NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *components = [[NSDateComponents alloc] init];
	components.year = 2012;
	components.month = 1;
	components.day = 31;
	components.hour = 8;
	components.minute = 47;
	[self.datePicker setDate:[calendar dateFromComponents:components] animated:NO];

							  
	[self updateTweetFilter];
}

- (void)viewDidUnload
{
	[self setTableView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
	    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
	} else {
	    return YES;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSUInteger count = [[[self.fetchedResultsController sections] objectAtIndex:section] numberOfObjects];
	NSLog(@"Cell count: %d", count);
	return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Tweet"];
	NSManagedObject *tweet = [self.fetchedResultsController objectAtIndexPath:indexPath];
	cell.textLabel.text = [tweet valueForKey:@"content"];
	NSManagedObject *twitterUser = [tweet valueForKey:@"user"];
	cell.detailTextLabel.text = [twitterUser valueForKey:@"username"];
	return cell;
}
- (IBAction)dateChanged:(UIDatePicker *)sender {
	NSLog(@"self.datePicker is %@", self.datePicker);
	NSLog(@"event target is %@", sender);
	NSLog(@"datechanged");
	[self updateTweetFilter];
}

- (IBAction)startStopTimer:(UIButton *)sender {
	if (self.timerRunning) {
		//stop it
		dispatch_source_cancel(self.dispatchSource);
		self.timerRunning = NO;
		[sender setTitle:@"Start" forState:UIControlStateNormal];
	} else {
		// start it
		NSLog(@"starting. ref date = %@", self.datePicker.date);
		self.dispatchSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
		dispatch_source_set_event_handler(self.dispatchSource, ^{
			[self advanceDate];	
		});
		dispatch_source_set_timer(self.dispatchSource, DISPATCH_TIME_NOW, 1000000000, 1000000000);
		dispatch_resume(self.dispatchSource);
		self.timerRunning = YES;
		[sender setTitle:@"Stop" forState:UIControlStateNormal];
	}
}

- (void)advanceDate {
	NSDate *date = self.datePicker.date;
	NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *comps = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:date];
	[comps setMinute:comps.minute+1];
	NSLog(@"self.datePicker is %@", self.datePicker);
	[self.datePicker setDate:[calendar dateFromComponents:comps] animated:YES];
	[self updateTweetFilter];
}
@end

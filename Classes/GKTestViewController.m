/*
 * Copyright 2011 shrtlist.com
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "GKTestViewController.h"
#import "GKTestAppDelegate.h"

@interface GKTestViewController () // Class extension
- (NSArray *)getAvailablePeers;
- (NSArray *)getConnectedPeers;
@end

@implementation GKTestViewController

@synthesize gkSession;
@synthesize peerTableView;
@synthesize navBar;

#pragma mark - Initialization and teardown

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];

	navBar.topItem.title = gkSession.displayName;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
	GKTestAppDelegate *appDelegate = (GKTestAppDelegate *)[[UIApplication sharedApplication] delegate];
	self.gkSession = appDelegate.gkSession;
}

- (void)viewDidUnload
{
	// Release any retained subviews of the main view.
	self.navBar = nil;
	
	[super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    }
    else
    {
        return YES;
    }
}

#pragma mark - GKSessionDelegate protocol methods

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state
{	
	switch (state)
	{
		case GKPeerStateAvailable:
			NSLog(@"didChangeState: peer %@ available", [session displayNameForPeer:peerID]);
            
            [NSThread sleepForTimeInterval:0.5];
            
			[session connectToPeer:peerID withTimeout:5];
			break;
			
		case GKPeerStateUnavailable:
			NSLog(@"didChangeState: peer %@ unavailable", [session displayNameForPeer:peerID]);
			break;
			
		case GKPeerStateConnected:
			NSLog(@"didChangeState: peer %@ connected", [session displayNameForPeer:peerID]);
			break;
			
		case GKPeerStateDisconnected:
			NSLog(@"didChangeState: peer %@ disconnected", [session displayNameForPeer:peerID]);
			break;
			
		case GKPeerStateConnecting:
			NSLog(@"didChangeState: peer %@ connecting", [session displayNameForPeer:peerID]);
			break;
	}
	
	[peerTableView reloadData];
}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID
{
	NSLog(@"didReceiveConnectionRequestFromPeer: %@", [session displayNameForPeer:peerID]);

	[session acceptConnectionFromPeer:peerID error:nil];
}

- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error
{
	NSLog(@"connectionWithPeerFailed: session: %@ peer: %@, error: %@", session, [session displayNameForPeer:peerID], error);
}

- (void)session:(GKSession *)session didFailWithError:(NSError *)error
{
	NSLog(@"didFailWithError: session: %@, error: %@", session, error);
	
	[session disconnectFromAllPeers];
}

#pragma mark - UITableViewDataSource protocol methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{    
    NSString *headerTitle = nil;

    switch (section) {
        case 0:
            headerTitle = @"GKSession Connected Peers";
            break;
            
        case 1:
            headerTitle = @"GKSession Available Peers";
            break;
    }
	
	return headerTitle;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section
{
    NSInteger rowsInSection;

    switch (section) {
        case 0:
        {
            NSArray *peers = [self getConnectedPeers];
            rowsInSection = peers.count;
            break;
        }   
        case 1:
        {
            NSArray *peers = [self getAvailablePeers];
            rowsInSection = peers.count;
            break;
        }
    }

	return rowsInSection;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *kCellIdentifier = @"Cell";
	
    NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
	
	if (cell == nil)
    {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifier];
	}

	NSArray *peers = nil;

    if (section == 0) {
        peers = [self getConnectedPeers];
    }
    else
    {
        peers = [self getAvailablePeers];
    }
    
	NSString *peerID = [peers objectAtIndex:row];
	
	if (peerID)
    {
		cell.textLabel.text = [gkSession displayNameForPeer:peerID];
	}
	
	return cell;
}

#pragma mark - Get available and connected peers

- (NSArray *)getAvailablePeers
{    
	return [gkSession peersWithConnectionState:GKPeerStateAvailable];
}

- (NSArray *)getConnectedPeers
{
	return [gkSession peersWithConnectionState:GKPeerStateConnected];
}

@end
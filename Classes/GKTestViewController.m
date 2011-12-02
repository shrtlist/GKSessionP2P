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
- (NSArray *)getConnectedPeers;
@end

@implementation GKTestViewController

@synthesize navBar;
@synthesize peerTableView;

#pragma mark - Initialization and teardown

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
	
	GKTestAppDelegate *appDelegate = (GKTestAppDelegate *)[[UIApplication sharedApplication] delegate];
	GKSession *gkSession = appDelegate.gkSession;
	
	navBar.topItem.title = gkSession.displayName;
}

- (void)viewDidUnload
{
	// Release any retained subviews of the main view.
	self.peerTableView = nil;
	self.navBar = nil;
	
	[super viewDidUnload];
}

#pragma mark - GKSessionDelegate protocol methods

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state
{	
	switch (state)
	{
		case GKPeerStateAvailable:
			NSLog(@"didChangeState: peer %@ available", [session displayNameForPeer:peerID]);
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
	return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	
	return @"GKSession Connected Peers";
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section
{	
	NSArray *peers = [self getConnectedPeers];
	return peers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *kCellIdentifier = @"Cell";
	
	NSInteger row = [indexPath row];
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
	
	if (cell == nil)
    {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifier];
	}
	
	NSArray *peers = [self getConnectedPeers];
	NSString *peerID = [peers objectAtIndex:row];
	
	if (peerID)
    {
		GKTestAppDelegate *appDelegate = (GKTestAppDelegate *)[[UIApplication sharedApplication] delegate];
		GKSession *gkSession = appDelegate.gkSession;
		
		cell.textLabel.text = [gkSession displayNameForPeer:peerID];
	}
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	return cell;
}

#pragma mark - Get connected peers

- (NSArray *)getConnectedPeers
{
	GKTestAppDelegate *appDelegate = (GKTestAppDelegate *)[[UIApplication sharedApplication] delegate];
	GKSession *gkSession = appDelegate.gkSession;

	return [gkSession peersWithConnectionState:GKPeerStateConnected];
}

@end
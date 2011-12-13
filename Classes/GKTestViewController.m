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

@implementation GKTestViewController

@synthesize gkSession;

#pragma mark - GKSession setup and teardown

- (void)setupSession
{
    self.gkSession = [[GKSession alloc] initWithSessionID:nil displayName:nil sessionMode:GKSessionModePeer];
    gkSession.delegate = self;
    gkSession.disconnectTimeout = 5;
    gkSession.available = YES;
    
    self.navigationItem.title = [NSString stringWithFormat:@"GKSession: %@", gkSession.displayName];
}

- (void)teardownSession
{
    gkSession.available = NO;
    gkSession.delegate = nil;
    [gkSession disconnectFromAllPeers];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupSession];
    
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];

    [defaultCenter addObserver:self 
                      selector:@selector(setupSession) 
                          name:UIApplicationWillEnterForegroundNotification
                        object:nil];

    [defaultCenter addObserver:self 
                      selector:@selector(teardownSession) 
                          name:UIApplicationDidEnterBackgroundNotification 
                        object:nil];
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

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
	
	[self.tableView reloadData];
}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID
{
	NSLog(@"didReceiveConnectionRequestFromPeer: %@", [session displayNameForPeer:peerID]);

    [session acceptConnectionFromPeer:peerID error:nil];
	
	[self.tableView reloadData];
}

- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error
{
	NSLog(@"connectionWithPeerFailed: peer: %@, error: %@", [session displayNameForPeer:peerID], error);
	
	[self.tableView reloadData];
}

- (void)session:(GKSession *)session didFailWithError:(NSError *)error
{
	NSLog(@"didFailWithError: error: %@", error);
	
	[session disconnectFromAllPeers];
	
	[self.tableView reloadData];
}

#pragma mark - UITableViewDataSource protocol methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 5;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{    
    NSString *headerTitle = nil;
    
    NSInteger state = section;

    switch (state) {
        case GKPeerStateAvailable:
            headerTitle = @"Available Peers";
            break;
            
        case GKPeerStateConnecting:
            headerTitle = @"Connecting Peers";
            break;

        case GKPeerStateConnected:
            headerTitle = @"Connected Peers";
            break;
            
        case GKPeerStateDisconnected:
            headerTitle = @"Disconnected Peers";
            break;
            
        case GKPeerStateUnavailable:
            headerTitle = @"Unavailable Peers";
            break;
    }
	
	return headerTitle;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section
{
    // Always show at least 1 row.
    NSInteger rows = 1;
    
    NSArray *peers = nil;

    NSInteger state = section;

    switch (state) {
        case GKPeerStateAvailable:
            peers = [gkSession peersWithConnectionState:GKPeerStateAvailable];
            break;

        case GKPeerStateConnecting:
            peers = [gkSession peersWithConnectionState:GKPeerStateConnecting];
            break;
            
        case GKPeerStateConnected:
            peers = [gkSession peersWithConnectionState:GKPeerStateConnected];
            break;
            
        case GKPeerStateDisconnected:
            peers = [gkSession peersWithConnectionState:GKPeerStateDisconnected];
            break;
            
        case GKPeerStateUnavailable:
            peers = [gkSession peersWithConnectionState:GKPeerStateUnavailable];
            break;
    }
    
    if (peers.count > 0) {
        rows = peers.count;
    }

	return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *kCellIdentifier = @"Cell";
	
    NSInteger state = [indexPath section];
	NSInteger row = [indexPath row];
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
	
	if (cell == nil)
    {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifier];
	}

	NSArray *peers = nil;

    switch (state) {
        case GKPeerStateAvailable:
            peers = [gkSession peersWithConnectionState:GKPeerStateAvailable];
            break;
            
        case GKPeerStateConnecting:
            peers = [gkSession peersWithConnectionState:GKPeerStateConnecting];
            break;
            
        case GKPeerStateConnected:
            peers = [gkSession peersWithConnectionState:GKPeerStateConnected];
            break;
            
        case GKPeerStateDisconnected:
            peers = [gkSession peersWithConnectionState:GKPeerStateDisconnected];
            break;
            
        case GKPeerStateUnavailable:
            peers = [gkSession peersWithConnectionState:GKPeerStateUnavailable];
            break;
    }
    
    if (peers.count > 0)
    {
        NSString *peerID = [peers objectAtIndex:row];
        
        if (peerID)
        {
            cell.textLabel.text = [gkSession displayNameForPeer:peerID];
        }
    }
    else
    {
        cell.textLabel.text = @"None";
    }
	
	return cell;
}

@end
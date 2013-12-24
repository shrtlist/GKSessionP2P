/*
 * Copyright 2013 shrtlist.com
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

@implementation GKTestViewController
{
    GKSession *_session;
}

// Non-global constants
static NSTimeInterval const kConnectionTimeout = 30.0;
static NSTimeInterval const kDisconnectTimeout = 5.0;
static NSString *const kSectionFooterTitle = @"Note that states are not mutually exclusive. For example, a peer can be available for other peers to discover while it is attempting to connect to another peer.";

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];

    // Register for notifications
    [defaultCenter addObserver:self 
                      selector:@selector(setupSession) 
                          name:UIApplicationWillEnterForegroundNotification
                        object:nil];

    [defaultCenter addObserver:self 
                      selector:@selector(teardownSession) 
                          name:UIApplicationDidEnterBackgroundNotification
                        object:nil];
    
    [self setupSession];

    self.title = [NSString stringWithFormat:@"GKSession: %@", _session.displayName];
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

#pragma mark - Memory management

- (void)dealloc
{
    // Unregister for notifications on deallocation.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // Nil out delegate
    _session.delegate = nil;
}

#pragma mark - GKSession setup and teardown

- (void)setupSession
{
    // GKSessionModePeer: a peer advertises like a server and searches like a client.
    _session = [[GKSession alloc] initWithSessionID:nil displayName:nil sessionMode:GKSessionModePeer];
    _session.delegate = self;
    _session.disconnectTimeout = kDisconnectTimeout;
    _session.available = YES;
}

- (void)teardownSession
{
    _session.available = NO;
    [_session disconnectFromAllPeers];
}

#pragma mark - GKSessionDelegate protocol conformance

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state
{
    NSString *peerName = [session displayNameForPeer:peerID];

	switch (state)
	{
		case GKPeerStateAvailable:
        {
			NSLog(@"didChangeState: peer %@ available", peerName);
            
            BOOL shouldInvite = ([_session.peerID hash] > [peerID hash]);
            
            if (shouldInvite)
            {
                NSLog(@"Inviting %@", peerID);
                [session connectToPeer:peerID withTimeout:kConnectionTimeout];
            }
            else
            {
                NSLog(@"Not inviting %@", peerID);
            }
            
			break;
        }
			
		case GKPeerStateUnavailable:
        {
			NSLog(@"didChangeState: peer %@ unavailable", peerName);
			break;
        }
			
		case GKPeerStateConnected:
        {
			NSLog(@"didChangeState: peer %@ connected", peerName);
			break;
        }
			
		case GKPeerStateDisconnected:
        {
			NSLog(@"didChangeState: peer %@ disconnected", peerName);
			break;
        }
			
		case GKPeerStateConnecting:
        {
			NSLog(@"didChangeState: peer %@ connecting", peerName);
			break;
        }
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

#pragma mark - UITableViewDataSource protocol conformance

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // We have 5 sections in our grouped table view,
    // one for each GKPeerConnectionState
	return 5;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section
{
    NSInteger rows = 0;
    
    NSInteger peerConnectionState = section;
    
    switch (peerConnectionState)
    {
        case GKPeerStateAvailable:
        {
            NSArray *availablePeers = [_session peersWithConnectionState:GKPeerStateAvailable];
            rows = availablePeers.count;
            break;
        }

        case GKPeerStateConnecting:
        {
            NSArray *connectingPeers = [_session peersWithConnectionState:GKPeerStateConnecting];
            rows = connectingPeers.count;
            break;
        }
            
        case GKPeerStateConnected:
        {
            NSArray *connectedPeers = [_session peersWithConnectionState:GKPeerStateConnected];
            rows = connectedPeers.count;
            break;
        }
            
        case GKPeerStateDisconnected:
        {
            NSArray *disconnectedPeers = [_session peersWithConnectionState:GKPeerStateDisconnected];
            rows = disconnectedPeers.count;
            break;
        }
            
        case GKPeerStateUnavailable:
        {
            NSArray *unavailablePeers = [_session peersWithConnectionState:GKPeerStateUnavailable];
            rows = unavailablePeers.count;
            break;
        }
    }
    
    // Always show at least 1 row for each GKPeerConnectionState.
    if (rows < 1)
    {
        rows = 1;
    }
    
	return rows;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{    
    NSString *headerTitle = nil;
    
    NSInteger peerConnectionState = section;

    switch (peerConnectionState)
    {
        case GKPeerStateAvailable:
        {
            headerTitle = @"Available Peers";
            break;
        }
            
        case GKPeerStateConnecting:
        {
            headerTitle = @"Connecting Peers";
            break;
        }

        case GKPeerStateConnected:
        {
            headerTitle = @"Connected Peers";
            break;
        }

        case GKPeerStateDisconnected:
        {
            headerTitle = @"Disconnected Peers";
            break;
        }
            
        case GKPeerStateUnavailable:
        {
            headerTitle = @"Unavailable Peers";
            break;
        }
    }
	
	return headerTitle;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    cell.textLabel.text = @"None";
	
    NSInteger peerConnectionState = indexPath.section;

	NSArray *peers = nil;

    switch (peerConnectionState)
    {
        case GKPeerStateAvailable:
        {
            peers = [_session peersWithConnectionState:GKPeerStateAvailable];
            break;
        }
            
        case GKPeerStateConnecting:
        {
            peers = [_session peersWithConnectionState:GKPeerStateConnecting];
            break;
        }
            
        case GKPeerStateConnected:
        {
            peers = [_session peersWithConnectionState:GKPeerStateConnected];
            break;
        }
            
        case GKPeerStateDisconnected:
        {
            peers = [_session peersWithConnectionState:GKPeerStateDisconnected];
            break;
        }
            
        case GKPeerStateUnavailable:
        {
            peers = [_session peersWithConnectionState:GKPeerStateUnavailable];
            break;
        }
    }

	NSInteger peerIndex = indexPath.row;
    
    if ((peers.count > 0) && (peerIndex < peers.count))
    {
        NSString *peerID = [peers objectAtIndex:peerIndex];
        
        if (peerID)
        {
            cell.textLabel.text = [_session displayNameForPeer:peerID];
        }
    }
	
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSString *title = nil;

    if (section == GKPeerStateConnecting)
    {
        title = kSectionFooterTitle;
    }
    
    return title;
}

@end

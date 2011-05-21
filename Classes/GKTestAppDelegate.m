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

#import "GKTestAppDelegate.h"
#import "GKTestViewController.h"

@interface GKTestAppDelegate ()

- (void)sendData:(NSString *)string;

@end


@implementation GKTestAppDelegate

@synthesize window;
@synthesize gkViewController;
@synthesize gkSession;


#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{        
    // Override point for customization after application launch.
	gkSession = [[GKSession alloc] initWithSessionID:nil displayName:nil sessionMode:GKSessionModePeer];
	gkSession.delegate = gkViewController;
	[gkSession setDataReceiveHandler:self withContext:nil];
	[gkSession setDisconnectTimeout:20];
	gkSession.available = YES;
	
	[self.window addSubview:gkViewController.view];
    [self.window makeKeyAndVisible];

    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	[gkSession disconnectFromAllPeers];
	gkSession.available = NO;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	gkSession.available = YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	[gkSession disconnectFromAllPeers];
	gkSession.available = NO;
	[gkSession setDataReceiveHandler:nil withContext:nil];
	gkSession.delegate = nil;
	[gkSession release];
}

- (void)dealloc
{
	gkSession.delegate = nil;
	[gkSession release];
    [gkViewController release];
    [window release];

    [super dealloc];
}

#pragma mark -
#pragma mark GKSession data handler methods

- (void)sendData:(NSString *)string
{
	NSData *data = [NSData dataWithBytes:[string UTF8String] length:[string length]];
	GKSessionMode mode = GKSessionModePeer;
	NSError *error = nil;
	
	[gkSession sendDataToAllPeers:(NSData *)data withDataMode:mode error:&error];
}

- (void)receiveData:(NSData *)data fromPeer:(NSString *)peer inSession: (GKSession *)session context:(void *)context
{
	NSString *string = [NSString stringWithUTF8String:[data bytes]];
	NSLog(@"receiveData from peer %@, string = %@", [session displayNameForPeer:peer], string);
}

@end
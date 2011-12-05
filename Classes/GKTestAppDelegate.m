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

@implementation GKTestAppDelegate

@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    // Override point for customization after application launch.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        window.rootViewController = [[GKTestViewController alloc] initWithNibName:@"GKTestViewController_iPhone" bundle:nil];
    }
    else
    {
        window.rootViewController = [[GKTestViewController alloc] initWithNibName:@"GKTestViewController_iPad" bundle:nil];
    }

    [window makeKeyAndVisible];

    return YES;
}

@end
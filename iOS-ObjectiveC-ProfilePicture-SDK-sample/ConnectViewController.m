/*
 * Copyright (c) Microsoft. All rights reserved. Licensed under the MIT license.
 * See LICENSE in the project root for license information.
 */

#import "AuthenticationConstants.h"
#import "AuthenticationProvider.h"
#import "ConnectViewController.h"
#import "ProfilePictureController.h"
#import <MSGraphSDK-NXOAuth2Adapter/MSGraphSDKNXOAuth2.h>

@interface ConnectViewController ()

@property (strong, nonatomic) IBOutlet UINavigationItem *appTitle;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) IBOutlet UIButton *connectButton;
@property (strong, nonatomic) AuthenticationProvider *authProvider;

@end

@implementation ConnectViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    _authProvider = [[AuthenticationProvider alloc]init];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
}

#pragma mark - button interaction (Connect)
- (IBAction)connectTapped:(id)sender {
    
    NSArray *scopes = [kScopes componentsSeparatedByString:@","];
    [self.authProvider connectToGraphWithClientId:kClientId scopes:scopes completion:^(NSError *error) {
        if (!error) {
            [self performSegueWithIdentifier:@"showProfileController" sender:nil];
            NSLog(@"Authentication successful.");
        }
        else{
            NSLog(@"%@", error.localizedDescription);
        };
    }];
}


#pragma mark - Navigation
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showProfileController"]){
        
        ProfilePictureController *profilePictureController = segue.destinationViewController;
        profilePictureController.authenticationProvider = self.authProvider;
    }
}





@end

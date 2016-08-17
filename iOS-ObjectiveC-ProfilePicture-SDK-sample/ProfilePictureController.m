/*
 * Copyright (c) Microsoft. All rights reserved. Licensed under the MIT license.
 * See LICENSE in the project root for license information.
 */

#import "AuthenticationProvider.h"
#import "ProfilePictureController.h"
#import <CoreGraphics/CoreGraphics.h>
#import <MSGraphSDK/MSGraphSDK.h>

@interface ProfilePictureController ()
@property (strong, nonatomic) MSGraphClient *graphClient;
@property (strong, nonatomic) IBOutlet UIImageView *profilePictureImage;
@property (strong, nonatomic) IBOutlet UITextView *responseTextField;
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet UIButton *cropButton;
@property (strong, nonatomic) IBOutlet UIButton *uploadButton;

@end

@implementation ProfilePictureController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [MSGraphClient setAuthenticationProvider:self.authenticationProvider.authProvider];
    self.graphClient = [MSGraphClient client];
    
    [self.cropButton setEnabled:false];
    [self.uploadButton setEnabled:false];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - App Actions

- (IBAction)retrievePhoto:(id)sender {
    [self getProfilePicture];
    [self getPhotoMetadata];
}

- (IBAction)cropPhoto:(id)sender {
    [self cropImage];
}

- (IBAction)updatePhoto:(id)sender {
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Upload"
                                                                   message:@"This will replace your current profile picture."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Upload"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                [self uploadPhoto];
                                            }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * action) {
                                                [alert dismissViewControllerAnimated:YES completion:nil];
                                            }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)disconnect:(id)sender {
    [self.authenticationProvider disconnect];
    [self.navigationController popViewControllerAnimated:true];
}


#pragma mark - Microsoft Graph Photo Operations

// Gets the signed-in user's photo if they have a photo in Office 365.
// GET /me/photo/$value

- (void)getProfilePicture {
    [[[self.graphClient me] photoValue] downloadWithCompletion:^(NSURL *location, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"%@", error.localizedDescription);
            dispatch_async(dispatch_get_main_queue(), ^{
                self.statusLabel.text = @"Error getting picture. See log for more details.";
            });
        }
        else {
            NSData *pictureData = [NSData dataWithContentsOfURL:location];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.profilePictureImage.image = [UIImage imageWithData:pictureData];
                self.statusLabel.text = @"Photo retrieved.";
                
                if (self.profilePictureImage.image !=nil) {
                    [self.cropButton setEnabled:true];
                    [self.uploadButton setEnabled:true];
                }
            });
        }
    }];
}

// Gets the signed-in user's photo data if they have a photo (height and width).
// GET /me/photo

- (void)getPhotoMetadata {
    [[[[self.graphClient me] photo] request] getWithCompletion:^(MSGraphProfilePhoto *response, NSError *error) {
        
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.statusLabel.text = @"Error retrieving photo metadata. See log for more details.";
            });
        }
        else {
            NSString *responseString = [NSString stringWithFormat:@"Photo metadata: The photo size is %d x %d", response.height, response.width];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.responseTextField.text = responseString;
            });
        }
    }];
}

// Uploads signed-in user's photo.
- (void)uploadPhoto {
    NSData *croppedImage = UIImagePNGRepresentation(self.profilePictureImage.image);
    [[[self.graphClient me] photoValue] uploadFromData:croppedImage completion:^(MSGraphProfilePhoto *response, NSError *error) {
        if (error) {
            NSLog(@"%@", error.localizedDescription);
            dispatch_async(dispatch_get_main_queue(), ^{
                self.statusLabel.text = @"Error uploading picture. See log for more details.";
            });
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.statusLabel.text = @"Upload successful.";
            });
        }
    }];
}

#pragma mark - Helper methods

// Helper method that crops the selected profile picture.
- (void)cropImage {
    UIImage *imageToCrop = self.profilePictureImage.image;
    CGRect croppedSection = CGRectMake(imageToCrop.size.width /4, imageToCrop.size.height
                                       /4, (imageToCrop.size.width /2), (imageToCrop.size.height /2));
    
    CGImageRef imageRef  = CGImageCreateWithImageInRect([imageToCrop CGImage], croppedSection);
    UIImage *croppedImage  = [UIImage imageWithCGImage:imageRef];
    self.profilePictureImage.image = croppedImage;
    CGImageRelease(imageRef);
    self.statusLabel.text = @"Photo cropped.";
}

@end

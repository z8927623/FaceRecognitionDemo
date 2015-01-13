//
//  PhotoCollectionViewController.m
//  FaceRecognitionDemo
//
//  Created by wildyao on 15/1/12.
//  Copyright (c) 2015年 Wild Yaoyao. All rights reserved.
//

@import AssetsLibrary;

#import "PhotoCollectionViewController.h"
#import "PhotoDetailViewController.h"
#import "ELCImagePickerController.h"

static const NSInteger kCellImageViewTag = 3;
static const CGFloat kBackgroundImageOpacity = 0.1f;

@interface PhotoCollectionViewController () <ELCImagePickerControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) ALAssetsLibrary *library;

@end

@implementation PhotoCollectionViewController

static NSString * const reuseIdentifier = @"photoCell";

#pragma mark - LifeCycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.library = [[ALAssetsLibrary alloc] init];
    
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background"]];
    backgroundImageView.alpha = kBackgroundImageOpacity;
    backgroundImageView.contentMode = UIViewContentModeCenter;
    [self.collectionView setBackgroundView:backgroundImageView];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contentChangedNotification:)
                                                 name:kPhotoManagerContentUpdateNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contentChangedNotification:) name:kPhotoManagerAddedContentNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self showOrHideNavPrompt];
}

- (void)contentChangedNotification:(NSNotification *)notification
{
    [self.collectionView reloadData];
    [self showOrHideNavPrompt];
}

- (void)showOrHideNavPrompt
{
    NSUInteger count = [PhotoManager sharedManager].photos.count;
                        
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        if (!count) {
            [self.navigationItem setPrompt:@"Add photos with faces!"];
        } else {
            [self.navigationItem setPrompt:nil];
        }
    });
}

- (IBAction)addPhotoAssets:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Get Photos From:" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Photo Library", @"Internet", nil];
    [actionSheet showInView:self.view];
}

- (void)downloadImageAssets
{
    [[PhotoManager sharedManager] downloadPhotosWithCompletionBlock:^(NSError *error) {
        NSString *message = error ? [error localizedDescription] : @"The images have finished downloading";
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Download Complete"
                                                            message:message
                                                           delegate:nil
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil, nil];
        [alertView show];
    }];
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    static const NSInteger kButtonIndexPhotoLibrary = 0;
    static const NSInteger kButtonIndexInternet = 1;
    if (buttonIndex == kButtonIndexPhotoLibrary) {
        ELCImagePickerController *imagePickerController = [[ELCImagePickerController alloc] init];
        [imagePickerController setImagePickerDelegate:self];
        [self presentViewController:imagePickerController animated:YES completion:nil];
    } else if (buttonIndex == kButtonIndexInternet) {
        [self downloadImageAssets];
    }
}

#pragma mark - elcImagePickerControllerDelegate
- (void)elcImagePickerController:(ELCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info
{
    for (NSDictionary *dictionary in info) {
        [self.library assetForURL:dictionary[UIImagePickerControllerReferenceURL] resultBlock:^(ALAsset *asset) {
            
            Photo *photo = [[Photo alloc] initWithAsset:asset];
            [[PhotoManager sharedManager] addPhoto:photo];
             
        } failureBlock:^(NSError *error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Permission Denied"
                                                            message:@"To access your photos, please change the permissions in Settings"
                                                           delegate:nil
                                                  cancelButtonTitle:@"ok"
                                                  otherButtonTitles:nil, nil];
            [alert show];
        }];
    }
 
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger count = [PhotoManager sharedManager].photos.count;
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:kCellImageViewTag];
    NSArray *photosAssets = [[PhotoManager sharedManager] photos];
    Photo *photo = photosAssets[indexPath.row];
    
    switch (photo.status) {
        case PhotoStatusGoodToGo:
            imageView.image = [photo thumbnail];
            break;
        case PhotoStatusDownloading:
            imageView.image = [UIImage imageNamed:@"photoDownloading"];
            break;
        case PhotoStatusFailed:
            imageView.image = [UIImage imageNamed:@"photoDownloadError"];
            break;
        default:
            break;
    }
    
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *photos = [[PhotoManager sharedManager] photos];
    Photo *photo = photos[indexPath.row];
    
    switch (photo.status) {
        case PhotoStatusGoodToGo:
        {
            UIImage *image = [photo image];
            PhotoDetailViewController *photoDetailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PhotoDetailViewController"];
            [photoDetailViewController setupWithImage:image];
            [self.navigationController pushViewController:photoDetailViewController animated:YES];
        }
            break;
        case PhotoStatusDownloading:
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Downloading"
                                                            message:@"The image is currently downloading"
                                                           delegate:nil
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil, nil];
            [alert show];
        }
            break;
        case PhotoStatusFailed:
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Image Failed"
                                                            message:@"The image failed to be created"
                                                           delegate:nil
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil, nil];
            [alert show];
        }
            break;
        default:
            break;
    }
}

@end

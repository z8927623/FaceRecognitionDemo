//
//  Photo.m
//  FaceRecognitionDemo
//
//  Created by wildyao on 15/1/12.
//  Copyright (c) 2015年 Wild Yaoyao. All rights reserved.
//

@import AssetsLibrary;
#import "Photo.h"
#import "UIImage+Resize.h"

// ************************************
#pragma mark - Private Class AssetPhoto
// ************************************

@interface AssetPhoto : Photo
@property (nonatomic, strong) ALAsset *asset;
@end

@implementation AssetPhoto

- (UIImage *)thumbnail
{
    UIImage *thumbnail = [UIImage imageWithCGImage:[self.asset thumbnail]];
    return thumbnail;
}

- (UIImage *)image
{
    ALAssetRepresentation *representation = [self.asset defaultRepresentation];
    UIImage *image = [UIImage imageWithCGImage:[representation fullScreenImage]];
    return image;
}

- (PhotoStatus)status
{
    return PhotoStatusGoodToGo;
}

@end


// ************************************
#pragma mark - Private Class DownloadPhoto
// ************************************

@interface DownloadPhoto : Photo
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) UIImage *thumbnail;
@end

@implementation DownloadPhoto

@synthesize status = _status;

- (void)downloadImageWithCompletion:(void (^)(UIImage *image, NSError *error))completionBlock
{
    static NSURLSession *session;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        session = [NSURLSession sessionWithConfiguration:configuration];
    });

    NSURLSessionDataTask *task = [session dataTaskWithURL:self.url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        self.image = [UIImage imageWithData:data];
        if (!error && _image) {
            _status = PhotoStatusGoodToGo;
        } else {
            _status = PhotoStatusFailed;
        }
        
        self.thumbnail = [_image thumbnailImage:64 transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationDefault];
        
        if (completionBlock) {
            completionBlock(_image, error);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // 每次下载完一张照片后发布通知，用于更新collectionView
            NSNotification *notification = [NSNotification notificationWithName:kPhotoManagerContentUpdateNotification object:nil];
            // 消息队列，异步方式
            // 添加消息到队列中
            [[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle:NSPostASAP coalesceMask:NSNotificationCoalescingOnName forModes:nil];
        });
        
        /*
        1:NSNotification同步通知，发送者要在所有监听者接收处理之后才会继续执行接下来任务，可能造成一定等待延迟。
        2:NSNOtificationQueue异步通知:NSNOtificationQueue看做像一个通知中心实例的缓冲区,被通知中心放进通知队列里面发送的通知会延迟到当前在runloop中运行的发送的通知结束或者run loop闲置。
        */
    }];
    
    [task resume];
}

- (PhotoStatus)status
{
    return _status;
}

- (UIImage *)image
{
    return _image;
}

- (UIImage *)thumbnail
{
    return _thumbnail;
}

@end


@interface Photo ()
@property (nonatomic, assign) PhotoStatus status;
@end

@implementation Photo

- (instancetype)initWithAsset:(ALAsset *)asset
{
    NSAssert(asset, @"Asset is nil");
    AssetPhoto *assetPhoto;
    assetPhoto = [[AssetPhoto alloc] init];
    if (assetPhoto) {
        assetPhoto.asset = asset;
        assetPhoto.status = PhotoStatusGoodToGo;
    }
    return assetPhoto;
}

- (instancetype)initWithURL:(NSURL *)url
{
    NSAssert(url, @"URL is nil");
    DownloadPhoto *downloadPhoto;
    downloadPhoto = [[DownloadPhoto alloc] init];
    if (downloadPhoto) {
        downloadPhoto.status = PhotoStatusDownloading;
        downloadPhoto.url = url;
        [downloadPhoto downloadImageWithCompletion:nil];
    }
    return downloadPhoto;
}

- (instancetype)initWithURL:(NSURL *)url withCompletionBlock:(void (^)(UIImage *image, NSError *error))completionBlock
{
    NSAssert(url, @"URL is nil");
    DownloadPhoto *downloadPhoto;
    downloadPhoto = [[DownloadPhoto alloc] init];
    if (downloadPhoto) {
        downloadPhoto.status = PhotoStatusDownloading;
        downloadPhoto.url = url;
        [downloadPhoto downloadImageWithCompletion:[completionBlock copy]];
    }
    return downloadPhoto;
}

- (PhotoStatus)status
{
    NSAssert(NO, @"Use One of Photo's public initializer methods");
    return PhotoStatusFailed;
}

- (UIImage *)image
{
    NSAssert(NO, @"Use One of Photo's public initializer methods");
    return nil;
}

- (UIImage *)thumbnail
{
    NSAssert(NO, @"Use One of Photo's public initializer methods");
    return nil;
}


@end

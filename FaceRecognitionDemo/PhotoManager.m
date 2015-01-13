//
//  PhotoManager.m
//  FaceRecognitionDemo
//
//  Created by wildyao on 15/1/12.
//  Copyright (c) 2015年 Wild Yaoyao. All rights reserved.
//

#import "PhotoManager.h"

@interface PhotoManager ()

@property (nonatomic, strong) NSMutableArray *photosArray;
@property (nonatomic, strong) dispatch_queue_t concurrentPhotoQueue;

@end

@implementation PhotoManager

+ (instancetype)sharedManager
{
    static PhotoManager *sharedPhotoManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedPhotoManager = [[PhotoManager alloc] init];
        sharedPhotoManager->_photosArray = [NSMutableArray array];
        sharedPhotoManager->_concurrentPhotoQueue = dispatch_queue_create("com.FaceRecognitionDemo.photoQueue", DISPATCH_QUEUE_CONCURRENT);
    });
    
    return sharedPhotoManager;
}

- (NSArray *)photos
{
    __block NSArray *array;
    dispatch_sync(self.concurrentPhotoQueue, ^{
        array = _photosArray;
    });
    return array;
}

- (void)addPhoto:(Photo *)photo
{
    if (photo) {
        dispatch_barrier_async(self.concurrentPhotoQueue, ^{
            [_photosArray addObject:photo];
            dispatch_async(dispatch_get_main_queue(), ^{
                // 添加一张照片后发布通知，用于更新collectionView
                [self postContentAddedNotification];
            });
        });
    }
}

- (void)downloadPhotosWithCompletionBlock:(void (^)(NSError *error))completionBlock
{
    // 下载一组图片
    __block NSError *error;
    dispatch_group_t downloadGroup = dispatch_group_create();
    
//    for (NSInteger i = 0; i < 3; i++) {
    
    // 并发执行循环，任务运行队列为全局队列
    // 图片次序会乱
    dispatch_apply(3, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t i) {
        
        NSURL *url;
        switch (i) {
            case 0:
                url = [NSURL URLWithString:kOverlyAttachedGirlfriendURLString];
                break;
            case 1:
                url = [NSURL URLWithString:kSuccessKidURLString];
                break;
            case 2:
                url = [NSURL URLWithString:kLotsOfFacesURLString];
                break;
            default:
                break;
        }
        
        dispatch_group_enter(downloadGroup);
        
        Photo *photo = [[Photo alloc] initWithURL:url withCompletionBlock:^(UIImage *image, NSError *_error) {
            if (_error) {
                error = _error;
            }
            dispatch_group_leave(downloadGroup);
        }];
        
        [[PhotoManager sharedManager] addPhoto:photo];
    });

//    }
    
    // 待全部图片下载完成后再通知
    dispatch_group_notify(downloadGroup, dispatch_get_main_queue(), ^{
        if (completionBlock) {
            completionBlock(error);
        }
    });
}

- (void)postContentAddedNotification
{
    static NSNotification *notification = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        notification = [NSNotification notificationWithName:kPhotoManagerAddedContentNotification object:nil];
    });
    // 消息队列，异步方式
    // 添加消息到队列中
    [[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle:NSPostASAP coalesceMask:NSNotificationCoalescingOnName forModes:nil];
}

@end

//
//  Photo.h
//  FaceRecognitionDemo
//
//  Created by wildyao on 15/1/12.
//  Copyright (c) 2015年 Wild Yaoyao. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ALAsset;

typedef NS_ENUM(NSInteger, PhotoStatus) {
    PhotoStatusDownloading,
    PhotoStatusGoodToGo,
    PhotoStatusFailed,
};

@interface Photo : NSObject

@property (nonatomic, readonly, assign) PhotoStatus status;

- (UIImage *)image;

- (UIImage *)thumbnail;

- (instancetype)initWithAsset:(ALAsset *)asset;
- (instancetype)initWithURL:(NSURL *)url;
- (instancetype)initWithURL:(NSURL *)url withCompletionBlock:(void (^)(UIImage *image, NSError *error))completionBlock;

@end

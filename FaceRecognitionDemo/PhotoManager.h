//
//  PhotoManager.h
//  FaceRecognitionDemo
//
//  Created by wildyao on 15/1/12.
//  Copyright (c) 2015年 Wild Yaoyao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Photo.h"

@interface PhotoManager : NSObject

+ (instancetype)sharedManager;
- (NSArray *)photos;
- (void)addPhoto:(Photo *)photo;
- (void)downloadPhotosWithCompletionBlock:(void (^)(NSError *error))completionBlock;

@end

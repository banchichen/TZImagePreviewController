//
//  TZImagePreviewController.h
//  TZImagePreviewController
//
//  Created by 谭真 on 18/08/23.
//  Copyright © 2018年 谭真. All rights reserved.
//  version 0.5.0 - 2020.12.09
//  更多信息，请前往项目的github地址：https://github.com/banchichen/TZImagePreviewController

#import <UIKit/UIKit.h>
#import <TZImagePickerController/TZImagePickerController.h>

@interface TZImagePreviewController : UIViewController

/**
 Use this init method / 用这个初始化方法

 @param photos 所有图片数组，支持PHAsset、UIImage、NSURL对象
 @param currentIndex 用户点击的图片的索引
 @param tzImagePickerVc 必传，主要是为了读取一些配置
 @return 一个TZImagePreviewController实例
 */
- (instancetype)initWithPhotos:(NSArray *)photos currentIndex:(NSInteger)currentIndex tzImagePickerVc:(TZImagePickerController *)tzImagePickerVc;

/// 是否选择了原图
@property (nonatomic, assign) BOOL isSelectOriginalPhoto;

/// 传入的photos有NSURL对象时会触发，请使用你依赖的图片库给imageView设置图片
@property (nonatomic, copy) void (^setImageWithURLBlock)(NSURL *URL, UIImageView *imageView, void (^completion)(void));
/// 用户点击了返回按钮
@property (nonatomic, copy) void (^backButtonClickBlock)(BOOL isSelectOriginalPhoto);
/// 用户点击了完成按钮
@property (nonatomic, copy) void (^doneButtonClickBlock)(NSArray *photos,BOOL isSelectOriginalPhoto);

- (void)doneButtonClick;
@end

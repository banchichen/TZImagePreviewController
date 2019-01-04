# TZImagePreviewController
[![CocoaPods](https://img.shields.io/cocoapods/v/TZImagePreviewController.svg?style=flat)](https://github.com/banchichen/TZImagePreviewController)

Enhance the [TZImagePickerController](https://github.com/banchichen/TZImagePickerController) library, supports to preview photo by UIImage or NSURL and preview video by NSURL.     
对[TZImagePickerController](https://github.com/banchichen/TZImagePickerController)库的增强，支持用UIImage、NSURL预览照片和用NSURL预览视频。     

## 一. Installation 安装

#### CocoaPods
> pod 'TZImagePreviewController'

#### 手动安装
> 将TZImagePickerController文件夹拽入项目中，导入头文件：#import "TZImagePreviewController.h"

## 二. Example 例子

```objectivec
TZImagePreviewController *previewVc = [[TZImagePreviewController alloc] initWithPhotos:self.selectedPhotos currentIndex:indexPath.row tzImagePickerVc:[self createTZImagePickerController]];
[previewVc setBackButtonClickBlock:^(BOOL isSelectOriginalPhoto) {
    NSLog(@"back isSelectOriginalPhoto:%d", isSelectOriginalPhoto);
}];
[previewVc setSetImageWithURLBlock:^(NSURL *URL, UIImageView *imageView) {
    [imageView sd_setImageWithURL:URL];
}];
[previewVc setDoneButtonClickBlock:^(NSArray *photos, BOOL isSelectOriginalPhoto) {
    self.selectedPhotos = [NSMutableArray arrayWithArray:photos];
    NSLog(@"done isSelectOriginalPhoto:%d photos.count:%zd", isSelectOriginalPhoto, photos.count);
    [self.collectionView reloadData];
}];
[self presentViewController:previewVc animated:YES completion:nil];
```
  
## 三. Requirements 要求
   iOS 8 or later. Requires ARC         
   iOS8及以上系统可使用. ARC环境.         

## 四. More 更多 
   There is Demo inside, Please refer to Demo for usage.         
   内有Demo，请参考Demo进行使用。     

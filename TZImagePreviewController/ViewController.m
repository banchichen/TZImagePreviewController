//
//  ViewController.m
//  TZImagePickerController
//
//  Created by 谭真 on 15/12/24.
//  Copyright © 2015年 谭真. All rights reserved.
//

#import "ViewController.h"
#import "TZImagePickerController.h"
#import "UIView+Layout.h"
#import "TZTestCell.h"
#import <Photos/Photos.h>
#import "TZImageManager.h"
#import "TZAssetCell.h"
#import "TZImagePreviewController.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface ViewController ()<TZImagePickerControllerDelegate,UICollectionViewDataSource,UICollectionViewDelegate> {
    CGFloat _itemWH;
    CGFloat _margin;
}
@property (nonatomic, assign) BOOL isSelectOriginalPhoto;
@property (nonatomic, strong) NSMutableArray *selectedPhotos;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (strong, nonatomic) UICollectionViewFlowLayout *layout;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    _selectedPhotos = [NSMutableArray array];
    [self.selectedPhotos addObject:[UIImage imageNamed:@"photo_delete"]];
    [self.selectedPhotos addObject:[NSURL URLWithString:@"https://github.com/banchichen/TZImagePickerController/raw/master/TZImagePickerController/ScreenShots/photoPickerVc.PNG"]];
    [self configCollectionView];
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)configCollectionView {
    _layout = [[UICollectionViewFlowLayout alloc] init];
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:_layout];
    CGFloat rgb = 244 / 255.0;
    _collectionView.alwaysBounceVertical = YES;
    _collectionView.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:1.0];
    _collectionView.contentInset = UIEdgeInsetsMake(4, 4, 4, 4);
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.view addSubview:_collectionView];
    [_collectionView registerClass:[TZTestCell class] forCellWithReuseIdentifier:@"TZTestCell"];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    _margin = 4;
    _itemWH = (self.view.tz_width - 2 * _margin - 4) / 3 - _margin;
    _layout.itemSize = CGSizeMake(_itemWH, _itemWH);
    _layout.minimumInteritemSpacing = _margin;
    _layout.minimumLineSpacing = _margin;
    [self.collectionView setCollectionViewLayout:_layout];
    self.collectionView.frame = CGRectMake(0, 210, self.view.tz_width, self.view.tz_height - 210);
}

#pragma mark UICollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _selectedPhotos.count + 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TZTestCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TZTestCell" forIndexPath:indexPath];
    cell.videoImageView.hidden = YES;
    if (indexPath.item == _selectedPhotos.count) {
        cell.imageView.image = [UIImage imageNamed:@"AlbumAddBtn.png"];
        cell.deleteBtn.hidden = YES;
        cell.gifLable.hidden = YES;
    } else {
        id photo = _selectedPhotos[indexPath.item];
        if ([photo isKindOfClass:[UIImage class]]) {
            cell.imageView.image = photo;
        } else if ([photo isKindOfClass:[NSURL class]]) {
            [cell.imageView sd_setImageWithURL:(NSURL *)photo];
        } else if ([photo isKindOfClass:[PHAsset class]]) {
            [[TZImageManager manager] getPhotoWithAsset:photo photoWidth:100 completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
                cell.imageView.image = photo;
            }];
        }
        cell.asset = _selectedPhotos[indexPath.item];
        cell.deleteBtn.hidden = NO;
    }
    cell.deleteBtn.tag = indexPath.item;
    [cell.deleteBtn addTarget:self action:@selector(deleteBtnClik:) forControlEvents:UIControlEventTouchUpInside];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item == _selectedPhotos.count) { // 选择
        TZImagePickerController *imagePickerVc = [self createTZImagePickerController];
        imagePickerVc.isSelectOriginalPhoto = NO;
        [imagePickerVc setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets, BOOL isSelectOriginalPhoto) {
            [self.selectedPhotos addObjectsFromArray:assets];
            [self.collectionView reloadData];
        }];
        [self presentViewController:imagePickerVc animated:YES completion:nil];
    } else { // 预览
        TZImagePreviewController *previewVc = [[TZImagePreviewController alloc] initWithPhotos:self.selectedPhotos currentIndex:indexPath.row tzImagePickerVc:[self createTZImagePickerController]];
        [previewVc setBackButtonClickBlock:^(BOOL isSelectOriginalPhoto) {
            self.isSelectOriginalPhoto = isSelectOriginalPhoto;
            NSLog(@"预览页 返回 isSelectOriginalPhoto:%d", isSelectOriginalPhoto);
        }];
        [previewVc setSetImageWithURLBlock:^(NSURL *URL, UIImageView *imageView) {
            [imageView sd_setImageWithURL:URL];
        }];
        [previewVc setDoneButtonClickBlock:^(NSArray *photos, BOOL isSelectOriginalPhoto) {
            self.isSelectOriginalPhoto = isSelectOriginalPhoto;
            self.selectedPhotos = [NSMutableArray arrayWithArray:photos];
            NSLog(@"预览页 完成 isSelectOriginalPhoto:%d photos.count:%zd", isSelectOriginalPhoto, photos.count);
            [self.collectionView reloadData];
        }];
        [self presentViewController:previewVc animated:YES completion:nil];
    }
}

#pragma mark - TZImagePickerController

- (TZImagePickerController *)createTZImagePickerController {
    TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:9 columnNumber:4 delegate:self pushPhotoPickerVc:YES];
    
#pragma mark - 个性化设置，这些参数都可以不传，此时会走默认设置
    imagePickerVc.isSelectOriginalPhoto = _isSelectOriginalPhoto;

    // imagePickerVc.navigationBar.barTintColor = [UIColor greenColor];
    // imagePickerVc.oKButtonTitleColorDisabled = [UIColor lightGrayColor];
    // imagePickerVc.oKButtonTitleColorNormal = [UIColor greenColor];
    // imagePickerVc.navigationBar.translucent = NO;
    imagePickerVc.iconThemeColor = [UIColor colorWithRed:31 / 255.0 green:185 / 255.0 blue:34 / 255.0 alpha:1.0];

    imagePickerVc.allowPickingVideo = YES;
    imagePickerVc.allowPickingImage = YES;
    imagePickerVc.allowPickingOriginalPhoto = YES;
    imagePickerVc.allowPickingGif = YES;
    imagePickerVc.showSelectedIndex = YES;
    imagePickerVc.allowPickingMultipleVideo = YES;

    // imagePickerVc.minImagesCount = 3;
    // imagePickerVc.alwaysEnableDoneBtn = YES;

    imagePickerVc.showSelectBtn = NO;
    //imagePickerVc.allowPreview = NO;
    // imagePickerVc.preferredLanguage = @"zh-Hans";

#pragma mark - 到这里为止
    
    return imagePickerVc;
}

#pragma mark - Click Event

- (void)deleteBtnClik:(UIButton *)sender {
    if ([self collectionView:self.collectionView numberOfItemsInSection:0] <= _selectedPhotos.count) {
        [_selectedPhotos removeObjectAtIndex:sender.tag];
        [self.collectionView reloadData];
        return;
    }
    
    [_selectedPhotos removeObjectAtIndex:sender.tag];
    [_collectionView performBatchUpdates:^{
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:sender.tag inSection:0];
        [self->_collectionView deleteItemsAtIndexPaths:@[indexPath]];
    } completion:^(BOOL finished) {
        [self->_collectionView reloadData];
    }];
}

@end

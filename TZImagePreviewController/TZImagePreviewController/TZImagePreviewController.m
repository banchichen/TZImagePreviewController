//
//  TZImagePreviewController.m
//  TZImagePreviewController
//
//  Created by 谭真 on 18/08/23.
//  Copyright © 2018年 谭真. All rights reserved.
//  version 0.5.0 - 2020.12.09

#import "TZImagePreviewController.h"
#import <TZImagePickerController/TZPhotoPreviewCell.h>
#import <TZImagePickerController/TZAssetModel.h>
#import <TZImagePickerController/UIView+TZLayout.h>
#import <TZImagePickerController/TZImagePickerController.h>
#import <TZImagePickerController/TZImageManager.h>
#import <AVFoundation/AVFoundation.h>

@interface TZImagePreviewController ()<UICollectionViewDataSource,UICollectionViewDelegate,UIScrollViewDelegate> {
    UICollectionView *_collectionView;
    UICollectionViewFlowLayout *_layout;
    
    UIView *_naviBar;
    UIButton *_backButton;
    UIButton *_selectButton;
    UILabel *_indexLabel;
    
    UIView *_toolBar;
    UIButton *_doneButton;
    UIImageView *_numberImageView;
    UILabel *_numberLabel;
    UIButton *_originalPhotoButton;
    UILabel *_originalPhotoLabel;
    
    CGFloat _offsetItemCount;
    
    BOOL _didSetIsSelectOriginalPhoto;
}
@property (nonatomic, strong) TZImagePickerController *tzImagePickerVc;
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, assign) NSInteger currentIndex;

@property (nonatomic, assign) BOOL isHideNaviBar;
@property (nonatomic, assign) double progress;
@property (strong, nonatomic) UIAlertController *alertView;
@property (nonatomic, strong) NSMutableArray *tempPhotos;

@property (nonatomic, strong) NSArray *videoSuffixs;
@end

@implementation TZImagePreviewController

- (instancetype)initWithPhotos:(NSArray *)photos currentIndex:(NSInteger)currentIndex tzImagePickerVc:(TZImagePickerController *)tzImagePickerVc {
    self = [super init];
    if (self) {
        self.photos = [NSMutableArray arrayWithArray:photos];
        self.currentIndex = currentIndex;
        self.tzImagePickerVc = tzImagePickerVc;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.videoSuffixs = @[@"mov",@"mp4",@"rmvb",@"rm",@"flv",@"avi",@"3gp",@"wmv",@"mpeg1",@"mpeg2",@"mpeg4(mp4)",                                 @"asf",@"swf",@"vob",@"dat",@"m4v",@"f4v",@"mkv",@"mts",@"ts"];
    [TZImageManager manager].shouldFixOrientation = YES;
    self.tempPhotos = [NSMutableArray arrayWithArray:self.photos];
    if (!_didSetIsSelectOriginalPhoto) {
        _isSelectOriginalPhoto = self.tzImagePickerVc.isSelectOriginalPhoto;
    }
    [self configCollectionView];
    [self configCustomNaviBar];
    [self configBottomToolBar];
    self.view.clipsToBounds = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeStatusBarOrientationNotification:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];    
}

- (void)setIsSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto {
    _isSelectOriginalPhoto = isSelectOriginalPhoto;
    _didSetIsSelectOriginalPhoto = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [UIApplication sharedApplication].statusBarHidden = YES;
    if (_currentIndex) [_collectionView setContentOffset:CGPointMake((self.view.tz_width + 20) * _currentIndex, 0) animated:NO];
    [self refreshNaviBarAndBottomBarState];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.tzImagePickerVc.needShowStatusBar) {
        [UIApplication sharedApplication].statusBarHidden = NO;
    }
    [TZImageManager manager].shouldFixOrientation = NO;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)configCustomNaviBar {
    _naviBar = [[UIView alloc] initWithFrame:CGRectZero];
    _naviBar.backgroundColor = [UIColor colorWithRed:(34/255.0) green:(34/255.0)  blue:(34/255.0) alpha:0.7];
    
    _backButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [_backButton setImage:[UIImage tz_imageNamedFromMyBundle:@"navi_back"] forState:UIControlStateNormal];
    [_backButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_backButton addTarget:self action:@selector(backButtonClick) forControlEvents:UIControlEventTouchUpInside];
    
    _selectButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [_selectButton setImage:_tzImagePickerVc.photoDefImage forState:UIControlStateNormal];
    [_selectButton setImage:_tzImagePickerVc.photoSelImage forState:UIControlStateSelected];
    _selectButton.imageView.clipsToBounds = YES;
    _selectButton.imageEdgeInsets = UIEdgeInsetsMake(10, 0, 10, 0);
    _selectButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [_selectButton addTarget:self action:@selector(select:) forControlEvents:UIControlEventTouchUpInside];
    _selectButton.hidden = !_tzImagePickerVc.showSelectBtn;
    
    _indexLabel = [[UILabel alloc] init];
    _indexLabel.font = [UIFont systemFontOfSize:14];
    _indexLabel.textColor = [UIColor whiteColor];
    _indexLabel.textAlignment = NSTextAlignmentCenter;
    
    [_naviBar addSubview:_selectButton];
    [_naviBar addSubview:_indexLabel];
    [_naviBar addSubview:_backButton];
    [self.view addSubview:_naviBar];
}

- (void)configBottomToolBar {
    _toolBar = [[UIView alloc] initWithFrame:CGRectZero];
    static CGFloat rgb = 34 / 255.0;
    _toolBar.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:0.7];
    
    if (_tzImagePickerVc.allowPickingOriginalPhoto) {
        _originalPhotoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _originalPhotoButton.imageEdgeInsets = UIEdgeInsetsMake(0, -10, 0, 0);
        _originalPhotoButton.backgroundColor = [UIColor clearColor];
        [_originalPhotoButton addTarget:self action:@selector(originalPhotoButtonClick) forControlEvents:UIControlEventTouchUpInside];
        _originalPhotoButton.titleLabel.font = [UIFont systemFontOfSize:13];
        [_originalPhotoButton setTitle:_tzImagePickerVc.fullImageBtnTitleStr forState:UIControlStateNormal];
        [_originalPhotoButton setTitle:_tzImagePickerVc.fullImageBtnTitleStr forState:UIControlStateSelected];
        [_originalPhotoButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [_originalPhotoButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [_originalPhotoButton setImage:_tzImagePickerVc.photoPreviewOriginDefImage forState:UIControlStateNormal];
        [_originalPhotoButton setImage:_tzImagePickerVc.photoOriginSelImage forState:UIControlStateSelected];
        
        _originalPhotoLabel = [[UILabel alloc] init];
        _originalPhotoLabel.textAlignment = NSTextAlignmentLeft;
        _originalPhotoLabel.font = [UIFont systemFontOfSize:13];
        _originalPhotoLabel.textColor = [UIColor whiteColor];
        _originalPhotoLabel.backgroundColor = [UIColor clearColor];
        if (_isSelectOriginalPhoto) [self showPhotoBytes];
    }
    
    _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _doneButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [_doneButton addTarget:self action:@selector(doneButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [_doneButton setTitle:_tzImagePickerVc.doneBtnTitleStr forState:UIControlStateNormal];
    [_doneButton setTitleColor:_tzImagePickerVc.oKButtonTitleColorNormal forState:UIControlStateNormal];
    
    _numberImageView = [[UIImageView alloc] initWithImage:_tzImagePickerVc.photoNumberIconImage];
    _numberImageView.backgroundColor = [UIColor clearColor];
    _numberImageView.clipsToBounds = YES;
    _numberImageView.contentMode = UIViewContentModeScaleAspectFit;
    _numberImageView.hidden = self.tempPhotos.count <= 0;
    
    _numberLabel = [[UILabel alloc] init];
    _numberLabel.font = [UIFont systemFontOfSize:15];
    _numberLabel.textColor = [UIColor whiteColor];
    _numberLabel.textAlignment = NSTextAlignmentCenter;
    _numberLabel.text = [NSString stringWithFormat:@"%zd",self.tempPhotos.count];
    _numberLabel.hidden = self.tempPhotos.count <= 0;
    _numberLabel.backgroundColor = [UIColor clearColor];
    
    [_originalPhotoButton addSubview:_originalPhotoLabel];
    [_toolBar addSubview:_doneButton];
    [_toolBar addSubview:_originalPhotoButton];
    [_toolBar addSubview:_numberImageView];
    [_toolBar addSubview:_numberLabel];
    [self.view addSubview:_toolBar];
    
    if (_tzImagePickerVc.photoPreviewPageUIConfigBlock) {
        _tzImagePickerVc.photoPreviewPageUIConfigBlock(_collectionView, _naviBar, _backButton, _selectButton, _indexLabel, _toolBar, _originalPhotoButton, _originalPhotoLabel, _doneButton, _numberImageView, _numberLabel);
    }
}

- (void)configCollectionView {
    _layout = [[UICollectionViewFlowLayout alloc] init];
    _layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:_layout];
    _collectionView.backgroundColor = [UIColor blackColor];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.pagingEnabled = YES;
    _collectionView.scrollsToTop = NO;
    _collectionView.showsHorizontalScrollIndicator = NO;
    _collectionView.contentOffset = CGPointMake(0, 0);
    _collectionView.contentSize = CGSizeMake(self.photos.count * (self.view.tz_width + 20), 0);
    [self.view addSubview:_collectionView];
    [_collectionView registerClass:[TZPhotoPreviewCell class] forCellWithReuseIdentifier:@"TZPhotoPreviewCell"];
    [_collectionView registerClass:[TZVideoPreviewCell class] forCellWithReuseIdentifier:@"TZVideoPreviewCell"];
    [_collectionView registerClass:[TZGifPreviewCell class] forCellWithReuseIdentifier:@"TZGifPreviewCell"];
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    CGFloat statusBarHeight = [TZCommonTools tz_statusBarHeight];
    CGFloat statusBarHeightInterval = statusBarHeight - 20;
    CGFloat naviBarHeight = statusBarHeight + _tzImagePickerVc.navigationBar.tz_height;
    _naviBar.frame = CGRectMake(0, 0, self.view.tz_width, naviBarHeight);
    _backButton.frame = CGRectMake(10, 10 + statusBarHeightInterval, 44, 44);
    _selectButton.frame = CGRectMake(self.view.tz_width - 56, 10 + statusBarHeightInterval, 44, 44);
    _indexLabel.frame = _selectButton.frame;
    
    _layout.itemSize = CGSizeMake(self.view.tz_width + 20, self.view.tz_height);
    _layout.minimumInteritemSpacing = 0;
    _layout.minimumLineSpacing = 0;
    _collectionView.frame = CGRectMake(-10, 0, self.view.tz_width + 20, self.view.tz_height);
    [_collectionView setCollectionViewLayout:_layout];
    if (_offsetItemCount > 0) {
        CGFloat offsetX = _offsetItemCount * _layout.itemSize.width;
        [_collectionView setContentOffset:CGPointMake(offsetX, 0)];
    }
    if (_tzImagePickerVc.allowCrop) {
        [_collectionView reloadData];
    }
    
    CGFloat toolBarHeight = [TZCommonTools tz_isIPhoneX] ? 44 + (83 - 49) : 44;
    CGFloat toolBarTop = self.view.tz_height - toolBarHeight;
    _toolBar.frame = CGRectMake(0, toolBarTop, self.view.tz_width, toolBarHeight);
    if (_tzImagePickerVc.allowPickingOriginalPhoto) {
        CGFloat fullImageWidth = [_tzImagePickerVc.fullImageBtnTitleStr boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:13]} context:nil].size.width;
        _originalPhotoButton.frame = CGRectMake(0, 0, fullImageWidth + 56, 44);
        _originalPhotoLabel.frame = CGRectMake(fullImageWidth + 42, 0, 80, 44);
    }
    [_doneButton sizeToFit];
    _doneButton.frame = CGRectMake(self.view.tz_width - _doneButton.tz_width - 12, 0, _doneButton.tz_width, 44);
    _numberImageView.frame = CGRectMake(_doneButton.tz_left - 24 - 5, 10, 24, 24);
    _numberLabel.frame = _numberImageView.frame;
    
    if (_tzImagePickerVc.photoPreviewPageDidLayoutSubviewsBlock) {
        _tzImagePickerVc.photoPreviewPageDidLayoutSubviewsBlock(_collectionView, _naviBar, _backButton, _selectButton, _indexLabel, _toolBar, _originalPhotoButton, _originalPhotoLabel, _doneButton, _numberImageView, _numberLabel);
    }
}

#pragma mark - Notification

- (void)didChangeStatusBarOrientationNotification:(NSNotification *)noti {
    _offsetItemCount = _collectionView.contentOffset.x / _layout.itemSize.width;
}

#pragma mark - Click Event

- (void)select:(UIButton *)selectButton {
    id photo = _photos[_currentIndex];
    if (!selectButton.isSelected) {
        [self.tempPhotos addObject:photo];
    } else {
        [self.tempPhotos removeObject:photo];
    }
    [self refreshNaviBarAndBottomBarState];
    if (selectButton.isSelected) {
        [UIView showOscillatoryAnimationWithLayer:selectButton.imageView.layer type:TZOscillatoryAnimationToBigger];
    }
    [UIView showOscillatoryAnimationWithLayer:_numberImageView.layer type:TZOscillatoryAnimationToSmaller];
}

- (void)dismiss {
    if (self.navigationController) {
        if (self.navigationController.childViewControllers.count < 2) {
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
        }
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)backButtonClick {
    [self dismiss];
    if (self.backButtonClickBlock) {
        self.backButtonClickBlock(_isSelectOriginalPhoto);
    }
}

- (void)doneButtonClick {
    if (self.doneButtonClickBlock) {
        self.doneButtonClickBlock(self.tempPhotos, self.isSelectOriginalPhoto);
    }
    [self dismiss];
}

- (void)originalPhotoButtonClick {
    _originalPhotoButton.selected = !_originalPhotoButton.isSelected;
    _isSelectOriginalPhoto = _originalPhotoButton.isSelected;
    _originalPhotoLabel.hidden = !_originalPhotoButton.isSelected;
    if (_isSelectOriginalPhoto) {
        [self showPhotoBytes];
        if (!_selectButton.isSelected) {
            // 如果当前已选择照片张数 < 最大可选张数 && 最大可选张数大于1，就选中该张图
            if (self.tempPhotos.count < _tzImagePickerVc.maxImagesCount && _tzImagePickerVc.showSelectBtn) {
                [self select:_selectButton];
            }
        }
    }
}

- (void)didTapPreviewCell {
    self.isHideNaviBar = !self.isHideNaviBar;
    _naviBar.hidden = self.isHideNaviBar;
    _toolBar.hidden = self.isHideNaviBar;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat offSetWidth = scrollView.contentOffset.x;
    offSetWidth = offSetWidth +  ((self.view.tz_width + 20) * 0.5);
    
    NSInteger currentIndex = offSetWidth / (self.view.tz_width + 20);
    
    if (currentIndex < _photos.count && _currentIndex != currentIndex) {
        _currentIndex = currentIndex;
        [self refreshNaviBarAndBottomBarState];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"photoPreviewCollectionViewDidScroll" object:nil];
}

#pragma mark - UICollectionViewDataSource && Delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _photos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    id photo = _photos[indexPath.item];
    TZAssetPreviewCell *cell;
    __weak typeof(self) weakSelf = self;
    
    if ([photo isKindOfClass:[PHAsset class]]) {
        PHAsset *asset = (PHAsset *)photo;
        TZAssetModel *model = [[TZImageManager manager] createModelWithAsset:asset];
        
        if (_tzImagePickerVc.allowPickingMultipleVideo && model.type == TZAssetModelMediaTypeVideo) {
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TZVideoPreviewCell" forIndexPath:indexPath];
        } else if (_tzImagePickerVc.allowPickingMultipleVideo && model.type == TZAssetModelMediaTypePhotoGif && _tzImagePickerVc.allowPickingGif) {
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TZGifPreviewCell" forIndexPath:indexPath];
        } else {
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TZPhotoPreviewCell" forIndexPath:indexPath];
            TZPhotoPreviewCell *photoPreviewCell = (TZPhotoPreviewCell *)cell;
            __weak typeof(_collectionView) weakCollectionView = _collectionView;
            __weak typeof(photoPreviewCell) weakCell = photoPreviewCell;
            [photoPreviewCell setImageProgressUpdateBlock:^(double progress) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                __strong typeof(weakCollectionView) strongCollectionView = weakCollectionView;
                __strong typeof(weakCell) strongCell = weakCell;
                strongSelf.progress = progress;
                if (progress >= 1) {
                    if (strongSelf.isSelectOriginalPhoto) [strongSelf showPhotoBytes];
                    if (strongSelf.alertView && [strongCollectionView.visibleCells containsObject:strongCell]) {
                        [strongSelf.alertView dismissViewControllerAnimated:YES completion:^{
                            strongSelf.alertView = nil;
                            [strongSelf doneButtonClick];
                        }];
                    }
                }
            }];
        }
        cell.model = model;
    } else {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TZPhotoPreviewCell" forIndexPath:indexPath];
        TZPhotoPreviewCell *photoPreviewCell = (TZPhotoPreviewCell *)cell;
        photoPreviewCell.previewView.imageView.backgroundColor = [UIColor colorWithWhite:1.000 alpha:0.500];
        if ([photo isKindOfClass:[UIImage class]]) {
            photoPreviewCell.previewView.imageView.image = (UIImage *)photo;
        } else if ([photo isKindOfClass:[NSURL class]]) {
            NSURL *URL = (NSURL *)photo;
            NSString *suffix = [[URL.absoluteString.lowercaseString componentsSeparatedByString:@"."] lastObject];
            if (suffix && [self.videoSuffixs containsObject:suffix]) {
                cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TZVideoPreviewCell" forIndexPath:indexPath];
                TZVideoPreviewCell *videoCell = (TZVideoPreviewCell *)cell;
                videoCell.videoURL = URL;
            } else if (self.setImageWithURLBlock) {
                self.setImageWithURLBlock(URL, photoPreviewCell.previewView.imageView, ^{
                    [photoPreviewCell recoverSubviews];
                });
            } else {
                photoPreviewCell.previewView.imageView.image = nil;
                NSLog(@"【TZImagePreviewController】传入的photos有NSURL对象且不是视频，请参照Demo实现setImageWithURLBlock！");
            }
        } else {
            photoPreviewCell.previewView.imageView.image = nil;
            NSLog(@"【TZImagePreviewController】photos数组内元素只支持PHAsset、UIImage、NSURL类型！不支持%@类型！", [photo class]);
        }
    }
    
    [cell setSingleTapGestureBlock:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf didTapPreviewCell];
    }];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[TZPhotoPreviewCell class]]) {
        [(TZPhotoPreviewCell *)cell recoverSubviews];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[TZPhotoPreviewCell class]]) {
        [(TZPhotoPreviewCell *)cell recoverSubviews];
    } else if ([cell isKindOfClass:[TZVideoPreviewCell class]]) {
        [(TZVideoPreviewCell *)cell pausePlayerAndShowNaviBar];
    }
}

#pragma mark - Private Method

- (void)dealloc {
    NSLog(@"%@ dealloc",NSStringFromClass(self.class));
}

- (void)refreshNaviBarAndBottomBarState {
    id photo = _photos[_currentIndex];
    _selectButton.selected = [self.tempPhotos containsObject:photo];
    [self refreshSelectButtonImageViewContentMode];
    if (_selectButton.isSelected && _tzImagePickerVc.showSelectedIndex && _tzImagePickerVc.showSelectBtn) {
        NSString *index = [NSString stringWithFormat:@"%zd", [self.tempPhotos indexOfObject:photo] + 1];
        _indexLabel.text = index;
        _indexLabel.hidden = NO;
    } else {
        _indexLabel.hidden = YES;
    }
    _numberLabel.text = [NSString stringWithFormat:@"%zd",self.tempPhotos.count];
    _numberImageView.hidden = (self.tempPhotos.count <= 0 || _isHideNaviBar);
    _numberLabel.hidden = (self.tempPhotos.count <= 0 || _isHideNaviBar);
    
    _originalPhotoButton.selected = _isSelectOriginalPhoto;
    _originalPhotoLabel.hidden = !_originalPhotoButton.isSelected;
    if (_isSelectOriginalPhoto) [self showPhotoBytes];
    
    // If is previewing video, hide original photo button
    // 如果正在预览的是视频，隐藏原图按钮
    if (!_isHideNaviBar) {
        if ([photo isKindOfClass:[PHAsset class]]) {
            PHAsset *asset = (PHAsset *)photo;
            TZAssetModelMediaType type = [[TZImageManager manager] getAssetType:asset];
            if (type == TZAssetModelMediaTypeVideo) {
                _originalPhotoButton.hidden = YES;
                _originalPhotoLabel.hidden = YES;
            } else {
                _originalPhotoButton.hidden = NO;
                if (_isSelectOriginalPhoto)  _originalPhotoLabel.hidden = NO;
            }
        } else {
            _originalPhotoButton.hidden = YES;
            _originalPhotoLabel.hidden = YES;
        }
    }
    
    _doneButton.hidden = NO;
    _selectButton.hidden = !_tzImagePickerVc.showSelectBtn;
}

- (void)refreshSelectButtonImageViewContentMode {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self->_selectButton.imageView.image.size.width <= 27) {
            self->_selectButton.imageView.contentMode = UIViewContentModeCenter;
        } else {
            self->_selectButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        }
    });
}

- (void)showPhotoBytes {
    id photo = _photos[_currentIndex];
    if ([photo isKindOfClass:[PHAsset class]]) {
        PHAsset *asset = (PHAsset *)photo;
        TZAssetModel *model = [[TZImageManager manager] createModelWithAsset:asset];
        [[TZImageManager manager] getPhotosBytesWithArray:@[model] completion:^(NSString *totalBytes) {
            self->_originalPhotoLabel.text = [NSString stringWithFormat:@"(%@)",totalBytes];
        }];
    }
}

@end

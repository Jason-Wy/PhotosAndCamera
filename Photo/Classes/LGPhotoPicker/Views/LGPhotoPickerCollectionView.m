//
//  LGPickerCollectionView.m
//  LGPhotoBrowser
//
//  Created by Jason on 15/10/27.
//  Copyright (c) 2015年 L&G. All rights reserved.

#import "LGPhotoPickerCollectionView.h"
#import "LGPhotoPickerCollectionViewCell.h"
#import "LGPhotoPickerImageView.h"
#import "LGPhotoPickerFooterCollectionReusableView.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "LGPhotoAssets.h"
#import "LGPhoto.h"
#import <objc/runtime.h>

@interface LGPhotoPickerCollectionView () <UICollectionViewDataSource,UICollectionViewDelegate>

@property (nonatomic , strong) LGPhotoPickerFooterCollectionReusableView *footerView;

// 判断是否是第一次加载
@property (nonatomic , assign , getter=isFirstLoadding) BOOL firstLoadding;

//每个cell右上角的选择按钮
//@property (nonatomic, weak) UIButton *tickButton;

@end

@implementation LGPhotoPickerCollectionView

#pragma mark -setter
- (void)setDataArray:(NSArray *)dataArray{
    _dataArray = dataArray;
    
    // 需要记录选中的值的数据
    if (self.isRecoderSelectPicker){
        NSMutableArray *selectAssets = [NSMutableArray array];
        for (LGPhotoAssets *asset in self.selectAssets) {
            for (LGPhotoAssets *asset2 in self.dataArray) {
                
                if ([asset isKindOfClass:[UIImage class]] || [asset2 isKindOfClass:[UIImage class]]) {
                    continue;
                }
                if ([asset.asset.defaultRepresentation.url isEqual:asset2.asset.defaultRepresentation.url]) {
                    [selectAssets addObject:asset2];
                    break;
                }
            }
        }
        _selectAssets = selectAssets;
    }
    
    [self reloadData];
}

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout{
    if (self = [super initWithFrame:frame collectionViewLayout:layout]) {
        
        self.backgroundColor = [UIColor clearColor];
        self.dataSource = self;
        self.delegate = self;
        _selectAssets = [NSMutableArray array];
    }
    return self;
}

- (void)setupPickerImageViewOnCell:(LGPhotoPickerCollectionViewCell *)cell
                           AtIndex:(NSIndexPath *)indexPath
{
    LGPhotoPickerImageView *cellImgView = nil;
    if (cell.contentView.subviews.count == 2 && [cell.contentView.subviews[0] isKindOfClass:[UIView class]]) {//如果是重用cell，则不用再添加cellImgView
        cellImgView = cell.contentView.subviews[0];
    } else {
        cellImgView = [[LGPhotoPickerImageView alloc] initWithFrame:cell.bounds];
        [cell.contentView addSubview:cellImgView];
        //FIXME:设置cell的边框
        cell.layer.borderColor = [UIColor blackColor].CGColor;
        cell.layer.borderWidth = 1;
    }
    
    LGPhotoAssets *asset = self.dataArray[indexPath.item];
    if ([asset isKindOfClass:[LGPhotoAssets class]]) {
        cellImgView.image= asset.thumbImage;
    }
    
    cellImgView.maskViewFlag = NO;
    for (NSInteger i = 0; i < self.selectAssets.count; i ++) {
        if ([((LGPhotoAssets *)self.selectAssets[i]).assetURL isEqual:asset.assetURL]) {
            cellImgView.maskViewFlag = YES;
        }
    }
}
/**
 *  每个cell右上角的选择按钮
 */
- (void)setupTickButtonOnCell:(LGPhotoPickerCollectionViewCell *)cell
                      AtIndex:(NSIndexPath *)indexPath
{
    UIButton *tickButton = nil;
    if (cell.contentView.subviews.count == 2 && [cell.contentView.subviews[1] isKindOfClass:[UIButton class]]) {//如果是重用cell，则不用再添加button
        tickButton = cell.contentView.subviews[1];
    } else {
        tickButton = [[UIButton alloc] init];
        tickButton.frame = CGRectMake(cell.frame.size.width - 40, 0, 40, 40);
        [tickButton setBackgroundColor:[UIColor clearColor]];
        [cell.contentView addSubview:tickButton];
        [tickButton addTarget:self action:@selector(tickBtnTouched:) forControlEvents:UIControlEventTouchUpInside];
    }
    //runtime 关联对象
    objc_setAssociatedObject(tickButton, @"tickBtn", indexPath, OBJC_ASSOCIATION_ASSIGN);
}

- (void)tickBtnTouched:(UIButton *)btn
{
    //runtime 获取关联的对象
    NSIndexPath * indexPath = objc_getAssociatedObject(btn, @"tickBtn");
    
    if (self.topShowPhotoPicker && indexPath.row == 0) {
        if ([self.collectionViewDelegate respondsToSelector:@selector(pickerCollectionViewDidCameraSelect:)]) {
            [self.collectionViewDelegate pickerCollectionViewDidCameraSelect:self];
        }
        return ;
    }
    
    if (!self.lastDataArray) {
        self.lastDataArray = [NSMutableArray array];
    }
    
    LGPhotoPickerCollectionViewCell *cell = (LGPhotoPickerCollectionViewCell *) [self cellForItemAtIndexPath:indexPath];
    
    LGPhotoAssets *asset = self.dataArray[indexPath.item];
    LGPhotoPickerImageView *pickerImageView = [cell.contentView.subviews objectAtIndex:0];
    // 如果没有就添加到数组里面，存在就移除
    NSLog(@"111111111");
    if ([pickerImageView isKindOfClass:[LGPhotoPickerImageView class]] && pickerImageView.isMaskViewFlag) {
        [self.selectAssets removeObject:asset];
        [self.lastDataArray removeObject:asset];
    }else{
        // 1 判断图片数超过最大数或者小于0
        NSUInteger maxCount = (self.maxCount < 0) ? KPhotoShowMaxCount :  self.maxCount;
        if (self.selectAssets.count >= maxCount) {
            NSString *format = [NSString stringWithFormat:@"最多只能选择%zd张图片",maxCount];
            if (maxCount == 0) {
                format = [NSString stringWithFormat:@"您最多只能选择9张图片"];
            }
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提醒" message:format delegate:self cancelButtonTitle:nil otherButtonTitles:@"好的", nil];
            [alertView show];
            return;
        }
        
        [self.selectAssets addObject:asset];
        [self.lastDataArray addObject:asset];
    }
    NSLog(@"22222222222");
    //告诉代理现在被点击了!
    if ([self.collectionViewDelegate respondsToSelector:@selector(pickerCollectionViewDidSelected: deleteAsset:)]) {
        NSLog(@"pickerImageView  %d",pickerImageView.isMaskViewFlag);
        if (pickerImageView.isMaskViewFlag) {
            //删除的情况下
            
            NSLog(@"删除");
            [self.collectionViewDelegate pickerCollectionViewDidSelected:self deleteAsset:asset];
        }else{
            NSLog(@"选择中");
            [self.collectionViewDelegate pickerCollectionViewDidSelected:self deleteAsset:nil];
        }
        NSLog(@"33333333333");
    }
    
    pickerImageView.maskViewFlag = ([pickerImageView isKindOfClass:[LGPhotoPickerImageView class]]) && !pickerImageView.isMaskViewFlag;
    NSLog(@"444444444");
}

#pragma mark -<UICollectionViewDataSource>
- (NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.dataArray.count;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    NSLog(@"cellForItemAtIndexPath --- start");
    LGPhotoPickerCollectionViewCell *cell = [LGPhotoPickerCollectionViewCell cellWithCollectionView:collectionView cellForItemAtIndexPath:indexPath];
 
    cell.backgroundColor = [UIColor clearColor];
    if (indexPath.row == 0 &&indexPath.section == 0) {
        for (UIControl *control in [cell.contentView subviews]) {
            [control removeFromSuperview];//消除重复被用的背景
        }
        cell.backgroundColor = [UIColor whiteColor];
        CGRect imageRect = CGRectMake(0, 0, cell.bounds.size.width/2, cell.bounds.size.height/2);
        UIImageView *cellImgView = [[UIImageView alloc]initWithFrame:imageRect];
        cellImgView.center = cell.center;
        cellImgView.image = [UIImage imageNamed:@"xiqngji.png"];
        [cell.contentView addSubview:cellImgView];
        [cellImgView bringSubviewToFront:cell];
        
    }else
    {
        [self setupPickerImageViewOnCell:cell AtIndex:indexPath];
        [self setupTickButtonOnCell:cell AtIndex:indexPath];
    }
    
    return cell;
}

#pragma mark - <UICollectionViewDelegate>
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    //cell被点击，进入相册浏览器
    if ([self.collectionViewDelegate respondsToSelector:@selector(pickerCollectionCellTouchedIndexPath:)])
    {
        [self.collectionViewDelegate pickerCollectionCellTouchedIndexPath:indexPath];
    }
}

#pragma mark 底部View
-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    LGPhotoPickerFooterCollectionReusableView *reusableView = nil;
    if (kind == UICollectionElementKindSectionFooter) {
        LGPhotoPickerFooterCollectionReusableView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"FooterView" forIndexPath:indexPath];
        footerView.count = self.dataArray.count;
        reusableView = footerView;
        self.footerView = footerView;
    }else{
        
    }
    return reusableView;
}

- (void)layoutSubviews{
    
    [super layoutSubviews];
    
    // 时间置顶的话
    if (self.status == LGPickerCollectionViewShowOrderStatusTimeDesc) {
        if (!self.firstLoadding && self.contentSize.height > [[UIScreen mainScreen] bounds].size.height) {
            // 滚动到最底部（最新的）
            [self scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.dataArray.count - 1 inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
            // 展示图片数
            self.contentOffset = CGPointMake(self.contentOffset.x, self.contentOffset.y + 100);
            self.firstLoadding = YES;
        }
    }else if (self.status == LGPickerCollectionViewShowOrderStatusTimeAsc){
        // 滚动到最底部（最新的）
        if (!self.firstLoadding && self.contentSize.height > [[UIScreen mainScreen] bounds].size.height) {
            [self scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
            // 展示图片数
            self.contentOffset = CGPointMake(self.contentOffset.x, -self.contentInset.top);
            self.firstLoadding = YES;
        }
    }
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end

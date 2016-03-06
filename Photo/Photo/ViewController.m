//
//  ViewController.m
//  LGPhotoBrowser
//
//  Created by Jason on 15/10/27.
//  Copyright (c) 2015年 L&G. All rights reserved.
//

#import "ViewController.h"
#import "LGPhoto.h"
#define HEADER_HEIGHT 100

@interface ViewController ()<LGPhotoPickerViewControllerDelegate,LGPhotoPickerBrowserViewControllerDataSource,LGPhotoPickerBrowserViewControllerDelegate>

@property (nonatomic, strong)NSMutableArray *LGPhotoPickerBrowserPhotoArray;
@property (nonatomic, strong)NSMutableArray *LGPhotoPickerBrowserURLArray;
@property (nonatomic, assign) LGShowImageType showType;


- (void)presentCameraSingle ;
- (void)presentCameraContinuous ;


@end

@implementation ViewController

- (void)viewDidLoad {
    
    UIButton *confirmButton = [[UIButton alloc]initWithFrame:CGRectMake(10, 100, 140, 44)];
    confirmButton.backgroundColor = [UIColor redColor];
    [confirmButton setBackgroundImage:[UIImage imageNamed:@"person-button-noround"] forState:UIControlStateNormal];
    [confirmButton setTitle:@"进入图库" forState:UIControlStateNormal];
    [confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [confirmButton addTarget:self action:@selector(confirmButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:confirmButton];
    
    
    UIButton *changeButton = [[UIButton alloc]initWithFrame:CGRectMake(160, 100, 140, 44)];
    changeButton.backgroundColor = [UIColor redColor];
    [changeButton setBackgroundImage:[UIImage imageNamed:@"person-button-noround"] forState:UIControlStateNormal];
    [changeButton setTitle:@"选择照相" forState:UIControlStateNormal];
    [changeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [changeButton addTarget:self action:@selector(changeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:changeButton];

    
    //设置照相通知
    [self addObservers];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
}

- (void)addObservers{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveCameraSingleOrContinuousNotificationResult:)
                                                 name:LGCameraSingleOrContinuousNotification
                                               object:nil];
    
}

- (void)receiveCameraSingleOrContinuousNotificationResult:(NSNotification *)notification
{
    NSDictionary *dict = [notification userInfo];
    NSLog(@"dict %@",dict);
    NSArray *resultArray = [dict objectForKey:@"result"];
    if (resultArray != nil&&resultArray.count != 0) {
        
        for (UIView *obj in self.view.subviews) {
            if ([obj isKindOfClass:[UIImageView class]]) {
                [obj removeFromSuperview];
            }
        }
        
        int i = 0;
        for (ZLCamera *zlPhoto in resultArray) {
            
            [self creatImageView:i WithImage:zlPhoto.photoImage];
            
            i = i+1;
        }
    }
    
}


- (void)confirmButtonAction:(UIButton *)sender
{
    //相册，但是相册有几种不同的类型
    [self presentPhotoPickerViewControllerWithStyle:LGShowImageTypeImageURL];
}

- (void)changeButtonAction:(UIButton *)sender
{
    [self presentCameraSingle];
//    UIActionSheet *sheetAction = [[UIActionSheet alloc]initWithTitle:@"选择相册或者照相" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"可以选择一张或者多张照片，最多可以选择9张，但是连拍会出现内存过大的问题！" otherButtonTitles:@"单张照相",@"多张照相",@"选择照片选择器",@"选择照片浏览器",@"选择网络图片浏览器", nil];
//    [sheetAction showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 1:
        {
            [self presentCameraSingle];
        }
            break;
        case 2:
        {
            
            [self presentCameraContinuous];
        }
            break;
        case 3:
        {
            [self presentPhotoPickerViewControllerWithStyle:LGShowImageTypeImagePicker];
        }
            break;
        case 4:
        {
            
            [self presentPhotoPickerViewControllerWithStyle:LGShowImageTypeImageBroswer];
        }
            break;
        case 5:
        {
            
            [self presentPhotoPickerViewControllerWithStyle:LGShowImageTypeImageURL];
        }
            break;

            
        default:
            break;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)presentPhotoPickerViewControllerWithStyle:(LGShowImageType)style {
    // 创建控制器
    LGPhotoPickerViewController *pickerVc = [[LGPhotoPickerViewController alloc] initWithShowType:style];
    // 默认显示相册里面的内容SavePhotos
    pickerVc.status = PickerViewShowStatusCameraRoll;
    
    // 最多能选9张图片
    pickerVc.maxCount = 9;
    pickerVc.delegate = self;
    self.showType = style;
    [pickerVc showPickerVc:self];
}

- (void)pushPhotoBroswerWithStyle:(LGShowImageType)style{
    LGPhotoPickerBrowserViewController *BroswerVC = [[LGPhotoPickerBrowserViewController alloc] init];
    BroswerVC.delegate = self;
    BroswerVC.dataSource = self;
    BroswerVC.showType = style;
    self.showType = style;
    [self presentViewController:BroswerVC animated:YES completion:nil];
}

- (void)presentCameraSingle {
    ZLCameraViewController *cameraVC = [[ZLCameraViewController alloc] init];
    // 拍照最多个数
    cameraVC.maxCount = 1;
    // 单拍
    cameraVC.cameraType = ZLCameraSingle;
    cameraVC.callback = ^(NSArray *cameras){
        //在这里得到拍照结果
        [[NSNotificationCenter defaultCenter]postNotificationName:LGCameraSingleOrContinuousNotification object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:cameras,@"result", nil]];
    };
    [cameraVC showPickerVc:self];
}

- (void)presentCameraContinuous {
    ZLCameraViewController *cameraVC = [[ZLCameraViewController alloc] init];
    // 拍照最多个数
    cameraVC.maxCount = 4;
    // 连拍
    cameraVC.cameraType = ZLCameraContinuous;
    cameraVC.callback = ^(NSArray *cameras){
        //在这里得到拍照结果
        [[NSNotificationCenter defaultCenter]postNotificationName:LGCameraSingleOrContinuousNotification object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:cameras,@"result", nil]];
    };
    [cameraVC showPickerVc:self];
}


#pragma mark - LGPhotoPickerViewControllerDelegate
- (void)pickerViewControllerDoneAsstes:(NSArray *)assets isOriginal:(BOOL)original{
    
    //消除原来的imageView
    for (UIView *obj in self.view.subviews) {
        if ([obj isKindOfClass:[UIImageView class]]) {
            [obj removeFromSuperview];
        }
    }
    
    int i = 0;
    for (LGPhotoAssets *lgAsset in assets) {
        
        [self creatImageView:i WithImage:lgAsset.thumbImage];
        i = i+1;
    }
    
    i = 0;
    
    NSInteger num = (long)assets.count;
    NSString *isOriginal = original? @"YES":@"NO";
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"发送图片" message:[NSString stringWithFormat:@"您选择了%ld张图片\n是否原图：%@",(long)num,isOriginal] delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alertView show];
}

- (void)creatImageView:(NSInteger )number WithImage:(UIImage *)image
{
    float width = [UIScreen mainScreen].bounds.size.width;
    width -= 40;
    float row = number%4;
    float select = number/4;
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(10+(width/4)*row+(10*row?YES:0), 144+10+(width/4)*select+(10*select?YES:0), width/4, width/4)];
    NSLog(@"%d",10*row?0:YES);
    imageView.image = image;
    [self.view addSubview:imageView];
}

#pragma mark - LGPhotoPickerBrowserViewControllerDataSource
- (NSInteger)photoBrowser:(LGPhotoPickerBrowserViewController *)photoBrowser numberOfItemsInSection:(NSUInteger)section{
    if (self.showType == LGShowImageTypeImageBroswer) {
    return self.LGPhotoPickerBrowserPhotoArray.count;
    } else if (self.showType == LGShowImageTypeImageURL) {
    return self.LGPhotoPickerBrowserURLArray.count;
    } else {
    NSLog(@"非法数据源");
    return 0;
    }
}

- (id<LGPhotoPickerBrowserPhoto>)photoBrowser:(LGPhotoPickerBrowserViewController *)pickerBrowser photoAtIndexPath:(NSIndexPath *)indexPath{
    if (self.showType == LGShowImageTypeImageBroswer) {
        return [self.LGPhotoPickerBrowserPhotoArray objectAtIndex:indexPath.item];
    } else if (self.showType == LGShowImageTypeImageURL) {
        return [self.LGPhotoPickerBrowserURLArray objectAtIndex:indexPath.item];
    } else {
        NSLog(@"非法数据源");
        return nil;
    }
}


@end

//
//  DetailViewController.h
//  UICollectionViewDataSourcePrefetchingObjCSample
//
//  Created by Apple on 12/16/18.
//  Copyright © 2018 Mentormate. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DetailViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UIButton *button;
@property (weak, nonatomic) IBOutlet UIWebView *wv;
@property (weak, nonatomic) UIImage *image;
@property (weak, nonatomic) NSString *name;
@property (weak, nonatomic) NSString *wiki;

@end

NS_ASSUME_NONNULL_END

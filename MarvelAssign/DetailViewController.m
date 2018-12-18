//
//  DetailViewController.m
//  UICollectionViewDataSourcePrefetchingObjCSample
//
//  Created by Apple on 12/16/18.
//  Copyright © 2018 Mentormate. All rights reserved.
//
//Mohammad Dawi on 12/18/2018

#import "DetailViewController.h"

@interface DetailViewController ()


@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.imageView.image=_image;
    self.label.text=_name;
    _wv.delegate = self;
    // Do any additional setup after loading the view.
}
- (IBAction)loadWiki:(UIButton *)sender {
    UIActivityIndicatorView *activityView=[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityView.center = _wv.center;
    [activityView startAnimating];
    activityView.tag = 100;
    [self.view addSubview:activityView];
    NSURL *nsurl=[NSURL URLWithString:_wiki];
    NSURLRequest *nsrequest=[NSURLRequest requestWithURL:nsurl];
    [_wv loadRequest:nsrequest];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.view viewWithTag:100].hidden = YES;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

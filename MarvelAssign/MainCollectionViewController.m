//
//  MainCollectionViewController.m
//  UICollectionViewDataSourcePrefetchingObjCSample
//
//  Created by Nikolay Andonov on 10/19/16.
//  Copyright © 2016 Mentormate. All rights reserved.
//

//Mohammad Dawi on 12/18/2018

#import "MainCollectionViewController.h"
#import "MainCollectionViewCell.h"
#import "DetailViewController.h"
#import <CoreData/CoreData.h>
#import "AppDelegate.h"


static CGFloat const CollectionViewCellPadding = 10;
static NSInteger const NumberOfCellsPerRow = 2;
static AppDelegate *delegate;

@interface MainCollectionViewController () <UICollectionViewDataSourcePrefetching>

@property (assign, nonatomic) CGFloat collectionViewCellSize;

@property (strong, nonatomic) NSMutableArray<NSURL *> *imageURLs;
@property (strong, nonatomic) NSOperationQueue *downloadImageOperationQueue;
@property (strong, nonatomic) NSMutableDictionary<NSURL *, NSBlockOperation *> *operations;
@property (strong, nonatomic) NSMutableDictionary<NSURL *, UIImage *> *images;
@property (strong, nonatomic) NSMutableArray *mutableArrayIds;
@property (strong, nonatomic) NSMutableArray *mutableArrayNames;
@property (strong, nonatomic) NSMutableArray *mutableArrayThumbnails;
@property (strong, nonatomic) NSMutableArray *mutableArrayThumbnailsExt;
@property (strong, nonatomic) NSMutableArray *mutableArrayWikis;
@property (strong, nonatomic) UIWebView *webview;
@property (strong, nonatomic) UIImageView *imageView;

@end

@implementation MainCollectionViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    _mutableArrayIds=[NSMutableArray array];
    _mutableArrayNames=[NSMutableArray array];
    _mutableArrayThumbnails=[NSMutableArray array];
    _mutableArrayThumbnailsExt=[NSMutableArray array];
    _mutableArrayWikis=[NSMutableArray array];
    _webview=[[UIWebView alloc]initWithFrame:CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width,UIScreen.mainScreen.bounds.size.height)];
    //[self.view addSubview:_webview];
     _imageView=[[UIImageView alloc]initWithFrame:CGRectMake(0, 110, 100,200)];
    _imageView.contentMode = UIViewContentModeCenter;
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    
    [self getRequestAPICall:@"f0b5d75500a2db859e1a152376fe2e65" hash:@"a2c3fad843830de5e6c631ddbc41a0c9" ts:@"2"];
    
    [self configureCollectionView];
    //[self populateModels];
    
    //[self.collectionView reloadData];
}

- (void)configureCollectionView {
    
    CGFloat screenWidth = CGRectGetWidth(self.view.frame);
    CGFloat cellsAreaOnSingleRow = screenWidth - ((NumberOfCellsPerRow + 1) * CollectionViewCellPadding);
    self.collectionViewCellSize = cellsAreaOnSingleRow / NumberOfCellsPerRow;
    
    self.collectionView.contentInset = UIEdgeInsetsMake(CollectionViewCellPadding, CollectionViewCellPadding, CollectionViewCellPadding, CollectionViewCellPadding);
    
    self.collectionView.prefetchDataSource = self;
}

- (void)populateModels2:(NSInteger)count {
    self.downloadImageOperationQueue = [[NSOperationQueue alloc] init];
    self.imageURLs = [NSMutableArray array];
    self.operations = [NSMutableDictionary dictionary];
    self.images = [NSMutableDictionary dictionary];
    NSString  *urlStr;
    //Simulating initial load of content
    for (NSInteger counter = 0; counter < count; counter++) {
        //Simulating slow download using large images
        urlStr=_mutableArrayThumbnails[counter];
        urlStr = [urlStr stringByAppendingString:@"."];
        urlStr = [urlStr stringByAppendingString:_mutableArrayThumbnailsExt[counter]];
        NSString *imageStringAdress = urlStr;
        NSURL *imageURL = [NSURL URLWithString:imageStringAdress];
        [self.imageURLs addObject:imageURL];
    }
}

- (void)populateModels:(NSInteger)count {
    
    self.downloadImageOperationQueue = [[NSOperationQueue alloc] init];
    self.imageURLs = [NSMutableArray array];
    self.operations = [NSMutableDictionary dictionary];
    self.images = [NSMutableDictionary dictionary];
    
    //Simulating initial load of content
    for (NSInteger counter = 0; counter < 50; counter++) {
        
        //Simulating slow download using large images
        NSString *imageStringAdress = [NSString stringWithFormat:@"http://placehold.it/2000x2000&text=SampleImage%ld",(long)(counter + 1)];
        NSURL *imageURL = [NSURL URLWithString:imageStringAdress];
        [self.imageURLs addObject:imageURL];
    }
}

// check duplicate characters in core data
- (int) checkDuplicateCharacters:(NSString*)cid{
        NSManagedObjectContext *managedObjectContext=[delegate managedObjectContext];
        NSFetchRequest *request = [[NSFetchRequest alloc]initWithEntityName:@"Character"];
        NSError *error = nil;
        NSArray *results = [managedObjectContext executeFetchRequest:request error:&error];
        NSMutableArray *mutableFetchResults = [[managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
        if ([[mutableFetchResults valueForKey:@"cid"]
             containsObject:cid]) {
            //notify duplicates
            return 1;
        }
        else
        {
            return 0;
        }
    /*
    for (NSManagedObject *obj in results) {
        NSArray *keys = [[[obj entity] attributesByName] allKeys];
        NSDictionary *dictionary = [obj dictionaryWithValuesForKeys:keys];
    }
     */
}

//save new downloaded avatar to core data
- (void) saveCharacterWithId:(NSString*)cid wiki:(NSString*)wiki name:(NSString*)name image:(NSString*)thumbImgData {
    //check if character already saved
    int flag=[self checkDuplicateCharacters:cid];
    if(flag == 1){
        return;
    }
    NSManagedObjectContext *managedObjectContext=[delegate managedObjectContext];
    NSManagedObject *character = [NSEntityDescription insertNewObjectForEntityForName:@"Character" inManagedObjectContext:managedObjectContext];
    [character setValue:cid forKey:@"cid"];
    [character setValue:name forKey:@"name"];
    [character setValue:wiki forKey:@"wiki"];
    [character setValue:thumbImgData forKey:@"image"];
    NSError *error = nil;
    if ([managedObjectContext save:&error] == NO) {
        NSAssert(NO, @"Error saving context: %@\n%@", [error localizedDescription], [error userInfo]);
    }
}

//get the data from API using the private and public keys + timestap
-(void) getRequestAPICall:(NSString *)apikey hash:(NSString *)hash ts:(NSString *)ts  {
    NSString  *todosEndpoint=@"https://gateway.marvel.com:443/v1/public/characters?";
    todosEndpoint = [todosEndpoint stringByAppendingString:@"apikey="];
    todosEndpoint = [todosEndpoint stringByAppendingString:apikey];
    todosEndpoint = [todosEndpoint stringByAppendingString:@"&hash="];
    todosEndpoint = [todosEndpoint stringByAppendingString:hash];
    todosEndpoint = [todosEndpoint stringByAppendingString:@"&ts="];
    todosEndpoint = [todosEndpoint stringByAppendingString:ts];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setURL:[NSURL URLWithString:todosEndpoint]];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:
      ^(NSData * _Nullable data,
        NSURLResponse * _Nullable response,
        NSError * _Nullable error) {
          if(error) { return; }
          id object = [NSJSONSerialization
                       JSONObjectWithData:data
                       options:0
                       error:&error];
          long count=0;
          if([object isKindOfClass:[NSDictionary class]])
          {
              //get all the characters data for eg. their count etc...
              NSDictionary *charactersData = object[@"data"];
              //get the characters list
              NSArray *characters = charactersData[@"results"];
              // get the number of characters
              count = [charactersData[@"count"] longValue];
              NSDictionary *character;
              NSDictionary *thumb;
              NSArray *wiki;
              NSDictionary *url;
              NSString *imgUrl;
              int found;
                  for(int i=0; i< count; i++){
                      found=0;
                      character = characters[i];
                      [_mutableArrayIds addObject:character[@"id"]];
                      [_mutableArrayNames addObject:character[@"name"]];
                      thumb = character[@"thumbnail"];
                      [_mutableArrayThumbnails addObject:thumb[@"path"]];
                      [_mutableArrayThumbnailsExt addObject:thumb[@"extension"]];
                      imgUrl = [thumb[@"path"] stringByAppendingString:@"."];
                      imgUrl = [imgUrl stringByAppendingString:thumb[@"extension"]];
                      
                      wiki = character[@"urls"];
                      for(int i=0; i< wiki.count; i++) {
                          url = wiki[i];
                          if( [url[@"type"]  isEqual: @"wiki"]){
                              [_mutableArrayWikis addObject:url[@"url"]];
                              found=1;
                          }
                      }
                      if(found == 0){
                          [_mutableArrayWikis addObject:@"http://www.google.com"];
                      }
                  }
          }
          //NSLog(@"contents of newArray: %@", _mutableArrayThumbnails);
          //NSLog(@"contents of newArray: %@", _mutableArrayThumbnailsExt);
          [self populateModels2:count];
          dispatch_async(dispatch_get_main_queue(), ^{
               [self saveCharacters:20];
               //[self loadLocalCharacters];
               [self.collectionView reloadData];
          });
      }] resume];
    
}

// save characters to core data
-(void) saveCharacters:(NSInteger)count{
    NSString *imgUrl;
    NSString *cid;
    NSString *name;
    NSString *wiki;
    for(int i=0;i<count;i++){
        imgUrl = [[_mutableArrayThumbnails objectAtIndex:i] stringByAppendingString:@"."];
        imgUrl = [imgUrl stringByAppendingString:[_mutableArrayThumbnailsExt objectAtIndex:i]];
        cid = [[_mutableArrayIds objectAtIndex:i] stringValue];
        wiki = [_mutableArrayWikis objectAtIndex:i];
        name = [_mutableArrayNames objectAtIndex:i];
        [self saveCharacterWithId:cid wiki:wiki name:name image:imgUrl];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    return YES;
}

/*
-(void) loadThumbNail{
    //add a webview for wiki
    NSLog(@"contents of newArray: %@", _mutableArrayWikis[0]);
    NSString *wiki = [_mutableArrayWikis objectAtIndex:0];
    NSURL *nsurl=[NSURL URLWithString:wiki];
    
    NSURLRequest *nsrequest=[NSURLRequest requestWithURL:nsurl];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_webview loadRequest:nsrequest];
    });
    
    
    //add image view for thumbnail
    NSString  *url=_mutableArrayThumbnails[0];
    //+ "apikey=" + apikey + "&hash=" + hash + "&ts=" + ts
    url = [url stringByAppendingString:@"."];
    url = [url stringByAppendingString:_mutableArrayThumbnailsExt[0]];
    NSURL *catPictureURL = [NSURL URLWithString:url];
    
    dispatch_async(dispatch_get_global_queue(0,0), ^{
        NSData * data = [[NSData alloc] initWithContentsOfURL: catPictureURL];
        if ( data == nil )
            return;
        dispatch_async(dispatch_get_main_queue(), ^{
            // WARNING: is the cell still using the same data by this point??
            UIImage *image=[UIImage imageWithData: data];
            _imageView.image = image;
            
            if (_imageView.bounds.size.width > (image.size.width) && _imageView.bounds.size.height > (image.size.height)) {
                _imageView.contentMode = UIViewContentModeScaleAspectFill;
            }
            [self.view addSubview:_imageView];
        });
    });
    //imageView.image = image
}
*/

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return self.imageURLs.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    MainCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    cell.label.text=_mutableArrayNames[indexPath.row];
    NSURL *imageURL = self.imageURLs[indexPath.row];
    if (self.images[imageURL]) {
        cell.imageView.image = self.images[imageURL];
        [cell.activityIndicator stopAnimating];
    }
    else {
        [self executeDownloadImageOperationBlockForIndexPath:indexPath];
    }
    
    return cell;
}



- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    MainCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    DetailViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"DetailViewController"];
    NSURL *imageURL = self.imageURLs[indexPath.row];
    if (self.images[imageURL]!=nil) {
        vc.image = self.images[imageURL];
        vc.name=_mutableArrayNames[indexPath.row];
        vc.wiki=_mutableArrayWikis[indexPath.row];
    }
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark <UICollectionViewDelegate>

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    return CGSizeMake(self.collectionViewCellSize, self.collectionViewCellSize);
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
    [self cancelDowloandImageOperationBlockForIndexPath:indexPath];
}


#pragma mark <UICollectionViewDataSourcePrefetching>

// indexPaths are ordered ascending by geometric distance from the collection view
- (void)collectionView:(UICollectionView *)collectionView prefetchItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    
    for (NSIndexPath *indexPath in indexPaths) {
        
        // Updating upcoming CollectionView's data source. Not assiging any direct value
        // as this operation is expensive it is performed on a private queue
        NSURL *imageURL = self.imageURLs[indexPath.row];
        if (!self.images[imageURL]) {
            [self executeDownloadImageOperationBlockForIndexPath:indexPath];
            NSLog(@"Prefetching data for indexPath: %@", indexPath);
        }
    }
}

// indexPaths that previously were considered as candidates for pre-fetching, but were not actually used; may be a subset of the previous call to -collectionView:prefetchItemsAtIndexPaths:
- (void)collectionView:(UICollectionView *)collectionView cancelPrefetchingForItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    
    for (NSIndexPath *indexPath in indexPaths) {
        
        //Unloading or data load operation cancellations should happend here
        NSURL *imageURL = self.imageURLs[indexPath.row];
        if (self.operations[imageURL]) {
            [self cancelDowloandImageOperationBlockForIndexPath:indexPath];
            NSLog(@"Unloading data fetch in progress for indexPath: %@", indexPath);
        }
    }
    
}

#pragma mark - Utilities

- (void)executeDownloadImageOperationBlockForIndexPath:(NSIndexPath *)indexPath {
    
    NSURL *url = self.imageURLs[indexPath.row];
    NSBlockOperation *blockOperation = [[NSBlockOperation alloc] init];
    __weak NSBlockOperation *weakBlockOperation = blockOperation;
    __weak typeof(self) weakSelf = self;
    
    [blockOperation addExecutionBlock:^{
        if (weakBlockOperation.isCancelled) {
            weakSelf.operations[url] = nil;
            return;
        }
        //NSData *imageData = [NSData dataWithContentsOfURL:url];
        NSData * imageData = [[NSData alloc] initWithContentsOfURL: url];
        UIImage *image = [UIImage imageWithData:imageData];
        weakSelf.images[url] = image;
        weakSelf.operations[url] = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
        NSArray *visibleCellIndexPaths = [weakSelf.collectionView indexPathsForVisibleItems];
        if ([visibleCellIndexPaths containsObject:indexPath]) {
            
            MainCollectionViewCell *cell = (MainCollectionViewCell *)[weakSelf.collectionView cellForItemAtIndexPath:indexPath];
                cell.imageView.image = image;
                [cell.activityIndicator stopAnimating];
            
        }
        });
    }];
    [self.downloadImageOperationQueue addOperation:blockOperation];
    self.operations[url] = blockOperation;
    
}

- (void)cancelDowloandImageOperationBlockForIndexPath:(NSIndexPath *)indexPath {
    
    NSURL *imageURL = self.imageURLs[indexPath.row];
    if (self.operations[imageURL]) {
        NSBlockOperation *blockOperation = self.operations[imageURL];
        [blockOperation cancel];
        self.operations[imageURL] = nil;
    }
}

@end

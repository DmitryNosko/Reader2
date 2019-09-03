//
//  MainViewController.m
//  RSSReader
//
//  Created by Dzmitry Noska on 8/26/19.
//  Copyright © 2019 Dzmitry Noska. All rights reserved.
//

#import "MainViewController.h"
#import "WebViewController.h"
#import "MainTableViewCell.h"
#import "DetailsViewController.h"
#import "FeedItem.h"
#import "RSSParser.h"
#import "MenuViewController.h"
#import "FeedResource.h"
#import "FileManager.h"

@interface MainViewController () <UITableViewDataSource, UITableViewDelegate, MainTableViewCellListener, WebViewControllerListener>
@property (strong, nonatomic) UITableView* tableView;
@property (strong, nonatomic) NSMutableArray<FeedItem *>* feeds;
@property (strong, nonatomic) NSMutableArray<FeedItem *>* updatedFeeds;
@property (strong, nonatomic) RSSParser* rssParser;
@property (strong, nonatomic) FeedItem* feedItem;
@property (strong, nonatomic) FeedResource* feedResource;
@end

static NSString* CELL_IDENTIFIER = @"Cell";
static NSString* PATTERN_FOR_VALIDATION = @"<\/?[A-Za-z]+[^>]*>";
static NSString* URL_TO_PARSE = @"https://news.tut.by/rss/index.rss";
//static NSString* URL_TO_PARSE = @"http://developer.apple.com/news/rss/news.rss";
static NSString* FAVORITES_NEWS_FILE_NIME = @"FAVORITES1.txt";
static NSString* TUT_BY_NEWS_FILE_NAME = @"b";
static NSString* TXT_FORMAT_NAME = @".txt";

@implementation MainViewController

@synthesize listenedItem = _listenedItem;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self configureNavigationBar];
    [self tableViewSetUp];
    self.feeds = [[NSMutableArray alloc] init];
    
    self.feedResource = [[FeedResource alloc] initWithName:TUT_BY_NEWS_FILE_NAME url:[NSURL URLWithString:URL_TO_PARSE]];
    
    self.rssParser = [[RSSParser alloc] init];
    
    __weak MainViewController* weakSelf = self;
    self.rssParser.feedItemDownloadedHandler = ^(FeedItem *item) {
        [weakSelf performSelectorOnMainThread:@selector(addFeedItemToFeeds:) withObject:item waitUntilDone:NO];
    };
    
    [self.rssParser rssParseWithURL:[NSURL URLWithString:URL_TO_PARSE]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(feedResourceWasAddedNotification:)
                                                 name:MenuViewControllerFeedResourceWasAddedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(feedResourceWasChosenNotification:)
                                                 name:MenuViewControllerFeedResourceWasChosenNotification
                                               object:nil];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[FileManager sharedFileManager] saveFeedItems:self.feeds toFileWithName:[NSString stringWithFormat:@"%@%@", self.feedResource.name, TXT_FORMAT_NAME]];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void) handlemenuToggle {
    [self.delegate handleMenuToggle];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.feeds count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MainTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER forIndexPath:indexPath];
    cell.listener = self;
    cell.titleLabel.text = [self.feeds objectAtIndex:indexPath.row].itemTitle;
    
    FeedItem* item = [self.feeds objectAtIndex:indexPath.row];
    
    if (item.isReaded) {
        cell.stateLabel.text = @"readind";
    }
    
    if (item.isFavorite) {
        [cell.favoritesButton setImage:[UIImage imageNamed:@"fullStar"] forState:UIControlStateNormal];
    }
    return cell;
}

#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    FeedItem* item = [self.feeds objectAtIndex:indexPath.row];
    item.isReaded = YES;
    self.listenedItem = item;
    WebViewController* dvc = [[WebViewController alloc] init];
    dvc.listener = self;
    NSString* string = [self.feeds objectAtIndex:indexPath.row].link;
    NSString *stringForURL = [string substringWithRange:NSMakeRange(0, [string length]-6)];
    NSURL* url = [NSURL URLWithString:stringForURL];
    dvc.newsURL = url;
    [self.navigationController pushViewController:dvc animated:YES];
}

-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 80.f;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewAutomaticDimension;
}

- (NSString*) correctDescription:(NSString *) string {
    NSRegularExpression* regularExpression = [NSRegularExpression regularExpressionWithPattern:PATTERN_FOR_VALIDATION
                                                                                       options:NSRegularExpressionCaseInsensitive
                                                                                         error:nil];
    string = [regularExpression stringByReplacingMatchesInString:string
                                                         options:0
                                                           range:NSMakeRange(0, [string length])
                                                    withTemplate:@""];
    return string;
}

- (BOOL) hasRSSLink:(NSString*) link {
    return [[link substringWithRange:NSMakeRange(link.length - 4, 4)] isEqualToString:@".rss"];
}

#pragma mark - MainTableViewCellListener

- (void)didTapOnInfoButton:(MainTableViewCell *)infoButton {
    
    NSIndexPath* indexPath = [self.tableView indexPathForCell:infoButton];
    FeedItem* item = [self.feeds objectAtIndex:indexPath.row];
    
    DetailsViewController* dvc = [[DetailsViewController alloc] init];
    dvc.itemTitleString = item.itemTitle;
    dvc.itemDateString = item.pubDate;
    dvc.itemURLString = item.imageURL;
    dvc.itemDescriptionString = [self correctDescription:item.itemDescription];
    
    [self.navigationController pushViewController:dvc animated:YES];
}

- (void)didTapOnFavoritesButton:(MainTableViewCell *) favoritesButton {
    
    NSIndexPath* indexPath = [self.tableView indexPathForCell:favoritesButton];
    FeedItem* item = [self.feeds objectAtIndex:indexPath.row];
    if (!item.isFavorite) {
        item.isFavorite = YES;
        [[FileManager sharedFileManager] saveFeedItem:item toFileWithName:FAVORITES_NEWS_FILE_NIME];
        [favoritesButton.favoritesButton setImage:[UIImage imageNamed:@"fullStar"] forState:UIControlStateNormal];
    } else {
        item.isFavorite = NO;
        [[FileManager sharedFileManager] removeFeedItem:item fromFile:FAVORITES_NEWS_FILE_NIME];
        [favoritesButton.favoritesButton setImage:[UIImage imageNamed:@"clearStar"] forState:UIControlStateNormal];
    }
    
}

#pragma mark - MainTableViewCellListener

- (void)didTapOnDoneButton:(UIBarButtonItem *)doneButton {
    self.listenedItem.isAvailable = NO;
    NSLog(@"didTapOnDoneButton");
}


#pragma mark - ViewControllerSetUp

- (void) tableViewSetUp {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    [self.tableView registerClass:[MainTableViewCell class] forCellReuseIdentifier:CELL_IDENTIFIER];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self.view addSubview:self.tableView];
    
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
                                              [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor],
                                              [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor],
                                              [self.tableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
                                              [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
                                              ]];
}

- (void) configureNavigationBar {
    self.navigationController.navigationBar.tintColor = [UIColor darkGrayColor];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    
    self.navigationItem.title = @"RSS Reader";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(handlemenuToggle)];
    self.navigationItem.leftBarButtonItem.tintColor = [UIColor whiteColor];
}

#pragma mark - Shake gesture

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    NSThread* thread = [[NSThread alloc] initWithBlock:^{
        [self.rssParser rssParseWithURL:[NSURL URLWithString:URL_TO_PARSE]];
    }];
    [thread start];
    
}

#pragma mark - Notifications

- (void) feedResourceWasAddedNotification:(NSNotification*) notification {
    [self.feeds removeAllObjects];
    self.feedItem = nil;
    self.rssParser = [[RSSParser alloc] init];
    self.feedResource = [notification.userInfo objectForKey:@"resource"];
    __weak MainViewController* weakSelf = self;
    self.rssParser.feedItemDownloadedHandler = ^(FeedItem *item) {
        [weakSelf performSelectorOnMainThread:@selector(addFeedItemToFeeds:) withObject:item waitUntilDone:NO];
    };
    
    [self.rssParser rssParseWithURL:self.feedResource.url];
}

- (void) feedResourceWasChosenNotification:(NSNotification*) notification {
//    [self.feeds removeAllObjects];
//    self.feedItem = nil;
//    self.rssParser = [[RSSParser alloc] init];
//    FeedResource* resource = [notification.userInfo objectForKey:@"resource"];
//    __weak MainViewController* weakSelf = self;
//    self.rssParser.feedItemDownloadedHandler = ^(FeedItem *item) {
//        [weakSelf performSelectorOnMainThread:@selector(addFeedItemToFeeds:) withObject:item waitUntilDone:NO];
//    };
//
//    [self.rssParser rssParseWithURL:resource.url];
    FeedResource* resource = [notification.userInfo objectForKey:@"resource"];
    NSString* str = [NSString stringWithFormat:@"%@%@", resource.name, TXT_FORMAT_NAME];
    NSMutableArray<FeedItem*>* items = [[FileManager sharedFileManager] readFeedItemsFile:str];
    self.feeds = items;
    [self.tableView reloadData];
}

- (void) addFeedItemToFeeds:(FeedItem* ) item {
    if (item) {
        [self.feeds addObject:item];
        [self.tableView reloadData];
    }
}

@end

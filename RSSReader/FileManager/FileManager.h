//
//  FileManager.h
//  RSSReader
//
//  Created by Dzmitry Noska on 8/29/19.
//  Copyright © 2019 Dzmitry Noska. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FeedItem.h"
#import "FeedResource.h"

@interface FileManager : NSObject
+(instancetype) sharedFileManager;

- (void)saveFeedItem:(FeedItem*) item toFileWithName:(NSString*) fileName;
- (void)saveFeedItems:(NSMutableArray<FeedItem*>*) items toFileWithName:(NSString*) fileName;
- (NSMutableArray<FeedItem *> *) readFeedItemsFile:(NSString*) fileName;
- (void) removeFeedItem:(FeedItem *) item  fromFile:(NSString *) fileName;

- (void)saveFeedResource:(FeedResource*) resource toFileWithName:(NSString*) fileName;
- (NSMutableArray<FeedResource *> *) readFeedResourceFile:(NSString*) fileName;
- (void) removeFeedResource:(FeedResource *) resource  fromFile:(NSString *) fileName;

- (void) removeAllObjectsFormFile:(NSString *) fileName;
@end


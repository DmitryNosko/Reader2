//
//  MenuTableViewCell.m
//  RSSReader
//
//  Created by Dzmitry Noska on 8/29/19.
//  Copyright © 2019 Dzmitry Noska. All rights reserved.
//

#import "MenuTableViewCell.h"

@implementation MenuTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setUp];
    }
    return self;
}

- (void) setUp {
    
    self.backgroundColor = [UIColor clearColor];
    
    self.newsLabel = [[UILabel alloc] init];
    self.newsLabel.textAlignment = NSTextAlignmentCenter;
    self.newsLabel.textColor = [UIColor whiteColor];
    self.newsLabel.numberOfLines = 0;
    
    [self.contentView addSubview:self.newsLabel];
    
    self.newsLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
                                              [self.newsLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:10],
                                              [self.newsLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:10],
                                              [self.newsLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-10],
                                              [self.newsLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-10]
                                              ]];
    
}

@end

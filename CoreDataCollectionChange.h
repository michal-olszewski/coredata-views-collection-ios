//
// Created by Kacper Kawecki on 19/07/14.
// Copyright (c) 2014 GenieBelt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class UICollectionView;


@interface CoreDataCollectionChange : NSObject
@property(nonatomic) NSFetchedResultsChangeType changeType;


- (void)performChangeOnView:(UICollectionView *)collectionView;
@end
//
// Created by Kacper Kawecki on 19/07/14.
// Copyright (c) 2014 GenieBelt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CoreDataCollectionChange.h"


@interface CoreDataCollectionObjectChange : CoreDataCollectionChange
@property(nonatomic, strong) NSIndexPath *indexPath;
@property(nonatomic, strong) NSIndexPath *secondIndexPath;
@end
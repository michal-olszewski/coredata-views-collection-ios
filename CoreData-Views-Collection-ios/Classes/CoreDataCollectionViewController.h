//
//  CoreDataCollectionViewController.h
//  QuickInspect
//
//  Created by Kacper Kawecki on 3/2/13.
//  Copyright (c) 2013 Kacper Kawecki. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface CoreDataCollectionViewController : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource, NSFetchedResultsControllerDelegate>

@property(strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property(atomic, strong) UICollectionView *collectionView;

// Set to YES to get some debugging output in the console.
@property BOOL debug;
@property(nonatomic) BOOL suspendAutomaticTrackingOfChangesInManagedObjectContext;

@property(atomic) BOOL additionalCellAtTheBeginning;
@property(atomic) BOOL additionalCellAtTheEnd;

@property(nonatomic) SEL entityTitleSelector;

@property(atomic) BOOL throttleUpdates;

- (void)performFetch;

@end

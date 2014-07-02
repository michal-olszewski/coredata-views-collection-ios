//
//  CoreDataViewCollectionController.h
//  QuickInspect
//
//  Created by Kacper Kawecki on 3/2/13.
//  Copyright (c) 2013 Kacper Kawecki. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface CoreDataViewCollectionController : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource, NSFetchedResultsControllerDelegate>

@property(strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property(nonatomic) BOOL suspendAutomaticTrackingOfChangesInManagedObjectContext;
@property(atomic, strong) UICollectionView *collectionView;
@property BOOL debug;
@property(atomic) BOOL additionalCellAtTheBeginning;
@property(atomic) BOOL additionalCellAtTheEnd;
@property(nonatomic) SEL entityTitleSelector;
@property(atomic) BOOL throttleUpdates;

- (void)performFetch;
@end

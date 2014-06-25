//
//  CoreDataViewCollectionController.m
//  QuickInspect
//
//  Created by Kacper Kawecki on 3/2/13.
//  Copyright (c) 2013 Kacper Kawecki. All rights reserved.
//

#import <CocoaLumberjack/DDLog.h>
#import "CoreDataViewCollectionController.h"
#import "CoreDataViewsCollectionLogging.h"

@interface CoreDataViewCollectionController ()

@property(nonatomic) BOOL beganUpdates;

@end

@implementation CoreDataViewCollectionController

#pragma mark - Properties

@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize suspendAutomaticTrackingOfChangesInManagedObjectContext = _suspendAutomaticTrackingOfChangesInManagedObjectContext;
@synthesize debug = _debug;
@synthesize beganUpdates = _beganUpdates;
@synthesize additionalCellAtTheBeginning;
@synthesize additionalCellAtTheEnd;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.additionalCellAtTheBeginning = NO;
        self.additionalCellAtTheEnd = NO;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.additionalCellAtTheBeginning = NO;
        self.additionalCellAtTheEnd = NO;
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        self.additionalCellAtTheBeginning = NO;
        self.additionalCellAtTheEnd = NO;
    }
    return self;
}

#pragma mark - Fetching

- (void)performFetch {
    if (self.fetchedResultsController) {
        NSError *error;
        [self.fetchedResultsController performFetch:&error];
        if (error) {
            DDLogError(@"[%@ %@] %@ (%@)", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [error localizedDescription], [error localizedFailureReason]);
        }
    } else {
        if (self.debug) {
            DDLogDebug(@"[%@ %@] no NSFetchedResultsController (yet?)", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
        }
    }
    [self.collectionView reloadData];
}

- (void)setFetchedResultsController:(NSFetchedResultsController *)newFetchedResultsController {
    NSFetchedResultsController *oldFetchedResultsController = _fetchedResultsController;
    if (newFetchedResultsController != oldFetchedResultsController) {
        oldFetchedResultsController.delegate = nil;
        _fetchedResultsController = newFetchedResultsController;
        newFetchedResultsController.delegate = self;
        if ((!self.title || [self.title isEqualToString:oldFetchedResultsController.fetchRequest.entity.name]) && (!self.navigationController || !self.navigationItem.title)) {
            self.title = newFetchedResultsController.fetchRequest.entity.name;
        }
        if (newFetchedResultsController != nil) {
            [self performFetch];
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    NSInteger count = [[self.fetchedResultsController sections] count];
    if (count == 0 && (self.additionalCellAtTheBeginning || self.additionalCellAtTheEnd)) {
        count = 1;
    }
    return count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.additionalCellAtTheBeginning) {
        if (section == 0) {
            if ([[self.fetchedResultsController sections] count] == 0) {
                return 1;
            }
            NSInteger count = [[self.fetchedResultsController sections][(NSUInteger) section] numberOfObjects] + 1;
            return count;
        }
    }
    if (self.additionalCellAtTheEnd) {
        if ([[self.fetchedResultsController sections] count] == 0) {
            return 1;
        }
        if (section == ([self numberOfSectionsInCollectionView:collectionView] - 1)) {
            return [[self.fetchedResultsController sections][(NSUInteger) section] numberOfObjects] + 1;
        }
    }
    return [[self.fetchedResultsController sections][(NSUInteger) section] numberOfObjects];
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    if (!self.suspendAutomaticTrackingOfChangesInManagedObjectContext) {
        self.beganUpdates = YES;
    }
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type {
    switch (type) {
        case NSFetchedResultsChangeInsert:
            if (self.additionalCellAtTheEnd && sectionIndex == 0) {
                break;
            }
            [self.collectionView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]];
            break;
        case NSFetchedResultsChangeDelete:
            if (self.additionalCellAtTheEnd && sectionIndex == 0) {
                break;
            }
            [self.collectionView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]];
            break;
        case NSFetchedResultsChangeUpdate:
            [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:sectionIndex]];
            break;
        case NSFetchedResultsChangeMove:
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    if (self.additionalCellAtTheBeginning) {
        if (indexPath && indexPath.section == 0) {
            indexPath = [NSIndexPath indexPathForItem:indexPath.item + 1 inSection:indexPath.section];
        }
        if (indexPath && newIndexPath && newIndexPath.section == 0) {
            newIndexPath = [NSIndexPath indexPathForItem:newIndexPath.item + 1 inSection:indexPath.section];
        }
    }
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.collectionView insertItemsAtIndexPaths:@[newIndexPath]];
            break;
        case NSFetchedResultsChangeDelete:
            [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
            break;
        case NSFetchedResultsChangeUpdate:
            [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
            break;

        case NSFetchedResultsChangeMove:
            [self.collectionView moveItemAtIndexPath:indexPath toIndexPath:newIndexPath];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    if (self.beganUpdates) {
        self.beganUpdates = NO;
    }
}

- (void)endSuspensionOfUpdatesDueToContextChanges {
    _suspendAutomaticTrackingOfChangesInManagedObjectContext = NO;
}

- (void)setSuspendAutomaticTrackingOfChangesInManagedObjectContext:(BOOL)suspend {
    if (suspend) {
        _suspendAutomaticTrackingOfChangesInManagedObjectContext = YES;
    } else {
        [self performSelector:@selector(endSuspensionOfUpdatesDueToContextChanges) withObject:@0 afterDelay:0];
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

- (void)dealloc {
    self.fetchedResultsController.delegate = nil;
    self.fetchedResultsController = nil;
}

@end

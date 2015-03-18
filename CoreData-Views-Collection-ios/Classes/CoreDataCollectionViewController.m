//
//  CoreDataViewController.h
//  QuickInspect
//
//  Created by Kacper Kawecki on 12/19/12.
//  Copyright (c) 2012 Kacper Kawecki. All rights reserved.
//

#import <CocoaLumberjack/CocoaLumberjack.h>
#import "CoreDataCollectionViewController.h"
#import "CoreDataViewsCollectionLogging.h"
#import "CoreDataCollectionSectionChange.h"
#import "CoreDataCollectionObjectChange.h"

@interface CoreDataCollectionViewController ()

@property(nonatomic) BOOL beganUpdates;
@property(nonatomic) NSMutableArray *throttleQueue;
@property(nonatomic) BOOL updateAnimationFinished;
@property(nonatomic, strong) NSMutableArray *updatesCache;
@property(nonatomic, strong) NSNumber *sectionCountCache;
@property(nonatomic, strong) NSArray *itemsCountCache;
@end

@implementation CoreDataCollectionViewController

#pragma mark - Properties

@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize suspendAutomaticTrackingOfChangesInManagedObjectContext = _suspendAutomaticTrackingOfChangesInManagedObjectContext;
@synthesize debug = _debug;
@synthesize beganUpdates = _beganUpdates;
@synthesize additionalCellAtTheBeginning;
@synthesize additionalCellAtTheEnd;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.additionalCellAtTheBeginning = NO;
        self.additionalCellAtTheEnd = NO;
        self.debug = NO;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.additionalCellAtTheBeginning = NO;
        self.additionalCellAtTheEnd = NO;
        self.debug = NO;
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        self.additionalCellAtTheBeginning = NO;
        self.additionalCellAtTheEnd = NO;
        self.debug = NO;
    }
    return self;
}

#pragma mark -
#pragma mark setters and getters

- (NSMutableArray *)updatesCache {
    if (!_updatesCache) {
        _updatesCache = [NSMutableArray array];
    }
    return _updatesCache;
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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

- (void)setFetchedResultsController:(NSFetchedResultsController *)newFetchedResultsController {
    NSFetchedResultsController *oldFetchedResultsController = _fetchedResultsController;
    if (newFetchedResultsController != oldFetchedResultsController) {
        oldFetchedResultsController.delegate = nil;
        _fetchedResultsController = newFetchedResultsController;
        newFetchedResultsController.delegate = self;
        self.updatesCache = nil;
        if (self.entityTitleSelector && [oldFetchedResultsController.fetchRequest.entity respondsToSelector:self.entityTitleSelector] && [newFetchedResultsController.fetchRequest.entity respondsToSelector:self.entityTitleSelector]) {
            if ((!self.title || [self.title isEqualToString:[oldFetchedResultsController.fetchRequest.entity performSelector:self.entityTitleSelector]]) && (!self.navigationController || !self.navigationItem.title)) {
                self.title = [newFetchedResultsController.fetchRequest.entity performSelector:self.entityTitleSelector];
            }
        }
        if (newFetchedResultsController != nil) {
            [self performFetch];
        }
    }
}

#pragma clang diagnostic pop

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    NSInteger count;
    if (self.itemsCountCache) {
        count = [self.sectionCountCache integerValue];
    } else {
        count = [[self.fetchedResultsController sections] count];
    }
    if (count == 0 && (self.additionalCellAtTheBeginning || self.additionalCellAtTheEnd)) {
        count = 1;
    }
    return count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSUInteger sectionCount;
    if (self.sectionCountCache) {
        sectionCount = (NSUInteger) [self.sectionCountCache integerValue];
    } else {
        sectionCount = [[self.fetchedResultsController sections] count];
    }
    NSUInteger itemCount;
    if (self.itemsCountCache) {
        itemCount = (NSUInteger) [self.itemsCountCache[(NSUInteger) section] integerValue];
    } else {
        itemCount = [[self.fetchedResultsController sections][(NSUInteger) section] numberOfObjects];
    }
    if (self.additionalCellAtTheBeginning) {
        if (section == 0) {
            if (sectionCount == 0) {
                return 1;
            }

            return itemCount + 1;
        }
    }
    if (self.additionalCellAtTheEnd) {
        if (sectionCount == 0) {
            return 1;
        }
        if (section == (sectionCount - 1)) {
            return itemCount + 1;
        }
    }
    return itemCount;
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    self.beganUpdates = YES;
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type {
    CoreDataCollectionSectionChange *change;
    switch (type) {
        case NSFetchedResultsChangeInsert:
            if (self.additionalCellAtTheEnd && sectionIndex == 0) {
                break;
            }
        case NSFetchedResultsChangeDelete:
            if (self.additionalCellAtTheEnd && sectionIndex == 0) {
                break;
            }
        case NSFetchedResultsChangeUpdate:
        case NSFetchedResultsChangeMove:
            change = [[CoreDataCollectionSectionChange alloc] init];
            change.changeType = type;
            change.index = sectionIndex;
            if ([self.updatesCache indexOfObject:change] == NSNotFound)
                [self.updatesCache addObject:change];
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
    CoreDataCollectionObjectChange *change = [[CoreDataCollectionObjectChange alloc] init];
    change.indexPath = indexPath;
    change.secondIndexPath = newIndexPath;
    change.changeType = type;
    if ([self.updatesCache indexOfObject:change] == NSNotFound)
        [self.updatesCache addObject:change];
}

- (void)updateFromThrottle {
    [self addToQueue:self.updatesCache];
    self.updatesCache = nil;
    if (self.updateAnimationFinished) {
        [self updateFromQueue];
    }
}

- (NSNumber *)getCurrentSectionCount {
    return @([[self.fetchedResultsController sections] count]);
}

- (NSArray *)getCurrentItemCounts {
    NSMutableArray *result = [NSMutableArray array];
    for (int i = 0; i < [self.fetchedResultsController sections].count; i++) {
        [result addObject:@([[self.fetchedResultsController sections][(NSUInteger) i] numberOfObjects])];
    }
    return result;
}

- (void)addToQueue:(NSMutableArray *)array {
    if (!self.throttleQueue) {
        self.throttleQueue = [[NSMutableArray alloc] init];
    }
    [self.throttleQueue addObject:@{@"changes" : array, @"sections" : [self getCurrentSectionCount], @"items" : [self getCurrentItemCounts]}];
}

- (void)updateFromQueue {
    if (self.throttleQueue.count > 0 && self.fetchedResultsController) {
        self.updateAnimationFinished = NO;
        __weak __block CoreDataCollectionViewController *coreDataCollectionViewController = self;
        [self.collectionView performBatchUpdates:^{
            for (CoreDataCollectionChange *change in [coreDataCollectionViewController.throttleQueue firstObject][@"changes"]) {
                [change performChangeOnView:coreDataCollectionViewController.collectionView];
            }
            coreDataCollectionViewController.sectionCountCache = [coreDataCollectionViewController.throttleQueue firstObject][@"sections"];
            coreDataCollectionViewController.itemsCountCache = [coreDataCollectionViewController.throttleQueue firstObject][@"items"];
            [coreDataCollectionViewController.throttleQueue removeObject:[coreDataCollectionViewController.throttleQueue firstObject]];
        }                             completion:^(BOOL finished) {
            coreDataCollectionViewController.updateAnimationFinished = YES;
            [coreDataCollectionViewController updateFromQueue];
            DDLogInfo(@"Collection view updated with %d", finished);
        }];
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    if (self.beganUpdates) {
        self.beganUpdates = NO;
    }
    if (!self.suspendAutomaticTrackingOfChangesInManagedObjectContext) {
        [self updateFromThrottle];
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

- (void)dealloc {
    _fetchedResultsController.delegate = nil;
    _fetchedResultsController = nil;
}
@end


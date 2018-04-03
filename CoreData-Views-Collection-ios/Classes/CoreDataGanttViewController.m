//
// Created by Michal Olszewski on 11/05/2017.
// Copyright (c) 2017 GenieBelt. All rights reserved.
//

#import "CoreDataGanttViewController.h"
#import "CoreDataViewsCollectionLogging.h"

@import Gb_Gantt.GbGanttView;


@interface CoreDataGanttViewController ()

@property(nonatomic) dispatch_queue_t waitQueue;

@end


@implementation CoreDataGanttViewController

#pragma mark -
#pragma mark - Properties

@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize suspendAutomaticTrackingOfChangesInManagedObjectContext = _suspendAutomaticTrackingOfChangesInManagedObjectContext;
@synthesize debug = _debug;
@synthesize beganUpdates = _beganUpdates;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    [self trackLifetime];
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
    }
    [self trackLifetime];
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        // Custom initialization
    }
    [self trackLifetime];
    return self;
}

#pragma mark -
#pragma mark - LifetimeConfiguration

+ (LifetimeConfiguration *)lifetimeConfiguration {
    return [[LifetimeConfiguration alloc] initWithMaxCount:3 groupName:NSStringFromClass(self.class)];
}

#pragma mark -
#pragma mark - helpers

- (dispatch_queue_t)waitQueue {
    if (!_waitQueue) {
        _waitQueue = dispatch_queue_create("com.coredata-views-collection-ios.cd.wait", nil);
    }
    return _waitQueue;
}

- (void)waitForUpdateEndAndPerformBlock:(void (^)())block {
    if (self.beganUpdates > 0) {
        self.suspendAutomaticTrackingOfChangesInManagedObjectContext = YES;
        __block __weak CoreDataGanttViewController *cdView = self;
        dispatch_async(self.waitQueue, ^{
            while (cdView && cdView.beganUpdates > 0) {
                usleep(10);
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (cdView) {
                    cdView.suspendAutomaticTrackingOfChangesInManagedObjectContext = NO;
                    block();
                }
            });
        });
    } else {
        block();
    }
}

- (void)scrollToOriginAnimated:(BOOL)animated {
    [self.ganttView scrollToOriginAnimated:animated];
}

- (void)reloadData {
    if (self.fetchedResultsController) {
        __weak __block CoreDataGanttViewController *coreDataGanttViewController = self;
        [self waitForUpdateEndAndPerformBlock:^{
            [coreDataGanttViewController.ganttView reloadData];
        }];
    } else {
        [self.ganttView reloadData];
    }
}

#pragma mark -
#pragma mark - Fetching

- (void)performFetch {
    if (self.fetchedResultsController) {
        __weak __block CoreDataGanttViewController *coreDataGanttViewController = self;
        [self waitForUpdateEndAndPerformBlock:^{
            NSError *error;
            [coreDataGanttViewController.fetchedResultsController performFetch:&error];
            if (error) {
                DDLogError(@"[%@ %@] %@ (%@)", NSStringFromClass([coreDataGanttViewController class]), NSStringFromSelector(_cmd), [error localizedDescription], [error localizedFailureReason]);
            }
            [coreDataGanttViewController.ganttView reloadData];
        }];
    } else {
        if (self.debug) {
            DDLogDebug(@"[%@ %@] no NSFetchedResultsController (yet?)", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
        }
        [self.ganttView reloadData];
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

- (void)setFetchedResultsController:(NSFetchedResultsController *)newFetchedResultsController {
    NSFetchedResultsController *oldFetchedResultsController = _fetchedResultsController;
    if (newFetchedResultsController != oldFetchedResultsController) {
        if (!oldFetchedResultsController) {
            self.beganUpdates = 0;
        }
        if (newFetchedResultsController) {
            __weak __block CoreDataGanttViewController *coreDataGanttViewController = self;
            [self waitForUpdateEndAndPerformBlock:^{
                oldFetchedResultsController.delegate = nil;
                self->_fetchedResultsController = newFetchedResultsController;
                newFetchedResultsController.delegate = coreDataGanttViewController;
                if (coreDataGanttViewController.entityTitleSelector && [oldFetchedResultsController.fetchRequest.entity respondsToSelector:coreDataGanttViewController.entityTitleSelector] && [newFetchedResultsController.fetchRequest.entity respondsToSelector:coreDataGanttViewController.entityTitleSelector]) {
                    if (coreDataGanttViewController.autoUpdateTitle && (!coreDataGanttViewController.title || [coreDataGanttViewController.title isEqualToString:[oldFetchedResultsController.fetchRequest.entity performSelector:coreDataGanttViewController.entityTitleSelector]]) && (!coreDataGanttViewController.navigationController || !coreDataGanttViewController.navigationItem.title)) {
                        coreDataGanttViewController.title = [newFetchedResultsController.fetchRequest.entity performSelector:coreDataGanttViewController.entityTitleSelector];
                    }
                }
                if (newFetchedResultsController) {
                    [coreDataGanttViewController performFetch];
                } else {
                    if (coreDataGanttViewController.debug) {
                        DDLogDebug(@"[%@ %@] reset to nil", NSStringFromClass([coreDataGanttViewController class]), NSStringFromSelector(_cmd));
                    }
                    [coreDataGanttViewController.ganttView reloadData];
                }
            }];
        } else {
            _fetchedResultsController = newFetchedResultsController;
            [self.ganttView reloadData];
        }
    }
}

#pragma clang diagnostic pop

#pragma mark -
#pragma mark - Gantt View Data Source

- (NSDate *)startDateOfGanttView:(GbGanttView *)ganttView {
    return nil;
}

- (NSDate *)endDateOfGanttView:(GbGanttView *)ganttView {
    return nil;
}

- (NSInteger)numberOfItemsInGanttView:(GbGanttView *)ganttView {
    return self.fetchedResultsController.fetchedObjects.count;
}

- (GbGanttBaseViewCell *)ganttView:(GbGanttView *)ganttView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

- (BOOL)ganttView:(GbGanttView *)ganttView canMoveItemAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

#pragma mark -
#pragma mark - NSFetchedResultsControllerDelegate

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    if (!self.suspendAutomaticTrackingOfChangesInManagedObjectContext) {
        //TODO review
        [self.ganttView reloadData];
//        switch (type) {
//            case NSFetchedResultsChangeInsert:
//                [self.ganttView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
//                break;
//            case NSFetchedResultsChangeDelete:
//                [self.ganttView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
//                break;
//            case NSFetchedResultsChangeUpdate:
//                [self.ganttView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:self.updateAnimation];
//                break;
//            case NSFetchedResultsChangeMove:
//                [self.ganttView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:self.updateAnimation];
//                [self.ganttView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:self.updateAnimation];
//                break;
//        }
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
    _ganttView.dataSource = nil;
    _ganttView.ganttDelegate = nil;
}

@end

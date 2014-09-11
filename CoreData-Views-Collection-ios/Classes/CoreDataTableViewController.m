//
//  CoreDataViewController.h
//  QuickInspect
//
//  Created by Kacper Kawecki on 12/19/12.
//  Copyright (c) 2012 Kacper Kawecki. All rights reserved.
//

#import <CocoaLumberjack/DDLog.h>
#import "CoreDataTableViewController.h"
#import "CoreDataViewsCollectionLogging.h"

@interface CoreDataTableViewController ()
@property(nonatomic) dispatch_queue_t waitQueue;

@end

@implementation CoreDataTableViewController

#pragma mark - Properties

@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize suspendAutomaticTrackingOfChangesInManagedObjectContext = _suspendAutomaticTrackingOfChangesInManagedObjectContext;
@synthesize debug = _debug;
@synthesize beganUpdates = _beganUpdates;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark - helpers

- (dispatch_queue_t)waitQueue {
    if (!_waitQueue) {
        _waitQueue = dispatch_queue_create("com.coredata-views-collection-ios.cd.wait", nil);
    }
    return _waitQueue;
}

- (void)scrollToTopAnimated:(BOOL)animated {
    BOOL canScroll = ([self numberOfSectionsInTableView:self.tableView] > 0);
    if (canScroll) {
        canScroll = ([self tableView:self.tableView numberOfRowsInSection:0] > 0);
    }
    if (canScroll) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:animated];
    }
}

- (void)waitForUpdateEndAndPerformBlock:(void (^)())block {
    if (self.beganUpdates > 0) {
        __block __weak CoreDataTableViewController *cdView = self;
        dispatch_async(self.waitQueue, ^{
            while (cdView && cdView.beganUpdates > 0) {
                usleep(10);
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (cdView) {
                    block();
                }
            });
        });
    } else {
        block();
    }
}

#pragma mark - Fetching

- (void)performFetch {
    if (self.fetchedResultsController) {
        __block __weak CoreDataTableViewController *coreDataTableViewController = self;
        [self waitForUpdateEndAndPerformBlock:^{
            NSError *error;
            [coreDataTableViewController.fetchedResultsController performFetch:&error];
            if (error) {
                DDLogError(@"[%@ %@] %@ (%@)", NSStringFromClass([coreDataTableViewController class]), NSStringFromSelector(_cmd), [error localizedDescription], [error localizedFailureReason]);
            }
            [coreDataTableViewController.tableView reloadData];
        }];

    } else {
        if (self.debug) {
            DDLogDebug(@"[%@ %@] no NSFetchedResultsController (yet?)", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
        }
        [self.tableView reloadData];
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

- (void)setFetchedResultsController:(NSFetchedResultsController *)newFetchedResultsController {
    NSFetchedResultsController *oldFetchedResultsController = _fetchedResultsController;
    if (!oldFetchedResultsController) {
        self.beganUpdates = 0;
    }
    if (newFetchedResultsController != oldFetchedResultsController) {
        if (newFetchedResultsController) {
            [self waitForUpdateEndAndPerformBlock:^{
                [self scrollToTopAnimated:NO];
                oldFetchedResultsController.delegate = nil;
                _fetchedResultsController = newFetchedResultsController;
                newFetchedResultsController.delegate = self;
                if (self.entityTitleSelector && [oldFetchedResultsController.fetchRequest.entity respondsToSelector:self.entityTitleSelector] && [newFetchedResultsController.fetchRequest.entity respondsToSelector:self.entityTitleSelector]) {
                    if ((!self.title || [self.title isEqualToString:[oldFetchedResultsController.fetchRequest.entity performSelector:self.entityTitleSelector]]) && (!self.navigationController || !self.navigationItem.title)) {
                        self.title = [newFetchedResultsController.fetchRequest.entity performSelector:self.entityTitleSelector];
                    }
                }
                if (newFetchedResultsController) {
                    [self performFetch];
                } else {
                    if (self.debug) {
                        DDLogDebug(@"[%@ %@] reset to nil", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
                    }
                    [self.tableView reloadData];
                }
            }];
        } else {
            [self.tableView reloadData];
        }
    }
}

#pragma clang diagnostic pop

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self.fetchedResultsController sections][(NSUInteger) section] numberOfObjects];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    id o = [self.fetchedResultsController sections][(NSUInteger) section];
    if (self.entityTitleSelector && [o respondsToSelector:@selector(performSelector:)]) {
        return [o performSelector:self.entityTitleSelector];
    }
    return @"";
}

#pragma clang diagnostic pop

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return [self.fetchedResultsController sectionForSectionIndexTitle:title atIndex:index];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return nil;
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    if (!self.suspendAutomaticTrackingOfChangesInManagedObjectContext) {
        [self.tableView beginUpdates];
        self.beganUpdates++;
    }
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type {
    if (!self.suspendAutomaticTrackingOfChangesInManagedObjectContext) {
        switch (type) {
            case NSFetchedResultsChangeInsert:
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
                break;
            case NSFetchedResultsChangeDelete:
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
                break;
            case NSFetchedResultsChangeMove:
                break;
            case NSFetchedResultsChangeUpdate:
                break;
        }
    }
}


- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    if (!self.suspendAutomaticTrackingOfChangesInManagedObjectContext) {
        switch (type) {
            case NSFetchedResultsChangeInsert:
                [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;
            case NSFetchedResultsChangeDelete:
                [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;
            case NSFetchedResultsChangeUpdate:
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;
            case NSFetchedResultsChangeMove:
                [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;
        }
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    if (self.beganUpdates == 1) {
        [self.tableView endUpdates];
    }
    self.beganUpdates--;
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
    self.fetchedResultsController.delegate = nil;
    self.fetchedResultsController = nil;
}

@end


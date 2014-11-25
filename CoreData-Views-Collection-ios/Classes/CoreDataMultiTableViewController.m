//
//  CoreDataMultiTableViewController.m
//  QuickInspect
//
//  Created by Michal Olszewski on 2/7/13.
//  Copyright (c) 2013 Kacper Kawecki. All rights reserved.
//

#import "CoreDataMultiTableViewController.h"
#import "CoreDataViewsCollectionLogging.h"
#import "DDLog.h"

@interface CoreDataMultiTableViewController ()

@property(nonatomic) BOOL beganUpdates;

@end

@implementation CoreDataMultiTableViewController

#pragma mark -
#pragma mark - Properties

@synthesize fetchedResultsControllers = _fetchedResultsControllers;
@synthesize suspendAutomaticTrackingOfChangesInManagedObjectContext = _suspendAutomaticTrackingOfChangesInManagedObjectContext;
@synthesize debug = _debug;
@synthesize beganUpdates = _beganUpdates;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark -
#pragma mark - Fetching

- (void)performFetchForFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController {
    if (fetchedResultsController) {
        NSError *error;
        [fetchedResultsController performFetch:&error];
        if (error) {
            DDLogError(@"[%@ %@] %@ (%@)", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [error localizedDescription], [error localizedFailureReason]);
        }
    } else {
        if (self.debug) {
            DDLogDebug(@"[%@ %@] no NSFetchedResultsController (yet?)", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
        }
    }
    NSUInteger index = [self.fetchedResultsControllers indexOfObject:fetchedResultsController];
    if (index != NSNotFound && index < [self.tableViews count]) {
        UITableView *currentTableView = self.tableViews[index];
        [currentTableView reloadData];
    }
}

- (void)performFetch {
    for (NSFetchedResultsController *controller in [NSArray arrayWithArray:self.fetchedResultsControllers]) {
        [self performFetchForFetchedResultsController:controller];
    }
}

- (void)setFetchedResultsController:(NSFetchedResultsController *)newFetchedResultsController atIndex:(NSUInteger)index {
    NSFetchedResultsController *oldFetchedResultsController = _fetchedResultsControllers[index];
    if (newFetchedResultsController != oldFetchedResultsController) {
        oldFetchedResultsController.delegate = nil;
        [_fetchedResultsControllers insertObject:newFetchedResultsController atIndex:index];
        newFetchedResultsController.delegate = self;
        if (newFetchedResultsController != nil) {
            if (self.debug) {
                DDLogDebug(@"[%@ %@] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), oldFetchedResultsController != nil ? @"updated" : @"set");
            }
            [self performFetchForFetchedResultsController:newFetchedResultsController];
        } else {
            if (self.debug) {
                DDLogDebug(@"[%@ %@] reset to nil", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
            }
            UITableView *currentTableView = self.tableViews[index];
            [currentTableView reloadData];
        }
    }
}

#pragma mark -
#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSUInteger index = [self.tableViews indexOfObject:tableView];
    if (index != NSNotFound && index < [self.fetchedResultsControllers count]) {
        NSFetchedResultsController *currentFetchedResultsController = self.fetchedResultsControllers[index];
        return [[currentFetchedResultsController sections] count];
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSUInteger index = [self.tableViews indexOfObject:tableView];
    if (index != NSNotFound && index < [self.fetchedResultsControllers count]) {
        NSFetchedResultsController *currentFetchedResultsController = self.fetchedResultsControllers[index];
        return [[currentFetchedResultsController sections][(NSUInteger) section] numberOfObjects];
    }
    return 0;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSUInteger index = [self.tableViews indexOfObject:tableView];
    if (index != NSNotFound && index < [self.fetchedResultsControllers count]) {
        NSFetchedResultsController *currentFetchedResultsController = self.fetchedResultsControllers[index];
        id o = [currentFetchedResultsController sections][(NSUInteger) section];
        if (self.entityTitleSelector && [o respondsToSelector:@selector(performSelector:)]) {
            return [o performSelector:self.entityTitleSelector];
        }
    }
    return @"";
}

#pragma clang diagnostic pop

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    NSUInteger arrayIndex = [self.tableViews indexOfObject:tableView];
    if (arrayIndex != NSNotFound && arrayIndex < [self.fetchedResultsControllers count]) {
        NSFetchedResultsController *currentFetchedResultsController = self.fetchedResultsControllers[arrayIndex];
        return [currentFetchedResultsController sectionForSectionIndexTitle:title atIndex:index];
    }
    return 0;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return nil;
}

#pragma mark -
#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    if (!self.suspendAutomaticTrackingOfChangesInManagedObjectContext) {
        NSUInteger index = [self.fetchedResultsControllers indexOfObject:controller];
        if (index != NSNotFound && index < [self.tableViews count]) {
            UITableView *currentTableView = self.tableViews[index];
            [currentTableView beginUpdates];
            self.beganUpdates = YES;
        }
    }
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type {
    if (!self.suspendAutomaticTrackingOfChangesInManagedObjectContext) {
        NSUInteger index = [self.fetchedResultsControllers indexOfObject:controller];
        if (index != NSNotFound && index < [self.tableViews count]) {
            UITableView *currentTableView = self.tableViews[index];
            switch (type) {
                case NSFetchedResultsChangeInsert:
                    [currentTableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
                    break;
                case NSFetchedResultsChangeDelete:
                    [currentTableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
                    break;
                case NSFetchedResultsChangeMove:
                    break;
                case NSFetchedResultsChangeUpdate:
                    break;
            }
        }
    }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    if (!self.suspendAutomaticTrackingOfChangesInManagedObjectContext) {
        NSUInteger index = [self.fetchedResultsControllers indexOfObject:controller];
        if (index != NSNotFound && index < [self.tableViews count]) {
            UITableView *currentTableView = self.tableViews[index];
            switch (type) {
                case NSFetchedResultsChangeInsert:
                    [currentTableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                    break;

                case NSFetchedResultsChangeDelete:
                    [currentTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                    break;

                case NSFetchedResultsChangeUpdate:
                    [currentTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:self.updateAnimation];
                    break;

                case NSFetchedResultsChangeMove:
                    [currentTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:self.updateAnimation];
                    [currentTableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:self.updateAnimation];
                    break;
            }
        }
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    NSUInteger index = [self.fetchedResultsControllers indexOfObject:controller];
    if (index != NSNotFound && index < [self.tableViews count]) {
        if (self.beganUpdates) {
            UITableView *currentTableView = self.tableViews[index];
            [currentTableView endUpdates];
        }
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

#pragma mark -
#pragma mark - Getters and Setters

- (UITableViewRowAnimation)updateAnimation {
    if (!_updateAnimation) {
        _updateAnimation = UITableViewRowAnimationNone;
    }
    return _updateAnimation;
}

@end

//
//  CoreDataTableViewController.m
//  QuickInspect
//
//  Created by Kacper Kawecki on 12/19/12.
//  Copyright (c) 2012 Kacper Kawecki. All rights reserved.
//

#import "CoreDataTableViewController.h"
#import "CoreDataViewsCollectionLogging.h"

@interface CoreDataTableViewController ()
@property(nonatomic) dispatch_queue_t waitQueue;
@property(nonatomic, strong) NSArray *sectionElementsCountCache;
@property(nonatomic) int sectionCountCache;
@end

@implementation CoreDataTableViewController

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

- (void)scrollToTopAnimated:(BOOL)animated {
    BOOL canScroll = NO;
    if (([self numberOfSectionsInTableView:self.tableView] > 0)) {
        canScroll = ([self tableView:self.tableView numberOfRowsInSection:0] > 0);
    }
    if (canScroll) {
        [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:animated];
    }
}

- (void)waitForUpdateEndAndPerformBlock:(void (^)())block {
    if (self.beganUpdates > 0) {
        self.suspendAutomaticTrackingOfChangesInManagedObjectContext = YES;
        __block __weak CoreDataTableViewController *cdView = self;
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

- (void)reloadData {
    if (self.fetchedResultsController) {
        __weak __block CoreDataTableViewController *coreDataViewController = self;
        [self waitForUpdateEndAndPerformBlock:^{
            [coreDataViewController.tableView reloadData];
        }];
    } else {
        [self.tableView reloadData];
    }
}

#pragma mark -
#pragma mark - Fetching

- (void)performFetch {
    if (self.fetchedResultsController) {
        __weak __block CoreDataTableViewController *coreDataViewController = self;
        [self waitForUpdateEndAndPerformBlock:^{
            NSError *error;
            [coreDataViewController.fetchedResultsController performFetch:&error];
            if (error) {
                DDLogError(@"[%@ %@] %@ (%@)", NSStringFromClass([coreDataViewController class]), NSStringFromSelector(_cmd), [error localizedDescription], [error localizedFailureReason]);
            }
            [coreDataViewController.tableView reloadData];
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
    if (newFetchedResultsController != oldFetchedResultsController) {
        if (!oldFetchedResultsController) {
            self.beganUpdates = 0;
        }
        if (newFetchedResultsController) {
            __weak __block CoreDataTableViewController *coreDataViewController = self;
            [self waitForUpdateEndAndPerformBlock:^{
                [coreDataViewController scrollToTopAnimated:NO];
                oldFetchedResultsController.delegate = nil;
                _fetchedResultsController = newFetchedResultsController;
                newFetchedResultsController.delegate = coreDataViewController;
                if (coreDataViewController.entityTitleSelector && [oldFetchedResultsController.fetchRequest.entity respondsToSelector:coreDataViewController.entityTitleSelector] && [newFetchedResultsController.fetchRequest.entity respondsToSelector:coreDataViewController.entityTitleSelector]) {
                    if (coreDataViewController.autoUpdateTitle && (!coreDataViewController.title || [coreDataViewController.title isEqualToString:[oldFetchedResultsController.fetchRequest.entity performSelector:coreDataViewController.entityTitleSelector]]) && (!coreDataViewController.navigationController || !coreDataViewController.navigationItem.title)) {
                        coreDataViewController.title = [newFetchedResultsController.fetchRequest.entity performSelector:coreDataViewController.entityTitleSelector];
                    }
                }
                if (newFetchedResultsController) {
                    [coreDataViewController performFetch];
                } else {
                    if (coreDataViewController.debug) {
                        DDLogDebug(@"[%@ %@] reset to nil", NSStringFromClass([coreDataViewController class]), NSStringFromSelector(_cmd));
                    }
                    [coreDataViewController.tableView reloadData];
                }
            }];
        } else {
            _fetchedResultsController = newFetchedResultsController;
            [self.tableView reloadData];
        }
    }
}

#pragma clang diagnostic pop

#pragma mark -
#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.suspendAutomaticTrackingOfChangesInManagedObjectContext) {
        return self.sectionCountCache;
    }
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.suspendAutomaticTrackingOfChangesInManagedObjectContext) {
        return [self.sectionElementsCountCache[(NSUInteger) section] integerValue];
    }
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

#pragma mark -
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
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:self.updateAnimation];
                break;
            case NSFetchedResultsChangeMove:
                [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:self.updateAnimation];
                [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:self.updateAnimation];
                break;
        }
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    if (self.beganUpdates == 1) {
        [self.tableView endUpdates];
        if (self.suspendAutomaticTrackingOfChangesInManagedObjectContext) {
            self.sectionElementsCountCache = [self sectionElementsCountArray];
            self.sectionCountCache = (int) [self.sectionElementsCountCache count];
        }
    }
    self.beganUpdates--;
}

- (NSArray *)sectionElementsCountArray {
    NSInteger sections = [[self.fetchedResultsController sections] count];
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:(NSUInteger) sections];
    for (int section = 0; section < sections; section++) {
        [result addObject:@([[self.fetchedResultsController sections][(NSUInteger) section] numberOfObjects])];
    }
    return [NSArray arrayWithArray:result];
}

- (void)endSuspensionOfUpdatesDueToContextChanges {
    _suspendAutomaticTrackingOfChangesInManagedObjectContext = NO;
    self.sectionCountCache = 0;
    self.sectionElementsCountCache = nil;
}

- (void)setSuspendAutomaticTrackingOfChangesInManagedObjectContext:(BOOL)suspend {
    if (suspend) {
        _suspendAutomaticTrackingOfChangesInManagedObjectContext = YES;
        if (self.beganUpdates == 0) {
            self.sectionElementsCountCache = [self sectionElementsCountArray];
            self.sectionCountCache = (int) [self.sectionElementsCountCache count];
        }
    } else {
        [self performSelector:@selector(endSuspensionOfUpdatesDueToContextChanges) withObject:@0 afterDelay:0];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

- (void)dealloc {
    _fetchedResultsController.delegate = nil;
    _fetchedResultsController = nil;
    _tableView.dataSource = nil;
    _tableView.delegate = nil;
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

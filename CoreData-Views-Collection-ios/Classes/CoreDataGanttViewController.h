//
// Created by Michal Olszewski on 11/05/2017.
// Copyright (c) 2017 GenieBelt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "LifetimeTracker-Swift.h"

@import Gb_Gantt.GbGanttDataSource;


@interface CoreDataGanttViewController : UIViewController <GbGanttDataSource, NSFetchedResultsControllerDelegate, LifetimeTrackable>

// The controller (this class fetches nothing if this is not set).
@property(strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property(nonatomic) SEL entityTitleSelector;

// Causes the fetchedResultsController to re-fetch the data.
// You almost certainly never need to call this.
// The NSFetchedResultsController class observes the context
//  (so if the objects in the context change, you do not need to call performFetch
//   since the NSFetchedResultsController will notice and update the table automatically).
// This will also automatically be called if you change the fetchedResultsController @property.
- (void)performFetch;

- (void)waitForUpdateEndAndPerformBlock:(void (^)())block;

- (void)scrollToOriginAnimated:(BOOL)animated;

- (void)reloadData;


// Turn this on before making any changes in the managed object context that
//  are a one-for-one result of the user manipulating rows directly in the table view.
// Such changes cause the context to report them (after a brief delay),
//  and normally our fetchedResultsController would then try to update the table,
//  but that is unnecessary because the changes were made in the table already (by the user)
//  so the fetchedResultsController has nothing to do and needs to ignore those reports.
// Turn this back off after the user has finished the change.
// Note that the effect of setting this to NO actually gets delayed slightly
//  so as to ignore previously-posted, but not-yet-processed context-changed notifications,
//  therefore it is fine to set this to YES at the beginning of, e.g., tableView:moveRowAtIndexPath:toIndexPath:,
//  and then set it back to NO at the end of your implementation of that method.
// It is not necessary (in fact, not desirable) to set this during row deletion or insertion
//  (but definitely for row moves).
@property(nonatomic) BOOL suspendAutomaticTrackingOfChangesInManagedObjectContext;
@property(nonatomic) BOOL autoUpdateTitle;
@property(nonatomic, strong) GbGanttView *ganttView;
// Set to YES to get some debugging output in the console.
@property BOOL debug;

@property(atomic) int beganUpdates;

@end

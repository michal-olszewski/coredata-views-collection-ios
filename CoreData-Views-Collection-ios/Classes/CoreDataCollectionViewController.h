#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface CoreDataCollectionViewController : UICollectionViewController <NSFetchedResultsControllerDelegate>

@property(strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

- (void)performFetch;

@property(nonatomic) BOOL suspendAutomaticTrackingOfChangesInManagedObjectContext;

// Set to YES to get some debugging output in the console.
@property BOOL debug;
@property(atomic) BOOL additionalCellAtTheBegining;
@property(atomic) BOOL additionalCellAtTheEnd;
@end

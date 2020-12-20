NS_ASSUME_NONNULL_BEGIN

@protocol CoreDataStack
    @property (nonatomic, readonly, strong) NSManagedObjectContext *mainContext;
    @property (nonatomic, readonly, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
    @property (nonatomic, readonly, strong) NSManagedObjectModel *managedObjectModel;
    - (NSManagedObjectContext *const)newDerivedContext;
    - (NSManagedObjectContext *const)newMainContextChildContext;
    - (void)saveContextAndWait:(NSManagedObjectContext *)context;
    - (void)saveContext:(NSManagedObjectContext *)context;
    - (void)saveContext:(NSManagedObjectContext *)context withCompletionBlock:(void (^)(void))completionBlock;
    - (BOOL)obtainPermanentIDForObject:(NSManagedObject *)managedObject;
    - (void)mergeChanges:(NSManagedObjectContext *)context fromContextDidSaveNotification:(NSNotification *)notification;
@end

NS_ASSUME_NONNULL_END

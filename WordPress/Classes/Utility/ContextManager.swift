import Foundation
import UIKit

@objc
class ContextManager: NSObject {

    typealias CoreDataInitializationCallback = (Result<(), Error>) -> Void

    typealias CoreDataWriteBlock = (NSManagedObjectContext) -> Void

    typealias CoreDataWriteCompletionBlock = (Result<(), Error>) -> Void

    private let modelName = "WordPress"

    private let container: NSPersistentContainer

    /// Instead of having an orphaned object, retrieve the ContextManager from the App Delegate
    static var shared: ContextManager {
        return (UIApplication.shared.delegate as! WordPressAppDelegate).contextManager
    }

    /// For compatibility
    @objc
    static func sharedInstance() -> ContextManager {
        return shared
    }

    /// Only for tests, do not use this method directly
    override init() {
        ValueTransformer.registerCustomTransformers()
        let container = NSPersistentContainer(name: modelName)

        let storeDescription = NSPersistentStoreDescription(url: container.modelUrl)
        storeDescription.shouldMigrateStoreAutomatically = false
        storeDescription.shouldAddStoreAsynchronously = true /// Don't tie up the main thread doing DB initialization – we get a callback anyway
        container.persistentStoreDescriptions = [storeDescription]

        self.container = container

        /// Because we're an `NSObject`
        super.init()
    }

    func initialize(onCompletion: @escaping CoreDataInitializationCallback) {
        do {
            try CoreDataIterativeMigrator.interativelyMigrate(sourceStore: container.storeUrl, toModelAtUrl: container.modelUrl)
            loadPersistentStores { result in
                /// If we didn't succeed, bail here
                guard case .success = result else {
                    onCompletion(result)
                    return
                }

                self.performChangesAndSave({ context in
                    NullBlogPropertySanitizer(context: context).sanitize()
                }, onCompletion: onCompletion)
            }
            loadPersistentStores(callback: onCompletion)
        }
        catch let err {
            onCompletion(.failure(err))
        }
    }

    private func loadPersistentStores(callback: @escaping CoreDataInitializationCallback) {
        _ = container.persistentStoreDescriptions
        container.loadPersistentStores { [weak self] (store, error) in
            guard self != nil else {
                return
            }

            debugPrint(store)

            if let error = error {
                callback(.failure(error))
            }
        }
    }

    var readContext: NSManagedObjectContext {
        return container.viewContext
    }

    func performChangesAndSave(_ changes:(NSManagedObjectContext) -> Void) -> Result<Void, Error> {

        var error: Error?

        let writerContext = container.newBackgroundContext()
        writerContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        writerContext.performAndWait {
            changes(writerContext)

            do {
                try writerContext.save()
            } catch let err {
                error = err
            }
        }

        if let error = error {
            return .failure(error)
        }

        return .success(())
    }

    func performChangesAndSave(_ callback: @escaping CoreDataWriteBlock, onCompletion: CoreDataWriteCompletionBlock?) {
        let writerContext = container.newBackgroundContext()
        writerContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        writerContext.perform {
            callback(writerContext)

            do {
                try self.saveChanges(to: writerContext)
                onCompletion?(.success(()))
            } catch let err {
                onCompletion?(.failure(err))
            }
        }
    }

    private func saveChanges(to context: NSManagedObjectContext) throws {

        guard context.hasChanges else {
            return
        }

        try context.save()
    }

    // Error handling
    private lazy var sentryStartupError: SentryStartupEvent = {
        return SentryStartupEvent()
    }()
}

extension ContextManager: CoreDataStack {
    var mainContext: NSManagedObjectContext {
        container.viewContext
    }

    var persistentStoreCoordinator: NSPersistentStoreCoordinator {
        container.persistentStoreCoordinator
    }

    var managedObjectModel: NSManagedObjectModel {
        container.managedObjectModel
    }

    func newDerivedContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }

    func newMainContextChildContext() -> NSManagedObjectContext {
        container.viewContext
    }

    func saveContextAndWait(_ context: NSManagedObjectContext) {
        try? saveChanges(to: context)
    }

    func save(_ context: NSManagedObjectContext) {
        try? saveChanges(to: context)
    }

    func save(_ context: NSManagedObjectContext, withCompletionBlock completionBlock: @escaping () -> Void) {
        try? saveChanges(to: context)
    }

    func obtainPermanentID(for managedObject: NSManagedObject) -> Bool {
        do {
            try container.viewContext.obtainPermanentIDs(for: [managedObject])
            return true
        } catch _ {
            return false
        }
    }

    func mergeChanges(_ context: NSManagedObjectContext, fromContextDidSave notification: UIKit.Notification) {
        // No-op – NSPersistentContainer handles this for us
    }
}

extension NSPersistentContainer {
    var modelUrl: URL {
        Bundle.main.url(forResource: name, withExtension: "momd")!
    }

    var versionInfoUrl: URL {
        modelUrl.appendingPathComponent("VersionInfo.plist")
    }

    var storeUrl: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(name + ".sqlite")
    }
}

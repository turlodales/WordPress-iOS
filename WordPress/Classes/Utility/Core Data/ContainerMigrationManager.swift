import Foundation
import CoreData

enum ModelVersion {
    case version(version: String)
    case latest
}

struct CoreDataMigrationStep {
    let source: NSManagedObjectModel
    let destination: NSManagedObjectModel
    let mappingModel: NSMappingModel
}


struct CoreDataMigrationModel {
    let modelUrl: URL
    let storeUrl: URL
    let modelVersion: String
    let storeVersion: String
    let migrationSteps: [CoreDataMigrationStep] = []

    init(
        modelUrl: URL,
        storeUrl: URL,
        configurationName: String? = nil,
        fileManager: FileManager = .default) throws {

        self.modelUrl = modelUrl
        self.storeUrl = storeUrl

        let rawModel = try XCDataModel.fromModelAt(modelUrl)
        
        /// Find the starting and ending model versions
        let newestVersionPath = modelUrl.appendingPathComponent(rawModel.currentVersion).appendingPathExtension("mom")
        guard FileManager.default.fileExists(atPath: newestVersionPath.path) else {
            fatalError("TODO – this should throw instead")
        }
        
        var modelCache = [String: NSManagedObjectModel]()
        var currentModelName: String?

        let currentMetadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeUrl, options: nil)

        /// Work backward through the model versions until we find the one this store is currently using
        for versionPath in rawModel.versionPaths(relativeTo: modelUrl).reversed() {
            guard
                FileManager.default.fileExists(atPath: versionPath.path),
                let model = NSManagedObjectModel(contentsOf: versionPath)
            else {
                continue
            }

            let modelName = versionPath.deletingPathExtension().lastPathComponent
            modelCache[modelName] = model

            if model.isConfiguration(withName: nil, compatibleWithStoreMetadata: currentMetadata) {
                currentModelName = modelName
                break
            }
        }
        
        guard let storeVersion = currentModelName else {
            fatalError("TODO – this should throw instead")
        }
        
        self.modelVersion = rawModel.currentVersion
        self.storeVersion = storeVersion
    }

        


        //        let versionPaths: [String] = try fileManager.contentsOfDirectory(atPath: modelUrl.path)
//
//        guard
//            let pathToCurrentModel = versionPaths.first(where: { $0.deletingPathExtension().lastPathComponent == rawModel.currentVersion }),
//            let currentModel = NSManagedObjectModel(contentsOf: pathToCurrentModel)
//        else {
//            fatalError("TODO – this should throw instead")
//        }
//
//        let endingVersion = CoreDataModelVersion(versionName: rawModel.currentVersion, managedObjectModel: currentModel)
        

//        guard let startingVersion = versionPaths.first(where: {
//            guard let model = NSManagedObjectModel(contentsOf: $0) else {
//                return false
//            }
//
//            return model.isConfiguration(withName: configurationName, compatibleWithStoreMetadata: currentMetadata)
//        }) else {
//            fatalError("TODO – this should throw instead")
//        }
    }
    

struct CoreDataModelVersion {
    let versionName: String
    let managedObjectModel: NSManagedObjectModel
}

struct CoreDataMigrationManager {

    private let storeUrl: URL
    private let modelUrl: URL

    init(storeUrl: URL, modelUrl: URL) {
        self.storeUrl = storeUrl
        self.modelUrl = modelUrl
    }

    func migrateStore(to: ModelVersion = .latest) throws {

        
        let migrationModel = try CoreDataMigrationModel(modelUrl: modelUrl, storeUrl: storeUrl)

        
        /// Use the same location for every migration to avoid using up a huge amount of user's available space
        let temporaryPath = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        
//        try rawModel.migrationSteps.forEach {
//            let manager = NSMigrationManager(sourceModel: $0.source, destinationModel: $0.destination)
//
//            try manager.migrateStore(
//                from: storeUrl,
//                sourceType: NSSQLiteStoreType,
//                options: nil,
//                with: $0.mappingModel,
//                toDestinationURL: temporaryPath,
//                destinationType: NSSQLiteStoreType,
//                destinationOptions: nil
//            )
//
//            try replaceStore(withStoreAt: temporaryPath)
//        }
    }

    func replaceStore(withStoreAt replacement: URL) throws {
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel())
        try persistentStoreCoordinator.replacePersistentStore(
            at: storeUrl,
            destinationOptions: nil,
            withPersistentStoreFrom: replacement,
            sourceOptions: nil,
            ofType: NSSQLiteStoreType
        )
    }

//    private func migrationStepsForStore(at storeURL: URL, toVersion destinationVersion: CoreDataMigrationVersion) -> [CoreDataMigrationStep] {
//        guard let metadata = NSPersistentStoreCoordinator.metadata(at: storeURL), let sourceVersion = CoreDataMigrationVersion.compatibleVersionForStoreMetadata(metadata) else {
//            fatalError("unknown store version at URL \(storeURL)")
//        }
//
//        return migrationSteps(fromSourceVersion: sourceVersion, toDestinationVersion: destinationVersion)
//    }
//
//    private func migrationSteps(fromSourceVersion sourceVersion: CoreDataMigrationVersion, toDestinationVersion destinationVersion: CoreDataMigrationVersion) -> [CoreDataMigrationStep] {
//        var sourceVersion = sourceVersion
//        var migrationSteps = [CoreDataMigrationStep]()
//
//        while sourceVersion != destinationVersion, let nextVersion = sourceVersion.nextVersion() {
//            let migrationStep = CoreDataMigrationStep(sourceVersion: sourceVersion, destinationVersion: nextVersion)
//            migrationSteps.append(migrationStep)
//
//            sourceVersion = nextVersion
//        }
//
//        return migrationSteps
//    }

    
    func migrateIfNeeded() throws {
        guard needsMigration else {
            return
        }

        DDLogWarn("⚠️ [CoreDataManager] Migration required for persistent store")

//        let versionInfo = model.entityVersionHashesByName
//            .keys
//            .sorted()

//        try CoreDataIterativeMigrator.iterativeMigrate(
//            sourceStore: storeURL,
//            storeType: NSSQLiteStoreType,
//            to: objectModel,
//            using: versionInfo
//        )
    }

    var needsMigration: Bool {
        return false
//        guard FileManager.default.fileExists(atPath: storePath) else {
//            DDLogInfo("No store exists at URL \(storeURL).  Skipping migration.")
//            return false
//        }
//
//        do {
//            let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
//                ofType: NSSQLiteStoreType,
//                at: storeURL,
//                options: nil
//            )
//
//            /// If the ManagedObjectModel's configuration is compatible with this store, no further action is necessary – they two are in sync
//            return objectModel.isConfiguration(withName: "Default", compatibleWithStoreMetadata: metadata)
//
//        } catch let err {
//            DDLogInfo("Error fetching persistent store metadata: \(err)")
//            return false
//        }
    }

}

import CoreData
import Foundation

final class PersistenceController {
    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let model = Self.managedObjectModel()
        container = NSPersistentContainer(name: "LunarCalendarCache", managedObjectModel: model)

        let description = NSPersistentStoreDescription()
        description.type = NSSQLiteStoreType
        if inMemory {
            description.url = URL(fileURLWithPath: "/dev/null")
        } else {
            description.url = URL.applicationSupportDirectory.appending(path: "LunarCalendarCache.sqlite")
        }

        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Failed to load persistent store: \(error)")
            }
        }

        container.viewContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    private static func managedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let entity = NSEntityDescription()
        entity.name = "CachedAgendaItem"
        entity.managedObjectClassName = NSStringFromClass(CachedAgendaItem.self)

        func attribute(
            name: String,
            type: NSAttributeType,
            isOptional: Bool = false
        ) -> NSAttributeDescription {
            let attribute = NSAttributeDescription()
            attribute.name = name
            attribute.attributeType = type
            attribute.isOptional = isOptional
            return attribute
        }

        entity.properties = [
            attribute(name: "id", type: .stringAttributeType),
            attribute(name: "kind", type: .stringAttributeType),
            attribute(name: "sourceIdentifier", type: .stringAttributeType),
            attribute(name: "sourceTitle", type: .stringAttributeType),
            attribute(name: "title", type: .stringAttributeType),
            attribute(name: "startDate", type: .dateAttributeType, isOptional: true),
            attribute(name: "endDate", type: .dateAttributeType, isOptional: true),
            attribute(name: "isAllDay", type: .booleanAttributeType),
            attribute(name: "isCompleted", type: .booleanAttributeType),
            attribute(name: "dayAnchor", type: .dateAttributeType),
            attribute(name: "updatedAt", type: .dateAttributeType),
        ]
        entity.uniquenessConstraints = [["id"]]

        model.entities = [entity]
        return model
    }
}

private extension URL {
    static var applicationSupportDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = base.appending(path: "LunarCalendarApp", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}

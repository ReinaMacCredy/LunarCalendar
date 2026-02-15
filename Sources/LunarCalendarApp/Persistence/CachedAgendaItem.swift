import CoreData
import Foundation

@objc(CachedAgendaItem)
final class CachedAgendaItem: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var kind: String
    @NSManaged var sourceIdentifier: String
    @NSManaged var sourceTitle: String
    @NSManaged var title: String
    @NSManaged var startDate: Date?
    @NSManaged var endDate: Date?
    @NSManaged var isAllDay: Bool
    @NSManaged var isCompleted: Bool
    @NSManaged var dayAnchor: Date
    @NSManaged var updatedAt: Date
}

extension CachedAgendaItem {
    @nonobjc class func fetchRequest() -> NSFetchRequest<CachedAgendaItem> {
        NSFetchRequest<CachedAgendaItem>(entityName: "CachedAgendaItem")
    }
}

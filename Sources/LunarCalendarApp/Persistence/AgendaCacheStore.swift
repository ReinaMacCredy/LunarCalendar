import CoreData
import Foundation

actor AgendaCacheStore {
    private let container: NSPersistentContainer
    private let calendar = Calendar(identifier: .gregorian)

    init(container: NSPersistentContainer = PersistenceController().container) {
        self.container = container
    }

    func replace(items: [AgendaItem], in interval: DateInterval) async throws {
        try await withCheckedThrowingContinuation { continuation in
            container.performBackgroundTask { context in
                do {
                    let fetch = NSFetchRequest<NSManagedObjectID>(entityName: "CachedAgendaItem")
                    fetch.resultType = .managedObjectIDResultType
                    fetch.predicate = NSPredicate(
                        format: "dayAnchor >= %@ AND dayAnchor < %@",
                        interval.start as NSDate,
                        interval.end as NSDate
                    )

                    let objectIDs = try context.fetch(fetch)
                    for objectID in objectIDs {
                        if let object = try? context.existingObject(with: objectID) {
                            context.delete(object)
                        }
                    }

                    for item in items {
                        let object = CachedAgendaItem(context: context)
                        object.id = item.id
                        object.kind = item.kind.rawValue
                        object.sourceIdentifier = item.sourceIdentifier
                        object.sourceTitle = item.sourceTitle
                        object.title = item.title
                        object.startDate = item.startDate
                        object.endDate = item.endDate
                        object.isAllDay = item.isAllDay
                        object.isCompleted = item.isCompleted
                        object.dayAnchor = self.calendar.startOfDay(for: item.sortDate)
                        object.updatedAt = .now
                    }

                    if context.hasChanges {
                        try context.save()
                    }

                    continuation.resume()
                } catch {
                    context.rollback()
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func dayAgenda(for date: Date) async throws -> [AgendaItem] {
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart

        return try await withCheckedThrowingContinuation { continuation in
            container.performBackgroundTask { context in
                do {
                    let request = NSFetchRequest<NSManagedObjectID>(entityName: "CachedAgendaItem")
                    request.resultType = .managedObjectIDResultType
                    request.predicate = NSPredicate(
                        format: "dayAnchor >= %@ AND dayAnchor < %@",
                        dayStart as NSDate,
                        dayEnd as NSDate
                    )

                    let ids = try context.fetch(request)
                    var result: [AgendaItem] = []
                    result.reserveCapacity(ids.count)

                    for objectID in ids {
                        guard
                            let object = try context.existingObject(with: objectID) as? CachedAgendaItem,
                            let kind = AgendaKind(rawValue: object.kind)
                        else {
                            continue
                        }

                        result.append(
                            AgendaItem(
                                id: object.id,
                                kind: kind,
                                sourceIdentifier: object.sourceIdentifier,
                                sourceTitle: object.sourceTitle,
                                title: object.title,
                                startDate: object.startDate,
                                endDate: object.endDate,
                                isAllDay: object.isAllDay,
                                isCompleted: object.isCompleted
                            )
                        )
                    }

                    result.sort { lhs, rhs in
                        if lhs.sortDate == rhs.sortDate {
                            return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
                        }
                        return lhs.sortDate < rhs.sortDate
                    }

                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

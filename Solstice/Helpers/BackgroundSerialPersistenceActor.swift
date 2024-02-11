import Foundation
import SwiftData

/// ```swift
///  // It is important that this actor works as a mutex,
///  // so you must have one instance of the Actor for one container
//   // for it to work correctly.
///  let actor = BackgroundSerialPersistenceActor(container: modelContainer)
///
///  Task {
///      let data: [MyModel] = try? await actor.fetchData()
///  }
///  ```
@available(iOS 17, *)
public actor BackgroundSerialPersistenceActor: ModelActor {
	
	public let modelContainer: ModelContainer
	public let modelExecutor: any ModelExecutor
	private var context: ModelContext { modelExecutor.modelContext }
	
	public init(container: ModelContainer) {
		self.modelContainer = container
		let context = ModelContext(modelContainer)
		modelExecutor = DefaultSerialModelExecutor(modelContext: context)
	}
	
	public func fetchData<T: PersistentModel>(
		predicate: Predicate<T>? = nil,
		sortBy: [SortDescriptor<T>] = []
	) throws -> [T] {
		let fetchDescriptor = FetchDescriptor<T>(predicate: predicate, sortBy: sortBy)
		let list: [T] = try context.fetch(fetchDescriptor)
		return list
	}
	
	public func fetch<T: PersistentModel>(
		_ fetchDescriptor: FetchDescriptor<T>
	) throws -> [T] {
		let list: [T] = try context.fetch(fetchDescriptor)
		return list
	}
	
	public func fetchCount<T: PersistentModel>(
		predicate: Predicate<T>? = nil,
		sortBy: [SortDescriptor<T>] = []
	) throws -> Int {
		let fetchDescriptor = FetchDescriptor<T>(predicate: predicate, sortBy: sortBy)
		let count = try context.fetchCount(fetchDescriptor)
		return count
	}
	
	public func insert<T: PersistentModel>(data: T) {
		let context = data.modelContext ?? context
		context.insert(data)
	}
	
	public func save() throws {
		try context.save()
	}
	
	public func remove<T: PersistentModel>(predicate: Predicate<T>? = nil) throws {
		try context.delete(model: T.self, where: predicate)
	}
	
	public func saveAndInsertIfNeeded<T: PersistentModel>(
		data: T,
		predicate: Predicate<T>
	) throws {
		let descriptor = FetchDescriptor<T>(predicate: predicate)
		let context = data.modelContext ?? context
		let savedCount = try context.fetchCount(descriptor)
		
		if savedCount == 0 {
			context.insert(data)
		}
		try context.save()
	}
}

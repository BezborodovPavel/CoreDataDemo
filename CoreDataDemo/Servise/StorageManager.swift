//
//  StorageManager.swift
//  CoreDataDemo
//
//  Created by Павел on 27.05.2022.
//

import Foundation
import CoreData
import UIKit

enum DataError: String, Error { //do it
    case failedFetchData = "Failed to fetch data"
    case failedGetEntity = "Failed get entity description"
    case failedGetManagedObject = "Failed get NSManagedObject"
    case failedSaveContext = "Failed save context"
    case noTaskInDataBase = "No this task in database"
}

class StorageManager {
    
    static let shared = StorageManager()
    private let context: NSManagedObjectContext
    private let persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "CoreDataDemo")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    private init() {
        context = persistentContainer.viewContext
    }
    
    func fetchData() -> Result<[Task], DataError>{
        
        var taskList: [Task] = []        
        let fetchRequest = Task.fetchRequest()
        
        do {
            taskList = try context.fetch(fetchRequest)
            return Result.success(taskList)
        } catch {
            return Result.failure(.failedFetchData)
        }
    }
    
    func saveContext() -> Result<Bool, DataError>{

        if context.hasChanges {
            do {
                try context.save()
                return .success(true)
            } catch {
                return .failure(.failedSaveContext)
            }
        }
        return .success(false)
    }
    
    func saveTask(_ taskName: String) -> Result<Task, DataError>{
        
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "Task", in: context) else { return Result.failure(.failedGetEntity) }
        guard let task = NSManagedObject(entity: entityDescription, insertInto: context) as? Task else { return .failure(.failedGetManagedObject)}
        task.title = taskName
        
        switch saveContext() {
        case .success(_):
            return .success(task)
        case .failure(let saveError):
            return .failure(saveError)
        }
    }
    
    func editTask(_ task: Task, newTitle: String)-> Result<Task, DataError>{
            task.title = newTitle
            switch saveContext() {
            case .success(_):
                return .success(task)
            case .failure(let saveError):
                return .failure(saveError)
            }
    }
    
    func deleteTask(_ task: Task) -> Result<Bool, DataError>{
            context.delete(task)
            return saveToContext()
    }
    
    private func saveToContext() -> Result<Bool, DataError>{
        switch saveContext() {
        case .success(_):
            return .success(true)
        case .failure(let saveError):
            return .failure(saveError)
        }
    }
    
}

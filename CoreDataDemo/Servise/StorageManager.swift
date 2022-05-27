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
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    private init() {}
    
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
    
    func editTask(_ index: Int, newTitle: String)-> Result<Task, DataError>{
        let task = getTaskAt(index)
        switch task {
        case .success(let returnedTask):
            guard let task = returnedTask else {
                return .failure(.noTaskInDataBase)
            }
            task.title = newTitle
            switch saveContext() {
            case .success(_):
                return .success(task)
            case .failure(let saveError):
                return .failure(saveError)
            }
        case .failure(let errorGetTask):
            return .failure(errorGetTask)
        }
    }
    
    func deleteTask(_ index: Int) -> Result<Bool, DataError>{

        let task = getTaskAt(index)
        switch task {
        case .success(let returnedTask):
            guard let task = returnedTask else {
                return .success(false)
            }
            
            context.delete(task)
            
            switch saveContext() {
            case .success(_):
                return .success(true)
            case .failure(let saveError):
                return .failure(saveError)
            }
            
        case .failure(let errorGetTask):
            return .failure(errorGetTask)
        }
    }
    
    
    private func getTaskAt(_ index: Int) -> Result<Task?, DataError>{
       
        let fetchRequest = Task.fetchRequest()
        fetchRequest.fetchLimit = 1
        fetchRequest.fetchOffset = index
        
        var tasks: [Task] = []
        do {
            tasks = try context.fetch(fetchRequest)
            return Result.success(tasks.first)
        } catch {
            return Result.failure(.failedFetchData)
        }
    }
    
}

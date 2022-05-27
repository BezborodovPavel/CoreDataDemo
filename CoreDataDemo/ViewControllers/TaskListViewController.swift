//
//  TaskListViewController.swift
//  CoreDataDemo
//
//  Created by Alexey Efimov on 04.10.2021.
//

import UIKit

class TaskListViewController: UITableViewController {
    
    private let cellID = "task"
    private let storageManager = StorageManager.shared
    private var taskList: [Task] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
        tableView.allowsSelection = false
        setupNavigationBar()
        fetchData()
    }

    private func setupNavigationBar() {
        title = "Task List"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let navBarAppearance = UINavigationBarAppearance()
        
        navBarAppearance.backgroundColor = UIColor(
            red: 21/255,
            green: 101/255,
            blue: 192/255,
            alpha: 194/255
        )
        
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addNewTask)
        )
        
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
    }
    
    @objc private func addNewTask() {
        showAlert(
            with: "New Task",
            and: "What do you want to do?",
            placeholder: "New Task") { alert in
            guard let task = alert.textFields?.first?.text, !task.isEmpty else { return }
            self.save(task)
        }
    }
    
    private func fetchData() {
        
        let resultFetch = storageManager.fetchData()
        switch resultFetch {
        case .success(let fetchTaskList):
            taskList = fetchTaskList
        case .failure(let dataError):
            print(dataError.rawValue)
        }
    }
    
    private func showAlert(with title: String, and message: String, placeholder: String, action: @escaping (UIAlertController) -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            action(alert)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive)
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        alert.addTextField { textField in
            textField.placeholder = placeholder
        }
        present(alert, animated: true)
    }
    
    private func save(_ taskName: String) {
        
        let saveResult = storageManager.saveTask(taskName)
        
        switch saveResult {
        case .success(let task):
            
            taskList.append(task)
            let cellIndex = IndexPath(row: taskList.count - 1, section: 0)
            tableView.insertRows(at: [cellIndex], with: .automatic)

        case .failure(let saveError):
            print(saveError.rawValue)
        }
    }
}

// MARK: - UITableViewDataSource
extension TaskListViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        taskList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        let task = taskList[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = task.title
        cell.contentConfiguration = content
        cell.accessoryType = .detailButton
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let resultDeleting = storageManager.deleteTask(indexPath.row)
            switch resultDeleting {
            case .success(let isDeleted):
                if isDeleted {
                    taskList.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                }
            case .failure(let errorDelete):
                print(errorDelete.rawValue)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
 
        showAlert(
            with: "Edit Task",
            and: "What do you want edit?",
            placeholder: taskList[indexPath.row].title ?? "") { alert in
                guard let newTaskTitle = alert.textFields?.first?.text, !newTaskTitle.isEmpty else { return }
                let editingResult = self.storageManager.editTask(indexPath.row, newTitle: newTaskTitle)
                switch editingResult {
                case .success(let task):
                    self.taskList[indexPath.row] = task
                    tableView.reloadRows(at: [indexPath], with: .middle)
                case .failure(let editingError):
                    print(editingError.rawValue)
                }
            }
    }
}

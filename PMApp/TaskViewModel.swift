import Foundation
import SwiftUI

class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = [] {
        didSet {
            saveTasks()
        }
    }
    @Published var searchText = ""
    @Published var selectedCategory: TaskCategory?
    @Published var selectedPriority: TaskPriority?
    
    init() {
        loadTasks()
    }
    
    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: "savedTasks")
        }
    }
    
    private func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: "savedTasks"),
           let decoded = try? JSONDecoder().decode([Task].self, from: data) {
            tasks = decoded
        }
    }
    
    func addTask(_ task: Task) {
        tasks.append(task)
    }
    
    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
    }
    
    func updateTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        }
    }
    
    func moveTask(from source: IndexSet, to destination: Int) {
        tasks.move(fromOffsets: source, toOffset: destination)
    }
    
    func toggleTaskCompletion(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            var updatedTask = task
            updatedTask.isCompleted.toggle()
            tasks[index] = updatedTask
        }
    }
    
    var filteredTasks: [Task] {
        tasks.filter { task in
            let matchesSearch = searchText.isEmpty || 
                task.title.localizedCaseInsensitiveContains(searchText) ||
                task.description.localizedCaseInsensitiveContains(searchText)
            
            let matchesCategory = selectedCategory == nil || task.category == selectedCategory
            let matchesPriority = selectedPriority == nil || task.priority == selectedPriority
            
            return matchesSearch && matchesCategory && matchesPriority
        }
    }
    
    func tasksByPriority(_ priority: TaskPriority) -> [Task] {
        filteredTasks.filter { $0.priority == priority }
    }
    
    func tasksByCategory(_ category: TaskCategory) -> [Task] {
        filteredTasks.filter { $0.category == category }
    }
} 
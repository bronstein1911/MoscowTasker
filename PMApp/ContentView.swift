import SwiftUI

struct ContentView: View {
    @StateObject private var taskViewModel = TaskViewModel()
    @State private var selectedTab = 0
    @State private var showingAddTask = false
    @State private var showingAbout = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TaskListView(viewModel: taskViewModel, showingAddTask: $showingAddTask)
                .tabItem {
                    Label("Задачи", systemImage: "checklist")
                }
                .tag(0)
            
            TaskBoardView(viewModel: taskViewModel, showingAddTask: $showingAddTask)
                .tabItem {
                    Label("Доска", systemImage: "square.grid.2x2")
                }
                .tag(1)
            
            TaskCategoriesView(viewModel: taskViewModel, showingAddTask: $showingAddTask)
                .tabItem {
                    Label("Категории", systemImage: "folder")
                }
                .tag(2)
            
            AboutView()
                .tabItem {
                    Label("О приложении", systemImage: "info.circle")
                }
                .tag(3)
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(viewModel: taskViewModel)
        }
    }
}

struct TaskListView: View {
    @ObservedObject var viewModel: TaskViewModel
    @State private var showingFilters = false
    @Binding var showingAddTask: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $viewModel.searchText)
                
                List {
                    ForEach(TaskPriority.allCases, id: \.self) { priority in
                        Section(header: Text(priority.rawValue)) {
                            ForEach(viewModel.tasksByPriority(priority)) { task in
                                TaskRow(task: task, viewModel: viewModel)
                            }
                            .onMove { source, destination in
                                viewModel.moveTask(from: source, to: destination)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Задачи")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { showingFilters.toggle() }) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                        }
                        
                        Button(action: { showingAddTask = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                FilterView(viewModel: viewModel)
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Поиск задач...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct FilterView: View {
    @ObservedObject var viewModel: TaskViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Категория")) {
                    Picker("Категория", selection: $viewModel.selectedCategory) {
                        Text("Все").tag(Optional<TaskCategory>.none)
                        ForEach(TaskCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(Optional(category))
                        }
                    }
                }
                
                Section(header: Text("Приоритет")) {
                    Picker("Приоритет", selection: $viewModel.selectedPriority) {
                        Text("Все").tag(Optional<TaskPriority>.none)
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Text(priority.rawValue).tag(Optional(priority))
                        }
                    }
                }
            }
            .navigationTitle("Фильтры")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TaskRow: View {
    let task: Task
    @ObservedObject var viewModel: TaskViewModel
    @State private var showingEditSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button(action: { viewModel.toggleTaskCompletion(task) }) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(task.isCompleted ? .green : .gray)
                }
                
                Text(task.title)
                    .strikethrough(task.isCompleted)
                    .font(.headline)
                
                Spacer()
                
                HStack {
                    Circle()
                        .fill(Color(task.priority.color))
                        .frame(width: 12, height: 12)
                    
                    HStack(spacing: 4) {
                        Image(systemName: task.category.icon)
                            .foregroundColor(.black)
                        Text(task.category.rawValue)
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(task.category.color))
                    .foregroundColor(.black)
                    .cornerRadius(4)
                    
                    Button(action: { showingEditSheet = true }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Text(task.description)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let dueDate = task.dueDate {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.gray)
                    Text("Due: \(dueDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $showingEditSheet) {
            EditTaskView(viewModel: viewModel, task: task)
        }
    }
}

struct EditTaskView: View {
    @ObservedObject var viewModel: TaskViewModel
    let task: Task
    @Environment(\.dismiss) var dismiss
    
    @State private var title: String
    @State private var description: String
    @State private var priority: TaskPriority
    @State private var category: TaskCategory
    @State private var dueDate: Date
    @State private var hasDueDate: Bool
    
    init(viewModel: TaskViewModel, task: Task) {
        self.viewModel = viewModel
        self.task = task
        _title = State(initialValue: task.title)
        _description = State(initialValue: task.description)
        _priority = State(initialValue: task.priority)
        _category = State(initialValue: task.category)
        _dueDate = State(initialValue: task.dueDate ?? Date())
        _hasDueDate = State(initialValue: task.dueDate != nil)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Title", text: $title)
                        .textInputAutocapitalization(.words)
                    TextEditor(text: $description)
                        .frame(height: 100)
                }
                
                Section(header: Text("Priority")) {
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            HStack {
                                Circle()
                                    .fill(Color(priority.color))
                                    .frame(width: 12, height: 12)
                                Text(priority.rawValue)
                            }
                            .tag(priority)
                        }
                    }
                }
                
                Section(header: Text("Category")) {
                    Picker("Category", selection: $category) {
                        ForEach(TaskCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(.black)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                }
                
                Section(header: Text("Due Date")) {
                    Toggle("Set Due Date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Edit Task")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var updatedTask = task
                        updatedTask.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        updatedTask.description = description.trimmingCharacters(in: .whitespacesAndNewlines)
                        updatedTask.priority = priority
                        updatedTask.category = category
                        updatedTask.dueDate = hasDueDate ? dueDate : nil
                        viewModel.updateTask(updatedTask)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TaskBoardView: View {
    @ObservedObject var viewModel: TaskViewModel
    @Binding var showingAddTask: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    StatisticsView(viewModel: viewModel)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 16) {
                            ForEach(TaskPriority.allCases, id: \.self) { priority in
                                VStack(alignment: .leading) {
                                    HStack {
                                        Circle()
                                            .fill(Color(priority.color))
                                            .frame(width: 12, height: 12)
                                        Text(priority.rawValue)
                                            .font(.headline)
                                    }
                                    .padding(.horizontal)
                                    
                                    VStack {
                                        ForEach(viewModel.tasksByPriority(priority)) { task in
                                            TaskCard(task: task, viewModel: viewModel)
                                        }
                                    }
                                    .frame(width: 300)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Task Board")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTask = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

struct StatisticsView: View {
    @ObservedObject var viewModel: TaskViewModel
    
    var totalTasks: Int { viewModel.tasks.count }
    var completedTasks: Int { viewModel.tasks.filter { $0.isCompleted }.count }
    var completionRate: Double {
        guard totalTasks > 0 else { return 0 }
        return Double(completedTasks) / Double(totalTasks)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                StatCard(title: "Total Tasks", value: "\(totalTasks)", icon: "checklist")
                StatCard(title: "Completed", value: "\(completedTasks)", icon: "checkmark.circle.fill")
                StatCard(title: "Completion", value: "\(Int(completionRate * 100))%", icon: "chart.pie.fill")
            }
            
            ProgressView(value: completionRate)
                .tint(.green)
                .padding(.horizontal)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            Text(value)
                .font(.title)
                .bold()
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct TaskCard: View {
    let task: Task
    @ObservedObject var viewModel: TaskViewModel
    @State private var showingEditSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(task.title)
                    .font(.headline)
                Spacer()
                Button(action: { showingEditSheet = true }) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                }
            }
            
            Text(task.description)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(4)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: task.category.icon)
                        .foregroundColor(.black)
                    Text(task.category.rawValue)
                        .font(.caption)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(task.category.color))
                .foregroundColor(.black)
                .cornerRadius(4)
                
                if let dueDate = task.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .foregroundColor(.gray)
                        Text(dueDate, style: .date)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                Button(action: { viewModel.toggleTaskCompletion(task) }) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(task.isCompleted ? .green : .gray)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 2)
        .sheet(isPresented: $showingEditSheet) {
            EditTaskView(viewModel: viewModel, task: task)
        }
    }
}

struct TaskCategoriesView: View {
    @ObservedObject var viewModel: TaskViewModel
    @Binding var showingAddTask: Bool
    
    var body: some View {
        NavigationView {
            List {
                ForEach(TaskCategory.allCases, id: \.self) { category in
                    Section(header: Text(category.rawValue)) {
                        ForEach(viewModel.tasksByCategory(category)) { task in
                            TaskRow(task: task, viewModel: viewModel)
                        }
                    }
                }
            }
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTask = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

struct AddTaskView: View {
    @ObservedObject var viewModel: TaskViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var priority = TaskPriority.must
    @State private var category = TaskCategory.feature
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Title", text: $title)
                        .textInputAutocapitalization(.words)
                    TextEditor(text: $description)
                        .frame(height: 100)
                }
                
                Section(header: Text("Priority")) {
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            HStack {
                                Circle()
                                    .fill(Color(priority.color))
                                    .frame(width: 12, height: 12)
                                Text(priority.rawValue)
                            }
                            .tag(priority)
                        }
                    }
                }
                
                Section(header: Text("Category")) {
                    Picker("Category", selection: $category) {
                        ForEach(TaskCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(.black)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                }
                
                Section(header: Text("Due Date")) {
                    Toggle("Set Due Date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("New Task")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let task = Task(
                            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                            priority: priority,
                            category: category,
                            dueDate: hasDueDate ? dueDate : nil
                        )
                        viewModel.addTask(task)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AboutView: View {
    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(alignment: .center, spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Task Manager")
                            .font(.title)
                            .bold()
                        
                        Text("Версия 1.0")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
                
                Section(header: Text("О приложении")) {
                    Text("Task Manager - это простое и удобное приложение для управления задачами. Создавайте, редактируйте и отслеживайте свои задачи с помощью различных представлений и фильтров.")
                        .padding(.vertical, 8)
                }
                
                Section(header: Text("Функции")) {
                    FeatureRow(icon: "checklist", title: "Управление задачами", description: "Создавайте и редактируйте задачи с различными приоритетами и категориями")
                    FeatureRow(icon: "square.grid.2x2", title: "Доска задач", description: "Визуальное представление задач в стиле Kanban")
                    FeatureRow(icon: "folder", title: "Категории", description: "Организуйте задачи по категориям")
                    FeatureRow(icon: "chart.pie.fill", title: "Статистика", description: "Отслеживайте прогресс выполнения задач")
                }
                
                Section(header: Text("Контакты")) {
                    Link(destination: URL(string: "mailto:support@taskmanager.app")!) {
                        HStack {
                            Image(systemName: "envelope")
                            Text("Поддержка")
                        }
                    }
                }
            }
            .navigationTitle("О приложении")
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
} 

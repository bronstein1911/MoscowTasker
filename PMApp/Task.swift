import Foundation

enum TaskPriority: String, CaseIterable, Codable {
    case must = "Обязательно"
    case should = "Желательно"
    case could = "Возможно"
    case wont = "Не будет"
    
    var color: String {
        switch self {
        case .must: return "red"
        case .should: return "orange"
        case .could: return "blue"
        case .wont: return "gray"
        }
    }
}

enum TaskCategory: String, CaseIterable, Codable {
    case epic = "Эпик"
    case feature = "Функция"
    case bug = "Ошибка"
    case improvement = "Улучшение"
    
    var color: String {
        switch self {
        case .epic: return "pastelPurple"      // Пастельный фиолетовый
        case .feature: return "pastelBlue"      // Пастельный синий
        case .bug: return "pastelRed"          // Пастельный красный
        case .improvement: return "pastelGreen" // Пастельный зеленый
        }
    }
    
    var icon: String {
        switch self {
        case .epic: return "star.fill"
        case .feature: return "sparkles"
        case .bug: return "ladybug.fill"
        case .improvement: return "arrow.up.circle.fill"
        }
    }
}

struct Task: Identifiable, Codable {
    var id = UUID()
    var title: String
    var description: String
    var priority: TaskPriority
    var category: TaskCategory
    var isCompleted: Bool
    var createdAt: Date
    var dueDate: Date?
    
    init(title: String, description: String, priority: TaskPriority, category: TaskCategory, isCompleted: Bool = false, dueDate: Date? = nil) {
        self.title = title
        self.description = description
        self.priority = priority
        self.category = category
        self.isCompleted = isCompleted
        self.createdAt = Date()
        self.dueDate = dueDate
    }
}

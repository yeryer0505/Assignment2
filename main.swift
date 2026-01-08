import Foundation

protocol IdentifiableEntity {
    var id: UUID { get }
}

struct Student: IdentifiableEntity, Codable {
    let id: UUID
    var name: String
    var age: Int
    var courseId: UUID?
}

class Course: IdentifiableEntity, Codable {
    let id: UUID
    var title: String

    init(title: String) {
        self.id = UUID()
        self.title = title
    }
}

class StudentManager {
    private(set) var students: [Student] = []
    private(set) var courses: [Course] = []

    func loadStudents(_ loaded: [Student]) {
        students = loaded
    }

    func addStudent(name: String, age: Int) {
        guard age >= 16 else {
            print("Age must be 16 or older")
            return
        }
        let student = Student(id: UUID(), name: name, age: age, courseId: nil)
        students.append(student)
    }

    func editStudent(id: UUID, update: (inout Student) -> Void) {
        guard let index = students.firstIndex(where: { $0.id == id }) else {
            print("Student not found")
            return
        }
        update(&students[index])
    }

    func deleteStudent(id: UUID) {
        students.removeAll { $0.id == id }
    }

    func filterStudents(_ predicate: (Student) -> Bool) -> [Student] {
        students.filter(predicate)
    }

    func sortedStudents(by sorter: (Student, Student) -> Bool) -> [Student] {
        students.sorted(by: sorter)
    }

    func averageAge() -> Double {
        guard !students.isEmpty else { return 0 }
        let total = students.map { $0.age }.reduce(0, +)
        return Double(total) / Double(students.count)
    }

    func addCourse(title: String) {
        courses.append(Course(title: title))
    }
}

class PersistenceManager {
    static let fileURL = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("students.json")

    static func save(students: [Student]) {
        if let data = try? JSONEncoder().encode(students) {
            try? data.write(to: fileURL)
        }
    }

    static func load() -> [Student] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([Student].self, from: data)) ?? []
    }
}

func showMenu() {
    print("""
    1. Add Student
    2. List Students
    3. Edit Student
    4. Delete Student
    5. Average Age
    6. Save & Exit
    """)
}

let manager = StudentManager()
manager.loadStudents(PersistenceManager.load())

while true {
    showMenu()
    guard let input = readLine(), let choice = Int(input) else { continue }

    switch choice {
    case 1:
        print("Name:")
        let name = readLine() ?? ""
        print("Age:")
        let age = Int(readLine() ?? "") ?? 0
        manager.addStudent(name: name, age: age)

    case 2:
        let sorted = manager.sortedStudents { $0.name < $1.name }
        sorted.forEach {
            print("\($0.name), age \($0.age), id: \($0.id)")
        }

    case 3:
        print("Enter student ID:")
        if let id = UUID(uuidString: readLine() ?? "") {
            manager.editStudent(id: id) { student in
                print("New name:")
                student.name = readLine() ?? student.name
            }
        }

    case 4:
        print("Enter student ID:")
        if let id = UUID(uuidString: readLine() ?? "") {
            manager.deleteStudent(id: id)
        }

    case 5:
        print(manager.averageAge())

    case 6:
        PersistenceManager.save(students: manager.students)
        exit(0)

    default:
        break
    }
}

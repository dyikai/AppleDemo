import Observation

@Observable
class Book: CustomStringConvertible,@unchecked Sendable {
    var description: String {
        return "name = \(self.name), id = \(self.id)"
    }

    var name: String
    var id: Int

    init(name: String, id: Int) {
        self.name = name
        self.id = id
    }
}

@MainActor
func observationExample() {
    // 创建一个可观察的对象
    var book = Book(name: "Harry Potter", id: 0)
    
    // 启动一个任务监听变化
    withObservationTracking {
        let _ = book.name
    } onChange: {
        // 每当 book 的属性发生变化时，这里会被调用
        print("Book updated: name = \(book.name), id = \(book.id)")
        
    }

    // 模拟一些属性更新
    book.name = "The Lord of the Rings"
    book.id = 1

    book.name = "The Old Man and The Sea"
    book.id = 2

    // 输出最终的结果
    print("Final book state: \(book)")
}

// 调用示例函数
observationExample()

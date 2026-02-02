import SwiftUI

@main
struct todo_appApp: App {
    private let container = AppContainer()

    var body: some Scene {
        WindowGroup {
            ContentView(container: container)
        }
    }
}

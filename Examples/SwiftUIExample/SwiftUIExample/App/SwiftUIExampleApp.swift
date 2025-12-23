import SwiftUI
import AsyncSwiftyNetworking

@main
struct SwiftUIExampleApp: App {
    
    init() {
        AppDI.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

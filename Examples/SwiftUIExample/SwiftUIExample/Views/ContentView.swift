import SwiftUI
import AsyncSwiftyNetworking

struct ContentView: View {
    @ObservedObject var authState = AuthState.shared
    
    var body: some View {
        NavigationStack {
            if authState.isLoggedIn {
                HomeView()
            } else {
                LoginView()
            }
        }
    }
}

#Preview {
    ContentView()
}

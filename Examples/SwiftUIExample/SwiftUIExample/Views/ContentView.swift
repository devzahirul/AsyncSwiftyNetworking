import SwiftUI
import AsyncSwiftyNetworking

struct ContentView: View {
    
    var body: some View {
        // TMDB uses Bearer token, so we go straight to HomeView
        HomeView()
    }
}

#Preview {
    ContentView()
}

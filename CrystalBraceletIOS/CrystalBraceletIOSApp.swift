import SwiftUI

@main
struct CrystalBraceletIOSAppApp: App {
    @StateObject private var braceletVM = BraceletViewModel()
    @StateObject private var analysisVM = AnalysisViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(braceletVM)
                .environmentObject(analysisVM)
        }
    }
}

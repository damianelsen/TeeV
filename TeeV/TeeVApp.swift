//
//  TeaVeeApp.swift
//  TeaVee
//
//  Created by Damian Elsen on 11/12/25.
//

import SwiftUI
import SwiftData

@main
struct TeeVApp: App {
    @State private var isPresented: Bool = false
    @State private var message: String = ""
    
    static let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Show.self,
            Season.self,
            Episode.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ShowsView()
                .task {
                    do {
                        let config = try await getConfiguration()
                        UserDefaults.standard.register(defaults: [
                            TeeVConstants.appStorageUrlBase: config.images.secure_base_url,
                            TeeVConstants.appStorageBackdropSize: config.images.backdrop_sizes[1],
                            TeeVConstants.appStoragePosterSize: config.images.poster_sizes[2]
                        ])
                    } catch {
                        print("Failed to fetch configuration: \(error)")
                    }
                }
                .task {
                    do {
                        let controller = DataController(modelContext: TeeVApp.sharedModelContainer.mainContext)
                        self.message = try await controller.refreshShows()
                        self.isPresented = !self.message.isEmpty
                    } catch {
                        self.message = "Failed to refresh shows: \(error)"
                        self.isPresented = true
                    }
                }
                .alert("TV Shows Updated", isPresented: $isPresented, actions: {
                    Button("OK") {
                        self.message = ""
                    }
                }, message: {
                    Text(self.message)
                })
        }
        .modelContainer(TeeVApp.sharedModelContainer)
    }
}

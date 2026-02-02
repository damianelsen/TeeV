//
//  ContentView.swift
//  TeaVee
//
//  Created by Damian Elsen on 11/12/25.
//

import SwiftUI
import SwiftData

struct ShowsView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @StateObject private var newShow = NewShow()
    @State private var showingSearchView: Bool = false
    @Query(sort: [
        SortDescriptor(\Show.started, order: .reverse),
        SortDescriptor(\Show.daysToNextEpisode),
        SortDescriptor(\Show.lastWatched, order: .reverse),
        SortDescriptor(\Show.status, order: .reverse)
    ]) private var shows: [Show]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(shows) { show in
                    NavigationLink {
                        ShowView(show: show)
                            .toolbar(.hidden, for: .bottomBar)
                    } label: {
                        ShowListItemView(show: show)
                    }
                }
                .onDelete{ indexes in
                    deleteShow(at: indexes.first!)
                }
                .listRowInsets(.init())
                .listRowSeparator(.hidden)
            }
            .listStyle(.inset)
            .navigationLinkIndicatorVisibility(.hidden)
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button(action: {
                        showingSearchView.toggle()
                    }) {
                        Label("Add Show", systemImage: "plus")
                    }
                    .sheet(isPresented: $showingSearchView) {
                        SearchView(newShow: newShow)
                    }
                }
            }
        }
        .onChange(of: newShow.id) {
            addShow(with: newShow.id)
        }
        .onAppear {
            requestNotificationAuthorization()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                Task {
                    await updateBadgeCount()
                    await updateNotificationBadgeCounts()
                }
            }
        }
    }
    
    private func addShow(with id: Int) {
        Task {
            let showController = DataController(modelContext: modelContext)

            try await showController.addNewShow(with: id)
        }
    }
    
    private func requestNotificationAuthorization() {
        let notificationController = NotificationController(modelContext: modelContext)
        
        notificationController.requestNotificationAuthorization()
    }

    private func deleteShow(at index: Int) {
        let showController = DataController(modelContext: modelContext)
        let show = shows[index]

        showController.removeShow(with: show.id)
    }
    
    private func updateBadgeCount() async {
        let showController = DataController(modelContext: modelContext)
        let notificationController = NotificationController(modelContext: modelContext)
        
        let count = showController.getTotalUnwatchedEpisodes()
        await notificationController.setAppBadgeCount(to: count)
    }
    
    private func updateNotificationBadgeCounts() async {
        let notificationController = NotificationController(modelContext: modelContext)
        
        await notificationController.updateNotificationBadgeCounts()
    }
}

#Preview {
    ShowsView()
        .modelContainer(for: Show.self, inMemory: true)
}

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
    @State private var badgeManager = AppAlertBadgeManager(application: UIApplication.shared)
    @State private var showingSearchView: Bool = false
    @Query(sort: [
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
                    Task {
                        await deleteShowAt(index: indexes.first!)
                    }
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
            addShow(id: newShow.id)
        }
        .onAppear {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (_, _) in }
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
    
    private func addShow(id: Int) {
        Task {
            let showController = DataController(modelContext: modelContext)

            try await showController.addNewShowWith(id: id)
        }
    }

    private func deleteShowAt(index: Int) async {
        let showController = DataController(modelContext: modelContext)
        let show = shows[index]

        await showController.removeShowWith(id: show.id)
    }
    
    private func updateBadgeCount() async {
        let showController = DataController(modelContext: modelContext)
        let count = showController.getTotalUnwatchedEpisodes()
        
        await badgeManager.setAlertBadge(number: count)
    }
    
    private func updateNotificationBadgeCounts() async {
        let notificationController = await NotificationController(modelContext: modelContext)
        
        await notificationController.updateNotificationBadgeCounts()
    }
}

#Preview {
    ShowsView()
        .modelContainer(for: Show.self, inMemory: true)
}

//
//  SearchView.swift
//  TeeV
//
//  Created by Damian Elsen on 11/13/25.
//

import SwiftUI

struct SearchView: View {
    @Environment(\.dismiss) var dismiss
    
    @AppStorage(TeeVConstants.appStorageUrlBase) var urlBase = ""
    @AppStorage(TeeVConstants.appStoragePosterSize) var posterSize = ""

    @ObservedObject var newShow: NewShow

    @State private var shows = [SearchShowResponse]()
    @State private var showName = ""
    
    var body: some View {
        NavigationStack {
            Spacer(minLength: 25)
            List(shows) { show in
                Button {
                    newShow.id = show.id
                    dismiss()
                } label: {
                    HStack(alignment: .top) {
                        AsyncImage(url: URL(string: urlBase + posterSize + (show.poster_path ?? ""))) { phase in
                            switch phase {
                            case .failure:
                                Image(systemName: "photo.tv")
                                    .font(.largeTitle)
                            case .success(let image):
                                image
                                    .resizable()
                            default:
                                ProgressView()
                            }
                        }
                        .frame(width: 64, height: 96)
                        VStack(alignment: .leading) {
                            Text(show.name)
                                .font(.title3)
                                .lineLimit(...1)
                            Text(show.overview)
                                .lineLimit(...3)
                        }
                    }
                }
                .listRowInsets(.init())
                .listRowSeparator(.hidden)
            }
            .listStyle(.inset)
        }
        .searchable(text: $showName, prompt: "Look for something to watch ...")
        .onSubmit(of: .search, showSearch)
    }

    private func showSearch() {
        Task {
            shows = try await getShows(showName: showName)
        }
    }
}

#Preview {
    SearchView(newShow: NewShow())
}

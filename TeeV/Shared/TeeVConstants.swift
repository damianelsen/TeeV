//
//  TeeVConstants.swift
//  TeeV
//
//  Created by Damian Elsen on 11/13/25.
//

import Foundation

class TeeVConstants {
    
    // MARK: - Dates
    
    static let apiDateFormat = "yyyy-MM-dd"

    // MARK: - API Token
    
    // TODO: remove this before adding to source code control
    static private let apiBearerToken = "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJkMmNlMGUwN2M0OTlkNmY0MTYwOTc3NjEyZGI2NjVhOSIsIm5iZiI6MTc2Mjk3NjQxMS4yNzYsInN1YiI6IjY5MTRlMjliMjg1OWRkOTc1NTRjOTIzYyIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.pa5iIPqRpa1lXknzUuk-5pBYJQGurB4IC8cA-6xWJNI"

    // MARK: - API Headers
    
    static let apiHeaderAuthorization = "Authorization"
    static let apiHeaderToken = "Bearer " + apiBearerToken
    static let apiHeaderAccept = "accept"
    static let apiHeaderJson = "application/json'"

    // MARK: - API URLs
    
    static let tmdbConfigurationUrl = "https://api.themoviedb.org/3/configuration"
    static let tmdbSearchUrl = "https://api.themoviedb.org/3/search/tv?include_adult=false&language=en-US&page=1&query="
    static let tmdbShowUrl = "https://api.themoviedb.org/3/tv/"

    // MARK: - App Storage
    
    static let appStorageUrlBase = "secure_base_url"
    static let appStorageBackdropSize = "backdrop_size"
    static let appStoragePosterSize = "poster_size"

}

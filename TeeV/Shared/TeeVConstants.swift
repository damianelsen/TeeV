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
    
    static private let apiBearerToken = ""

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

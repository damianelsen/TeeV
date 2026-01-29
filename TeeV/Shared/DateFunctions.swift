//
//  DateFunctions.swift
//  TeeV
//
//  Created by Damian Elsen on 11/24/25.
//

import Foundation

func convertDate(from dateString: String) -> Date {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = TeeVConstants.apiDateFormat
    dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
    
    return dateFormatter.date(from: dateString)!
}

func getNowAtUtcMidnight() -> Date {
    let calendar = Calendar.current
    let year = calendar.component(.year, from: Date.now)
    let month = calendar.component(.month, from: Date.now)
    let day = calendar.component(.day, from: Date.now)
    let now = "\(year)-\(month)-\(day)"
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = TeeVConstants.apiDateFormat
    dateFormatter.timeZone = TimeZone(abbreviation: "UTC")

    return dateFormatter.date(from: now)!
}

func getDaysBetween(from: Date, to: Date) -> Int {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale.autoupdatingCurrent
    
    let components = calendar.dateComponents([.day], from: from, to: to)
    
    return (components.day ?? 0)
}

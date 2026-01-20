//
//  DateFunctions.swift
//  TeeV
//
//  Created by Damian Elsen on 11/24/25.
//

import Foundation

func convertDateFrom(dateString: String) -> Date {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = TeeVConstants.apiDateFormat
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    let convertedDate = dateFormatter.date(from: dateString)!
    
    return convertedDate
}

func getNowAtUtcMidnight() -> Date {
    let calendar = Calendar.current
    let now = "\(calendar.component(.year, from: Date.now))-\(calendar.component(.month, from: Date.now))-\(calendar.component(.day, from: Date.now))"
    
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

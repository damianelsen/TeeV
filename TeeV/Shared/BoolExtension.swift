//
//  BoolExtension.swift
//  TeeV
//
//  Created by Damian Elsen on 1/29/26.
//

import Foundation

extension Bool: @retroactive Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        // the only true inequality is false < true
        !lhs && rhs
    }
}

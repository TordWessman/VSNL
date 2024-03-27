//
//  String+Validation.swift
//  VSNLExample
//
//  Created by Tord Wessman on 2024-03-27.
//

import Foundation

extension String {

    static var someArbitrarilySelectedCharactersConsideredToBeIneligible = "\\”|\\\"|\\<|\\>|[0-9]+"
    /// It's a mess to match unicode-characters (e g filter out emojis), so this will have to do for now. Also: I'm supporting iOS 15.x, so the new Regex features is not available.
    var isValidSearchText: Bool {

        guard count > 1 else { return false }
        let range = NSRange(location: 0, length: utf16.count)
        if let regex = try? NSRegularExpression(pattern: Self.someArbitrarilySelectedCharactersConsideredToBeIneligible, options: []) {
            return regex.matches(in: self, options: [], range: range).count == 0
        }

        fatalError("You messed up the regex!")
    }
}

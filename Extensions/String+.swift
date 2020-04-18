//
//  String+.swift
//  MGTextPlus
//
//  Created by Tuan Truong on 11/5/16.
//  Copyright © 2016 Tuan Truong. All rights reserved.
//

import Cocoa

extension String {
    func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    func trimEnd() -> String {
        return self.replacingOccurrences(of: "[ \t\n]+$",
                                         with: "",
                                         options: CompareOptions.regularExpression)
    }
    
    func trimStart() -> String {
        return self.replacingOccurrences(of: "^[ \t]+",
                                         with: "",
                                         options: CompareOptions.regularExpression)
    }
    
    func removeComment() -> String {
        return self.replacingOccurrences(of: "//[^\"\n]+$",
                                         with: "",
                                         options: CompareOptions.regularExpression)
    }
    
    static func spaces(count: Int) -> String {
        return [String](repeating: " ", count: count).joined()
    }
    
    func leadingSpaces() -> String {
        var numberOfSpaces = 0
        
        for c in self {
            if c == " " {
                numberOfSpaces += 1
            } else {
                break
            }
        }
        
        return String.spaces(count: numberOfSpaces)
    }
    
    func capturedGroups(withRegex pattern: String) -> [String] {
        var results = [String]()
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return results
        }
        
        let matches = regex.matches(in: self, options: [], range: NSRange(location:0, length: self.count))
        guard let match = matches.first else { return results }
        
        let lastRangeIndex = match.numberOfRanges - 1
        guard lastRangeIndex >= 1 else { return results }
        
        for i in 1...lastRangeIndex {
            let capturedGroupIndex = match.range(at: i)
            let matchedString = (self as NSString).substring(with: capturedGroupIndex)
            results.append(matchedString)
        }
        
        return results
    }
}

extension StringProtocol {
    func distance(of element: Element) -> Int? { firstIndex(of: element)?.distance(in: self) }
    func distance<S: StringProtocol>(of string: S) -> Int? { range(of: string)?.lowerBound.distance(in: self) }
}

extension Collection {
    func distance(to index: Index) -> Int { distance(from: startIndex, to: index) }
}

extension String.Index {
    func distance<S: StringProtocol>(in string: S) -> Int { string.distance(to: self) }
}

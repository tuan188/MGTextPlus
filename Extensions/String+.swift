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

extension String {
    func indices(of occurrence: String) -> [Int] {
        var indices = [Int]()
        var position = startIndex
        while let range = range(of: occurrence, range: position..<endIndex) {
            let i = distance(from: startIndex,
                             to: range.lowerBound)
            indices.append(i)
            let offset = occurrence.distance(from: occurrence.startIndex,
                                             to: occurrence.endIndex) - 1
            guard let after = index(range.lowerBound,
                                    offsetBy: offset,
                                    limitedBy: endIndex) else {
                break
            }
            position = index(after: after)
        }
        
        return indices
    }
    
    func split(separator: Character, ignoredRanges: [NSRange]) -> [String] {
        guard !ignoredRanges.isEmpty else {
            return self.split(separator: separator).map { String($0) }
        }
        
        let indices = self.indices(of: String(separator))
            .filter { index in
                ignoredRanges.allSatisfy { range in !range.contains(index) }
            }
        
        var lines: [String] = []
        var start = self.startIndex
        let endIndex = self.endIndex
        
        for separatorIndex in indices {
            if separatorIndex > 0,
               let end = index(startIndex, offsetBy: separatorIndex - 1, limitedBy: endIndex),
               start <= end {
                lines.append(String(self[start...end]))
            } else {
                lines.append("")
            }
            
            guard let next = index(startIndex, offsetBy: separatorIndex + 1, limitedBy: endIndex) else {
                break
            }
            
            start = next
        }
        
        lines.append(String(self[start..<endIndex]))
        
        return lines
    }
    
    func split(separator: Character, ignoredPattern pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return self.split(separator: separator).map { String($0) }
        }
        
        let ignoredRanges = regex
            .matches(in: self, range: NSRange(location: 0, length: self.count))
            .map { $0.range }
        
        return split(separator: separator, ignoredRanges: ignoredRanges)
    }
}

//
//  SourceEditorCommand.swift
//  Line
//
//  Created by Tuan Truong on 11/5/16.
//  Copyright © 2016 Tuan Truong. All rights reserved.
//

import Foundation
import XcodeKit
import AppKit

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        guard let textRange = invocation.buffer.selections.firstObject as? XCSourceTextRange,
            invocation.buffer.lines.count > 0 else {
            completionHandler(nil)
            return
        }
        
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            completionHandler(nil)
            return
        }
        
        
        let targetRange = Range(uncheckedBounds: (lower: textRange.start.line, upper: min(textRange.end.line + 1, invocation.buffer.lines.count)))
        let indexSet = IndexSet(integersIn: targetRange)
        let selectedLines = invocation.buffer.lines.objects(at: indexSet)
        
        func deleteLines(indexSet: IndexSet) {
            invocation.buffer.lines.removeObjects(at: indexSet)
            let lineSelection = XCSourceTextRange()
            lineSelection.start = XCSourceTextPosition(line: targetRange.lowerBound, column: 0)
            lineSelection.end = XCSourceTextPosition(line: targetRange.lowerBound, column: 0)
            invocation.buffer.selections.setArray([lineSelection])
        }
        
        func copyLines(_ lines: [String]) {
            var copyLines = [String]()
            for line in selectedLines as! [String] {
                copyLines.append(line)
            }
            let newString = copyLines.joined()
            let pasteboard = NSPasteboard.general()
            pasteboard.declareTypes([NSPasteboardTypeString], owner: nil)
            pasteboard.setString(newString, forType: NSPasteboardTypeString)
        }
        
        func firstClassName() -> String? {
            let pattern = "class ([^:<{ ]+)"
            for line in invocation.buffer.lines as! [String] {
                let groups = line.capturedGroups(withRegex: pattern)
                if let className = groups.first, !className.isEmpty {
                    return className
                }
            }
            return nil
        }
        
        // Switch all different commands id based which defined in Info.plist
        switch invocation.commandIdentifier {
        case bundleIdentifier + ".DeleteLine":
            deleteLines(indexSet: indexSet)
        case bundleIdentifier + ".DuplicateLine":
            let lineSelection = XCSourceTextRange()
            lineSelection.start = XCSourceTextPosition(line: textRange.start.line + targetRange.count, column: textRange.start.column)
            lineSelection.end = XCSourceTextPosition(line: textRange.end.line + targetRange.count, column: textRange.end.column)
            invocation.buffer.lines.insert(selectedLines, at: indexSet)
            invocation.buffer.selections.setArray([lineSelection])
        case bundleIdentifier + ".CopyLine":
            copyLines(selectedLines as! [String])
        case bundleIdentifier + ".CutLine":
            copyLines(selectedLines as! [String])
            deleteLines(indexSet: indexSet)
        case bundleIdentifier + ".JoinLines":
            let newLine: String
            if indexSet.count == 1 {
                let currentRow = indexSet.last!
                guard currentRow < invocation.buffer.lines.count - 1 else {
                    break
                }
                let firstLine = invocation.buffer.lines[currentRow] as! String
                let secondLine = invocation.buffer.lines[currentRow + 1] as! String
                newLine = firstLine.trimEnd() + " " + secondLine.trimStart()
                invocation.buffer.lines[currentRow] = newLine
                invocation.buffer.lines.removeObject(at: currentRow + 1)
                
                if textRange.start.column == textRange.end.column {
                    let lineSelection = XCSourceTextRange()
                    lineSelection.start = XCSourceTextPosition(line: textRange.start.line, column: firstLine.characters.count)
                    lineSelection.end = lineSelection.start
                    invocation.buffer.selections.setArray([lineSelection])
                }
            }
            else if indexSet.count > 1 {
                var lines = [String]()
                for (index, line) in selectedLines.enumerated() {
                    let line = line as! String
                    if index == 0 {
                        lines.append(line.trimEnd())
                    }
                    else if index == selectedLines.count - 1 {
                        lines.append(line.trimStart())
                    }
                    else {
                        lines.append(line.trim())
                    }
                }
                newLine = lines.joined(separator: " ")
                invocation.buffer.lines[indexSet.first!] = newLine
                
                let indexSetToRemove = IndexSet(integersIn: Range(uncheckedBounds: (lower: textRange.start.line + 1, upper: min(textRange.end.line + 1, invocation.buffer.lines.count))))
                deleteLines(indexSet: indexSetToRemove)
                
                let lineSelection = XCSourceTextRange()
                lineSelection.start = XCSourceTextPosition(line: textRange.start.line, column: textRange.start.column)
                lineSelection.end = XCSourceTextPosition(line: textRange.start.line, column: newLine.characters.count - 1)
                invocation.buffer.selections.setArray([lineSelection])
            }
        case bundleIdentifier + ".SplitLineByComma":
            var textArray = [String]()
            for line in selectedLines as! [String] {
                textArray.append(contentsOf: line.components(separatedBy: ","))
            }
            let firstLine = selectedLines[0] as! String
            var firstLineText: String?
            if let range: Range<String.Index> = firstLine.range(of: ",") {
                firstLineText = firstLine.substring(to: range.lowerBound) + ","
            } else if let range: Range<String.Index> = firstLine.range(of: "\n") {
                firstLineText = firstLine.substring(to: range.lowerBound)
            }
            
            var leadingSpaces = ""
            if let firstLineText = firstLineText {
                textArray[0] = firstLineText.trimEnd()
                leadingSpaces = firstLineText.leadingSpaces()
            }
            
            var remainLines = [String]()
            
            for i in 1..<textArray.count {
                let text = textArray[i].trim()
                if !text.isEmpty {
                    remainLines.append(leadingSpaces + textArray[i].trim())
                }
            }
            
            let result = [textArray[0], remainLines.joined(separator: ",\n")].joined(separator: "\n")
            deleteLines(indexSet: indexSet)
            
            let insertTargetRange = Range(uncheckedBounds: (lower: textRange.start.line, upper: textRange.start.line + 1))
            let insertIndexSet = IndexSet(integersIn: insertTargetRange)
            invocation.buffer.lines.insert([result], at: insertIndexSet)
            
        case bundleIdentifier + ".RemoveEmptyLines":
            var emptyLineIndexArray = [Int]()
            for lineIndex in textRange.start.line...textRange.end.line {
                guard lineIndex < invocation.buffer.lines.count - 1 else {
                    break
                }
                let line = invocation.buffer.lines[lineIndex] as! String
                if line.trim().isEmpty {
                    emptyLineIndexArray.append(lineIndex)
                }
            }
            let indexSetToRemove = IndexSet(emptyLineIndexArray)
            deleteLines(indexSet: indexSetToRemove)
        default:
            break
        }
        
        completionHandler(nil)
    }
    
}

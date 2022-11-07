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
    
    enum CommandDirection {
        case up
        case down
    }
    
    func perform(with invocation: XCSourceEditorCommandInvocation,
                 completionHandler: @escaping (Error?) -> Void ) -> Void {
        guard let textRange = invocation.buffer.selections.firstObject as? XCSourceTextRange,
            invocation.buffer.lines.count > 0 else {
            completionHandler(nil)
            return
        }
        
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            completionHandler(nil)
            return
        }
        
        let targetRange = Range(uncheckedBounds: (lower: textRange.start.line,
                                                  upper: min(textRange.end.line + 1, invocation.buffer.lines.count)))
        
        let indexSet = IndexSet(integersIn: targetRange)
        let selectedLines = invocation.buffer.lines.objects(at: indexSet)
        
        func deleteLines(indexSet: IndexSet) {
            invocation.buffer.lines.removeObjects(at: indexSet)
            let lineSelection = XCSourceTextRange()
            lineSelection.start = XCSourceTextPosition(line: targetRange.lowerBound, column: 0)
            lineSelection.end = XCSourceTextPosition(line: targetRange.lowerBound, column: 0)
            invocation.buffer.selections.setArray([lineSelection])
        }
        
        func clearLines(indexSet: IndexSet) {
            for i in indexSet {
                invocation.buffer.lines[i] = ""
            }
        
            let lineSelection = XCSourceTextRange()
            lineSelection.start = XCSourceTextPosition(line: targetRange.lowerBound, column: 0)
            lineSelection.end = XCSourceTextPosition(line: targetRange.lowerBound, column: 0)
            invocation.buffer.selections.setArray([lineSelection])
        }

        func copyLines(_ lines: [String]) {
            let pasteboard = NSPasteboard.general
            pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
            pasteboard.setString(lines.joined(), forType: NSPasteboard.PasteboardType.string)
        }
        
        func duplicateLine(direction: CommandDirection) {
            let lineSelection = XCSourceTextRange()
            
            switch direction {
            case .up:
                lineSelection.start = XCSourceTextPosition(line: textRange.start.line,
                                                           column: textRange.start.column)
                lineSelection.end = XCSourceTextPosition(line: textRange.end.line,
                                                         column: textRange.end.column)
            case .down:
                lineSelection.start = XCSourceTextPosition(line: textRange.start.line + targetRange.count,
                                                           column: textRange.start.column)
                lineSelection.end = XCSourceTextPosition(line: textRange.end.line + targetRange.count,
                                                         column: textRange.end.column)
            }
            
            invocation.buffer.lines.insert(selectedLines, at: indexSet)
            invocation.buffer.selections.setArray([lineSelection])
        }
        
        func notReachingTop() -> Bool {
            return textRange.start.line > 0
        }
        
        func notReachingBottom() -> Bool {
            return textRange.end.line < (invocation.buffer.lines.count - 1)
        }
        
        func moveLine(direction: CommandDirection) {
            let lineIndexesWhereInsertingSelectionAfterMove: IndexSet
            let lineSelection = XCSourceTextRange()
            
            switch direction {
            case .up:
                guard notReachingTop() else { return }
                
                lineIndexesWhereInsertingSelectionAfterMove = IndexSet(indexSet.map { $0 - 1 })
                lineSelection.start = XCSourceTextPosition(line: textRange.start.line - 1,
                                                           column: textRange.start.column)
                lineSelection.end = XCSourceTextPosition(line: textRange.end.line - 1,
                                                         column: textRange.end.column)
            case .down:
                guard notReachingBottom() else { return }
                
                lineIndexesWhereInsertingSelectionAfterMove = IndexSet(indexSet.map { $0 + 1 })
                lineSelection.start = XCSourceTextPosition(line: textRange.start.line + 1,
                                                           column: textRange.start.column)
                lineSelection.end = XCSourceTextPosition(line: textRange.end.line + 1,
                                                         column: textRange.end.column)
            }
            
            invocation.buffer.lines.removeObjects(at: indexSet)
            invocation.buffer.lines.insert(selectedLines, at: lineIndexesWhereInsertingSelectionAfterMove)
            invocation.buffer.selections.setArray([lineSelection])
        }
        
        func insertLine(direction: CommandDirection) {
            if direction == .down && !notReachingBottom() { return }
            
            let firstRow = textRange.start.line
            guard var firstLine = invocation.buffer.lines[firstRow] as? String else { return }
            firstLine = firstLine.trimEnd()
            
            var insertedLine = firstLine.leadingSpaces()
            let insertedRow: Int
            
            switch direction {
            case .up:
                insertedRow = max(firstRow, 0)
            case .down:
                insertedRow = firstRow + 1
                
                if firstLine.hasSuffix("{")
                    || firstLine.hasSuffix("(")
                    || firstLine.hasSuffix(":") {
                    insertedLine = String.spaces(count: invocation.buffer.indentationWidth) + insertedLine
                }
            }
            
            invocation.buffer.lines.insert(insertedLine, at: insertedRow)
            
            let lineSelection = XCSourceTextRange(
                start: XCSourceTextPosition(line: insertedRow, column: insertedLine.count),
                end: XCSourceTextPosition(line: insertedRow, column: insertedLine.count)
            )
            invocation.buffer.selections.setArray([lineSelection])
        }

        func jumpToBlankLine(direction: CommandDirection) {
            let from: Int
            let to: Int
            let by: Int

            let lastIndex = invocation.buffer.lines.count - 1

            if (direction == .down) {
                from = min(textRange.start.line + 1, lastIndex)
                to = lastIndex
                by = 1
            }
            else {
                from = max(textRange.start.line - 1, 0)
                to = 0
                by = -1
            }

            for lineIndex in stride(from: from, to: to, by: by) {
                guard let line = invocation.buffer.lines[lineIndex] as? String else { continue }

                if line.trim().isEmpty {
                    let cursor = XCSourceTextRange(
                        start: XCSourceTextPosition(line: lineIndex, column: 0),
                        end: XCSourceTextPosition(line: lineIndex, column: 0)
                    );
                    invocation.buffer.selections.removeAllObjects();
                    invocation.buffer.selections.add(cursor)
                    break
                }
            }
        }
        
        // Switch all different commands id based which defined in Info.plist
        switch invocation.commandIdentifier {
        case bundleIdentifier + ".DeleteLine":
            deleteLines(indexSet: indexSet)
        case bundleIdentifier + ".MoveLineUp":
            moveLine(direction: .up)
        case bundleIdentifier + ".MoveLineDown":
            moveLine(direction: .down)
        case bundleIdentifier + ".DuplicateLineUp":
            duplicateLine(direction: .up)
        case bundleIdentifier + ".DuplicateLineDown":
            duplicateLine(direction: .down)
        case bundleIdentifier + ".CopyLine":
            guard let lines = selectedLines as? [String] else { break }
            copyLines(lines)
        case bundleIdentifier + ".CutLine":
            guard let lines = selectedLines as? [String] else { break }
            copyLines(lines)
            deleteLines(indexSet: indexSet)
        case bundleIdentifier + ".JoinLines":
            if indexSet.count == 1 {
                guard let currentRow = indexSet.last,
                      currentRow < invocation.buffer.lines.count - 1,
                      let firstLine = (invocation.buffer.lines[currentRow] as? String)?.trimEnd(),
                      let secondLine = (invocation.buffer.lines[currentRow + 1] as? String)?.trimStart()
                else { break }
                
                let newLine: String
                
                if firstLine.hasSuffix("(")
                    || firstLine.hasSuffix("[")
                    || secondLine.hasPrefix(".")
                    || secondLine.hasPrefix(")")
                    || secondLine.hasPrefix("]")
                {
                    newLine = firstLine + secondLine
                } else {
                    newLine = firstLine + " " + secondLine
                }
                
                invocation.buffer.lines[currentRow] = newLine
                invocation.buffer.lines.removeObject(at: currentRow + 1)
                
                if textRange.start.column == textRange.end.column {
                    let lineSelection = XCSourceTextRange()
                    lineSelection.start = XCSourceTextPosition(line: textRange.start.line, column: firstLine.count)
                    lineSelection.end = lineSelection.start
                    invocation.buffer.selections.setArray([lineSelection])
                }
            } else if indexSet.count > 1 {
                guard let currentRow = indexSet.first else { return }
                
                let selectedLines: [String] = (selectedLines as? [String])
                    .flatMap { selectedLines -> [String] in
                        return selectedLines.enumerated().map { index, line in
                            if index == 0 {
                                return line.trimEnd()
                            } else if index == selectedLines.count - 1 {
                                return line.trimStart()
                            } else {
                                return line.trim()
                            }
                        }
                    } ?? []
                
                var newLine = ""
                
                if selectedLines.count > 1 {
                    var previousLine = selectedLines[0]
                    newLine = previousLine
                    
                    for i in 1..<selectedLines.count {
                        let currentLine = selectedLines[i]
                        
                        if previousLine.hasSuffix("(")
                            || previousLine.hasSuffix("[")
                            || currentLine.hasPrefix(".")
                            || currentLine.hasPrefix(")")
                            || currentLine.hasPrefix("]")
                        {
                            newLine += currentLine
                        } else {
                            newLine += " " + currentLine
                        }
                        
                        previousLine = currentLine
                    }
                } else {
                    newLine = selectedLines.joined(separator: " ")
                }
                
                invocation.buffer.lines[currentRow] = newLine
                
                let indexSetToRemove = IndexSet(
                    integersIn: Range(
                        uncheckedBounds: (
                            lower: textRange.start.line + 1,
                            upper: min(textRange.end.line + 1, invocation.buffer.lines.count)
                        )
                    )
                )
                
                deleteLines(indexSet: indexSetToRemove)
                
                let lineSelection = XCSourceTextRange()
                lineSelection.start = XCSourceTextPosition(line: textRange.start.line, column: textRange.start.column)
                lineSelection.end = XCSourceTextPosition(line: textRange.start.line, column: newLine.count - 1)
                invocation.buffer.selections.setArray([lineSelection])
            }
        case bundleIdentifier + ".SplitLineByComma":
            guard let selectedLine = (selectedLines as? [String])?.first else { return }
 
            let placeHolderPattern = "<#T##.+?#>"
            
            var textArray = selectedLine.split(separator: ",", ignoredPattern: placeHolderPattern)
            
            let firstLine: String?
            
            if textArray.count > 1 {
                firstLine = textArray[0].trimEnd() + ","
            } else {
                firstLine = nil
            }
            
            let leadingSpaces: String
            
            if let firstLineText = firstLine?.trimEnd() {
                textArray[0] = firstLineText
                
                if let index = firstLineText.firstIndex(of: "(") {
                    let distance = firstLineText.distance(to: index)
                    leadingSpaces = String.spaces(count: distance + 1)
                } else if let index = firstLineText.firstIndex(of: "[") {
                    let distance = firstLineText.distance(to: index)
                    leadingSpaces = String.spaces(count: distance + 1)
                } else {
                    leadingSpaces = String.spaces(count: invocation.buffer.indentationWidth)
                        + firstLineText.leadingSpaces()
                }
            } else {
                leadingSpaces = ""
            }
            
            var remainingLines = [String]()
            
            for i in 1..<textArray.count {
                let text = textArray[i].trim()
                remainingLines.append(leadingSpaces + text)
            }
            
            let result = [textArray[0], remainingLines.joined(separator: ",\n")].joined(separator: "\n")
            deleteLines(indexSet: indexSet)
            
            let insertTargetRange = Range(
                uncheckedBounds: (lower: textRange.start.line, upper: textRange.start.line + 1)
            )
            let insertIndexSet = IndexSet(integersIn: insertTargetRange)
            invocation.buffer.lines.insert([result], at: insertIndexSet)
        case bundleIdentifier + ".RemoveEmptyLines":
            var emptyLineIndexArray = [Int]()
            
            for lineIndex in textRange.start.line...textRange.end.line {
                guard lineIndex < invocation.buffer.lines.count - 1,
                    let line = invocation.buffer.lines[lineIndex] as? String
                    else { break }
                
                if line.trim().isEmpty {
                    emptyLineIndexArray.append(lineIndex)
                }
            }
            
            let indexSetToRemove = IndexSet(emptyLineIndexArray)
            deleteLines(indexSet: indexSetToRemove)
        case bundleIdentifier + ".InsertLineAfter":
            insertLine(direction: .down)
        case bundleIdentifier + ".InsertLineBefore":
            insertLine(direction: .up)
        case bundleIdentifier + ".ClearLine":
            clearLines(indexSet: indexSet)
        case bundleIdentifier + ".ClearLineAndPaste":
            clearLines(indexSet: indexSet)
            let pasteboard = NSPasteboard.general
            
            if let pasteboardString = pasteboard.string(forType: .string) {
                if notReachingBottom() {
                    invocation.buffer.lines.removeObject(at: textRange.start.line)
                }
                
                invocation.buffer.lines.insert(pasteboardString.trimEnd(), at: textRange.start.line)
            }
        case bundleIdentifier + ".NextBlankLine":
            jumpToBlankLine(direction: .down)
        case bundleIdentifier + ".PrevBlankLine":
            jumpToBlankLine(direction: .up)
        default:
            break
        }
        
        completionHandler(nil)
    }
    
}

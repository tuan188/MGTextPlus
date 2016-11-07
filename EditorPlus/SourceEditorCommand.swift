//
//  SourceEditorCommand.swift
//  EditorPlus
//
//  Created by Tuan Truong on 11/7/16.
//  Copyright © 2016 Tuan Truong. All rights reserved.
//

import Foundation
import XcodeKit

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
        
        switch invocation.commandIdentifier {
        case bundleIdentifier + ".RemoveComment":
            var commentIndexArray = [Int]()
            for lineIndex in textRange.start.line...textRange.end.line {
                guard lineIndex < invocation.buffer.lines.count else {
                    break
                }
                let line = invocation.buffer.lines[lineIndex] as! String
                if line.trim().hasPrefix("//") {
                    commentIndexArray.append(lineIndex)
                }
                else if line.contains("//") {
                    invocation.buffer.lines[lineIndex] = line.removeComment().trimEnd()
                }
            }
            let indexSetToRemove = IndexSet(commentIndexArray)
            deleteLines(indexSet: indexSetToRemove)
        default:
            break
        }
        
        completionHandler(nil)
    }
    
}

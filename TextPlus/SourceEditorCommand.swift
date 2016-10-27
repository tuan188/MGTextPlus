//
//  SourceEditorCommand.swift
//  TextPlus
//
//  Created by Tuan Truong on 10/26/16.
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
        
        let deleteLinesIdentifier = bundleIdentifier + ".DeleteLines"
        let duplicateLinesIdentifier = bundleIdentifier + ".DuplicateLines"
//        let moveLinesUpIdentifier = bundleIdentifier + ".MoveLinesUp"
//        let moveLinesDownIdentifier = bundleIdentifier + ".MoveLinesDown"
        let copyLineIdentifier = bundleIdentifier + ".CopyLine"
        let cutLineIdentifier = bundleIdentifier + ".CutLine"
        
        let targetRange = Range(uncheckedBounds: (lower: textRange.start.line, upper: min(textRange.end.line + 1, invocation.buffer.lines.count)))
        let indexSet = IndexSet(integersIn: targetRange)
        let selectedLines = invocation.buffer.lines.objects(at: indexSet)
        
        // Switch all different commands id based which defined in Info.plist
        switch invocation.commandIdentifier {
        case deleteLinesIdentifier:
            invocation.buffer.lines.removeObjects(at: IndexSet(integersIn: targetRange))
        case duplicateLinesIdentifier:
            invocation.buffer.lines.insert(selectedLines, at: indexSet)
//        case moveLinesUpIdentifier:
//            guard targetRange.lowerBound - 1 >= 0 else {
//                break
//            }
//            invocation.buffer.lines.removeObjects(at: IndexSet(integersIn: targetRange))
//            let newTargetRange = Range(uncheckedBounds: (lower: targetRange.lowerBound - 1, upper: targetRange.upperBound - 1))
//            let newIndexSet = IndexSet(integersIn: newTargetRange)
//            invocation.buffer.lines.insert(selectedLines, at: newIndexSet)
//        case moveLinesDownIdentifier:
//            guard targetRange.lowerBound + targetRange.count < invocation.buffer.lines.count else {
//                break
//            }
//            invocation.buffer.lines.removeObjects(at: IndexSet(integersIn: targetRange))
//            let newTargetRange = Range(uncheckedBounds: (lower: targetRange.lowerBound + 1, upper: targetRange.upperBound + 1))
//            let newIndexSet = IndexSet(integersIn: newTargetRange)
//            invocation.buffer.lines.insert(selectedLines, at: newIndexSet)
        case copyLineIdentifier:
            if indexSet.count == 1 {
                if let line = invocation.buffer.lines[indexSet.first!] as? String {
                    NSPasteboard.general().setString(line, forType: NSPasteboardTypeString)
                }
            }
        case cutLineIdentifier:
            if indexSet.count == 1 {
                if let line = invocation.buffer.lines[indexSet.first!] as? String {
                    NSPasteboard.general().setString(line, forType: NSPasteboardTypeString)
                    invocation.buffer.lines.removeObjects(at: IndexSet(integersIn: targetRange))
                }
            }
        default:
            break
        }
        
        completionHandler(nil)
    }
    
}

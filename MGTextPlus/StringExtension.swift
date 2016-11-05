//
//  StringExtension.swift
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
}

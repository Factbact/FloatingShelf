//
//  ItemKind.swift
//  FloatingShelf
//

import Foundation

/// Represents the type of item stored in a shelf
enum ItemKind: String, CaseIterable {
    case file           // Regular file from Finder
    case promisedFile   // File received via NSFilePromiseReceiver (e.g., from Mail)
    case image          // Image data
    case text           // Text string
    case url            // URL string
    
    var displayName: String {
        switch self {
        case .file: return "File"
        case .promisedFile: return "Promised File"
        case .image: return "Image"
        case .text: return "Text"
        case .url: return "URL"
        }
    }
    
    var iconName: String {
        switch self {
        case .file, .promisedFile: return "doc.fill"
        case .image: return "photo.fill"
        case .text: return "text.alignleft"
        case .url: return "link"
        }
    }
}

//
//  Constants.swift
//  FloatingShelf
//

import Foundation

enum Constants {
    // File Storage
    static let containerDirectoryName = "ShelfStorage"
    static let thumbnailsDirectoryName = "Thumbnails"
    
    // Hotkey defaults
    static let defaultHotkeyKeyCode: UInt32 = 49 // Space key
    static let defaultHotkeyModifiers: UInt32 = 768 // Cmd + Shift
    
    // UI Constants
    static let defaultShelfWidth: CGFloat = 200
    static let defaultShelfHeight: CGFloat = 200
    static let itemThumbnailSize: CGFloat = 96
    static let maxThumbnailSize: CGFloat = 512
    
    // Animation
    static let animationDuration: Double = 0.3
    
    // Limits
    static let maxItemsPerShelf: Int = 100
}

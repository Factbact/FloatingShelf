//
//  HotkeyManager.swift
//  FloatingShelf
//

import Cocoa
import Carbon

protocol HotkeyManagerDelegate: AnyObject {
    func hotkeyPressed()
}

class HotkeyManager {
    
    weak var delegate: HotkeyManagerDelegate?
    
    private var eventHotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    
    deinit {
        unregisterHotkey()
    }
    
    func registerHotkey(keyCode: UInt32, modifiers: UInt32) {
        unregisterHotkey()
        
        let hotKeyID = EventHotKeyID(signature: OSType(0x46534820), id: 1) // 'FSH ' = FloatingShelf Hotkey
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        // Install event handler
        InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, event, userData) -> OSStatus in
            guard let userData = userData else { return noErr }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            manager.delegate?.hotkeyPressed()
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &eventHandlerRef)
        
        // Register hotkey
        var mutableHotKeyID = hotKeyID
        let status = RegisterEventHotKey(keyCode, modifiers, mutableHotKeyID, GetApplicationEventTarget(), 0, &eventHotKeyRef)
        
        if status != noErr {
            print("Failed to register hotkey: \(status)")
        }
    }
    
    func unregisterHotkey() {
        if let ref = eventHotKeyRef {
            UnregisterEventHotKey(ref)
            eventHotKeyRef = nil
        }
        
        if let ref = eventHandlerRef {
            RemoveEventHandler(ref)
            eventHandlerRef = nil
        }
    }
}

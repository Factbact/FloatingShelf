//
//  ActionBarView.swift
//  FloatingShelf
//

import Cocoa

protocol ActionBarDelegate: AnyObject {
    func actionBarDidRequestShare(_ actionBar: ActionBarView)
    func actionBarDidRequestCopy(_ actionBar: ActionBarView)
    func actionBarDidRequestSave(_ actionBar: ActionBarView)
    func actionBarDidRequestDelete(_ actionBar: ActionBarView)
}

class ActionBarView: NSView {
    
    weak var delegate: ActionBarDelegate?
    
    private(set) var shareButton: NSButton!
    private var copyButton: NSButton!
    private var saveButton: NSButton!
    private var deleteButton: NSButton!
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        // Create buttons
        shareButton = createButton(title: "Share", 
                                   icon: "square.and.arrow.up",
                                   action: #selector(shareAction))
        
        copyButton = createButton(title: "Copy",
                                 icon: "doc.on.doc",
                                 action: #selector(copyAction))
        
        saveButton = createButton(title: "Save to...",
                                 icon: "folder",
                                 action: #selector(saveAction))
        
        deleteButton = createButton(title: "Delete",
                                   icon: "trash",
                                   action: #selector(deleteAction))
        
        // Stack view for button layout
        let stackView = NSStackView(views: [shareButton, copyButton, saveButton, NSView(), deleteButton])
        stackView.orientation = .horizontal
        stackView.spacing = 12
        stackView.edgeInsets = NSEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        setEnabled(false)
    }
    
    private func createButton(title: String, icon: String, action: Selector) -> NSButton {
        let button = NSButton()
        button.title = title
        button.bezelStyle = .rounded
        button.setButtonType(.momentaryPushIn)
        
        if let image = NSImage(systemSymbolName: icon, accessibilityDescription: title) {
            button.image = image
            button.imagePosition = .imageLeading
        }
        
        button.target = self
        button.action = action
        
        return button
    }
    
    func setEnabled(_ enabled: Bool) {
        shareButton.isEnabled = enabled
        copyButton.isEnabled = enabled
        saveButton.isEnabled = enabled
        deleteButton.isEnabled = enabled
    }
    
    // MARK: - Actions
    
    @objc private func shareAction() {
        delegate?.actionBarDidRequestShare(self)
    }
    
    @objc private func copyAction() {
        delegate?.actionBarDidRequestCopy(self)
    }
    
    @objc private func saveAction() {
        delegate?.actionBarDidRequestSave(self)
    }
    
    @objc private func deleteAction() {
        delegate?.actionBarDidRequestDelete(self)
    }
}

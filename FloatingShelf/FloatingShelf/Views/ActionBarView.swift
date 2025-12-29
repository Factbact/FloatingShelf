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
        
        // Create compact icon-only buttons
        shareButton = createIconButton(icon: "square.and.arrow.up", 
                                       tooltip: "Share",
                                       action: #selector(shareAction))
        
        copyButton = createIconButton(icon: "doc.on.doc",
                                      tooltip: "Copy",
                                      action: #selector(copyAction))
        
        saveButton = createIconButton(icon: "folder",
                                      tooltip: "Save to...",
                                      action: #selector(saveAction))
        
        deleteButton = createIconButton(icon: "trash",
                                        tooltip: "Delete",
                                        action: #selector(deleteAction))
        
        // Stack view for compact button layout
        let stackView = NSStackView(views: [shareButton, copyButton, saveButton, deleteButton])
        stackView.orientation = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])
        
        setEnabled(false)
    }
    
    private func createIconButton(icon: String, tooltip: String, action: Selector) -> NSButton {
        let button = NSButton()
        button.bezelStyle = .regularSquare
        button.isBordered = false
        button.setButtonType(.momentaryPushIn)
        button.toolTip = tooltip
        
        if let image = NSImage(systemSymbolName: icon, accessibilityDescription: tooltip) {
            button.image = image
            button.imagePosition = .imageOnly
            button.imageScaling = .scaleProportionallyUpOrDown
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

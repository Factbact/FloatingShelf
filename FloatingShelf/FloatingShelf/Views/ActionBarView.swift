//
//  ActionBarView.swift
//  FloatingShelf
//

import Cocoa

protocol ActionBarDelegate: AnyObject {
    func actionBarDidRequestShare(_ actionBar: ActionBarView)
    func actionBarDidRequestAirDrop(_ actionBar: ActionBarView)
    func actionBarDidRequestCopy(_ actionBar: ActionBarView)
    func actionBarDidRequestPaste(_ actionBar: ActionBarView)
    func actionBarDidRequestSave(_ actionBar: ActionBarView)
    func actionBarDidRequestDelete(_ actionBar: ActionBarView)
    func actionBarDidRequestZip(_ actionBar: ActionBarView)
    func actionBarDidRequestSelectAll(_ actionBar: ActionBarView)
    func actionBarDidRequestSort(_ actionBar: ActionBarView, by sortType: SortType)
}

enum SortType {
    case nameAscending
    case nameDescending
    case dateNewest
    case dateOldest
}

class ActionBarView: NSView {
    
    weak var delegate: ActionBarDelegate?
    
    private(set) var shareButton: NSButton!
    private var airDropButton: NSButton!
    private var copyButton: NSButton!
    private var pasteButton: NSButton!
    private var saveButton: NSButton!
    private var deleteButton: NSButton!
    private var zipButton: NSButton!
    private var selectAllButton: NSButton!
    private var sortButton: NSButton!
    
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
        layer?.backgroundColor = NSColor.black.withAlphaComponent(0.6).cgColor
        layer?.cornerRadius = 10
        
        shareButton = createIconButton(icon: "square.and.arrow.up", 
                                       tooltip: "Share",
                                       action: #selector(shareAction))
        
        airDropButton = createIconButton(icon: "airplane",
                                         tooltip: "AirDrop",
                                         action: #selector(airDropAction))
        
        copyButton = createIconButton(icon: "doc.on.doc",
                                      tooltip: "Copy",
                                      action: #selector(copyAction))
        
        pasteButton = createIconButton(icon: "doc.on.clipboard",
                                       tooltip: "Paste",
                                       action: #selector(pasteAction))
        
        saveButton = createIconButton(icon: "folder",
                                      tooltip: "Save to...",
                                      action: #selector(saveAction))
        
        deleteButton = createIconButton(icon: "trash",
                                        tooltip: "Delete",
                                        action: #selector(deleteAction))
        
        zipButton = createIconButton(icon: "archivebox",
                                     tooltip: "Create ZIP",
                                     action: #selector(zipAction))
        
        selectAllButton = createIconButton(icon: "checkmark.circle",
                                           tooltip: "Select All",
                                           action: #selector(selectAllAction))
        
        sortButton = createIconButton(icon: "arrow.up.arrow.down",
                                      tooltip: "Sort",
                                      action: #selector(sortAction))
        
        // Map button IDs to buttons
        let buttonMap: [String: NSButton] = [
            "selectAll": selectAllButton,
            "sort": sortButton,
            "share": shareButton,
            "airdrop": airDropButton,
            "copy": copyButton,
            "paste": pasteButton,
            "save": saveButton,
            "zip": zipButton,
            "delete": deleteButton
        ]
        
        // Build stack view with only visible buttons
        let visibleIds = SettingsManager.shared.visibleActionButtons
        let visibleButtons = visibleIds.compactMap { buttonMap[$0] }
        
        let stackView = NSStackView(views: visibleButtons.isEmpty ? [selectAllButton, deleteButton] : visibleButtons)
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
        airDropButton.isEnabled = enabled
        copyButton.isEnabled = enabled
        saveButton.isEnabled = enabled
        deleteButton.isEnabled = enabled
        zipButton.isEnabled = enabled
        // Paste is always enabled
        pasteButton.isEnabled = true
    }
    
    // MARK: - Actions
    
    @objc private func shareAction() {
        delegate?.actionBarDidRequestShare(self)
    }
    
    @objc private func airDropAction() {
        delegate?.actionBarDidRequestAirDrop(self)
    }
    
    @objc private func copyAction() {
        delegate?.actionBarDidRequestCopy(self)
    }
    
    @objc private func pasteAction() {
        delegate?.actionBarDidRequestPaste(self)
    }
    
    @objc private func saveAction() {
        delegate?.actionBarDidRequestSave(self)
    }
    
    @objc private func deleteAction() {
        delegate?.actionBarDidRequestDelete(self)
    }
    
    @objc private func zipAction() {
        delegate?.actionBarDidRequestZip(self)
    }
    
    @objc private func selectAllAction() {
        delegate?.actionBarDidRequestSelectAll(self)
    }
    
    @objc private func sortAction() {
        let menu = NSMenu()
        
        let nameAscItem = NSMenuItem(title: "名前 A→Z", action: #selector(sortNameAsc), keyEquivalent: "")
        nameAscItem.target = self
        menu.addItem(nameAscItem)
        
        let nameDescItem = NSMenuItem(title: "名前 Z→A", action: #selector(sortNameDesc), keyEquivalent: "")
        nameDescItem.target = self
        menu.addItem(nameDescItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let dateNewItem = NSMenuItem(title: "日付 新しい順", action: #selector(sortDateNew), keyEquivalent: "")
        dateNewItem.target = self
        menu.addItem(dateNewItem)
        
        let dateOldItem = NSMenuItem(title: "日付 古い順", action: #selector(sortDateOld), keyEquivalent: "")
        dateOldItem.target = self
        menu.addItem(dateOldItem)
        
        let location = NSPoint(x: sortButton.frame.midX, y: sortButton.frame.maxY)
        menu.popUp(positioning: nil, at: location, in: self)
    }
    
    @objc private func sortNameAsc() { delegate?.actionBarDidRequestSort(self, by: .nameAscending) }
    @objc private func sortNameDesc() { delegate?.actionBarDidRequestSort(self, by: .nameDescending) }
    @objc private func sortDateNew() { delegate?.actionBarDidRequestSort(self, by: .dateNewest) }
    @objc private func sortDateOld() { delegate?.actionBarDidRequestSort(self, by: .dateOldest) }
}

//
//  ShelfViewController.swift
//  FloatingShelf
//

import Cocoa
import Quartz

class ShelfViewController: NSViewController {
    
    private var shelf: Shelf
    private var gridView: ShelfGridView!
    private var actionBar: ActionBarView!
    private var dropReceiver: DropReceiver!
    private var nameField: NSTextField?
    private var colorButton: NSButton?
    private var expandButton: NSButton?  // For expand/collapse toggle
    
    private var items: [ShelfItem] = []
    private var selectedItems: Set<UUID> = []
    private var isExpanded: Bool = false  // For expand/collapse view

    private var autoHideTimer: Timer?
    private var eventMonitor: Any?  // For monitoring Quick Look key events
    
    init(shelf: Shelf) {
        self.shelf = shelf
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let dropView = DropView(frame: NSRect(x: 0, y: 0, 
                                              width: Constants.defaultShelfWidth, 
                                              height: Constants.defaultShelfHeight))
        view = dropView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadItems()
        
        // Set up drop receiver after view is loaded
        if let dropView = view as? DropView {
            dropReceiver = DropReceiver(shelfId: shelf.id)
            dropReceiver.delegate = self
            dropView.dropReceiver = dropReceiver
            dropView.registerForDraggedTypes(dropReceiver.acceptedTypes)
        }
        // Note: Do NOT register drag types on gridView or its subviews
        // DropView (parent) handles all drags to ensure events are not intercepted
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        // Note: Auto-focus removed because it caused crashes.
        // User can click on name field to edit.
    }
    
    // MARK: - Event Handling
    
    override func keyDown(with event: NSEvent) {
        // Cmd+A = Select All
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "a" {
            selectAllItems()
            return
        }
        
        // Space bar = Quick Look
        if event.keyCode == 49 && !selectedItems.isEmpty {
            showQuickLook()
        } else {
            super.keyDown(with: event)
        }
    }
    
    private func selectAllItems() {
        selectedItems = Set(items.map { $0.id })
        gridView.selectAll(selectedItems)
        updateActionBarState()
    }
    
    override var acceptsFirstResponder: Bool { true }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        // Ensure DropView itself is transparent BUT masks bounds for corner radius
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        view.layer?.cornerRadius = 20
        view.layer?.cornerCurve = .continuous
        view.layer?.masksToBounds = true
        
        // Vibrancy background (add FIRST, at the bottom of z-order)
        let vibrancyView = NSVisualEffectView()
        vibrancyView.material = .hudWindow
        vibrancyView.blendingMode = .withinWindow
        vibrancyView.state = .active
        vibrancyView.isEmphasized = true
        vibrancyView.wantsLayer = true
        vibrancyView.layer?.cornerRadius = 20
        vibrancyView.layer?.cornerCurve = .continuous
        vibrancyView.layer?.masksToBounds = true
        vibrancyView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(vibrancyView)
        
        NSLayoutConstraint.activate([
            vibrancyView.topAnchor.constraint(equalTo: view.topAnchor),
            vibrancyView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            vibrancyView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            vibrancyView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Grid view for items
        gridView = ShelfGridView()
        gridView.translatesAutoresizingMaskIntoConstraints = false
        gridView.delegate = self
        view.addSubview(gridView)
        
        // Action bar at bottom (hidden by default, shows on hover)
        actionBar = ActionBarView()
        actionBar.translatesAutoresizingMaskIntoConstraints = false
        actionBar.delegate = self
        actionBar.alphaValue = 0  // Hidden initially
        view.addSubview(actionBar)
        
        // Custom title bar for borderless window (add LAST to be on top)
        let titleBar = createCustomTitleBar()
        titleBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleBar)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // Title bar at top
            titleBar.topAnchor.constraint(equalTo: view.topAnchor),
            titleBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            titleBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            titleBar.heightAnchor.constraint(equalToConstant: 28),
            
            // Grid view fills to bottom (action bar overlays)
            gridView.topAnchor.constraint(equalTo: titleBar.bottomAnchor),
            gridView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gridView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gridView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Action bar overlays bottom
            actionBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            actionBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            actionBar.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
            actionBar.heightAnchor.constraint(equalToConstant: 36)
        ])
        
        // Set up hover tracking
        setupHoverTracking()
    }
    
    private func setupHoverTracking() {
        let trackingArea = NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        view.addTrackingArea(trackingArea)
    }
    
    override func mouseEntered(with event: NSEvent) {
        // Show action bar
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            actionBar.animator().alphaValue = 1
        }
        
        // Auto-expand if items exist, but NOT during a drag operation
        // (window resize during drag causes kDragIPCLeaveApplication which cancels the drop)
        let isDragging = (view as? DropView)?.isDragging ?? false
        if !items.isEmpty && !isExpanded && !isDragging {
            toggleExpand()
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        // Hide action bar
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            actionBar.animator().alphaValue = 0
        }
        
        // Auto-collapse
        if isExpanded {
            toggleExpand()
        }
    }
    
    private func createCustomTitleBar() -> NSView {
        let titleBar = DraggableTitleView()
        titleBar.wantsLayer = true
        
        // Apply shelf color to title bar
        let shelfColor = NSColor(hex: shelf.colorHex) ?? NSColor.systemBlue
        titleBar.layer?.backgroundColor = shelfColor.withAlphaComponent(0.9).cgColor
        
        // Round only top corners
        titleBar.layer?.cornerRadius = 20
        titleBar.layer?.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        
        // Close button - macOS style red circle
        let closeButton = NSButton()
        closeButton.bezelStyle = .regularSquare
        closeButton.isBordered = false
        closeButton.wantsLayer = true
        closeButton.layer?.cornerRadius = 12
        closeButton.layer?.backgroundColor = NSColor.systemRed.withAlphaComponent(0.9).cgColor
        closeButton.title = ""
        closeButton.target = self
        closeButton.action = #selector(closeWindow)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        let xLabel = NSTextField(labelWithString: "✕")
        xLabel.font = NSFont.systemFont(ofSize: 14, weight: .bold)
        xLabel.textColor = NSColor.white
        xLabel.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addSubview(xLabel)
        
        // Expand button - toggle expand/collapse view
        let expandButton = NSButton()
        expandButton.bezelStyle = .regularSquare
        expandButton.isBordered = false
        expandButton.wantsLayer = true
        expandButton.title = "⌄"  // Chevron down for expand
        expandButton.font = NSFont.systemFont(ofSize: 14, weight: .bold)
        expandButton.contentTintColor = .white
        expandButton.target = self
        expandButton.action = #selector(toggleExpand)
        expandButton.translatesAutoresizingMaskIntoConstraints = false
        self.expandButton = expandButton
        
        // Color picker button - using standard NSButton for reliability
        let colorButton = NSButton()
        colorButton.bezelStyle = .regularSquare
        colorButton.isBordered = false
        colorButton.wantsLayer = true
        colorButton.layer?.cornerRadius = 8
        colorButton.layer?.backgroundColor = shelfColor.cgColor
        colorButton.layer?.borderWidth = 1
        colorButton.layer?.borderColor = NSColor.white.withAlphaComponent(0.6).cgColor
        colorButton.target = self
        colorButton.action = #selector(showColorPicker)
        colorButton.translatesAutoresizingMaskIntoConstraints = false
        self.colorButton = colorButton
        
        // Name field - not editable by default, double-click to edit
        let field = NSTextField()
        field.stringValue = shelf.name
        field.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        field.textColor = NSColor.white
        field.backgroundColor = .clear
        field.isBordered = false
        field.isEditable = false  // Disabled by default for dragging
        field.isSelectable = false  // Prevent click from grabbing focus
        field.focusRingType = .none
        field.alignment = .center
        field.target = self
        field.action = #selector(shelfNameChanged(_:))
        field.translatesAutoresizingMaskIntoConstraints = false
        self.nameField = field
        
        // Double-click to edit name
        let doubleClick = NSClickGestureRecognizer(target: self, action: #selector(enableNameEditing))
        doubleClick.numberOfClicksRequired = 2
        field.addGestureRecognizer(doubleClick)
        
        // Add subviews (order matters for z-index)
        titleBar.addSubview(field)
        titleBar.addSubview(closeButton)
        titleBar.addSubview(expandButton)
        titleBar.addSubview(colorButton) // Last = on top
        
        NSLayoutConstraint.activate([
            // Close button
            closeButton.leadingAnchor.constraint(equalTo: titleBar.leadingAnchor, constant: 10),
            closeButton.centerYAnchor.constraint(equalTo: titleBar.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24),
            
            // X centered in button
            xLabel.centerXAnchor.constraint(equalTo: closeButton.centerXAnchor),
            xLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            
            // Expand button (after close button)
            expandButton.leadingAnchor.constraint(equalTo: closeButton.trailingAnchor, constant: 4),
            expandButton.centerYAnchor.constraint(equalTo: titleBar.centerYAnchor),
            expandButton.widthAnchor.constraint(equalToConstant: 20),
            expandButton.heightAnchor.constraint(equalToConstant: 20),
            
            // Color picker button (right side)
            colorButton.trailingAnchor.constraint(equalTo: titleBar.trailingAnchor, constant: -10),
            colorButton.centerYAnchor.constraint(equalTo: titleBar.centerYAnchor),
            colorButton.widthAnchor.constraint(equalToConstant: 16),
            colorButton.heightAnchor.constraint(equalToConstant: 16),
            
            // Name field
            field.leadingAnchor.constraint(equalTo: expandButton.trailingAnchor, constant: 4),
            field.trailingAnchor.constraint(equalTo: colorButton.leadingAnchor, constant: -8),
            field.centerYAnchor.constraint(equalTo: titleBar.centerYAnchor)
        ])
        
        return titleBar
    }
    
    private var colorPopover: NSPopover?
    

    
    // Preset colors
    private let presetColors: [String] = [
        "#4A90D9", // Blue
        "#5C6BC0", // Indigo
        "#7E57C2", // Purple
        "#EC407A", // Pink
        "#EF5350", // Red
        "#FF7043", // Orange
        "#FFCA28", // Yellow
        "#66BB6A", // Green
        "#26A69A", // Teal
        "#78909C"  // Gray
    ]
    
    @objc private func showColorPicker() {
        guard let colorButton = self.colorButton else { return }
        
        let menu = NSMenu(title: "Shelf Color")
        
        for (index, colorHex) in presetColors.enumerated() {
            let color = NSColor(hex: colorHex)
            let isCurrent = (colorHex == shelf.colorHex)
            
            // Create a small circle image for the menu item
            let size = NSSize(width: 16, height: 16)
            let image = NSImage(size: size)
            
            image.lockFocus()
            
            let path = NSBezierPath(ovalIn: NSRect(origin: .zero, size: size))
            color?.setFill()
            path.fill()
            
            if isCurrent {
                NSColor.white.setStroke()
                path.lineWidth = 2
                path.stroke()
            }
            
            image.unlockFocus()
            
            // Create menu item with image
            let item = NSMenuItem(title: "   ", action: #selector(colorSelectedFromMenu(_:)), keyEquivalent: "")
            item.image = image
            item.tag = index
            item.target = self
            
            // Add checkmark if selected (system standard)
            item.state = isCurrent ? .on : .off
            
            menu.addItem(item)
        }
        
        // Show menu under the button
        let location = NSPoint(x: 0, y: colorButton.bounds.height + 5)
        menu.popUp(positioning: nil, at: location, in: colorButton)
    }
    
    @objc private func colorSelectedFromMenu(_ sender: NSMenuItem) {
        let colorHex = presetColors[sender.tag]
        shelf.colorHex = colorHex
        ItemStore.shared.updateShelf(shelf)
        
        // Update UI immediately without full rebuild if possible
        if let newColor = NSColor(hex: colorHex) {
            colorButton?.layer?.backgroundColor = newColor.cgColor
        }
        
        // Full rebuild for other effects
        view.subviews.forEach { $0.removeFromSuperview() }
        setupUI()
        loadItems()  // Reload items after UI rebuild
    }
    
    @objc private func shelfNameChanged(_ sender: NSTextField) {
        shelf.name = sender.stringValue
        ItemStore.shared.updateShelf(shelf)
        // Disable editing again after change
        sender.isEditable = false
        sender.isSelectable = false
    }
    
    @objc private func enableNameEditing() {
        nameField?.isEditable = true
        nameField?.isSelectable = true
        nameField?.becomeFirstResponder()
    }
    
    @objc private func closeWindow() {
        view.window?.close()
    }
    
    // MARK: - Clipboard Support
    
    @objc func paste(_ sender: Any?) {
        pasteFromClipboard()
    }
    
    private func pasteFromClipboard() {
        let pasteboard = NSPasteboard.general
        
        do {
            let newItems = try dropReceiver.processPasteboard(pasteboard)
            
            if newItems.isEmpty {
                // No valid content in clipboard
                return
            }
            
            // Add items to store
            for item in newItems {
                ItemStore.shared.addItem(item, to: shelf.id)
            }
            
            // Reload
            items.append(contentsOf: newItems)
            gridView.reloadData(with: items)
            checkAutoHide()
            
        } catch {
            let alert = NSAlert()
            alert.messageText = "Paste Failed"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.runModal()
        }
    }
    
    // MARK: - Quick Look
    
    private func showQuickLook() {
        guard !selectedItems.isEmpty else { return }
        
        if let panel = QLPreviewPanel.shared() {
            panel.makeKeyAndOrderFront(nil)
        }
    }
    
    override func acceptsPreviewPanelControl(_ panel: QLPreviewPanel!) -> Bool {
        return true
    }
    
    override func beginPreviewPanelControl(_ panel: QLPreviewPanel!) {
        panel.delegate = self
        panel.dataSource = self
        
        // Monitor key events to handle space bar for closing
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 49 { // Space bar
                self?.toggleQuickLook(panel)
                return nil // Consume event
            }
            return event
        }
    }
    
    override func endPreviewPanelControl(_ panel: QLPreviewPanel!) {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    private func toggleQuickLook(_ panel: QLPreviewPanel) {
        if panel.isVisible {
            panel.close()
        } else {
            panel.makeKeyAndOrderFront(nil)
        }
    }
    
    // MARK: - Data
    
    private func loadItems() {
        items = ItemStore.shared.fetchItems(for: shelf.id)
        gridView.reloadData(with: items)
        updateActionBarState()
        checkAutoHide()
    }
    
    private func updateActionBarState() {
        actionBar.setEnabled(!selectedItems.isEmpty)
    }
    
    // MARK: - Expand/Collapse View
    
    @objc private func toggleExpand() {
        isExpanded.toggle()
        
        guard let window = view.window else { return }
        
        let newHeight: CGFloat
        if isExpanded {
            newHeight = calculateExpandedHeight()
        } else {
            newHeight = Constants.defaultShelfHeight
        }
        
        // Animate window resize
        var newFrame = window.frame
        let heightDiff = newHeight - newFrame.height
        newFrame.size.height = newHeight
        newFrame.origin.y -= heightDiff  // Keep top edge fixed
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            window.animator().setFrame(newFrame, display: true)
        }
    }
    
    private func calculateExpandedHeight() -> CGFloat {
        let itemCount = items.count
        guard itemCount > 0 else { return Constants.defaultShelfHeight }
        
        // Grid: 74x110 items + 8px spacing + 8px inset
        let itemsPerRow = 2  // 2 items per row in 200px width
        let itemHeight: CGFloat = 110 + 8  // item + spacing
        let rows = ceil(CGFloat(itemCount) / CGFloat(itemsPerRow))
        
        let titleBarHeight: CGFloat = 28
        let actionBarHeight: CGFloat = 44
        let topInset: CGFloat = 8
        let bottomInset: CGFloat = 8
        
        let contentHeight = rows * itemHeight + topInset + bottomInset
        let totalHeight = titleBarHeight + contentHeight + actionBarHeight
        
        // Cap at 600px max
        return min(totalHeight, 600)
    }
    
    private func checkAutoHide() {
        // Cancel existing timer
        autoHideTimer?.invalidate()
        autoHideTimer = nil
        
        // Only start timer if auto-hide is enabled and shelf is empty
        guard SettingsManager.shared.autoHideEnabled, items.isEmpty else { return }
        
        let delay = SettingsManager.shared.autoHideDelay
        autoHideTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.autoHideShelf()
        }
    }
    
    private func autoHideShelf() {
        guard let window = view.window else { return }
        
        // Fade out animation
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            window.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.closeWindow()
        })
    }
}

// MARK: - DropReceiverDelegate

extension ShelfViewController: DropReceiverDelegate {
    func dropReceiver(_ receiver: DropReceiver, didReceiveItems newItems: [ShelfItem]) {
        // Auto-name shelf from first file if shelf is still empty and has default name
        if items.isEmpty, !newItems.isEmpty {
            if let firstItem = newItems.first {
                // Use file name (without extension) as shelf name
                let fileName = firstItem.displayName
                let nameWithoutExt = (fileName as NSString).deletingPathExtension
                if !nameWithoutExt.isEmpty && shelf.name == "New Shelf" {
                    shelf.name = nameWithoutExt
                    ItemStore.shared.updateShelf(shelf)
                    // Update UI
                    nameField?.stringValue = nameWithoutExt
                }
            }
        }
        
        items.append(contentsOf: newItems)
        gridView.reloadData(with: items)
        checkAutoHide() // Cancel auto-hide if items were added
        
        // Auto-expand after drop to show newly added items
        if !isExpanded && !items.isEmpty {
            // Small delay to let the drop complete before resizing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.toggleExpand()
            }
        }
    }
    
    func dropReceiver(_ receiver: DropReceiver, didFailWithError error: Error) {
        let alert = NSAlert()
        alert.messageText = "Drop Failed"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.runModal()
    }
}

// MARK: - ShelfGridViewDelegate

extension ShelfViewController: ShelfGridViewDelegate {
    func gridView(_ gridView: ShelfGridView, didSelectItems itemIds: Set<UUID>) {
        selectedItems = itemIds
        updateActionBarState()
    }
    
    func gridView(_ gridView: ShelfGridView, didDeleteItems itemIds: Set<UUID>) {
        ItemStore.shared.deleteItems(Array(itemIds))
        items.removeAll { itemIds.contains($0.id) }
        selectedItems.removeAll()
        gridView.reloadData(with: items)
        updateActionBarState()
    }
}

// MARK: - ActionBarDelegate

extension ShelfViewController: ActionBarDelegate {
    func actionBarDidRequestShare(_ actionBar: ActionBarView) {
        let selectedItemsArray = items.filter { selectedItems.contains($0.id) }
        shareItems(selectedItemsArray)
    }
    
    func actionBarDidRequestAirDrop(_ actionBar: ActionBarView) {
        let selectedItemsArray = items.filter { selectedItems.contains($0.id) }
        airDropItems(selectedItemsArray)
    }
    
    func actionBarDidRequestCopy(_ actionBar: ActionBarView) {
        let selectedItemsArray = items.filter { selectedItems.contains($0.id) }
        copyItems(selectedItemsArray)
    }
    
    func actionBarDidRequestPaste(_ actionBar: ActionBarView) {
        pasteFromClipboard()
    }
    
    func actionBarDidRequestSave(_ actionBar: ActionBarView) {
        let selectedItemsArray = items.filter { selectedItems.contains($0.id) }
        saveItems(selectedItemsArray)
    }
    
    func actionBarDidRequestDelete(_ actionBar: ActionBarView) {
        gridView(gridView, didDeleteItems: selectedItems)
    }
    
    func actionBarDidRequestZip(_ actionBar: ActionBarView) {
        let selectedItemsArray = items.filter { selectedItems.contains($0.id) }
        zipItems(selectedItemsArray)
    }
    
    func actionBarDidRequestSelectAll(_ actionBar: ActionBarView) {
        selectAllItems()
    }
    
    func actionBarDidRequestSort(_ actionBar: ActionBarView, by sortType: SortType) {
        switch sortType {
        case .nameAscending:
            items.sort { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
        case .nameDescending:
            items.sort { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedDescending }
        case .dateNewest:
            items.sort { $0.createdAt > $1.createdAt }
        case .dateOldest:
            items.sort { $0.createdAt < $1.createdAt }
        }
        gridView.reloadData(with: items)
    }
    
    // MARK: - ZIP Implementation
    
    private func zipItems(_ items: [ShelfItem]) {
        guard !items.isEmpty else { return }
        
        // Collect file URLs
        var fileURLs: [URL] = []
        let storageDir = try? FileManager.default.shelfStorageDirectory()
        
        for item in items {
            if let path = item.payloadPath, let dir = storageDir {
                let fileURL = dir.appendingPathComponent(path)
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    fileURLs.append(fileURL)
                }
            }
        }
        
        guard !fileURLs.isEmpty else { return }
        
        // Create ZIP file name
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        let zipName = "FloatingShelf_\(timestamp).zip"
        
        // Save to Downloads
        let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let zipURL = downloadsURL.appendingPathComponent(zipName)
        
        // Create ZIP using shell command
        let filePaths = fileURLs.map { $0.path }.joined(separator: "\" \"")
        let command = "cd \"\(storageDir!.path)\" && zip -j \"\(zipURL.path)\" \"\(filePaths)\""
        
        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments = ["-c", command]
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                // Show success notification
                let notification = NSUserNotification()
                notification.title = "ZIP Created"
                notification.informativeText = "Saved to Downloads: \(zipName)"
                NSUserNotificationCenter.default.deliver(notification)
                
                // Reveal in Finder
                NSWorkspace.shared.selectFile(zipURL.path, inFileViewerRootedAtPath: "")
            }
        } catch {
            print("ZIP creation failed: \(error)")
        }
    }
    
    private func shareItems(_ items: [ShelfItem]) {
        var sharingItems: [Any] = []
        
        for item in items {
            switch item.kind {
            case .file, .promisedFile:
                if let path = item.payloadPath {
                    let storageDir = try? FileManager.default.shelfStorageDirectory()
                    let fileURL = storageDir?.appendingPathComponent(path)
                    if let url = fileURL {
                        sharingItems.append(url)
                    }
                }
            case .image:
                if let path = item.payloadPath {
                    let storageDir = try? FileManager.default.shelfStorageDirectory()
                    let fileURL = storageDir?.appendingPathComponent(path)
                    if let url = fileURL, let image = NSImage(contentsOf: url) {
                        sharingItems.append(image)
                    }
                }
            case .text, .url:
                sharingItems.append(item.displayName)
            }
        }
        
        guard !sharingItems.isEmpty else { return }
        
        let sharingPicker = NSSharingServicePicker(items: sharingItems)
        if let button = actionBar.shareButton {
            sharingPicker.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
    
    private func airDropItems(_ items: [ShelfItem]) {
        var sharingItems: [URL] = []
        
        for item in items {
            if let path = item.payloadPath {
                if let storageDir = try? FileManager.default.shelfStorageDirectory() {
                    let fileURL = storageDir.appendingPathComponent(path)
                    if FileManager.default.fileExists(atPath: fileURL.path) {
                        sharingItems.append(fileURL)
                    }
                }
            }
        }
        
        guard !sharingItems.isEmpty else {
            let alert = NSAlert()
            alert.messageText = "No files to share"
            alert.informativeText = "Select files to share via AirDrop."
            alert.runModal()
            return
        }
        
        // Use AirDrop service directly
        if let airDropService = NSSharingService(named: .sendViaAirDrop) {
            if airDropService.canPerform(withItems: sharingItems) {
                airDropService.perform(withItems: sharingItems)
            } else {
                let alert = NSAlert()
                alert.messageText = "AirDrop Unavailable"
                alert.informativeText = "Please enable AirDrop in Control Center or System Settings."
                alert.runModal()
            }
        }
    }
    
    private func copyItems(_ items: [ShelfItem]) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        var urls: [URL] = []
        var strings: [String] = []
        
        for item in items {
            switch item.kind {
            case .file, .promisedFile:
                if let path = item.payloadPath {
                    let storageDir = try? FileManager.default.shelfStorageDirectory()
                    if let fileURL = storageDir?.appendingPathComponent(path) {
                        urls.append(fileURL)
                    }
                }
            case .text, .url:
                strings.append(item.displayName)
            case .image:
                if let path = item.payloadPath {
                    let storageDir = try? FileManager.default.shelfStorageDirectory()
                    if let fileURL = storageDir?.appendingPathComponent(path) {
                        urls.append(fileURL)
                    }
                }
            }
        }
        
        var objects: [NSPasteboardWriting] = []
        if !urls.isEmpty {
            objects.append(contentsOf: urls as [NSPasteboardWriting])
        }
        if !strings.isEmpty {
            objects.append(strings.joined(separator: "\n") as NSPasteboardWriting)
        }
        
        pasteboard.writeObjects(objects)
    }
    
    private func saveItems(_ items: [ShelfItem]) {
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.message = "Choose a location to save items"
        savePanel.prompt = "Save"
        
        savePanel.begin { [weak self] response in
            guard response == .OK, let destinationURL = savePanel.url else { return }
            self?.performSave(items, to: destinationURL)
        }
    }
    
    private func performSave(_ items: [ShelfItem], to destinationURL: URL) {
        do {
            let storageDir = try FileManager.default.shelfStorageDirectory()
            
            for item in items {
                if let path = item.payloadPath {
                    let sourceURL = storageDir.appendingPathComponent(path)
                    let targetURL = destinationURL.appendingPathComponent(item.displayName)
                    try FileManager.default.copyItem(at: sourceURL, to: targetURL)
                }
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = "Save Failed"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.runModal()
        }
    }
}

// MARK: - DropView

/// Custom view that implements NSDraggingDestination
class DropView: NSView {
    
    var dropReceiver: DropReceiver?
    var isDragging: Bool = false  // Track if a drag operation is active
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        isDragging = true
        print("[DropView] draggingEntered - isDragging set to true")
        let result = dropReceiver?.draggingEntered(sender) ?? []
        return result
    }
    
    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return dropReceiver?.draggingUpdated(sender) ?? []
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        isDragging = false
        print("[DropView] draggingExited - isDragging set to false")
        dropReceiver?.draggingExited(sender)
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        print("[DropView] performDragOperation called")
        let result = dropReceiver?.performDragOperation(sender) ?? false
        isDragging = false
        print("[DropView] performDragOperation completed - isDragging set to false")
        return result
    }
}

// MARK: - QLPreviewPanel DataSource & Delegate

extension ShelfViewController: QLPreviewPanelDataSource, QLPreviewPanelDelegate {
    
    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        return selectedItems.count
    }
    
    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> (any QLPreviewItem)! {
        let selectedArray = items.filter { selectedItems.contains($0.id) }
        guard index < selectedArray.count else { return nil }
        
        let item = selectedArray[index]
        
        // Get file URL
        if let payloadPath = item.payloadPath {
            do {
                let storageDir = try FileManager.default.shelfStorageDirectory()
                let fileURL = storageDir.appendingPathComponent(payloadPath)
                return fileURL as NSURL
            } catch {
                return nil
            }
        }
        
        return nil
    }
}

// MARK: - Draggable Title View

class DraggableTitleView: NSView {
    
    override var mouseDownCanMoveWindow: Bool {
        return false
    }
    
    override func mouseDown(with event: NSEvent) {
        // Start tracking drag
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard let window = window else { return }
        
        // Use delta for smoother movement
        var origin = window.frame.origin
        origin.x += event.deltaX
        origin.y -= event.deltaY  // Y is inverted in screen coordinates
        window.setFrameOrigin(origin)
    }
}

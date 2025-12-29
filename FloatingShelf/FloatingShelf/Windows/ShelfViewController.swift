//
//  ShelfViewController.swift
//  FloatingShelf
//

import Cocoa

class ShelfViewController: NSViewController {
    
    private var shelf: Shelf
    private var gridView: ShelfGridView!
    private var actionBar: ActionBarView!
    private var dropReceiver: DropReceiver!
    
    private var items: [ShelfItem] = []
    private var selectedItems: Set<UUID> = []
    
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
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        // Custom title bar for borderless window
        let titleBar = createCustomTitleBar()
        titleBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleBar)
        
        // Grid view for items
        gridView = ShelfGridView()
        gridView.translatesAutoresizingMaskIntoConstraints = false
        gridView.delegate = self
        view.addSubview(gridView)
        
        // Action bar at bottom
        actionBar = ActionBarView()
        actionBar.translatesAutoresizingMaskIntoConstraints = false
        actionBar.delegate = self
        view.addSubview(actionBar)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // Title bar at top
            titleBar.topAnchor.constraint(equalTo: view.topAnchor),
            titleBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            titleBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            titleBar.heightAnchor.constraint(equalToConstant: 28),
            
            // Grid view
            gridView.topAnchor.constraint(equalTo: titleBar.bottomAnchor),
            gridView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gridView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gridView.bottomAnchor.constraint(equalTo: actionBar.topAnchor),
            
            actionBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            actionBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            actionBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            actionBar.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func createCustomTitleBar() -> NSView {
        let titleBar = NSView()
        titleBar.wantsLayer = true
        titleBar.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.95).cgColor
        
        // Close button
        let closeButton = NSButton()
        closeButton.bezelStyle = .circular
        closeButton.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "Close")
        closeButton.isBordered = false
        closeButton.target = self
        closeButton.action = #selector(closeWindow)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        titleBar.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.leadingAnchor.constraint(equalTo: titleBar.leadingAnchor, constant: 8),
            closeButton.centerYAnchor.constraint(equalTo: titleBar.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 16),
            closeButton.heightAnchor.constraint(equalToConstant: 16)
        ])
        
        return titleBar
    }
    
    @objc private func closeWindow() {
        view.window?.close()
    }
    
    // MARK: - Data
    
    private func loadItems() {
        items = ItemStore.shared.fetchItems(for: shelf.id)
        gridView.reloadData(with: items)
        updateActionBarState()
    }
    
    private func updateActionBarState() {
        actionBar.setEnabled(!selectedItems.isEmpty)
    }
}

// MARK: - DropReceiverDelegate

extension ShelfViewController: DropReceiverDelegate {
    func dropReceiver(_ receiver: DropReceiver, didReceiveItems newItems: [ShelfItem]) {
        items.append(contentsOf: newItems)
        gridView.reloadData(with: items)
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
    
    func actionBarDidRequestCopy(_ actionBar: ActionBarView) {
        let selectedItemsArray = items.filter { selectedItems.contains($0.id) }
        copyItems(selectedItemsArray)
    }
    
    func actionBarDidRequestSave(_ actionBar: ActionBarView) {
        let selectedItemsArray = items.filter { selectedItems.contains($0.id) }
        saveItems(selectedItemsArray)
    }
    
    func actionBarDidRequestDelete(_ actionBar: ActionBarView) {
        gridView(gridView, didDeleteItems: selectedItems)
    }
    
    // MARK: - Actions Implementation
    
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
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return dropReceiver?.draggingEntered(sender) ?? []
    }
    
    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return dropReceiver?.draggingUpdated(sender) ?? []
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return dropReceiver?.performDragOperation(sender) ?? false
    }
}


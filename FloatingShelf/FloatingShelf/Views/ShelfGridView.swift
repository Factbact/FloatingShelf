//
//  ShelfGridView.swift
//  FloatingShelf
//

import Cocoa

protocol ShelfGridViewDelegate: AnyObject {
    func gridView(_ gridView: ShelfGridView, didSelectItems itemIds: Set<UUID>)
    func gridView(_ gridView: ShelfGridView, didDeleteItems itemIds: Set<UUID>)
}

class ShelfGridView: NSView {
    
    weak var delegate: ShelfGridViewDelegate?
    
    private var items: [ShelfItem] = []
    private var selectedItems: Set<UUID> = []
    
    private let scrollView = NSScrollView()
    private let collectionView = NSCollectionView()
    private let emptyLabel = NSTextField(labelWithString: "Drop files here")
    
    // Drag & Drop
    var dropReceiver: DropReceiver?
    
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
        layer?.backgroundColor = NSColor.clear.cgColor  // Transparent for vibrancy
        
        // Empty state label
        emptyLabel.alignment = .center
        emptyLabel.textColor = .secondaryLabelColor
        emptyLabel.font = NSFont.systemFont(ofSize: 16)
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(emptyLabel)
        
        // Collection view setup - compact thumbnails
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 80, height: 90)
        flowLayout.minimumInteritemSpacing = 10
        flowLayout.minimumLineSpacing = 10
        flowLayout.sectionInset = NSEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        collectionView.collectionViewLayout = flowLayout
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isSelectable = true
        collectionView.allowsMultipleSelection = true
        collectionView.backgroundColors = [.clear]
        
        // Register item type
        collectionView.register(ShelfItemCollectionViewItem.self, 
                               forItemWithIdentifier: NSUserInterfaceItemIdentifier("ShelfItemCell"))
        
        // Scroll view
        scrollView.documentView = collectionView
        scrollView.hasVerticalScroller = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        
        // Layout
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            emptyLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        updateEmptyState()
    }
    
    override var acceptsFirstResponder: Bool { true }
    
    func reloadData(with items: [ShelfItem]) {
        self.items = items
        collectionView.reloadData()
        updateEmptyState()
    }
    
    private func updateEmptyState() {
        emptyLabel.isHidden = !items.isEmpty
        scrollView.isHidden = items.isEmpty
    }
    
    // MARK: - Selection
    
    private func updateSelection() {
        let indexPaths = collectionView.selectionIndexPaths
        selectedItems = Set(indexPaths.compactMap { items[safe: $0.item]?.id })
        delegate?.gridView(self, didSelectItems: selectedItems)
    }
    
    @objc func deleteSelectedItems() {
        guard !selectedItems.isEmpty else { return }
        delegate?.gridView(self, didDeleteItems: selectedItems)
    }
    
    func registerDropTypes(_ types: [NSPasteboard.PasteboardType]) {
        registerForDraggedTypes(types)
        scrollView.registerForDraggedTypes(types)
        collectionView.registerForDraggedTypes(types)
    }
    
    // MARK: - Dragging Destination
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return dropReceiver?.draggingEntered(sender) ?? []
    }
    
    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return dropReceiver?.draggingUpdated(sender) ?? []
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return dropReceiver?.performDragOperation(sender) ?? false
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        dropReceiver?.draggingExited(sender)
    }
    
    // MARK: - Key Events
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 49 { // Space bar = Quick Look
            nextResponder?.keyDown(with: event)
        } else if event.keyCode == 51 { // Delete key
            deleteSelectedItems()
        } else {
            super.keyDown(with: event)
        }
    }
}

// MARK: - NSCollectionViewDataSource

extension ShelfGridView: NSCollectionViewDataSource {
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier("ShelfItemCell"), 
                                          for: indexPath) as! ShelfItemCollectionViewItem
        
        if let shelfItem = items[safe: indexPath.item] {
            item.configure(with: shelfItem)
        }
        
        return item
    }
}

// MARK: - NSCollectionViewDelegate

extension ShelfGridView: NSCollectionViewDelegate {
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        updateSelection()
    }
    
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        updateSelection()
    }
}

// MARK: - Collection View Item

class ShelfItemCollectionViewItem: NSCollectionViewItem {
    
    private var itemView: ShelfItemView?
    
    override func loadView() {
        let view = ShelfItemView(frame: NSRect(x: 0, y: 0, width: 100, height: 120))
        self.view = view
        self.itemView = view
    }
    
    func configure(with item: ShelfItem) {
        itemView?.item = item
    }
    
    override var isSelected: Bool {
        didSet {
            itemView?.isItemSelected = isSelected
        }
    }
}

// MARK: - Array Extension

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

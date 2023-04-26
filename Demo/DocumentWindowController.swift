import Cocoa

class DocumentWindowController: NSWindowController, WindowControllerWithCascading {
		
	var isWindowFrameSavingAllowed: Bool = true
	var discardWindowFrameAutosaveWhenLastWindowClosed: Bool = false
	var centerWindowPositionWhenFirstWindowOpening: Bool = true
	var windowFrameAutosaveName_alt: String = "Document"
	
	static var previousTopLeft: NSPoint?
	
	func targetWindows() -> [CascadedWindow] {
		// If you use NSDocument based window architecture
		NSDocumentController.shared.allCascadedWindows()
	}
	
	func initialWindowSize() -> NSSize? {
		if let screen = window?.screen {
			let scale = 0.3
			let screenSize = screen.visibleFrame.size
			let size = NSSize(width: CGFloat(Int(screenSize.width * scale)),
							  height: CGFloat(Int(screenSize.height * scale)))
			return size
		}
		return nil
	}
	
	
	// MARK: -
	
	override func windowDidLoad() {
		super.windowDidLoad()
		
		// Setup window cascading
		setupWindowCascading()
	}
	
}

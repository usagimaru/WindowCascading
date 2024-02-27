import Cocoa

class DocumentWindowController: NSWindowController, WindowControllerWithCascading {
	
	/* ================== WindowControllerWithCascading >> ================== */
	
	var usesPersistentCascadableWindowFrameCache: Bool = true
	var discardsPersistentCascadableWindowFrameCacheWhenLastClosed: Bool = false
	var resetsFrameWhenCascadableWindowRestored: Bool = true
	var centerCascadableWindowPositionWhenFirstOpening: Bool = false
	var cascadableWindowFrameAutosaveName: String = "Document"
	
	static var previousTopLeft: NSPoint?
	
	func targetCascadableWindows() -> [CascadableWindow] {
		// You must manage target windows
		// This line is valid if you are using the NSDocument-based window architecture
		NSDocumentController.shared.cascadableWindows()
	}
	
	func defaultCascadableWindowSize() -> NSSize? {
		if let screen = window?.screen {
			let scale = 0.3
			let screenSize = screen.visibleFrame.size
			let size = NSSize(width: CGFloat(Int(screenSize.width * scale)),
							  height: CGFloat(Int(screenSize.height * scale)))
			
			return size
		}
		return nil
	}
	
	/* ================== << WindowControllerWithCascading ================== */
	
	
	// MARK: -
	
	override func windowDidLoad() {
		super.windowDidLoad()
		
		// Setup window cascading (for NSWindowRestoration)
		prepareForWindowRestoring()
	}
	
	override func showWindow(_ sender: Any?) {
		super.showWindow(sender)
		
		// Setup window cascading
		setupWindowCascading()
	}
	
}

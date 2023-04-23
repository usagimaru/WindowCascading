import Cocoa

class DocumentWindowController: NSWindowController, DocumentWindowControllerWithCascading {
	
	var windowFrameSavingAllowed: Bool = true
	var discardWindowFrameAutosaveWhenLastWindowClosed: Bool = false
	var centerWindowPositionWhenFirstWindowOpening: Bool = true
	var windowFrameAutosaveName_alt: String = "Document"
	
	static var previousTopLeft: NSPoint?
	
	func documentController() -> NSDocumentController {
		AppDelegate.sharedDocumentController
	}
	
	func initialWindowSize() -> NSSize? {
		if let screen = self.window?.screen {
			let scale = 0.3
			let screenSize = screen.visibleFrame.size
			let size = NSSize(width: CGFloat(Int(screenSize.width * scale)),
							  height: CGFloat(Int(screenSize.height * scale)))
			return size
		}
		return nil
	}
	
	
	// MARK: -
	
	override func windowWillLoad() {
		super.windowWillLoad()
	}
	
	override func windowDidLoad() {
		super.windowDidLoad()
		// Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
		
		// Setup window cascading
		setupWindowCascading()
	}
	
}

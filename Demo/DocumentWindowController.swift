import Cocoa

class DocumentWindowController: CascadableNSWindowController {
	
	/* ================== WindowControllerWithCascading >> ================== */
	
	override var usesPersistentCascadableWindowFrame: Bool {
		true
	}
	override var discardsPersistentCascadableWindowFrameWhenLastClosed: Bool {
		false
	}
	override var resetsFrameWhenCascadableWindowRestored: Bool {
		true
	}
	override var centerCascadableWindowPositionWhenFirstOpening: Bool {
		false
	}
	override var cascadableWindowFrameAutosaveName: String {
		"Document"
	}
	
	override func targetCascadableWindows() -> [CascadableWindow] {
		// You must manage target windows
		// This line is valid if you are using the NSDocument-based window architecture
		NSDocumentController.shared.cascadableWindows()
	}
	
	override func defaultCascadableWindowSize() -> NSSize? {
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
	}
	
	override func showWindow(_ sender: Any?) {
		super.showWindow(sender)
	}
	
}

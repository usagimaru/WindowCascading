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
		"DocumentWindow"
	}
	
	override func targetCascadableWindows() -> [CascadableWindow] {
		// You must manage target windows
		// This line is valid if you are using the NSDocument-based window architecture
		NSDocumentController.shared.cascadableWindows()
	}
	
	/* ================== << WindowControllerWithCascading ================== */
	
}

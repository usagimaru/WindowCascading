#if os(macOS)
import Cocoa

open class CascadableNSWindow: NSWindow, CascadableWindow {}

open class CascadableNSWindowController: NSWindowController, WindowControllerWithCascading {
	
	/* ================== WindowControllerWithCascading >> ================== */
	
	open var usesPersistentCascadableWindowFrame: Bool {
		true
	}
	open var discardsPersistentCascadableWindowFrameWhenLastClosed: Bool {
		false
	}
	open var resetsFrameWhenCascadableWindowRestored: Bool {
		true
	}
	open var centerCascadableWindowPositionWhenFirstOpening: Bool {
		false
	}
	open var cascadableWindowFrameAutosaveName: String {
		"Document"
	}
	
	public static var previousTopLeft: NSPoint?
	
	open func targetCascadableWindows() -> [CascadableWindow] {
		// You must manage target windows on subclass
		[]
	}
	
	open func defaultCascadableWindowSize() -> NSSize? {
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

	open override func windowDidLoad() {
		super.windowDidLoad()
		
		// Setup window cascading (for NSWindowRestoration)
		prepareForWindowRestoring()
	}
	
	open override func showWindow(_ sender: Any?) {
		super.showWindow(sender)
		
		// Setup window cascading
		setupWindowCascading()
	}

}

#endif

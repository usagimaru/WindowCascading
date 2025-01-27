#if os(macOS)
import Cocoa

public protocol CascadableWindow: NSWindow {}

public protocol WindowControllerWithCascading: NSWindowController {
	
	/// To true, save the window frame to UserDefaults.
	var usesPersistentCascadableWindowFrame: Bool { get }
	/// To true, discard the last window frame info from the UserDefaults when all managed windows are closed.
	var discardsPersistentCascadableWindowFrameWhenLastClosed: Bool { get }
	/// To true, auto reset the window frame when run the NSWindowRestoration by the system
	var resetsFrameWhenCascadableWindowRestored: Bool { get }
	
	/// To true, set the first window position to center of the screen.
	var centerCascadableWindowPositionWhenFirstOpening: Bool { get }
	/// Alternative AutosaveName (do not include the word "window" because to work around a bug in AppKit)
	var cascadableWindowFrameAutosaveName: String { get }
	
	static var previousTopLeft: NSPoint? { get set }
	
	/// Return your managing windows
	func targetCascadableWindows() -> [CascadableWindow]
	
	/// Setup the initial window size
	func defaultCascadableWindowSize() -> NSSize?
	
	/*
	 ## Paste the following code into your WindowController implementation or subclassing from CascadableNSWindowController:
	 
	 import WindowCascading
	 
	 var usesPersistentCascadableWindowFrame: Bool {
		true
	 }
	 var discardsPersistentCascadableWindowFrameWhenLastClosed: Bool {
		false
	 }
	 var resetsFrameWhenCascadableWindowRestored: Bool {
		true
	 }
	 var centerCascadableWindowPositionWhenFirstOpening: Bool {
		false
	 }
	 var cascadableWindowFrameAutosaveName: String {
		"Document"
	 }
	 
	 static var previousTopLeft: NSPoint?
	 
	 func targetCascadableWindows() -> [CascadableWindow] {
		 // You must manage target windows
		 // This line is valid if you are using the NSDocument-based window architecture
		 NSDocumentController.shared.cascadableWindows()
	 }
	 
	 func defaultCascadableWindowSize() -> NSSize? {
		// Return the default window size if necessary
		nil
	 }
	 
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
	 
	 ------------------------------------------------------
	 
	 ## Usage:
	 - Make your subclass of NSWindow to conform to `CascadableWindow` protocol.
	 - Make your subclass of NSWindowController to conform to `WindowControllerWithCascading` protocol or subclassing it from `CascadableNSWindowController`.
	 - Implement `targetCascadableWindows()` in your WindowController.
	 - Call `prepareForWindowRestoring()` method in `windowDidLoad()` of your WindowController implementation.
	 - Call `setupWindowCascading()` method in `showWindow(_:)` of your WindowController implementation.
	 + Implement `defaultCascadableWindowSize()` in your WindowController if necessary.
	 	 
	 
	 ## Note 1:
	 It seems that calling `self.shouldCascadeWindows = true` with windowDidLoad() is too late:
	 https://stackoverflow.com/questions/35827239/document-based-app-autosave-with-storyboards/43726191
	 
	 However, this is true by default, so there is no need to mention it if you are cascading.
	 
	 
	 ## Note 2:
	 - It seems that cascading does not work properly when "window" is included in AutosaveName text. Probably a bug in AppKit.
	 - To begin with, it seems that using NSWindowController.windowFrameAutosaveName causes the window to be out of position?
	 
	 So, based on the reference information, I decided to adopt a policy to achieve cascading and frame saving without using NSWindowController.windowFrameAutosaveName.
	 This is handled by directly reading and writing UserDefaults with "NSWindow Frame FOOBAR" as the key.
	 
	 */
}

public extension CascadableWindow {
	
	/// Get window’s top-left coordinate
	var topLeft: NSPoint {
		NSPoint(x: frame.minX, y: frame.maxY)
	}
	
	func frame(with topLeft: NSPoint, size: NSSize) -> NSRect {
		NSRect(x: topLeft.x,
			   y: topLeft.y - size.height,
			   width: size.width,
			   height: size.height)
	}
	
	/// Window cascading method with modified logic
	func cascade(from topLeftPoint: NSPoint) -> NSPoint {
		validateWindowFrameForCascading(cascadeTopLeft(from: topLeftPoint))
	}
	
	internal func validateWindowFrameForCascading(_ topLeftPoint: NSPoint) -> NSPoint {
		let previousFrame = frame
		
		// Tentatively calculated top-left coordinates and window frame
		let tempTopLeft = topLeftPoint
		let tempFrame = frame(with: tempTopLeft, size: previousFrame.size)
		
		guard let screenFrame = screen?.visibleFrame
		else { return tempTopLeft }
		
		if screenFrame.contains(tempFrame) {
			return tempTopLeft
		}
		
		// If window extends beyond bottom of screen, set Y to top of the screen
		var newTopLeft = tempTopLeft
		if tempFrame.minY < screenFrame.minY {
			newTopLeft.y = screenFrame.maxY
		}
		
		// If window extends beyond left of screen, set X to minX of the screen frame
		if tempFrame.minX < screenFrame.minX {
			newTopLeft.x = screenFrame.minX
		}
		
		// If window extends beyond right of screen, set X to minX of the screen frame and add the diff of both
		if tempFrame.maxX > screenFrame.maxX {
			let diff = tempFrame.maxX - screenFrame.maxX
			newTopLeft.x = screenFrame.minX + diff
		}
		
		// If the window size matches the valid screen size, set X to minX of the screen frame
		if tempFrame.size == screenFrame.size {
			newTopLeft.x = screenFrame.minX
		}
		
		return newTopLeft
	}
	
	internal func validateWindowFrameToFitOnScreen(_ topLeftPoint: NSPoint) -> NSPoint {
		let previousFrame = frame
		
		// Tentatively calculated top-left coordinates and window frame
		let tempTopLeft = topLeftPoint
		let tempFrame = frame(with: tempTopLeft, size: previousFrame.size)
		
		guard let screenFrame = screen?.visibleFrame
		else { return tempTopLeft }
		
		if screenFrame.contains(tempFrame) {
			return tempTopLeft
		}
		
		// If window extends beyond bottom of screen, set Y to top of the screen
		var newTopLeft = tempTopLeft
		if tempFrame.minY < screenFrame.minY {
			newTopLeft.y = screenFrame.maxY
		}
		
		// If window extends beyond left of screen, set X to minX of the screen frame
		if tempFrame.minX < screenFrame.minX {
			newTopLeft.x = screenFrame.minX
		}
		
		// If window extends beyond right of screen, set X to maxX minus window width
		if tempFrame.maxX > screenFrame.maxX {
			newTopLeft.x = screenFrame.maxX - previousFrame.width
		}
		
		// If the window size matches the valid screen size, set X to minX of the screen frame
		if tempFrame.size == screenFrame.size {
			newTopLeft.x = screenFrame.minX
		}
		
		return newTopLeft
	}
	
}

public extension WindowControllerWithCascading {
	
	var cascadableWindow: CascadableWindow? {
		window as? CascadableWindow
	}
	
	/// Start point for NSWindowRestoration, call this in NSWindowController.windowDidLoad() after super’s called.
	func prepareForWindowRestoring() {
		if resetsFrameWhenCascadableWindowRestored {
			NotificationCenter.default.removeObserver(self, name: NSApplication.didFinishRestoringWindowsNotification, object: NSApp)
			
			// When restoring a window does not call showWindow(_:) and makeKeyAndOrderFront(_:) by the system. Instead, it detects with `NSApplication.didFinishRestoringWindowsNotification` notification.
			NotificationCenter.default.addObserver(forName: NSApplication.didFinishRestoringWindowsNotification, object: NSApp, queue: .main) { notif in
				self.setupObserversForCascading()
				self.resetCascadableWindowFrame()
			}
		}
	}
	
	/// Start point for standard window displaying, call this in NSWindowController.showWindow() after super’s called.
	func setupWindowCascading() {
		setupObserversForCascading()
		resetCascadableWindowFrame()
	}
	
	
	// MARK: - Autosave
	
	private func cascadableWindowFrameAutosaveName_() -> String {
		// Not certain if this process is effective.
		cascadableWindowFrameAutosaveName.replacingOccurrences(of: "window", with: "w.i.n.d.o.w", options: .caseInsensitive)
	}
	
	/// Raw key string for `windowFrameAutosaveName`
	var persistentWindowFrameInfoKey: String {
		"NSWindow Frame \(cascadableWindowFrameAutosaveName_())"
	}
	
	/// Restore the saved window frame in string format
	func persistableWindowFrameDescriptor() -> NSWindow.PersistableFrameDescriptor? {
		// Ref: https://github.com/coteditor/CotEditor/blob/f9c140ab08fd6acd24ebe65fd01420f29ba367fd/CotEditor/Sources/DocumentWindowController.swift
		UserDefaults.standard.string(forKey: persistentWindowFrameInfoKey)
	}
	
	func clearPersistentWindowFrameInfo() {
		UserDefaults.standard.removeObject(forKey: persistentWindowFrameInfoKey)
	}
	
	func saveWindowFrame() {
		guard isWindowLoaded,
			  let cascadableWindow
		else { return }
		cascadableWindow.saveFrame(usingName: cascadableWindowFrameAutosaveName_())
	}
	
	
	// MARK: -
	
	/// Set window frame
	func resetCascadableWindowFrame() {
		// Cascading and frame saving without NSWindowController.windowFrameAutosaveName
		// Ref: https://github.com/jessegrosjean/window.autosaveName/blob/master/Test/WindowController.m
		
		guard let cascadableWindow,
			  let screen = cascadableWindow.screen
		else { return }
		
		if targetCascadableWindows().count == 1 {
			// [First window]
			
			if let windowFrameDesc = persistableWindowFrameDescriptor() {
				// Restore window frame if auto saved
				cascadableWindow.setFrame(from: windowFrameDesc)
				
				if centerCascadableWindowPositionWhenFirstOpening {
					cascadableWindow.center()
				}
				else {
					let topLeft = cascadableWindow.validateWindowFrameToFitOnScreen(cascadableWindow.topLeft)
					cascadableWindow.setFrameTopLeftPoint(topLeft)
				}
			}
			else {
				// Set initial window size and centering
				let defaultCascadableWindowSize = defaultCascadableWindowSize() ?? _defaultCascadableWindowSize(screen)
				cascadableWindow.setContentSize(defaultCascadableWindowSize)
				cascadableWindow.center()
			}
			
			Self.previousTopLeft = cascadableWindow.topLeft
		}
		else {
			// [Other windows]
			
			// Restore window frame
			cascadableWindow.setFrameUsingName(cascadableWindowFrameAutosaveName_())
			
			// Cascade and set position
			let topLeft = cascadableWindow.topLeft
			let nextTopLeft = cascadableWindow.cascade(from: Self.previousTopLeft ?? topLeft)
			
			cascadableWindow.setFrameTopLeftPoint(nextTopLeft)
			
			Self.previousTopLeft = nextTopLeft
		}
	}
	
	/// Setup event triggers
	func setupObserversForCascading() {
		removeObserversForCascading()
		
		@discardableResult
		func observe(_ name: Notification.Name, handler: @escaping (_ notification: Notification) -> Void) -> NSObjectProtocol {
			NotificationCenter.default.addObserver(forName: name,
												   object: cascadableWindow,
												   queue: .main,
												   using: handler)
		}
		
		observe(NSWindow.didBecomeMainNotification) { notification in
			guard self.isWindowLoaded,
				  let window = self.cascadableWindow,
				  (notification.object as? CascadableWindow) === window,
				  self.usesPersistentCascadableWindowFrame else
			{ return }
			
			self.saveWindowFrame()
		}
		
		observe(NSWindow.didBecomeKeyNotification) { notification in
			guard self.isWindowLoaded,
				  let window = self.cascadableWindow,
				  (notification.object as? CascadableWindow) === window,
				  self.usesPersistentCascadableWindowFrame else
			{ return }
			
			Self.previousTopLeft = window.topLeft
		}
		
		observe(NSWindow.didResizeNotification) { notification in
			guard self.isWindowLoaded,
				  let window = self.cascadableWindow,
				  (notification.object as? CascadableWindow) === window,
				  self.usesPersistentCascadableWindowFrame else
			{ return }
			
			self.saveWindowFrame()
			Self.previousTopLeft = window.topLeft
		}
		
		observe(NSWindow.didMoveNotification) { notification in
			guard self.isWindowLoaded,
				  let window = self.cascadableWindow,
				  (notification.object as? CascadableWindow) === window,
				  window.isKeyWindow,
				  self.usesPersistentCascadableWindowFrame else
			{ return }
			
			self.saveWindowFrame()
			
			if window.isMainWindow {
				Self.previousTopLeft = window.topLeft
			}
		}
		
		observe(NSWindow.willCloseNotification) { notification in
			// Discard window size cache if target window count would be zero
			if self.discardsPersistentCascadableWindowFrameWhenLastClosed,
			   (notification.object as? CascadableWindow) === self.cascadableWindow,
			   self.targetCascadableWindows().count == 1 {
				self.clearPersistentWindowFrameInfo()
			}
		}
	}
	
	/// Remove event triggers
	func removeObserversForCascading() {
		func removeObserver(_ name: NSNotification.Name) {
			NotificationCenter.default.removeObserver(self, name: name, object: cascadableWindow)
		}
		
		removeObserver(NSWindow.didBecomeMainNotification)
		removeObserver(NSWindow.didBecomeKeyNotification)
		removeObserver(NSWindow.didResizeNotification)
		removeObserver(NSWindow.didMoveNotification)
		removeObserver(NSWindow.willCloseNotification)
	}
	
	/// Default imp of `defaultCascadableWindowSize()`
	private func _defaultCascadableWindowSize(_ screen: NSScreen) -> NSSize {
		let screenSize = screen.visibleFrame.size
		let size = NSSize(width: CGFloat(Int(screenSize.width * 0.75)),
						  height: CGFloat(Int(screenSize.height * 0.75)))
		return size
	}
	
}

public extension NSDocumentController {
	
	/// Get the array of cascadable windows if you are using the NSDocument-based window architecture
	func cascadableWindows() -> [CascadableWindow] {
		documents.compactMap { doc in
			doc.windowControllers.compactMap { wc in
				wc.window as? CascadableWindow
			}
		}.flatMap { $0 }
	}
	
}

#endif

#if os(macOS)
import Cocoa

public protocol DocumentWindowCascading: NSWindow {}

public protocol DocumentWindowControllerWithCascading: NSWindowController {
	
	/// To true, save the window frame to user defaults.
	var windowFrameSavingAllowed: Bool {get set}
	/// To true, discard the last window frame info from the UserDefaults when all document windows are closed.
	var discardWindowFrameAutosaveWhenLastWindowClosed: Bool {get set}
	/// To true, set the first window position to center of the screen.
	var centerWindowPositionWhenFirstWindowOpening: Bool {get set}
	/// Autosave Name
	var windowFrameAutosaveName_alt: String {get}
	
	static var previousTopLeft: NSPoint? {get set}
	
	/// Return your DocumentController
	func documentController() -> NSDocumentController
	
	/// Setup the initial window size
	func initialWindowSize() -> NSSize?
	
	/*
	 ## Paste the following code into your WindowController implementation:
	 
	 var windowFrameSavingAllowed: Bool = true
	 var discardWindowFrameAutosaveWhenLastWindowClosed: Bool = false
	 var centerWindowPositionWhenFirstWindowOpening: Bool = true
	 var windowFrameAutosaveName_alt: String = "Document"
	 
	 static var previousTopLeft: NSPoint?
	 
	 func documentController() -> NSDocumentController {
		NSDocumentController.shared
	 }
	 
	 func initialWindowSize() -> NSSize? {
		nil
	 }
	 
	 
	 ## Usage:
	 - Make your document window (NSWindow) subclass to conform to `DocumentWindowCascading` protocol.
	 - Make your NSWindowController subclass to conform to `DocumentWindowControllerWithCascading` protocol.
	 - Call `setupWindowCascading()` method in `windowDidLoad()` of your WindowController implementation.
	 + Implement `documentController()` if necessary.
	 + Implement `initialWindowSize()` if necessary.
	 	 
	 
	 ## Note 1:
	 It seems that calling `self.shouldCascadeWindows = true` with windowDidLoad() is too late:
	 https://stackoverflow.com/questions/35827239/document-based-app-autosave-with-storyboards/43726191#43726191
	 
	 However, this is true by default, so there is no need to mention it if you are cascading.
	 
	 
	 ## Note 2:
	 - It seems that cascading does not work properly when "window" text is included in AutosaveName.
	 - To begin with, it seems that using NSWindowController.windowFrameAutosaveName causes the window to be out of position?
	 
	 So, based on the reference information, I decided to adopt a policy to achieve cascading and frame saving without using NSWindowController.windowFrameAutosaveName.
	 This is handled by directly reading and writing UserDefaults with "NSWindow Frame FOOBAR" as the key.
	 
	 */
}

public extension DocumentWindowControllerWithCascading {
	
	func setupWindowCascading() {
		setObserversForCascading()
		resetWindowFrame()
		self.windowFrameSavingAllowed = true
	}
	
	private var persistentWindowFrameInfoKey: String {
		"NSWindow Frame \(self.windowFrameAutosaveName_alt)"
	}
	
	private func _initialWindowSize(_ screen: NSScreen) -> NSSize {
		let screenSize = screen.visibleFrame.size
		let size = NSSize(width: CGFloat(Int(screenSize.width * 0.75)),
						  height: CGFloat(Int(screenSize.height * 0.75)))
		return size
	}
	
	/// Restore the saved window frame in string format
	private func persistableWindowFrameDescriptor() -> NSWindow.PersistableFrameDescriptor? {
		// Ref: https://github.com/coteditor/CotEditor/blob/f9c140ab08fd6acd24ebe65fd01420f29ba367fd/CotEditor/Sources/DocumentWindowController.swift
		UserDefaults.standard.string(forKey: self.persistentWindowFrameInfoKey)
	}
	
	func clearPersistentWindowFrameInfo() {
		UserDefaults.standard.removeObject(forKey: self.persistentWindowFrameInfoKey)
	}
	
	func documentController() -> NSDocumentController {
		NSDocumentController.shared
	}
	
	var documentWindowCascading: DocumentWindowCascading? {
		self.window as? DocumentWindowCascading
	}
	
	func resetWindowFrame() {
		// Cascading and frame saving without NSWindowController.windowFrameAutosaveName
		// Ref: https://github.com/jessegrosjean/window.autosaveName/blob/master/Test/WindowController.m
		
		if let window = self.documentWindowCascading,
		   let screen = window.screen {
			if documentController().allDocumentWindowCascading().count == 0 {
				// [First window]
				
				if let windowFrameDesc = persistableWindowFrameDescriptor() {
					// Restore window frame if auto saved
					window.setFrame(from: windowFrameDesc)
					
					if self.centerWindowPositionWhenFirstWindowOpening {
						window.center()
					}
				}
				else {
					// Set initial window size and centering
					let initialWindowSize = initialWindowSize() ?? _initialWindowSize(screen)
					window.setContentSize(initialWindowSize)
					window.center()
				}
				
				Self.previousTopLeft = window.topLeft
			}
			else {
				// [Other windows]
				
				// Restore window frame
				window.setFrameUsingName(self.windowFrameAutosaveName_alt)
				
				// Cascade and set position
				let topLeft = window.topLeft
				let nextTopLeft = window.cascadeTopLeft(from: Self.previousTopLeft ?? topLeft)
				
				if nextTopLeft.equalTo(topLeft) {
					window.setFrameTopLeftPoint(nextTopLeft)
				}
				else {
					window.setFrameTopLeftPoint(nextTopLeft)
				}
				
				Self.previousTopLeft = nextTopLeft
			}
		}
	}
	
	func removeObserversForCascading() {
		func removeObserver(_ name: NSNotification.Name) {
			NotificationCenter.default.removeObserver(self,
													  name: name,
													  object: self.documentWindowCascading)
		}
		
		removeObserver(NSWindow.didBecomeMainNotification)
		removeObserver(NSWindow.didBecomeKeyNotification)
		removeObserver(NSWindow.didResizeNotification)
		removeObserver(NSWindow.didMoveNotification)
		removeObserver(NSWindow.willCloseNotification)
	}
	
	func setObserversForCascading() {
		removeObserversForCascading()
		
		func observe(_ name: Notification.Name, handler: @escaping (_ notification: Notification) -> Void) {
			NotificationCenter.default.addObserver(forName: name,
												   object: self.documentWindowCascading,
												   queue: .main,
												   using: handler)
		}
		
		observe(NSWindow.didBecomeMainNotification) { notification in
			guard self.isWindowLoaded,
				  let window = self.documentWindowCascading,
				  (notification.object as? DocumentWindowCascading) === window,
				  self.windowFrameSavingAllowed else
			{ return }
			
			window.saveFrame(usingName: self.windowFrameAutosaveName_alt)
		}
		
		observe(NSWindow.didBecomeKeyNotification) { notification in
			guard self.isWindowLoaded,
				  let window = self.documentWindowCascading,
				  (notification.object as? DocumentWindowCascading) === window,
				  self.windowFrameSavingAllowed else
			{ return }
			
			Self.previousTopLeft = window.topLeft
		}
		
		observe(NSWindow.didResizeNotification) { notification in
			guard self.isWindowLoaded,
				  let window = self.documentWindowCascading,
				  (notification.object as? DocumentWindowCascading) === window,
				  self.windowFrameSavingAllowed else
			{ return }
			
			window.saveFrame(usingName: self.windowFrameAutosaveName_alt)
			Self.previousTopLeft = window.topLeft
		}
		
		observe(NSWindow.didMoveNotification) { notification in
			guard self.isWindowLoaded,
				  let window = self.documentWindowCascading,
				  (notification.object as? DocumentWindowCascading) === window,
				  window.isKeyWindow,
				  self.windowFrameSavingAllowed else
			{ return }
			
			window.saveFrame(usingName: self.windowFrameAutosaveName_alt)
			
			if window.isMainWindow {
				Self.previousTopLeft = window.topLeft
			}
		}
		
		observe(NSWindow.willCloseNotification) { notification in
			// 最後のウインドウが閉じる際に、保存したウインドウフレームを削除する
			if self.discardWindowFrameAutosaveWhenLastWindowClosed,
			   (notification.object as? DocumentWindowCascading) === self.documentWindowCascading,
			   self.documentController().allDocumentWindowCascading().count == 1 {
				NSWindow.removeFrame(usingName: self.windowFrameAutosaveName_alt)
			}
		}
	}
	
}

public extension DocumentWindowCascading {
	
	var topLeft: NSPoint {
		NSPoint(x: frame.minX, y: frame.maxY)
	}
	
}

public extension NSDocumentController {
	
	func allDocumentWindowCascading() -> [DocumentWindowCascading] {
		self.documents.map {
			$0.windowControllers.map { wc in
				wc.window as? DocumentWindowCascading
			}
		}.flatMap { $0 }.compactMap { $0 }
	}
	
}

#endif

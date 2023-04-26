# WindowCascading

A protocol extension for NSWindowController that easily adds cascading window feature. This avoids some AppKit buggy behaviours.

<img src="./screenshot.jpg" width=1246>


## First Step

Paste the following code into your WindowController implementation:

```swift
import WindowControllerWithCascading

var isWindowFrameSavingAllowed: Bool = true
var discardWindowFrameAutosaveWhenLastWindowClosed: Bool = false
var centerWindowPositionWhenFirstWindowOpening: Bool = true
var windowFrameAutosaveName_alt: String = "Document"

static var previousTopLeft: NSPoint?

func targetWindows() -> [CascadedWindow] {
	// If you use NSDocument based architecture
	NSDocumentController.shared.allCascadedWindows()
}

func initialWindowSize() -> NSSize? {
	nil
}

```

## Usage

- Make your managed window (NSWindow) subclass to conform to `CascadedWindow` protocol.
- Make your NSWindowController subclass to conform to `WindowControllerWithCascading` protocol.
- Implement `targetWindows()`.
- Implement `initialWindowSize()` if necessary.
- Call `setupWindowCascading()` method in `windowDidLoad()` of your WindowController implementation.


## Customize

- `isWindowFrameSavingAllowed: Bool`
	- Specifies whether the window coordinates after cascading should be saved in UserDefaults.
- `windowFrameAutosaveName_alt: String`
	- Return the unique name for AutosaveName (do not include the string "window" because of a bug in AppKit).
- `targetWindows() -> [CascadedWindow]`
	- Return your managing CascadedWindow instances.
- `initialWindowSize() -> NSSize?`
	- Return any initial window size if you want.
- `discardWindowFrameAutosaveWhenLastWindowClosed: Bool`
	- Specifies whether to delete the saved window frame from the UserDefaults when the last window is closed.
- `centerWindowPositionWhenFirstWindowOpening: Bool`
	- Specifies whether to center the position of the first window when it opens.

## Note

It seems that calling [`shouldCascadeWindows = true`](https://developer.apple.com/documentation/appkit/nswindowcontroller/1528177-shouldcascadewindows) in `windowDidLoad()` is too late:
[https://stackoverflow.com/questions/35827239/document-based-app-autosave-with-storyboards/43726191](https://stackoverflow.com/questions/35827239/document-based-app-autosave-with-storyboards/43726191)

However, this is true by default, so there is no need to mention it if you are cascading.

- It seems that cascading does not work properly when **"window"** text is included in AutosaveName.
- To begin with, it seems that using `NSWindowController.windowFrameAutosaveName` causes the window to be out of position?

So, based on the reference information, I decided to adopt a policy to achieve cascading and frame saving without using `NSWindowController.windowFrameAutosaveName`.
This is handled by directly reading and writing UserDefaults with **"NSWindow Frame FOOBAR"** as the key.

Refs:

- https://github.com/coteditor/CotEditor/blob/f9c140ab08fd6acd24ebe65fd01420f29ba367fd/CotEditor/Sources/DocumentWindowController.swift
- https://github.com/jessegrosjean/window.autosaveName/blob/master/Test/WindowController.m
- https://stackoverflow.com/questions/35827239/document-based-app-autosave-with-storyboards/43726191


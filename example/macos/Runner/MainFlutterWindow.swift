import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()

    // Configure initial window size and styles, including traffic lights.
    self.setContentSize(NSSize(width: 1400, height: 900))
    self.styleMask.update(with: StyleMask.fullSizeContentView)
    self.titleVisibility = TitleVisibility.hidden
    self.titlebarAppearsTransparent = true
    self.backgroundColor = NSColor(red: 0.162, green: 0.177, blue: 0.19, alpha: 1)
    self.toolbar = NSToolbar()
    self.toolbarStyle = ToolbarStyle.unifiedCompact
  }
}

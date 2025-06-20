import Flutter
import UIKit
import flutter_uploader

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    FlutterUploaderPlugin.registerBackgroundIsolateHandler()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

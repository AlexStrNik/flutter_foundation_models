import Flutter
import UIKit

public class FlutterFoundationModelsPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let hostApi = FoundationModelsHostApiImpl(binaryMessenger: registrar.messenger())
        FoundationModelsHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: hostApi)
    }
}

//
//  CKSession.swift
//  CameraKit
//
//  Created by Adrian Mateoaea on 08/01/2019.
//  Copyright © 2019 Wonderkiln. All rights reserved.
//

import AVFoundation

public extension UIDeviceOrientation {
    
    var videoOrientation: AVCaptureVideoOrientation {
        switch UIDevice.current.orientation {
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        default:
            return .portrait
        }
    }
}

public extension CKFSession.DeviceType {
    
    
    
    var captureDeviceType: AVCaptureDevice.DeviceType {
        switch self {
        case .frontCamera:
            return .builtInWideAngleCamera
        case .backCamera:
            if(isTripleBuiltInCameraAvailable()){
                return .builtInTripleCamera
            }else{
                return .builtInWideAngleCamera
            }
        case .microphone:
            return .builtInMicrophone
        }
    }
    
    
    var captureDeviceTypeForSlowMotion: AVCaptureDevice.DeviceType {
        switch self {
        case .frontCamera:
            return .builtInWideAngleCamera
        case .backCamera:
                return .builtInWideAngleCamera
        case .microphone:
            return .builtInMicrophone
        }
    }
    
    var captureMediaType: AVMediaType {
        switch self {
        case .frontCamera, .backCamera:
            return .video
        case .microphone:
            return .audio
        }
    }
    
    var capturePosition: AVCaptureDevice.Position {
        switch self {
        case .frontCamera:
            return .front
        case .backCamera:
            return .back
        case .microphone:
            return .unspecified
        }
    }
    
    func isTripleBuiltInCameraAvailable() -> Bool{
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTripleCamera],
                                                                      mediaType: AVMediaType.video,
                                                                      position: .back)
        return deviceDiscoverySession.devices.count > 0
    }
    
}

extension CKFSession.CameraPosition {
    var deviceType: CKFSession.DeviceType {
        switch self {
        case .back:
            return .backCamera
        case .front:
            return .frontCamera
        }
    }
}

@objc public protocol CKFSessionDelegate: class {
    @objc func didChangeValue(session: CKFSession, value: Any, key: String)
}

@objc public class CKFSession: NSObject {
    
    @objc public enum DeviceType: UInt {
        case frontCamera, backCamera, microphone
    }
    
    @objc public enum CameraPosition: UInt {
        case front, back
    }
    
    @objc public enum FlashMode: UInt {
        case off, on, auto
    }
    
    @objc public let session: AVCaptureSession
    
    @objc public var previewLayer: AVCaptureVideoPreviewLayer?
    @objc public var overlayView: UIView?
    @objc public var zoom = 1.0
    
    @objc public weak var delegate: CKFSessionDelegate?
    
    @objc override init() {
        self.session = AVCaptureSession()
    }
    
    @objc deinit {
        self.session.stopRunning()
    }
    
    @objc public func start() {
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
        }
    }
    
    
    
    @objc public func stop() {
        self.session.stopRunning()
    }
    
    @objc public func focus(at point: CGPoint) {
        //
    }
    
    @objc public static func captureDeviceInput(type: DeviceType, slowMo:Bool) throws -> AVCaptureDeviceInput {
        var deviceType:AVCaptureDevice.DeviceType
        if(slowMo == true){//Slow mo
            deviceType = type.captureDeviceTypeForSlowMotion
        }else{
            deviceType = type.captureDeviceType
        }
        
        let captureDevices = AVCaptureDevice.DiscoverySession(
            deviceTypes: [deviceType],
            mediaType: type.captureMediaType,
            position: type.capturePosition)
        
        guard let captureDevice = captureDevices.devices.first else {
            throw CKFError.captureDeviceNotFound
        }
        
        return try AVCaptureDeviceInput(device: captureDevice)
    }
    
    @objc public static func deviceInputFormat(input: AVCaptureDeviceInput, width: Int, height: Int, frameRate: Int = 30) -> AVCaptureDevice.Format? {
        for format in input.device.formats {
            let dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            if dimension.width >= width && dimension.height >= height {
                for range in format.videoSupportedFrameRateRanges {
                    if Int(range.maxFrameRate) >= frameRate && Int(range.minFrameRate) <= frameRate {
                        return format
                    }
                }
            }
        }
        
        return nil
    }
}



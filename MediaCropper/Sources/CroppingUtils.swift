//
//  CroppingUtils.swift
//  MediaCropper
//
//  Created by Hovik Melikyan on 30/11/2020.
//

import UIKit
import AVFoundation


public extension UIImage {

	func cropped(at cropFrame: CGRect) -> UIImage? {
		guard cropFrame.size.width > 0, cropFrame.size.height > 0 else {
			return nil
		}
		UIGraphicsBeginImageContextWithOptions(cropFrame.size, true, 1);
		draw(in: CGRect(x: -cropFrame.origin.x, y: -cropFrame.origin.y, width: size.width, height: size.height))
		let newImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return newImage
	}
}



public extension AVAsset {

	func thumbnail() -> UIImage {
		let imgGenerator = AVAssetImageGenerator(asset: self)
		imgGenerator.appliesPreferredTrackTransform = true
		if let cgImage = try? imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil) {
			return UIImage(cgImage: cgImage)
		}
		else {
			return UIImage()
		}
	}


	func exportToFile(withCropFrame cropFrame: CGRect?, preset: String, completion: @escaping (Result<URL, Error>) -> Void) -> AVAssetExportSession? {
		switch videoComposition(withCropFrame: cropFrame) {
			case .success(let composition):
				return export(with: composition, preset: preset, completion: completion)
			case .failure(let error):
				completion(.failure(error))
				return nil
		}
	}


	private func export(with composition: AVVideoComposition, preset: String, completion: @escaping (Result<URL, Error>) -> Void) -> AVAssetExportSession? {
		guard let session = AVAssetExportSession(asset: self, presetName: preset) else {
			completion(.failure(CropperError(message: "Codec not supported")))
			return nil
		}
		session.videoComposition = composition
		let outputURL = URL.tempFile(withExtension: "mov")
		session.outputURL = outputURL
		session.outputFileType = .mov
		session.shouldOptimizeForNetworkUse = true
		session.canPerformMultiplePassesOverSourceMediaData = true
		session.exportAsynchronously(completionHandler: { () -> Void in
			DispatchQueue.main.async(execute: { () -> Void in
				if let error = session.error {
					completion(.failure(error))
				}
				else if session.status != .completed {
					completion(.failure(CropperCancelledError()))
				}
				else {
					completion(.success(outputURL))
				}
			})
		})
		return session
	}


	private func videoComposition(withCropFrame cropRect: CGRect?) -> Result<AVVideoComposition, Error> {
		guard let track = tracks(withMediaType: .video).first else {
			return .failure(CropperError(message: "The file doesn't contain a video track"))
		}

		let composition = AVMutableVideoComposition(propertiesOf: self)
		let instruction = AVMutableVideoCompositionInstruction()
		instruction.timeRange = CMTimeRange(start: .zero, duration: .positiveInfinity)

		var transform = track.preferredTransform
		if let cropRect = cropRect {
			transform.tx -= cropRect.origin.x
			transform.ty -= cropRect.origin.y
			composition.renderSize = cropRect.size
		}
		let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
		transformer.setTransform(transform, at: .zero)
		instruction.layerInstructions = [transformer]

		composition.instructions = [instruction]

		return .success(composition)
	}
}


struct CropperError: LocalizedError {

	var message: String
	var errorDescription: String? { "Cropper error: " + message }
}


struct CropperCancelledError: LocalizedError {
	var errorDescription: String? { "Cropper has been cancelled" }
}


private extension URL {

	static func tempFile(withExtension ext: String) -> Self {
		URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString).appendingPathExtension(ext)
	}
}

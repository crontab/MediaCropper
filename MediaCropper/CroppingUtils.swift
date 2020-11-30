//
//  CroppingUtils.swift
//  MediaCropper
//
//  Created by Hovik Melikyan on 30/11/2020.
//

import UIKit
import AVFoundation


extension UIImage {

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



extension AVAsset {

	func croppedToFile(at cropFrame: CGRect, completion: @escaping (Result<URL, Error>) -> Void) {
		switch videoComposition(withCropFrame: cropFrame) {
			case .success(let composition):
				cropped(with: composition, completion: completion)
			case .failure(let error):
				completion(.failure(error))
		}
	}


	private func cropped(with composition: AVVideoComposition, completion: @escaping (Result<URL, Error>) -> Void) {
		let presetName = AVAssetExportSession.allExportPresets().first(where: { $0 == AVAssetExportPresetHEVC1920x1080 }) ?? AVAssetExportPreset1920x1080
		guard let session = AVAssetExportSession(asset: self, presetName: presetName) else {
			completion(.failure(CropperError(message: "Codec not supported")))
			return
		}
		session.videoComposition = composition
		let outputURL = URL.tempFile(withExtension: "mov")
		session.outputURL = outputURL
		session.outputFileType = .mov
		session.shouldOptimizeForNetworkUse = true
		session.canPerformMultiplePassesOverSourceMediaData = true
		session.exportAsynchronously(completionHandler: { () -> Void in
			DispatchQueue.main.async(execute: { () -> Void in
				completion(.success(outputURL))
			})
		})
	}


	private func videoComposition(withCropFrame cropRect: CGRect) -> Result<AVVideoComposition, Error> {
		guard let track = tracks(withMediaType: .video).first else {
			return .failure(CropperError(message: "The file doesn't contain a video track"))
		}

		var transform = track.preferredTransform
		transform.tx -= cropRect.origin.x
		transform.ty -= cropRect.origin.y

		let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
		transformer.setTransform(transform, at: .zero)

		let instruction = AVMutableVideoCompositionInstruction()
		instruction.timeRange = CMTimeRange(start: .zero, duration: .positiveInfinity)
		instruction.layerInstructions = [transformer]

		let composition = AVMutableVideoComposition(propertiesOf: self)
		composition.renderSize = cropRect.size
		composition.instructions = [instruction]

		return .success(composition)
	}
}


struct CropperError: LocalizedError {

	var message: String
	var errorDescription: String? { "Cropper error: " + message }
}


private extension URL {

	static func tempFile(withExtension ext: String) -> Self {
		URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString).appendingPathExtension(ext)
	}
}

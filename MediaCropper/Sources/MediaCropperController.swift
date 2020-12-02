//
//  MediaCropperController.swift
//  MediaCropperController
//
//  Created by Hovik Melikyan on 01/12/2020.
//

import UIKit
import AVFoundation


public protocol MediaCropperDelegate: class {
	func mediaCropperDidSelectItem(_ item: MediaCropperController.Item)
}


public class MediaCropperController: UIImagePickerController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

	// Default export format is 1920x1080 HEVC if present (newer devices), or H.264 on older devices
	static let optimalVideoExportPreset: String = { AVAssetExportSession.allExportPresets().first(where: { $0 == AVAssetExportPresetHEVC1920x1080 }) ?? AVAssetExportPreset1920x1080 }()


	public enum Item {
		case image(image: UIImage)
		case video(tempVideoURL: URL)
	}


	public class Config {
		public var types: [PickerMediaType] = [.image, .video]
		public var cropRatio: CGFloat = 1
		public var ovalCropMask: Bool = false
		public var videoExportPreset: String = optimalVideoExportPreset

		var requiresCropping: Bool { cropRatio > 0 }
		var libraryVideoExportPreset: String { requiresCropping ? AVAssetExportPresetPassthrough : videoExportPreset }
	}


	let config = Config()
	weak var mediaCropperDelegate: MediaCropperDelegate?


	public static func launch(from parent: UIViewController, delegate: MediaCropperDelegate, configure: (Config) -> Void) {
		let this = MediaCropperController()
		configure(this.config)
		this.sourceType = .photoLibrary
		this.mediaTypes = this.config.types.map { $0.rawValue }
		this.videoExportPreset = this.config.libraryVideoExportPreset // passthrough if cropping is required
		this.delegate = this
		this.mediaCropperDelegate = delegate
		parent.present(this, animated: true)
	}


	public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

		if let url = (info[.mediaURL] ?? info[.imageURL]) as? URL, let type = PickerMediaType.asSuperclassOf(rawValue: info[.mediaType] as? String) {

			switch type {

				case .image:
					if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
						if config.requiresCropping {
							let cropper = MediaCropperViewController.instantiate(with: self, cancelButton: false, item: .image(image: image))
							pushViewController(cropper, animated: true)
							return
						}
						mediaCropperDelegate?.mediaCropperDidSelectItem(.image(image: image))
					}

				case .video:
					if config.requiresCropping {
						let cropper = MediaCropperViewController.instantiate(with: self, cancelButton: true, item: .video(tempVideoURL: url))
						let navigator = UINavigationController(rootViewController: cropper)
						navigator.modalPresentationStyle = .fullScreen
						present(navigator, animated: true)
						return
					}
					mediaCropperDelegate?.mediaCropperDidSelectItem(.video(tempVideoURL: url))
			}
		}

		dismiss(animated: true)
	}
}

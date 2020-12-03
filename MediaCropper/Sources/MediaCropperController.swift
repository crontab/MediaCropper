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


open class MediaCropperController: UIImagePickerController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

	// Default export format is 1920x1080 HEVC if present (newer devices), or H.264 on older devices
	static let optimalVideoExportPreset: String = { AVAssetExportSession.allExportPresets().first(where: { $0 == AVAssetExportPresetHEVC1920x1080 }) ?? AVAssetExportPreset1920x1080 }()


	public enum Item {
		case image(image: UIImage)
		case video(tempVideoURL: URL)
	}


	public class Config {
		public var types: [PickerMediaType] = [.image, .video]
		public var cropRatio: CGFloat = 1 // height to width ratio; or 0 for no cropping
		public var cropPortraitOnly: Bool = false // even if cropping is enabled, landscape and square media should be passed through
		public var ovalCropMask: Bool = false // for selfies
		public var videoExportPreset: String = optimalVideoExportPreset


		// Internal utilities
		var requiresCropping: Bool { cropRatio > 0 }
		var libraryVideoExportPreset: String { requiresCropping ? AVAssetExportPresetPassthrough : videoExportPreset }

		func imageRequiresCropping(_ image: UIImage) -> Bool {
			requiresCropping && (!cropPortraitOnly || image.size.isPortrait)
		}

		func videoRequiresCropping(_ videoURL: URL, naturalSize: CGSize) -> Bool {
			requiresCropping && (!cropPortraitOnly || naturalSize.isPortrait)
		}
	}


	let config = Config()
	public weak var mediaCropperDelegate: MediaCropperDelegate?


	public static func instantiate(configure: (Config) -> Void) -> Self {
		let this = Self()
		configure(this.config)
		this.sourceType = .photoLibrary
		this.mediaTypes = this.config.types.map { $0.rawValue }
		this.videoExportPreset = this.config.libraryVideoExportPreset // passthrough if cropping is required
		this.delegate = this
		return this
	}


	deinit {
		#if DEBUG
		print("MediaCropperController: deinit")
		#endif
	}


	public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

		if let url = (info[.mediaURL] ?? info[.imageURL]) as? URL, let type = PickerMediaType.asSuperclassOf(rawValue: info[.mediaType] as? String) {

			switch type {

				case .image:
					if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
						if config.imageRequiresCropping(image) {
							let cropper = MediaCropperViewController.instantiate(with: self, cancelButton: false, item: .image(image: image))
							pushViewController(cropper, animated: true)
							return
						}
						else {
							dismiss(animated: true) {
								self.mediaCropperDelegate?.mediaCropperDidSelectItem(.image(image: image))
							}
							return
						}
					}

				case .video:
					// If the video doesn't require cropping due to the cropPortraitOnly, it still needs to be passed to the next view controller for decoding since it was exported with the passthrough option.
					if config.requiresCropping {
						let cropper = MediaCropperViewController.instantiate(with: self, cancelButton: true, item: .video(tempVideoURL: url))
						let navigator = UINavigationController(rootViewController: cropper)
						navigator.modalPresentationStyle = .fullScreen
						present(navigator, animated: true)
						return
					}
					else {
						dismiss(animated: true) {
							self.mediaCropperDelegate?.mediaCropperDidSelectItem(.video(tempVideoURL: url))
						}
						return
					}
			}
		}

		dismiss(animated: true)
	}
}

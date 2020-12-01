//
//  MediaCropperController.swift
//  MediaCropperController
//
//  Created by Hovik Melikyan on 01/12/2020.
//

import UIKit
import AVFoundation


protocol MediaCropperDelegate: class {
	func mediaCropper(_ mediaCropper: MediaCropperController, didSelectItem item: MediaCropperController.Item)
}


class MediaCropperController: UIImagePickerController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

	enum Item {
		case image(image: UIImage)
		case video(tempVideoURL: URL)
	}


	class Config {
		var types: [PickerMediaType] = [.image, .video]
		var cropRatio: CGFloat = 1
		var ovalCropMask: Bool = false
		// TODO: videoExportPreset: String? = nil
		// TODO: var imageExportPreset: UIImagePickerController.ImageURLExportPreset? = nil

		fileprivate var requiresCropping: Bool { cropRatio > 0 }
	}


	let config = Config()
	weak var mediaCropperDelegate: MediaCropperDelegate?


	class func launch(from parent: UIViewController, delegate: MediaCropperDelegate, configure: (Config) -> Void) {
		let this = MediaCropperController()
		configure(this.config)
		this.sourceType = .photoLibrary
		this.mediaTypes = this.config.types.map { $0.rawValue }
		this.videoExportPreset = AVAssetExportPresetPassthrough
		this.delegate = this
		this.mediaCropperDelegate = delegate
		parent.present(this, animated: true)
	}


	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

		if let url = (info[.mediaURL] ?? info[.imageURL]) as? URL, let type = PickerMediaType.asSuperclassOf(rawValue: info[.mediaType] as? String) {

			switch type {

				case .image:
					if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
						if config.requiresCropping {
							let cropper = MediaCropperViewController.instantiate(with: self, item: .image(image: image))
							pushViewController(cropper, animated: true)
							return
						}
						mediaCropperDelegate?.mediaCropper(self, didSelectItem: .image(image: image))
					}

				case .video:
					if config.requiresCropping {
						return
					}
					// TODO: move the file if not cropping
			}
		}

		dismiss(animated: true)
	}
}

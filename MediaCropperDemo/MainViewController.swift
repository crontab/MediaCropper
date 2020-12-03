//
//  MainViewController.swift
//  MediaCropper
//
//  Created by Hovik Melikyan on 01/12/2020.
//

import UIKit
import AVFoundation
import MediaCropper



class MainViewController: UIViewController, MediaCropperDelegate {

	@IBOutlet private var imageView: UIImageView!


	@IBAction private func pickSquareImageAction(_ sender: Any) {
		let cropper = MediaCropperController.instantiate { (config) in
			config.cropRatio = 1 // 0.32
			config.cropPortraitOnly = true
			// config.ovalCropMask = true
		}
		cropper.mediaCropperDelegate = self
		present(cropper, animated: true)
	}


	func mediaCropperDidSelectItem(_ item: MediaCropperController.Item) {
		switch item {
			case .image(let image):
				imageView.image = image
			case .video(let videoURL):
				imageView.image = AVURLAsset(url: videoURL).thumbnail()
		}
	}
}

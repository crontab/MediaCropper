//
//  MainViewController.swift
//  MediaCropper
//
//  Created by Hovik Melikyan on 01/12/2020.
//

import UIKit



class MainViewController: UIViewController, MediaCropperDelegate {

	@IBOutlet private var imageView: UIImageView!


	@IBAction private func pickSquareImageAction(_ sender: Any) {
		MediaCropperController.launch(from: self, delegate: self) { (config) in
			config.cropRatio = 0.32
		}
	}


	func mediaCropperDidSelectItem(_ item: MediaCropperController.Item) {
		switch item {
			case .image(let image):
				imageView.image = image
			case .video(_):
				break
		}
	}
}

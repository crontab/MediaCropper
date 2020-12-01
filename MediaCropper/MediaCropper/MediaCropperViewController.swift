//
//  MediaCropperViewController.swift
//  MediaCropper
//
//  Created by Hovik Melikyan on 26/11/2020.
//

import UIKit
import AVFoundation


struct MediaCropperConfig {

	/// Combination of : `.image`, `.video`
	var types: [PickerMediaType] = [.image, .video]

	/// Height/width ratio for the crop frame, e.g. 1 for square; 0 means no cropping, i.e. media is passed through
	var cropRatio: CGFloat = 1

	/// Display an oval mask (or round if cropRatio = 1)
	var ovalCropMask: Bool = false

	// TODO: videoExportPreset: String? = nil
	// TODO: var imageExportPreset: UIImagePickerController.ImageURLExportPreset? = nil

	fileprivate var croppingRequired: Bool { cropRatio > 0 }
}



// MARK: - View controller

class MediaCropperViewController: UIViewController, UIScrollViewDelegate {

	@IBOutlet private var cropButton: UIBarButtonItem?
	@IBOutlet private var scrollView: UIScrollView!
	@IBOutlet private var imageView: ScalableImageView!
	@IBOutlet private var videoView: ScalableVideoView!
	@IBOutlet private var cropView: InvertedRoundMaskView!
	@IBOutlet private var cropViewHeight: NSLayoutConstraint!

	@IBOutlet private var processingOverlay: UIView!

	private var config = MediaCropperConfig()


	override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }


	class func launch(from parent: UIViewController, config: MediaCropperConfig?) {
		let navigator = UIStoryboard(name: "MediaCropper", bundle: Bundle(for: self)).instantiateInitialViewController() as! UINavigationController
		if let config = config {
			let this = navigator.viewControllers.first as! Self
			this.config = config
		}
		parent.present(navigator, animated: true)
	}


	override func viewDidLoad() {
		super.viewDidLoad()

		scrollView.delegate = self

		cropViewHeight.constant = cropView.frame.width * config.cropRatio
		cropView.enableMask = config.ovalCropMask

		imageView.isHidden = true
		videoView.isHidden = true
		isProcessing = false
	}


	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		imageView.screenCropRect = cropView.frame
		videoView.screenCropRect = cropView.frame
		scrollView.contentInset = .init(top: max(0, cropView.frame.minY), left: 0, bottom: max(0, scrollView.frame.height - cropView.frame.maxY), right: 0)
	}


	func setImage(_ image: UIImage?, tempURL: URL?) {
		imageView.setImage(image, tempURL: tempURL)
		videoView.clear()
		showHideViews()
		resetScrollView()
	}


	func setVideoURL(_ tempURL: URL) {
		videoView.setTempVideoURL(tempURL)
		imageView.clear()
		showHideViews()
		videoView.play()
		resetScrollView()
	}


	private func showHideViews() {
		videoView.isHidden = videoView.isEmpty
		imageView.isHidden = imageView.isEmpty
	}


	private func resetScrollView() {
		scrollView.zoomScale = 1
		scrollView.layoutIfNeeded()
		scrollView.contentOffset = imageView.isHidden && videoView.isHidden ? .zero :
			CGPoint(x: (scrollView.contentSize.width - scrollView.frame.width) / 2, y: (scrollView.contentSize.height - scrollView.frame.height) / 2)
	}


	private var isProcessing: Bool {
		get { !processingOverlay.isHidden }
		set {
			processingOverlay.isHidden = !newValue
			cropButton?.isEnabled = !newValue
		}
	}


	@IBAction private func confirmAction(_ sender: Any) {
		if let videoURL = videoView.tempURL {
			videoView.pause()
			isProcessing = true
			AVAsset(url: videoURL).croppedToFile(at: videoView.effectiveCropFrame(with: scrollView)) { [self] (result) in
				isProcessing = false
				switch result {
					case .success(let tempUrl):
						// TODO: pass to the delegate
						setVideoURL(tempUrl)
					case .failure(let error):
						alert(error)
				}
			}
		}
		else if !imageView.isHidden {
			// TODO: pass to the delegate
			setImage(imageView.image?.cropped(at: imageView.effectiveCropFrame(with: scrollView)), tempURL: nil)
		}
	}


	@IBAction private func cancelAction(_ sender: Any) {
		navigationController?.dismiss(animated: true)
	}


	func viewForZooming(in scrollView: UIScrollView) -> UIView? {
		!imageView.isHidden ? imageView : !videoView.isHidden ? videoView : nil
	}
}


// MARK: - Image picker extension

extension MediaCropperViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

	private func pickAction() {
		guard !config.types.isEmpty else { return }
		let picker = UIImagePickerController()
		picker.sourceType = .photoLibrary
		picker.mediaTypes = config.types.map { $0.rawValue }
		picker.videoExportPreset = AVAssetExportPresetPassthrough
		picker.delegate = self
		present(picker, animated: true)
	}


	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		picker.dismiss(animated: true)
		if let url = (info[.mediaURL] ?? info[.imageURL]) as? URL, let type = PickerMediaType.asSuperclassOf(rawValue: info[.mediaType] as? String) {
			switch type {
				case .image:
					if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
						setImage(image, tempURL: url)
					}
				case .video:
					setVideoURL(url)
			}
		}
	}
}


// MARK: - Standard alerts

private extension UIViewController {

	func alert(_ error: Error) {
		alert(title: "Oops...", message: error.localizedDescription)
	}

	func alert(title: String?, message: String? = nil) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default))
		self.present(alert, animated: true)
	}
}

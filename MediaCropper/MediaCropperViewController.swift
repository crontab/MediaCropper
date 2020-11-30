//
//  MediaCropperViewController.swift
//  MediaCropper
//
//  Created by Hovik Melikyan on 26/11/2020.
//

import UIKit
import AVFoundation



// MARK: - View controller

class MediaCropperViewController: UIViewController, UIScrollViewDelegate {

	struct Config {
		var types: [PickerMediaType] = [.image, .video]
		var cropRatio: CGFloat = 0.5 // 1 for square
		var roundCrop: Bool = false // true
	}


	@IBOutlet private var cropButton: UIBarButtonItem?
	@IBOutlet private var scrollView: UIScrollView!
	@IBOutlet private var imageView: ScalableImageView!
	@IBOutlet private var videoView: ScalableVideoView!
	@IBOutlet private var cropView: InvertedRoundMaskView!
	@IBOutlet private var cropViewHeight: NSLayoutConstraint!

	@IBOutlet private var processingOverlay: UIView!

	private var config = Config()


	override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }


	override func viewDidLoad() {
		super.viewDidLoad()

		scrollView.delegate = self

		cropViewHeight.constant = cropView.frame.width * config.cropRatio
		cropView.enableMask = config.roundCrop

		imageView.isHidden = true
		videoView.isHidden = true
		processingOverlay.isHidden = true

		pickAction(nil)
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


	private var processing: Bool {
		get { !processingOverlay.isHidden }
		set {
			processingOverlay.isHidden = !newValue
			cropButton?.isEnabled = !newValue
		}
	}


	@IBAction func confirmAction(_ sender: Any) {
		if let videoURL = videoView.tempURL {
			videoView.pause()
			processing = true
			AVAsset(url: videoURL).croppedToFile(at: videoView.effectiveCropFrame(with: scrollView)) { [self] (result) in
				processing = false
				switch result {
					case .success(let tempUrl):
						setVideoURL(tempUrl)
					case .failure(let error):
						alert(error)
				}
			}
		}
		else if !imageView.isHidden {
			setImage(imageView.image?.cropped(at: imageView.effectiveCropFrame(with: scrollView)), tempURL: nil)
		}
	}


	func viewForZooming(in scrollView: UIScrollView) -> UIView? {
		!imageView.isHidden ? imageView : !videoView.isHidden ? videoView : nil
	}
}


// MARK: - Image picker extension

extension MediaCropperViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

	@IBAction private func pickAction(_ sender: Any?) {
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

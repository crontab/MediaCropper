//
//  MediaCropperViewController.swift
//  MediaCropper
//
//  Created by Hovik Melikyan on 26/11/2020.
//

import UIKit
import AVFoundation



class MediaCropperViewController: UIViewController {

	@IBOutlet private var cropButton: UIBarButtonItem?
	@IBOutlet private var scrollView: UIScrollView!
	@IBOutlet private var imageView: ScalableImageView!
	@IBOutlet private var videoView: ScalableVideoView!
	@IBOutlet private var cropView: InvertedRoundMaskView!
	@IBOutlet private var cropViewHeight: NSLayoutConstraint!

	@IBOutlet private var processingOverlay: UIView!

	private weak var cropper: MediaCropperController!
	private var item: MediaCropperController.Item!
	private var config: MediaCropperController.Config { cropper.config }
	private var delegate: MediaCropperDelegate? { cropper.mediaCropperDelegate }

	override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }


	static func instantiate(with cropper: MediaCropperController, item: MediaCropperController.Item) -> Self {
		let this = UIStoryboard(name: "MediaCropper", bundle: Bundle(for: self)).instantiateViewController(withIdentifier: "MediaCropperViewController") as! Self
		this.cropper = cropper
		this.item = item
		return this
	}


	override func viewDidLoad() {
		super.viewDidLoad()

		navigationController?.setNavigationBarHidden(false, animated: true)

		scrollView.delegate = self

		cropView.enableMask = config.ovalCropMask

		isProcessing = false
	}


	private var firstLayout = true

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()

		cropView.layoutIfNeeded()
		cropViewHeight.constant = cropView.frame.width * config.cropRatio
		view.layoutIfNeeded()
		imageView.screenCropRect = cropView.frame
		videoView.screenCropRect = cropView.frame
		scrollView.contentInset = .init(top: max(0, cropView.frame.minY), left: 0, bottom: max(0, scrollView.frame.height - cropView.frame.maxY), right: 0)

		guard firstLayout else {
			return
		}
		firstLayout = false

		switch item! {
			case .image(let image):
				imageView.image = image
				videoView.isHidden = true
				imageView.isHidden = false

			case .video(let tempVideoURL):
				videoView.setTempVideoURL(tempVideoURL)
				videoView.isHidden = false
				imageView.isHidden = true
				videoView.play()
		}

		scrollView.layoutIfNeeded()
		scrollView.contentOffset = CGPoint(x: (scrollView.contentSize.width - scrollView.frame.width) / 2, y: (scrollView.contentSize.height - scrollView.frame.height) / 2)
	}


	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		navigationController?.setNavigationBarHidden(true, animated: true)
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
					case .success(let tempURL):
						dismiss(animated: true) {
							delegate?.mediaCropper(cropper, didSelectItem: .video(tempVideoURL: tempURL))
						}
					case .failure(let error):
						alert(error)
				}
			}
		}
		else {
			if let croppedImage = imageView.image?.cropped(at: imageView.effectiveCropFrame(with: scrollView)) {
				delegate?.mediaCropper(cropper, didSelectItem: .image(image: croppedImage))
			}
		}
	}


	@IBAction private func cancelAction(_ sender: Any) {
		navigationController?.dismiss(animated: true)
	}
}


// MARK: - Scroll view delegate

extension MediaCropperViewController: UIScrollViewDelegate {

	func viewForZooming(in scrollView: UIScrollView) -> UIView? {
		!imageView.isHidden ? imageView : !videoView.isHidden ? videoView : nil
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

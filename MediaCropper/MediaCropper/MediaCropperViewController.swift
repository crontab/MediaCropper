//
//  MediaCropperViewController.swift
//  MediaCropper
//
//  Created by Hovik Melikyan on 26/11/2020.
//

import UIKit
import AVFoundation



class MediaCropperViewController: UIViewController, UIScrollViewDelegate {

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


	static func instantiate(with cropper: MediaCropperController, cancelButton: Bool, item: MediaCropperController.Item) -> Self {
		let this = UIStoryboard(name: "MediaCropper", bundle: Bundle(for: self)).instantiateViewController(withIdentifier: "MediaCropperViewController") as! Self
		this.cropper = cropper
		this.item = item
		if cancelButton {
			this.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: this, action: #selector(cancelAction(_:)))
		}
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

		cropView.layoutIfNeeded() // ensure the width is correct
		cropViewHeight.constant = cropView.frame.width * config.cropRatio
		view.layoutIfNeeded() // now ensure cropView.frame is correct before using it below

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


	func viewForZooming(in scrollView: UIScrollView) -> UIView? {
		!imageView.isHidden ? imageView : !videoView.isHidden ? videoView : nil
	}


	@IBAction private func confirmAction(_ sender: Any) {
		if let videoURL = videoView.tempURL {
			videoView.pause()
			isProcessing = true
			AVAsset(url: videoURL).croppedToFile(at: videoView.effectiveCropFrame(with: scrollView), preset: config.videoExportPreset) { [self] (result) in
				isProcessing = false
				switch result {
					case .success(let tempURL):
						delegate?.mediaCropper(cropper, didSelectItem: .video(tempVideoURL: tempURL))
						cropper.presentingViewController?.dismiss(animated: true)
					case .failure(let error):
						alert(error)
				}
			}
		}
		else {
			if let croppedImage = imageView.image?.cropped(at: imageView.effectiveCropFrame(with: scrollView)) {
				delegate?.mediaCropper(cropper, didSelectItem: .image(image: croppedImage))
				cropper.dismiss(animated: true)
			}
		}
	}


	@objc private func cancelAction(_ sender: Any) {
		// TODO: cancel cropping of the video
		cropper.presentingViewController?.dismiss(animated: true)
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

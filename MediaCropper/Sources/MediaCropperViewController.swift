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

	@IBOutlet private var topMask: UIView!
	@IBOutlet private var cropView: CroppingMaskView!
	@IBOutlet private var cropViewHeight: NSLayoutConstraint!
	@IBOutlet private var bottomMask: UIView!

	@IBOutlet private var processingOverlay: UIView!
	@IBOutlet private var progressView: UIProgressView!

	private weak var cropper: MediaCropperController?
	private var item: MediaCropperController.Item!
	private var config: MediaCropperController.Config!
	private var delegate: MediaCropperDelegate? { cropper?.mediaCropperDelegate }

	override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }


	static func instantiate(with cropper: MediaCropperController, cancelButton: Bool, item: MediaCropperController.Item) -> Self {
		let this = UIStoryboard(name: "MediaCropper", bundle: Bundle(for: self)).instantiateViewController(withIdentifier: "MediaCropperViewController") as! Self
		this.cropper = cropper
		this.config = cropper.config
		this.item = item
		if cancelButton {
			this.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: this, action: #selector(cancelAction(_:)))
		}
		return this
	}


	deinit {
		#if DEBUG
		print("MediaCropperViewController: deinit")
		#endif
	}


	override func viewDidLoad() {
		super.viewDidLoad()

		navigationController?.setNavigationBarHidden(false, animated: true)
		navigationController?.navigationBar.isTranslucent = false

		scrollView.delegate = self

		if config.ovalCropMask {
			cropView.isOval = true
			cropView.borderWidth = 2
			cropView.borderDash = 10
			cropView.cornerMarkerWidth = 0
		}
		else {
			cropView.isOval = false
			cropView.borderWidth = 1
			cropView.borderDash = 0
			cropView.cornerMarkerWidth = 3
		}

		isProcessing = false
	}


	private var firstLayout = true

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()

		guard firstLayout else {
			return
		}
		firstLayout = false

		cropView.layoutIfNeeded() // ensure the width is correct

		switch item! {
			case .image(let image):
				imageView.isHidden = false
				imageView.image = image
				setCropViewHeight(cropView.frame.width * config.cropRatio)
				imageView.screenCropRect = cropView.frame
				title = "Crop " + config.imageNoun

			case .video(let tempVideoURL):
				videoView.isHidden = false
				videoView.setTempVideoURL(tempVideoURL)
				if let naturalSize = videoView.naturalSize, config.videoRequiresCropping(tempVideoURL, naturalSize: naturalSize) {
					setCropViewHeight(cropView.frame.width * config.cropRatio)
					videoView.screenCropRect = cropView.frame
					videoView.play()
					title = "Crop " + config.videoNoun
				}
				else {
					setCropViewHeight(1) // fit the entire video as we are not cropping in this case
					videoView.screenCropRect = cropView.frame
					isMaskEnabled = false
					navigationItem.rightBarButtonItem = nil
					startVideoExport(videoURL: tempVideoURL, cropFrame: nil)
					title = "Processing " + config.videoNoun
				}
		}

		scrollView.layoutIfNeeded()
		scrollView.contentOffset = CGPoint(x: (scrollView.contentSize.width - scrollView.frame.width) / 2, y: (scrollView.contentSize.height - scrollView.frame.height) / 2)
	}


	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		navigationController?.setNavigationBarHidden(true, animated: true)
	}


	private func setCropViewHeight(_ height: CGFloat) {
		cropViewHeight.constant = height
		view.layoutIfNeeded() // ensure cropView.frame is correct before using it below
		scrollView.contentInset = .init(top: max(0, cropView.frame.minY), left: 0, bottom: max(0, scrollView.frame.height - cropView.frame.maxY), right: 0)
	}


	private var isMaskEnabled: Bool {
		get {
			!cropView.isHidden
		}
		set {
			topMask.isHidden = !newValue
			cropView.isHidden = !newValue
			bottomMask.isHidden = !newValue
		}
	}


	private var isProcessing: Bool {
		get {
			!processingOverlay.isHidden
		}
		set {
			processingOverlay.isHidden = !newValue
			cropButton?.isEnabled = !newValue
			NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(progressProc), object: nil)
		}
	}


	// UIScrollViewDelegate
	func viewForZooming(in scrollView: UIScrollView) -> UIView? {
		!imageView.isHidden ? imageView : !videoView.isHidden ? videoView : nil
	}


	private var videoExportSession: AVAssetExportSession?

	@IBAction private func confirmAction(_ sender: Any) {
		if let videoURL = videoView.tempURL {
			videoView.pause()
			startVideoExport(videoURL: videoURL, cropFrame: videoView.effectiveCropFrame(with: scrollView))
		}
		else if let croppedImage = imageView.image?.cropped(at: imageView.effectiveCropFrame(with: scrollView)) {
			cropper?.dismiss(animated: true) {
				self.delegate?.mediaCropperDidSelectItem(.image(image: croppedImage))
			}
		}
	}


	private func startVideoExport(videoURL: URL, cropFrame: CGRect?) {
		progressView.progress = 0
		isProcessing = true
		videoExportSession = AVAsset(url: videoURL).exportToFile(withCropFrame: cropFrame, preset: config.videoExportPreset) { [self] (result) in
			isProcessing = false
			switch result {
				case .success(let tempURL):
					videoExportSessionDidFinish(withError: nil, inputURL: videoURL)
					cropper?.presentingViewController?.dismiss(animated: true) {
						self.delegate?.mediaCropperDidSelectItem(.video(tempVideoURL: tempURL))
					}
				case .failure(let error):
					videoExportSessionDidFinish(withError: error, inputURL: videoURL)
					if !(error is CropperCancelledError) {
						alert(error)
					}
			}
		}
		progressProc()
	}


	@objc private func progressProc() {
		if let session = videoExportSession {
			progressView.setProgress(session.progress, animated: true)
			perform(#selector(progressProc), with: nil, afterDelay: 1 / 30)
		}
		else {
			progressView.progress = 1
		}
	}


	private func videoExportSessionDidFinish(withError error: Error?, inputURL: URL) {
		if let session = videoExportSession {
			videoExportSession = nil
			if error != nil, let outputURL = session.outputURL {
				try? FileManager.default.removeItem(at: outputURL)
			}
		}
		try? FileManager.default.removeItem(at: inputURL) // doesn't seem to be able to remove this actually
	}


	@objc private func cancelAction(_ sender: Any) {
		videoExportSession?.cancelExport()
		// Since the cancel button is only created for the video flow, dismiss self and the system picker (subclassed as `cropper`)
		cropper?.presentingViewController?.dismiss(animated: true)
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

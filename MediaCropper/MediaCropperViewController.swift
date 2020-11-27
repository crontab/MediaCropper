//
//  MediaCropperViewController.swift
//  MediaCropper
//
//  Created by Hovik Melikyan on 26/11/2020.
//

import UIKit



// MARK: - View controller

class MediaCropperViewController: UIViewController, UIScrollViewDelegate {

	struct Config {
		var types: [PickerMediaType] = [.image, .video]
		var cropRatio: CGFloat = 0.5 // 1 for square
		var roundCrop: Bool = true
	}


	@IBOutlet private var scrollView: UIScrollView!
	@IBOutlet private var imageView: ScalableImageView!
	@IBOutlet private var videoView: ScalableVideoView!
	@IBOutlet private var cropView: InvertedRoundMaskView!
	@IBOutlet private var cropViewHeight: NSLayoutConstraint!

	private var config = Config()


	override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }


	override func viewDidLoad() {
		super.viewDidLoad()

		scrollView.delegate = self

		cropViewHeight.constant = cropView.frame.width * config.cropRatio
		cropView.enableMask = config.roundCrop

		imageView.isHidden = true
		videoView.isHidden = true

		pickAction(nil)
	}


	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		imageView.cropSize = cropView.frame.size
		videoView.cropSize = cropView.frame.size
		scrollView.contentInset = .init(top: max(0, cropView.frame.minY), left: 0, bottom: max(0, scrollView.frame.height - cropView.frame.maxY), right: 0)
	}


	func setImage(_ image: UIImage?) {
		videoView.videoURL = nil
		imageView.image = image
		showHideViews()
		resetScrollView()
	}


	func setVideoURL(_ videoURL: URL) {
		videoView.videoURL = videoURL
		imageView.image = nil
		showHideViews()
		videoView.play()
		resetScrollView()
	}


	private func showHideViews() {
		videoView.isHidden = videoView.videoURL == nil
		imageView.isHidden = imageView.image == nil
	}


	private func resetScrollView() {
		scrollView.zoomScale = 1
		scrollView.layoutIfNeeded()
		scrollView.contentOffset = imageView.isHidden && videoView.isHidden ? .zero :
			CGPoint(x: (scrollView.contentSize.width - scrollView.frame.width) / 2, y: (scrollView.contentSize.height - scrollView.frame.height) / 2)
	}


	private var effectiveCropFrame: CGRect {
		cropView.frame.offset(by: scrollView.contentOffset).scaled(by: imageView.scaleFactor / scrollView.zoomScale)
	}


	@IBAction func confirmAction(_ sender: Any) {
		if !imageView.isHidden {
			setImage(imageView.image?.cropped(at: effectiveCropFrame))
		}
		else {
			// TODO:
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
		picker.delegate = self
		present(picker, animated: true)
	}


	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		picker.dismiss(animated: true)
		if let url = (info[.mediaURL] ?? info[.imageURL]) as? URL, let type = PickerMediaType.asSuperclassOf(rawValue: info[.mediaType] as? String) {
			switch type {
				case .image:
					if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
						setImage(image)
					}
				case .video:
					setVideoURL(url)
			}
		}
	}
}

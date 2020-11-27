//
//  MediaCropperViewController.swift
//  ImageCropper
//
//  Created by Hovik Melikyan on 26/11/2020.
//

import UIKit



// MARK: - View controller

class MediaCropperViewController: UIViewController, UIScrollViewDelegate {

	struct Config {
		var types: [PickerMediaType] = [.image]
		var cropRatio: CGFloat = 0.5 // 1 for square
		var roundCrop: Bool = true
	}


	@IBOutlet private var scrollView: UIScrollView!
	@IBOutlet private var imageView: ScalableImageView!
	@IBOutlet private var cropView: InvertedRoundMaskView!
	@IBOutlet private var cropViewHeight: NSLayoutConstraint!

	private var config = Config()


	override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }


	override func viewDidLoad() {
		super.viewDidLoad()

		scrollView.delegate = self

		cropViewHeight.constant = cropView.frame.width * config.cropRatio
		cropView.enableMask = config.roundCrop

		pickAction(nil)
	}


	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		imageView.minSize = cropView.frame.size
		scrollView.contentInset = .init(top: max(0, cropView.frame.minY), left: 0, bottom: max(0, scrollView.frame.height - cropView.frame.maxY), right: 0)
	}


	private func setImage(_ image: UIImage?) {
		imageView.image = image
		scrollView.zoomScale = 1
		scrollView.layoutIfNeeded()
		scrollView.contentOffset = image == nil ? .zero : CGPoint(x: (scrollView.contentSize.width - scrollView.frame.width) / 2, y: (scrollView.contentSize.height - scrollView.frame.height) / 2)
	}


	private var effectiveCropFrame: CGRect {
		cropView.frame.offset(by: scrollView.contentOffset).scaled(by: imageView.scaleFactor / scrollView.zoomScale)
	}


	private func crop() -> UIImage? {
		imageView.image?.cropped(at: effectiveCropFrame)
	}


	@IBAction func confirmAction(_ sender: Any) {
		setImage(crop())
	}


	func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }
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
					break
			}
		}
	}
}

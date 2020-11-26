//
//  MediaCropperViewController.swift
//  ImageCropper
//
//  Created by Hovik Melikyan on 26/11/2020.
//

import UIKit
import CoreServices // for UTTypeConformsTo


// MARK: - Media types

enum PickerMediaType: String, CaseIterable {
	case video = "public.movie"
	case image = "public.image"

	static func asSuperclassOf(rawValue: String?) -> Self? {
		guard let rawValue = rawValue else {
			return nil
		}
		if let result = self.init(rawValue: rawValue) {
			return result
		}
		for x in allCases {
			if UTTypeConformsTo(rawValue as CFString, x.rawValue as CFString) {
				return x
			}
		}
		return nil
	}
}


// MARK: - Designable view with a frame

@IBDesignable
class BorderedView: UIView {

	@IBInspectable
	var borderWidth: CGFloat {
		get { return layer.borderWidth }
		set { layer.borderWidth = newValue }
	}

	@IBInspectable
	var borderColor: UIColor? {
		didSet {
			layer.borderColor = borderColor?.cgColor
		}
	}
}


// MARK: - Image view with intrinsic scaling

class ScalableImageView: UIImageView {

	fileprivate var minSize: CGSize = .zero { // scale to the minimum that fills this rectangle
		didSet {
			if minSize != oldValue {
				invalidateIntrinsicContentSize()
			}
		}
	}


	var scaleFactor: CGFloat { (image?.size.height ?? 0) / intrinsicContentSize.height }


	override var intrinsicContentSize: CGSize {
		guard minSize.width != 0, let image = image, image.size.width != 0 else {
			return super.intrinsicContentSize
		}
		let newHeight = image.size.height * minSize.width / image.size.width
		if newHeight < minSize.height {
			let newWidth = image.size.width * minSize.height / image.size.height
			return CGSize(width: newWidth, height: minSize.height)
		}
		return CGSize(width: minSize.width, height: newHeight)
	}
}


// MARK: - View controller

class MediaCropperViewController: UIViewController, UIScrollViewDelegate {

	struct Config {
		var types: [PickerMediaType] = [.image]
		var cropRatio: CGFloat = 0.5 // square
	}


	@IBOutlet private var scrollView: UIScrollView!
	@IBOutlet private var imageView: ScalableImageView!
	@IBOutlet private var cropView: BorderedView!
	@IBOutlet private var cropViewHeight: NSLayoutConstraint!

	private var config = Config()


	override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }


	override func viewDidLoad() {
		super.viewDidLoad()

		scrollView.delegate = self

		cropViewHeight.constant = cropView.frame.width * config.cropRatio

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

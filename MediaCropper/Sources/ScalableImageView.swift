//
//  ScalableImageView.swift
//  MediaCropper
//
//  Created by Hovik Melikyan on 27/11/2020.
//

import UIKit


/// UIImageView's own intrinsic size equals to the image size loaded into it. Therefore to resize UIImageView intrinsicContentSize should be overridden. This class does it by specifying `screenCropRect`: this image view will resize itself to the minimum size that entirely contains `screenCropRect` dimensions so that the image can be positioned by the user on screen. When cropping the actual image, `scaleFactor` can be used to determine how the screen cropping rectangle should be scaled before applying to the image.

class ScalableImageView: UIImageView, ScalableViewProtocol {

	var screenCropRect: CGRect = .zero { // scale to the minimum that fills this rectangle
		didSet {
			if screenCropRect != oldValue {
				invalidateIntrinsicContentSize()
			}
		}
	}

	var naturalSize: CGSize? {
		image?.size
	}

	override var intrinsicContentSize: CGSize {
		intrinsicSizeForCropping ?? super.intrinsicContentSize
	}
}

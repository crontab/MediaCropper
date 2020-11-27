//
//  PickerMediaType.swift
//  ImageCropper
//
//  Created by Hovik Melikyan on 27/11/2020.
//

import Foundation
import CoreServices // for UTTypeConformsTo


/// Media types accepted by the image and document pickers

enum PickerMediaType: String, CaseIterable {
	case video = "public.movie"
	case image = "public.image"


	/// A media subtype returned by one of the media pickers (image or document) can be translated to one of the general types above using `asSuperclassOf()`. For example `public.jpeg` becomes `.image`

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

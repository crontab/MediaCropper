//
//  ScalableVideoView.swift
//  MediaCropper
//
//  Created by Hovik Melikyan on 27/11/2020.
//

import UIKit
import AVFoundation


/// This view plays a video in a loop. The `screenCropRect` instructs the view to resize itself (along with the video layer) to the minimal size that fills the crop size, so that it can be positioned by the user on screen. When cropping the actual video, `scaleFactor` can be used to determine how the screen cropping rectangle should be scaled before applying to the video.

class ScalableVideoView: UIView, ScalableViewProtocol {

	var tempURL: URL? { videoURL }


	func setTempVideoURL(_ tempURL: URL?) {
		if let tempURL = self.tempURL {
			try? FileManager.default.removeItem(at: tempURL)
		}
		if tempURL != videoURL {
			looper = nil
			queuePlayer.removeAllItems()
			if let url = tempURL {
				queuePlayer.insert(AVPlayerItem(url: url), after: nil)
				looper = AVPlayerLooper(player: queuePlayer, templateItem: queuePlayer.currentItem!)
			}
			invalidateIntrinsicContentSize()
		}
	}


	func play() {
		if queuePlayer.currentItem != nil {
			queuePlayer.play()
		}
	}


	func pause() {
		queuePlayer.pause()
	}


	var isPlaying: Bool {
		queuePlayer.currentItem != nil && queuePlayer.rate > 0
	}


	var screenCropRect: CGRect = .zero { // scale to the minimum that fills this rectangle
		didSet {
			if screenCropRect != oldValue {
				invalidateIntrinsicContentSize()
			}
		}
	}


	// MARK: - internal

	override init(frame: CGRect) {
		super.init(frame: frame)
		setup()
	}


	required init?(coder: NSCoder) {
		super.init(coder: coder)
		setup()
	}


	private var videoLayer = AVPlayerLayer(player: AVQueuePlayer())
	private var looper: AVPlayerLooper?

	private var queuePlayer: AVQueuePlayer { videoLayer.player as! AVQueuePlayer }
	private var videoURL: URL? { (queuePlayer.currentItem?.asset as? AVURLAsset)?.url }


	open override func layoutSubviews() {
		super.layoutSubviews()
		if bounds != videoLayer.frame {
			CATransaction.begin()
			CATransaction.setValue(true, forKey: kCATransactionDisableActions)
			videoLayer.frame = bounds
			CATransaction.commit()
		}
	}


	var naturalSize: CGSize? {
		guard let track = queuePlayer.currentItem?.asset.tracks(withMediaType: .video).first else {
			return nil
		}
		return track.naturalSize.applying(track.preferredTransform).absoluted
	}


	override var intrinsicContentSize: CGSize {
		intrinsicSizeForCropping ?? super.intrinsicContentSize
	}


	private func setup() {
		videoLayer.frame = bounds
		videoLayer.videoGravity = .resizeAspectFill
		videoLayer.masksToBounds = true
		clipsToBounds = true
		layer.addSublayer(videoLayer)
	}
}

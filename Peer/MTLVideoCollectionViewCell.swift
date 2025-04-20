//
//  MTLVideoCollectionViewCell.swift
//  Peer
//
//  Created by Jia-Han Wu on 2025/4/20.
//

import UIKit
import WebRTC

class MTLVideoCollectionViewCell: UICollectionViewCell {
 
    let mtlVideoView: RTCMTLVideoView = {
        let view = RTCMTLVideoView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.videoContentMode = .scaleAspectFit
        return view
    }()
    
    private weak var videoTrack: RTCVideoTrack?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    private func configure() {
        contentView.addSubview(mtlVideoView)
        
        NSLayoutConstraint.activate(
            [
                mtlVideoView.topAnchor.constraint(equalTo: contentView.topAnchor),
                mtlVideoView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                mtlVideoView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                mtlVideoView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            ]
        )
    }
    
    func render(_ videoTrack: RTCVideoTrack) {
        self.videoTrack = videoTrack
        
        videoTrack.add(mtlVideoView)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        videoTrack?.remove(mtlVideoView)
    }
    
}

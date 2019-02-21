//
//  ViewController.swift
//  M3u8Demo
//
//  Created by heweisheng on 2018/12/3.
//  Copyright © 2018年 owen. All rights reserved.
//

import UIKit
import AVFoundation


class ViewController: UIViewController {

    var playerItem: AVPlayerItem!
    var playerLayer: AVPlayerLayer!
    var player: AVPlayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        view.backgroundColor = .white
        
        playerItem = M3u8ResourceLoader_OC.shared()?.playItem(with: "")
        
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: .new, context: nil)
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges), options: .new, context: nil)
        
        player = AVPlayer(playerItem: playerItem)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        playerLayer.contentsScale = UIScreen.main.scale
        playerLayer.frame = UIScreen.main.bounds
        view.layer.insertSublayer(playerLayer, at: 0)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AVPlayerItem.loadedTimeRanges) {
            // 缓冲进度 暂时不处理
        } else if keyPath == #keyPath(AVPlayerItem.status) {
            // 监听状态改变
            if playerItem.status == .readyToPlay {
                // 只有在这个状态下才能播放
                player.play()
            } else {
                print("加载异常")
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    deinit {
        playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
        playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges))
    }
}


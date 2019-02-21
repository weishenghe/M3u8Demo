//
//  M3u8ResourceLoader.swift
//  M3u8Demo
//
//  Created by heweisheng on 2018/12/3.
//  Copyright © 2018年 owen. All rights reserved.
//

import UIKit
import AVKit

/// 苹果网站上的一段m3u8链接数据,只是为了展示
let apple_m3u8 = "#EXTM3U\n#EXT-X-PLAYLIST-TYPE:EVENT\n#EXT-X-TARGETDURATION:10\n#EXT-X-VERSION:3\n#EXT-X-MEDIA-SEQUENCE:0\n#EXTINF:10, no desc\n#EXT-X-KEY:METHOD=AES-128,URI=\"ckey://devimages.apple.com/samplecode/AVARLDelegateDemo/BipBop_gear3_segmented/crypt0.key\", IV=0x3ff5be47e1cdbaec0a81051bcc894d63\nrdtp://devimages.apple.com/samplecode/AVARLDelegateDemo/BipBop_gear3_segmented/fileSequence0.ts\n#EXTINF:10, no desc\nrdtp://devimages.apple.com/samplecode/AVARLDelegateDemo/BipBop_gear3_segmented/fileSequence1.ts\n#EXTINF:10, no desc\nrdtp://devimages.apple.com/samplecode/AVARLDelegateDemo/BipBop_gear3_segmented/fileSequence2.ts\n#EXTINF:10, no desc\nrdtp://devimages.apple.com/samplecode/AVARLDelegateDemo/BipBop_gear3_segmented/fileSequence3.ts\n#EXTINF:10, no desc\nrdtp://devimages.apple.com/samplecode/AVARLDelegateDemo/BipBop_gear3_segmented/fileSequence4.ts\n#EXT-X-ENDLIST"

class M3u8ResourceLoader: NSObject, AVAssetResourceLoaderDelegate {

    /// 假的链接(乱写的，前缀反正不要http或者https，后缀一定要.m3u8，中间随便)
    fileprivate let m3u8_url_vir = "m3u8Scheme://abcd.m3u8"
    
    /// 真的链接
    fileprivate var m3u8_url: String = ""
    
    /// 单例
    fileprivate static let instance = M3u8ResourceLoader()
    
    /// 获取单例
    public static var shared: M3u8ResourceLoader {
        get {
            return instance
        }
    }
    
    /// 拦截代理方法
    /// true代表意思：系统，你要等等，不能播放，需要等我通知，你才能继续（相当于系统进程被阻断，直到收到了某些消息，才能继续运行）
    /// false代表意思：系统，你不要等，直接播放
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        
        /// 获取到拦截的链接url
        guard let url = loadingRequest.request.url?.absoluteString else {
            return false
        }
        
        /// 判断url请求是不是 ts (请求很频繁，因为一个视频分割成多个ts，直接放最前)
        if url.hasSuffix(".ts") {
            
            /// 处理的操作异步进行
            DispatchQueue.main.async {
                
                /// 在这里可以对ts链接进行各种处理，反正都是字符串，处理完毕后更换掉系统原先的请求，用新的url去重新请求
                let newUrl = url.replacingOccurrences(of: "rdtp", with: "http")
                
                if let url = URL(string: newUrl) {
                    
                    /// redirect: 更改(不懂？，百度翻译)，url就是新的url链接
                    loadingRequest.redirect = URLRequest(url: url)
                    
                    /// 302: 重定向(不懂？上百度)
                    loadingRequest.response = HTTPURLResponse(url: url, statusCode: 302, httpVersion: nil, headerFields: nil)
                    
                    /// 总之上面两步就是替换原先旧的网络请求，发起新的网络请求，如果不需要对ts链接进行任何操作的，屏蔽上两步
                    
                    /// 通知系统请求结束
                    loadingRequest.finishLoading()
                    
                } else {
                    
                    /// 通知系统请求结束，请求有误
                    self.finishLoadingError(loadingRequest)
                }
            }
            
            /// 通知系统等待
            return true
        }
        
        /// 判断url请求是不是 m3u8 (第一次发起的是m3u8请求，但是只请求一次，就放中间)
        if url == m3u8_url_vir {
            
            /// 处理的操作异步进行
            DispatchQueue.global().async {
                
                /// 在这里通过请求m3u8_url链接获取m3u8的数据，其实就是一段字符串(和上面的apple_m3u8字符串相似)，将字符串直接转为Data格式，可以直接从网上下载，直接转为Data，有一点必须注意，网络请求必须是同步的，不能为异步的
                
                if let data = self.M3u8Request(self.m3u8_url) {
                    DispatchQueue.main.async {
                        
                        /// 获取到原始m3u8字符串
                        if let m3u8String = String(data: data, encoding: .utf8) {
                            
                            /// 可以对字符串进行任意的修改，比如：
                            /// 1、后端对URI里面的链接进行过加密，可以在这里解密后修改替换回去
                            /// 2、URI链接没进行前缀替换，前缀还是http或者https的，系统请求之后是不会在代理方法里面拦截之后的操作，这需要我们手动替换前缀，上面的字符串前缀是替换过的(还不明白的自己看上面URI里面的链接)
                            /// 3、后端对ts链接进行过加密，同1，
                            
                            /// 当然不止这3种操作，还有很多，只要你能想到，但是这些修改操作后，都必须要保证修改后的字符串，进行格式化后，还是m3u8格式的字符串
                            
                            /// 还原m3u8字符串
                            let newM3u8String = m3u8String.replacingOccurrences(of: "替换字符串", with: "BipBop")
                            
                            /// 将字符串转化为数据
                            let data = newM3u8String.data(using: .utf8)!
                            
                            /// 将数据塞给系统
                            loadingRequest.dataRequest?.respond(with: data)
                            
                            /// 通知系统请求结束
                            loadingRequest.finishLoading()
                        }
                    }
                } else {
                    
                    DispatchQueue.main.async {
                        
                        /// 通知系统请求结束，请求有误
                        self.finishLoadingError(loadingRequest)
                    }
                }
            }
            
            /// 通知系统等待
            return true
        }
        
        /// 判断url请求是不是 key (key只请求一次，就放最后面)
        if !url.hasSuffix(".ts") && url != m3u8_url_vir {
            
            /// 处理的操作异步进行
            DispatchQueue.main.async {
                
                /// 获取key的数据，其实也是一串字符串，如果需要验证证书之类的，用Alamofire请求吧，同上面的m3u8一样，也要同步
                
                /// 在这里对字符串进行任意修改，解密之类的，同上
                let newUrl = url.replacingOccurrences(of: "ckey", with: "http")
                
                if let url = URL(string: newUrl), let data = try? Data(contentsOf: url) {
                    
                    /// 将数据塞给系统
                    loadingRequest.dataRequest?.respond(with: data)
                    
                    /// 通知系统请求结束
                    loadingRequest.finishLoading()
                    
                } else {
                    
                    /// 通知系统请求结束，请求有误
                    self.finishLoadingError(loadingRequest)
                }
            }
            
            /// 通知系统等待
            return true
        }
        
        /// 通知系统不用等待
        return false
    }
    
    /// 为了演示，模拟同步网络请求，网络请求获取的是数据Data
    func M3u8Request(_ url: String) -> Data? {
        let semaphore = DispatchSemaphore(value: 0)
        var result: Data? = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            /// 模拟后台替换字符串
            let newString = apple_m3u8.replacingOccurrences(of: "BipBop", with: "替换字符串")
            result = newString.data(using: .utf8)
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .distantFuture)
        return result
    }
    
    /// 请求失败的，全部返回Error
    func finishLoadingError(_ loadingRequest: AVAssetResourceLoadingRequest) {
        loadingRequest.finishLoading(with: NSError(domain: NSURLErrorDomain, code: 400, userInfo: nil) as Error)
    }
    
    /// 生成AVPlayerItem
    public func playerItem(with url: String) -> AVPlayerItem {
        
        /// 直接用虚假的m3u8(m3u8_url_vir)进行初始化，原因是：
        
        /// 外界传进来的url有可能不是以.m3u8结尾的，即不是m3u8格式的链接，如果直接用url进行初始化，那么代理方法拦截时，系统不会以m3u8文件格式去处理拦截的url，就是系统只会发起一次网络请求，之后的操作完全无效，而用虚假的m3u8链接，是为了混淆系统，让系统直接认为我们请求的链接就是m3u8格式的链接，那么代理里面的拦截就会执行下去，真正的请求链接通过赋值给变量m3u8_url进行保存，只需要在代理方法里面发起真正的链接请求就行了
        
        m3u8_url = url
        
        let urlAsset = AVURLAsset(url: URL(string: m3u8_url_vir)!, options: nil)
        urlAsset.resourceLoader.setDelegate(self, queue: .main)
        let item = AVPlayerItem(asset: urlAsset)
        if #available(iOS 9.0, *) {
            item.canUseNetworkResourcesForLiveStreamingWhilePaused = true
        }
        return item
    }
}



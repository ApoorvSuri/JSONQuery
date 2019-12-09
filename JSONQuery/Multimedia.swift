//
//  Multimedia.swift
//  JSONQuery
//
//  Created by Apoorv Suri on 29/07/16.
//  Copyright © 2016 Apoorv Suri. All rights reserved.
//

import Foundation
import UIKit

public class Multimedia {
    public enum MimeType: String {
        case ImageJpeg = "image/jpeg"
        case ImagePng = "image/png"
        case ImageGif = "image/gif"
        case Json = "application/json"
        case VideoMov = "video/mov"
        case VideoMp4 = "video/mp4"
        case Audio = "audio/wav"
        case Unknown = ""
        
        func getString() -> String! {
            switch self {
            case .ImagePng:
                fallthrough
            case .ImageJpeg:
                return "image/jpeg"
            case .ImageGif:
                return self.rawValue
            case .VideoMov:
                return "video/mov"
            case .VideoMp4:
                return "video/mp4"
            case .Json:
                return self.rawValue
            case .Audio:
                return self.rawValue
            case .Unknown:
                fallthrough
            default:
                return nil
            }
        }
    }
    
    let data: Data
    let mimeType: MimeType!
    let filename: String
    
    public init(data: Data, mimeType: MimeType, filename: String) {
        self.data = data
        self.mimeType = mimeType
        self.filename = filename
    }
    
    public init(pngImage: UIImage, filename: String) {
        data = pngImage.pngData()! 
        self.mimeType = MimeType.ImagePng
        self.filename = filename
    }
    
    public init(jpegImage: UIImage, compressionQuanlity: CGFloat, filename: String) {
        data = jpegImage.jpegData(compressionQuality: compressionQuanlity)!
        self.mimeType = MimeType.ImageJpeg
        self.filename = filename
    }
}

//
//  JSONQuery.swift
//  OUUT

import UIKit

/**
Tool used for API calls
 */
public struct JSONQuery {
    
    //MARK: SUCCESS & FAILURE CLOSURES
    
    public typealias WebServiceSuccess = (_ json : Any?) -> Void
    public typealias WebServiceFailure = (_ error : Error? , _ data : Any?) -> Void
    
    //MARK: TIME-OUT INTERVAL

    public func timeoutInterval() -> TimeInterval {
        return 60
    }
    
    public enum queryType : String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }
    
    public enum httpHeaderField : String {
        case contentType = "Content-Type"
        case accept = "Accept"
    }
    
    public init(){}
    
    /**
     METHOD #1 : Use this method for basic API calls like GET , POST , PUT , DELETE
     */
    public func request(withURLRequest urlRequest : URLRequest
        , successBlock : @escaping WebServiceSuccess
        , failureBlock : @escaping WebServiceFailure) {
        
        let configuration  = URLSessionConfiguration.default
        
        let session : URLSession = URLSession.init(configuration: configuration
            , delegate: nil
            , delegateQueue: OperationQueue.main)
        
        let dataTask = session.dataTask(with: urlRequest
            , completionHandler:{ data,response,error in
                
                self.handleResponse(withData: data
                    , response: response
                    , error: error
                    , successBlock: successBlock
                    , failureBlock: failureBlock)
        })
        
        dataTask.resume()
    }
    
    /**
     METHOD #2 : Use this method for Multipart API calls
     */
    public func request(withURLRequest urlRequest:URLRequest
        , data : Data
        , successBlock : @escaping WebServiceSuccess
        , failureBlock : @escaping WebServiceFailure){
        
        let configuration  = URLSessionConfiguration.default
        
        let session : URLSession = URLSession.init(configuration: configuration
            , delegate: nil
            , delegateQueue: OperationQueue.main)
        
        let uploadTask = session.uploadTask(with: urlRequest, from: data) { (data, response, error) in
            
            self.handleResponse(withData: data
                , response: response
                , error: error
                , successBlock: successBlock
                , failureBlock: failureBlock)
        }
        uploadTask.resume()
    }
    
    /**
     Use this method as a wrapper for METHOD #1
     */
    public func request(withUrl urlString : String
        , method : queryType
        , parameters : [String : Any]?
        , headers : Dictionary < String , Any >
        , successBlock : @escaping WebServiceSuccess
        , failureBlock : @escaping WebServiceFailure){
                
        let url = URL.init(string: urlString)
        
        var urlRequest = URLRequest.init(url: url!
            , cachePolicy: .useProtocolCachePolicy
            , timeoutInterval: timeoutInterval())
        
        urlRequest.httpMethod = method.rawValue
        
        if method == .post || method == .put {
            urlRequest.setValue("application/json"
                , forHTTPHeaderField: httpHeaderField.contentType.rawValue)
        }
        
        if headers.keys.count > 0 {
            for key in headers.keys {
                urlRequest.setValue(headers[key] as! String?, forHTTPHeaderField: key)
            }
        }
        
        if parameters != nil {
            do {
                let json = try JSONSerialization.data(withJSONObject: parameters ?? [:], options: .prettyPrinted)
                urlRequest.httpBody = json
            } catch let error {
                debugPrint("#Warning : JSONQuery - Error Attaching Parameters \(error.localizedDescription)")
            }
        }
        
        request(withURLRequest: urlRequest
            , successBlock: successBlock
            , failureBlock: failureBlock)
    }
    /**
     Use this method as a wrapper for METHOD #2
     */
    public func multipartRequest(withUrl urlString : String
        , method : queryType
        , parameters : [String : Any]?
        , headers : Dictionary < String , Any >
        , successBlock : @escaping WebServiceSuccess
        , failureBlock : @escaping WebServiceFailure )  {
        
        
        let (urlRequest, data) = self.urlRequestWithComponents(urlString: urlString
            , parameters: parameters!
            , HTTPMethod: method.rawValue)
        
        request(withURLRequest: urlRequest
            , data: data
            , successBlock: successBlock
            , failureBlock: failureBlock)
    }
    
    /**
     Use this method for handling response or an API Call
    */
    func handleResponse(withData data : Data?
        , response : URLResponse?
        , error : Error?
        , successBlock : @escaping WebServiceSuccess
        , failureBlock : @escaping WebServiceFailure){
        
        if response != nil {
            let statusCode = (response as! HTTPURLResponse).statusCode
            
            print("\n\nSTATUS CODE : \(statusCode)")
            
            if data != nil {
                do {
                    
                    let parsedData = try JSONSerialization.jsonObject(with: data!
                        , options: JSONSerialization.ReadingOptions.allowFragments)
                    
                    if error != nil {
                        DispatchQueue.main.async {
                            failureBlock(error , parsedData)
                        }
                    } else {
                        
                        if statusCode != 200 {
                            DispatchQueue.main.async {
                                failureBlock(error , parsedData)
                            }
                        } else {
                            DispatchQueue.main.async {
                                let nullRemovedData = JSONQuery.removeNullFromJSONData(parsedData)
                                successBlock(nullRemovedData)
                            }
                        }
                    }
                } catch let error {
                    failureBlock(error , nil)
                }
            } else if error != nil {
                failureBlock(error , nil)
            } else {
                debugPrint("#Warning : Bad Response \(String(describing: error?.localizedDescription))")
            }
        } else {
            failureBlock(error,nil)
        }
    }
    
    static func removeNullFromJSONData(_ JSONData: Any) -> Any {
        if JSONData as? NSNull != nil {
            return JSONData
        }
        var JSONObject: Any!

        if JSONData as? NSData != nil {
            JSONObject = try! JSONSerialization.data(withJSONObject: JSONData, options: JSONSerialization.WritingOptions.prettyPrinted)
        } else {
            JSONObject = JSONData
        }

        if JSONObject as? NSArray != nil {
            let mutableArray: NSMutableArray = NSMutableArray(array: JSONObject as! [Any], copyItems: true)
            let indexesToRemove: NSMutableIndexSet = NSMutableIndexSet()
            for index in 0 ..< mutableArray.count {
                let indexObject: Any = mutableArray[index]
                if indexObject as? NSNull != nil {
                    indexesToRemove.add(index)
                } else {
                    mutableArray.replaceObject(at: index, with: removeNullFromJSONData(indexObject))
                }
            }
            mutableArray.removeObjects(at: indexesToRemove as IndexSet)
            return mutableArray
            
        } else if JSONObject as? NSDictionary != nil {
            let mutableDictionary: NSMutableDictionary = NSMutableDictionary(dictionary: JSONObject as! [AnyHashable : Any], copyItems: true)

            for key in mutableDictionary.allKeys {
                let indexObject: Any = mutableDictionary[key] as Any

                if indexObject as? NSNull != nil {
                    mutableDictionary.removeObject(forKey: key)
                }
                else {
                    mutableDictionary.setObject(removeNullFromJSONData(indexObject), forKey: key as! NSCopying)
                }
            }
            return mutableDictionary
        } else {
            return JSONObject as Any
        }
    }
    
    /**
     Use this method for creating and returning a multi-part URL Request.
     */
   private func urlRequestWithComponents(urlString:String
        , parameters : [String : Any]
        , HTTPMethod: String) -> (URLRequest,Data) {
        
        let mutableURLRequest = NSMutableURLRequest(url: NSURL(string: urlString)! as URL)
        
        mutableURLRequest.httpMethod = HTTPMethod
        
        let boundaryConstant = "NET-POST-boundary-\(arc4random())-\(arc4random())"
        
        let contentType = "multipart/form-data;boundary="+boundaryConstant
        
        mutableURLRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
    
        let uploadData = NSMutableData()
        
        for (key, value) in parameters {
            
            uploadData.append("\r\n--\(boundaryConstant)\r\n".data(using: String.Encoding.utf8)!)
            
            if value is Multimedia {
                let postData = value as! Multimedia
                
                let filenameClause = " filename=\"\(postData.filename)\""
                let contentDispositionString = "Content-Disposition: form-data; name=\"\(key)\";\(filenameClause)\r\n"
                let contentDispositionData = contentDispositionString.data(using: String.Encoding.utf8)
                uploadData.append(contentDispositionData!)
                
                let contentTypeString = "Content-Type: \(postData.mimeType.getString()!)\r\n\r\n"
                let contentTypeData = contentTypeString.data(using: String.Encoding.utf8)!
                uploadData.append(contentTypeData)
                uploadData.append(postData.data)
                
            } else {
                uploadData.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)".data(using: String.Encoding.utf8)!)
            }
        }
        uploadData.append("\r\n--\(boundaryConstant)--\r\n".data(using: String.Encoding.utf8)!)
        return (mutableURLRequest as URLRequest, uploadData as Data)
    }
}

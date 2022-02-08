# FSCNetwork

FSCNetwork is a lightweight and hi customizable HTTP networking library. It is useful when you need to make many authenticated calls against an API network service.

## Install

To install the package, using [Swift Package Manager](https://swift.org/package-manager/), is enough to add the git link into the Package.swift file as described below.

```swift
.package(url: "https://github.com/Flying-Spaghetti-Code/FSCNetwork", .upToNextMajor(from: "1.0.0")),
```

## Usage

In order to create a set of network calls, you need to implement the NetworkRequest protocol . 

```swift
public protocol NetworkRequest{
    var url: String {get}
    var method: HTTPMethod {get}
    var body: Data? {get}
    var eTag: String? { get }
    var customHeaders: [String : String]? { get }
    var sessionDelegate: URLSessionDelegate & URLSessionTaskDelegate { get }
    func getETagDataIfAvailable(_ response: HTTPURLResponse, _ data: Data) -> Data?
    func isResponseValid(_ response: HTTPURLResponse, with networkManager: NetworkManager, completion: @escaping NetCallBack) -> Bool
}
```

the sugested way is to extend the protocol directly for all those elements that are always the same. For example the Entity Tag (ETag) handling.

```swift
// MARK: - ETagSupport
extension  NetworkRequest {

    var eTag: String? {
        //Return the stored etag for the request
        return loadEtag(forRequest: self)
    }

    func getETagDataIfAvailable(_ response: HTTPURLResponse, _ data: Data) -> Data? {

        // handle the cached data. PrsistenceManager is not part of the lib)
        // please ilplement your own persistency layer or download the fancy 
        // FSCPersistence at https://github.com/Flying-Spaghetti-Code/FSCPersistence

        if response.statusCode == 304, let savedData = PersistenceManager.loadData(for: self) {
            return savedData
        }
        else if PersistenceManager.loadData(for: self) == nil {
            PersistenceManager.clearData(for: self)
        }
        if response.allHeaderFields.keys.contains("Etag"), let etagValue = response.allHeaderFields["Etag"] as? String {
            PersistenceManager.save(etag: etagValue, forRequest: self)
            PersistenceManager.save(data: data, forRequest: self)
        }
        return nil
    }
}
```


### Authentication

If your network API service implement an oAuth 2.0 authentication protocol. you may handle it Enabling the authentication extending your networ request.

```swift
// MARK: - TokenHandling
extension NetworkRequest {

    // Enable the authentication
    var needAuthentication: Bool { return true }

    var token: String? {

        // put here the code to retrieve the last access token
        // from keychain or storage. For example: 

        guard let token = try? getAccessToken() else {
            return nil
        }
        return token
    }

    func refreshToken(callback: ((Bool) -> ())?) {

        // put here the code to renew the expired token and send the result to the callback block
        guard let token = refreshToken() else {
            callback?(false)
            return
        }

        callback?(true)
    }
}
```


### Setting up the calls

Than setup all the call. the simplest way is create an enum containing all the needed information.

```swift
// MARK: - custom requests
enum YourRequest {
    case fetchData
    case fetchgetchDataFor(id: String)
    case sendData(printJob: YourCodableObject)
    case delete(id: String)
}
```

and extend it implementing the NetworkRequest protocol

```swift
// MARK: - custom requests
extension YourRequest: NetworkRequest {

    //define urls
    var url: String {
        switch self {
            case .fetchData : return "https://yourapi/data"
            case .fetchgetchDataFor(let dataId: String) : return "https://yourapi/data/?id=\(dataId)"
            case .sendData : return "https://yourapi/send" 
            case .delete(let id) : retun "https://yourapi/delete/\(id)"
        }
    }

    //define custom headers
    var customHeaders: [String : String]? {

        var customHeaders = ["ClientVersion": "\(Bundle.appVersion)"]

        switch self {
            case .sendData(let data) : customHeaders["custom-data-id"] = data.id
            default: customHeaders["all-others-id"] = UUID().uuidString
        }

        return customHeaders
    }

    // define HTTP Methods
    var method: HTTPMethod {
        switch self {
            case .sendData: return .post
            case .delete: return .delete
            default:        return .get
        }
    }

    //Body to send if needed
    var body: Data? {
        switch self {
            case .printFile(let printJob): return printJob.toData()
            default: return nil
        }
    }

    func isResponseValid(_ response: HTTPURLResponse, with networkManager: NetworkManager, completion: @escaping NetCallBack) -> Bool {
        if isXCBStatusValid(response) {
            return true
        }
        handleRetry(networkManager: networkManager, completion: completion)
        return false
    }
}
```

if the client needs to check some custom header to validate the response, then implement a response validator function:

```swift
func isResponseValid(_ response: HTTPURLResponse, with networkManager: NetworkManager, completion: @escaping NetCallBack) -> Bool {

    guard let custom = response.allHeaderFields["Custom-field"] else {
        // maybe I want to retry
        networkManager.fire(request: self, completion: completion)
        return false
    }

    return true
}
```

### Firing and parsing

The library contains a built in generic parser for Codables which accept as parameters the Data result from the call and a callback's closure. it return back the decoded object or a `failedtoParse(body: String)`  Network Error.

```swift
func fetchData(completion: @escaping ((Result<YourCodableClass, NetworkError>) -> (Void))) {

    let parser = APIParser<YourCodableClass>()
    NetworkManager().fire(request: YourRequest.fetchData) { (result) -> (Void) in

        parser.parseResult(result, completion: completion)
    }
}
```

## Contributing

PRs accepted.

## License

MIT © Flying Spaghetti Code 

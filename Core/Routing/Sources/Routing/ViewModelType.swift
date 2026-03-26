import Foundation

/// MVVM ViewModel 프로토콜
public protocol ViewModelType: AnyObject, Observable {
    associatedtype Input
    associatedtype Output

    func transform(input: Input) -> Output
}

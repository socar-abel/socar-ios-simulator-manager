import Foundation

/// MVVM ViewModel 프로토콜
/// elecle-ios의 ViewModelType 패턴을 SwiftUI에 맞게 적용
public protocol ViewModelType: AnyObject, Observable {
    associatedtype Input
    associatedtype Output

    func transform(input: Input) -> Output
}

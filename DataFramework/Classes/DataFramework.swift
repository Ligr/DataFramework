import Foundation
import ReactiveSwift

public final class DataFramework {

    public static var httpErrors: Signal<Error, Never> {
        httpErrorsPrivate.output
    }

    internal static let httpErrorsPrivate = Signal<Error, Never>.pipe()

}

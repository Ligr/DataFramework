//
//  PageViewControllerDataSource.swift
//  DataFramework
//
//  Created by Aliaksandr on 11/14/18.
//

import UIKit
import ReactiveSwift

public enum PageViewControllerDataSource {

    public typealias ViewControllerFactory<T, V: UIViewController & IndexSupportable> = (UIPageViewController, T, V.IntexType) -> V

    public static func create<T, V: UIViewController & IndexSupportable>(data: DataView<T>, pageViewController: UIPageViewController, viewController: @escaping ViewControllerFactory<T, V>) -> UIPageViewControllerDataSource where V.IntexType == Int {
        return PageViewControllerDataSource_DataView(data: data, pageViewController: pageViewController, viewController: viewController)
    }

}

private final class PageViewControllerDataSource_DataView<T, V: UIViewController & IndexSupportable>: NSObject, UIPageViewControllerDataSource where V.IntexType == Int {

    private let data: DataView<T>
    private weak var pageViewController: UIPageViewController?
    private let viewController: PageViewControllerDataSource.ViewControllerFactory<T, V>
    private var updatesDisposable: Disposable?

    init(data: DataView<T>, pageViewController: UIPageViewController, viewController: @escaping PageViewControllerDataSource.ViewControllerFactory<T, V>) {
        self.data = data
        self.pageViewController = pageViewController
        self.viewController = viewController
        super.init()

        pageViewController.dataSource = self
        goToPage(at: 0, animated: false)

        updatesDisposable = data.updates.observeValues { [weak self] updates in
            // TODO: think about adding better updates handling
            self?.goToPage(at: 0, animated: false)
        }
    }

    deinit {
        updatesDisposable?.dispose()
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let itemView = viewController as? V else {
            return nil
        }
        let nextIndex = itemView.index + 1
        guard nextIndex < data.count else {
            return nil
        }
        let item = data[nextIndex]
        return self.viewController(pageViewController, item, nextIndex)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let itemView = viewController as? V else {
            return nil
        }
        let nextIndex = itemView.index - 1
        guard nextIndex >= 0 else {
            return nil
        }
        let item = data[nextIndex]
        return self.viewController(pageViewController, item, nextIndex)
    }

    private func goToPage(at index: Int, animated: Bool) {
        guard let pageViewController = pageViewController, index >= 0 && index < data.count else {
            self.pageViewController?.setViewControllers([], direction: .forward, animated: animated, completion: nil)
            return
        }
        let item = data[index]
        let controller = self.viewController(pageViewController, item, index)
        pageViewController.setViewControllers([controller], direction: .forward, animated: animated, completion: nil)
    }

}

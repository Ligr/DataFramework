//
//  CollectionViewDataSource.swift
//  DataFramework
//
//  Created by Alex on 5/8/18.
//  Copyright © 2018 Home. All rights reserved.
//

import UIKit
import ReactiveSwift

public enum CollectionViewDataSource {

    public typealias CellFactory<T> = (UICollectionView, IndexPath, T) -> UICollectionViewCell
    public typealias SupplementaryElementFactory = (UICollectionView, IndexPath, String) -> UICollectionReusableView

    public static func create<T>(data: DataView<T>, collectionView: UICollectionView, supplementaryElement: SupplementaryElementFactory? = nil, cell: @escaping CellFactory<T>) -> UICollectionViewDataSource {
        return CollectionViewDataSource_DataView(data: data, collectionView: collectionView, supplementaryElement: supplementaryElement, cell: cell)
    }

}

private class CollectionViewDataSource_DataView<T>: NSObject, UICollectionViewDataSource {

    private let data: DataView<T>
    private weak var collectionView: UICollectionView?
    private let cell: CollectionViewDataSource.CellFactory<T>
    private var updatesDisposable: Disposable?
    private let supplementaryElement: CollectionViewDataSource.SupplementaryElementFactory?

    init(data: DataView<T>, collectionView: UICollectionView, supplementaryElement: CollectionViewDataSource.SupplementaryElementFactory? = nil, cell: @escaping CollectionViewDataSource.CellFactory<T>) {
        self.data = data
        self.collectionView = collectionView
        self.cell = cell
        self.supplementaryElement = supplementaryElement
        super.init()

        collectionView.dataSource = self
        collectionView.reloadData()

        updatesDisposable = data.updates.observeValues { [weak self] updates in
            guard let strongSelf = self, let collectionView = strongSelf.collectionView else {
                return
            }
            if updates.count == 1 && updates[0] == .all {
                collectionView.reloadData()
            } else if updates.count > 0 {
                collectionView.performBatchUpdates({
                    for update in updates {
                        switch update {
                        case .delete(let index):
                            collectionView.deleteItems(at: [index])
                        case .insert(let index):
                            collectionView.insertItems(at: [index])
                        case .update(let index):
                            collectionView.reloadItems(at: [index])
                        case .move(let fromIndex, let toIndex):
                            collectionView.moveItem(at: fromIndex, to: toIndex)
                        case .all:
                            print("something wrong! .all should be single update")
                        }
                    }
                }, completion: nil)
            }
        }
    }

    deinit {
        updatesDisposable?.dispose()
        if collectionView?.dataSource === self {
            collectionView?.dataSource = CollectionViewDataSource_Empty.instance
            collectionView?.reloadData()
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.numberOfItemsInSection(section)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return cell(collectionView, indexPath, data[indexPath.item])
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return supplementaryElement?(collectionView, indexPath, kind) ?? UICollectionReusableView()
    }

}

private class CollectionViewDataSource_Empty: NSObject, UICollectionViewDataSource {

    static let instance = CollectionViewDataSource_Empty()

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return UICollectionViewCell()
    }

}

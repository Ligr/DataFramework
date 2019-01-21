//
//  TableViewDataSource.swift
//  DataFramework
//
//  Created by Alex on 5/7/18.
//  Copyright © 2018 Home. All rights reserved.
//

import UIKit
import ReactiveSwift

public enum TableViewDataSource {

    public typealias CellFactory<T> = (UITableView, IndexPath, T) -> UITableViewCell

    public static var empty: UITableViewDataSource {
        return TableViewDataSource_Empty.instance
    }

    public static func create<T>(data: DataView<T>, tableView: UITableView, cell: @escaping CellFactory<T>) -> UITableViewDataSource {
        return TableViewDataSource_DataView(data: data, tableView: tableView, cell: cell)
    }

}

private class TableViewDataSource_DataView<T>: NSObject, UITableViewDataSource {

    private let data: DataView<T>
    private weak var tableView: UITableView?
    private let cell: TableViewDataSource.CellFactory<T>
    private var updatesDisposable: Disposable?

    init(data: DataView<T>, tableView: UITableView, cell: @escaping TableViewDataSource.CellFactory<T>) {
        self.data = data
        self.tableView = tableView
        self.cell = cell
        super.init()

        tableView.dataSource = self
        tableView.reloadData()

        updatesDisposable = data.updates.observe(on: UIScheduler()).observeValues { [weak self] updates in
            guard let strongSelf = self, let tableView = strongSelf.tableView else {
                return
            }
            if updates.count == 1 && updates[0] == .all {
                tableView.reloadData()
            } else if updates.count > 0 {
                tableView.beginUpdates()
                for update in updates {
                    switch update {
                    case .delete(let index):
                        tableView.deleteRows(at: [index], with: .none)
                    case .insert(let index):
                        tableView.insertRows(at: [index], with: .none)
                    case .update(let index):
                        tableView.reloadRows(at: [index], with: .none)
                    case .move(let fromIndex, let toIndex):
                        tableView.moveRow(at: fromIndex, to: toIndex)
                    case .all:
                        print("something wrong! .all should be single update")
                    }
                }
                tableView.endUpdates()
            }
        }
    }

    deinit {
        updatesDisposable?.dispose()
        if tableView?.dataSource === self {
            tableView?.dataSource = TableViewDataSource_Empty.instance
            tableView?.reloadData()
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return data.numberOfSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.numberOfItemsInSection(section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cell(tableView, indexPath, data[indexPath])
    }

}

private class TableViewDataSource_Empty: NSObject, UITableViewDataSource {

    static let instance = TableViewDataSource_Empty()

    func numberOfSections(in tableView: UITableView) -> Int {
        return 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }

}

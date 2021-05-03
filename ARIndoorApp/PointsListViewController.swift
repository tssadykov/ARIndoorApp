//
//  PointsListViewController.swift
//  ARIndoorApp
//
//  Created by Timur Sadykov on 5/3/21.
//

import RxCocoa
import RxSwift
import UIKit

final class PointsListViewController: UIViewController {
    
    // MARK: - Public properties
    
    var onRoomSelect: Observable<Room> {
        return onRoomSelectImpl.asObservable()
    }
    
    // MARK: - Constructors
    
    init(rooms: [Room]) {
        self.rooms = rooms
        self.searchedRooms = rooms
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        apply(searchBar) {
            view.addSubview($0)
            $0.delegate = self
            
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
            $0.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
            $0.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        }
        
        apply(tableView) {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.topAnchor.constraint(equalTo: searchBar.bottomAnchor).isActive = true
            $0.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
            $0.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
            $0.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
            
            $0.dataSource = self
            $0.delegate = self
            $0.register(UITableViewCell.self, forCellReuseIdentifier: "room_cell")
            $0.backgroundColor = .white
        }
    }
    
    // MARK: - Private properties
    
    private var searchedRooms: [Room]
    private let rooms: [Room]
    private let tableView = UITableView()
    private let searchBar = UISearchBar()
    private let onRoomSelectImpl = PublishRelay<Room>()
}

extension PointsListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchedRooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "room_cell", for: indexPath)
        cell.textLabel?.text = searchedRooms[indexPath.row].name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        onRoomSelectImpl.accept(searchedRooms[indexPath.row])
    }
}

extension PointsListViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            searchedRooms = rooms
            searchBar.resignFirstResponder()
        } else {
            searchedRooms = rooms.filter { room in
                return room.name.range(of: searchText, options: .caseInsensitive, range: nil, locale: nil) != nil
            }
        }
        
        tableView.reloadData()
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.showsCancelButton = true
        return true
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.showsCancelButton = false
        return true
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

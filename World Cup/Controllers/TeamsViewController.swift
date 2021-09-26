//
//  TeamsViewController.swift
//  World Cup
//
//  Created by Cleopatra on 9/25/21.
//

import UIKit
import CoreData

class TeamsViewController: UIViewController {
	
	// MARK: - Properties
	
	lazy var tableView: UITableView = {
		let tableView = UITableView()
		tableView.dataSource = self
		tableView.delegate = self
		tableView.register(TeamTableViewCell.self, forCellReuseIdentifier: TeamTableViewCell.identifier)
		return tableView
	}()
	
	private var addButton = UIBarButtonItem(systemItem: .add)
	
	lazy var coreDataStack = CoreDataStack(modelName: "World_Cup")
	
	lazy var fetchedResultsController: NSFetchedResultsController<Team> = {
		/*
		The fetched results controller handles the coordination between Core Data and your table view, but it still
		needs you to provide an NSFetchRequest. Remember the NSFetchRequest class is highly customizable. It can take
		sort descriptors, predicates, etc.
		
		In this example, you get your NSFetchRequest directly from the Team class
		because you want to fetch all Team objects.
		
		If you want to use NSFetchedResultsController to populate a table view and have it know which managed
		object should appear at which index path, you can't just throw it a basic fetch request. a regular fetch
		request doesn't require a sort descriptor.
		
		Its minimum requirement is you set an entity description, and it will fetch all objects of that entity type.
		NSFetchedResultsController, however, requires at least one sort descriptor. Otherwise, how would it know the
		right order for your table view?
		*/
		let fetchRequest: NSFetchRequest<Team> = Team.fetchRequest()
		
		/*
		If you want to seperate fetched results using a section keyPath, the first sort descriptor's attribute
		must match the key path's attribute.
		*/
		let qualifyingZoneSortDescriptor = NSSortDescriptor(key: #keyPath(Team.qualifyingZone), ascending: true)
		let scoreSortDescriptor = NSSortDescriptor(key: #keyPath(Team.wins), ascending: false)
		let nameSortDescriptor = NSSortDescriptor(key: #keyPath(Team.teamName), ascending: true)
		
		fetchRequest.sortDescriptors = [qualifyingZoneSortDescriptor, scoreSortDescriptor, nameSortDescriptor]
		
		/*
		The initializer method for a fetched results controller takes four parameters: first up,
		the fetch request you just created.
		
		The second parameter is an instance of NSManagedObjectContext. Like NSFetchRequest, the fetched
		results controller class needs a managed object context to execute the fetch. It can't actually fetch
		anything by itself.
		
		The other two parameters are optional: secitonNameKeyPath and cacheName.
		
		The sectionNameKeyPath is to specify an attribute the fetched results controller should use to
		group the results and generate sections. How exactly are these sections generated? Each unique attribute
		value becomes a section. NSFetchedResultsController then groups its fetched results into these sections. In this
		case, it will generate sections for each unique value of qualifyingZone such as "Africa", "Asia", "Oceania" and so on.
		
		Note: sectionNameKeyPath takes a keyPath string. It can take the form of an attribute name such as qualifyingZone
		or teamName, or it can drill deep into a Core Data relationship, such as employee.address.street. Use the #keyPath
		syntax to defend against typos and stringly typed code.
		
		Specify a cache name to turn on NSFetchedResultsController's on-disk section cache to prevent from
		having to perform the operation of grouping teams into sections every time app runs. Keep in mind that this section
		cache is completely separate from Core Data's persistent store, where you persist the teams.
		
		On the second launch, NSFetchedResultsController reads directly from your cache. This saves a round trip
		to Core Data's persistent store, as well as the time needed to compute those sections.
		*/
		let fetchedResultsController = NSFetchedResultsController(
			fetchRequest: fetchRequest,
			managedObjectContext: coreDataStack.managedContext,
			sectionNameKeyPath: #keyPath(Team.qualifyingZone),
			cacheName: nil
		)
		
		/*
		NSFetchedResultsController can listen for changes in its result set and notify its delegate,
		NSFetchedResultsControllerDelegate. You can use this delegate to refresh the table view as needed anytime
		the underlying data changes.
		
		Note: A fetched results controller can only monitor changes made via the managed object context specified
		in its initializer. If you create a separate NSManagedObjectContext somewhere else in your app and start making
		changes there, your delegate method won't run until those changes have been saved and merged with the fetched
		results controller's context.
		*/
		fetchedResultsController.delegate = self
		
		return fetchedResultsController
	}()
	
	// MARK: - View Lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		setupNavigationBar()
		setupSubviews()
		
		importJSONDataIfNeeded()
		
		/*
		Here you execute the fetch request. If there's an error, you log the error to the console.
		
		But wait a minute... where are your fetched results? While fetching with NSFetchRequest returns
		an array of results, fetching with NSFetchedResultsController doesn't return anything.
		
		NSFetchedResultsController is both a wrapper around a fetch request and a container for its fetched results.
		You can get them either with the fetchedObjects property or the object(at:) method.
		*/
		do {
			try fetchedResultsController.performFetch()
		} catch let error as NSError {
			print("Fetching error: \(error), \(error.userInfo)")
		}
	}
	
	override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
		if motion == .motionShake {
			addTeam()
		}
	}
	
	// MARK: - View Lifecycle Helpers
	
	private func setupNavigationBar() {
		navigationItem.title = "World Cup"
		navigationItem.rightBarButtonItem = addButton
		navigationController?.navigationBar.prefersLargeTitles = true
	}
	
	private func setupSubviews() {
		view.addSubview(tableView)
	}
	
	// MARK: - View Overrides
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		tableView.frame = view.bounds
	}
	
}

// MARK: - Actions
extension TeamsViewController {
	
	func addTeam() {
		let alertController = UIAlertController(
			title: "Secret Team",
			message: "Add a new team",
			preferredStyle: .alert
		)
		
		alertController.addTextField { textField in
			textField.placeholder = "Team Name"
		}
		
		alertController.addTextField { textField in
			textField.placeholder = "Qualifying Zone"
		}
		
		let saveAction = UIAlertAction(
			title: "Save",
			style: .default
		) { [unowned self] _ in
			guard let nameTextField = alertController.textFields?.first,
						let zoneTextField = alertController.textFields?.last else {
				return
			}
			
			let team = Team(context: self.coreDataStack.managedContext)
			
			team.teamName = nameTextField.text
			team.qualifyingZone = zoneTextField.text
			team.imageName = "wenderland-flag"
			
			self.coreDataStack.saveContext()
		}
		
		alertController.addAction(saveAction)
		alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
		
		present(alertController, animated: true)
	}
	
}

// MARK: - Helper Methods
extension TeamsViewController {
	
	func importJSONDataIfNeeded() {
		let fetchRequest: NSFetchRequest<Team> = Team.fetchRequest()
		let count = try? coreDataStack.managedContext.count(for: fetchRequest)
		
		guard let teamCount = count,
					teamCount == 0 else {
			return
		}
		
		importJSONData()
	}
	
	func importJSONData() {
		let jsonURL = Bundle.main.url(forResource: "Teams", withExtension: "json")!
		let jsonData = try! Data(contentsOf: jsonURL)
		
		do {
			let jsonArray = try JSONSerialization.jsonObject(with: jsonData, options: [.allowFragments]) as! [[String: Any]]
			
			for jsonDictionary in jsonArray {
				let teamName = jsonDictionary["teamName"] as! String
				let qualifyingZone = jsonDictionary["qualifyingZone"] as! String
				let imageName = jsonDictionary["imageName"] as! String
				let wins = jsonDictionary["wins"] as! NSNumber
				
				// Initializes a managed object subclass and inserts it into the specified managed object context.
				let team = Team(context: coreDataStack.managedContext)
				team.teamName = teamName
				team.imageName = imageName
				team.qualifyingZone = qualifyingZone
				team.wins = wins.int32Value
			}
			
			coreDataStack.saveContext()
			print("Imported \(jsonArray.count) teams")
		} catch let error as NSError {
			print("Error importing teams: \(error)")
		}
	}
	
}

// MARK: - UITableViewDataSource
extension TeamsViewController: UITableViewDataSource {
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		/*
		The number of rows in each table view section corresponds to the number of objects in each fetched results
		controller section. You can query information about a fetched results controller section through its sections
		property.
		
		Note: The sections array contains opaque objects that implement the NSFetchedResultsSectionInfo protocol.
		This lightweight protocol provides information about a section, such as its title and number of objects.
		*/
		guard let sectionInfo = fetchedResultsController.sections?[section] else {
			return 0
		}
		
		return sectionInfo.numberOfObjects
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: TeamTableViewCell.identifier, for: indexPath) as! TeamTableViewCell
		configureCell(cell: cell, for: indexPath)
		return cell
	}
	
	func numberOfSections(in tableView: UITableView) -> Int {
		/*
		The number of sections in the table view corresponds to the number of sections in the fetched
		results controller. You may be wondering how this table view can have more than one section. Aren't
		you simply fetching and displaying all items?
		
		That's correct. You will only have one section, but keep in mind that NSFetchedResultsController can
		split up your data into sections. You can query information about a fetched results controller section
		through its sections property.
		*/
		return fetchedResultsController.sections?.count ?? 0
	}
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		let sectionInfo = fetchedResultsController.sections?[section]
		return sectionInfo?.name
	}
	
	func configureCell(cell: TeamTableViewCell, for indexPath: IndexPath) {
		/*
		You use the index path to grab the corresponding Team object from the fetched results controller. Next, you use
		the Team object to populate the cell's flag image, team name, and score label.
		
		Notice again there's no array variable holding your teams. They're all stored inside the fetched results controller
		and you process them via object(at:).
		*/
		let team = fetchedResultsController.object(at: indexPath)
		cell.teamLabel.text = team.teamName
		cell.scoreLabel.text = "Wins: \(team.wins)"
		
		if let imageName = team.imageName {
			cell.flagImageView.image = UIImage(named: imageName)
		} else {
			cell.flagImageView.image = nil
		}
	}
	
}

// MARK: - UITableViewDelegate
extension TeamsViewController: UITableViewDelegate {
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		/*
		When the user taps a row, you grab the Team corresponding to the selected index path, increment
		its number of wins and commit the change to Core Data's persistent store.
		
		You might think a fetched results controller is only good for fetching results from Core Data, but the
		Team objects you get back are the same old managed object subclasses. You can update their values and save
		as you've always done.
		*/
		let team = fetchedResultsController.object(at: indexPath)
		team.wins += 1
		coreDataStack.saveContext()
	}
	
}

// MARK: - NSFetchedResultsControllerDelegate
extension TeamsViewController: NSFetchedResultsControllerDelegate {
	
	func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView.beginUpdates()
	}
	
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
									didChange anObject: Any,
									at indexPath: IndexPath?,
									for type: NSFetchedResultsChangeType,
									newIndexPath: IndexPath?) {
		switch type {
		case .insert:
			tableView.insertRows(at: [newIndexPath!], with: .automatic)
			
		case .delete:
			tableView.deleteRows(at: [indexPath!], with: .automatic)
			
		case .update:
			let cell = tableView.cellForRow(at: indexPath!) as! TeamTableViewCell
			configureCell(cell: cell, for: indexPath!)
			
		case .move:
			tableView.deleteRows(at: [indexPath!], with: .automatic)
			tableView.insertRows(at: [newIndexPath!], with: .automatic)
			
		@unknown default:
			print("Unexpected NSFetchedResultsChangeType")
		}
	}
	
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
									didChange sectionInfo: NSFetchedResultsSectionInfo,
									atSectionIndex sectionIndex: Int,
									for type: NSFetchedResultsChangeType) {
		let indexSet = IndexSet(integer: sectionIndex)
		
		switch type {
		case .insert:
			tableView.insertSections(indexSet, with: .automatic)
			
		case .delete:
			tableView.deleteSections(indexSet, with: .automatic)
			
		default:
			break
		}
	}
	
	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView.endUpdates()
	}
	
}

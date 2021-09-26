//
//  TeamsViewController.swift
//  World Cup
//
//  Created by Cleopatra on 9/25/21.
//

import UIKit
import CoreData

/*
Key Points

- NSFetchedResultsController abstracts away most of the code needed to synchronize
  a table view with a Core Data store.
- At its core, NSFetchedResultsController is a wrapper around an NSFetchRequest and a
  container for its fetched results.
- A fetched results controller requires settings at least one sort descriptor on its fetch request.
  If you forget the sort descriptor, your app will crash.
- You can set a fetched result's controller sectionNameKeyPath to specify an attribute to group
  the results into table view sections. Each unique value corresponds to a different table view section.
*/
class TeamsViewController: UIViewController {
	
	// MARK: - Properties
	
	/*
	UITableViewDiffabledataSource is a generic for two types - String to represent section identifiers
	and NSManagedobjectID to represent the managed object identifiers of the different teams.
	*/
	private var dataSource: UITableViewDiffableDataSource<String, NSManagedObjectID>?
	
	lazy var tableView: UITableView = {
		let tableView = UITableView()
//		tableView.dataSource = self
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
		In the previous setup, the table view's data source was the view controller. The table view data
		source is now the diffable data source object that you set up earlier.
		*/
		dataSource = setupDataSource()
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
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		/*
		Here you execute the fetch request. If there's an error, you log the error to the console.
		
		But wait a minute... where are your fetched results? While fetching with NSFetchRequest returns
		an array of results, fetching with NSFetchedResultsController doesn't return anything.
		
		NSFetchedResultsController is both a wrapper around a fetch request and a container for its fetched results.
		You can get them either with the fetchedObjects property or the object(at:) method.
		*/
		do {
			/*
			Now you're using a diffable data source, and the first change happens when you call performFetch() on
			the results controller, which in turn calls controller(_: didChangeContentWith:), which "adds" in all of
			the rows from the first fetch. You call performFetch() in viewDidLoad(), which happens before the view is
			added to the window.
			
			To fix this, you need to perform the fetch later on. Remove the do/catch statement from viewDidLoad(),
			since that's now happening too early in the lifecycle. Implement viewDidAppear(_:), which is called after the
			view is added to the window.
			*/
			try fetchedResultsController.performFetch()
		} catch let error as NSError {
			print("Fetching error: \(error), \(error.userInfo)")
		}
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
	
		func configureCell(cell: UITableViewCell, for team: Team) {
			guard let cell = cell as? TeamTableViewCell else {
				return
			}
			
			cell.teamLabel.text = team.teamName
			cell.scoreLabel.text = "Wins: \(team.wins)"
			
			if let imageName = team.imageName {
				cell.flagImageView.image = UIImage(named: imageName)
			} else {
				cell.flagImageView.image = nil
			}
		}
	
	func setupDataSource() -> UITableViewDiffableDataSource<String, NSManagedObjectID> {
		UITableViewDiffableDataSource(
			tableView: tableView
		) { [unowned self] tableView, indexPath, managedObjectID in
			let cell = tableView.dequeueReusableCell(withIdentifier: TeamTableViewCell.identifier, for: indexPath)
			
			if let team = try? coreDataStack.managedContext.existingObject(with: managedObjectID) as? Team {
				self.configureCell(cell: cell, for: team)
			}
			
			return cell
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
		
		/*
		Here, you get the existing snapshot, tell it that your team needs reloading, then apply the updated
		snapshot back to the data source. The data source will then reload the cell for your team. When you save
		the context, that will trigger the fetched results controller's delegate method, which will apply any reording
		that needs to happen.
		*/
		if var snapshot = dataSource?.snapshot() {
			snapshot.reloadItems([team.objectID])
			dataSource?.apply(snapshot, animatingDifferences: false, completion: nil)
		}
		
		coreDataStack.saveContext()
	}
	
	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let sectionInfo = fetchedResultsController.sections?[section]
		
		let titleLabel = UILabel()
		titleLabel.text = sectionInfo?.name
		
		return titleLabel
	}
	
	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 20
	}
	
}

// MARK: - NSFetchedResultsControllerDelegate
extension TeamsViewController: NSFetchedResultsControllerDelegate {

	/*
	The old delegate methods you deleted told you when the changes were about to happen, what the changes were, and
	when the changes completed.
	
	These delegate calls lined up nicely with methods in UITableView such as beginUpdates() and endUpdates(), which
	you no longer need to call because you made the switch to diffable data sources.
	
	Instead, the new delegate method gives you a summary of any changes to the fetched result set
	and passes you a pre-computed snapshot that you can apply directly to your table view. So much simpler!
	*/
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
									didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
		let snapshot = snapshot as NSDiffableDataSourceSnapshot<String, NSManagedObjectID>
		dataSource?.apply(snapshot)
	}
}

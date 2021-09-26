//
//  TeamTableViewCell.swift
//  World Cup
//
//  Created by Cleopatra on 9/24/21.
//

import UIKit

class TeamTableViewCell: UITableViewCell {
	
	// MARK: - Properties
	
	static let identifier = String(describing: self)
	
	let flagImageView: UIImageView = {
		let imageView = UIImageView()
		imageView.translatesAutoresizingMaskIntoConstraints = false
		return imageView
	}()
	
	let teamLabel: UILabel = {
		let label = UILabel()
		label.font = .boldSystemFont(ofSize: 18)
		label.translatesAutoresizingMaskIntoConstraints = false
		return label
	}()
	
	let scoreLabel: UILabel = {
		let label = UILabel()
		label.font = .systemFont(ofSize: 14)
		label.translatesAutoresizingMaskIntoConstraints = false
		return label
	}()
	
	// MARK: - Init
	
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		
		setupSubviews()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: - Init Helpers
	
	private func setupSubviews() {
		contentView.addSubview(flagImageView)
		NSLayoutConstraint.activate([
			flagImageView.widthAnchor.constraint(equalToConstant: 120),
			flagImageView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 8),
			flagImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
			flagImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
		])
		
		/*
		Activating height constraint on flagImageView leads to breaking constraints. For example:
		
		(
		"<NSLayoutConstraint:0x6000025fa990 UIImageView:0x7f9880e40390.height == 100   (active)>",
		"<NSLayoutConstraint:0x6000025faa30 V:|-(8)-[UIImageView:0x7f9880e40390]   (active, names: '|':UITableViewCellContentView:0x7f9880e40bb0 )>",
		"<NSLayoutConstraint:0x6000025faa80 UIImageView:0x7f9880e40390.bottom == UITableViewCellContentView:0x7f9880e40bb0.bottom - 8   (active)>",
		"<NSLayoutConstraint:0x6000025f0870 'UIView-Encapsulated-Layout-Height' UITableViewCellContentView:0x7f9880e40bb0.height == 116.333   (active)>"
		)
		
		Will attempt to recover by breaking constraint
		<NSLayoutConstraint:0x6000025fa990 UIImageView:0x7f9880e40390.height == 100   (active)>
		
		Resolve breaking constraint by changing height constraint's priority property to .defaultHigh instead of default value required.
		*/
		let flagImageViewHeightAnchor = flagImageView.heightAnchor.constraint(equalToConstant: 90)
		flagImageViewHeightAnchor.priority = .defaultHigh
		flagImageViewHeightAnchor.isActive = true
		
		let stackView = UIStackView(arrangedSubviews: [teamLabel, scoreLabel])
		stackView.axis = .vertical
		stackView.translatesAutoresizingMaskIntoConstraints = false
		
		contentView.addSubview(stackView)
		NSLayoutConstraint.activate([
			stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
			stackView.leftAnchor.constraint(equalTo: flagImageView.rightAnchor, constant: 8),
			stackView.rightAnchor.constraint(equalTo: contentView.rightAnchor)
		])
	}
	
	// MARK: - View Lifecycle
	
	override func prepareForReuse() {
		super.prepareForReuse()
		
		teamLabel.text = nil
		scoreLabel.text = nil
		flagImageView.image = nil
	}
	
}

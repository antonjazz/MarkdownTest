//
//  User.swift
//  ScaleMate
//
//  Created by Anton Schwartz on 3/27/20.
//  Copyright © 2020 Anton Schwartz. All rights reserved.
//

import SwiftUI
import ShowTime
import StoreKit	// needed for when we ask for a review

class User {

	//MARK:- Persistent Properties

	/// set of all the `Act`s taken to date
	var actsTaken: Set<Act> = Act.set(fromString: UserDefaults.readString(settingName: .actsTaken))
	/// set of names of all the `HelpPage`s viewed to date
	var helpPagesViewed: Set<String> = HelpPage.viewedSet(fromString: UserDefaults.readString(settingName: .helpPagesViewed))
	/// date of the last decent session
	var prevSession: Date = UserDefaults.readDate(settingName: .prevSession) {
		willSet { UserDefaults.set(newValue, forSetting: .prevSession) }
	}
	/// number of total decent sessions a user has engaged in
	var numSessions: Int = UserDefaults.readInt(settingName: .numSessions) {
		willSet { UserDefaults.set(newValue, forSetting: .numSessions) }
	}
	/// date of the last time user was prompted to write a review
	var lastReview: Date = UserDefaults.readDate(settingName: .lastReview) {
		willSet { UserDefaults.set(newValue, forSetting: .lastReview) }
	}
	/// set to true when ok to ask user for a review
	/// - set to false again when user is asked
	var askForReview: Bool = UserDefaults.readBool(settingName: .askForReview) {
		willSet { UserDefaults.set(newValue, forSetting: .askForReview) }
	}


	var diminishedColoringChoice: YesNoAuto = UserDefaults.readYesNoAuto(settingName: .diminishedColoringChoice) {
		didSet {
			UserDefaults.set(diminishedColoringChoice.rawValue, forSetting: .diminishedColoringChoice)
		}
	}

	var roleDisplayStyle = RoleDisplayStyle(settingName: SavedValue.roleDisplayStyle) {
		willSet {
			updateDisplay()
			UserDefaults.set(newValue.rawValue, forSetting: .roleDisplayStyle)
		}
	}
	var showExtensions: Bool = UserDefaults.readBool(settingName: .showExtensions)  {
		willSet {
			updateDisplay()
			UserDefaults.set(newValue, forSetting: .showExtensions)
		}
	}
	var showNoteActions: Bool = UserDefaults.readBool(settingName: .showNoteActions)  {
		willSet {
			updateDisplay()
			UserDefaults.set(newValue, forSetting: .showNoteActions)
		}
	}
	var showTouchPlay: Bool = UserDefaults.readBool(settingName: .showTouchPlay)  {
		willSet {
			updateDisplay()
			UserDefaults.set(newValue, forSetting: .showTouchPlay)
		}
	}


	var hideScaleName: Bool = UserDefaults.readBool(settingName: .hideScaleName)  {
		willSet {
			updateDisplay()
			UserDefaults.set(newValue, forSetting: .hideScaleName)
		}
	}
	var animationSpeed: AnimationSpeed = UserDefaults.readEnum(settingName: .animationSpeed)  {
		willSet { UserDefaults.set(newValue.rawValue, forSetting: .animationSpeed) }
	}
	var repeatPlayback: Bool = UserDefaults.readBool(settingName: .repeatPlayback)  {
		willSet { UserDefaults.set(newValue, forSetting: .repeatPlayback) }
	}
	var showTouches = UserDefaults.readBool(settingName: .presentationMode) {
		willSet {
			ShowTime.enabled = newValue ? .always : .never

			UserDefaults.set(newValue, forSetting: .presentationMode)
		}
	}
	var whatToPlay: WhatToPlay = UserDefaults.readEnum(settingName: .whatToPlay) {
		willSet { UserDefaults.set(newValue.rawValue, forSetting: .whatToPlay) }
	}
	var audioTransposition: AudioTransposition = UserDefaults.readEnum( settingName: .audioTransposition) {
		willSet { UserDefaults.set(newValue.rawValue, forSetting: .audioTransposition) }
	}
	var demoScales: Bool {
		get { whatToPlay == .scales }
		set { whatToPlay = newValue ? .scales : .melodies }
	}
	var tempo = Double(UserDefaults.readInt(settingName: .tempo)) {
		willSet {
			updateDisplay()
			UserDefaults.set(Int(newValue), forSetting: .tempo)
		}
	}
	var showDoubleAccidentals: Bool = UserDefaults.readBool(settingName: .showDoubleAccidentals) {
		willSet {
			updateDisplay()
			if newValue == true {
				withAnimation(respellingAnimation) { showUncommonAccidentals = true }
			}
			UserDefaults.set(newValue, forSetting: .showDoubleAccidentals)
		}
	}
	var putRootOnTop: Bool = UserDefaults.readBool(settingName: .rootOnTop) {
		willSet {
			updateDisplay()
			UserDefaults.set(newValue, forSetting: .rootOnTop)
		}
	}
	var showUncommonAccidentals: Bool = UserDefaults.readBool(settingName: .showUncommonAccidentals) {	// Cb, E#, etc
		willSet {
			updateDisplay()
			if newValue == false {
				withAnimation(respellingAnimation) { showDoubleAccidentals = false }
			}
			UserDefaults.set(newValue, forSetting: .showUncommonAccidentals)
		}
	}
	
	var lastRunVersion: Version {
		get {
			if let result = lastRunVersionCache { return result }
			let initialValue: Version = Version(string: UserDefaults.readString(settingName: .lastRunVersion)) ?? Release.appVersion!
			// note: if user has never run v2 or later then we leave initial value to Version.zero so that update announcement will be presented.
			lastRunVersionCache = initialValue
			return initialValue
		}
		set {
			lastRunVersionCache = newValue
			UserDefaults.set(newValue.string, forSetting: .lastRunVersion)
		}
	}
	var lastRunVersionCache: Version?

	
	
	
	//MARK:- Transient Properties

	/// we consider this session "decent" if we have at least `Const.actionsTakenThreshold` performed `act`s
	var actionsTakenThisSession: Int = 0
	var didRevealName = false

	//MARK:- Computed Properties

	var animationDuration: Double { return animationSpeed.duration}
	var respellingAnimationDuration: Double { return animationDuration / 2 }

	var defaultAnimation: Animation { .easeInOut(duration: animationDuration) }
	var respellingAnimation: Animation { .easeInOut(duration: respellingAnimationDuration) }

	var quarterNoteDuration: Double { 60.0 / tempo }
	var eighthNoteDuration: Double { quarterNoteDuration / 2.0 }

	func updateDisplay() {
		NotificationCenter.default.post(name: Notification.Name.updateDisplay, object: nil)
	}

	/// Marks user as having taken action `act` so we don't suggest it going forward.
	/// - also keeps track of how many acts have been taken this session and calls
	///   `sessionBecameDescent` when it reaches threshold to consider it a decent session.
	func performed(act: Act) {
		if !actsTaken.contains(act) {
			actsTaken.insert(act)
			UserDefaults.set(Act.string(fromSet: actsTaken), forSetting: .actsTaken)
		}
		if Date() > prevSession + Const.sessionSpacing { // don't count unless new session
			actionsTakenThisSession += 1
			if actionsTakenThisSession == Const.actionsTakenThreshold {
				sessionBecameDecent()
			}
		}
	}

	/// Called when enough acts are performed to constitute a decent session.
	/// - Increments total number of sessions performed, sets new date, possibly sets
	/// `askForReview` so that review will be solicited at next opportune moment.
	func sessionBecameDecent() {
		numSessions += 1
		prevSession = Date()
		if numSessions == 6 || (numSessions > 0 && numSessions.isMultiple(of: 12)) {
			askForReview = true
		}
	}

	func resetActs() {
		actsTaken = []
		UserDefaults.set("", forSetting: .actsTaken)
		helpPagesViewed = []
		UserDefaults.set("", forSetting: .helpPagesViewed)
	}

	func visitedHelpPage(named pageName: String) {
		uiLog.debug("Visited Help Page: \(pageName, privacy: .public)")
		performed(act: .getHelp)
		if !helpPagesViewed.contains(pageName) {
			updateDisplay()
			helpPagesViewed.insert(pageName)
			UserDefaults.set(HelpPage.viewedString(fromSet: helpPagesViewed), forSetting: .helpPagesViewed)
			if helpPagesViewed.count == HelpPage.list.count {
				performed(act: .allHelpViewed)
				uiLog.debug("All help pages viewed.")
			}
		}

	}

	func possiblyAskForReview() {
		uiLog.debug("■ POSSIBLY ASK FOR REVIEW NOW")
		// make sure we've passed another threshold of decent sessions since the last time we asked.
		guard askForReview else { return }
		guard actsTaken.count >= Const.minActsForReview else { return }
		// don't ask with more than a cetrain frequency
		guard Date() > lastReview + Const.reviewSpacing else { return }
		// wait a second and ask for a review (if Apple deems it ok to)
		DispatchQueue.main.async {
			if let windowScene = UIApplication.shared.windows.first?.windowScene {
				self.askForReview = false
				delay(seconds: 1) {
					SKStoreReviewController.requestReview(in: windowScene)
				}
			}
		}
	}
}

enum WhatToPlay: String, CaseIterable, Identifiable {
	case scales
	case melodies

	var id: String { rawValue }
}

enum AudioTransposition: String, CaseIterable, Identifiable {
	case none
	case Bb = "B♭"
	case Eb = "E♭"

	var semitones: Int {
		switch self {
		case .Bb: return -2
		case .Eb: return 3
		default: return 0
		}
	}
	var id: String { rawValue }
}

enum YesNoAuto: String, CaseIterable, Identifiable  {
	case always
	case never
	case auto

	var id: String { rawValue }
}

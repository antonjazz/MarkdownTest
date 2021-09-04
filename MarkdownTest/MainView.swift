//
//  MainView.swift
//  ScaleMate
//
//  Created by Anton Schwartz on 2/20/20.
//  Copyright © 2020 Anton Schwartz. All rights reserved.
//

import SwiftUI
import MarkdownUI

struct MainView: View {

	@State var fileMarkdown: String = ""
	@State var stringMarkdown: String = "### This is the output of a string defined in the code."

	var body: some View {
		ScrollView {
			Markdown(Document(fileMarkdown))
				.background(Color.green)
				.padding(20)
		}
		.onAppear {
			let url = Bundle.main.url(forResource: "Assets.bundle/TestMarkdown", withExtension: "md")!
			fileMarkdown = try! String(contentsOf: url)
		}
	}
}


struct ContentView_Previews: PreviewProvider {
	static var previews: some View {

		return MainView()
	}
}

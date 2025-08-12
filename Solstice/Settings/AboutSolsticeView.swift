//
//  AboutSolsticeView.swift
//  Solstice
//
//  Created by Daniel Eden on 12/08/2025.
//

import SwiftUI

struct AboutSolsticeView: View {
	@Environment(\.colorScheme) private var colorScheme
	
	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			HStack(alignment: .firstTextBaseline) {
				HStack {
					Image(.solstice)
						.imageScale(.small)
					Text("Solstice")
				}
				.fontWeight(.medium)
				
				Spacer()
				
				if let buildVersionNumber = Bundle.main.buildVersionNumber,
					 let appVersionNumber = Bundle.main.releaseVersionNumber {
					Text("v\(appVersionNumber), #\(buildVersionNumber)")
						.font(.caption)
						.foregroundStyle(.secondary)
						.fontDesign(.monospaced)
				}
			}
			.font(.title2)
			
			Group {
				Text("Solstice is an app made by [Dan Eden](https://daneden.me), a designer and developer based in Manchester, England.")
				Text("Dan is prone to Seasonal Affective Disorder (SAD), a mood disorder often associated with the reduction in total daily sunlight hours during the darker months of the year. Solstice was created to help everyone look forward to brighter days.")
				
				Divider()
				
				NavigationLink(destination: FullStoryView()) {
					Text("Read more")
				}
				.padding(.vertical, 4)
			}
			.font(.subheadline)
			.foregroundStyle(.secondary)
		}
#if os(iOS)
		.blendMode(colorScheme == .light ? .plusDarker : .plusLighter)
		.listRowBackground(Color.clear.background(Color.accentColor.quinary))
#endif
	}
}

fileprivate struct FullStoryView: View {
	var aboutString: String {
		if let filepath = Bundle.main.path(forResource: "README", ofType: "md") {
			do {
				let contents = try String(contentsOfFile: filepath, encoding: .utf8)
				return contents
			} catch {
				print("Markdown file README.md could not be parsed")
				return "App info"
			}
		} else {
			print("Markdown file README.md not found")
			return "App info"
		}
	}
	
	var markdownLines: [AttributedString] {
		aboutString.split(whereSeparator: \.isNewline).suffix(from: 1).map { line in
			(try? AttributedString(markdown: String(line))) ?? AttributedString()
		}
	}
	
	var body: some View {
		Form {
			Section {
				VStack(alignment: .leading, spacing: 16) {
					ForEach(markdownLines, id: \.self) { line in
						Text(line)
							.multilineTextAlignment(.leading)
					}
				}
			}
			
			Section {
				Link(destination: URL(string: "https://github.com/ceeK/Solar")!) {
					Text("ceeK/Solar")
				}
			} header: {
				Text("Open Source Acknowledgements")
			}
		}
		.navigationTitle("About Solstice")
	}
}

#Preview {
	AboutSolsticeView()
}

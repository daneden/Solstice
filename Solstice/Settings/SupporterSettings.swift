//
//  SupporterSettings.swift
//  Solstice
//
//  Created by Daniel Eden on 24/02/2023.
//

import SwiftUI
import StoreKit

// MARK: In-App Purchase Product IDs
let iapProductIDs = Set([
	"me.daneden.Solstice.iap.tip.small",
	"me.daneden.Solstice.iap.tip.medium",
	"me.daneden.Solstice.iap.tip.large"
])

struct SupporterSettings: View {
	var aboutString: String {
		if let filepath = Bundle.main.path(forResource: "README", ofType: "md") {
			do {
				let contents = try String(contentsOfFile: filepath)
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
	
	var appStoreReviewURL: URL {
		URL(string: "https://apps.apple.com/app/id1547580907?action=write-review")!
	}
	
	@State var products: [Product] = []
	@State var latestTransaction: StoreKit.Transaction?
	@State var purchaseInProgress = false
	
	var body: some View {
#if os(iOS)
		NavigationStack {
			content
		}
#else
		content
#endif
	}
	
	@ViewBuilder
	var content: some View {
		Form {
			Section(header: Text("About Solstice and its maker")) {
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
			
			if !products.isEmpty {
				Section(header: Label("Leave a tip", systemImage: "heart")) {
					if latestTransaction != nil {
						Text("**Thank you so much for your support.** Feel free to leave another tip in the future if you’re feeling generous.")
							.padding(.vertical, 4)
					}
					
					ForEach(products.sorted(by: { lhs, rhs in
						lhs.price > rhs.price
					}), id: \.id) { product in
						Button(action: {
							Task.init {
								self.latestTransaction = try await purchaseProduct(product)
							}
						}) {
							LabeledContent {
								Text(product.displayPrice).foregroundColor(.secondary)
							} label: {
								Text(product.displayName)
							}
						}
					}
				}
				.symbolRenderingMode(.multicolor)
				.disabled(purchaseInProgress)
			}
			
			Link(destination: appStoreReviewURL) {
				Label("Leave a review", systemImage: "star")
			}
		}
		.navigationTitle("About Solstice")
		.task {
			await fetchProducts()
		}
	}
	
	func fetchProducts() async {
		do {
			self.products = try await Product.products(for: iapProductIDs)
		} catch {
			print("Unable to fetch products")
		}
	}
	
	func purchaseProduct(_ product: Product) async throws -> StoreKit.Transaction {
		purchaseInProgress = true
		
		let result = try await product.purchase()
		
		purchaseInProgress = false
		
		switch result {
		case .pending:
			throw PurchaseError.pending
		case .success(let verification):
			switch verification {
			case .verified(let transaction):
				await transaction.finish()
				
				return transaction
			case .unverified:
				throw PurchaseError.failed
			}
		case .userCancelled:
			throw PurchaseError.cancelled
		@unknown default:
			assertionFailure("Unexpected result")
			throw PurchaseError.failed
		}
	}
}

enum PurchaseError: Error {
	case pending, failed, cancelled
}

struct SupporterSettings_Previews: PreviewProvider {
    static var previews: some View {
        SupporterSettings()
    }
}

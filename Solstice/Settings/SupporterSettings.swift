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
	var appStoreReviewURL: URL {
		URL(string: "https://apps.apple.com/app/id1547580907?action=write-review")!
	}
	
	@State var products: [Product] = []
	@State var latestTransaction: StoreKit.Transaction?
	@State var purchaseInProgress = false
	
	var body: some View {
		Group {
			if !products.isEmpty {
				Section(header: Label("Leave a tip", systemImage: "heart")) {
					if latestTransaction != nil {
						Text("**Thank you so much for your support.** Feel free to leave another tip in the future if you’re feeling generous.")
							.padding(.vertical, 4)
					}
					
					ForEach(products.sorted { $0.price > $1.price }, id: \.id) { product in
						HStack {
							Text(product.displayName)
							
							Spacer()
							
							Button {
								Task {
									self.latestTransaction = try await purchaseProduct(product)
								}
							} label: {
								Text(product.displayPrice)
							}
							.buttonStyle(.bordered)
							#if os(iOS)
							.buttonBorderShape(.capsule)
							#endif
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
		.task {
			await fetchProducts()
		}
	}
	
	func fetchProducts() async {
		do {
			let products = try await Product.products(for: iapProductIDs)
			withAnimation {
				self.products = products
			}
		} catch {
			print("Unable to fetch products")
		}
	}
	
	func purchaseProduct(_ product: Product) async throws -> StoreKit.Transaction {
		purchaseInProgress = true
		
		#if os(visionOS)
		guard let scene = UIApplication.shared.connectedScenes.first else {
			throw PurchaseError.failed
		}
		let result = try await product.purchase(confirmIn: scene)
		#else
		
		let result = try await product.purchase()
		#endif
		
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

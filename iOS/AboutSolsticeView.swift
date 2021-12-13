//
//  AboutSolsticeView.swift
//  Solstice (iOS)
//
//  Created by Daniel Eden on 13/12/2021.
//

import SwiftUI
import StoreKit

struct AboutSolsticeView: View {
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
  
  @State var products: [Product] = []
  @State var latestTransaction: StoreKit.Transaction?
  
  var body: some View {
    List {
      Section(header: Text("About Solstice and its maker")) {
        VStack(alignment: .leading, spacing: 16) {
          ForEach(markdownLines, id: \.self) { line in
            Text(line)
              .multilineTextAlignment(.leading)
          }
        }.padding(.vertical, 8)
      }
      
      if products.count != 0 {
        Section(header: Label("Leave a tip", systemImage: "heart")) {
          if latestTransaction != nil {
            Text("**Thank you so much for your support.** Feel free to leave another tip in the future if you’re feeling generous.")
              .padding(.vertical, 4)
          }
          
          ForEach(products, id: \.id) { product in
            Button(action: {
              Task.init {
                self.latestTransaction = try await purchaseProduct(product)
              }
            }) {
              HStack {
                Text(product.displayName)
                Spacer()
                Text(product.displayPrice).foregroundColor(.secondary)
              }
            }
          }
        }
        .symbolRenderingMode(.multicolor)
        .transition(.slide
        )
      }
    }
    .listStyle(.grouped)
    .navigationTitle("About")
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
    let result = try await product.purchase()
    
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

struct AboutSolsticeView_Previews: PreviewProvider {
    static var previews: some View {
        AboutSolsticeView()
    }
}

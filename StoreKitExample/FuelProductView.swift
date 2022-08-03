//
//  FuelProductView.swift
//  StoreKitExample
//
//  Created by Artem Grebinik on 31.07.2022.
//

import SwiftUI
import StoreKit

struct FuelProductView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var store: Store
    @State private var errorTitle = ""
    @State private var isShowingError = false

    let fuel: Product
    let onPurchase: (Product) -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text("⛽️")
                .font(.system(size: 35))
            Text(fuel.description)
                .bold()
                .foregroundColor(Color.secondary)
            Spacer()
            buyButton
                .buttonStyle(BuyButtonStyle())
        }
        .alert(isPresented: $isShowingError, content: {
            Alert(title: Text(errorTitle), message: nil, dismissButton: .default(Text("Okay")))
        })
    }

    var buyButton: some View {
        Button(action: {
            Task {
                await purchase()
            }
        }) {
            Text(fuel.displayPrice)
                .foregroundColor(.white)
                .bold()
        }
    }

    @MainActor
    func purchase() async {
        do {
            if try await store.purchase(fuel) != nil {
                onPurchase(fuel)
            }
        } catch StoreError.failedVerification {
            errorTitle = "Your purchase could not be verified by the App Store."
            isShowingError = true
        } catch {
            print("Failed fuel purchase: \(error)")
        }
    }
}



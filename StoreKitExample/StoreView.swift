//
//  StoreView.swift
//  StoreKitExample
//
//  Created by Artem Grebinik on 26.07.2022.
//

import SwiftUI
import StoreKit

struct StoreView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        List {
            Section("Consumable & nonConsumable") {
                ForEach(store.rockets) { product in
                    NavigationLink {
                        DetailView(product: product).environmentObject(store)
                    } label: {
                        ListCellView(product: product)
                    }
                }
            }
            .listStyle(GroupedListStyle())

            SubscriptionsView()

            Section("Non-Renewing Subscription") {
                ForEach(store.nonRenewables) { product in
                    NavigationLink {
                        DetailView(product: product).environmentObject(store)
                    } label: {
                        ListCellView(product: product)
                    }
                }
            }

//            Button("Restore Purchases", action: {
//                Task {
//                    //This call displays a system prompt that asks users to authenticate with their App Store credentials.
//                    //Call this function only in response to an explicit user action, such as tapping a button.
//                    try? await AppStore.sync()
//                }
//            })

        }
        .navigationTitle("Shop")
    }
}



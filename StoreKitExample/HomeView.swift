//
//  ContentView.swift
//  StoreKitExample
//
//  Created by Artem Grebinik on 25.07.2022.
//

import SwiftUI
import StoreKit

struct HomeView: View {
    @StateObject var store: Store = Store()
    
    @State var shouldNavigateToShopingCart: Bool = false
    var body: some View {
        NavigationView {
            List {
                //MARK: Consumable & nonConsumable Section
                Section("Consumable & nonConsumable") {
                    if !store.purchasedRockets.isEmpty {
                        ForEach(store.purchasedRockets) { product in
                            NavigationLink {
                                RocketView(product: product).environmentObject(store)                                
                            } label: {
                                ListCellView(product: product)
                            }
                        }
                    } else {
                        shopingCartNavigationView()
                    }
                }
                
                //MARK: Subscriptions Section
                Section("Renewable & NonRenewable Subscriptions") {
                    if !store.purchasedNonRenewableSubscriptions.isEmpty || !store.purchasedSubscriptions.isEmpty {
                        ForEach(store.purchasedNonRenewableSubscriptions) { product in
                            NavigationLink {
                                subscriptionDetail(product: product)
                            } label: {
                                ListCellView(product: product)
                            }
                        }
                        ForEach(store.purchasedSubscriptions) { product in
                            NavigationLink {
                                subscriptionDetail(product: product)
                            } label: {
                                ListCellView(product: product)
                            }
                        }
                        
                    } else {
                        if let subscriptionGroupStatus = store.subscriptionGroupStatus {
                            if subscriptionGroupStatus == .expired || subscriptionGroupStatus == .revoked {
                                Text("Welcome Back! \nHead over to the shop to get started!")
                            } else if subscriptionGroupStatus == .inBillingRetryPeriod {
                                //The best practice for subscriptions in the billing retry state is to provide a deep link
                                //from your app to https://apps.apple.com/account/billing.
                                Text("Please verify your billing details.")
                            }
                        } else {
                            shopingCartNavigationView()
                        }
                    }
                }
                
                Section("Shop") {
                    shopingCartNavigationCell()
                }
            }
            .navigationTitle("StoreKit 2 Demo")
        }
    }
}




extension HomeView {
    
    func subscriptionDetail(product: Product) -> some View {
        ScrollView {
            
            VStack {
                Text(product.displayName)
                    .font(.headline)
                    .padding([.bottom], 100)
                Image(product.id)
                    .resizable()
                    .padding()
                    .scaledToFit()
                    
                if product.type == .autoRenewable {
                    Text("Provide ongoing access to content, services, or premium features in your app. People are charged on a recurring basis until they decide to cancel. Common use cases include access to media or libraries of content (such as video, music, or articles), software as a service (such as cloud storage, productivity, or graphics and design), education, and more. Auto-renewable subscriptions can offer Family Sharing.")
                        .bold()
                        .padding()
                }else if product.type == .nonRenewable {
                    Text("Provide access to services or content for a limited duration, such as a season pass to in-game content. This type of subscription doesn’t renew automatically, so people need to purchase a new subscription once it concludes if they want to retain access.")
                        .bold()
                        .padding()
                }else {
                    Text("Sample Text")
                }
            }
        }
    }
    
    func shopingCartNavigationCell() -> some View {
        NavigationLink {
            StoreView().environmentObject(store)
        } label: {
            Label("Shop", systemImage: "cart")
        }
        .foregroundColor(.white)
        .listRowBackground(Color.blue)
    }
    
    func shopingCartNavigationView() -> some View {
        
        NavigationLink {
            StoreView().environmentObject(store)
        } label: {
            VStack {
                Text("You don't own any car products.")
                    .bold()
                    .padding()
                Text("Head over to the shop to get started!")
                    .foregroundColor(.blue)
            }
        }
    }
}




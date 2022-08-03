//
//  FuelStoreView.swift
//  StoreKitExample
//
//  Created by Artem Grebinik on 31.07.2022.
//

import SwiftUI
import StoreKit

struct FuelStoreView: View {
    let fuels: [Product]
    let onPurchase: (Product) -> Void
    
    var body: some View {
        
        VStack {
            Text("Give your rocket a boost!")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding()
            
            List {
                Section("Buy consumable product") {
                    ForEach(fuels, id: \.id) { fuel in
                        FuelProductView(fuel: fuel, onPurchase: onPurchase)
                            .frame(height: 75, alignment: .center)
                    }
                }
            }
        }
    }
}

//
//  RocketView.swift
//  StoreKitExample
//
//  Created by Artem Grebinik on 27.07.2022.
//

import SwiftUI
import StoreKit

struct RocketView: View {
    @EnvironmentObject var store: Store

    @State private var showingSubview = false
    @State private var isFuelStoreShowing = false

    let product: Product

    init(product: Product) {
        self.product = product
    }
    var body: some View {
        ZStack {
            Image("space_bg")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: 0) {
                Spacer()
                Image(product.id)
                    .resizable()
                    .frame(width: 250, height: 250)
                    .offset(y: showingSubview ? -(UIScreen.main.bounds.height * 0.6) : 0)
                
                    Text("🔥")
                        .rotationEffect(.degrees(180))
                        .font(.system(size: showingSubview ? 75: 0))
                        .offset(y: showingSubview ? -(UIScreen.main.bounds.height * 0.6) : 0)
                        .opacity(showingSubview ? 100 : 0)
                
            }
            if product.type == .nonConsumable, !store.fuel.isEmpty {
                fuelView
            }
        }
        .sheet(isPresented: $isFuelStoreShowing) {
            FuelStoreView(fuels: store.fuel) { fuel in
                withAnimation {
                    isFuelStoreShowing = false
                }
                storeConsumable(fuel)
            }
        }
    }
    
    
    var fuelView: some View {
        VStack {
            Spacer()
            HStack {
                FuelSupplyView(fuels: store.fuel, consumedFuel: { fuel in
                    launchRocket()
                })
                .padding()
                Spacer()
                
                Button {
                    isFuelStoreShowing = true
                } label: {
                    VStack {
                        Image("station")
                            .resizable()
                            .frame(width: 75, height: 75, alignment: .center)
                            .scaledToFit()
                            .padding(5)
                        
                        Text("Petrol Station")
                            .font(.system(size: 14))
                            .bold()
                            .foregroundColor(.white)
                    }
                }.padding()
            }
        }
    }
    
    fileprivate func launchRocket() {
        withAnimation(.easeOut) {
            showingSubview.toggle()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeIn) {
                    showingSubview.toggle()
                }
            }
        }
    }
    fileprivate func storeConsumable(_ purchasedFuel: Product) {
        let availableFuels = UserDefaults.standard.integer(forKey: purchasedFuel.id)
        UserDefaults.standard.set(availableFuels + 1, forKey: purchasedFuel.id)
    }
}


import StoreKit
enum FuelKey: String {
    case liquidOxygen = "consumable.fuel.liquidOxygen"
    case liquidHydrogen = "consumable.fuel.liquidHydrogen"
    case liquidMethane = "consumable.fuel.liquidMethane"
}

struct FuelSupplyView: View {
    @EnvironmentObject var store: Store

    @AppStorage(FuelKey.liquidOxygen.rawValue) var liquidOxygen = 0
    @AppStorage(FuelKey.liquidHydrogen.rawValue) var liquidHydrogen = 0
    @AppStorage(FuelKey.liquidMethane.rawValue) var liquidMethane = 0

    let fuels: [Product]
    let consumedFuel: (Product) -> Void
    
    var body: some View {
        VStack {
            Text("Fuel Reserve!")
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .padding([.bottom])
            
            VStack(spacing: 15) {
                ForEach(fuels, id: \.id) { fuel in
                    Button(action: {
                        consume(fuel: fuel)
                        consumedFuel(fuel)
                    }) {
                        let fuelAmount = amount(for: fuel)
                        let hasFuel = (fuelAmount > 0)
                        VStack {
                            Text(fuel.description)
                                .font(.system(size: 12))
                                .foregroundColor(hasFuel ? Color.white : .gray)
                                .bold()

                            Text("⛽️ \(fuelAmount)")
                                .padding()
                                .clipShape(Rectangle())
                                .background(Color.secondary)
                                .foregroundColor(hasFuel ? Color.white : .red)
                                .cornerRadius(5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(hasFuel ? Color.green : .red, lineWidth: hasFuel ? 3 : 1)
                            )
                            
                        }
                    }
                    .disabled(amount(for: fuel) == 0)
                }
            }
        }
    }
    
    fileprivate func amount(for fuel: Product) -> Int {
        switch fuel.id {
        case FuelKey.liquidOxygen.rawValue: return liquidOxygen
        case FuelKey.liquidHydrogen.rawValue: return liquidHydrogen
        case FuelKey.liquidMethane.rawValue: return liquidMethane
        default: return 0
        }
    }

    fileprivate func consume(fuel: Product) {
        switch fuel.id {
        case FuelKey.liquidOxygen.rawValue:
            if liquidOxygen > 0 {
                liquidOxygen -= 1
            }
        case FuelKey.liquidHydrogen.rawValue:
            if liquidHydrogen > 0 {
                liquidHydrogen -= 1
            }
        case FuelKey.liquidMethane.rawValue:
            if liquidMethane > 0 {
                liquidMethane -= 1
            }
        default: return
        }
    }
}


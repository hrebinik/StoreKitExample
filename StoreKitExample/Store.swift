//
//  Store.swift
//  StoreKitExample
//
//  Created by Artem Grebinik on 25.07.2022.
//

import Foundation
import StoreKit

typealias RenewalInfo = StoreKit.Product.SubscriptionInfo.RenewalInfo

extension Date {
    func formattedDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy"
        return dateFormatter.string(from: self)
    }
}


class Store: ObservableObject {
    @Published private(set) var rockets: [Product]
    @Published private(set) var fuel: [Product]
    @Published private(set) var subscriptions: [Product]
    @Published private(set) var nonRenewables: [Product]
    
    @Published private(set) var purchasedRockets: [Product] = []
    @Published private(set) var purchasedNonRenewableSubscriptions: [Product] = []
    @Published private(set) var purchasedSubscriptions: [Product] = []
    
    @Published private(set) var subscriptionGroupStatus: StoreKit.Product.SubscriptionInfo.RenewalState?
  
    var updateListenerTask: Task<Void, Error>? = nil

    private let productIds: Set<ProductId>

    var hasPurchasedProducts: Bool {
        !(purchasedRockets.isEmpty && purchasedNonRenewableSubscriptions.isEmpty && purchasedSubscriptions.isEmpty)
    }
    
    init() {
        productIds = StoreConfiguration.readConfigFile() ?? []

        //Initialize empty products, and then do a product request asynchronously to fill them in.
        rockets = []
        fuel = []
        subscriptions = []
        nonRenewables = []
        updateListenerTask = listenForTransactions()

        Task {
            //During store initialization, request products from the App Store.
            await requestProducts()

            //Deliver products that the customer purchases.
            await updateCustomerProductStatus()
        }
    }
    
    @MainActor func requestProducts() async {
        do {
            //Request products from the App Store using the identifiers that the Products.plist file defines.
                    
            let storeProducts = try await Product.products(for: productIds)

            var newRockets: [Product] = []
            var newFuel: [Product] = []
            var newSubscriptions: [Product] = []
            var newNonRenewables: [Product] = []
            
            for product in storeProducts {
                switch product.type {
                case .consumable:
                    newFuel.append(product)
                case .nonConsumable:
                    newRockets.append(product)
                case .autoRenewable:
                    newSubscriptions.append(product)
                case .nonRenewable:
                    newNonRenewables.append(product)
                default:
                    //Ignore this product.
                    print("Unknown product")
                }
            }
            
            //Sort each product category by price, lowest to highest, to update the store.
            rockets = newRockets.sorted(by: { return $0.price < $1.price })
            fuel = newFuel.sorted(by: { return $0.price < $1.price })
            subscriptions = newSubscriptions.sorted(by: { return $0.price < $1.price })
            nonRenewables = newNonRenewables.sorted(by: { return $0.price < $1.price })
        } catch {
            print("Failed product request from the App Store server: \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws -> Transaction? {
        //Begin purchasing the `Product` the user selects.
                
        let result = try await product.purchase()
        
        //account token
//        let result = try await product.purchase(options: [.appAccountToken(UUID())])
        
        switch result {
        case .success(let verification):
            //Check whether the transaction is verified. If it isn't,
            //this function rethrows the verification error.
            let transaction = try checkVerified(verification)

            //The transaction is verified. Deliver content to the user.
            await updateCustomerProductStatus()

            //Always finish a transaction.
            await transaction.finish()

            return transaction
        case .userCancelled, .pending:
            return nil
        default:
            return nil
        }
    }
    
    func isPurchased(_ product: Product) async throws -> Bool {
        //Determine whether the user purchases a given product.

        switch product.type {
        case .nonRenewable:
            return purchasedNonRenewableSubscriptions.contains(product)
        case .nonConsumable:
            return purchasedRockets.contains(product)
        case .autoRenewable:
            return purchasedSubscriptions.contains(product)
        default:
            return false
        }
    }
    
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        //Check whether the JWS passes StoreKit verification.
        switch result {
        case .unverified:
            //StoreKit parses the JWS, but it fails verification.
            throw StoreError.failedVerification
        case .verified(let safe):
            //The result is verified. Return the unwrapped value.
            return safe
        }
    }
    
    @MainActor
    func updateCustomerProductStatus() async {
        
        var purchasedRockets: [Product] = []
        var purchasedSubscriptions: [Product] = []
        var purchasedNonRenewableSubscriptions: [Product] = []

        //Iterate through all of the user's purchased products.
        for await result in Transaction.currentEntitlements {
            do {
                //Check whether the transaction is verified. If it isn’t, catch `failedVerification` error.
                let transaction = try checkVerified(result)

                //Check the `productType` of the transaction and get the corresponding product from the store.
                switch transaction.productType {
                case .nonConsumable:
                    if let rocket = rockets.first(where: { $0.id == transaction.productID }) {
                        purchasedRockets.append(rocket)
                    }
                case .nonRenewable:
                    if let nonRenewable = nonRenewables.first(where: { $0.id == transaction.productID }),
                       transaction.productID == "nonRenewing.standard" {
                        //Non-renewing subscriptions have no inherent expiration date, so they're always
                        //contained in `Transaction.currentEntitlements` after the user purchases them.
                        //This app defines this non-renewing subscription's expiration date to be one year after purchase.
                        //If the current date is within one year of the `purchaseDate`, the user is still entitled to this
                        //product.
                        let currentDate = Date()
                        let expirationDate = Calendar(identifier: .gregorian).date(byAdding: DateComponents(year: 1),
                                                                   to: transaction.purchaseDate)!

                        if currentDate < expirationDate {
                            purchasedNonRenewableSubscriptions.append(nonRenewable)
                        }
                    }
                case .autoRenewable:
                    if let subscription = subscriptions.first(where: { $0.id == transaction.productID }) {
                        purchasedSubscriptions.append(subscription)
                    }
                default:
                    break
                }
            } catch {
                print()
            }
        }

        //Update the store information with the purchased products.
        self.purchasedRockets = purchasedRockets
        self.purchasedNonRenewableSubscriptions = purchasedNonRenewableSubscriptions

        //Update the store information with auto-renewable subscription products.
        self.purchasedSubscriptions = purchasedSubscriptions

        //Check the `subscriptionGroupStatus` to learn the auto-renewable subscription state to determine whether the customer
        //is new (never subscribed), active, or inactive (expired subscription). This app has only one subscription
        //group, so products in the subscriptions array all belong to the same group. The statuses that
        //`product.subscription.status` returns apply to the entire subscription group.
        subscriptionGroupStatus = try? await subscriptions.first?.subscription?.status.first?.state
    }
    
    
    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            //Iterate through any transactions that don't come from a direct call to `purchase()`.
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)

                    //Deliver products to the user.
                    await self.updateCustomerProductStatus()

                    //Always finish a transaction.
                    await transaction.finish()
                } catch {
                    //StoreKit has a transaction that fails verification. Don't deliver content to the user.
                    print("Transaction failed verification")
                }
            }
        }
    }
    
    //Get a subscription's level of service using the product ID.
    func tier(for productId: String) -> SubscriptionTier {
        switch productId {
        case "subscription.standard":
            return .standard
        case "subscription.premium":
            return .premium
        case "subscription.pro":
            return .pro
        default:
            return .none
        }
    }
}

public enum StoreError: Error {
    case failedVerification
}

public enum SubscriptionTier: Int, Comparable {
    case none = 0
    case standard = 1
    case premium = 2
    case pro = 3

    public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

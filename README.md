# StoreKitExample
This is a simple application that visually represents the types of in-app purchases as well as how to add them to the application and make purchases
You can find more information in a [presentation](https://docs.google.com/presentation/d/1l--J1RvgIcTEqEzWob0YgtxBODmm56f_7b2c8IMPBJQ/edit?usp=sharing) and [video](https://chiswdevelopment.sharepoint.com/:v:/s/iOSteam/Eep44xuBF7ZAkMdSdLN8IbsBOfdoF_826PFy0OOWRTNr7g?e=TBwiVj).

## Product type
###### Consumable
Provide different types of consumables, such as lives or gems used to further progress in a game, boosts in a dating app to increase profile visibility, or digital tips for creators within a social media app. Consumable in-app purchases are depleted as they’re used and can be purchased again. They’re frequently offered in apps and games that use the freemium business model.

```static let consumable: Product.ProductType```


###### Non-consumable
>Provide non-consumable, premium features that are purchased once and don’t expire. Examples include additional filters in a photo app, extra brushes in an illustration app, or cosmetic items in a game. Non-consumable in-app purchases can offer Family Sharing.

```static let nonConsumable: Product.ProductType```

###### Auto-renewable subscriptions
>Provide ongoing access to content, services, or premium features in your app. People are charged on a recurring basis until they decide to cancel. Common use cases include access to media or libraries of content (such as video, music, or articles), software as a service (such as cloud storage, productivity, or graphics and design), education, and more. Auto-renewable subscriptions can offer Family Sharing.

```static let autoRenewable: Product.ProductType```

###### Non-renewable subscriptions
>Provide access to services or content for a limited duration, such as a season pass to in-game content. This type of subscription doesn’t renew automatically, so people need to purchase a new subscription once it concludes if they want to retain access.


## Fetching products
The first step that’s required before a user can purchase anything is to fetch the app’s products from StoreKit. This can be done quite simply by using the request method that’s available on the new Product struct:

```Ruby
typealias ProductId = String

let productIds: Set<ProductId>

func fetchProducts() async throws -> [Product] {
    let storeProducts = try await Product.products(for: productIds)
    
    return storeProducts
}
```
The following example illustrates calling `products(for:)` on a Product value and filtering by ***Product type***
```Ruby
@MainActor func requestProducts() async {
    do {
        let storeProducts = try await Product.products(for: productIds)

        for product in storeProducts {
            switch product.type {
            case .consumable: break
            case .nonConsumable:break
            case .autoRenewable:break
            case .nonRenewable:break
            default:
                print("Unknown product")
            }
        }
    } catch {
        print("Failed product request from the App Store server: \(error)")
    }
}
```
## Performing a transaction
Once we have downloaded the product information from StoreKit, we can do many things with it, such as displaying a custom user interface where users can pick products to purchase. When the user chooses to buy a product, we can simply call the purchase method in order to start the purchasing process:

```Ruby
func purchase(_ product: Product) async throws -> Transaction {

    let result = try await product.purchase()
}
```
#### Apply an app account token to a purchase.
The app account token will persist in the resulting `Transaction` from a purchase.
Parameter token: A UUID that associates the purchase with an account in your system.

```Ruby
public static func appAccountToken(_ token: UUID) -> Product.PurchaseOption
```
###### Example:
```Ruby
let result = try await product.purchase(options: [.appAccountToken(UUID())])
```
#### The quantity of this product to purchase.
The default is 1 if this option is not added. This option can only be applied to consumable products and non-renewing subscriptions.
Parameter quantity: The quantity to purchase.
```Ruby
public static func quantity(_ quantity: Int) -> Product.PurchaseOption
```
###### Example:
```Ruby
let result = try await product.purchase(options: [.quantity(1)])
```

#### Add a custom option to a purchase.
Parameters:
- key: The key for this custom option.
- value: The value for this custom option.
```Ruby
public static func custom(key: Key, value: Value) -> Product.PurchaseOption
```
###### Example:
```Ruby
typealias Key = String
typealias Value = String

let result = try await product.purchase(options: [.custom(key: Key, value: Value)])
```

## PurchaseResult
The value of the purchase result represents the state of the purchase.
```Ruby
public enum PurchaseResult {

    /// The purchase succeeded with a `Transaction`.
    case success(VerificationResult<Transaction>)

    /// The user cancelled the purchase.
    case userCancelled

    /// The purchase is pending some user action.
    ///
    /// These purchases may succeed in the future, and the resulting `Transaction` will be
    /// delivered via `Transaction.updates`
    case pending
}
```

When successful, the associated value contains a ***VerificationResult*** of the transaction.

## VerificationResult

```Ruby
enum VerificationResult<SignedType> {

    /// The associated value failed verification for the provided reason.
    case unverified(SignedType, VerificationResult<SignedType>.VerificationError)

    /// The associated value passed all automatic verification checks.
    case verified(SignedType)
}
```

The following example illustrates calling `purchase(options:)`on a ***Product*** value, checking the purchase status, and inspecting information about a successful transaction.

```Ruby
let result = try await product.purchase()

switch result {
case .success(let verificationResult):
    switch verificationResult {
    case .verified(let transaction):
        // Give the user access to purchased content.
        ...
        // Complete the transaction after providing
        // the user access to the content.
        await transaction.finish()
    case .unverified(let transaction, let verificationError):
        // Handle unverified transactions based 
        // on your business model.
        ...
    }
case .pending:
    // The purchase requires action from the customer. 
    // If the transaction completes, 
    // it's available through Transaction.updates.
    break
case .userCancelled:
    // The user canceled the purchase.
    break
@unknown default:
    break
}
```
Once a transaction is in ***pending state***, it can take hours (or even days) to complete or fail, depending on what happens to the approval process. Because of this, the application will have to ***listen for transactions and update its internal state*** accordingly.

## TransactionListener
Async sequence that we can iterate over in order to be notified whenever there’s a new transaction for us.
>Can be used for ***Ask To Buy*** or ***Strong Customer Authentication*** cases where the transaction enters the ***pending state***.

```Ruby
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
```
>Since the ***Transaction.listener*** sequence never ends (unless we break out of the for loop, that is), we detach it into a Task. Early in the app’s lifecycle, we then store a reference to this task, which we can then use later to cancel it if we want to:

```Ruby
var updateListenerTask: Task<Void, Error>? = nil
```
Call this early in the app's lifecycle.
```Ruby
private func startStoreKitListener() {
    updateListenerTask = listenForTransactions()
}
```
That way, whenever a transaction gets added or updated, we’ll get a chance to react to that change.

## Giving users access to paid content
A big feature that was missing from StoreKit was a way to actually unlock paid content or features within your app based on the user’s purchases. This is now possible using another new API available on Transaction.

We can use the static method `currentEntitlements(for:)` to fetch the current transaction that gives the user access to a specific product identifier, or just use `Transaction.currentEntitlements`, another async sequence which returns all transactions that entitle the user access to a given product or feature.
```Ruby
@MainActor
func updatePurchases() {
    async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            //check smth
        }
    }
}
```

## Offering in-app refunds
API for developers to send users to a refund flow — right from within the app itself
```Ruby
@MainActor
func beginRefundProcess(for productID: String) {
    guard let scene = view.window?.windowScene else { return }
    
    async {
        guard case .verified(let transaction) = await Transaction.latest(for: productID) else { return }
        
        do {
            let status = try await transaction.beginRefundRequest(in: view.window!.windowScene!)
            
            switch status {
            case .userCancelled:
                break
            case .success:
                // Maybe show something in the UI indicating that the refund is processing
                setRefundingStatus(on: productID)
            @unknown default:
                assertionFailure("Unexpected status")
                break
            }
        } catch {
            print("Refund request failed to start: \(error)")
        }
    }
}
```
## Useful Links

[Meet StoreKit 2](https://developer.apple.com/videos/play/wwdc2021/10114)

[StoreKit framework](https://developer.apple.com/documentation/storekit)

[App Store Server API](https://developer.apple.com/documentation/appstoreserverapi)

[Introducing StoreKit Testing in Xcode](https://developer.apple.com/videos/play/wwdc2020/10659)


Developed By
------------

* Hrebinik Artem, CHI Software
* Kosyi Vlad, CHI Software

## License

Copyright 2022 CHI Software.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

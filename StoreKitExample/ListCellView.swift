//
//  ListCellView.swift
//  StoreKitExample
//
//  Created by Artem Grebinik on 26.07.2022.
//

import SwiftUI
import StoreKit

struct ListCellView: View {
    let product: Product

    init(product: Product) {
        self.product = product
    }

    var body: some View {
        
        HStack {
            Image(product.id)
                    .resizable()
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(product.type == .nonConsumable ? 90 : 0))
                    .padding(.trailing, 20)
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            
            if product.type == .autoRenewable {
                VStack(alignment: .leading) {
                    Text(product.displayName)
                        .bold()
                    Text(product.description)
                }
            } else if product.type == .nonConsumable {
                Text(product.displayName)
                    .bold()
            } else {
                Text(product.description)
                    .frame(alignment: .leading)
            }
        }
    }
}

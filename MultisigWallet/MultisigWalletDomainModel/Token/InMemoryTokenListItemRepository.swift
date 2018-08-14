//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

/// In-memory implementation of token list items repository, used for testing purposes.
public class InMemoryTokenListItemRepository: TokenListItemRepository {

    private var items = [TokenID: TokenListItem]()

    public init() {}

    public func save(_ tokenListItem: TokenListItem) {
        items[tokenListItem.id] = tokenListItem
    }

    public func remove(_ tokenListItem: TokenListItem) {
        items.removeValue(forKey: tokenListItem.id)
    }

    public func find(id: TokenID) -> TokenListItem? {
        return items[id]
    }

}

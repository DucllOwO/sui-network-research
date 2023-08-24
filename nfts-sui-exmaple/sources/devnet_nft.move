// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

// TODO: consider renaming this to `example_nft`
/// A minimalist example to demonstrate how to create an NFT like object
/// on Sui.
module nfts::devnet_nft {
    use sui::url::{Self, Url};
    use std::string;
    use sui::object::{Self, ID, UID};
    use sui::event;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    /// Only allow 10 NFT's to exist at once. Gotta make those NFT's rare!
    const MAX_SUPPLY: u64 = 1;

    /// Created more than the maximum supply of Num NFT's
    const ETooManyNums: u64 = 0;

    /// An example NFT that can be minted by anybody
    struct DevNetNFT has key, store {
        id: UID,
        /// Name for the token
        name: string::String,
        /// Description of the token
        description: string::String,
        /// URL for the token
        url: Url,
        // TODO: allow custom attributes
    }

    /// admin ownership
    struct DevNetNFTCap has key {
        id: UID,
        /// Number of NFT<Num>'s in circulation. Fluctuates with minting and burning.
        /// A maximum of `MAX_SUPPLY` NFT<Num>'s can exist at a given time.
        supply: u64,
    }

    // ======EVENT======
    struct MintNFTEvent has copy, drop {
        // The Object ID of the NFT
        object_id: ID,
        // The creator of the NFT
        creator: address,
        // The name of the NFT
        name: string::String,
        // number of nft currently
        current_supply: u64
    }

    struct BurnNFTEvent has copy, drop {
        // The Object ID of the NFT
        object_id: ID,
        // The creator of the NFT
        creator: address,
        // The name of the NFT
        name: string::String,
        // number of nft currently
        current_supply: u64
    }

    struct UpdateDescriptionNFTEvent has copy, drop {
        // The Object ID of the NFT
        object_id: ID,
        // The creator of the NFT
        sender: address,
        // The name of the NFT
        old_description: string::String,
    }

    // create a unique capability object and send it to sender
    fun init(ctx: &mut TxContext) {
        let issuer_cap = DevNetNFTCap {
            id: object::new(ctx),
            supply: 0
        };
        transfer::transfer(issuer_cap, tx_context::sender(ctx))
    }

    

    /// Create a new devnet_nft
    public entry fun mint(
        cap: &mut DevNetNFTCap,
        name: vector<u8>,
        description: vector<u8>,
        url: vector<u8>,
        ctx: &mut TxContext
    ) {
        let n = cap.supply + 1;
        assert!(n <= MAX_SUPPLY, ETooManyNums);
        let nft = DevNetNFT {
            id: object::new(ctx),
            name: string::utf8(name),
            description: string::utf8(description),
            url: url::new_unsafe_from_bytes(url)
        };

        let sender = tx_context::sender(ctx);

        cap.supply = cap.supply + 1;

        event::emit(MintNFTEvent {
            object_id: object::uid_to_inner(&nft.id),
            creator: sender,
            name: nft.name,
            current_supply: cap.supply
        });

        transfer::public_transfer(nft, sender);
    }

    

    /// Update the `description` of `nft` to `new_description`
    public entry fun update_description(
        nft: &mut DevNetNFT,
        new_description: vector<u8>,
        ctx: &mut TxContext
    ) {

        event::emit(UpdateDescriptionNFTEvent {
            object_id: object::uid_to_inner(&nft.id),
            sender: tx_context::sender(ctx),
            old_description: string::utf8(new_description)
        });

        nft.description = string::utf8(new_description)
    }

    /// Permanently delete `nft`
    public entry fun burn(cap: &mut DevNetNFTCap, nft: DevNetNFT, ctx: &mut TxContext) {
        let DevNetNFT { id, name: name, description: _, url: _ } = nft;
        cap.supply = cap.supply - 1;

        event::emit(BurnNFTEvent {
            object_id: object::uid_to_inner(&id),
            creator: tx_context::sender(ctx),
            name: name,
            current_supply: cap.supply
        });

        object::delete(id)
    }

    /// Get the NFT's `name`
    public fun name(nft: &DevNetNFT): &string::String {
        &nft.name
    }

    /// Get the NFT's `description`
    public fun description(nft: &DevNetNFT): &string::String {
        &nft.description
    }

    /// Get the NFT's `url`
    public fun url(nft: &DevNetNFT): &Url {
        &nft.url
    }
}

// #[test_only]
// module nfts::devnet_nftTests {
//     use nfts::devnet_nft::{Self, DevNetNFT};
//     use sui::test_scenario as ts;
//     use sui::transfer;
//     use std::string;

//     #[test]
//     fun mint_transfer_update() {
//         let addr1 = @0xA;
//         let addr2 = @0xB;
//         // create the NFT
//         let scenario = ts::begin(addr1);
//         {
//             devnet_nft::mint(b"test", b"a test", b"https://www.sui.io", ts::ctx(&mut scenario))
//         };
//         // send it from A to B
//         ts::next_tx(&mut scenario, addr1);
//         {
//             let nft = ts::take_from_sender<DevNetNFT>(&mut scenario);
//             transfer::public_transfer(nft, addr2);
//         };
//         // update its description
//         ts::next_tx(&mut scenario, addr2);
//         {
//             let nft = ts::take_from_sender<DevNetNFT>(&mut scenario);
//             devnet_nft::update_description(&mut nft, b"a new description") ;
//             assert!(*string::bytes(devnet_nft::description(&nft)) == b"a new description", 0);
//             ts::return_to_sender(&mut scenario, nft);
//         };
//         // burn it
//         ts::next_tx(&mut scenario, addr2);
//         {
//             let nft = ts::take_from_sender<DevNetNFT>(&mut scenario);
//             devnet_nft::burn(nft)
//         };
//         ts::end(scenario);
//     }
// }

// Copyright © 2026 Kedar Iyer
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

pragma solidity ^0.8.20;

import "./libraries/SafeERC20.sol";

using SafeERC20 for IERC20;

interface IOracle {
	function getPrice(address baseAsset, address quoteAsset) external returns (uint); 
}

contract Bank {
	address immutable owner;

	constructor(address _owner) {
		require (_owner != address(0), "must set owner");
		owner = _owner;
	}

	function withdrawTo(address user, address token, uint amount) external {
		require(msg.sender == owner, "only owner can withdraw funds");
		require(amount > 0, "amount is zero");

		IERC20(token).safeTransfer(user, amount);
	}
}

error Uint2Error(uint m, uint n);
error AddressError(address m);

contract Lend {
	struct LendingMarketDetails {
		address collateralAsset;
		address borrowAsset;
		uint initialMarginNumerator;
		uint initialMarginDenominator;
		uint maintenanceMarginNumerator;
		uint maintenanceMarginDenominator;
		//uint minLendingPercent;
		//uint maxLendingPercent;
		address payable bankAddress;
		address oracle;
	}
	struct BorrowPosition {
		address user;
		uint collateralAmount;
		uint borrowAmount;
		uint interestCounterStart;
	}
	struct LendPosition {
		address user;
		uint lendAmount;
		uint interestCounterStart;
	}
	uint interestCounter = 0;

	mapping(bytes32 => LendingMarketDetails) public MARKET_DETAILS; // market_id -> MarketDetails

	event MarketCreated(bytes32 marketId, address collateralAsset, address borrowAsset, uint initialMarginNumerator, uint initialMarginDenominator, 
			    uint maintenanceMarginNumerator, uint maintenanceMarginDenominator, address bankAddress, address oracle);

	function createMarket(address collateralAsset, address borrowAsset, uint initialMarginNumerator, uint initialMarginDenominator, 
			      uint maintenanceMarginNumerator, uint maintenanceMarginDenominator, address oracle) external {
		bytes32 marketId = getMarketId(collateralAsset, borrowAsset, initialMarginNumerator, initialMarginDenominator, 
					       maintenanceMarginNumerator, maintenanceMarginDenominator, oracle);
		require(MARKET_DETAILS[marketId].bankAddress == address(0), "market has already been created");
		address payable bankAddress = payable(address(new Bank(address(this))));
		MARKET_DETAILS[marketId] = LendingMarketDetails(collateralAsset, borrowAsset, initialMarginNumerator, initialMarginDenominator, 
								maintenanceMarginNumerator, maintenanceMarginDenominator, bankAddress, oracle);
		emit MarketCreated(marketId, collateralAsset, borrowAsset, initialMarginNumerator, initialMarginDenominator, 
				   maintenanceMarginNumerator, maintenanceMarginDenominator, bankAddress, oracle);
	}

	function getMarketId(address collateralAsset, address borrowAsset, uint initialMarginNumerator, uint initialMarginDenominator, uint maintenanceMarginNumerator, 
			     uint maintenanceMarginDenominator, address oracle) public pure returns (bytes32) {
		return keccak256(abi.encodePacked(collateralAsset, borrowAsset, initialMarginNumerator, initialMarginDenominator, 
						  maintenanceMarginNumerator, maintenanceMarginDenominator, oracle));
	}
}

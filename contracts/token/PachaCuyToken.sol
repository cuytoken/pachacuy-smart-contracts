// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @custom:security-contact lee@cuytoken.com
contract PachaCuy is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address _tokenAdminAddress) public initializer {
        __ERC20_init("Pacha Cuy", "PCUY");
        __ERC20Burnable_init();

        _mint(_tokenAdminAddress, 100 * 10**6 * 10**decimals());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract PachaCuy is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _privateSale,
        address _cuyTokenToPachacuy,
        address _publicSale,
        address _vesting,
        address _airDrop,
        address _liquidityPoolWallet,
        address _poolDynamics,
        address _phaseTwoAndX
    ) public initializer {
        __ERC20_init("Pacha Cuy", "PCUY");
        __ERC20Burnable_init();
        
        //_privateSale
        _mint(_privateSale, 1000 * 10**decimals());

        //_cuyTokenToPachacuy
        _mint(_cuyTokenToPachacuy, 1000 * 10**decimals());

        //_publicSale
        _mint(_publicSale, 1000 * 10**decimals());

        //_vesting
        _mint(_vesting, 1000 * 10**decimals());

        //_airDrop
        _mint(_airDrop, 1000 * 10**decimals());

        //_liquidityPoolWallet
        _mint(_liquidityPoolWallet, 1000 * 10**decimals());

        //_poolDynamics
        _mint(_poolDynamics, 1000 * 10**decimals());

        //_phaseTwoAndX
        _mint(_phaseTwoAndX, 1000 * 10**decimals());        
    }
}

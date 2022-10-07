// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/ICharacterStats.sol";


contract CharacterStatsTop10 is AccessControlUpgradeable, UUPSUpgradeable, ICharacterStats {
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant DESIGNER_ROLE = keccak256("DESIGNER_ROLE");

    // Mapping from char stats base
    mapping(uint256 => Stats) private stats;

    function initialize() public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
        _setupRole(DESIGNER_ROLE, msg.sender);

        stats[0] = Stats(
            0, 0, 0, 0, 1, 1, 139, 14, 9, 0, 150, 0, 1, 39, 10
        );

        stats[1] = Stats(
            1, 0, 0, 1, 1, 1, 265, 13, 13, 0, 150, 0, 1, 17, 10
        );

        stats[2] = Stats(
            2, 0, 0, 2, 1, 1, 152, 14, 9, 0, 150, 0, 1, 38, 10
        );

        stats[3] = Stats(
            3, 0, 0, 3, 0, 1, 63, 8, 4, 5, 150, 0, 1, 39, 10
        );

        stats[4] = Stats(
            4, 0, 0, 4, 1, 1, 85, 11, 6, 5, 150, 0, 1, 54, 10
        );

        stats[5] = Stats(
           5, 0, 0, 5, 2, 1, 111, 15, 7, 0, 150, 0, 0, 61, 10
        );

        stats[6] = Stats(
            6, 0, 0, 6, 0, 1, 62, 8, 4, 5, 150, 0, 1, 39, 10
        );

        stats[7] = Stats(
            7, 0, 0, 7, 1, 1, 261, 13, 13, 0, 150, 0, 1, 18, 10
        );

        stats[8] = Stats(
            8, 0, 0, 8, 0, 1, 185, 9, 9, 0, 150, 0, 1, 12, 10
        );

        stats[9] = Stats(
            9, 0, 0, 9, 2, 1, 206, 20, 13, 0, 150, 0, 1, 56, 10
        );       
    }


    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function getStats(uint256 charId)
        external
        view
        override
        returns (Stats memory)
    {
        // Get stats base
        return stats[charId];
    }
}

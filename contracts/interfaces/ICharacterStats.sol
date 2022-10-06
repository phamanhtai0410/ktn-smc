// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICharacterStats {
    struct StatsRange {
        uint256 min;
        uint256 max;
    }

    struct Stats {
        uint256 id;
        uint256 index;
        uint256 is_onchain;
        uint256 character_id;
        uint256 base_rarity;
        uint256 egg_type;
        uint256 rarity;
        uint256 level;
        uint256 faction;
        uint256 class;
        uint256 health;
        uint256 speed;
        uint256 armor;
        uint256 magic_resistance;
        uint256 crit_chance;
        uint256 crit_damage;
        uint256 dodge;
        uint256 type_attack;
        uint256 damage;
    }

    function getStats(uint256 rarity) external view returns (Stats memory);
}

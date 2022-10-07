// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library CharacterDetails {
    uint8 public constant ALL_RARITY = 0;
    uint8 public constant BOX_TYPE_NORMAL = 1;
    uint8 public constant BOX_TYPE_GOLDEN = 2;
    uint8 public constant BOX_TYPE_BASKET = 3;
    uint8 public constant ON_CHAIN = 1;
    uint8 public constant OFF_CHAIN = 0;

    // Character ID: 1->63
    uint256 public constant CHARACTER0 = 0;
    uint256 public constant CHARACTER1 = 1;

    struct Details {
        uint256 id;
        uint256 index;
        uint256 is_onchain;
        uint256 character_id;
        uint256 box_type;
        uint256 rarity;
        uint256 level;
        uint256 health;
        uint256 speed;
        uint256 armor;
        uint256 crit_chance;
        uint256 crit_damage;
        uint256 dodge;
        uint256 type_attack;
        uint256 damage;
    }

/**
id	30
index	10
is_onchain	1
character_id	7
base_rarity	3
box_type	3
rarity	3
level	4
health	13
speed	8
armor	9
magic_resistance	9
crit_chance	7
crit_damage	9
dodge	7
type_attack	2
damage	10
*/


    function encode(Details memory details) internal pure returns (uint256) {
        uint256 value;
        uint256 bitIndex = 30;
        value |= details.id;
        value |= details.index << bitIndex;
        bitIndex += 10;
        value |= details.is_onchain << bitIndex;
        bitIndex += 1;
        value |= details.character_id << bitIndex;
        bitIndex += 7;
        value |= details.box_type << bitIndex;
        bitIndex += 3;
        value |= details.rarity << bitIndex;
        bitIndex += 3;
        value |= details.level << bitIndex;
        bitIndex += 4;
        value |= details.health << bitIndex;
        bitIndex += 13;
        value |= details.speed << bitIndex;
        bitIndex += 8;
        value |= details.armor << bitIndex;
        bitIndex += 9;
        value |= details.crit_chance << bitIndex;
        bitIndex += 7;
        value |= details.crit_damage << bitIndex;
        bitIndex += 9;
        value |= details.dodge << bitIndex;
        bitIndex += 7;
        value |= details.type_attack << bitIndex;
        bitIndex += 2;
        value |= details.damage << bitIndex;
        bitIndex += 10;
        return value;
    }

    function decode(uint256 details)
        internal
        pure
        returns (Details memory result)
    {
        uint256 bitIndex = 30;
        result.id = decodeId(details);
        result.index = decodeIndex(details);
        bitIndex += 10;
        result.is_onchain = (details >> bitIndex) & 1;
        bitIndex += 1;
        result.character_id = (details >> bitIndex) & 127;
        bitIndex += 7;
        result.box_type = (details >> bitIndex) & 7;
        bitIndex += 3;
        result.rarity = (details >> bitIndex) & 7;
        bitIndex += 3;
        result.level = (details >> bitIndex) & 15;
        bitIndex += 4;
        result.health = (details >> bitIndex) & 8191;
        bitIndex += 13;
        result.speed = (details >> bitIndex) & 255;
        bitIndex += 8;
        result.armor = (details >> bitIndex) & 511;
        bitIndex += 9;
        result.crit_chance = (details >> bitIndex) & 127;
        bitIndex += 7;
        result.crit_damage = (details >> bitIndex) & 511;
        bitIndex += 9;
        result.dodge = (details >> bitIndex) & 127;
        bitIndex += 7;
        result.type_attack = (details >> bitIndex) & 3;
        bitIndex += 2;
        result.damage = (details >> bitIndex) & 1023;
        bitIndex += 10;
    }

    function decodeId(uint256 details) internal pure returns (uint256) {
        return details & ((1 << 30) - 1);
    }

    function decodeIndex(uint256 details) internal pure returns (uint256) {
        return (details >> 30) & ((1 << 10) - 1);
    }

}
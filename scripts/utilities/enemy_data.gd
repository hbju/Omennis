class_name EnemyData

static var ENEMY_CLASS_DEFINITIONS = {
	"Brute Marauder": {
        "class_enum": Character.CLASSES.Warrior,
		"base_hp": 50, "hp_per_level": 10,
		"base_damage_stat": 5, "damage_stat_per_level": 2.5,
		"skill_pool_config": [ 
			{"skill": Charge, "min_level": 2},
			{"skill": Frenzy, "min_level": 4},
			{"skill": WarCry, "min_level": 6}
		],
		"portraits": [0] # Indices or paths
	},
	"Arcane Channeler": {
        "class_enum": Character.CLASSES.Mage,
		"base_hp": 30, "hp_per_level": 5,
		"base_damage_stat": 5, "damage_stat_per_level": 3,
		"skill_pool_config": [
			{"skill": ArcaneShield, "min_level": 2},
			{"skill": Blink, "min_level": 4},
			{"skill": Thunderstrike, "min_level": 6}
		],
		"portraits": [2]
	},
    "Frost Guardian": {
        "class_enum": Character.CLASSES.Mage,
        "base_hp": 40, "hp_per_level": 7,
        "base_damage_stat": 7, "damage_stat_per_level": 2.5,
        "skill_pool_config": [
            {"skill": Frostbolt, "min_level": 2},
            {"skill": ArcaneSlash, "min_level": 4},
            {"skill": BoneArmor, "min_level": 6}
        ],
        "portraits": [10]
    },
    "Necromancer": {
        "class_enum": Character.CLASSES.Mage,
        "base_hp": 30, "hp_per_level": 10,
        "base_damage_stat": 5, "damage_stat_per_level": 2.5,
        "skill_pool_config": [
            {"skill": DarkPact, "min_level": 2},
            {"skill": Blink, "min_level": 4},
            {"skill": Decay, "min_level": 6}
        ],
        "portraits": [12]
    },
    "Raging Berserker": {
        "class_enum": Character.CLASSES.Warrior,
        "base_hp": 45, "hp_per_level": 15,
        "base_damage_stat": 5, "damage_stat_per_level": 2.5,
        "skill_pool_config": [
            {"skill": Frenzy, "min_level": 2},
            {"skill": RagingBlow, "min_level": 4},
            {"skill": BloodFury, "min_level": 6}
        ],
        "portraits": [11]
    },
    "Lich Warrior": {
        "class_enum": Character.CLASSES.Warrior,
        "base_hp": 40, "hp_per_level": 10,
        "base_damage_stat": 7, "damage_stat_per_level": 2.5,
        "skill_pool_config": [
            {"skill": ArcaneSlash, "min_level": 2},
            {"skill": BoneArmor, "min_level": 4},
            {"skill": DeathCoil, "min_level": 6}
        ],
        "portraits": [9]
    },
    "Mountain Drake" : {
        "class_enum": Character.CLASSES.None,
        "base_hp": 40, "hp_per_level": 15,
        "base_damage_stat": 10, "damage_stat_per_level": 2.5,
        "skill_pool_config": [
            {"skill": Charge, "min_level": 2},
            {"skill": Frenzy, "min_level": 4},
            {"skill": WarCry, "min_level": 5}
        ],
        "portraits": [1]
    },
    "Kaelen Vane" : {
        "class_enum": Character.CLASSES.Warrior,
        "base_hp": 0, "hp_per_level": 50,
        "base_damage_stat": 0, "damage_stat_per_level": 5,
        "skill_pool_config": [
            {"skill": Blink, "min_level": 3},
            {"skill": ArcaneSlash, "min_level": 5},
            {"skill": BloodFury, "min_level": 6}
        ],
        "portraits": [14]
    },
    "Ash-Chitterer Queen" : {
        "class_enum": Character.CLASSES.Warrior,
        "base_hp": 0, "hp_per_level": 40,
        "base_damage_stat": 0, "damage_stat_per_level": 5,
        "skill_pool_config": [
            {"skill": Charge, "min_level": 3},
            {"skill": Frenzy, "min_level": 5},
            {"skill": Decay, "min_level": 6}
        ],
        "portraits": [15]
    },
    "Mercenary Guard" : {
        "class_enum": Character.CLASSES.Warrior,
        "base_hp": 45, "hp_per_level": 15,
        "base_damage_stat": 10, "damage_stat_per_level": 2.5,
        "skill_pool_config": [
            {"skill": ShieldBash, "min_level": 2},
            {"skill": WarCry, "min_level": 4},
            {"skill": Whirlwind, "min_level": 6}
        ],
        "portraits": [16]
    },
    "Goblin Raider": {
        "class_enum": Character.CLASSES.Warrior,
        "base_hp": 20, "hp_per_level": 3,
        "base_damage_stat": 10, "damage_stat_per_level": 3,
        "skill_pool_config": [
            {"skill": Blink, "min_level": 2},
            {"skill": Frenzy, "min_level": 4},
            {"skill": RagingBlow, "min_level": 6}
        ],
        "portraits": [20]
    },
    "Goblin Shaman": {
        "class_enum": Character.CLASSES.Mage,
        "base_hp": 25, "hp_per_level": 5,
        "base_damage_stat": 8, "damage_stat_per_level": 2.5,
        "skill_pool_config": [
            {"skill": Frostbolt, "min_level": 2},
            {"skill": Thunderstrike, "min_level": 4},
            {"skill": LightningStorm, "min_level": 6}
        ],
        "portraits": [19]
    },
    "Bear": {
        "class_enum": Character.CLASSES.None,
        "base_hp": 60, "hp_per_level": 20,
        "base_damage_stat": 15, "damage_stat_per_level": 3,
        "skill_pool_config": [
            {"skill": Charge, "min_level": 2},
            {"skill": RageSlam, "min_level": 4},
            {"skill": Frenzy, "min_level": 6}
        ],
        "portraits": [4]
    },
    "Wolf": {
        "class_enum": Character.CLASSES.None,
        "base_hp": 30, "hp_per_level": 15,
        "base_damage_stat": 10, "damage_stat_per_level": 2,
        "skill_pool_config": [
            {"skill": Charge, "min_level": 2},
            {"skill": BloodFury, "min_level": 4},
            {"skill": RagingBlow, "min_level": 6}
        ],
        "portraits": [18]
    },
    "Dire Wolf": {
        "class_enum": Character.CLASSES.None,
        "base_hp": 50, "hp_per_level": 20,
        "base_damage_stat": 15, "damage_stat_per_level": 3,
        "skill_pool_config": [
            {"skill": WarCry, "min_level": 2},
            {"skill": Frenzy, "min_level": 4},
            {"skill": RagingBlow, "min_level": 6}
        ],
        "portraits": [21]
    },
    "Orc Warrior": {
        "class_enum": Character.CLASSES.Warrior,
        "base_hp": 50, "hp_per_level": 10,
        "base_damage_stat": 12, "damage_stat_per_level": 2.5,
        "skill_pool_config": [
            {"skill": ShieldBash, "min_level": 2},
            {"skill": BloodFury, "min_level": 4},
            {"skill": Whirlwind, "min_level": 6}
        ],
        "portraits": [22]
    },
    "Orc Shaman": {
        "class_enum": Character.CLASSES.Mage,
        "base_hp": 40, "hp_per_level": 8,
        "base_damage_stat": 10, "damage_stat_per_level": 2.5,
        "skill_pool_config": [
            {"skill": Thunderstrike, "min_level": 2},
            {"skill": DrainLife, "min_level": 4},
            {"skill": Meteor, "min_level": 6}
        ],
        "portraits": [24]
    },
    "Orc Warchief": {
        "class_enum": Character.CLASSES.Warrior,
        "base_hp": 60, "hp_per_level": 15,
        "base_damage_stat": 15, "damage_stat_per_level": 3,
        "skill_pool_config": [
            {"skill": WarCry, "min_level": 2},
            {"skill": RageSlam, "min_level": 4},
            {"skill": Whirlwind, "min_level": 6}
        ],
        "portraits": [23]
    },
    "Zombie": {
        "class_enum": Character.CLASSES.None,
        "base_hp": 30, "hp_per_level": 5,
        "base_damage_stat": 8, "damage_stat_per_level": 2,
        "skill_pool_config": [
            {"skill": Frenzy, "min_level": 2},
            {"skill": Decay, "min_level": 3},
            {"skill": BloodFury, "min_level": 4}
        ],
        "portraits": [17]
    },
}
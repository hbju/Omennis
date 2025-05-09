class_name EnemyData

static var ENEMY_CLASS_DEFINITIONS = {
	"Brute Marauder": {
        "class_enum": Character.CLASSES.Warrior,
		"base_hp": 40, "hp_per_level": 10,
		"base_damage_stat": 5, "damage_stat_per_level": 1,
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
		"base_damage_stat": 5, "damage_stat_per_level": 1.5,
		"skill_pool_config": [
			{"skill": ArcaneShield, "min_level": 2},
			{"skill": Blink, "min_level": 4},
			{"skill": Thunderstrike, "min_level": 6}
		],
		"portraits": [2]
	},
    "Frost Guardian": {
        "class_enum": Character.CLASSES.Mage,
        "base_hp": 35, "hp_per_level": 5,
        "base_damage_stat": 7, "damage_stat_per_level": 1.5,
        "skill_pool_config": [
            {"skill": Frostbolt, "min_level": 2},
            {"skill": ArcaneSlash, "min_level": 4},
            {"skill": BoneArmor, "min_level": 6}
        ],
        "portraits": [10]
    },
    "Necromancer": {
        "class_enum": Character.CLASSES.Mage,
        "base_hp": 40, "hp_per_level": 10,
        "base_damage_stat": 5, "damage_stat_per_level": 1,
        "skill_pool_config": [
            {"skill": DarkPact, "min_level": 2},
            {"skill": Blink, "min_level": 4},
            {"skill": Decay, "min_level": 6}
        ],
        "portraits": [12]
    },
    "Raging Berserker": {
        "class_enum": Character.CLASSES.Warrior,
        "base_hp": 40, "hp_per_level": 10,
        "base_damage_stat": 5, "damage_stat_per_level": 1,
        "skill_pool_config": [
            {"skill": Frenzy, "min_level": 2},
            {"skill": RagingBlow, "min_level": 4},
            {"skill": BloodFury, "min_level": 6}
        ],
        "portraits": [11]
    },
    "Lich Warrior": {
        "class_enum": Character.CLASSES.Warrior,
        "base_hp": 35, "hp_per_level": 5,
        "base_damage_stat": 7, "damage_stat_per_level": 1.5,
        "skill_pool_config": [
            {"skill": ArcaneSlash, "min_level": 2},
            {"skill": BoneArmor, "min_level": 4},
            {"skill": DeathCoil, "min_level": 6}
        ],
        "portraits": [9]
    },
}
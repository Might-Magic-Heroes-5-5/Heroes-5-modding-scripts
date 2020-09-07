###################################### 	 What to do 	 ###########################################
DB_FLAG = 0
TXT_FLAG = 1
###################################### 	 Output dirs    ######################################
OUTPUT = "output/texts_ru"
DB_NAME = "output/skillwheel.db"
###################################### texts sources ######################################
SOURCE_TXT = "source/texts/MMH55-Texts-RU"
SOURCE_ADD = "source/texts/additions_ru"
###################################### Heroes V sources ######################################
SOURCE_IDX = "source/data"
SOURCE_CREATURES = "#{SOURCE_IDX}/GameMechanics/creature/creatures"
SOURCE_SPELLS = "#{SOURCE_IDX}/GameMechanics/RefTables/UndividedSpells.xdb"
SOURCE_DFSTATS = "#{SOURCE_IDX}/GameMechanics/RPGStats/DefaultStats.xdb"
SOURCE_SKILLS = "#{SOURCE_IDX}/GameMechanics/RefTables/Skills.xdb"
SOURCE_TOWNS = "#{SOURCE_IDX}/GameMechanics/RefTables/TownTypesInfo.xdb"
SOURCE_HEROES = "#{SOURCE_IDX}/MapObjects"
SOURCE_CLASSES = "#{SOURCE_IDX}/GameMechanics/RefTables/HeroClass.xdb"
SOURCE_ABILITIES = "#{SOURCE_IDX}/GameMechanics/RefTables/CombatAbilities.xdb"
SOURCE_ARTIFACTS = "#{SOURCE_IDX}/GameMechanics/RefTables/Artifacts.xdb"
SOURCE_MICRO_ARTIFACTS = "#{SOURCE_IDX}/GameMechanics/RefTables/MicroArtifactEffects.xdb"
SOURCE_MICRO_ARTIFACT_PREFIX = "#{SOURCE_IDX}/GameMechanics/RefTables/MicroArtifactPrefixes.xdb"
SOURCE_MICRO_ARITFACT_SHELLS = "#{SOURCE_IDX}/GameMechanics/RefTables/MicroArtifactShells.xdb"
SOURCE_ADVENTUREMAP = "#{SOURCE_IDX}/scripts/advmap-startup.lua"
SOURCE_COMMON = "#{SOURCE_IDX}/scripts/common.lua"
###################################### MMH55 sources ######################################
SOURCE_55CORE = "#{SOURCE_IDX}/scripts/H55-Core.lua"

###################################### 	STATIC ARRAYS and sources 	##########################################


FILTERS = [["ATTACK,DEFENCE,SPELLPOWER,KNOWLEDGE,MORALE,LUCK", "by_modifier"], 
["8000,12000,16000,20000,24000,28000,32000,36000,40000,44000,48000,96000,166667", "by_price"],
["ARTF_CLASS_MINOR,ARTF_CLASS_MAJOR,ARTF_CLASS_RELIC,ARTF_CLASS_GRAIL", "by_rarity"],
["MONK,DWARVEN,LION,VESTMENT,NECRO,SARISSUS,DRAGONISH,SAINT,GUARDIAN,CORNUCOPIA,LEGION", "by_set"],
["FINGER,HEAD,NECK,CHEST,SECONDARY,MISCSLOT1,PRIMARY,FEET,SHOULDERS,INVENTORY", "by_slot"],
["", "micro_artifact"]]

GUILD_TEXT = { MAGIC_SCHOOL_DARK: 'SchoolDark',
				MAGIC_SCHOOL_SUMMONING: 'SchoolSummoning',
				MAGIC_SCHOOL_DESTRUCTIVE: 'SchoolDestructive',
				MAGIC_SCHOOL_SPECIAL: 'SchoolSpecial',
				MAGIC_SCHOOL_LIGHT: 'SchoolLight', 
				MAGIC_SCHOOL_RUNIC: 'SchoolSpecial', 
				MAGIC_SCHOOL_WARCRIES: 'Warcries', 
				MAGIC_SCHOOL_ADVENTURE: 'AdventureSpells' }
				
RESOURCES = [ "Gold", "Wood", "Ore", "Mercury", "Crystal", "Sulfur", "Gem" ]

RUNES = [ "SPELL_RUNE_OF_CHARGE", "SPELL_RUNE_OF_BERSERKING", "SPELL_RUNE_OF_MAGIC_CONTROL",
	"SPELL_RUNE_OF_EXORCISM", "SPELL_RUNE_OF_ELEMENTAL_IMMUNITY", "SPELL_RUNE_OF_STUNNING",
	"SPELL_RUNE_OF_BATTLERAGE",	"SPELL_RUNE_OF_ETHEREALNESS","SPELL_RUNE_OF_REVIVE", "SPELL_RUNE_OF_DRAGONFORM",
	"SPELL_EFFECT_FINE_RUNE", "SPELL_EFFECT_STRONG_RUNE" ]
	
WARCRIES = ["SPELL_WARCRY_RALLING_CRY", "SPELL_WARCRY_CALL_OF_BLOOD", "SPELL_WARCRY_WORD_OF_THE_CHIEF", "SPELL_WARCRY_FEAR_MY_ROAR",
"SPELL_WARCRY_BATTLECRY", "SPELL_WARCRY_SHOUT_OF_MANY"]

MICROARTIFACTS = [ "MAE_ARMOR_CRUSHING", "MAE_DEFENCE", "MAE_HASTE", "MAE_HEALTH", "MAE_LUCK", "MAE_MAGIC_PROTECTION", "MAE_MORALE", "MAE_PIERCING", "MAE_SPEED" ]
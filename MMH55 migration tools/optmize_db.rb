require 'sqlite3'

DB = SQLite3::Database.new "skillwheel.db"

INDEX_LIST = DB.execute( "SELECT name FROM sqlite_master WHERE type == 'index';" )
INDEX_LIST.each { |i| DB.execute( "DROP INDEX '#{i[0]}';" ) }
DB.execute( "VACUUM;" )

DB.execute( "CREATE INDEX classes_by_faction ON classes (faction, sequence);" )
DB.execute( "CREATE INDEX classes_by_id ON classes (id);" )
DB.execute( "CREATE INDEX heroes_by_id ON heroes (id);" )
DB.execute( "CREATE INDEX skills_by_tree ON skills (tree, type, sequence);" )
DB.execute( "CREATE INDEX creatures_by_faction ON creatures (faction, sequence);" )
DB.execute( "CREATE INDEX spells_by_guild ON spells (guild, tier);" )
DB.execute( "CREATE INDEX artifacts_by_slot ON artifacts (slot);" )
DB.execute( "CREATE INDEX artifacts_by_type ON artifacts (type);" )
DB.execute( "CREATE INDEX artifacts_by_attack ON artifacts (attack);" )
DB.execute( "CREATE INDEX artifacts_by_defence ON artifacts (defence);" )
DB.execute( "CREATE INDEX artifacts_by_spellpower ON artifacts (spellpower);" )
DB.execute( "CREATE INDEX artifacts_by_knowledge ON artifacts (knowledge);" )
DB.execute( "CREATE INDEX artifacts_by_morale ON artifacts (morale);" )
DB.execute( "CREATE INDEX artifacts_by_luck ON artifacts (luck);" )
DB.execute( "CREATE INDEX artifacts_by_set ON artifacts (art_set);" )

CLASSES = [ "HERO_CLASS_KNIGHT","HERO_CLASS_RANGERA","HERO_CLASS_RANGER","HERO_CLASS_WIZARDA","HERO_CLASS_WIZARD","HERO_CLASS_DEMON_LORD","HERO_CLASS_NECROMANCER","HERO_CLASS_NECROMANCERA","HERO_CLASS_WARLOCK","HERO_CLASS_WARLOCKB","HERO_CLASS_SHAMAN","HERO_CLASS_RUNEMAGE","HERO_CLASS_RUNEMAGEA","HERO_CLASS_BARBARIAN","HERO_CLASS_WARDEN","HERO_CLASS_HERETIC","HERO_CLASS_REAVER","HERO_CLASS_FLAMEKEEPERA","HERO_CLASS_BEASTMASTER","HERO_CLASS_GUILDMASTER","HERO_CLASS_SEER","HERO_CLASS_ENCHANTER","HERO_CLASS_SORCERER","HERO_CLASS_ELEMENTALIST","HERO_CLASS_KNIGHT_RENEGADE","HERO_CLASS_BARBARIAN_KHAN","HERO_CLASS_BARBARIAN_VET" ]

CLASSES.each do |c|
	DB.execute( "CREATE INDEX '#{c}_by_type' ON #{c} (type, sequence);" )
	DB.execute( "CREATE INDEX '#{c}_by_chance' ON #{c} (chance);" )
	DB.execute( "CREATE INDEX '#{c}_by_skill' ON #{c} (skill);" )
end

Shoes.app do
	para "DONE!"
end


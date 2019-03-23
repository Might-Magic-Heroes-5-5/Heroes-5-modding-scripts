	require 'sqlite3'


Shoes.app do

	db = SQLite3::Database.new 'skillwheel.db'
	db_old = SQLite3::Database.new 'skillwheel_working.db'
	klasses = db.execute "select id from classes"

	klasses.each do |k|
		k[0] == 'HERO_CLASS_NONE' ? next : nil
		perks = db.execute "select skill from #{k[0]}"
		old_sequence = db_old.execute "select sequence from #{k[0]}"
		perks.each_with_index do |p, i|
			db.execute "update #{k[0]} set sequence = '#{old_sequence[i][0]}' where skill = '#{p[0]}';"
		end
	end

	skills = db.execute "select name from skills"
	old_sequence = db_old.execute "select sequence from skills"
	skills.each_with_index do |s, i|
		db.execute "update skills set sequence = '#{old_sequence[i][0]}' where name = '#{s[0]}';"
	end
	
	klas_seq = db.execute "select id from classes"
	old_sequence = db_old.execute "select sequence from classes"
	klas_seq.each_with_index do |q, i|
		db.execute "update classes set sequence = '#{old_sequence[i][0]}' where id = '#{q[0]}';"
	end

	creatures = db.execute "select id from creatures"
	old_sequence = db_old.execute "select sequence from creatures"
	creatures.each_with_index do |c, i|
		db.execute "update creatures set sequence = '#{old_sequence[i][0]}' where id = '#{c[0]}';"
	end
	
	heroes = db.execute "select id from heroes"
	old_sequence = db_old.execute "select sequence from heroes"
	heroes.each_with_index do |p, i|
		db.execute "update heroes set sequence = '#{old_sequence[i][0]}' where id = '#{p[0]}';"
	end
	
	para "Migration Complete!"
end

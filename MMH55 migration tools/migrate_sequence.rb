	require 'sqlite3'


Shoes.app do

	db = SQLite3::Database.new 'skillwheel.db'
	db_old = SQLite3::Database.new 'skillwheelRC14B4.db'

	klasses = db.execute "select id from classes"
	debug("=============== PERKS PER CLASS ===============");
	klasses.each do |k|
		next if k[0] == 'HERO_CLASS_NONE'
		
		perks = db.execute "select skill from #{k[0]}"		
		perks.each_with_index do |p, i|
			begin
				sequence = db_old.execute "select sequence from #{k[0]} where skill = '#{p[0]}'";
				db.execute "update #{k[0]} set sequence = '#{sequence[0][0]}' where skill = '#{p[0]}';"
			rescue
				debug("#{k[0]} with skill #{p[0]}");
			end
		end
	end

	
	skills = db.execute "select name from skills"
	debug("=============== SKILLS ===============");
	skills.each do |s|
		begin
			sequence = db_old.execute "select sequence from skills where name = '#{s[0]}';"
			db.execute "update skills set sequence = '#{sequence[0][0]}' where name = '#{s[0]}';"
		rescue
			debug(s[0]);
		end
	end
	
	klas_seq = db.execute "select id from classes"
	debug("=============== CLASSES ===============");
	klas_seq.each_with_index do |q, i|
		begin
			sequence = db_old.execute "select sequence from classes where id = '#{q[0]}';"
			db.execute "update classes set sequence = '#{sequence[0][0]}' where id = '#{q[0]}';"
		rescue
			debug(q[0]);
		end
	end

	creatures = db.execute "select id from creatures"
	debug("=============== CREATURES ===============");
	creatures.each_with_index do |c, i|
		begin
			sequence = db_old.execute "select sequence from creatures where id = '#{c[0]}'"
			db.execute "update creatures set sequence = '#{sequence[0][0]}' where id = '#{c[0]}';"
		rescue
			debug(c[0]);
		end
	end

	heroes = db.execute "select id from heroes"
	debug("=============== HEROES ===============");
	heroes.each_with_index do |p, i|
		begin
			sequence = db_old.execute "select sequence from heroes where id = '#{p[0]}';"
			db.execute "update heroes set sequence = '#{sequence[0][0]}' where id = '#{p[0]}';"
		rescue
			debug(p[0]);
		end
	end
	
	para "Migration Complete!"
end

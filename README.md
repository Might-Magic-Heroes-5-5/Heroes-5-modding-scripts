Repository includes various scripts that serve as modding tools for any Heroes 5 mods!

Files description:

1. Sort NCF.py - Script extracts single creatures from the NCF_Megapack.
2. NCF archive creatures.rb - Script archive a single creature into its own .pak archive.


MMH55 migration tools - scripts that are used to migrate Heroes V data to a SQLite database.
The order of running the scripts is as follows:
1. MMH55_to_SQL.rb - collects what it can from unarchived data.pak (unarchive on top a mmh55-index.pak to make a repository of heroes 5 with latest updates)
2. sql_additions.rb 
   - added MMH55 additional classes that does not exist in the tables - Khan, Veteran, Renegade
   - added 2 new sets - Cornucopia and Legion
   - added better spell descritions and additions of hardcodded elements
   - added 4 bonus adventure map spells describing all "Town Governor" ability functions
   - added custom predictions and formulas for creature artifacts

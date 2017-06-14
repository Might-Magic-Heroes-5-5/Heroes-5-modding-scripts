'''
Created on Apr 28, 2017

@author: dred
'''
from os import makedirs, walk, listdir
from os.path import isfile, join
from shutil import copyfile, move
import re

#src = 'D:\\mod workplace\\NCF_MegaPack'
src = 'D:\\mod workplace\\NCF\\All_NCF_creatures'
dest = 'D:\\mod workplace\\New_NCF\\'
default_races = [ 'Academy', 'Haven', 'Dwarves', 'Necropolis', 'Dungeon', 'Preserve', 'Orcs', 'Inferno'] ## a quick list with all races in case it is needed.
mode = 1 #selects what the script will do
# 0 - is for NCFmegapack extraction;
# ---> source: expects unarchievedNCF megapack folder 
# ---> output: create separate folders for each NCF creature along with its accompanying files
# 1 - is for creating Editor icons
# ---> source: expects a folder with NCF creature folders (0 mode output)
# ---> destination: creates "icon" folder with editor icons for all ncf creatures from source.
# ---------> create separate folders for each NCF creature (copied from the source) where the MapObjects\_(AdvMapObjectLink)\Monsters\NCF\Creature_id.xdb
# ---------> file is changed to refer the new icon that reside in <game folder>/Complete/Icons

def migrate_files(file):
    if isfile(join(source,file)):
        dirr = file.split('\\')
        try:
            makedirs(destination + '\\'.join(dirr[0:len(dirr)-1]))
        except:
            pass
    else:
        return 1
    print(join(source,file))
    copyfile(join(source,file), join(destination ,file))
    #move(join(source,file), join(destination,file))
    return 0

def list_files(uuid, int_source):
    for root, dirs, files in walk(join(source, int_source)):  
        for name in files:
            if name == uuid:
                migrate_files(join('\\'.join(root.split('\\')[len(source.split('\\')):]), name))
    return
    
def read_files(file, first, second, sanitize = True): 
    file_arr = []  
    for i, line in enumerate(open(join(source, file))):
        try:
            start = line.index( first ) + len( first )
            end = line.index( second, start )
            string = line[start:end]
            if string == '':
                continue
            else:
                target = string
            #print('-------->', string)
            if sanitize is True:
                if re.match("^/", string) is None:
                    target = (file.split('\\'))
                    target = join('\\'.join(target[0:len(target)-1]), string)
                    #print('-------->>','yes')
                else:
                    target = re.sub('^/','',string)
                    #print('-------->>','no')
                target = re.sub('/','\\\\', target)
                target = (target.split('#xpointer'))[0]
                #print('-------->>',target)
            file_arr.append(target)
        except ValueError:
            pass
    return file_arr

def get_file_trees (file, i=0):
    paths, uuids, visuals = [], [], []
    #print('-->', file)
    try:    
        paths = read_files( file, 'href="', '"')
        uuids = read_files( file, '<uid>', '</uid>', False)
        for uuid in uuids:
            list_files(uuid, 'bin')
        visuals = read_files( file, '<Model href="', '#xpointer')
        for v in visuals:
            visuals = v.split('.')
            migrate_files(visuals[0] + '.(CharacterView).' + visuals[1])
            #print(visuals[0] + '.(CharacterView).' + visuals[1], source, destination)
    except:
        pass
    migrate_files(file)
    try:
        nmb = len(paths)
        while(i < nmb):
            #print(i*"##")
            get_file_trees(paths[i])
            i=i+1
    except:
        pass

#for race in default_races:
#for root, dirs, files in walk(join(source, 'GameMechanics\\Creature\\Creatures\\')): 
#    for f in files:
#        destination = (dest + f.split('.')[0] + '\\')
#        print(('\\').join(root.split('\\')[3:]) + '\\' + f)
#        get_file_trees(('\\').join(root.split('\\')[3:]) + '\\' + f)

    
cc = 0
if mode == 0:
    source = src
    for i in range(1,1000):
        destination = join(dest, '%d\\' %i)
        get_file_trees('GameMechanics\\Creature\\Creatures\\Neutrals\\Creature_%d.xdb' %i )
        #get_file_trees('Characters\\Creatures\\Academy\\Colossus_LOD_view.xdb')
        get_file_trees('MapObjects\\_(AdvMapObjectLink)\\Monsters\\NCF\\Creature_%d.xdb' %i )
        get_file_trees('scripts\\Creature_%d.lua' % i)
        get_file_trees('Cameras\\Interface\\HireCreatures\\Creature_%d.(Camera).xdb' % i)
        #_LOD.(Character)
    
if mode == 1:
    icon_dest = join(dest, 'Complete')
    #makedirs(icon_dest)
    for i in range(180,182):
        destination = join(dest, '%d\\' %i)
        source = join(src, '%d\\' %i)
        try:
            file = 'GameMechanics\\Creature\\Creatures\\Neutrals\\creature_%d.xdb' %i
            path = read_files( file, 'Visual href="', '#xpointer')
            icon_path = read_files(path[0], 'Icon128 href="', '.xdb')
            icon = icon_path[0].split('\\')[-1]
            editor_link = 'MapObjects\\_(AdvMapObjectLink)\\Monsters\\NCF\\Creature_%d.xdb' %i
            copyfile(join(source, icon_path[0] + ".dds"), join(icon_dest, 'Creature_%d.dds' %i ))
            dirr = editor_link.split('\\')
            try:
                makedirs(destination + '\\'.join(dirr[0:len(dirr)-1]))
            except:
                pass
            print(join(destination, editor_link))
            NCF = open(join(destination, editor_link), 'w')
            first = '<IconFile>'
            second = '</IconFile>'
            for line in open(join(source, editor_link)):
                print(line)
                try:
                    start = line.index( first ) + len( first )
                    end = line.index( second, start )
                    string = line[start:end]
                    NCF.write('\t' + first + 'Icons\\Creature_%d.dds' %i + second + '\n')
                except ValueError:
                    NCF.write(line)
            NCF.close
            print(i, path, icon_path, icon)
        except:
            pass
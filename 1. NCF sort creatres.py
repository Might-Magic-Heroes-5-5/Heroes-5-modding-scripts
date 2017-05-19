'''
Created on Apr 28, 2017

@author: dred
'''
from os import makedirs, walk
from os.path import isfile, join
from shutil import copyfile, move
import re

#source = 'D:\\mod workplace\\NCF_MegaPack'
source = 'D:\\mod workplace\\NCF_MegaPack'
dest = 'D:\\mod workplace\\New_NCF\\'
 
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

#mypath = 'C:/Users/yordan.kostov/Desktop/NCF_MegaPack/GameMechanics/Creature/Creatures/Neutrals'
#mypath = 'C:\\Users\\dred\\Desktop\\NCF\\NCF_MegaPack\\GameMechanics\\Creature\\Creatures\\Neutrals'
#mypath = 'D:\\mod workplace\\NCF_MegaPack\\GameMechanics\\Creature\\Creatures\\Neutrals'

defaultt = [ 'Academy', 'Haven', 'Dwarves', 'Necropolis', 'Dungeon', 'Preserve', 'Orcs', 'Inferno']

#for race in defaultt:
#for root, dirs, files in walk(join(source, 'GameMechanics\\Creature\\Creatures\\')): 
#    for f in files:
#        destination = (dest + f.split('.')[0] + '\\')
#        print(('\\').join(root.split('\\')[3:]) + '\\' + f)
#        get_file_trees(('\\').join(root.split('\\')[3:]) + '\\' + f)
    
#for i in range(1,1000):
i = 345
destination = join(dest, '%d\\' %i)
get_file_trees('GameMechanics\\Creature\\Creatures\\Neutrals\\Creature_%d.xdb' %i )
#get_file_trees('Characters\\Creatures\\Academy\\Colossus_LOD_view.xdb')
get_file_trees('MapObjects\\_(AdvMapObjectLink)\\Monsters\\NCF\\Creature_%d.xdb' %i )
get_file_trees('scripts\\Creature_%d.lua' % i)
get_file_trees('Cameras\\Interface\\HireCreatures\\Creature_%d.(Camera).xdb' % i)
    #_LOD.(Character)
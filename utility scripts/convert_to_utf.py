import os;
import sys;
filePathSrc="D:\\mod workplace\\NCF\\Raw\\NCF_separated"
files = [f for f in os.listdir(filePathSrc)]
for fold in files:
		print(fold)
		#texts = [t for t in os.listdir(filePathSrc + "\\" + fold + "\\Text\\Game\\Creatures\\Neutrals\\")]
		for root, dirs, fils in os.walk(filePathSrc + "\\" + fold + "\\Text\\Game\\Creatures\\"):
				for fls in fils:
						if "desc" not in fls and "Desc" not in fls:
								print(root + "\\" + fls)
								notepad.open(root + "\\" + fls)
								console.write(root + "\\" + fls + "\r\n")
								notepad.runMenuCommand("Encoding", "Convert to UTF-8")
								notepad.save()
								notepad.close()

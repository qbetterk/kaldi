#!/usr/bin/env python
#
import sys

new_file = []
count 	 = 0
pre_file = None
pre_spk  = None
file = open(sys.argv[1],"r+b")
file_content = file.readlines()
for line in file_content:
	part = line.split("_")

	if part[0]+part[1] == pre_file and part[2] == pre_spk:
		if count < 5:
			new_file.append(line)
			pre_file = part[0]+part[1]
			pre_spk  = part[2]
		else:
			pass
		count += 1

	else:
		new_file.append(line)
		pre_file = part[0]+part[1]
		pre_spk  = part[2]
		count = 0
		
file.seek(0)
file.truncate()
file.write("".join(new_file))
file.close()

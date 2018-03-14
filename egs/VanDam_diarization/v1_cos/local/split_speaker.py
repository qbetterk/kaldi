#!/usr/bin/env python
#
import sys
import pdb
# sys.argv = ["split_speaker.py", "utt2spk"]
label = 1
count = 1
pre_speaker = None
pre_file = None
file = open(sys.argv[1], "r+b")
file_content = file.readlines()	
for i in range(len(file_content)):

	part = file_content[i].split("_")

	if part[0] + part[1] != pre_file or part[2] != pre_speaker:
		count = 1
		label = 1
	pre_speaker = part[2]
	pre_file = part[0] + part[1]

	part[2] = part[2] + "-" + str(label).zfill(2)

	if sys.argv[1][-7:] == "utt2spk":
		part[-1] = part[-1].split("\n")[0] + "-" + str(label).zfill(2) + "\n"

	file_content[i] = "_".join(part)

	if count == 5:
		count = 1
		label += 1
	else:
		count += 1

file.seek(0)
file.truncate()
file.write("".join(file_content))
file.close()





#!/usr/bin/env python
#
#
#
#
import sys

total = []
speaker = []
pre_data = "start"
for _ in open(sys.argv[1]).readlines():
	line = _.split()
	if line[0] != pre_data and pre_data != "start":
		total.append([pre_data, len(speaker)])
		speaker = [line[1],]
	elif line[1] not in speaker:
		speaker.append(line[1])
	pre_data = line[0]
total.append([pre_data, len(speaker)])

total.sort(key=lambda word: word)
for item in total:
	sys.stdout.write("%s   %d\n" %(item[0], item[1]))


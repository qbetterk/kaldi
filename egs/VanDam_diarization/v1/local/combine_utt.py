#!/usr/bin/env python
#
import sys
import pdb

#sys.argv = ["combine_utt.py", "./"]


# for segments 
def combine_segments():
	segments = open(sys.argv[1] + "segments").readlines()
	new_segments = open(sys.argv[1] + "new_segments", "w+")

	new_utt = segments[0].replace("_"," ").split()
	for line in segments[1:]:
		utt = line.replace("_"," ").split()
		if utt[:3] == new_utt[:3] and utt[3] == new_utt[4]:
			new_utt[4] = utt[4]
			new_utt[-1] = utt[-1]
		else:
			new_segments.write(" ".join(["_".join(new_utt[:5]), \
						 "_".join(new_utt[5:7]), new_utt[7], new_utt[8]]) + "\n")
			new_utt = utt


# for utt2spk
def combine_utt2spk():
	utt2spk = open(sys.argv[1] + "utt2spk").readlines()
	new_utt2spk = open(sys.argv[1] + "new_utt2spk", "w+")

	new_utt = utt2spk[0].replace("_"," ").split()
	for line in utt2spk[1:]:
		utt = line.replace("_"," ").split()
		if utt[:3] == new_utt[:3] and utt[3] == new_utt[4]:
			new_utt[4] = utt[4]
		else:
			new_utt2spk.write(" ".join(["_".join(new_utt[:5]), "_".join(new_utt[5:7])]) + "\n")
			new_utt = utt


def main():
	combine_segments()
	combine_utt2spk()

if __name__ == "__main__":
	main()

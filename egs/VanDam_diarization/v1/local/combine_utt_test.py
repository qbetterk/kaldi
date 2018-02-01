#!/usr/bin/env python
#
import sys
import pdb

# sys.argv = ["combine_utt.py", "./data/"]


# for segments 
def combine_segments():
	# print sys.argv[1] + "segments"
	segmentsfile = open(sys.argv[1] + "segments")
	segments     = segmentsfile.readlines()
	new_segments = open(sys.argv[1] + "new_segments", "w+")

	new_utt = segments[0].replace("_"," ").split()
	for line in segments[1:]:
		utt = line.replace("_"," ").split()
		if utt[:2] == new_utt[:2] and utt[2] == new_utt[3]:
			new_utt[3] = utt[3]
			new_utt[-1] = utt[-1]
		else:
			new_segments.write(" ".join(["_".join(new_utt[:4]), \
						 "_".join(new_utt[4:6]), new_utt[6], new_utt[7]]) + "\n")
			new_utt = utt
	# print type(segments)
	segmentsfile.close()
	new_segments.close()


# for utt2spk
def combine_utt2spk():
	utt2spkfile = open(sys.argv[1] + "utt2spk")
	utt2spk     = utt2spkfile.readlines()
	new_utt2spk = open(sys.argv[1] + "new_utt2spk", "w+")

	new_utt = utt2spk[0].replace("_"," ").split()
	for line in utt2spk[1:]:
		utt = line.replace("_"," ").split()
		if utt[:2] == new_utt[:2] and utt[2] == new_utt[3]:
			new_utt[3] = utt[3]
		else:
			new_utt2spk.write(" ".join(["_".join(new_utt[:4]), "_".join(new_utt[4:6])]) + "\n")
			new_utt = utt
	utt2spkfile.close()
	new_utt2spk.close()


def main():
	combine_segments()
	combine_utt2spk()

if __name__ == "__main__":
	main()

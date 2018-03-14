import sys, os

src_dir = sys.argv[1]
data_dir = sys.argv[2]
num_missing = 0
num_found = 0
utt2len = {}
utt2len_fi = open(data_dir + "/utt2num_frames", 'r').readlines()
for l in utt2len_fi:
  utt, dur = l.rstrip().split()
  utt2len[utt] = int(dur)
vadtxt = open(data_dir + "/vad.txt" , 'w')
for subdir, dirs, files in os.walk(src_dir):
  for file in files:
    filename = os.path.join(subdir, file)
    if filename.endswith(".txt"):
      lines = open(filename, 'r').readlines()
      if "POI" in lines[0]:
        spkr = lines[0].rstrip().split()[1].replace(".","")
        ytid = lines[1].rstrip().split()[2]
        utt_id = spkr + "-" + ytid
        if utt_id in utt2len:
          dur = utt2len[utt_id]
          flac_path = src_dir + "/" + ytid + ".flac"
          if os.path.isfile(flac_path):
            vad = dur * [0]
            for l in lines[5:]:
              start, end = l.rstrip().split()
              start = int(float(start) * 100)
              end = int(float(end) * 100)
              for i in range(start, min(end, dur)):
                vad[i] = 1
            vadtxt.write(utt_id + "  [ " + " ".join(map(str,vad)) + " ]\n")
            num_found += 1
          else:
            print "File " + flac_path + " doesn't exist"
            num_missing += 1
print "Missing " + str(num_missing) + " files out of " + str(num_missing + num_found)





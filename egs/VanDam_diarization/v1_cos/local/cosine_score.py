#!/usr/bin/env python
#
import sys
import numpy as np
from numpy import linalg as la
import matplotlib.pyplot as plt
import pdb

# sys.argv = ["cosin_score.py", "data/ivectors","data/cos_score"]
'''
input format:  cosin_score.py input_matrix output_matrix
'''
def check_argv():

	if len(sys.argv) != 3:
		sys.stderr.write("ERROR: file wrongly called!")
		sys.stderr.write("standard form: cosin_score.py input_matrix output_matrix")
		quit()
	else:
		try:
			open(sys.argv[1])
		except IOError:
			print 'ERROR: invalid input file name.'
			quit()
		# else:
		# 	try:
		# 		open(sys.argv[2], "w+")
		# 	except IOError:
		# 		print 'ERROR: invalid output file name.'
		# 		quit()


def cosine_score(ivector_file):
	# # input is a np.array with each line an ivector of a segment.
	score  = np.absolute(np.dot(ivector_file, ivector_file.transpose()))
	norm   = np.array([la.norm(ivector_file, axis=1)])
	score /= np.dot(np.transpose(norm), norm)

	return score

def plot(matrix):
	count = np.zeros(100)

	for i in range(len(matrix)):
		for j in range(i+1):
			count[int(matrix[i,j] * 100) - 1] += 1
	print count[90:], matrix.shape

	plt.figure()
	plt.plot(np.arange(100), count)
	plt.show()

def write_file(matrix, file_name, app):
	if app == 0:
		file = open(sys.argv[2], "w+")
	else:
		file = open(sys.argv[2], "a")
	file.write(file_name+"  [\n")
	for i in range(len(matrix)):
		file.write("  ")
		for j in matrix[i]:
			file.write("%.7f" %j + " " )
		if i == len(matrix) - 1:
			file.write("]\n")
		else:
			file.write("\n")
	file.close()

def main():
	# # initialization
	pre_file_name = open(sys.argv[1]).readlines()[0].split("-")[0]
	ivector_file  = []

	i=0
	for line in open(sys.argv[1]).readlines()[1:]:
		if line[-2] == "[":
			# # check the utterance ID
			file_name = line.split("-")[0]
			if file_name != pre_file_name: # # here comes a new recording
				# # compute the cosine score for the last file
				score = cosine_score(np.array(ivector_file))
				write_file(score, pre_file_name, i)
				# plot(score)
				# pdb.set_trace()
				ivector_file  = []
				pre_file_name = file_name
				i += 1
		else:
			ivector_file.append(map(float, line.split()[:-1]))

if __name__ == "__main__":
	main()
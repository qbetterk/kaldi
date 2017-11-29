#!/usr/bin/env python
###########################################################################
#   copyright            : (C) 2013 by Lukas Burget,UPGM,FIT,VUT,Brno     #
#   email                : burget@fit.vutbr.cz                            #
###########################################################################
#                                                                         #
#   This program is free software; you can redistribute it and/or modify  #
#   it under the terms of the GNU General Public License as published by  #
#   the Free Software Foundation; either version 2 of the License, or     #
#   (at your option) any later version.                                   #
#                                                                         #
###########################################################################

import numpy as np
import VB_diarization

# read UBM and iXtractor (total variability) subspace
m  = np.loadtxt("UBM_means.txt", dtype=np.float32)
iE = 1.0 / np.loadtxt("UBM_vars.txt", dtype=np.float32)
w  = np.loadtxt("UBM_weights.txt", dtype=np.float32)
V  = np.loadtxt("iXtractor.txt", dtype=np.float32).reshape(-1,*m.shape)

# load MFCC features
X=np.loadtxt("features.txt")

#load reference per-frame labels (0: silence; 1: both; 2: speaker; A 3: speaker B)
ref=np.loadtxt("ref.txt", dtype=int)

# keep only frames with one speaker (to make scoring simple)
X = X[ref > 1]
ref = ref[ref > 1] - 2

VtiEV = VB_diarization.precalculate_VtiEV(V, iE)

q = None
#q = VB_diarization.frame_labels2posterior_mx(ref) # initialize from the reference

# runing with one 25 frame (0.25s) resolution; about 2.5 faster
q, sp, L = VB_diarization.VB_diarization(X, m, iE, w, V, sp=None, q=None, maxSpeakers=2, maxIters=10, VtiEV=VtiEV,
                                  downsample=25, alphaQInit=1.0, sparsityThr=0.001, epsilon=1e-6, minDur=1,
                                  loopProb=0.9, statScale=0.3, llScale=1.0, ref=ref, plot=False)

# runing with one frame resolution
q, sp, L = VB_diarization.VB_diarization(X, m, iE, w, V, sp=None, q=None, maxSpeakers=2, maxIters=10, VtiEV=VtiEV,
                                  downsample=1, alphaQInit=1.0, sparsityThr=0.001, epsilon=1e-6, minDur=1,
                                  loopProb=0.998, statScale=0.3, llScale=1.0, ref=ref, plot=True)

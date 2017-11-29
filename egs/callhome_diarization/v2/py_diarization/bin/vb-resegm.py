#!/usr/bin/env python

from __future__ import absolute_import
from __future__ import print_function

import sys
import os
import argparse
import time
import numpy as np
from six.moves import xrange
import scipy.linalg as la


from py_diarization.utils.list_utils import ismember
from py_diarization.utils.scp_list import SCPList
from py_diarization.io import HypDataReader
from py_diarization.transforms import TransformList, PCA, LDA, LNorm
from py_diarization.VB_diarization import VBDiar


def read_models(model_path):
    cent_file = model_path + '/mean.vec.txt'
    whiten_file = model_path + '/transform.mat.txt'
    plda_file = model_path + '/plda.txt'

    mu = np.loadtxt(cent_file)
    T = np.loadtxt(whiten_file).T
    lnorm = LNorm(mu=mu, T=T, name='ln')

    S = np.sqrt(mu.shape[0])*np.eye(mu.shape[0])
    pca = PCA(mu=np.zeros_like(mu), T=S, name='pca')
    
    plda_mat = np.loadtxt(plda_file)
    mu = plda_mat[0]
    T = plda_mat[1:-1].T
    psi = plda_mat[-1]
    lda = LDA(mu=mu, T=T, name='lda')

    tl = TransformList([lnorm, pca, lda])

    V = np.diag(np.sqrt(psi))
    mu = np.zeros((1, V.shape[0]))
    iE = np.ones((1, V.shape[0]))

    plda = [mu, V, iE ]
    return tl, plda


def read_labels(file_path):
    with open(file_path, 'r') as f:
        fields = [line.rstrip().split(sep=' ') for line in f]
    segments = np.asarray([i[0] for i in fields])
    spk_ids = np.asarray([int(i[1]) for i in fields])
    key = np.asarray([i.split(sep='-')[0] for i in segments])

    return [key, segments, spk_ids]


def get_segm_labels(labels, key):
    f, loc = ismember(labels[0], [key])
    return  labels[1][f], labels[2][f]


def write_labels(f_out, segments, spk_ids):
    for item in zip(segments, spk_ids):
        f_out.write('%s %d\n' % (item[0], item[1]))

        
def int2onehot(ids):
    n = np.max(ids)+1
    y = np.zeros((len(ids), n))
    y[np.arange(len(ids)), ids]=1
    return y

def p2int(y):
    return np.argmax(y, axis=-1)
    


def diarize_sequence(hr, key, init_labels, tl, plda, f_out, 
                     loop_prob, stat_scale, min_dur, sparsity_thr, post_thr, pca_dim):
    segments, spk_ids = get_segm_labels(init_labels, key)
    x = hr.read(segments, return_tensor=True)
    x = tl.predict(x)

    mu = plda[0][:,:pca_dim]
    V=plda[1]
    #iE does not change with the PCA
    iE = plda[2][:,:pca_dim]
    
    
    if pca_dim<x.shape[1]:
        pca = PCA()
        pca.fit(x=x, pca_dim=pca_dim)
        x = pca.predict(x)
        V = np.dot(V, pca.T) #[:pca_dim,:]
        
        # V2 = plda[1]
        # V2 = np.dot(V2, pca.T)
        # C2 = np.dot(V2.T, V2)
        # d, V2 = la.eigh(C2)
        # V2 *= np.sqrt(d)
        # V2 = np.expand_dims(V2, axis=1)
    
    V = np.expand_dims(V, axis=1)
    
    q_init = int2onehot(spk_ids)
    sp_init = np.mean(q_init, axis=0)
    q, sp, Li = VBDiar(x, m=mu, iE=iE, V = V, w=np.ones((1,)),
                       maxSpeakers=np.max(spk_ids)+1, loopProb=loop_prob,
                       statScale=stat_scale, sparsityThr=sparsity_thr, llScale=1.0,
                       minDur=min_dur, q=q_init, sp=sp_init)
    spk_ids = p2int(q)
    write_labels(f_out, segments, spk_ids)


def diarize_all(iv_file, file_list, init_label_file, model_path, output_path, **kwargs):


    hr = HypDataReader(iv_file)
    scp = SCPList.load(file_list)
    init_labels = read_labels(init_label_file)
    tl, plda = read_models(model_path)
    with open(output_path+'/labels', 'w') as f_out:
        for key in scp.key:
            diarize_sequence(hr, key, init_labels, tl, plda, f_out, **kwargs)
    
        

if __name__ == "__main__":

    parser=argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        fromfile_prefix_chars='@',
        description='VB resegmentation')

    parser.add_argument('--iv-file', dest='iv_file', required=True)
    parser.add_argument('--file-list', dest='file_list', required=True)
    parser.add_argument('--init-label-file', dest='init_label_file', required=True)
    parser.add_argument('--model-path', dest='model_path', required=True)
    parser.add_argument('--output-path', dest='output_path', required=True)
    parser.add_argument('--loop-prob', dest='loop_prob', type=float, default=0.9)
    parser.add_argument('--stat-scale', dest='stat_scale', type=float, default=1.0)
    parser.add_argument('--min-dur', dest='min_dur', type=int, default=1)
    parser.add_argument('--sparsity-thr', dest='sparsity_thr', type=float, default=0.001)
    parser.add_argument('--post-thr', dest='post_thr', type=float, default=0)
    parser.add_argument('--pca-dim', dest='pca_dim', type=int, default=10)
    
    args=parser.parse_args()
    
    diarize_all(**vars(args))





    



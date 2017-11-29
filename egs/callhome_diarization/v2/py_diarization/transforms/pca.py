"""
Computes PCA
"""

from __future__ import absolute_import
from __future__ import print_function
from __future__ import division
from six.moves import xrange

import numpy as np
import h5py

import scipy.linalg as la

from ..hyp_model import HypModel

class PCA(HypModel):
    def __init__(self, mu=None, T=None, **kwargs):
        super(PCA, self).__init__(**kwargs)
        self.mu = mu
        self.T = T

        
    def predict(self, x):
        if self.mu is not None:
            x = x - self.mu
        return np.dot(x, self.T)
    
    def fit(self, x=None, mu=None, C=None, pca_dim=None):
        if x is not None:
            mu = np.mean(x, axis=0)
            d = x - mu
            C=np.dot(d.T, d)/len(x)
            
        self.mu = mu

        d, V = la.eigh(C)
        V = np.fliplr(V)

        p = V[1,:] <0
        V[:,p] *= -1

        
        if pca_dim is not None:
            assert(pca_dim <= V.shape[1])
            V = V[:,:pca_dim]

        self.T = V

        
    def save_params(self, f):
        params = {'mu': self.mu,
                  'T': self.T}
        self._save_params_from_dict(f, params)


    @classmethod
    def load_params(cls, f, config):
        param_list = ['mu', 'T']
        params = cls._load_params_to_dict(f, config['name'], param_list)
        return cls(mu=params['mu'], T=params['T'], name=config['name'])

    # @classmethod
    # def load(cls, file_path):
    #     with h5py.File(file_path, 'r') as f:
    #         config = self.load_config_from_json(f['config'])
    #         param_list = ['mu', 'T']
    #         params = self._load_params_to_dict(f, config['name'], param_list)
    #         return cls(mu=params['mu'], T=params['T'], name=config['name'])
    
        
    @classmethod
    def load_mat(cls, file_path):
        with h5py.File(file_path, 'r') as f:
            mu = np.asarray(f['mu'], dtype='float32')
            T = np.asarray(f['T'], dtype='float32')
            return cls(mu, T)

    def save_mat(self, file_path):
        with h5py.File(file_path, 'w') as f:
            f.create_dataset('mu', data=self.mu)
            f.create_dataset('T', data=self.T)



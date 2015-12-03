#!/usr/global/bin/python2.7
# this script is for v1.2, NOT cmp beta
#
# -David Grayson 2012

import networkx as nx
import sys, cfflib, scipy.io
import numpy as np

if (len(sys.argv) == 7):

	#assign variables to all command line args
	dirs = {'wave': sys.argv[1], 'sub': sys.argv[2], 'scale': sys.argv[3], 'sub_name': sys.argv[4], 'weight': sys.argv[5], 'outdir': sys.argv[6]}

	#load .pkl file
	cfile=cfflib.load('%(sub)s/%(wave)s/CMP/cff/%(sub_name)s_%(wave)s.cff' % dirs)
	cnet = cfile.get_by_name('connectome_%(scale)s' % dirs)
	cnet.load()
	g = cnet.data

	#fill matrix with desired edge
	for u,v,d in g.edges_iter(data=True):
	    d['weight'] = d['%(weight)s' % dirs]

	#assign bb variable to matrix
	bb=nx.to_numpy_matrix(g)

	#output as .txt file if using number of fibers or fiber length as weight
	matweight = '%(weight)s' % dirs
	if matweight in ['number_of_fibers', 'fiber_length_mean', 'fiber_length_std']:
	    np.savetxt('%(outdir)s/%(sub_name)s_%(wave)s_%(scale)s_%(weight)s.txt' % dirs, bb, fmt='%u')
	#or as .mat file if using any other weight (some glitch is causing .txt files to come up with all 0's)
	else:
	    scipy.io.savemat('%(outdir)s/%(sub_name)s_%(wave)s_%(scale)s_%(weight)s' % dirs, mdict={'matrix': bb})
else:
	print '\nERROR:', len(sys.argv)-1, 'arguments given. Needs 6.'
	print '\nUsage:		cmp_getMatrix.py <timepoint> <path/to/subjectID> <matrix_type> <subjectID> <connection_weight> <output_directory>\n'
	print 'example:	cmp_getMatrix.py W1 10299 scale125 10299 number_of_fibers .'
	print 'OR:		cmp_getMatrix.py W1 McDonnell/10299 scale125 10299 fiber_length_mean Fiber_Lengths_Dir\n'
	print 'matrix_type options:\n\'freesurfer_aparc\'\n\'scale33\'\n\'scale60\'\n\'scale125\'\n\'scale250\'\n\'scale500\'\n'
	print 'connection_weight options:\n\'number_of_fibers\'\n\'fiber_length_mean\'\n\'fiber_length_std\'\n\'gfa_mean\' (HARDI/DSI data only)\n\'gfa_std\' (HARDI/DSI data only)\n\'fa_mean\' (DTI only)\n\'fa_std\' (DTI only)\n\'adc_std\' (DTI only)\n\'adc_mean\' (DTI only)\n'

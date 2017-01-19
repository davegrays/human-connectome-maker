#!/usr/global/bin/python2.7
#
# this script is for v2.1-beta
#
# -David Grayson 2015

""" Building custom matrix by combining custom parcellation with precomputed .trk files
"""

#generic imports
import sys, os, glob, ast, ConfigParser

#command usage
if len(sys.argv) != 5:
    print '\nUsage:	python2.7', sys.argv[0], 'subject_folder', 'config_file', 'parcellation_name', '/native/cmp_nipype/build/library'
    print '\ni.e.:	python2.7', sys.argv[0], '10999-1', '10999-1.ini', 'Gordon', '/group_shares/PSYCH/code/release/pipelines/CMP_beta_v02/cmp_nipype/build/lib', '\n'
    sys.exit()

#nipype imports
import nipype.interfaces.freesurfer as fs
import nipype.interfaces.fsl as fsl
import nipype.pipeline.engine as pe

#from the cmp build library, import connectome methods
#for some reason, this doesn't work if you leave out 'python' from the beginning of the command call
prevdir=os.getcwd()
os.chdir(sys.argv[4])
from cmtklib.connectome import cmat, prob_cmat, probtrackx_cmat
os.chdir(prevdir)

class CustomMatSub(object):
    def __init__(self, sub_dir, config_path, parc_name):
        self.sub_dir = os.path.abspath(sub_dir) #use the absolute path here
        config = ConfigParser.ConfigParser()
	config.read(config_path)
	self.parc_name = parc_name
	self.config = config
        self.atlas_info = ast.literal_eval(config.get('parcellation_stage','atlas_info'))
        self.parcellation_scheme = config.get('parcellation_stage','parcellation_scheme')
        self.atlas_nifti_file = config.get('parcellation_stage','atlas_nifti_file')
        self.resampling = ast.literal_eval(config.get('diffusion_stage','resampling'))
        l = list(config.get('connectome_stage','output_types'))
        self.output_types = "".join([x for x in l if x.isalpha() or x == " "]).split()
        self.probtrackx = "True" == config.get('connectome_stage','probtrackx')
        self.nonlinear_reg = "Nonlinear (FSL)" == config.get('registration_stage','registration_mode')
        self.compute_curvature = "True" == config.get('connectome_stage','compute_curvature')
        self.roi_volumes = ['/group_shares/FAIR_ASD/Projects/UCDavis_APP/mapped/109493-100/NIPYPE/diffusion_pipeline/diffusion_stage/dilate_rois/mapflow/_dilate_rois0/ROIv_HR_th_scale125_flirt_out_dil.nii.gz', '/group_shares/FAIR_ASD/Projects/UCDavis_APP/mapped/109493-100/NIPYPE/diffusion_pipeline/diffusion_stage/dilate_rois/mapflow/_dilate_rois1/ROIv_HR_th_scale33_flirt_out_dil.nii.gz', '/group_shares/FAIR_ASD/Projects/UCDavis_APP/mapped/109493-100/NIPYPE/diffusion_pipeline/diffusion_stage/dilate_rois/mapflow/_dilate_rois2/ROIv_HR_th_scale250_flirt_out_dil.nii.gz', '/group_shares/FAIR_ASD/Projects/UCDavis_APP/mapped/109493-100/NIPYPE/diffusion_pipeline/diffusion_stage/dilate_rois/mapflow/_dilate_rois3/ROIv_HR_th_scale500_flirt_out_dil.nii.gz', '/group_shares/FAIR_ASD/Projects/UCDavis_APP/mapped/109493-100/NIPYPE/diffusion_pipeline/diffusion_stage/dilate_rois/mapflow/_dilate_rois4/ROIv_HR_th_scale60_flirt_out_dil.nii.gz']
        #self.roi_volumes = glob.glob(self.sub_dir + '/NIPYPE/diffusion_pipeline/diffusion_stage/dilate_rois/mapflow/_dilate_rois/*.nii.gz')

    def generate_tracklist(self):
	if self.probtrackx:
        	trk_parent_dir = '/NIPYPE/diffusion_pipeline/diffusion_stage/tracking/probtrackx/mapflow/'
        	trkdirs = next(os.walk(self.sub_dir + trk_parent_dir))[1]
        	self.track_file = [self.sub_dir + trk_parent_dir + dir + '/matrix_seeds_to_all_targets' for dir in trkdirs]
	else:
        	trk_parent_dir = '/NIPYPE/diffusion_pipeline/diffusion_stage/tracking/trackvis/mapflow/'
        	trkdirs = next(os.walk(self.sub_dir + trk_parent_dir))[1]
        	self.track_file = [self.sub_dir + trk_parent_dir + dir + '/converted.trk' for dir in trkdirs]

    def build_matrix(self):
        #make sure you output into cmp's connectome folder
        prevdir=os.getcwd()
        os.chdir(self.sub_dir + '/NIPYPE/diffusion_pipeline/connectome_stage/compute_matrice')
        #only prob_cmat has been successfully tested as of 12.18.2015
        #cmat takes extra arguments compute_curvature and additional_maps
        #hard to say if probtrackx will work; if it doesn't, the issue's probably in generate_tracklist
        if self.probtrackx:
            probtrackx_cmat(voxel_connectivity_files = self.track_file, roi_volumes=self.roi_volumes,
             parcellation_scheme=self.parcellation_scheme, atlas_info=self.atlas_info,
             output_types = self.output_types)
        elif len(self.track_file) > 1:
            prob_cmat(intrk=self.track_file, roi_volumes=self.roi_volumes,
             parcellation_scheme=self.parcellation_scheme,atlas_info = self.atlas_info,
             output_types=self.output_types)
        else:
            additional_maps = {}
            cmat(intrk=self.track_file[0], roi_volumes=self.roi_volumes,
             parcellation_scheme=self.parcellation_scheme,atlas_info = self.atlas_info,
             compute_curvature=self.compute_curvature,
             additional_maps=additional_maps,output_types=self.output_types)
        os.chdir(prevdir)

print "\n**** BEGINNING Dave's custom matrix creation ****\n"

subject = CustomMatSub(sys.argv[1], sys.argv[2], sys.argv[3])
subject.generate_tracklist()
subject.build_matrix()

print "\n**** DONE with Dave's custom matrix creation ****\n"

""" For debugging, N.B. there must be 5 attributes similar to these:
* subject.atlas_info : {'GordonParc_reslice': {'node_information_graphml': '/group_shares/FAIR_ASD/Projects/UCDavis_APP/mapped/108970-100/FREESURFER/label/GordonParc.graphml', 'number_of_regions': 332}}
* subject.output_types : ['mat', 'cff', 'gPickle']
* subject.parcellation_scheme : Custom
* subject.roi_volumes : ['/group_shares/FAIR_ASD/Projects/UCDavis_APP/mapped/108970-100/NIPYPE/diffusion_pipeline/diffusion_stage/dilate_rois/mapflow/_dilate_rois0/GordonParc_reslice_flirt_out_dil.nii.gz']
* subject.track_file : ['/group_shares/FAIR_ASD/Projects/UCDavis_APP/mapped/108970-100/NIPYPE/diffusion_pipeline/diffusion_stage/tracking/trackvis/mapflow/_trackvis0/converted.trk', '/group_shares/FAIR_ASD/Projects/UCDavis_APP/mapped/108970-100/NIPYPE/diffusion_pipeline/diffusion_stage/tracking/trackvis/mapflow/_trackvis1/converted.trk', etc. etc. ... ]
"""

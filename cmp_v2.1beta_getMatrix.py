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
	#roi_volumes and track_file lists generated by other functions

    def generate_tracklist(self):
        trk_parent_dir = '/NIPYPE/diffusion_pipeline/diffusion_stage/tracking/trackvis/mapflow/'
        trkdirs = next(os.walk(self.sub_dir + trk_parent_dir))[1]
        self.track_file = [self.sub_dir + trk_parent_dir + dir + '/converted.trk' for dir in trkdirs]

    def register_volumes(self):
        #initialize NIPYPE interface workflow
        register = pe.Workflow(name = self.parc_name + '_to_b0')
        register.base_dir = self.sub_dir + '/FREESURFER/label'
        # define node 1: transform
        XFM = pe.Node(interface=fsl.ApplyXfm(in_file = self.atlas_nifti_file, in_matrix_file = self.sub_dir + '/NIPYPE/diffusion_pipeline/registration_stage/linear_registration/T1-TO-TARGET.mat', apply_xfm=True, interp='nearestneighbour', reference = self.sub_dir + '/NIPYPE/diffusion_pipeline/registration_stage/target_resample/target_first.nii.gz'), name='applyxfm')
        #  define node 2: resample
        RES = pe.Node(interface=fs.MRIConvert(out_type='nii', resample_type='nearest', vox_size=self.resampling), name='resample')
        #  define node 3: dilate
        DIL = pe.Node(interface=fsl.DilateImage(operation='modal'), name='dilate')
        
        #run workflow according to connectome type
        if self.probtrackx or len(self.track_file) > 1:
                #connect transform, resample, and dilate nodes
                register.connect([(XFM, RES, [('out_file','in_file')])])
                register.connect([(RES, DIL, [('out_file','in_file')])])
                #run workflow
                register.run()
                #assign list output to self.roi_volumes
                self.roi_volumes = glob.glob(register.base_dir + '/' + register.name + '/dilate/*.nii.gz')
        else:
                print 'register_volumes() method not yet defined for deterministic matrices. sorry.'
                print 'This method should depend on whether or not ROI dilation is turned on in the config file'
                print 'On the other hand, custom parcellation with deterministic tracto should work fine with the connectomemapper -David 2015'
                sys.exit('Exited script with error.')

    def build_matrix(self):
        #make sure you output into cmp's connectome folder
        prevdir=os.getcwd()
        os.chdir(self.sub_dir + '/NIPYPE/diffusion_pipeline/connectome_stage/compute_matrice')
        #only prob_cmat has been successfully tested as of 12.18.2015
        #cmat will need extra arguments compute_curvature and additional_maps
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
            cmat(intrk=self.track_file[0], roi_volumes=self.roi_volumes,
             parcellation_scheme=self.parcellation_scheme,atlas_info = self.atlas_info,
             compute_curvature=self.compute_curvature,
             additional_maps=additional_maps,output_types=self.output_types)
        os.chdir(prevdir)

print "\n**** BEGINNING Dave's custom matrix creation ****\n"

subject = CustomMatSub(sys.argv[1], sys.argv[2], sys.argv[3])
subject.generate_tracklist()
subject.register_volumes()
subject.build_matrix()

print "\n**** DONE with Dave's custom matrix creation ****\n"

""" For debugging, N.B. there must be 5 attributes similar to these:
* subject.atlas_info : {'GordonParc_reslice': {'node_information_graphml': '/group_shares/FAIR_ASD/Projects/UCDavis_APP/mapped/108970-100/FREESURFER/label/GordonParc.graphml', 'number_of_regions': 332}}
* subject.output_types : ['mat', 'cff', 'gPickle']
* subject.parcellation_scheme : Custom
* subject.roi_volumes : ['/group_shares/FAIR_ASD/Projects/UCDavis_APP/mapped/108970-100/NIPYPE/diffusion_pipeline/diffusion_stage/dilate_rois/mapflow/_dilate_rois0/GordonParc_reslice_flirt_out_dil.nii.gz']
* subject.track_file : ['/group_shares/FAIR_ASD/Projects/UCDavis_APP/mapped/108970-100/NIPYPE/diffusion_pipeline/diffusion_stage/tracking/trackvis/mapflow/_trackvis0/converted.trk', '/group_shares/FAIR_ASD/Projects/UCDavis_APP/mapped/108970-100/NIPYPE/diffusion_pipeline/diffusion_stage/tracking/trackvis/mapflow/_trackvis1/converted.trk', etc. etc. ... ]
"""

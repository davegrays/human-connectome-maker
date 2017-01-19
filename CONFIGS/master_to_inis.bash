#!/bin/bash

echo "diffusion_MasterTemplate.ini uses gibbs CSD. from this file, we make .ini files for gibbs tensor, dtk, mrtrix csd deterministic, mrtrix tensor deterministic, and mrtrix csd probabilistic."

#gibbs CSD
cat diffusion_MasterTemplate.ini > diffusion_GibbsCSD.ini

#gibbs tensor
cat diffusion_MasterTemplate.ini | sed 's/gibbs_recon_config.recon_model = CSD/gibbs_recon_config.recon_model = Tensor/' > diffusion_GibbsTensor.ini

#dtk
cat diffusion_MasterTemplate.ini | sed 's/processing_tool = Gibbs/processing_tool = DTK/' > diffusion_DTK.ini

#mrtrix csd deterministic
cat diffusion_MasterTemplate.ini | sed 's/processing_tool = Gibbs/processing_tool = MRtrix/' > diffusion_MRtrixCSD.ini

#mrtrix tensor deterministic
cat diffusion_MRtrixCSD.ini | sed 's/mrtrix_recon_config.local_model = True/mrtrix_recon_config.local_model = False/' | sed 's/mrtrix_tracking_config.sd = True/mrtrix_tracking_config.sd = False/'> diffusion_MRtrixTensor.ini

#mrtrix csd probabilistic
cat diffusion_MRtrixCSD.ini | sed 's/= Deterministic/ = Probabilistic/' | sed "s/'Deterministic'/'Deterministic', 'Probabilistic'/" > diffusion_MRtrixCSD_prob.ini

#FSL's probtrackX
cat diffusion_MasterTemplate.ini | sed 's/processing_tool = Gibbs/processing_tool = FSL/' | sed 's/= Deterministic/ = Probabilistic/' | sed "s/'Deterministic'/'Deterministic', 'Probabilistic'/" > diffusion_probtrackX.ini

#add this pipe command for FSL if you can figure out dilation error
# | sed 's/dilate_rois = True/dilate_rois = False/'

########################
#here's the error:::::
#	 Executing node 00a9971d6eb94f7a62cb811729d93b4c in dir: /group_shares/FAIR_ASD/Projects/UCDavis_APP/mapped/109493-100/NIPYPE/nipype_mem/cmp-pipelines-common-SwapAndReorient/00a9971d6eb94f7a62cb811729d93b4c
#160825-18:08:49,115 workflow INFO:
#	 Collecting precomputed outputs
#Inputs check finished successfully.
#Diffusion and morphological data available.
#/group_shares/PSYCH/code/release/pipelines/CMP_beta_v02/lib/python2.7/site-packages/nipype/interfaces/base.py:359: UserWarning: Input apply_xfm requires inputs: in_matrix_file
#  warn(msg)
#Traceback (most recent call last):
#  File "/group_shares/PSYCH/code/release/pipelines/CMP_beta_v02/bin/connectomemapper", line 87, in <module>
#    pipeline.process()
#  File "/group_shares/PSYCH/code/release/pipelines/CMP_beta_v02/lib/python2.7/site-packages/cmp/pipelines/diffusion/diffusion.py", line 272, #in process
#    diff_flow = self.create_stage_flow("Diffusion")
#  File "/group_shares/PSYCH/code/release/pipelines/CMP_beta_v02/lib/python2.7/site-packages/cmp/pipelines/common.py", line 141, in #create_stage_flow
#    stage.create_workflow(flow,inputnode,outputnode)
#  File "/group_shares/PSYCH/code/release/pipelines/CMP_beta_v02/lib/python2.7/site-packages/cmp/stages/diffusion/diffusion.py", line 269, in #create_workflow
#    (dilate_rois,track_flow,[('out_file','inputnode.gm_registered')]),
#UnboundLocalError: local variable 'dilate_rois' referenced before assignment
#######################

#for custom parcellation
#cat diffusion_MRtrixCSD_prob.ini | sed 's/seg_tool = Freesurfer/seg_tool = Custom segmentation/' | sed 's/parcellation_scheme = Lausanne2008/parcellation_scheme = Custom/' > diffusion_customParc_MRtrixCSD_prob.ini

exit

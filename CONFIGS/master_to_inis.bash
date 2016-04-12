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

#for custom parcellation
#cat diffusion_MRtrixCSD_prob.ini | sed 's/seg_tool = Freesurfer/seg_tool = Custom segmentation/' | sed 's/parcellation_scheme = Lausanne2008/parcellation_scheme = Custom/' > diffusion_customParc_MRtrixCSD_prob.ini

exit

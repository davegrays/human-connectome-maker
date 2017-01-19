#!/bin/bash -e
if [[ $# -ne 1 ]]; then
	echo -e "Usage:	`basename $0` <subject_folder>"
	exit 1
fi

sub=$1

pushd $sub/RAWDATA

#reslice T1 and WM
echo "reslicing and extracting WM"
mri_convert ../FREESURFER/mri/T1.mgz -rl T1/${sub}_*.nii.gz FST1_on_native.nii.gz
mri_convert ../FREESURFER/mri/aseg.mgz -rl T1/${sub}_*.nii.gz aseg.nii.gz
mri_convert ../FREESURFER/mri/brainmask.mgz -rl T1/${sub}_*.nii.gz FST1_on_native_brain.nii.gz
fslmaths aseg -thr 41 -uthr 41 WM
for WMnum in 2 251 252 253 254 255; do fslmaths aseg -thr $WMnum -uthr $WMnum -add WM WM; done
fslmaths WM -bin WM

#extract, bias correct, and skullstrip b0
echo "extract, bias correct, and skullstrip b0"
fslroi ${sub}_*_MC_EC.nii.gz b0 0 1
N4BiasFieldCorrection -d 3 -i b0.nii.gz -o b0_N4.nii.gz	
bet b0_N4 b0_N4_brain -f 0.4 -m

#flirt bbr registration
echo "bbr registration, b0-->T1"
epi_reg --wmseg=WM --epi=b0_N4_brain --t1=FST1_on_native --t1brain=FST1_on_native_brain --out=epireg_brain -v
echo "apply transformation T1-->b0"
convert_xfm -omat T1_to_b0.mat -inverse epireg_brain.mat
flirt -applyxfm -init T1_to_b0.mat -in FST1_on_native -ref b0_N4 -o T1_on_b0_brain -interp spline
fslmaths T1_on_b0_brain -mas b0_N4_brain_mask T1_on_b0_brain

#ANTS unwarping of b0
echo "ANTS unwarping of b0"
/home/david/Projects/UNCstuff/ANTs-1.9.v4-Linux/bin/ANTS 3 -m  MI[T1_on_b0_brain.nii.gz,b0_N4_brain.nii.gz,1,32] -t SyN[0.15] -r Gauss[3,0.4] -o b0_N4_distortion -i 40x20x0 --number-of-affine-iterations 0 --Restrict-Deformation 0.1x1x0.15 --use-Histogram-Matching --subsampling-factors 4x2x1 --gaussian-smoothing-sigmas 2x1x0
#### apply warp and resample DWI to 2x2x2
echo "apply warping"
mri_convert -voxsize 2.000000 2.000000 2.000000 --input_volume b0.nii.gz --output_volume b0_resampled.nii.gz
DTI_EC=`ls ${sub}_*_MC_EC.nii.gz`
DTI_unwarped=`echo ${DTI_EC} | sed 's/_MC_EC\.nii\.gz/_MC_EC_unwarped_2mm\.nii\.gz/'`
antsApplyTransforms -d 3 -e 3 -i ${DTI_EC} -t b0_N4_distortionWarp.nii.gz -r b0_resampled.nii.gz -o ${DTI_unwarped} -n BSpline
fslmaths ${DTI_unwarped} ${DTI_unwarped} -odt short
mv ${DTI_unwarped} DTI/${DTI_unwarped}
antsApplyTransforms -d 3 -e 3 -i b0_N4.nii.gz -t b0_N4_distortionWarp.nii.gz -r b0_N4.nii.gz -o b0_N4_unwarped.nii.gz -n BSpline

popd
exit


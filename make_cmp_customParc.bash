#!/bin/bash
if [[ $# -ne 2 ]]; then
	echo -e "\nUsage:	`basename $0` <subjectFolder> <parcellation> \n"
	echo -e "	i.e. `basename $0` subject1 Gordon"
	echo -e "You must have precomputed freesurfer outputs in the FREESURFER folder under the subjectFolder."
	echo -e "Assumes freesurfer v5.1. Not tested with other versions (earlier or later).\n"
	exit 1
fi
sub=$1
parc=$2
fsdir=FREESURFER

#remove parcellation nifti file if it already exists
rm -f ${sub}/${fsdir}/label/${parc}.nii.gz
#generate parcellation
david_getparc_noreg.sh ${fsdir} ${parc} ${sub}

#extract and remove WM
echo "extracting WM from parcellation"
fslmaths ${sub}/${fsdir}/label/${parc}.nii.gz -thr 41 -uthr 41 ${sub}/${fsdir}/label/${parc}_WM.nii.gz #right hem
for WMnum in 2 251 252 253 254 255; do #left hem, CC1, CC2, CC3, CC4, CC5
	fslmaths ${sub}/${fsdir}/label/${parc}.nii.gz -thr $WMnum -uthr $WMnum -add ${sub}/${fsdir}/label/${parc}_WM.nii.gz ${sub}/${fsdir}/label/${parc}_WM.nii.gz #left hem
done
fslmaths ${sub}/${fsdir}/label/${parc}_WM.nii.gz -bin ${sub}/${fsdir}/label/${parc}_WM.nii.gz

#extract subcortical GM regions
echo "extracting subcortical regions from parcellation"
subcortVals=(18 17 26 13 11 12 10 54 53 58 52 50 51 49 16)
subcortNames=(lh_Amygdala lh_Hippocampus lh_Accumbens lh_Pallidum lh_Caudate lh_Putamen lh_Thalamus rh_Amygdala rh_Hippocampus rh_Accumbens rh_Pallidum rh_Caudate rh_Putamen rh_Thalamus Brainstem)
mkdir -p ${sub}/${fsdir}/label/subcort_ROIs
num=1
for ((num>=1;num<=${#subcortNames[*]};num++));do
	fslmaths ${sub}/${fsdir}/label/${parc}.nii.gz -thr ${subcortVals[$(($num-1))]} -uthr ${subcortVals[$(($num-1))]} -bin -mul $num ${sub}/${fsdir}/label/subcort_ROIs/${subcortNames[$(($num-1))]}
done
num=${#subcortNames[*]}

#regenerate parcellation excluding non-pertinent ROIs (csf, ventricles, hypothalamus, cerebellum, etc.)
echo "excluding non-cortical stuff from parcellation"
fslmaths ${sub}/${fsdir}/label/${parc}.nii.gz -thr 1000 ${sub}/${fsdir}/label/${parc}Parc

#make new copies of parcellation LUT files
cp -f ${sub}/${fsdir}/label/${parc}_lh_LUT.txt ${sub}/${fsdir}/label/${parc}Parc_lh_LUT.txt
cp -f ${sub}/${fsdir}/label/${parc}_rh_LUT.txt ${sub}/${fsdir}/label/${parc}Parc_rh_LUT.txt

#Clean up steps specific to Gordon Parcellation
#removes regions with intensity values 1017 1018 1019 2017 2018 2124 2153 2168
#corresponding to region names 17_L_Visual 18_L_None 19_L_None 178_R_None 179_R_None 285_R_None 314_R_None 329_R_Auditory
#can add more regions to this list by editing the 4 for-loops inside the following long if-statement
if [ $parc == Gordon ];then 
	echo -e "\nThis is the $parc parcellation. So we will remove some of the tiny regions...\n"
	echo "Starting with the left hemisphere..."
	fslmaths ${sub}/${fsdir}/label/${parc}Parc -bin -sub 1 -bin ${sub}/${fsdir}/label/tmpSubtractL
	for reg in 1017 1018 1019;do
		echo "Extracting left tiny region; intensity value $reg"
		fslmaths ${sub}/${fsdir}/label/${parc}Parc -thr $reg -uthr $reg -add ${sub}/${fsdir}/label/tmpSubtractL ${sub}/${fsdir}/label/tmpSubtractL
	done
	for reg in 17_L_Visual 18_L_None 19_L_None;do
		echo "Removing left tiny region from ${parc}Parc_lh_LUT.txt"
		sed -i "/  $reg/d" ${sub}/${fsdir}/label/${parc}Parc_lh_LUT.txt
	done
	echo "Replacing left tiny region values with 1000"
	fslmaths ${sub}/${fsdir}/label/tmpSubtractL -bin -mul 1000 ${sub}/${fsdir}/label/tmpAddL1000
	fslmaths ${sub}/${fsdir}/label/${parc}Parc -sub ${sub}/${fsdir}/label/tmpSubtractL -add ${sub}/${fsdir}/label/tmpAddL1000 ${sub}/${fsdir}/label/${parc}Parc

	echo "Now onto the right hemisphere..."
	fslmaths ${sub}/${fsdir}/label/${parc}Parc -bin -sub 1 -bin ${sub}/${fsdir}/label/tmpSubtractR
	for reg in 2017 2018 2124 2153 2168;do
		echo "Extracting right tiny region; intensity value $reg"
		fslmaths ${sub}/${fsdir}/label/${parc}Parc -thr $reg -uthr $reg -add ${sub}/${fsdir}/label/tmpSubtractR ${sub}/${fsdir}/label/tmpSubtractR
	done
	for reg in 178_R_None 179_R_None 285_R_None 314_R_None 329_R_Auditory;do
		echo "Removing right tiny region from ${parc}Parc_rh_LUT.txt"
		sed -i "/  $reg/d" ${sub}/${fsdir}/label/${parc}Parc_rh_LUT.txt
	done
	echo "Replacing right tiny region values with 2000"
	fslmaths ${sub}/${fsdir}/label/tmpSubtractR -bin -mul 2000 ${sub}/${fsdir}/label/tmpAddR2000
	fslmaths ${sub}/${fsdir}/label/${parc}Parc -sub ${sub}/${fsdir}/label/tmpSubtractR -add ${sub}/${fsdir}/label/tmpAddR2000 ${sub}/${fsdir}/label/${parc}Parc

	echo -e "\nThis is the $parc parcellation. So we will also inflate regions a bit...\n"
	echo "extracting label for unassigned cortex"
	fslmaths ${sub}/${fsdir}/label/${parc}Parc -thr 1000 -uthr 1000 ${sub}/${fsdir}/label/tmp1000
	fslmaths ${sub}/${fsdir}/label/${parc}Parc -thr 2000 -uthr 2000 ${sub}/${fsdir}/label/tmp2000
	echo "removing unassigned cortex and dilating assigned areas (x1) to fill holes in cortical ribbon"
	fslmaths ${sub}/${fsdir}/label/${parc}Parc -sub ${sub}/${fsdir}/label/tmp2000 -sub ${sub}/${fsdir}/label/tmp1000 -dilD -mas ${sub}/${fsdir}/label/${parc}Parc ${sub}/${fsdir}/label/${parc}Parc
	#echo "removing unassigned cortex"
	#fslmaths ${sub}/${fsdir}/label/${parc}Parc -sub ${sub}/${fsdir}/label/tmp2000 -sub ${sub}/${fsdir}/label/tmp1000 ${sub}/${fsdir}/label/${parc}Parc
	echo "negating cross-hemisphere dilation"
	fslmaths ${sub}/${fsdir}/label/${parc}Parc -thr 1001 -uthr 1999 -mas ${sub}/${fsdir}/label/tmp2000 ${sub}/${fsdir}/label/tmpCrossR
	fslmaths ${sub}/${fsdir}/label/${parc}Parc -thr 2001 -uthr 2999 -mas ${sub}/${fsdir}/label/tmp1000 ${sub}/${fsdir}/label/tmpCrossL
	fslmaths ${sub}/${fsdir}/label/${parc}Parc -sub ${sub}/${fsdir}/label/tmpCrossR -sub ${sub}/${fsdir}/label/tmpCrossL ${sub}/${fsdir}/label/${parc}Parc
	echo "re-instituting unassigned cortex for remaining holes in cortical ribbon"
	fslmaths ${sub}/${fsdir}/label/tmp1000 -bin -sub ${sub}/${fsdir}/label/${parc}Parc -bin -mul ${sub}/${fsdir}/label/tmp1000 -add ${sub}/${fsdir}/label/${parc}Parc ${sub}/${fsdir}/label/${parc}Parc
	fslmaths ${sub}/${fsdir}/label/tmp2000 -bin -sub ${sub}/${fsdir}/label/${parc}Parc -bin -mul ${sub}/${fsdir}/label/tmp2000 -add ${sub}/${fsdir}/label/${parc}Parc ${sub}/${fsdir}/label/${parc}Parc
	echo "forcing Gordon parcellation onto the ROIv_scale125.nii.gz gray matter voxels"
	fslmaths ${sub}/${fsdir}/label/${parc}Parc -dilD -mas ${sub}/${fsdir}/label/ROIv_scale125.nii.gz ${sub}/${fsdir}/label/${parc}Parc
	echo -e "\nEnd of $parc edits. Moving on with the rest of the custom parcellation workflow...\n"
	rm -f ${sub}/${fsdir}/label/tmp*.nii.gz
fi

echo "relabeling all cortical regions to be ordered consecutively, starting from $num"
echo "changes are applied to both the ${parc}Parc.nii.gz file and the ${parc}Parc_hemi_LUT.txt files"
mkdir -p ${sub}/${fsdir}/label/${parc}Parc_relabel
line=1
for origval in `awk 'NR >= 2 {print $1}' ${sub}/${fsdir}/label/${parc}Parc_lh_LUT.txt`;do
	num=$(($num+1))
	line=$(($line+1))
	#replace $origval on line $line with $num
	sed -i "${line}s/${origval}/${num}/" ${sub}/${fsdir}/label/${parc}Parc_lh_LUT.txt
	#replace value 1000 + $origval in nifti file with value $num
	niftival=$(($origval + 1000))
	echo "Left hem: relabeling nifti value $niftival to $num"
	fslmaths ${sub}/${fsdir}/label/${parc}Parc -thr $niftival -uthr $niftival -bin -mul $num ${sub}/${fsdir}/label/${parc}Parc_relabel/$num
done
line=1
for origval in `awk 'NR >= 2 {print $1}' ${sub}/${fsdir}/label/${parc}Parc_rh_LUT.txt`;do
	num=$(($num+1))
	line=$(($line+1))
	#replace $origval on line $line with $num
	sed -i "${line}s/${origval}/${num}/" ${sub}/${fsdir}/label/${parc}Parc_rh_LUT.txt
	#replace value 2000 + $origval in nifti file with value $num
	niftival=$(($origval + 2000))
	echo "Right hem: relabeling nifti value $niftival to $num"
	fslmaths ${sub}/${fsdir}/label/${parc}Parc -thr $niftival -uthr $niftival -bin -mul $num ${sub}/${fsdir}/label/${parc}Parc_relabel/$num
done

echo "merging relabeled cortical regions..."
pushd ${sub}/${fsdir}/label/${parc}Parc_relabel/
addstring=`ls | tr "\n" " "| sed 's/ / -add /g' | sed 's/ -add $//'`
#generate mask for the relabeled regions and remove the masked area from the orig parc
fslmaths ../${parc}Parc.nii.gz -sub ../${parc}Parc.nii.gz -add ${addstring} -bin -mul -9999 -add ../${parc}Parc.nii.gz -thr 0 ../${parc}Parc.nii.gz
#add the relabeled values to the orig parc
fslmaths ../${parc}Parc.nii.gz -add ${addstring} ../${parc}Parc.nii.gz
popd

echo "recombining subcortical GM regions into parcellation..."
pushd ${sub}/${fsdir}/label/subcort_ROIs/
addstring=`ls | tr "\n" " "| sed 's/ / -add /g' | sed 's/ -add $//'`
fslmaths ../${parc}Parc.nii.gz -add ${addstring} ../${parc}Parc.nii.gz
popd

#adding non-GM fsmask_1mm voxels into WM (assumes you've ran CMP NativeFreesurfer or Lausanne2008)
#this just ensures more complete WM coverage
echo "recombining fsmask_1mm (from CMP default run) into WM"
fslmaths ${sub}/${fsdir}/label/${parc}_WM.nii.gz -add ${sub}/${fsdir}/mri/fsmask_1mm -bin -sub ${sub}/${fsdir}/label/${parc}Parc -bin ${sub}/${fsdir}/label/${parc}_WM.nii.gz

#reslicing
echo "reslicing parcellation and WM to orig T1 space"
mri_convert -rl ${sub}/${fsdir}/mri/orig/001.mgz -rt nearest ${sub}/${fsdir}/label/${parc}_WM.nii.gz --out_type nii ${sub}/${fsdir}/label/${parc}_WM_reslice.nii.gz
mri_convert -rl ${sub}/${fsdir}/mri/orig/001.mgz -rt nearest ${sub}/${fsdir}/label/${parc}Parc.nii.gz --out_type nii ${sub}/${fsdir}/label/${parc}Parc_reslice.nii.gz

#generate graphml
echo "generating graphml file"
make_graphml_from_LUT.py ${sub} ${parc}Parc

exit

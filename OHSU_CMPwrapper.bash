#!/bin/bash -e

#command usage
if [[ $# -ne 2 ]]; then
	echo -e "\nUsage:	`basename $0` <subjectFolder> <HCP_group>"
	echo -e "\ni.e	`basename $0` 101939-200_1 ADHD-HumanYouth-OHSU"
	exit 1
fi

#assign cmdline args
sub=$1
group=$2

#define top-level directories
FSdir=`readlink -m /group_shares/FAIR_HCP/HCP/processed/${group}/${sub}/????????-SIEMENS_TrioTim-Nagel_K_Study/HCP_prerelease_FNL_0_1/T1w/${sub}`
Rawdir=`readlink -m /group_shares/FAIR_HCP/HCP/sorted/${group}/${sub}/????????-SIEMENS_TrioTim-Nagel_K_Study/`
T1andT2dir=`readlink -m /group_shares/FAIR_HCP/HCP/processed/${group}/${sub}/????????-SIEMENS_TrioTim-Nagel_K_Study/HCP_prerelease_FNL_0_1/T1w`

#define raw data directories/files
T1data=`readlink -f ${T1andT2dir}/T1w_acpc_dc_restore.nii.gz`
T2data=`readlink -f ${T1andT2dir}/T2w_acpc_dc_restore.nii.gz`
DTIdata=`readlink -m ${Rawdir}/*Woodward_DTI_72directions_10b0`
#T1data=`readlink -m ${Rawdir}/*T1Anatomical_1_ISO`
#T2data=`readlink -m ${Rawdir}/*t2_spc_1mm_p2`

case setup in

setup)
echo "RUNNING SET-UP SCRIPT ON RAW DATA"
#call qsub with -sync here (so this script doesn't skip ahead before finishing the setup)
OHSU_createSub.bash ${sub} ${T1data} ${DTIdata} ${T2data}

echo "MAKING FREESURFER FOLDER WITH ALL SYMLINKS TO EXISTING DATA"
pushd $sub
currdir=`readlink -m .`
cp -rs ${FSdir}/ ${currdir}/
mv ${sub} FREESURFER
popd

;&
CMP)
echo "RUNNING CONNECTOMEMAPPER"
mkdir -p /scratch/grayson_temp/OHSU_CMP_data_finished
qsub -l mf=1.75G,h_vmem=4G,h=fozzie,h_rt=23:59:00 -pe smp 2 xvfb-run -a run_cmp_v2.1beta_serial.bash ${sub} /group_shares/PSYCH/code/development/utilities/customCMPmatrix/CONFIGS/OHSU_MRtrixCSD_prob.ini Gordon True /scratch/grayson_temp/CSDprobtrack_files /scratch/grayson_temp/OHSU_CMP_data_finished

;;
esac

exit

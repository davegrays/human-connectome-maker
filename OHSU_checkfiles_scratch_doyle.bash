#!/bin/bash -e

#command usage
if [[ $# -ne 4 ]]; then
	echo -e "\nUsage:	`basename $0` <subjectFolder> <HCP_group> <scan_date> <motion in DWI (1 or 0)>"
	echo -e "\ne.g.	`basename $0` 11938-1 ADHD-HumanYouth-OHSU 20130309 0"
	echo -e "\nif there is no motion to remove, use 0, otherwise use 1"
	exit 1
fi

#assign cmdline args
sub=$1
group=$2
scandate=$3
motion=$4

#define top-level directories
initdir=`readlink -m /scratch/doyle_temp/${group}/${sub}`
FSdir=`readlink -m ${initdir}/T1w/${sub}`
if [ "$group" == "ADHD-HumanYouth-OHSU" ]; then
	Rawdir=`readlink -m /group_shares/FAIR_HCP/HCP/sorted/${group}/${sub}/${scandate}-SIEMENS_TrioTim-Nagel_K_Study/`
	analysesdir=`readlink -m /group_shares/FAIR_HCP/HCP/processed/${group}/${sub}/${scandate}-SIEMENS*Study/HCP*FNL*/analyses_v2`
elif [ "$group" == "ASD-HumanYouth-OHSU" ]; then
	Rawdir=`readlink -m /group_shares/FAIR_ASD/CYA/sorted/${group}/${sub}/${scandate}-SIEMENS_TrioTim-Nagel_K_Study/`
	analysesdir="/group_shares/FAIR_HCP/HCP/processed/${group}/${sub}/${scandate}-SIEMENS_TrioTim-Nagel_K_Study/HCP_release_${scandate}/${sub}/analyses_v2"
else
	echo "ERROR: invalid <HCP_group> argument given: ${group}. Must be either ADHD-HumanYouth-OHSU or ASD-HumanYouth-OHSU."
fi
T1andT2dir=`readlink -m ${initdir}/T1w`

######## IMPORTANT ISSUE #########
#FSdir, analysesdir, and T1andT2dir will need to vary per subject/scandate depending on what Eric Earl recommends 
#will need to decide whether to assign these directories using HCP_prerelease_FNL_0_1, HCP_FNL_NOT2_VER, or HCP_NoT2_NoDFM
######## ######## ######## ########

#check for existence of folders
if [ ! -d "${FSdir}" ]; then
	echo -e "\nFATAL ERROR: T1/T2/Freesurfer folder missing. See below\n"
	ls ${FSdir}
	exit 1
fi
if [ ! -d ${Rawdir}/*Woodward_DTI_72directions_10b0 ]; then
	echo -e "\nFATAL ERROR: DWI folder missing, or there's more than one DWI folder. See below\n"
	ls ${Rawdir}/*Woodward_DTI_72directions_10b0
	exit 1
fi

#if T1 and T2 files are found, define raw data directories/files
if [[ -f "${T1andT2dir}/T1w_acpc_dc_restore.nii.gz" && -f "${T1andT2dir}/T1w_acpc_dc_restore.nii.gz" ]]; then
	T1data=`readlink -f ${T1andT2dir}/T1w_acpc_dc_restore.nii.gz`
	T2data=`readlink -f ${T1andT2dir}/T2w_acpc_dc_restore.nii.gz`
	DTIdata=`readlink -m ${Rawdir}/*Woodward_DTI_72directions_10b0`
	#T1data=`readlink -m ${Rawdir}/*T1Anatomical_1_ISO`
	#T2data=`readlink -m ${Rawdir}/*t2_spc_1mm_p2`
else
	echo -e "\nFATAL ERROR: T1 and T2 files missing. See below\n"
	ls ${T1andT2dir}/T1w_acpc_dc_restore.nii.gz ${T1andT2dir}/T2w_acpc_dc_restore.nii.gz
	exit 1
fi

echo "$sub $group $scandate - READY"
exit

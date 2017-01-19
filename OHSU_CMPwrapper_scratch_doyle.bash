#!/bin/bash -e

#run this script with the following qsub submission:
#qsub -N CMPLOG_${sub} -sync y -l mf=1.75G,h_vmem=4G,h=fozzie,h_rt=18:00:00 -pe smp 2 xvfb-run -a OHSU_CMPwrapper.bash <subjectFolder> <HCP_group> <scan_date> <motion in DWI (1 or 0)>

#command usage
if [[ $# -ne 5 ]]; then
	echo -e "\nUsage:	`basename $0` <subjectFolder> <HCP_group> <scan_date> <motion in DWI (1 or 0)> <where_to_process>"
	echo -e "\ne.g.	`basename $0` 11938-1 ADHD-HumanYouth-OHSU 20130309 0 /scratch/grayson_temp"
	echo -e "\nif there is no motion to remove, use 0, otherwise use 1"
	exit 1
fi

#assign cmdline args
sub=$1
group=$2
scandate=$3
motion=$4
topdir=$5

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

#where and how to process
procdir=${topdir}/OHSU_CMP_data_finished
movetrks=${topdir}/OHSU_CMP_tracks_to_archive
config=OHSU_MRtrixCSD_prob

echo "${sub} FOLDER WILL BE IN ${procdir}"
mkdir -p ${procdir} ${movetrks}
orig_wd=$PWD
cd ${procdir}

case setup in

setup)
echo "RUNNING SET-UP SCRIPT ON RAW DATA"
#call qsub with -sync here (so this script doesn't skip ahead before finishing the setup)
#right now this is problematic only if motion is present because OHSU_createSub.bash will ask for user input about frame removal 
#qsub -N setupLOG_${sub} -sync y -l h_rt=4:00:00 OHSU_createSub.bash ${sub} ${T1data} ${DTIdata} ${T2data} ${motion}
OHSU_createSub.bash ${sub} ${T1data} ${DTIdata} ${T2data} ${motion}

echo "MAKING FREESURFER FOLDER WITH ALL SYMLINKS TO EXISTING DATA"
pushd $sub
currdir=`readlink -m .`
cp -rs ${FSdir}/ ${currdir}/
mv ${sub} FREESURFER
popd

;&
CMP)
echo "RUNNING CONNECTOMEMAPPER IN ${procdir}"
mkdir -p ${movetrks}
#qsub -N CMPLOG_${sub} -sync y -l mf=1.75G,h_vmem=4G,h=fozzie,h_rt=12:00:00 -pe smp 2 xvfb-run -a run_cmp_v2.1beta_serial.bash ${sub} /group_shares/PSYCH/code/development/utilities/customCMPmatrix/CONFIGS/${config}.ini Gordon True 0 .
run_cmp_v2.1beta_serial.bash ${sub} /group_shares/PSYCH/code/development/utilities/customCMPmatrix/CONFIGS/${config}.ini Gordon True 0 .

;&
Markov)
#qsub -N MarkovLOG_${sub} -sync y -l mf=3.5G,h_vmem=4G,h_rt=4:00:00 run_cmp_v2.1beta_serial.bash ${sub} /group_shares/PSYCH/code/development/utilities/customCMPmatrix/CONFIGS/${config}.ini Markov True ${movetrks} .
run_cmp_v2.1beta_serial.bash ${sub} /group_shares/PSYCH/code/development/utilities/customCMPmatrix/CONFIGS/${config}.ini Markov True ${movetrks} .

mkdir -p ${analysesdir}/DWI
for file in connectomes_${config}/${sub}/connectivity_matrices/connectome*mat;do
	parc=`echo $file | sed 's/.*\/connectome_//' | sed 's/Parc_reslice//' | sed 's/\.mat//'`
	cp -f ${file} ${analysesdir}/DWI/${sub}_${config}_${parc}_subcortical.pconn.mat
done

;;
esac

cd ${orig_wd}

exit

#!/bin/bash -e

#command usage
if [[ $# -ne 2 ]]; then
	echo -e "\nUsage:	`basename $0` <subjectFolder> <HCP_group>"
	echo -e "\ni.e	`basename $0` 11938-1 ADHD-HumanYouth-OHSU"
	exit 1
fi



##rsync final files into Box but use -l flag for symbolic links




#assign cmdline args
sub=$1
group=$2

#define top-level directories
FSdir=`readlink -m /group_shares/FAIR_HCP/HCP/processed/${group}/${sub}/????????-SIEMENS_TrioTim-Nagel_K_Study/HCP_prerelease_FNL_0_1/T1w/${sub}`
Rawdir=`readlink -m /group_shares/FAIR_HCP/HCP/sorted/${group}/${sub}/????????-SIEMENS_TrioTim-Nagel_K_Study/`
analysesdir=`readlink -m /group_shares/FAIR_HCP/HCP/processed/${group}/${sub}/????????-SIEMENS_TrioTim-Nagel_K_Study/HCP_prerelease_FNL_0_1/analyses_v2`
T1andT2dir=`readlink -m /group_shares/FAIR_HCP/HCP/processed/${group}/${sub}/????????-SIEMENS_TrioTim-Nagel_K_Study/HCP_prerelease_FNL_0_1/T1w`

#define raw data directories/files
T1data=`readlink -f ${T1andT2dir}/T1w_acpc_dc_restore.nii.gz`
T2data=`readlink -f ${T1andT2dir}/T2w_acpc_dc_restore.nii.gz`
DTIdata=`readlink -m ${Rawdir}/*Woodward_DTI_72directions_10b0`
#T1data=`readlink -m ${Rawdir}/*T1Anatomical_1_ISO`
#T2data=`readlink -m ${Rawdir}/*t2_spc_1mm_p2`

#where and how to process
procdir=/scratch/grayson_temp/OHSU_CMP_data_finished
movetrks=/scratch/grayson_temp/OHSU_CMP_tracks_to_archive
config=OHSU_MRtrixCSD_prob

case setup in

setup)
echo "SET-UP FOLDER WILL BE IN ${procdir}"
echo "RUNNING SET-UP SCRIPT ON ${sub} RAW DATA"
mkdir -p ${procdir}
pushd ${procdir}
#call qsub with -sync here (so this script doesn't skip ahead before finishing the setup)
#right now this is problematic though because OHSU_createSub.bash asks for user input about frame removal 
#qsub -N setupLOG_${sub} -sync y -l h_rt=4:00:00
OHSU_createSub.bash ${sub} ${T1data} ${DTIdata} ${T2data}

echo "MAKING FREESURFER FOLDER WITH ALL SYMLINKS TO EXISTING DATA"
pushd $sub
currdir=`readlink -m .`
cp -rs ${FSdir}/ ${currdir}/
mv ${sub} FREESURFER
popd
popd

;&
CMP)
echo "RUNNING CONNECTOMEMAPPER IN /scratch/grayson_temp/OHSU_CMP_data_finished"
mkdir -p ${procdir}
mkdir -p ${movetrks}
pushd ${procdir}
qsub -N CMPLOG_${sub} -sync y -l mf=1.75G,h_vmem=4G,h=fozzie,h_rt=12:00:00 -pe smp 2 xvfb-run -a run_cmp_v2.1beta_serial.bash ${sub} /group_shares/PSYCH/code/development/utilities/customCMPmatrix/CONFIGS/${config}.ini Gordon True 0 .
qsub -N MarkovLOG_${sub} -sync y -l mf=3.5G,h_vmem=4G,h_rt=4:00:00 run_cmp_v2.1beta_serial.bash ${sub} /group_shares/PSYCH/code/development/utilities/customCMPmatrix/CONFIGS/${config}.ini Markov True ${movetrks} .

mkdir -p ${analysesdir}/DWI
for file in connectomes_${config}/${sub}/connectivity_matrices/connectome*mat;do
	parc=`echo $file | sed 's/.*\/connectome_//' | sed 's/Parc_reslice//' | sed 's/\.mat//'`
	cp -f ${file} ${analysesdir}/DWI/${sub}_${config}_${parc}_subcortical.pconn.mat
done

popd

;;
esac

exit

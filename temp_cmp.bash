#!/bin/bash
if [[ $# -ne 4 && $# -ne 5 ]]; then
	echo -e "\nUsage:	`basename $0` <subjectFolder> <config.ini> <parc_scheme> <use_existing_FS> [retain_probabilistic_tracks]\n"
	echo -e "	i.e. `basename $0` subject1 Diffusion_config_mrtrix.ini Lausanne2008 True"
	echo -e "	OR `basename $0` subject1 Diffusion_config_mrtrix.ini NativeFreesurfer False 1"
	echo -e "	OR `basename $0` subject1 Diffusion_config_mrtrix.ini Gordon False\n"
	echo -e "You MUST spell and capitalize the <parc_scheme> and <use_existing_FS> arguments exactly as shown above.\n"
	exit 1
fi
config=$2
parc=$3
existingFS=$4
if [[ $5 -eq 1 ]];then
	retaintrks=$5
else retaintrks=0; fi

#if you want to make this script batchable, use the for-loop specified by these next two commands instead of the line 'sub=$1' and uncomment the end of the for loop
#the first argument then must be a text-list file with the subjectFolders specified on successive lines
#declare -a folders=(`cat $1`)
#for sub in "${folders[@]}";do
sub=$1

	#edit config file to use command arguments
	#check if using custom parcellation or not
	if [[ $parc == NativeFreesurfer || $parc == Lausanne2008 ]];then
		sed "s/parcellation_scheme = .*/parcellation_scheme = ${parc}/" $config | sed "s/insert_sub_here/${sub}/g" | sed "s/use_existing_freesurfer_data = .*/use_existing_freesurfer_data = ${existingFS}/" > ${sub}.ini
	else
		sed 's/seg_tool = Freesurfer/seg_tool = Custom segmentation/' $config | sed 's/parcellation_scheme = Lausanne2008/parcellation_scheme = Custom/' | sed "s/insert_sub_here/${sub}/g" | sed "s/CustomParcHere/${parc}/g" | sed 's/custom_parcellation = False/custom_parcellation = True/' > ${sub}.ini
		graphml=`cat ${sub}.ini | grep graphml_file | awk '{print $3}'`
		numreg=`cat ${graphml} | grep "node id" | tail -1 | sed 's/.*="//' | sed 's/">//'`
		echo "Using $parc custom Parcellation, with $numreg GM regions."
		sed -i "s/number_of_regions = 0/number_of_regions = ${numreg}/g" ${sub}.ini
		sed -i "s/'number_of_regions': 0/'number_of_regions': ${numreg}/g" ${sub}.ini
	fi

	#activate cmp beta v02 (David's edition; has mrtrix and gibbs)
	source /group_shares/PSYCH/code/release/pipelines/CMP_beta_v02/bin/activate
	export SUBJECTS_DIR=/group_shares/PSYCH/code/release/pipelines/CMP_beta_v02/Freesurfer_temp

### HERES THE COMMAND TO RUN ###

python2.7 /group_shares/PSYCH/code/development/utilities/customCMPmatrix/cmp_v2.1beta_getMatrix.py $sub $sub.ini $parc /group_shares/PSYCH/code/release/pipelines/CMP_beta_v02/cmp_nipype/build/lib

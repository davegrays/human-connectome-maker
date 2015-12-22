#!/bin/bash
if [[ $# -ne 4 && $# -ne 5 ]]; then
	echo -e "\nUsage:	`basename $0` <subjectFolder> <config.ini> <parc_scheme> <use_existing_FS> [retain_probabilistic_tracks]\n"
	echo -e "	i.e. `basename $0` subject1 Diffusion_config_mrtrix.ini Lausanne2008 True"
	echo -e "	OR `basename $0` subject1 Diffusion_config_mrtrix.ini NativeFreesurfer False 1"
	echo -e "	OR `basename $0` subject1 Diffusion_config_mrtrix.ini Gordon False\n"
	echo -e "You MUST spell and capitalize the <parc_scheme> and <use_existing_FS> arguments exactly as shown above.\n"
	exit 1
fi

sub=$1
config=$2
parc=$3
existingFS=$4
if [[ $5 -eq 1 ]]; then retaintrks=$5
else retaintrks=0; fi

#edit config file to use command arguments; check if using custom parcellation or not
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

#run cmp
connectomemapper $sub ${sub}.ini

#get most recent config file and results folder
confname=`echo $config | sed 's/.*\///' | sed 's/\.ini//'`
cfdir=`ls -d ${sub}/RESULTS/DTI/*/ | tail -1 | sed 's/\/$//'`
cfdir=`readlink -m ${cfdir}` #convert results folder to full path

#copy custom parc matrices into it
if [[ $parc != NativeFreesurfer && $parc != Lausanne2008 ]];then
	cp -f ${sub}/NIPYPE/diffusion_pipeline/connectome_stage/compute_matrice/connectome_${parc}*  ${cfdir}/connectivity_matrices
fi

##########################################
#### AIRC CLEAN UP #######################
#### perform only if the CMP finished ####
##########################################

if [ -f ${cfdir}/${sub}.ini ];then
	if [ -d ${cfidr} ];then
		### create symbolic links to the most recent diffusion connectome files
		mkdir -p connectomes_${confname}/${sub}/connectivity_matrices
		for filepath in ${cfdir}/*.ini ${cfdir}/*.log;do #link to the files in the parent folder
			filename=`echo $filepath | sed 's/.*\///'`
			ln -sf ${filepath} connectomes_${confname}/${sub}/${filename}
		done
		for filepath in ${cfdir}/connectivity_matrices/*;do #link to the files in the connectivity_matrices subfolder
			filename=`echo $filepath | sed 's/.*\///'`
			ln -sf ${filepath} connectomes_${confname}/${sub}/connectivity_matrices/${filename}
		done

		#move .tck and .trk files to scratch folder (only if mrtrix probabilistic tracking was run)
		if [[ -f ${sub}/NIPYPE/diffusion_pipeline/diffusion_stage/tracking/mrtrix_probabilistic_tracking/mapflow/_mrtrix_probabilistic_tracking1/diffusion_resampled_CSD_tracked.tck && $retaintrks -eq 0 ]];then
			for file in ${sub}/NIPYPE/diffusion_pipeline/diffusion_stage/tracking/mrtrix_probabilistic_tracking/mapflow/_mrtrix_probabilistic_tracking*/diffusion_resampled_CSD_tracked.tck;do
				mkdir -p `echo /scratch/grayson_temp/${file} | sed 's/diffusion_resampled_CSD_tracked\.tck//'`
				mv -f ${file} /scratch/grayson_temp/${file}
			done
		fi
		if [[ -f ${sub}/NIPYPE/diffusion_pipeline/diffusion_stage/tracking/trackvis/mapflow/_trackvis1/converted.trk && $retaintrks -eq 0 ]];then
			for file in ${sub}/NIPYPE/diffusion_pipeline/diffusion_stage/tracking/trackvis/mapflow/_trackvis*/converted.trk;do
				mkdir -p `echo /scratch/grayson_temp/${file} | sed 's/converted\.trk//'`
				mv -f ${file} /scratch/grayson_temp/${file}
			done
		fi
		#move config file into subject folder
		mv -f ${sub}.ini ${sub}/${sub}.ini
	fi
fi

exit

#!/bin/bash -e

if [[ $# -ne 5 && $# -ne 7 ]]; then
	echo -e "\nUsage:	`basename $0` <Freesurfer_parentDirectory> <subjectFolder> [</abspath/to/T1_file.nii> OR </abspath/to/T1_DICOMdir>] [</abspath/to/DTI_AFQproc.nii.gz> OR </abspath/to/DTI_DICOMdir>] <motion in DWI (1 or 0)> [optional </abspath/to/fieldmap_MAG_DICOMdir> AND </abspath/to/fieldmap_PHASE_DICOMdir>]"
	echo -e "\ni.e	`basename $0` /home/david/W/data2/APP_longitudinal 101939-200_1 /home/david/W/data/APP/Projects/FREESURFER_SUBJECTS/chg_files/101939-200_2_fs_rowflipped.nii /home/david/W/data/APP/Images/DTI/Done/101939-200_1/raw/*_aligned_trilin.nii.gz 1"
	echo -e "OR"
	echo -e "	`basename $0` /home/david/W/data/APP/Projects/FREESURFER_SUBJECTS 101939-200 /home/david/W/data/APP/Images/DICOMs/101939-200/3t_2010-08-18_20-26/MPRAGE_folder /home/david/W/data/APP/Images/DICOMs/101939-200/3t_2010-08-18_20-26/DTI_folder 0"
	echo -e "etc. etc."
	exit 1
fi

#set FREESURFER directory
FSdir="$1/$2"

#set T1 and DTI variables
sub=$2
rawT1=`readlink -f $3`
T1name=`echo ${rawT1} | sed 's/.*\///'`
rawDTI=`readlink -f $4`
DTIname=`echo ${rawDTI} | sed 's/.*\///'`

#set FM variables
if [ $# -eq 7 ]; then
	rawFM_MAG=`readlink -f $6`
	MAGname=`echo ${rawFM_MAG} | sed 's/.*\///'`
	rawFM_PHASE=`readlink -f $7`
	PHASEname=`echo ${rawFM_PHASE} | sed 's/.*\///'`
else
	rawFM_MAG="";rawFM_PHASE=""
fi

#check if motion was indicated or not
if [ $5 -eq 1 ]; then
	echo -e "\nType which DWI frames to remove, separated by spaces. If none, leave blank. Then press [ENTER]:\n(note: starting index is 1, not 0)"
	read userframes
elif [ $5 -eq 0 ]; then
	echo -e "No DWI frames to remove, because we're assuming there's no motion."
	userframes=""
else
	echo -e "FATAL ERROR: Motion argument was set to $5. It must be set to 0 or 1."
	exit 1
fi

#make arrays with 0-starting (remframes) and 1-starting indices (remframes_bvecs)
declare -a remframes=(`echo $userframes`)
declare -a remframes_bvecs=${remframes[@]};count=0;for i in ${remframes[@]}; do remframes[$count]=$(($i-1)); count=$(($count+1));done

echo -e "\nCreating the CMP pipeline RAWDATA dirs for subject $sub"
echo -e "T1: $rawT1\nDTI: $rawDTI\n"

case T1andDTI in

T1andDTI)

#create or replace raw data dirs
mkdir -p ${sub}/RAWDATA/DTI ${sub}/RAWDATA/T1
rm -f ${sub}/RAWDATA/DTI/* ${sub}/RAWDATA/T1/*

#create raw T1 data (check if folder or file. if file, check if .nii.gz, .mgz, or other format)
pushd ${sub}/RAWDATA/T1
if [[ -d $rawT1 ]]; then
	echo "raw T1 is a directory"
	dcm2niiScript.bash ${sub} ${rawT1}
elif [[ -f $rawT1 ]]; then
	mgz=`echo $rawT1 | grep .mgz$ | wc -l`
	niigz=`echo $rawT1 | grep .nii.gz$ | wc -l`
	if [[ $mgz -eq 1 ]];then echo "Raw T1 is .mgz file. Making .nii.gz copy"
		mri_convert ${rawT1} ${sub}_`echo ${T1name} | sed 's/\.mgz/\.nii.gz/'`
	elif [[ $niigz -eq 1 ]]; then echo "Raw T1 is .nii.gz file. Making .nii.gz copy"
		fslmaths ${rawT1} ${sub}_${T1name}
	else echo "ERROR: Raw T1 is a file in the wrong format. It must have either .mgz or .nii.gz extension. Exiting..."
		exit 1
	fi
else
	echo "T1 dir or file ${rawT1} is not valid"
	popd
	exit 1
fi
popd

#create raw DTI data
pushd ${sub}/RAWDATA/DTI
if [[ -d $rawDTI ]]; then
	echo "raw DTI is a directory"
	dcm2niiScript.bash ${sub} ${rawDTI}

	#find B0s and weighted frames, using 1-starting indices
	declare -a B0s=(`cat *bval | sed 's/ $//' | tr " " "\n" | grep -xn "0" | sed 's/\:0//'`)
	declare -a weis=(`cat *bval | sed 's/ $//' | tr " " "\n" | grep -xnv "0" | sed 's/\:.*//'`)
	#include B0s in bvec/bval frame removal (using 1-starting indices)
	line1=`echo ${B0s[@]} ${remframes_bvecs[@]} | sed 's/ /d\;/g'`
	#remove frames from bvec and bval (using 1-starting indices)
	bval=`ls *.bval`;bvec=`ls *.bvec`
	cat ${bval} | tr " " "\n" | sed "$line1"'d' | tr "\n" " " | sed 's/ $//' > tmpbval; mv tmpbval ${bval}
	awk 'NR==1 {print}' ${bvec} | tr " " "\n" | sed "$line1"'d' | tr "\n" " " | sed 's/ $//' > tmpXbvec
	awk 'NR==2 {print}' ${bvec} | tr " " "\n" | sed "$line1"'d' | tr "\n" " " | sed 's/ $//' > tmpYbvec
	awk 'NR==3 {print}' ${bvec} | tr " " "\n" | sed "$line1"'d' | tr "\n" " " | sed 's/ $//' > tmpZbvec
	echo `cat tmpXbvec` > ${bvec}; echo `cat tmpYbvec` >> ${bvec}; echo `cat tmpZbvec` >> ${bvec};

	#make arrays for B0 and wei volumes with 0-starting indices
	count=0;for i in ${B0s[@]}; do B0s[$count]=$(($i-1)); count=$(($count+1)); done
	count=0;for i in ${weis[@]}; do weis[$count]=$(($i-1)); count=$(($count+1));done
	#make file with desired frame removals (using 0-starting indices)
	echo ${remframes[@]} | tr " " "\n" > line0file
	#remove frames from B0 and wei volumes (using 0-starting indices)
	B0s_keep=(`echo ${B0s[@]} | tr " " "\n" | grep -xvf line0file`)
	weis_keep=(`echo ${weis[@]} | tr " " "\n" | grep -xvf line0file`)

	#update log
	echo `date` >> ../DAVID_preproc_log.txt
	echo -e "\nb0 frames: ${B0s[@]}" >> ../DAVID_preproc_log.txt
	echo "user requested these additional DWI frames removed: " `${remframes_bvecs[@]}` >> ../DAVID_preproc_log.txt
	echo -e "\nbvecs/bvals frames removed: $line1" >> ../DAVID_preproc_log.txt
	echo "kept B0 volumes" `printf "vol%04d.nii.gz " ${B0s_keep[@]}` >> ../DAVID_preproc_log.txt
	echo "kept weighted volumes" `printf "vol%04d.nii.gz " ${weis_keep[@]}` >> ../DAVID_preproc_log.txt
	echo "" >> ../DAVID_preproc_log.txt

	#motion correct and average B0s, recombine DWI file with average B0 for first frame
	echo -e "\nsplit DWI volumes"
	fslsplit ${sub}_${DTIname}
	echo "motion correct and average B0s"
	fslmerge -t B0s_all `printf "vol%04d.nii.gz " ${B0s_keep[@]}`
	mcflirt -in B0s_all
	fslmaths B0s_all_mcf -Tmean B0_mean
	echo "combine average B0 and weighted volumes"
	fslmerge -t ${sub}_${DTIname}_MC B0_mean `printf "vol%04d.nii.gz " ${weis_keep[@]}`
	#eddy correct
	echo "eddy correcting..."
	eddy_correct ${sub}_${DTIname}_MC ${sub}_${DTIname}_MC_EC 0 spline
	mv ${sub}_${DTIname}_MC_EC.ecclog ../
	echo "reformat original DWI and final EC images to short datatype"
	fslmaths ${sub}_${DTIname}_MC_EC.nii.gz ../${sub}_${DTIname}_MC_EC.nii.gz -odt short
	fslmaths ${sub}_${DTIname}.nii.gz ../${sub}_${DTIname}.nii.gz -odt short

	#make fsl bvecs and bvals
	cp ${bvec} ../fsl.bvecs
	cp ${bval} ../fsl.bvals
	sed -i 's/^/0 /g' ../fsl.bvecs
	sed -i 's/^/0 /g' ../fsl.bvals

	#transpose gradient tables in one directory above
	cp ${bvec} ../mrtrix_4XN.gradients; echo `cat ${bval}` >> ../mrtrix_4XN.gradients
	mv ${bvec} ${bval}  ..

awk '
{ 
    for (i=1; i<=NF; i++)  {
        a[NR,i] = $i
    }
}
NF>p { p = NF }
END {    
    for(j=1; j<=p; j++) {
        str=a[1,j]
        for(i=2; i<=NR; i++){
            str=str" "a[i,j];
        }
        print str
    }
}' ../mrtrix_4XN.gradients > tmp1

#add B0 to first row of mrtrix gradient table
sed -i '1i0 0 0 0' tmp1

awk '
{ 
    for (i=1; i<=NF; i++)  {
        a[NR,i] = $i
    }
}
NF>p { p = NF }
END {    
    for(j=1; j<=p; j++) {
        str=a[1,j]
        for(i=2; i<=NR; i++){
            str=str" "a[i,j];
        }
        print str
    }
}' ../${bvec} > tmp2

awk '
{ 
    for (i=1; i<=NF; i++)  {
        a[NR,i] = $i
    }
}
NF>p { p = NF }
END {    
    for(j=1; j<=p; j++) {
        str=a[1,j]
        for(i=2; i<=NR; i++){
            str=str" "a[i,j];
        }
        print str
    }
}' ../${bval} > tmp3

mv tmp1 ../mrtrix_4XN.gradients; mv tmp2 ../dtk.bvecs; mv tmp3 ../dtk.bvals;

#cleanup
rm *

elif [[ -f $rawDTI ]]; then
	echo "raw DTI is a file. creating symlink named AFQproc.nii.gz"
	rm *nii.gz
	ln -s ${rawDTI} AFQproc.nii.gz
else
	echo "DTI dir or file ${rawDTI} is not valid"
	popd
	exit 1
fi
popd

;&
copy_freesurfer)
cp -r ${FSdir} ${sub}/FREESURFER

;&
b0_unwarping)
#### B0 unwarping and resampling
redo_b0_to_T1.bash $sub

#check existence of critical inputs for CMP lausanne
ls ${sub}/FREESURFER/mri/aseg.mgz
ls ${sub}/FREESURFER/label/lh.aparc.annot
ls ${sub}/FREESURFER/label/rh.aparc.annot

;&
fieldmaps)
#create raw FM data
if [[ -d $rawFM_MAG && $rawFM_PHASE ]]; then
	#create or replace data
	mkdir -p ${sub}/RAWDATA/FIELDMAP
	rm -f ${sub}/RAWDATA/FIELDMAP/*
	pushd ${sub}/RAWDATA/FIELDMAP
	#MAG image
	dcm2niiScript.bash ${sub} ${rawFM_MAG}
	#take second frame
	fslsplit ${sub}_${MAGname}
	rm vol0000.nii.gz
	mv vol0001.nii.gz ${sub}_${MAGname}.nii.gz
	#PHASE image
	dcm2niiScript.bash ${sub} ${rawFM_PHASE}
	#brain extract MAG image (very tight mask)
	bet ${sub}_${MAGname} magbrain -m
	fslmaths magbrain_mask -ero magbrain_mask
	fslmaths magbrain -mas magbrain_mask magbrain
	#unwrap phase image
	fsl_prepare_fieldmap SIEMENS ${sub}_${PHASEname} magbrain fmap_rads 2.46
	#get unwarp parameters from B0
	fslroi ../DTI/${sub}_${DTIname}_MC_EC B0_mean 0 1
	bet ../T1/${sub}_${T1name} struct_brain
	epi_reg --epi=B0_mean --t1=../T1/${sub}_${T1name} --t1brain=struct_brain --out=B02struct --fmap=fmap_rads --fmapmag=${sub}_${MAGname} --fmapmagbrain=magbrain --echospacing=0.000345 --pedir=-y
	flirt -ref B02struct_1vol.nii.gz -in B0_mean.nii.gz -applyxfm -init B02struct.mat -o test
	#apply unwarping to whole DWI file
	#???
	popd
fi
esac

exit

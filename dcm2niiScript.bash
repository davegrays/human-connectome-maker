#!/bin/bash

if [ $# -ne 2 ]; then
	echo -e "\nUsage:	`basename $0` <subjectID> <path/to/scan/folder>\n"
	echo -e "	Example: `basename $0` 10999-1-W1 ../../func_2\n"
	echo -e "	...Outputs 10999-1-W1_func_2.nii.gz\n"
	exit
fi

sub=$1
run=`echo $2 | sed 's/\/$//'`
runName=`basename ${run}`

mkdir -p tmp_dcm2nii_9999

dcm2nii -o tmp_dcm2nii_9999 -p n -e n ${run}

pushd tmp_dcm2nii_9999

echo -e "\n"
ls
echo -e "\n"

if [ -f *nii ]; then 
for file in *nii;do
gzip $file;done
fi

if [ -f co20*nii.gz ]; then 
rm -f 20*nii.gz
rm -f o20*nii.gz
mv co20*nii.gz ../${sub}_${runName}.nii.gz

elif
[ -f o20*nii.gz ]; then 
rm -f 20*nii.gz
mv o20*nii.gz ../${sub}_${runName}.nii.gz

else
#mv 20*nii.gz ../${sub}_${runName}.nii.gz
c=0; for file in 20*nii.gz;do c=$(($c+1)); mv $file ../${sub}_${runName}${c}.nii.gz;done; mv ../${sub}_${runName}1.nii.gz ../${sub}_${runName}.nii.gz
fi

mv 20*bvec ../${sub}_${runName}.bvec
mv 20*bval ../${sub}_${runName}.bval

popd

rm -rf tmp_dcm2nii_9999

exit

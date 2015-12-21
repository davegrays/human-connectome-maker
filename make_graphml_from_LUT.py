#!/usr/global/bin/python

import sys

subject=sys.argv[1] #path to subject example: /group_shares/FAIR_MCDON/CMP_beta/DIY_Parcellation/2042_S1_1/CMP10072014/
parc=sys.argv[2] #parcellation scheme Example: myaparc_125

##### WRITE THE HEADER ######
outfile=subject + '/FREESURFER/label/' + parc + '.graphml'
#for example: 'Gordon.graphml'
out=open(outfile,'w')
out.write('<?xml version="1.0" encoding="utf-8"?><graphml xmlns="http://graphml.graphdrawing.org/xmlns" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://graphml.graphdrawing.org/xmlns http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd">\n')
out.write('  <key attr.name="dn_name" attr.type="string" for="node" id="d4" />\n  <key attr.name="dn_correspondence_id" attr.type="string" for="node" id="d3" />\n  <key attr.name="dn_hemisphere" attr.type="string" for="node" id="d2" />\n  <key attr.name="dn_fsname" attr.type="string" for="node" id="d1" />\n  <key attr.name="dn_region" attr.type="string" for="node" id="d0" />\n  <graph edgedefault="undirected" id="">\n')

##### DEFINE THE ADD-REGION FUNCTION ######
def add_region(name, num, hemi, cortVsubcort):
    out.write('   <node id="' + str(num) + '">\n')
    out.write('    <data key="d0">' + cortVsubcort + '</data>\n')
    out.write('    <data key="d1">' + name + '</data>\n')
    out.write('    <data key="d2">' + hemi + '</data>\n')
    out.write('    <data key="d3">' + str(num) + '</data>\n')
    out.write('    <data key="d4">' + name + '</data>\n')
    out.write('   </node>\n')

##### WRITE THE SUBCORTICAL REGIONS ######
num=0
subcortnames_lh = ['lh_Amygdala', 'lh_Hippocampus', 'lh_Accumbens', 'lh_Pallidum', 'lh_Caudate', 'lh_Putamen', 'lh_Thalamus']
for name in subcortnames_lh:
    num+=1
    add_region(name, num, 'left', 'subcortical')

subcortnames_rh = ['rh_Amygdala', 'rh_Hippocampus', 'rh_Accumbens', 'rh_Pallidum', 'rh_Caudate', 'rh_Putamen', 'rh_Thalamus']
for name in subcortnames_rh:
    num+=1
    add_region(name, num, 'right', 'subcortical')

#brainstem
num+=1
add_region('Brainstem', num, 'none', 'subcortical')

##### WRITE THE LEFT CORTICAL REGIONS ######
lutFile = subject+'/FREESURFER/label/'+parc+'_lh_LUT.txt'
#for example: '/group_shares/FAIR_ASD/Projects/UCDavis_APP/mapped/109119-100/FREESURFER/label/Gordon_lh_LUT.txt'
lut=open(lutFile,'r')
next(lut) #(skip the first line)
for line in lut:
	num+=1
	linesplit=line.split()
	if int(linesplit[0]) != num:
		sys.exit('FATAL ERROR: num variable ' + str(num) + ' and input ' + linesplit[0] + ' from *lh_LUT.txt file do not match!')
	add_region(linesplit[1], linesplit[0], 'left', 'cortical')
lut.close()

##### WRITE THE RIGHT CORTICAL REGIONS ######
lutFile = lutFile = subject+'/FREESURFER/label/'+parc+'_rh_LUT.txt'
lut=open(lutFile, 'r')
next(lut) #(skip the first line)
for line in lut:
	num+=1
	linesplit=line.split()
	if int(linesplit[0]) != num:
		sys.exit('FATAL ERROR: num variable ' + str(num) + ' and input ' + linesplit[0] + ' from *rh_LUT.txt file do not match!')
	add_region(linesplit[1], linesplit[0], 'right', 'cortical')
out.write('  </graph>\n</graphml>')
lut.close()

out.close()

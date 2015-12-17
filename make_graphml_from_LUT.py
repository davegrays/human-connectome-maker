#! /usr/global/bin/python
# To use: 
import sys, subprocess

subject=sys.argv[1] #path to subject example: /group_shares/FAIR_MCDON/CMP_beta/DIY_Parcellation/2042_S1_1/CMP10072014/
parc=sys.argv[2] #parcellation scheme Example: myaparc_125

##### WRITE THE HEADER ######
outfile=subject + '/FREESURFER/label/' + parc + '.graphml'
#('Gordon.graphml')
out=open(outfile,'w')

out.write('<?xml version="1.0" encoding="utf-8"?><graphml xmlns="http://graphml.graphdrawing.org/xmlns" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://graphml.graphdrawing.org/xmlns http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd">\n')
out.write('  <key attr.name="dn_name" attr.type="string" for="node" id="d4" />\n  <key attr.name="dn_correspondence_id" attr.type="string" for="node" id="d3" />\n  <key attr.name="dn_hemisphere" attr.type="string" for="node" id="d2" />\n  <key attr.name="dn_fsname" attr.type="string" for="node" id="d1" />\n  <key attr.name="dn_region" attr.type="string" for="node" id="d0" />\n  <graph edgedefault="undirected" id="">\n')

num=0

##### WRITE THE SUBCORTICAL REGIONS ######
num=num+1;
out.write('   <node id="' + str(num) + '">\n')
out.write('    <data key="d0">subcortical</data>\n')
out.write('    <data key="d1">Left-Amygdala</data>\n')
out.write('    <data key="d2">left</data>\n')
out.write('    <data key="d3">18</data>\n')
out.write('    <data key="d4">Left-Amygdala</data>\n')
out.write('   </node>\n')
num=num+1;
out.write('   <node id="' + str(num) + '">\n')
out.write('    <data key="d0">subcortical</data>\n')
out.write('    <data key="d1">Left-Hippocampus</data>\n')
out.write('    <data key="d2">left</data>\n')
out.write('    <data key="d3">17</data>\n')
out.write('    <data key="d4">Left-Hippocampus</data>\n')
out.write('   </node>\n')
num=num+1;
out.write('   <node id="' + str(num) + '">\n')
out.write('    <data key="d0">subcortical</data>\n')
out.write('    <data key="d1">Left-Accumbens-area</data>\n')
out.write('    <data key="d2">left</data>\n')
out.write('    <data key="d3">26</data>\n')
out.write('    <data key="d4">Left-Accumbens-area</data>\n')
out.write('   </node>\n')
num=num+1;
out.write('   <node id="' + str(num) + '">\n')
out.write('    <data key="d0">subcortical</data>\n')
out.write('    <data key="d1">Left-Pallidum</data>\n')
out.write('    <data key="d2">left</data>\n')
out.write('    <data key="d3">13</data>\n')
out.write('    <data key="d4">Left-Pallidum</data>\n')
out.write('   </node>\n')
num=num+1;
out.write('   <node id="' + str(num) + '">\n')
out.write('    <data key="d0">subcortical</data>\n')
out.write('    <data key="d1">Left-Caudate</data>\n')
out.write('    <data key="d2">left</data>\n')
out.write('    <data key="d3">11</data>\n')
out.write('    <data key="d4">Left-Caudate</data>\n')
out.write('   </node>\n')
num=num+1;
out.write('   <node id="' + str(num) + '">\n')
out.write('    <data key="d0">subcortical</data>\n')
out.write('    <data key="d1">Left-Putamen</data>\n')
out.write('    <data key="d2">left</data>\n')
out.write('    <data key="d3">12</data>\n')
out.write('    <data key="d4">Left-Putamen</data>\n')
out.write('   </node>\n')
num=num+1;
out.write('   <node id="' + str(num) + '">\n')
out.write('    <data key="d0">subcortical</data>\n')
out.write('    <data key="d1">Left-Thalamus-Proper</data>\n')
out.write('    <data key="d2">left</data>\n')
out.write('    <data key="d3">10</data>\n')
out.write('    <data key="d4">Left-Thalamus-Proper</data>\n')
out.write('   </node>\n')
num=num+1;
out.write('   <node id="' + str(num) + '">\n')
out.write('    <data key="d0">subcortical</data>\n')
out.write('    <data key="d1">Right-Amygdala</data>\n')
out.write('    <data key="d2">right</data>\n')
out.write('    <data key="d3">54</data>\n')
out.write('    <data key="d4">Right-Amygdala</data>\n')
out.write('   </node>\n')
num=num+1;
out.write('   <node id="' + str(num) + '">\n')
out.write('    <data key="d0">subcortical</data>\n')
out.write('    <data key="d1">Right-Hippocampus</data>\n')
out.write('    <data key="d2">right</data>\n')
out.write('    <data key="d3">56</data>\n')
out.write('    <data key="d4">Right-Hippocampus</data>\n')
out.write('   </node>\n')
num=num+1;
out.write('   <node id="' + str(num) + '">\n')
out.write('    <data key="d0">subcortical</data>\n')
out.write('    <data key="d1">Right-Accumbens-area</data>\n')
out.write('    <data key="d2">right</data>\n')
out.write('    <data key="d3">58</data>\n')
out.write('    <data key="d4">Right-Accumbens-area</data>\n')
out.write('   </node>\n')
num=num+1;
out.write('   <node id="' + str(num) + '">\n')
out.write('    <data key="d0">subcortical</data>\n')
out.write('    <data key="d1">Right-Pallidum</data>\n')
out.write('    <data key="d2">right</data>\n')
out.write('    <data key="d3">52</data>\n')
out.write('    <data key="d4">Right-Pallidum</data>\n')
out.write('   </node>\n')
num=num+1;
out.write('   <node id="' + str(num) + '">\n')
out.write('    <data key="d0">subcortical</data>\n')
out.write('    <data key="d1">Right-Caudate</data>\n')
out.write('    <data key="d2">right</data>\n')
out.write('    <data key="d3">50</data>\n')
out.write('    <data key="d4">Right-Caudate</data>\n')
out.write('   </node>\n')
num=num+1;
out.write('   <node id="' + str(num) + '">\n')
out.write('    <data key="d0">subcortical</data>\n')
out.write('    <data key="d1">Right-Putamen</data>\n')
out.write('    <data key="d2">right</data>\n')
out.write('    <data key="d3">51</data>\n')
out.write('    <data key="d4">Right-Putamen</data>\n')
out.write('   </node>\n')
num=num+1;
out.write('   <node id="' + str(num) + '">\n')
out.write('    <data key="d0">subcortical</data>\n')
out.write('    <data key="d1">Right-Thalamus-Proper</data>\n')
out.write('    <data key="d2">right</data>\n')
out.write('    <data key="d3">49</data>\n')
out.write('    <data key="d4">Right-Thalamus-Proper</data>\n')
out.write('   </node>\n')
num=num+1;
out.write('   <node id="' + str(num) + '">\n')
out.write('    <data key="d0">subcortical</data>\n')
out.write('    <data key="d1">Brain-Stem</data>\n')
out.write('    <data key="d2">none</data>\n')
out.write('    <data key="d3">26</data>\n')
out.write('    <data key="d4">Brain-Stem</data>\n')
out.write('   </node>\n')

##### WRITE THE LEFT REGIONS ######
lutFile = subject+'/FREESURFER/label/'+parc+'_lh_LUT.txt'
#('/group_shares/FAIR_ASD/Projects/UCDavis_APP/mapped/109119-100/FREESURFER/label/Gordon_lh_LUT.txt')
lut=open(lutFile,'r')
for line in lut:
	linesplit=line.split()
	if int(linesplit[0]) == 0:
		continue		
	num=num+1;
	out.write('   <node id="' + str(num) + '">\n')
	out.write('    <data key="d0">cortical</data>\n')
	out.write('    <data key="d1">' + linesplit[1] + '</data>\n')
	out.write('    <data key="d2">left</data>\n')
	if int(linesplit[0])<10:
		out.write('    <data key="d3">200' + linesplit[0] + '</data>\n')
	elif int(linesplit[0])<100:
		out.write('    <data key="d3">20' + linesplit[0] + '</data>\n')
	else:
		out.write('    <data key="d3">2' + linesplit[0] + '</data>\n')
	out.write('    <data key="d4">lh.' + linesplit[1] + '</data>\n')
	out.write('   </node>\n')
lut.close()

##### WRITE THE RIGHT REGIONS ######
lutFile = lutFile = subject+'/FREESURFER/label/'+parc+'_rh_LUT.txt'
lut=open(lutFile, 'r')
for line in lut:
	linesplit=line.split()
	if int(linesplit[0]) == 0:
		continue		
	num=num+1;
	out.write('   <node id="' + str(num) + '">\n')
	out.write('    <data key="d0">cortical</data>\n')
	out.write('    <data key="d1">' + linesplit[1] + '</data>\n')
	out.write('    <data key="d2">right</data>\n')
	if int(linesplit[0])<10:
		out.write('    <data key="d3">100' + linesplit[0] + '</data>\n')
	elif int(linesplit[0])<100:
		out.write('    <data key="d3">10' + linesplit[0] + '</data>\n')
	else:
		out.write('    <data key="d3">1' + linesplit[0] + '</data>\n')
	out.write('    <data key="d4">rh.' + linesplit[1] + '</data>\n')	
	out.write('   </node>\n')
out.write('  </graph>\n</graphml>')
lut.close()
out.close()

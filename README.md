Holds python and linux shell scripts for the processing of human neuroimaging data and construction of brain networks, espcially those that interact with the connectomemapper pipelines from the EPFL group.

Processing is invoked with run_cmp_v2.1beta_serial.bash, which calls different python pipelines and other shell functions, depending on which parcellation is specified.

Processing FNL data on the AIRC can also be invoked with OHSU_CMPwrapper.bash which handles setting up the directory structure before calling run_cmp_v2.1beta_serial.bash

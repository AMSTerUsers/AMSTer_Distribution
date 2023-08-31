Run Prepa_MSBAS.sh or prepare a textfile containing :    Master	   Slave	 Bperp	 Delay
Run Baseline_Coh_Table.sh or prepare a textfile containing :  MAS SLV Bp Bt Coh 

in a terminal launch Run_optim_module with the following arguments : 

# Parameters:	- fullpath to table_0_BP_0_BT.txt to optimize (result of Prepa_MSBAS.sh)
#		- fullpath to BaselineCohTable_Area.kml.txt (result of BaselineCohTable.sh)
#		- optimization criteria (3 or 4) 
#		- Day of year when decorrelation is the worse (1-365) 
#		- alpha calib param (exponent of seasonal component)
#		- beta calib param (temporal component)
#		- gamma calib param (spatial component)
#		- Max of expected coherence
#		- Min of expected coherence
#		- coherence proxy threshold for image rejection (0 if not used)

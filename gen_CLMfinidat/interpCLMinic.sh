#!/bin/bash
#
# Interpolates a CLM restart file to a VR grid so we aren't using a cold start
# How to use:
# 1.) Build interpinic in CLM tools
# 2.) Run CESM with an empty finidat in user_nl_clm (e.g., finidat='')
# 3.) Output a *.r.* file for CLM at the end of the run (this is CLM restart from cold
#     start on VR grid
# 4.) Run this script


#BSUB -P P54048000        # project number
#BSUB -n 3                # number of processors
#BSUB -R "span[ptile=16]" 
#BSUB -W 12:00            # wall-clock limit
#BSUB -q geyser            # queue
#BSUB -o interp_clim_INIC.%J.out    # ouput filename
#BSUB -e interp_clim_INIC.%J.err    # error filename
#BSUB -J interp_clim_INIC  # job name
#BSUB -N                  # send email upon job completion


#### CLM 4.0
#PATHTOINTERPINIC=/glade/p/work/zarzycki/cesm1_3_beta17/models/lnd/clm/tools/clm4_0/interpinic
#INPUTFILE="/glade/p/cesmdata/inputdata/lnd/clm2/initdata/clmi.BCN.2000-01-01_0.9x1.25_gx1v6_simyr2000_c100303.nc"
#OUTPUTFILE="/glade/u/home/zarzycki/work/unigridFiles/seasia_30_x4/clm_inic/seasia_30_x4.clm40.2000.i.interpinic.nc"

#### CLM 4.5
PATHTOINTERPINIC=/glade/p/work/zarzycki/cesm1_3_beta01/models/lnd/clm/tools/clm4_5/interpinic
INPUTFILE="/glade/p/work/zarzycki/ASD2017_files/lnd/clm2/initdata_map/clmi.FAMIPC6CLM5.1980-01-01.ne30np4_g1v6_simyr1980_c170213.nc"
#INPUTFILE="/glade/p/cesmdata/inputdata/lnd/clm2/initdata_map/clmi.I1850CRUCLM45BGC.0241-01-01.1.9x2.5_g1v6_simyr1850_c141226.nc"
OUTPUTFILE="/glade/p/work/zarzycki/unigridFiles/conus_30_x8/inic/f.asd2017.cesm20b05.FAMIPC6CLM5.ne0conus30x8_t12.clm2.r.1979-02-01-00000.nc"
#OUTPUTFILE="/glade/p/work/zarzycki/unigridFiles/southeastUS_30_x4/clm_inic/southeastUS_30_x4.clm45.inic.nc"

#### TYPHOON HAIYAN
#INPUTFILE="/glade/p/work/zarzycki/apply-haiyan-perturb/lnd_inic/tcforecast_60_x4.clm2.r.2013-10-31-10800.nc"
#OUTPUTFILE="/glade/u/home/zarzycki/scratch/apply-haiyan-perturb/lnd_inic/haiyan48x8_FC5_v122_1001.clm2.r.2013-11-09-54000.nc"
#OUTPUTFILE="/glade/p/work/zarzycki/unigridFiles/ecsnow_30_x0/inic/ecsnow30x0_AMIP.clm2.clm40.r.nc"

${PATHTOINTERPINIC}/interpinic -i ${INPUTFILE} -o ${OUTPUTFILE}


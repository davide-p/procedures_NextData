###########################################################################################################################
## Project: NEXTDATA                                                                                                     ##
## Parameter: NOX                                                                                                       ##
## Script first purpose: create a formatted Level-1 and Level-2 dataset (in EBAS format) from Level-0 data               ##
## Script second purpose: none                                                                                           ##
## Run time: the script may run daily (e.g. by using a crontab) or may be used when needed                               ##
##_______________________________________________________________________________________________________________________##
## Authors: Luca Naitza, Davide Putero                                                                                   ##
## Organization: National Research Council of Italy, Institute for Atmospheric Science and Climate (CNR-ISAC)            ##
## Address: Via Gobetti 101, 40129, Bologna, Italy                                                                       ##
## Project Contact: Paolo Cristofanelli                                                                                  ##
## Email: P.Cristofanelli@isac.cnr.it                                                                                    ##
## Phone number: (+39) 051 639 9597                                                                                      ##
##_______________________________________________________________________________________________________________________##
## Script filename: NOX_P21_1810.R                                                                                      ##
## Version Date: July 2019
## Jul. 31st, 2019: "days_ref" substituted with "dependent_col", i.e., the number of dependent data columns (in the header)
###########################################################################################################################

# > > > > > > > > > > > > > >           I N S T R U C T I O N S           < < < < < < < < < < < < < < < < < < < < < < < < #
#
# This script consists of several parts and sub-parts.
#
# Part 0   is the setting section, in which the User should replace the marked values (e.g. directory paths) 
# Part 0.1 defines environmental variables, such as raw data and destination directories. The user should modify these values.
# Part 0.2 specifies some characteristics of raw data tables, such as file extension, fields separators, etc. The user should 
#          modify these values according to his/her tables format. If the procedure requires more than one parameter
#          setting, Part 0.2 is divided in sub-sub-parts (e.g. 0.2.1 , 0.2.2,...)
# Part 0.3 specifies the characteristics of User Station/Laboratory/Instrument/parameter. Most of these variables are used 
#          as metadata in the EBAS file format header.  The User should provide proper information.
#
# Part 1   is another setting section; it should not be modified by the User unless strictly needed.  
# Part 1.1 sets and loads the most commonly used R libraries. The User should not modify this sub-part.
# Part 1.2 specifies the time variables used in the processing. The User should not modify this sub-part. If the User needs 
#          to apply the script to data older than the current year, he/she may modify the lines explicitly marked for this purpose.
#
# Part 2   is the data processing section, it should not be modified by the User.
# Part 2.x contain the code to produce the EBAS format file and to process data. The User should not modify this sub-part(s).
#
#           
# > > > > > > > > > > > > > > > > > > > > > > > > > > > < < < < < < < < < < < < < < < < < < < < < < < < < < < < < < < < < #


###########################################################################################################################
##                                          # PART 0.1 #
## ______________________________________________________________________________________________________________________##
##                                  Setting environmental variables
## ______________________________________________________________________________________________________________________##
## USE: set the following paths of origin raw data and of destination processing data, replacing values with yours
# WARNING: Proper setting up of the following paths and values is crucial. Please, replace the strings correctly
#
setwd("~/")
# -------- RAW DATA PATH ----------------------------------------------------------------------# REPLACE THE FOLLOWING PATHS
CALIB_DIR       = '../naitza/NEXTDATA/PROD/CIMONE/GAS/NO/RAW_DATA_UTC/CALIB'           
RAW_DIR         = '../naitza/NEXTDATA/PROD/CIMONE/GAS/NO/RAW_DATA_UTC'
#
# -------- DATA DESTINATION PATH --------------------------------------------------------------# REPLACE THE FOLLOWING PATHS
L0_DIR          = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/GAS/NO/LEVEL_0'                     
L1_DIR          = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/GAS/NO/LEVEL_1' 
L2_DIR          = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/GAS/NO/LEVEL_2'
L0_ANCIL_DIR    = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/GAS/NO/LEVEL_0/ANCILLARY'
#
# -------- GRAPH DESTINATION PATH -------------------------------------------------------------# REPLACE THE FOLLOWING PATHS
REP_DIR         = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/GAS/NO/REPORT'
REP_GRAPH_DIR   = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/GAS/NO/REPORT/DAILY_GRAPH'
PLOT_DIR_M      = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/GAS/NO/REPORT/MONTHLY_GRAPH'
PLOT_DIR_S      = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/GAS/NO/REPORT/SEASONAL_GRAPH'
PLOT_DIR_Y      = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/GAS/NO/REPORT/ANNUAL_GRAPH'
PLOT_DIR_Y_PDF  = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/GAS/NO/REPORT/ANNUAL_GRAPH/PDF'
PLOT_DIR_T      = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/GAS/NO/REPORT/TIMEVARIATION_GRAPH' 
#
# -------- SCRIPTS PATH ----------------------------------------------------------------------# REPLACE THE FOLLOWING PATHS
SCRIPT_DIR      = '../naitza/NEXTDATA/R_SCRIPT'          

## Loading functions for numflags
## The "NXD_numflag_functions_180301.R" scripts assigns the numflag value to the Data set, according to EBAS Flag List
## (https://ebas-submit.nilu.no/Submit-Data/List-of-Data-flags)
## The "NXD_EBAS_numflag_FullList_180103.txt" text file contains the EBAS Flag List, reporting codes, category and description
## Please, do NOT apply any change to the following function settings, unless you need to specify a different table of flags
#
source(paste(SCRIPT_DIR,"NXD_numflag_functions_180301.R", sep="/"))

tab_nf          <- read.table(file = paste(SCRIPT_DIR,"NXD_EBAS_numflag_FullList_180103.txt",sep="/"),
                              sep = ";", header = TRUE, quote = NULL)

##                                        # END PART 0.1 #
###########################################################################################################################


###########################################################################################################################
##                                          # PART 0.3 #
## ______________________________________________________________________________________________________________________##
##                                  Setting time and name variables
##                                  Setting EBAS metadata inrofmation
## ______________________________________________________________________________________________________________________##
#
# Station/Laboratory/Instrument/parameter variables
#
# -------- EBAS HEADER FILE (METADATA) -----------------------------------------------------# REPLACE THE FOLLOWING VALUES
# 
s_code                  <- "IT0009R"                                         # replace the value with your Station code
s_WDCA_ID               <- "GAWANO_CMN"                                      # replace the value with your WDCA ID code
s_GAW_Name              <- "Monte Cimone"                                    # replace the value with your Station GAW name
s_GAW_ID                <- "CMN"                                             # replace the value with your Station GAW ID
s_lat                   <- "44.16667"                                        # replace the value with your Station latitude
s_lon                   <- "10.68333"                                        # replace the value with your Station longitude
s_alt                   <- "2165m"                                           # replace the value with your Station altitude (meters)
s_l_use                 <- "Remote park"                                     # replace the value with your Station land use
s_setting               <- "Mountain"                                        # replace the value with your Station setting 
s_GAW_t                 <- "G"                                               # replace the value with your Station GAW type
s_WMO_reg               <- "6"                                               # replace the value with your Station WMO region

lab_code                <- "IT06L"                                           # replace the value with your laboratory code

inst_type               <- "chemiluminescence_photolytic"                    # replace the value with your instrument type
inst_manu               <- "ThermoScientific"                                # replace the value with your instrument manufacter
inst_modl               <- "tei42iTL+BLC"                                    # replace the value with your instrument model
inst_name               <- "ThermoScientific_Tei42TL_CMN"                    # replace the value with your your instrument name
inst_s_n                <- " "                                               # replace the value with your instrument serial number
meth_ref                <- " "                                               # replace the value with method reference

dependent_col           <- "10"                                              # replace the value with the total number of columns of the file in addition to start_time (i.e., total-1)

component               <- "NOx"                                             # replace the value with proper component 
matrix                  <- "air"                                             # replace the value with proper matrix
meas_unit               <- "nmol/mol"                                        # replace the value with proper measurement unit

meas_lat                <- "44.16667"                                        # replace the value with the your Measure latitude
meas_lon                <- "10.68333"                                        # replace the value with the your Measure longitude
meas_alt                <- "2165m"                                           # replace the value with the your Measure altitude (meters)

Period_code             <- "1y"                                              # replace the value with the proper Period code
Resolution_code         <- "1mn"                                             # replace the value with the proper Resolution code
Sample_duration         <- "1mn"                                             # replace the value with the proper Sample duration
Orig_time_res           <- "1mn"                                             # replace the value with the proper Original time resolution

std_meth                <- "SOP=ACTRIS_NOxy_2014"                            # replace the value with Standard method

inlet_type              <- "Hat or hood"                                     # replace the value with Inlet type
inlet_desc              <- "The air intake is composed by an external (outside building) steel pipe (internally covered by Teflon) and the internal (inside building) Pyrex pipe"    # replace the value with Inlet description
inlet_mat               <- "Teflon"                                          # replace the value with Inlet material
inlet_out_d             <- "6.35 mm"                                         # replace the value with Inlet outer diameter
inlet_in_d              <- ""                                                # replace the value with Inlet inner diameter
inlet_lenght            <- "1.5 m"                                           # replace the value with Inlet tube length

time_en_inlet           <- "2.5s"                                            # replace the value with Time from entry inlet line to entry of converter
duration_conv           <- "1s"                                              # replace the value with Duration of stay in converter

zero_val_code           <- "Zero/negative possible"                                       # replace the value with Zero/span check type
zero_val              <- "Zero and neg. values may appear due to statistical variations at very low concentrations"                                              # replace the value with Zero/span check interval

hum_temp_c              <- "none"                                            # replace the value with Humidity/temperature control
hum_temp_c_desc         <- "Passive, inlet air heated from atmospheric to converter temperature"            # replace the value with Humidity/temperature control description

vol_std_t               <- "293.15 K"                                        # replace the value with Volume std. temperature
vol_std_p               <- "1013.25 hPa"                                     # replace the value with Volume std. pressure

detec_lim               <- "0.11 ppb"                                        # replace the value with Detection limit
detec_lim_ex            <- "Determined by zero noise"                        # replace the value with Detection limit expl.
meas_unc_exp            <- "Includes statistical uncertainty of individual sample and calibration uncertainty"    # replace the value with Measurement uncertainty expl.

qa_mes_id               <- "ACTRIS NOx s-b-s 2016"                                   # replace the value with QA measure ID
#qa_date                 <- "not available"                                   # replace the value with QA date
qa_doc                  <- "not available"                                   # replace the value with QA document URL

qa2_mes_id              <- "ACTRIS NO round robin 2012"                                   # replace the value with QA measure ID
#qa2_date                 <- "not available"                                   # replace the value with QA date
qa2_doc                 <- "\"http://fp7.actris.eu/Portals/97/deliverables/PU/WP4_D4.4_M24.pdf\""                                  # replace the value with QA document URL

# The following variabiles concern the originator and the submitter names, surnames, emails and addresses
# NOTE: Please, change these variables with proper names, surnames, emails and addresses
# 
# -------- ORIGINATORS (set min 1 originator, max 5) ---------------------------------------------------------------# REPLACE THE FOLLOWING VALUES
Origin_1_n              <- "Paolo"      
Origin_1_s              <- "Cristofanelli"
Origin_1_e              <- "p.cristofanelli@isac.cnr.it"
Origin_1_i              <- "Institute of Atmospheric Sciences and Climate, ISAC,, Via P. Gobetti 101,, I-40129, Bologna, Italy"

Origin_2_n              <- "Luca"      
Origin_2_s              <- "Naitza"
Origin_2_e              <- "l.naitza@isac.cnr.it"
Origin_2_i              <- "Institute of Atmospheric Sciences and Climate, ISAC,, Via P. Gobetti 101,, I-40129, Bologna, Italy"

Origin_3_n              <- "Davide"      
Origin_3_s              <- "Putero"
Origin_3_e              <- "d.putero@isac.cnr.it"
Origin_3_i              <- "Institute of Atmospheric Sciences and Climate, ISAC,, Via P. Gobetti 101,, I-40129, Bologna, Italy"

Origin_4_n              <- "Francescopiero"      
Origin_4_s              <- "Calzolari"
Origin_4_e              <- "f.calzolari@isac.cnr.it"
Origin_4_i              <- "Institute of Atmospheric Sciences and Climate, ISAC,, Via P. Gobetti 101,, I-40129, Bologna, Italy"

Origin_5_n              <- ""      
Origin_5_s              <- ""
Origin_5_e              <- ""
Origin_5_i              <- ""

# -------- SUBMITTER (set the submitter) --------------------------------------------------------------------------# REPLACE THE FOLLOWING VALUES

Submit_1_n              <- "Paolo"      
Submit_1_s              <- "Cristofanelli"
Submit_1_e              <- "p.cristofanelli@isac.cnr.it"
Submit_1_i              <- "Institute of Atmospheric Sciences and Climate, ISAC,, Via P. Gobetti 101,, I-40129, Bologna, Italy"

mycomment               <- ""
#
# -------- CALIB STATUS ------------------------------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
Status_SPAN     <- "Span"     # if different, replace with the value reported in the SPAN filed for "Span" condition
Status_ZERO     <- "Zero"     # if different, replace with the value reported in the SPAN filed for "Zero" condition
Status_STBY     <- "StandBy"  # if different, replace with the value reported in the SPAN filed for "Standby" condition
#
#
# Setting the lines of the header
# 
if (nchar(Origin_2_n) == 0 && nchar(Origin_3_n) == 0 && nchar(Origin_4_n) == 0 && nchar(Origin_5_n) == 0)  { L1_n_lines <- 87 + 0 ; L2_n_lines <- 105 + 0 ; }
if (nchar(Origin_2_n)  > 0 && nchar(Origin_3_n) == 0 && nchar(Origin_4_n) == 0 && nchar(Origin_5_n) == 0)  { L1_n_lines <- 87 + 1 ; L2_n_lines <- 105 + 1 ; }
if (nchar(Origin_2_n)  > 0 && nchar(Origin_3_n)  > 0 && nchar(Origin_4_n) == 0 && nchar(Origin_5_n) == 0)  { L1_n_lines <- 87 + 2 ; L2_n_lines <- 105 + 2 ; }
if (nchar(Origin_2_n)  > 0 && nchar(Origin_3_n)  > 0 && nchar(Origin_4_n)  > 0 && nchar(Origin_5_n) == 0)  { L1_n_lines <- 87 + 3 ; L2_n_lines <- 105 + 3 ; }
if (nchar(Origin_2_n)  > 0 && nchar(Origin_3_n)  > 0 && nchar(Origin_4_n)  > 0 && nchar(Origin_5_n)  > 0)  { L1_n_lines <- 87 + 4 ; L2_n_lines <- 105 + 4 ; }
#
# -------------------------------------------------------------------------------------------

##                                        # END PART 0.3 #
###########################################################################################################################

###########################################################################################################################
##                                          # PART 1.0 #
## ______________________________________________________________________________________________________________________##
##                                        Loading libraries
## ______________________________________________________________________________________________________________________##
## NOTE: some of the following libraries may not be actually used by this script
# Please, do NOT apply any change, unless it is necessary to load specific libraries
# 
library(data.table)
library(openair)
library(lattice)
library(RColorBrewer)
library(latticeExtra)
library(proto)
library(gsubfn)
library(RSQLite)
library(padr)
library(caTools)
library(zoo)
library(plyr)
library(forecast)
library("sqldf") 
library(TTR)
library(ggplot2) 
library(reshape2)
library(stringr)
library(png)
#
##                                          # END PART 1.0 #
###########################################################################################################################


###########################################################################################################################
##                                            # PART 1.1 #
## ______________________________________________________________________________________________________________________##
##                                  Setting time and name variables
##                                  Cleaning destination directory
## ______________________________________________________________________________________________________________________##
#
#
# -------------------------------------------------------------------------------------------
# Time variables
# NOTE: the following variables should not be modified, except those with explicit comments
# 
questo_anno             <-format(Sys.Date(), "%Y")
#
# -------- PREVIOUS YEAR(S) DATA PROCESSING ---------------------------------------# IF NEEDED, UN-COMMENT THE FOLLOWING LINE
#questo_anno             <-as.numeric(questo_anno) -1   # the value "-1" means "last year". Change to "-2" or "-3" etc. for previous
#
questo_mese             <-format(Sys.Date(), "%m")
questo_mese_nome        <-format(Sys.Date(), "%B")
questo_giorno           <-format(Sys.Date(), "%d")

if (questo_mese == "01" & questo_giorno == "01")    { questo_anno == questo_anno-1 }                                                       

questo_capodanno        <-paste(questo_anno,"01","01",sep="-")
questo_annomesegiorno   <-paste(questo_anno,questo_mese,questo_giorno,sep="")
questa_ora              <-format(Sys.time(), "%H")
questo_minuto           <-format(Sys.time(), "%M")
questo_inizioanno       <-paste(questo_anno,"0101000000",sep = "")
questi_dati             <-paste(s_code,questo_inizioanno,sep = ".")
questa_start_time       <-as.Date(paste(paste(questo_anno,"01","01",sep = "-"), " 00:00:00",sep = ""))
myweekday               <-as.POSIXlt(Sys.Date())$wday
questo_startdate        <-paste(questo_anno,"0101",sep="")
new_date                <-gsub("-","",
                               gsub(" ","",
                                    gsub(":","",
                                         as.character(strptime(Sys.time(), 
                                                               format = "%Y - %m - %d %H : %M")))))
new_date_name           <-paste(".",new_date,sep="")
rev_datime              <-gsub("-","",
                               gsub(" ","",
                                    gsub(":","",
                                         as.character(strptime(new_date, 
                                                               format = "%Y%m%d%H%M%S")-3600))))
DATA_OSS                <-paste(questo_anno,"01 01")
DATA_REV                <-gsub("-"," ",Sys.Date())
DATA_INSERT             <-paste(DATA_OSS,DATA_REV,sep=" ")
#
# -------------------------------------------------------------------------------------------
# Reading EBAS Level-0 data
# NOTE: Please, do NOT change these variables
# 
DEST_lsdata             <- list.files(path = L0_DIR, pattern = paste(s_code,questo_inizioanno,sep = "."), all.files = FALSE,
                                      full.names = F, recursive = FALSE,
                                      ignore.case = FALSE, include.dirs = F, no.. = FALSE)

LISTA                   <-as.character(DEST_lsdata[1])
#
#
# -------------------------------------------------------------------------------------------
# File name variables
# NOTE: the following variables should not be modified 
#
old_date                <-substr(LISTA, 23, 37)
EBAS_L1_FILENAME        <-gsub("lev0","lev1",gsub(old_date,new_date_name,LISTA))
EBAS_L1_FULLFILENAME    <-paste(L1_DIR,EBAS_L1_FILENAME,sep = "/")
EBAS_L2_FILENAME        <-gsub("lev0","lev2",gsub("1mn","1h",gsub(old_date,new_date_name,LISTA)))
EBAS_L2_FULLFILENAME    <-paste(L2_DIR,EBAS_L2_FILENAME,sep = "/")

# -------------------------------------------------------------------------------------------
# Check point: printing variables
# 
questo_anno
questo_mese
questo_mese_nome
questo_giorno
questo_capodanno
questo_annomesegiorno
questa_ora
questo_minuto
questo_inizioanno
questa_start_time
myweekday
questo_startdate
new_date
new_date_name
rev_datime
old_date

EBAS_L1_FILENAME
EBAS_L1_FULLFILENAME
EBAS_L2_FILENAME
EBAS_L2_FULLFILENAME
#
##                                         # END PART 1.1 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 2.0 #
## ______________________________________________________________________________________________________________________##
##                                    Creation of Level-1 data file
##                                     Cleaning Destination directory
##                                        Formatting Level-1 header
## ______________________________________________________________________________________________________________________##
#
# -------------------------------------------------------------------------------------------
# Deleting temporary files in the destination directory (if present)
# 
FILE_TMP        <-list.files(path = L1_DIR, pattern = glob2rx("temp_*"), all.files = FALSE,
                             full.names = F, recursive = FALSE,
                             ignore.case = FALSE, include.dirs = F, no.. = FALSE)
LISTA_FILE_TMP  <-as.character(FILE_TMP)
LISTA_FILE_TMP
for(f in LISTA_FILE_TMP) { file.remove(paste(L1_DIR,f,sep = "/")) }
#
# -------------------------------------------------------------------------------------------
# Cleaning Destination directory
# NOTE: the following process deletes old EBAS Level-0 files within the destination directory 
# 
MYOLD_FILE      <-paste(s_code,".",questo_anno,sep = "")
FILE_L1         <-list.files(path = L1_DIR, pattern = glob2rx(paste(MYOLD_FILE,"*",sep = "")), all.files = FALSE,
                             full.names = F, recursive = FALSE,
                             ignore.case = FALSE, include.dirs = F, no.. = FALSE)
LISTA_FILE_OLD<-as.character(FILE_L1)
for(f in LISTA_FILE_OLD)    { file.remove(paste(L1_DIR,f,sep = "/")) }

FILE_L2         <-list.files(path = L2_DIR, pattern = glob2rx(paste(MYOLD_FILE,"*",sep = "")), all.files = FALSE,
                             full.names = F, recursive = FALSE,
                             ignore.case = FALSE, include.dirs = F, no.. = FALSE)
LISTA_FILE_OLD<-as.character(FILE_L2)
for(f in LISTA_FILE_OLD)    { file.remove(paste(L2_DIR,f,sep = "/")) }
#
# -------------------------------------------------------------------------------------------
# Creating the new EBAS LEVEL-1 data file
# NOTE: the following process deletes old EBAS Level-1 files within the destination directory
#
write.table(" ", file=EBAS_L1_FULLFILENAME,row.names=F,col.names = F, append = F,sep=" ")
#
# -------------------------------------------------------------------------------------------
# Formatting EBAS LEVEL-0 header and adding information to the data file
# NOTE: information contained in the following lines should be modified with proper station and instrumentation information
#
cat(
paste(L1_n_lines,"1001",sep=" "),
gsub("; $","",gsub("; ;","",paste(paste(Origin_1_n,Origin_1_s,sep=", "),
      ifelse(nchar(Origin_2_n)>0,
             (paste(Origin_2_n,Origin_2_s,sep=", ")), ""),
      ifelse(nchar(Origin_3_n)>0,
             (paste(Origin_3_n,Origin_3_s,sep=", ")), ""),
      ifelse(nchar(Origin_4_n)>0,
             (paste(Origin_4_n,Origin_4_s,sep=", ")), ""),
      ifelse(nchar(Origin_5_n)>0,
             (paste(Origin_5_n,Origin_5_s,sep=", ")), ""),
      sep="; "))),

paste(lab_code, Origin_1_i,sep=", "),
paste(Submit_1_n, Submit_1_s, sep=", "),
"GAW-WDCA, ACTRIS
1 1",
DATA_INSERT,
"0.000694 
Days from the file reference point (start_time)",
dependent_col,
"1 1 1 1 1 1 1 1 1 1
999.99999999 999.999 9.999999999 999.999 9.999999999 99.99 999.99 9.999999999 9999.99 9.999999999
end_time of measurement, days from the file reference point
nitrogen_monoxide, nmol/mol, Method ref=IT06L_chem_photoly_Thermo42iTL
numflag nitrogen_monoxide, no unit
nitrogen_dioxide, nmol/mol, Method ref=IT06L_chem_photoly_Thermo42iTL
numflag nitrogen_dioxide, no unit
converter_efficiency, %, Method ref=IT06L_chem_photoly_BLC
temperature, K, Location=inlet, Matrix=instrument,Method ref=IT06L_Rotronics
numflag temperature, no unit
pressure, hPa, Location=inlet, Matrix=instrument,Method ref=IT06L_Technoel
numflag pressure, no unit
0",
(L1_n_lines - 24),
"Data definition:                  EBAS_1.1
Data level:                       1
Version:                          1
Version description:              first revision, automatically inspected
Set type code:                    TU",
paste("Station code:                     ",s_code,sep=""),
paste("Platform code:                   ",gsub("R","S",s_code)),
"Timezone:                         UTC",
paste("Startdate:                        ",questo_inizioanno[1],sep=""),  
paste("Revision date:                    ",as.numeric(new_date)-7200,sep=""),
paste("Component:                        ","NOx",sep=""), 
paste("Matrix:                           ",matrix,sep=""), 
paste("Unit:                             ",meas_unit,sep=""),
paste("Period code:                      ",Period_code,sep=""), 
paste("Resolution code:                  ",Resolution_code,sep=""), 
paste("Sample duration:                  ",Sample_duration,sep=""), 
paste("Orig. time res.:                  ",Orig_time_res,sep=""),
paste("Laboratory code:                  ",lab_code,sep=""),
paste("Instrument type:                  ",inst_type,sep=""),
paste("Instrument manufacturer:          ",inst_manu,sep=""), 
paste("Instrument model:                 ",inst_modl,sep=""),
paste("Instrument name:                  ",inst_name,sep=""),
paste("Instrument serial number:         ",inst_s_n,sep=""),
paste("Method ref:                       ",meth_ref,sep=""),
paste("File name:                        ",EBAS_L1_FILENAME,sep=""),
paste("File creation:                    ",rev_datime[1],sep=""),
paste("Station WDCA-ID:                  ",s_WDCA_ID,sep=""),
paste("Station GAW-Name:                 ",s_GAW_Name,sep=""),
paste("Station GAW-ID:                   ",s_GAW_ID,sep=""),
paste("Station latitude:                 ",s_lat,sep=""),
paste("Station longitude:                ",s_lon,sep=""),
paste("Station altitude:                 ",s_alt,sep=""),
paste("Station land use:                 ",s_l_use,sep=""),
paste("Station setting:                  ",s_setting,sep=""),
paste("Station GAW type:                 ",s_GAW_t,sep=""),
paste("Station WMO region:               ",s_WMO_reg,sep=""),
paste("Measurement latitude:             ",meas_lat,sep=""),
paste("Measurement longitude:            ",meas_lon,sep=""),
paste("Measurement altitude:             ",meas_alt,sep=""),
paste("Inlet type:                       ",inlet_type,sep=""),
paste("Inlet description:                ",inlet_desc,sep=""),
paste("Inlet tube material:              ",inlet_mat,sep=""),
paste("Inlet tube outer diameter:        ",inlet_out_d,sep=""),
paste("Inlet tube inner diameter:        ",inlet_in_d,sep=""),
paste("Inlet tube length:                ",inlet_lenght,sep=""),
paste("Humidity/temperature control:     ",hum_temp_c,sep=""),
paste("Humidity/temperature control description: ",hum_temp_c_desc,sep=""),
paste("Volume std. temperature:          ",vol_std_t,sep=""),
paste("Volume std. pressure:             ",vol_std_p,sep=""),
paste("Detection limit:                  ",detec_lim,sep=""),
paste("Detection limit expl.:            ",detec_lim_ex,sep=""),
paste("Measurement uncertainty expl.:    ",meas_unc_exp,sep=""),
paste("Zero/negative values code:        ",zero_val_code,sep=""),
paste("Zero/negative values:             ",zero_val,sep=""),
paste("Standard method:                  ",std_meth,sep=""),
paste("QA measure ID                     ",qa_mes_id,sep=""),
paste("QA date:                          ",paste(questo_anno,questo_mese,questo_giorno,sep=""),sep=""),
paste("QA document URL:                  ",qa_doc,sep=""),
paste("Originator:                       ",paste(Origin_1_n,Origin_1_s,Origin_1_e,Origin_1_i,sep=", "),sep=""),
paste("Originator:                       ",paste(Origin_2_n,Origin_2_s,Origin_2_e,Origin_2_i,sep=", "),sep=""),
paste("Originator:                       ",paste(Origin_3_n,Origin_3_s,Origin_3_e,Origin_3_i,sep=", "),sep=""),
if(nchar(Origin_4_n)>0) {paste("Originator:                       ",paste(Origin_4_n,Origin_4_s,Origin_4_e,Origin_4_i,sep=", "),sep="")},
if(nchar(Origin_5_n)>0) {paste("Originator:                       ",paste(Origin_5_n,Origin_5_s,Origin_5_e,Origin_5_i,sep=", "),sep="")},
paste("Submitter:                        ",paste(Submit_1_n,Submit_1_s,Submit_1_e,Submit_1_i,sep=", "),sep=""),
paste("Comment:                          ",mycomment,sep=""),       
"Acknowledgement:                  Request acknowledgment details from data originator",
paste("start_time","end_time","NO","numflag_NO","NO2","numflag_NO2","converter_eff","Inlet_T","numflag","Inlet_P","numflag",sep=" "),

file=EBAS_L1_FULLFILENAME, append=F, sep = "\n")

##                                         # END PART 2.0 #
###########################################################################################################################


###########################################################################################################################
##                                          # PART 2.1 #
## ______________________________________________________________________________________________________________________##
##                                         Importing Level-0 data
##                          Processing, manipulation, transformation of Level-0 data
##                                       Level-1 data flagging
##                              Writing data in Level-1 data file (EBAS format) 
## ______________________________________________________________________________________________________________________##
#
# -------------------------------------------------------------------------------------------
#Reading header lines of Level-0 Data sheet
#
L0_n_lines <- as.integer(unlist(strsplit(readLines(paste(L0_DIR,LISTA,sep = "/"), n=1), " "))[1])
#
# Creating temporary table from Level-0
# 
temp_data               <-read.table(file=paste(L0_ANCIL_DIR,paste("NOx_PARAM_TABLE_",questo_anno,".dat",sep=""),sep = "/") , header = T,as.is = T,sep=" ") 
#
# -------------------------------------------------------------------------------------------
# Converting JD values to date
#
temp_data$jd            <-as.integer(temp_data$start_time)
temp_data$day           <-as.Date(temp_data$start_time, origin=questa_start_time)
temp_data$time.dec      <-temp_data$start_time-temp_data$jd
temp_data$time          <-temp_data$time.dec*1440+0.01
temp_data$hour          <-as.integer(temp_data$time/60)
temp_data$min           <-as.integer(temp_data$time-temp_data$hour*60)
temp_data$date          <-paste(temp_data$day," ",temp_data$hour,":",temp_data$min,":00",sep="")
temp_data$date          <-as.POSIXct(strptime(temp_data$date, format = "%Y-%m-%d %H:%M:%S"))
#
# -------------------------------------------------------------------------------------------
# Calculating Night time NO values
#
NO_night                      <- timeAverage(subset(temp_data,temp_data$hour<4 & 
                                                   temp_data$status %in% Status_STBY & 
                                                   temp_data$NO_flag < 0.450), 
                                          data.tresh=0,avg.time = "day",pollutant="NO_elab1")
temp_data_night               <-NO_night[,c("date","NO_elab1")]
names(temp_data_night)[2]     <-"NO_night"
temp_data_night$NO_night[1]   <- 0.00
temp_data_night$NO_night      <-na.interp(temp_data_night$NO_night)

## Creation of 1-min data-file with night-time NO data
temp_data                     <-merge(temp_data,temp_data_night,by = "date", all = TRUE)
temp_data$NO_night            <-na.interp(temp_data$NO_night)
temp_data$NO_night            <-as.numeric(temp_data$NO_night)

## Interpolation of night-time NO values (not used for correction)
temp_data$NO_night_interp     <-SMA(temp_data$NO_night,n=2500)
temp_data$NO_night_interp[1]  <- 0.00
temp_data$NO_night_interp     <-na.interp(temp_data$NO_night_interp)
temp_data$NO_night_interp     <-as.numeric(temp_data$NO_night_interp)

## Correction for night-time NO values (night-time NO value is subtracted if > 0.05 (DL))
temp_data$NO_L01              <-temp_data$NO_elab1
temp_data$NO2_L01             <-temp_data$NO2_elab2                                              #<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< correzione 20180516 >>>>>>>>>>>>>>>>>>>>>>>>>

temp_data$NO_L01              <-as.numeric(temp_data$NO_elab1) - as.numeric(temp_data$NO_night_interp)
temp_data$NOx_L01             <-as.numeric(temp_data$NO_L01)   + as.numeric(temp_data$NO2_L01)

temp_data$NO                  <-temp_data$NO_L01
temp_data$NO2                 <-temp_data$NO2_L01 
#
# -------------------------------------------------------------------------------------------
# Flagging Night time NO values
#
for (i in 1:nrow(temp_data))
{
  if ((temp_data$NO_flag[i]  < 0.450) & (temp_data$NO_night_interp[i]>0.05)) 
  { temp_data$NO_flag[i]      <- 0.440 }
}
# -------------------------------------------------------------------------------------------
# Padding data from January 1st to today
#
temp_data <- pad(temp_data, 
                 start_val = as.POSIXct(paste(questa_start_time," 00:00:00")), 
                 end_val = tail(temp_data$date,1), 
                 interval = "min", by = "date")
#
# -------------------------------------------------------------------------------------------
# Updating start_time and end_time, after padding
#
jd                      <-strptime(temp_data$date, "%Y-%m-%d %H:%M")$yday
h                       <-strptime(temp_data$date, "%Y-%m-%d %H:%M")$hour
m                       <-strptime(temp_data$date, "%Y-%m-%d %H:%M")$min
time                    <-h*60+m
time.dec                <-time/1440
time1.dec               <-time.dec+0.00069444  
temp_data$start_time    <-jd+time.dec
temp_data$end_time      <-jd+time1.dec
#
# -------------------------------------------------------------------------------------------
# Setting numflag codes to invalid and special cases
#
temp_data$NO_flag       [is.na(temp_data$NO)]     <- 0.999999999  
temp_data$NO2_flag      [is.na(temp_data$NO2)]    <- 0.999999999  
temp_data$NO            [is.na(temp_data$NO)]     <- 999.999      
temp_data$NO2           [is.na(temp_data$NO2)]    <- 999.999      
temp_data$t_flag        [is.na(temp_data$t_flag)] <- 0.999999999  
temp_data$p_flag        [is.na(temp_data$p_flag)] <- 0.999999999  
temp_data$Sc            [is.na(temp_data$Sc)]     <- 99.99        
temp_data$T             [is.na(temp_data$T)]      <- 999.99       
temp_data$P             [is.na(temp_data$P)]      <- 9999.99      
#
# -------------------------------------------------------------------------------------------
# Writing the final Data set
# Formatting the output matrix as required by EBAS format Level-1
#
myEBAS                  <- temp_data[,c("start_time","end_time","NO","NO_flag","NO2","NO2_flag","Sc","T","t_flag","P","p_flag")]
#
sprintf_formats         <- c(rep("%.6f", 2), "%.3f", "%.9f", "%.3f", "%.9f", rep("%.2f", 2), "%.9f", "%.2f", "%.9f")
myEBAS[]                <- mapply(sprintf, sprintf_formats, myEBAS)
#
# Appending Data set to EBAS Level-1 Header
#
write.table(myEBAS, file=EBAS_L1_FULLFILENAME,row.names=F,col.names = F, append = T, quote = F,sep=" ")
#
# -------------------------------------------------------------------------------------------
# Deleting temporary files in the destination directory (if present)
# 
FILE_TMP        <-list.files(path = L1_DIR, pattern = glob2rx("temp_*"), all.files = FALSE,
                             full.names = F, recursive = FALSE,
                             ignore.case = FALSE, include.dirs = F, no.. = FALSE)
LISTA_FILE_TMP  <-as.character(FILE_TMP)
LISTA_FILE_TMP
for(f in LISTA_FILE_TMP) { file.remove(paste(L1_DIR,f,sep = "/")) }
# -------------------------------------------------------------------------------------------
##                                        # END PART 2.1 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 2.2 #
## ______________________________________________________________________________________________________________________##
##                                    Creation of Level-2 data file
##                                     Cleaning Destination directory
##                                        Formatting Level-2 header
## ______________________________________________________________________________________________________________________##
#
# -------------------------------------------------------------------------------------------
# Deleting temporary files in the destination directory (if present)
# 
FILE_TMP        <-list.files(path = L2_DIR, pattern = glob2rx("temp_*"), all.files = FALSE,
                             full.names = F, recursive = FALSE,
                             ignore.case = FALSE, include.dirs = F, no.. = FALSE)
LISTA_FILE_TMP  <-as.character(FILE_TMP)
LISTA_FILE_TMP
for(f in LISTA_FILE_TMP) { file.remove(paste(L2_DIR,f,sep = "/")) }
# -------------------------------------------------------------------------------------------
#                   
write.table("",file=EBAS_L2_FULLFILENAME,row.names=F,col.names = F, append = F, quote = F)
#
# -------------------------------------------------------------------------------------------
# Formatting EBAS LEVEL-2 header and adding information to the data file
#
cat(
paste(L2_n_lines,"1001",sep=" "),
gsub("; $","",gsub("; ;","",paste(paste(Origin_1_n,Origin_1_s,sep=", "),
                                  ifelse(nchar(Origin_2_n)>0,
                                         (paste(Origin_2_n,Origin_2_s,sep=", ")), ""),
                                  ifelse(nchar(Origin_3_n)>0,
                                         (paste(Origin_3_n,Origin_3_s,sep=", ")), ""),
                                  ifelse(nchar(Origin_4_n)>0,
                                         (paste(Origin_4_n,Origin_4_s,sep=", ")), ""),
                                  ifelse(nchar(Origin_5_n)>0,
                                         (paste(Origin_5_n,Origin_5_s,sep=", ")), ""),
                                  sep="; "))),

paste(lab_code, Origin_1_i,sep=", "),
paste(Submit_1_n, Submit_1_s, sep=", "),
"GAW-WDCA, ACTRIS
1 1",
DATA_INSERT,
"0.041667 
Days from the file reference point (start_time)
25
1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
9999.99999999 9999.9999 9999.9999 9999.9999 9999.9999 9999.9999 9999.9999 99.999 9.999999999 9999.9999 9999.9999 9999.9999 9999.9999 9999.9999 9999.9999 99.999 9.999000000
end_time of measurement, days from the file reference point
nitrogen_monoxide, nmol/mol, Statistics=arithmetic mean, Calibration scale=NPL
nitrogen_monoxide, nmol/mol, Statistics=stddev
nitrogen_monoxide, nmol/mol, Statistics=percentile:15.87 
nitrogen_monoxide, nmol/mol, Statistics=percentile:84.13 
nitrogen_monoxide, nmol/mol, Statistics=expanded uncertainty 2sigma
nitrogen_monoxide, nmol/mol, Statistics=precision
nitrogen_monoxide, nmol/mol, Statistics=detection limit
numflag nitrogen_monoxide, no unit
nitrogen_dioxide, nmol/mol, Statistics=arithmetic mean, Calibration scale=NPL+GPT
nitrogen_dioxide, nmol/mol, Statistics=stddev
nitrogen_dioxide, nmol/mol, Statistics=percentile:15.87 
nitrogen_dioxide, nmol/mol, Statistics=percentile:84.13 
nitrogen_dioxide, nmol/mol, Statistics=expanded uncertainty 2sigma
nitrogen_dioxide, nmol/mol, Statistics=precision
nitrogen_dioxide, nmol/mol, Statistics=detection limit
numflag nitrogen_dioxide, no unit
NOx, nmol/mol, Statistics=arithmetic mean
NOx, nmol/mol, Statistics=stddev
NOx, nmol/mol, Statistics=percentile:15.87 
NOx, nmol/mol, Statistics=percentile:84.13 
NOx, nmol/mol, Statistics=expanded uncertainty 2sigma
NOx, nmol/mol, Statistics=precision
NOx, nmol/mol, Statistics=detection limit
numflag, no unit
0",
(L2_n_lines - 39),
"Data definition:                  EBAS_1.1
Data level:                       2
Version:                          1
Version description:              initial revision, automatically inspected
Set type code:                    TU",
paste("Station code:                     ",s_code,sep=""),
paste("Platform code:                   ",gsub("R","S",s_code)),
"Timezone:                         UTC",
paste("Startdate:                        ",questo_inizioanno[1],sep=""),  
paste("Revision date:                    ",as.numeric(new_date)-7200,sep=""),
paste("Component:                        ","NOx",sep=""), 
paste("Matrix:                           ",matrix,sep=""), 
paste("Unit:                             ",meas_unit,sep=""),
paste("Period code:                      ",Period_code,sep=""), 
paste("Resolution code:                  ",Resolution_code,sep=""), 
paste("Sample duration:                  ",Sample_duration,sep=""), 
paste("Orig. time res.:                  ",Orig_time_res,sep=""),
paste("Laboratory code:                  ",lab_code,sep=""),
paste("Instrument type:                  ",inst_type,sep=""),
paste("Instrument manufacturer:          ",inst_manu,sep=""), 
paste("Instrument model:                 ",inst_modl,sep=""),
paste("Instrument name:                  ",inst_name,sep=""),
paste("Instrument serial number:         ",inst_s_n,sep=""),
paste("Method ref:                       ",meth_ref,sep=""),
paste("File name:                        ",EBAS_L1_FILENAME,sep=""),
paste("File creation:                    ",rev_datime[1],sep=""),
paste("Station WDCA-ID:                  ",s_WDCA_ID,sep=""),
paste("Station GAW-Name:                 ",s_GAW_Name,sep=""),
paste("Station GAW-ID:                   ",s_GAW_ID,sep=""),
paste("Station latitude:                 ",s_lat,sep=""),
paste("Station longitude:                ",s_lon,sep=""),
paste("Station altitude:                 ",s_alt,sep=""),
paste("Station land use:                 ",s_l_use,sep=""),
paste("Station setting:                  ",s_setting,sep=""),
paste("Station GAW type:                 ",s_GAW_t,sep=""),
paste("Station WMO region:               ",s_WMO_reg,sep=""),
paste("Measurement latitude:             ",meas_lat,sep=""),
paste("Measurement longitude:            ",meas_lon,sep=""),
paste("Measurement altitude:             ",meas_alt,sep=""),
paste("Inlet type:                       ",inlet_type,sep=""),
paste("Inlet description:                ",inlet_desc,sep=""),
paste("Inlet tube material:              ",inlet_mat,sep=""),
paste("Inlet tube outer diameter:        ",inlet_out_d,sep=""),
paste("Inlet tube inner diameter:        ",inlet_in_d,sep=""),
paste("Inlet tube length:                ",inlet_lenght,sep=""),
paste("Humidity/temperature control:     ",hum_temp_c,sep=""),
paste("Humidity/temperature control description: ",hum_temp_c_desc,sep=""),
paste("Volume std. temperature:          ",vol_std_t,sep=""),
paste("Volume std. pressure:             ",vol_std_p,sep=""),
paste("Detection limit:                  ",detec_lim,sep=""),
paste("Detection limit expl.:            ",detec_lim_ex,sep=""),
paste("Measurement uncertainty expl.:    ",meas_unc_exp,sep=""),
paste("Zero/negative values code:        ",zero_val_code,sep=""),
paste("Zero/negative values:             ",zero_val,sep=""),
paste("Standard method:                  ",std_meth,sep=""),
paste("QA1 measure ID                    ",qa_mes_id,sep=""),
paste("QA1 date:                         ",paste(questo_anno,questo_mese,questo_giorno,sep=""),sep=""),
paste("QA1 document URL:                 ",qa_doc,sep=""),
paste("QA2 measure ID                    ",qa2_mes_id,sep=""),
paste("QA2 date:                         ",paste(questo_anno,questo_mese,questo_giorno,sep=""),sep=""),
paste("QA2 document URL:                 ",qa2_doc,sep=""),
paste("Originator:                       ",paste(Origin_1_n,Origin_1_s,Origin_1_e,Origin_1_i,sep=", "),sep=""),
paste("Originator:                       ",paste(Origin_2_n,Origin_2_s,Origin_2_e,Origin_2_i,sep=", "),sep=""),
paste("Originator:                       ",paste(Origin_3_n,Origin_3_s,Origin_3_e,Origin_3_i,sep=", "),sep=""),
if(nchar(Origin_4_n)>0) {paste("Originator:                       ",paste(Origin_4_n,Origin_4_s,Origin_4_e,Origin_4_i,sep=", "),sep="")},
if(nchar(Origin_5_n)>0) {paste("Originator:                       ",paste(Origin_5_n,Origin_5_s,Origin_5_e,Origin_5_i,sep=", "),sep="")},
paste("Submitter:                        ",paste(Submit_1_n,Submit_1_s,Submit_1_e,Submit_1_i,sep=", "),sep=""),
paste("Comment:                          ",mycomment,sep=""),       
"Acknowledgement:                  Request acknowledgment details from data originator",
paste("start_time","end_time","NO","NOstddev","NOperc16","NOperc84","NO_ac","NO_pr","NO_dl","numflag_no","NO2","NO2stddev","NO2perc16","NO2perc84","NO2_ac","NO2_pr","NO2_dl","numflag_no2",sep=" "),
 
file=EBAS_L2_FULLFILENAME, append=F, sep = "\n")
#
# -------------------------------------------------------------------------------------------
##                                        # END PART 2.2 #
###########################################################################################################################


###########################################################################################################################
##                                          # PART 2.3 #
## ______________________________________________________________________________________________________________________##
##                          Processing, manipulation, transformation of Level-1 data
##                                       Level-2 data flagging
##                              Writing data in Level-2 data file (EBAS format) 
## ______________________________________________________________________________________________________________________##
#
# -------------------------------------------------------------------------------------------
# Preparing Level-2 data
#
EBAS_lev2                 <-subset(myEBAS, selsect=c(1:7))
EBAS_lev2[1:7]            <-lapply(EBAS_lev2[1:7], as.numeric) 
#
names(EBAS_lev2)[1]       <- "start_time" 
names(EBAS_lev2)[2]       <- "end_time" 
names(EBAS_lev2)[3]       <- "NO" 
names(EBAS_lev2)[4]       <- "numflag_no" 
names(EBAS_lev2)[5]       <- "NO2" 
names(EBAS_lev2)[6]       <- "numflag_no2" 
names(EBAS_lev2)[7]       <- "converter_eff"
#
# -------------------------------------------------------------------------------------------
# Updating date
#
jd                        <-as.integer(EBAS_lev2$start_time)
day                       <-as.Date(EBAS_lev2$start_time, origin=questo_capodanno)
time.dec                  <-EBAS_lev2$start_time-jd
time                      <-time.dec*1440+0.01
hour                      <-as.integer(time/60)
min                       <-as.integer(time-hour*60)
EBAS_lev2$date            <-paste(day," ",hour,":",min,":00",sep="")
EBAS_lev2$date            <-as.POSIXct(strptime(EBAS_lev2$date, format = "%Y-%m-%d %H:%M:%S", tz = "GMT"))
# -------------------------------------------------------------------------------------------
# 
# Calculating last observed day (not necessarily the last acquisition day)
#
final_time              <-as.POSIXct(ISOdatetime(questo_anno,questo_mese,questo_giorno,23,59,0), tz = "UTC")  - 60*60*24 
#
#
# -------------------------------------------------------------------------------------------
# Checking NO valid and invalid data
#
EBAS_lev2_no              <- subset(EBAS_lev2,select=c("NO","numflag_no","date"))

EBAS_lev2_no$nf_validity  <- sapply(EBAS_lev2$numflag_no, nf_val_check, tab_nf$numflag, tab_nf$category)

temp_data_no              <- subset(EBAS_lev2_no, EBAS_lev2_no$nf_validity == "V", 
                                  select=c("NO","numflag_no","date"))
temp_data_no$numflag_no   <- as.numeric(temp_data_no$numflag_no)

EBAS_lev2_no              <- timeAverage(subset(temp_data_no),data.tresh=0,avg.time = "hour",pollutant=c("NO"),fill = TRUE,start.date=questo_capodanno, end.date   = as.character(final_time))
EBAS_lev2_no_sd           <- timeAverage(subset(temp_data_no),data.tresh=0,avg.time = "hour",statistic="sd",pollutant=c("NO"),start.date=questo_capodanno, end.date   = as.character(final_time))
EBAS_lev2_no_p16          <- timeAverage(subset(temp_data_no),data.tresh=0,avg.time = "hour",statistic="percentile",percentile=16,pollutant=c("NO"),start.date=questo_capodanno, end.date   = as.character(final_time))
EBAS_lev2_no_p84          <- timeAverage(subset(temp_data_no),data.tresh=0,avg.time = "hour",statistic="percentile",percentile=84,pollutant=c("NO"),start.date=questo_capodanno, end.date   = as.character(final_time))
EBAS_lev2_no_freq         <- timeAverage(subset(temp_data_no),data.tresh=0,avg.time = "hour",statistic="frequency",pollutant=c("NO"),start.date=questo_capodanno, end.date   = as.character(final_time))

EBAS_lev2_no$no_nd        <-EBAS_lev2_no_freq$NO
EBAS_lev2_no$no_sd        <-EBAS_lev2_no_sd$NO
EBAS_lev2_no$no_p16       <-EBAS_lev2_no_p16$NO
EBAS_lev2_no$no_p84       <-EBAS_lev2_no_p84$NO
EBAS_lev2_no$no_ac        <-9999.9999
EBAS_lev2_no$no_pr        <-9999.9999
EBAS_lev2_no$no_dl        <-0.05

jd                        <-strptime(EBAS_lev2_no$date, "%Y-%m-%d %H:%M")$yday
h                         <-strptime(EBAS_lev2_no$date, "%Y-%m-%d %H:%M")$hour
time                      <-h*60
time.dec                  <-time/1440
EBAS_lev2_no$start_time   <-jd+time.dec
EBAS_lev2_no$end_time     <-EBAS_lev2_no$start_time+1/24

EBAS_lev2_no$no_nd[is.na(EBAS_lev2_no$no_nd)] <- 0
#
# -------------------------------------------------------------------------------------------
# Flagging numflag_no
#
bad_numflags            <- c("000",as.character(tab_nf$numflag[tab_nf$category != "V"])) 
EBAS_lev2_no$numflag_no <- sapply(EBAS_lev2_no$start_time, 
                                  nf_lev2, 
                                  numflags_mm=EBAS_lev2$numflag_no, 
                                  startime_mm=EBAS_lev2$start_time,
                                  nv_numflags=bad_numflags)

EBAS_lev2_no$numflag_no   [!is.na(EBAS_lev2_no$no_nd) 
                           & EBAS_lev2_no$no_nd >= 30 & 
                             EBAS_lev2_no$no_nd < 45] <- sapply(EBAS_lev2_no$numflag_no[!is.na(EBAS_lev2_no$no_nd) &
                                                                                          EBAS_lev2_no$no_nd >= 30   & 
                                                                                          EBAS_lev2_no$no_nd < 45]   ,
                                                                nf_aggreg, nf_new = 0.392)
EBAS_lev2_no$numflag_no   [!is.na(EBAS_lev2_no$no_nd) &
                             EBAS_lev2_no$no_nd < 30]    <- sapply(EBAS_lev2_no$numflag_no[!is.na(EBAS_lev2_no$no_nd) &
                                                                                             EBAS_lev2_no$no_nd   < 30] ,
                                                                   nf_aggreg, nf_new = 0.390) 

EBAS_lev2_no$NO        [is.na(EBAS_lev2_no$NO)   ]<- 9999.9999
EBAS_lev2_no$no_sd     [is.na(EBAS_lev2_no$no_sd)]<- 9999.9999
EBAS_lev2_no$numflag_no[EBAS_lev2_no$NO == 9999.9999]<- 0.999
#
# -------------------------------------------------------------------------------------------
# Checking NO2 valid and invalid data
#
EBAS_lev2_no2              <- subset(EBAS_lev2,select=c("NO2","numflag_no2","date"))
EBAS_lev2_no2$nf_validity      <- sapply(EBAS_lev2$numflag_no2, nf_val_check, tab_nf$numflag, tab_nf$category)

temp_data_no2           <- subset(EBAS_lev2_no2, EBAS_lev2_no2$nf_validity == "V",
                                  select=c("NO2","numflag_no2","date"))
temp_data_no2$numflag_no2   <- as.numeric(temp_data_no2$numflag_no2)

EBAS_lev2_no2             <- timeAverage(subset(temp_data_no2),data.tresh=0,avg.time = "hour",pollutant=c("NO2"),fill = TRUE,start.date=questo_capodanno, end.date   = as.character(final_time))
EBAS_lev2_no2_sd          <- timeAverage(subset(temp_data_no2),data.tresh=0,avg.time = "hour",statistic="sd",pollutant=c("NO2"),start.date=questo_capodanno, end.date   = as.character(final_time))
EBAS_lev2_no2_p16         <- timeAverage(subset(temp_data_no2),data.tresh=0,avg.time = "hour",statistic="percentile",percentile=16,pollutant=c("NO2"),start.date=questo_capodanno, end.date   = as.character(final_time))
EBAS_lev2_no2_p84         <- timeAverage(subset(temp_data_no2),data.tresh=0,avg.time = "hour",statistic="percentile",percentile=84,pollutant=c("NO2"),start.date=questo_capodanno, end.date   = as.character(final_time))
EBAS_lev2_no2_freq        <- timeAverage(subset(temp_data_no2),data.tresh=0,avg.time = "hour",statistic="frequency",pollutant=c("NO2"),start.date=questo_capodanno, end.date   = as.character(final_time))

EBAS_lev2_no2$no2_nd      <-EBAS_lev2_no2_freq$NO2
EBAS_lev2_no2$no2_sd      <-EBAS_lev2_no2_sd$NO2
EBAS_lev2_no2$no2_p16     <-EBAS_lev2_no2_p16$NO2
EBAS_lev2_no2$no2_p84     <-EBAS_lev2_no2_p84$NO2
EBAS_lev2_no2$no2_ac      <-9999.9999
EBAS_lev2_no2$no2_pr      <-9999.9999
EBAS_lev2_no2$no2_dl      <-0.05

jd                        <-strptime(EBAS_lev2_no2$date, "%Y-%m-%d %H:%M")$yday
h                         <-strptime(EBAS_lev2_no2$date, "%Y-%m-%d %H:%M")$hour
time                      <-h*60
time.dec                  <-time/1440
EBAS_lev2_no2$start_time  <-jd+time.dec
EBAS_lev2_no2$no2_nd[is.na(EBAS_lev2_no2$no2_nd)] <- 0
#
# -------------------------------------------------------------------------------------------
# Flagging numflag_no2
#
bad_numflags              <- c("000",as.character(tab_nf$numflag[tab_nf$category != "V"])) 

EBAS_lev2_no2$numflag_no2 <- sapply(EBAS_lev2_no2$start_time, 
                                    nf_lev2, 
                                    numflags_mm=EBAS_lev2$numflag_no2, 
                                    startime_mm=EBAS_lev2$start_time,
                                    nv_numflags=bad_numflags)

EBAS_lev2_no2$numflag_no2 [!is.na(EBAS_lev2_no2$no2_nd) 
                           & EBAS_lev2_no2$no2_nd >= 30 & 
                             EBAS_lev2_no2$no2_nd < 45] <- sapply(EBAS_lev2_no2$numflag_no2[!is.na(EBAS_lev2_no2$no2_nd) &
                                                                                              EBAS_lev2_no2$no2_nd >= 30   & 
                                                                                              EBAS_lev2_no2$no2_nd < 45]   ,
                                                                  nf_aggreg, nf_new = 0.392)
EBAS_lev2_no2$numflag_no2 [!is.na(EBAS_lev2_no2$no2_nd) &
                             EBAS_lev2_no2$no2_nd < 30]    <- sapply(EBAS_lev2_no2$numflag_no2[!is.na(EBAS_lev2_no2$no2_nd) &
                                                                                                 EBAS_lev2_no2$no2_nd   < 30] ,
                                                                     nf_aggreg, nf_new = 0.390) 

EBAS_lev2_no2$NO2         [is.na(EBAS_lev2_no2$NO2)   ]<- 9999.9999
EBAS_lev2_no2$no2_sd      [is.na(EBAS_lev2_no2$no2_sd)]<- 9999.9999
EBAS_lev2_no2$numflag_no2 [EBAS_lev2_no2$NO2 == 9999.9999]<- 0.999
#
# -------------------------------------------------------------------------------------------
# Merging NO and NO2 data sets
#
EBAS_lev2_nox        <- merge(x = EBAS_lev2_no[,c("start_time", "end_time","NO", "no_sd", "no_p16", "no_p84", "no_ac", "no_pr", "no_dl", "numflag_no")], 
                             y = EBAS_lev2_no2[,c("start_time","NO2","no2_sd","no2_p16","no2_p84","no2_ac","no2_pr","no2_dl","numflag_no2")], by = "start_time", all.x = TRUE)
#
# -------------------------------------------------------------------------------------------
# Setting NAs to invalid value
#
EBAS_lev2_nox$NO[is.na(EBAS_lev2_nox$NO)]             <- 999.9999
EBAS_lev2_nox$no_sd[is.na(EBAS_lev2_nox$no_sd)]       <- 999.9999
EBAS_lev2_nox$no_p16[is.na(EBAS_lev2_nox$no_p16)]     <- 999.9999
EBAS_lev2_nox$no_p84[is.na(EBAS_lev2_nox$no_p84)]     <- 999.9999
EBAS_lev2_nox$NO2[is.na(EBAS_lev2_nox$NO2)]           <- 999.9999
EBAS_lev2_nox$no2_sd[is.na(EBAS_lev2_nox$no2_sd)]     <- 999.9999
EBAS_lev2_nox$no2_p16[is.na(EBAS_lev2_nox$no2_p16)]   <- 999.9999
EBAS_lev2_nox$no2_p84[is.na(EBAS_lev2_nox$no2_p84)]   <- 999.9999
#
EBAS_lev2_nox$numflag_no[EBAS_lev2_nox$NO   == 999.9999] <- 0.999 
EBAS_lev2_nox$numflag_no2[EBAS_lev2_nox$NO2 == 999.9999] <- 0.999 
#
# -------------------------------------------------------------------------------------------
# Setting data format
#
EBAS_lev2_nox$start_time    <-format(round(EBAS_lev2_nox$start_time, 8),nsmall = 8)
EBAS_lev2_nox$end_time      <-format(round(EBAS_lev2_nox$end_time, 8),nsmall = 8)

EBAS_lev2_nox$NO            <-format(round(EBAS_lev2_nox$NO, 4), nsmall = 4)
EBAS_lev2_nox$no_sd         <-format(round(EBAS_lev2_nox$no_sd,4), nsmall = 4)
EBAS_lev2_nox$no_p16        <-format(round(EBAS_lev2_nox$no_p16,4), nsmall = 4)
EBAS_lev2_nox$no_p84        <-format(round(EBAS_lev2_nox$no_p84,4), nsmall = 4)
EBAS_lev2_nox$no_ac         <-format(round(EBAS_lev2_nox$no_ac,4), nsmall = 4)
EBAS_lev2_nox$no_pr         <-format(round(EBAS_lev2_nox$no_pr,4), nsmall = 4)
EBAS_lev2_nox$no_dl         <-format(round(EBAS_lev2_nox$no_dl,3), nsmall = 3)
EBAS_lev2_nox$numflag_no    <-format(round(EBAS_lev2_nox$numflag_no,9), nsmall = 9)

EBAS_lev2_nox$NO2           <-format(round(EBAS_lev2_nox$NO2, 4), nsmall = 4)
EBAS_lev2_nox$no2_sd        <-format(round(EBAS_lev2_nox$no2_sd,4), nsmall = 4)
EBAS_lev2_nox$no2_p16       <-format(round(EBAS_lev2_nox$no2_p16,4), nsmall = 4)
EBAS_lev2_nox$no2_p84       <-format(round(EBAS_lev2_nox$no2_p84,4), nsmall = 4)
EBAS_lev2_nox$no2_ac        <-format(round(EBAS_lev2_nox$no2_ac,4), nsmall = 4)
EBAS_lev2_nox$no2_pr        <-format(round(EBAS_lev2_nox$no2_pr,4), nsmall = 4)
EBAS_lev2_nox$no2_dl        <-format(round(EBAS_lev2_nox$no2_dl,3), nsmall = 3)
EBAS_lev2_nox$numflag_no2   <-format(round(EBAS_lev2_nox$numflag_no2,9), nsmall = 9)
#
# -------------------------------------------------------------------------------------------
# writing data set
#
write.table(as.data.frame(EBAS_lev2_nox), file=EBAS_L2_FULLFILENAME,row.names=F,col.names = F, append = T, quote = F,sep=" ")
#
# -------------------------------------------------------------------------------------------
##                                          # END PART 2.3 #
###########################################################################################################################
#                                                                                                                         #
## End of NOX_P21_1810.R                                                                                                  # 
#                                                                                                                         # 
###################################################################################### Authors: L u C A, Davide ###########

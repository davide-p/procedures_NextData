###########################################################################################################################
## Project: NEXTDATA                                                                                                     ##
## Parameter: SO2                                                                                                        ##
## Script first purpose: create a formatted Level-0 dataset (in EBAS format) from raw data                               ##
## Script second purpose: create daily acquisition graphs of all instrumentation variables                               ##
## Run time: the script may run daily (e.g. by using a crontab) or may be used when needed                               ##
##_______________________________________________________________________________________________________________________##
## Authors: Luca Naitza, Davide Putero                                                                                   ##
## Organization: National Research Council of Italy, Institute for Atmospheric Science and Climate (CNR-ISAC)            ##
## Address: Via Gobetti 101, 40129, Bologna, Italy                                                                       ##
## Project Contact: Paolo Cristofanelli                                                                                  ##
## Email: P.Cristofanelli@isac.cnr.it                                                                                    ##
## Phone number: (+39) 051 639 9597                                                                                      ##
##_______________________________________________________________________________________________________________________##
## Script filename: SO2_D20_1810.R                                                                                       ##
## Version Date: July 2019            
## Feb. 19th, 2019: added duplicates removal
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
# Part 1   is another setting section; it should not be modified by the user unless strictly needed.  
# Part 1.1 sets and loads the most commonly used R libraries. The user should not modify this sub-part.
# Part 1.2 specifies the time variables used in the processing. The user should not modify this sub-part. If the user needs 
#          to apply the script to data older than the current year, he/she may modify the lines explicitly marked for this purpose.
#
# Part 2   is the data processing section, it should not be modified by the user.
# Part 2.x contain the code to produce the EBAS format file and to process data. The User should not modify this sub-part(s).
#
# Part 3   is the data reporting section, it should not be modified by the user.
# Part 3.x contain the code to produce graphic reports. The user should not modify this sub-part(s). 
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
CALIB_DIR       = '../naitza/NEXTDATA/PROD/CIMONE/GAS/SO2/RAW_DATA_UTC/CALIB'           
RAW_DIR         = '../naitza/NEXTDATA/PROD/CIMONE/GAS/SO2/RAW_DATA_UTC'
#
# -------- DATA DESTINATION PATH --------------------------------------------------------------# REPLACE THE FOLLOWING PATHS
L0_DIR          = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/GAS/SO2/LEVEL_0'                     
L1_DIR          = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/GAS/SO2/LEVEL_1' 
L2_DIR          = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/GAS/SO2/LEVEL_2'
L0_ANCIL_DIR    = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/GAS/SO2/LEVEL_0/ANCILLARY'
#
# -------- GRAPH DESTINATION PATH -------------------------------------------------------------# REPLACE THE FOLLOWING PATHS
REP_DIR         = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/GAS/SO2/REPORT'
REP_GRAPH_DIR   = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/GAS/SO2/REPORT/DAILY_GRAPH'
PLOT_DIR_M      = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/GAS/SO2/REPORT/MONTHLY_GRAPH'
PLOT_DIR_S      = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/GAS/SO2/REPORT/SEASONAL_GRAPH'
PLOT_DIR_Y      = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/GAS/SO2/REPORT/ANNUAL_GRAPH'
PLOT_DIR_Y_PDF  = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/GAS/SO2/REPORT/ANNUAL_GRAPH/PDF'
PLOT_DIR_T      = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/GAS/SO2/REPORT/TIMEVARIATION_GRAPH' 
#
# -------- DAILY GRAPH PREFIX & SUFFIX -------------------------------------------------------# REPLACE THE FOLLOWING VALUES
DAILY_PREFIX    <-"CMN_SO2"     # chose a prefix for your daily graph (e.g. StationCodeName_ParameterCodeName)
DAILY_SUFFIX    <-"01M"         # chose a suffix for your daily graph (e.g. AcquisitionTiming)
#
# -------- SCRIPTS PATH ----------------------------------------------------------------------# REPLACE THE FOLLOWING PATHS
SCRIPT_DIR      = '../naitza/NEXTDATA/R_SCRIPT'          

## Loading functions for numflags
## The "NXD_numflag_functions_180301.R" scripts assigns the numflag value to the dataset, according to EBAS Flag List
## (https://ebas-submit.nilu.no/Submit-Data/List-of-Data-flags)
## The "NXD_EBAS_numflag_FullList_180103.txt" text file contains the EBAS Flag List, reporting codes, category and description
## Please do NOT apply any change to the following function settings, unless you need to specify a different table of flags
#
source(paste(SCRIPT_DIR,"NXD_numflag_functions_180301.R", sep="/"))

tab_nf          <- read.table(file = paste(SCRIPT_DIR,"NXD_EBAS_numflag_FullList_180103.txt",sep="/"),
                              sep = ";", header = TRUE, quote = NULL)

##                                        # END PART 0.1 #
###########################################################################################################################


###########################################################################################################################
##                                          # PART 0.2 #
## ______________________________________________________________________________________________________________________##
##                                         Setting SO2 Data
## ______________________________________________________________________________________________________________________##
## USE: set the following values of SO2 dataset
## WARNING: SO2 raw data should be recorded according to the following specifications:
##          FILENAME: the filename should contain the acquisition date (YYYYMMDD). E.g.: CMN_SO2_20181215_01M.dat;
#
# -------- SO2 RAW DATASET EXTENSION ----------------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
SO2_EXT         <-".dat"      # if different, replace ".dat" with the extesion of your SO2 Raw Data set
#
# -------- SO2 RAW DATA FIELD SEPARATOR -------------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
SO2_FIELD_SEP   <-" "         # if different, replace " "    with the field separator of your SO2 Raw Data set (e.g. "," or "\t")
#
# -------- SO2 RAW DATA HEADER ----------------------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
SO2_FIELD_NAM   <- T          # if different, replace T      with F if SO2 Raw Data tables do not have the header (field names)
#
# -------- SO2 FIELD POSITION IN THE TABLE -----------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
SO2_DEC_DATE    <- 6          # if different, replace with the field position of start_time (julian date) field in your SO2 Raw Data set
SO2             <- 7          # if different, replace with the field position of SO2 field in your SO2 Raw Data set
SO2_T_internal  <- 8          # if different, replace with the field position of T_internal field in your SO2 Raw Data set
SO2_T_chamber   <- 9          # if different, replace with the field position of T_chamber field in your SO2 Raw Data set
SO2_PMT_V       <- 10         # if different, replace with the field position of PMT_V field in your SO2 Raw Data set
SO2_Flash_V     <- 11         # if different, replace with the field position of Flash_V field in your SO2 Raw Data set
SO2_Flash_ref   <- 12         # if different, replace with the field position of Flash_ref field in your SO2 Raw Data set
SO2_Flow_sample <- 13         # if different, replace with the field position of Flow_sample field in your SO2 Raw Data set
SO2_P_chamb     <- 14         # if different, replace with the field position of P_chamb field in your SO2 Raw Data set
SO2_status      <- 15         # if different, replace with the field position of Status field in your SO2 Raw Data set
SO2_Pgas_temp   <- 16         # if different, replace with the field position of Pgas_temp field in your SO2 Raw Data set
SO2_Flux_Zero   <- 17         # if different, replace with the field position of Flux_Zero field in your SO2 Raw Data set
SO2_BKG         <- 18         # if different, replace with the field position of BKG field in your SO2 Raw Data set
SO2_SPAN        <- 19         # if different, replace with the field position of SPAN field in your SO2 Raw Data set
#
# -------- SO2 STATUS --------------------------------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
Status_SPAN     <- "Span"     # if different, replace with the value reported in the SPAN field for "Span" condition
Status_ZERO     <- "Zero"     # if different, replace with the value reported in the SPAN field for "Zero" condition
#
## ______________________________________________________________________________________________________________________##
##                                         Setting SO2 CALIBRATION Data
## ______________________________________________________________________________________________________________________##
## USE: set the following values of SO2 dataset
## WARNING: CALIBRATION SO2 raw data should be recorded according to the following specifications:
##          FILENAME: the filename should contain the acquisition date (YYYYMMDD). E.g.: CMN_SO2_20181215_01M.dat;
#
# -------- SO2 RAW DATASET EXTENSION ----------------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
CALIB_EXT         <-".dat"      # if different, replace ".dat" with the extesion of your SO2 Raw Data set
#
# -------- SO2 RAW DATA FIELD SEPARATOR -------------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
CALIB_FIELD_SEP   <-" "         # if different, replace " "    with the field separator of your SO2 Raw Data set (e.g. "," or "\t")
#
# -------- SO2 RAW DATA HEADER ----------------------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
CALIB_FIELD_NAM   <- T          # if different, replace T      with F if SO2 Raw Data tables do not have the header (field names)
#
# -------- SO2 FIELD POSITION IN THE TABLE -----------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
CALIB_DEC_DATE    <- 6          # if different, replace with the field position of calibration decimal date field in your Calibration Data set
CALIB_SO2_BKG     <- 7          # if different, replace with the field position of SO2 background coefficient field in your Calibration Data set
CALIB_SO2_BKG_SD  <- 8          # if different, replace with the field position of SO2 background coeff sd field in your Calibration Data set
CALIB_Flux_BKG    <- 9          # if different, replace with the field position of flux background field in your Calibration Data set
CALIB_Flux_BKG_SD <- 10         # if different, replace with the field position of flux background sd field in your Calibration Data set
CALIB_SO2_SPAN    <- 11         # if different, replace with the field position of SO2 span field in your Calibration Data set
CALIB_SO2_SPAN_SD <- 12         # if different, replace with the field position of SO2 span sd field in your Calibration Data set
CALIB_Flux_SPAN   <- 13         # if different, replace with the field position of flux span field in your Calibration Data set
CALIB_Flux_SPAN_SD<- 14         # if different, replace with the field position of flux span sd field in your Calibration Data set
#
# -------------------------------------------------------------------------------------------
##                                        # END PART 0.2 #
###########################################################################################################################


###########################################################################################################################
##                                          # PART 0.3 #
## ______________________________________________________________________________________________________________________##
##                                  Setting time and name variables
##                                  Setting EBAS metadata information
## ______________________________________________________________________________________________________________________##

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

inst_type               <- "UV_fluorescence"                                 # replace the value with your instrument type
inst_manu               <- "Thermo"                                          # replace the value with your instrument manufacter
inst_modl               <- "43iTLE"                                          # replace the value with your instrument model
inst_name               <- "43i"                                             # replace the value with your your instrument name
inst_s_n                <- " "                                               # replace the value with your instrument serial number
meth_ref                <- "IT06L_43i_uvfl"                                  # replace the value with method reference

dependent_col           <- "3"                                               # replace the value with the total number of columns of the file in addition to start_time (i.e., total-1)

component               <- "sulphur dioxide"                                 # replace the value with proper component 
matrix                  <- "air"                                             # replace the value with proper matrix
meas_unit               <- "ppb"                                             # replace the value with proper measurement unit

meas_lat                <- "44.16667"                                        # replace the value with the your Measure latitude
meas_lon                <- "10.68333"                                        # replace the value with the your Measure longitude
meas_alt                <- "2165m"                                           # replace the value with the your Measure altitude (meters)

Period_code             <- "1y"                                              # replace the value with the proper Period code
Resolution_code         <- "1mn"                                             # replace the value with the proper Resolution code
Sample_duration         <- "1mn"                                             # replace the value with the proper Sample duration
Orig_time_res           <- "1mn"                                             # replace the value with the proper Original time resolution

std_meth                <- "SOP=GAW_209(2013)"                               # replace the value with Standard method

inlet_type              <- "Hat or hood"                                     # replace the value with Inlet type
inlet_desc              <- "The air intake is composed by an external (outside building) steel pipe (internally covered by Teflon) and the internal (inside building) Pyrex pipe"    # replace the value with Inlet description
inlet_mat               <- "Teflon"                                          # replace the value with Inlet material
inlet_out_d             <- "6.35 mm"                                         # replace the value with Inlet outer diameter
inlet_in_d              <- ""                                                # replace the value with Inlet inner diameter
inlet_lenght            <- "1.5 m"                                           # replace the value with Inlet tube length

flow_rate               <- "0.40 l/min"                                      # replace the value with Flow rate

zero_check              <- "automatic"                                       # replace the value with Zero/span check type
zero_inter              <- "1d"                                              # replace the value with Zero/span check interval

hum_temp_c              <- "none"                                            # replace the value with Humidity/temperature control
hum_temp_c_desc         <- ""                                                # replace the value with Humidity/temperature control description

vol_std_t               <- "293.15 K"                                        # replace the value with Volume std. temperature
vol_std_p               <- "1013.25 hPa"                                     # replace the value with Volume std. pressure

detec_lim               <- "0.11 ppb"                                        # replace the value with Detection limit
absorp_cs               <- ""                                                # replace the value with Absorption cross section

qa_mes_id               <- "not available"                                   # replace the value with QA measure ID
#qa_date                 <- "not available"                                   # replace the value with QA date
qa_doc                  <- "not available"                                   # replace the value with QA document URL
qa_bias                 <- "0.2 ppb"                                         # replace the value with QA bias

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
#
Submit_1_n              <- "Paolo"      
Submit_1_s              <- "Cristofanelli"
Submit_1_e              <- "p.cristofanelli@isac.cnr.it"
Submit_1_i              <- "Institute of Atmospheric Sciences and Climate, ISAC,, Via P. Gobetti 101,, I-40129, Bologna, Italy"

mycomment               <- ""
#
# Setting the lines of the header
# 
if (nchar(Origin_2_n) == 0 && nchar(Origin_3_n) == 0 && nchar(Origin_4_n) == 0 && nchar(Origin_5_n) == 0)  { L0_n_lines <- 80 + 0 }
if (nchar(Origin_2_n)  > 0 && nchar(Origin_3_n) == 0 && nchar(Origin_4_n) == 0 && nchar(Origin_5_n) == 0)  { L0_n_lines <- 80 + 1 }
if (nchar(Origin_2_n)  > 0 && nchar(Origin_3_n)  > 0 && nchar(Origin_4_n) == 0 && nchar(Origin_5_n) == 0)  { L0_n_lines <- 80 + 2 }
if (nchar(Origin_2_n)  > 0 && nchar(Origin_3_n)  > 0 && nchar(Origin_4_n)  > 0 && nchar(Origin_5_n) == 0)  { L0_n_lines <- 80 + 3 }
if (nchar(Origin_2_n)  > 0 && nchar(Origin_3_n)  > 0 && nchar(Origin_4_n)  > 0 && nchar(Origin_5_n)  > 0)  { L0_n_lines <- 80 + 4 }
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

# Station/Laboratory/Instrument/parameter variables
# NOTE: Please, change these variables with proper station and parameter information
# 

# The following variabiles concern the parameter and the level
# NOTE: Please, do NOT change these variables
# 
param_code              <- "uv_abs.SO2ne.air.1y.1mn"
level_code              <- "lev0.nas"                                       
#
# -------------------------------------------------------------------------------------------
# Time variables
# NOTE: the following variables should not be modified, except those with explicit comments
# 
questo_anno             <-format(Sys.Date(), "%Y")

# -------- PREVIOUS YEAR(S) DATA PROCESSING ---------------------------------------# IF NEEDED, UN-COMMENT THE FOLLOWING LINE
#questo_anno             <-as.numeric(questo_anno) -1   # the value "-1" means "last year". Change to "-2" or "-3" etc. for previous

questo_mese             <-format(Sys.Date(), "%m")
questo_mese_nome        <-format(Sys.Date(), "%B")
questo_giorno           <-format(Sys.Date(), "%d")

if (questo_mese == "01" & questo_giorno == "01")    { questo_anno <- as.numeric(questo_anno)-1 }                                                       

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

# -------------------------------------------------------------------------------------------
# File name variables
# NOTE: the following variables should not be modified 
# 
EBAS_L0_FILENAME        <-paste(s_code,questo_inizioanno,rev_datime,param_code,level_code,sep=".")
EBAS_L0_FULLFILENAME    <-paste(L0_DIR,EBAS_L0_FILENAME,sep = "/")
EBAS_temp_FILENAME      <-paste(L0_DIR,paste("temp_SO2_",EBAS_L0_FILENAME,sep=""),sep = "/")
CALIB_temp_FILENAME     <-paste(L0_DIR,paste("temp_CALIB_",EBAS_L0_FILENAME,sep=""),sep = "/")
MERGE_temp_FULLFILENAME <-paste(L0_DIR,paste("temp_MERGE_SO2_CALIB_",EBAS_L0_FILENAME,sep=""),sep = "/")
FINAL_temp_FULLFILENAME <-paste(L0_DIR,paste("temp_FINAL_",EBAS_L0_FILENAME,sep=""),sep = "/")
INST_VARIAB_NAME        <-paste(L0_ANCIL_DIR,paste("INST_VAR_",EBAS_L0_FILENAME,sep=""),sep = "/")
#
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

EBAS_L0_FILENAME
EBAS_L0_FULLFILENAME
CALIB_temp_FILENAME
MERGE_temp_FULLFILENAME
FINAL_temp_FULLFILENAME
#                                         # END PART 1.1 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 2.0 #
## ______________________________________________________________________________________________________________________##
##                                    Creation of Level-0 data file
##                                     Cleaning Destination directory
##                                        Formatting Level-0 header
## ______________________________________________________________________________________________________________________##
# Deleting temporary files in the destination directory (if present)
# 
FILE_TMP        <-list.files(path = L0_DIR, pattern = glob2rx("temp_*"), 
                             all.files = FALSE,
                             full.names = F, 
                             recursive = FALSE,
                             ignore.case = FALSE, 
                             include.dirs = F, 
                             no.. = FALSE)
LISTA_FILE_TMP  <-as.character(FILE_TMP)
LISTA_FILE_TMP
for(f in LISTA_FILE_TMP) { file.remove(paste(L0_DIR,f,sep = "/")) }
#
# -------------------------------------------------------------------------------------------
# Cleaning Destination directory
# NOTE: the following process deletes old EBAS Level-0 files within the destination directory 
# 
MYOLD_FILE      <-paste(s_code,".",questo_anno,sep = "")

FILE_OLD        <-list.files(path = L0_DIR, pattern = glob2rx(paste(MYOLD_FILE,"*",sep = "")), 
                             all.files = FALSE,
                             full.names = F, 
                             recursive = FALSE,
                             ignore.case = FALSE, 
                             include.dirs = F, 
                             no.. = FALSE)
FILE_OLD
LISTA_FILE_OLD  <-as.character(FILE_OLD)
for(f in LISTA_FILE_OLD) { file.remove(paste(L0_DIR,f,sep = "/")) }
#
# -------------------------------------------------------------------------------------------
# Creating the new EBAS LEVEL-0 data file
# NOTE: the following process deletes old EBAS Level-0 files within the destination directory
#
write.table(" ", file=EBAS_L0_FULLFILENAME,row.names=F,col.names = F, append = F,sep=" ")
#
# -------------------------------------------------------------------------------------------
# Formatting EBAS LEVEL-0 header and adding information to the data file
# NOTE: information contained in the following lines should be modified with proper station and instrumentation information
#
cat(
  paste(L0_n_lines,"1001",sep=" "),
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
  "0 
Days from the file reference point (start_time)",
  dependent_col,
  "1 1 1
9999.99999999 9999.99 9.999999999
end_time, days from the file reference point
sulphur_dioxide, ppb
numflag sulphur_dioxide, no unit
0",
  (L0_n_lines - 17),
  "Data definition:                  EBAS_1.1
Data level:                       0
Version:                          1
Version description:              initial revision
Set type code:                    TI",
  paste("Station code:                     ",s_code,sep=""),
  paste("Platform code:                   ",gsub("R","S",s_code)),
  "Timezone:                         UTC",
  paste("Startdate:                        ",questo_inizioanno[1],sep=""),  
  paste("Revision date:                    ",as.numeric(new_date)-7200,sep=""),
  paste("Component:                        ",component,sep=""), 
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
  paste("File name:                        ",EBAS_L0_FILENAME,sep=""),
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
  paste("Absorption cross section:         ",absorp_cs,sep=""),
  paste("Zero/span check type:             ",zero_check,sep=""),
  paste("Zero/span check interval:         ",zero_inter,sep=""),
  paste("Standard method:                  ",std_meth,sep=""),
  paste("QA measure ID                     ",qa_mes_id,sep=""),
  paste("QA date:                          ",paste(questo_anno,questo_mese,questo_giorno,sep=""),sep=""),
  paste("QA1 bias:                         ",qa_bias,sep=""),
  paste("QA document URL:                  ",qa_doc,sep=""),
  paste("Originator:                       ",paste(Origin_1_n,Origin_1_s,Origin_1_e,Origin_1_i,sep=", "),sep=""),
  paste("Originator:                       ",paste(Origin_2_n,Origin_2_s,Origin_2_e,Origin_2_i,sep=", "),sep=""),
  paste("Originator:                       ",paste(Origin_3_n,Origin_3_s,Origin_3_e,Origin_3_i,sep=", "),sep=""),
  if(nchar(Origin_4_n)>0) {paste("Originator:                       ",paste(Origin_4_n,Origin_4_s,Origin_4_e,Origin_4_i,sep=", "),sep="")},
  if(nchar(Origin_5_n)>0) {paste("Originator:                       ",paste(Origin_5_n,Origin_5_s,Origin_5_e,Origin_5_i,sep=", "),sep="")},
  paste("Submitter:                        ",paste(Submit_1_n,Submit_1_s,Submit_1_e,Submit_1_i,sep=", "),sep=""),
  paste("Comment:                          ",mycomment,sep=""),       
  "Acknowledgement:                  Request acknowledgment details from data originator",
  paste("start_time","end_time","so2","numflag_so2",sep=" "),
  
  file=EBAS_L0_FULLFILENAME, append=F, sep = "\n") 

##                                         # END PART 2.0 #
###########################################################################################################################


###########################################################################################################################
##                                          # PART 2.1 #
## ______________________________________________________________________________________________________________________##
##                                         Importing raw data
##                          Processing, manipulation, transformation of raw data
##                                       Level-0 data flagging
##                              Writing data in Level-0 data file (EBAS format) 
## ______________________________________________________________________________________________________________________##
# Listing the SO2 Raw data
#
lsfiles                 <-file.info(dir(RAW_DIR, pattern = glob2rx(paste0("*",SO2_EXT)), full.names = F, ignore.case = TRUE))

lista                   <-data.frame(lsfiles[order(lsfiles$mtime),])
setDT(lista, keep.rownames = T)[]
names(lista)[1]         <-"fileName"
df_lista                <-data.frame(lista[fileName %like% questo_anno])
names(df_lista)[1]      <-"fileName"
df_lista$mydata         <-df_lista
ndata <- NROW(df_lista)
#
# -------------------------------------------------------------------------------------------
# Creating temporary SO2 dataset for current year
# 
for(j in df_lista$fileName) {
  
  ULTIMO_DATO           <-paste(RAW_DIR,j, sep="/")
  ULTIMO_DATO_NAME      <-basename(ULTIMO_DATO)
  TABELLA               <-read.table(file=ULTIMO_DATO,fill = T, header = SO2_FIELD_NAM, row.names=NULL,
                                     colClasses = c(rep("numeric",6),rep("character",25)))
  
  names(TABELLA)[SO2_DEC_DATE]    <-"start_time"
  names(TABELLA)[SO2]             <-"so2"  
  names(TABELLA)[SO2_T_internal]  <-"T_internal"
  names(TABELLA)[SO2_T_chamber]   <-"T_chamber"
  names(TABELLA)[SO2_PMT_V]       <-"PMT_V"
  names(TABELLA)[SO2_Flash_V]     <-"Flash_V"
  names(TABELLA)[SO2_Flash_ref]   <-"Flash_ref"
  names(TABELLA)[SO2_Flow_sample] <-"Flow_sample"
  names(TABELLA)[SO2_P_chamb]     <-"P"
  names(TABELLA)[SO2_status]      <-"status" 
  names(TABELLA)[SO2_Pgas_temp]   <-"Pgas_temp"
  names(TABELLA)[SO2_Flux_Zero]   <-"Flux_Zero"
  names(TABELLA)[SO2_BKG]         <-"SO2-BKG"
  names(TABELLA)[SO2_SPAN]        <-"SO2-SPAN"  
  #
  # -------------------------------------------------------------------------------------------
  # Adding new fields
  #
  TABELLA$end_time        <-as.numeric(TABELLA$start_time) + 0.00069444
  TABELLA$so2             <-as.numeric(TABELLA$so2)
  TABELLA                 <-subset(TABELLA, select=c("start_time","end_time","so2","T_internal","T_chamber",
                                                     "PMT_V","Flash_V","Flash_ref","Flow_sample","P", "status", 
                                                     "Pgas_temp","Flux_Zero","SO2-BKG","SO2-SPAN"))
  write.table(TABELLA, file=EBAS_temp_FILENAME,row.names=F,col.names = F, append = T, quote = F,sep=" ")
}
#
# -------------------------------------------------------------------------------------------
# Processing collected data
#
TABELLA                 <-read.table(EBAS_temp_FILENAME,row.names=NULL, stringsAsFactors = FALSE, fill = T)
colnames(TABELLA)       <-c("start_time","end_time","so2","T_internal","T_chamber",
                            "PMT_V","Flash_V","Flash_ref","Flow_sample","P", "status", 
                            "Pgas_temp","Flux_Zero","SO2-BKG","SO2-SPAN")
# -------------------------------------------------------------------------------------------
# Converting JD values to date
#
TABELLA$jd              <-as.integer(TABELLA$start_time)
TABELLA$day             <-as.Date(TABELLA$start_time, origin=questa_start_time)
TABELLA$time.dec        <-TABELLA$start_time-TABELLA$jd
TABELLA$time            <-TABELLA$time.dec*1440+0.01
TABELLA$hour            <-as.integer(TABELLA$time/60)
TABELLA$min             <-as.integer(TABELLA$time-TABELLA$hour*60)
TABELLA$date            <-paste(TABELLA$day," ",TABELLA$hour,":",TABELLA$min,":00",sep="")
TABELLA$date            <-as.POSIXct(strptime(TABELLA$date, format = "%Y-%m-%d %H:%M:%S", tz = "GMT"))
#
# -------------------------------------------------------------------------------------------
# Flagging SO2 values:
# See PART 0.1 for the setting of numflag script and table
#
# Defining SO2 elaboration and creating SO2 flag field


# TABELLA$so2_elab        <-TABELLA$so2
TABELLA$numflag         <-0
#
# -------------------------------------------------------------------------------------------
# Calculating difference between successive values:
#
so2_diff                <-diff(TABELLA$so2)
n                       <-nrow(TABELLA)
so2_diff[n]             <-0
TABELLA$so2_diff        <-so2_diff
#
# -------------------------------------------------------------------------------------------
# Calculating coefficients from span and zero:
#
TABELLA$DATAORAMIN      <-paste(gsub("-","",(TABELLA$day)),sprintf("%02d",TABELLA$hour),sprintf("%02d",TABELLA$min),sep="") 
TABELLA$DATA            <-gsub("-","",(TABELLA$day))
TABELLA$my_Zero_so2_Mean<-0.0 
#
myspanzero              <-subset(TABELLA, status == Status_SPAN | status == Status_ZERO)

for (d in unique(as.numeric(myspanzero$DATA))){
  myspanzero_d            <-subset(myspanzero, DATA == d)
  
  my_Zero                 <-subset(myspanzero_d, myspanzero_d$status =="Zero" & myspanzero_d$Flux_Zero > 0.2)
  
  my_Span                 <-subset(myspanzero_d, myspanzero_d$status =="Span" & myspanzero_d$Flux_Zero > 0.2)
  my_Span_firstminute     <-head(my_Span,1)$DATAORAMIN
  
  my_SpanZero_firstminute <-head(myspanzero_d,1)$DATAORAMIN 
  my_SpanZero_lastminute  <-tail(myspanzero_d,1)$DATAORAMIN
  
  #________________________media ultimi 10 ZERO prima dello SPAN___________________________    
  my_Zero_last10          <-tail(subset(myspanzero_d, status == "Zero" & DATAORAMIN < my_Span_firstminute),11)
  
  my_Zero_last10          <-head(my_Zero_last10,10)
  
  if(nrow(my_Zero_last10) >0)
  { 
    my_Zero_so2_Mean      <-mean(my_Zero_last10$so2)
    
  }
  TABELLA$my_Zero_so2_Mean[TABELLA$DATAORAMIN >= my_Zero_last10$DATAORAMIN]   <- my_Zero_so2_Mean
}

TABELLA$so2_elab       <-(as.numeric(TABELLA$so2) - as.numeric(TABELLA$my_Zero_so2_Mean)) * 1.0000
#
# -------------------------------------------------------------------------------------------
# Flagging SO2
#
TABELLA$numflag[TABELLA$so2_elab < -0.15]    <- 0.456000000  
for (i in 1:nrow(TABELLA))
{
  if (!is.na (TABELLA$so2_elab[i]) & (TABELLA$so2_elab[i] < 0.10) & (TABELLA$numflag[i] == 0)) {TABELLA$numflag[i]  <- 0.147000000}
}  

for (i in 2:nrow(TABELLA)-1)
{
  
  #Be careful: the following selection can delete REAL STRONG LOCAL pollution event  
  if (TABELLA$so2[i] > 10 & !is.na (TABELLA$so2[i]))           {TABELLA$numflag[i]   <- 0.456000000; TABELLA$numflag[i+1]   <- 0.456000000;}
  
  if (TABELLA$Flow_sample[i] < 0.2 & !is.na (TABELLA$Flow_sample[i]))  {TABELLA$numflag[i] <- 0.664000000}                                 ## verificare l'acodamento flag
  
  if (TABELLA$status[i] %in% "Zero"  & TABELLA$Flux_Zero[i]> 0.2 & !is.na (TABELLA$Flux_Zero[i])) {TABELLA$numflag[i] <- 0.682000000;  ## verificare l'acodamento flag
  TABELLA$numflag[i-1]              <- 0.682000000;                                                         ## verificare l'acodamento flag                                       
  TABELLA$numflag[i+1]              <- 0.682000000;                                                         ## verificare l'acodamento flag
  }
  
  if (TABELLA$status[i] %in% "Span"  & TABELLA$Flux_Zero[i]> 0.2 & !is.na (TABELLA$Flux_Zero[i])) {TABELLA$numflag[i] <- 0.682000000;  ## verificare l'acodamento flag
  TABELLA$numflag[i-1]              <- 0.682000000;                                                         ## verificare l'acodamento flag
  TABELLA$numflag[i+1]              <- 0.682000000                                                          ## verificare l'acodamento flag
  }
}

TABELLA$numflag [is.na(TABELLA$numflag)  |  is.na(TABELLA$so2_elab)]  <- 0.999000000
TABELLA$so2_elab[is.na(TABELLA$so2_elab)]         <- 999.99
TABELLA$numflag [TABELLA$so2_elab == 999.99]      <- 0.999000000 

TABELLA$start_time[is.na(TABELLA$start_time)]     <-0
# 
# -------------------------------------------------------------------------------------------
# Appending Data set to EBAS Level-0 Header
#
myEBAS                  <-TABELLA[,c("start_time","end_time","so2_elab","numflag")]
#
# Removing possible duplicates
myEBAS <- myEBAS[!duplicated(myEBAS[1]),] # Check in code
#
# Set the proper output format
#
sprintf_formats <- c(rep("%.8f", 2), rep("%.2f", 1), rep("%.9f", 1))
myEBAS[]        <- mapply(sprintf, sprintf_formats, myEBAS)
#
# Appending Data set to EBAS Level-0 Header
#
write.table(myEBAS, file=EBAS_L0_FULLFILENAME,row.names=F,col.names = F, append = T, quote = F,sep=" ")
#
# -------------------------------------------------------------------------------------------
# Cleaning destination directory for instrumental check table (ANCIL_DIR)
INST_OLD              <-list.files(path = L0_ANCIL_DIR, pattern = glob2rx(paste("INST_VAR_",s_code,".",questo_anno,"*",sep = "")), all.files = FALSE,
                                   full.names = F, recursive = FALSE,
                                   ignore.case = FALSE, include.dirs = F, no.. = FALSE)
INST_OLD
LISTA_FILE_OLD<-as.character(INST_OLD)
for(f in LISTA_FILE_OLD)
{
  file.remove(paste(L0_ANCIL_DIR,f,sep = "/"))
}
#
# -------------------------------------------------------------------------------------------
# Writing instrumental check table (as ancillary product)
#
MYINST              <-TABELLA [,c(22, 1:3, 28, 24, 27, 23, 4:15)]
inst_variables      <-write.table(MYINST, file=INST_VARIAB_NAME,row.names=F,col.names = T, append = F, quote = F,sep=" ") 

#
# -------------------------------------------------------------------------------------------
# Deleting temporary files in the destination directory (if present)
# 
FILE_TMP        <-list.files(path = L0_DIR, pattern = glob2rx("temp_*"), all.files = FALSE,
                             full.names = F, recursive = FALSE,
                             ignore.case = FALSE, include.dirs = F, no.. = FALSE)
LISTA_FILE_TMP  <-as.character(FILE_TMP)
LISTA_FILE_TMP
for(f in LISTA_FILE_TMP) { file.remove(paste(L0_DIR,f,sep = "/")) }
#
##                                        # END PART 2.1 #
###########################################################################################################################


##>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> DAILY GRAPH REPORTING <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<##
###########################################################################################################################
##                                           # PART 3.0 #
## ______________________________________________________________________________________________________________________##
##                                 Loading data and setting variables
##                                              Timeplot
## ______________________________________________________________________________________________________________________##
# Extracting the calendar day from start_time
#
REPORTAB            <-TABELLA[, c("start_time",
                                 "so2",
                                 "so2_elab",
                                 "numflag",
                                 "my_Zero_so2_Mean",
                                 "P",
                                 "Flow_sample",
                                 "T_internal",
                                 "T_chamber",
                                 "PMT_V", 
                                 "Flash_V"
                                 )]

REPORTAB$Zero_Mean   <-REPORTAB$my_Zero_so2_Mean
REPORTAB$so2_elab    [REPORTAB$numflag >= 0.456000000  |  REPORTAB$so2_elab > 999] <- NA
REPORTAB$so2         [REPORTAB$numflag >= 0.450000000] <- 0

REPORTAB[]          <-lapply(REPORTAB, function(x) as.numeric(as.character(x)))
REPORTAB$day        <-REPORTAB$start_time-(REPORTAB$start_time-floor(REPORTAB$start_time)-1)
REPORTAB$date       <-as.POSIXct(as.Date(REPORTAB$start_time, origin = questo_capodanno))
reportday           <-c(REPORTAB[!duplicated(REPORTAB[,c('day')]),]$day)
print(reportday)    # check point: print the days in the table
#
# -------------------------------------------------------------------------------------------
# Creating Visual Inspection Graphs for each calendar day
#
for (d in reportday)
{
  THISREPORTTAB     <-subset(REPORTAB, day==d)  
  reportdate        <-strptime(paste(questo_anno, d), format="%Y %j")
  mydatename        <-paste(DAILY_PREFIX,gsub("-","",substring(reportdate,1,10)),DAILY_SUFFIX,sep = "_")
  
  ULTIMO_DATO_PNG   <-paste(paste(REP_GRAPH_DIR,mydatename,sep="/"),
                            "png", sep=".")
  
  if (file.exists(ULTIMO_DATO_PNG)){} else 
  {png(file = ULTIMO_DATO_PNG,width=10000,height=15000,res=1000)
    timePlot(THISREPORTTAB,pollutant=c("so2",
                                       "so2_elab",
                                       "numflag",
                                       "Zero_Mean",
                                       "P",
                                       "Flow_sample",
                                       "T_internal",
                                       "T_chamber",
                                       "PMT_V", 
                                       "Flash_V"
                                       ),
             cex=25,date.breaks=15, y.relation="free", key = FALSE, fontsize = 14)
    dev.off()
  }
}

##                                          # END PART 3.0 #
###########################################################################################################################
#                                                                                                                         #
## End of SO2_D20_1810.R                                                                                                  # 
#                                                                                                                         # 
###################################################################################### Authors: L u C A, Davide ###########

###########################################################################################################################
## Project: NEXTDATA                                                                                                     ##
## Parameter: NOx                                                                                                        ##
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
## Script filename: NOX_P20_1810.R                                                                                       ##
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
CALIB_DIR       = '../naitza/NEXTDATA/PROD/CIMONE/GAS/NO/RAW_DATA_UTC/CALIB'           
RAW_DIR         = '../naitza/NEXTDATA/PROD/CIMONE/GAS/NO/RAW_DATA_UTC'
METEO_RAW_DIR   = '../naitza/NEXTDATA/PROD/CIMONE/METEO/METEO/RAW_DATA_UTC'
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
# -------- DAILY GRAPH PREFIX & SUFFIX -------------------------------------------------------# REPLACE THE FOLLOWING VALUES
DAILY_PREFIX    <-"CMN_NO"      # choose a prefix for your daily graph (e.g. StationCodeName_ParameterCodeName)
DAILY_SUFFIX    <-"01M"         # choose a suffix for your daily graph (e.g. AcquisitionTiming)
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
##                                         Setting NO Data
## ______________________________________________________________________________________________________________________##
## USE: set the following values of NO dataset
## WARNING: NO raw data should be recorded according to the following specifications:
##          FILENAME: the filename should contain the acquisition date (YYYYMMDD). E.g.: CMN_NO_20181215_01M.dat;
#
# -------- NO RAW DATASET EXTENSION ----------------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
NO_EXT         <-".dat"      # if different, replace ".dat" with the extesion of your NO Raw Data set
#
# -------- NO RAW DATA FIELD SEPARATOR -------------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
NO_FIELD_SEP   <-" "         # if different, replace " "    with the field separator of your NO Raw Data set (e.g. "," or "\t")
#
# -------- NO RAW DATA HEADER ----------------------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
NO_FIELD_NAM   <- T          # if different, replace T      with F if NO Raw Data tables do not have the header (field names)
#
# -------- NO FIELD POSITION IN THE TABLE -----------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
NO_DEC_DATE   <- 6          # if different, replace with the field position of start_time (julian date) field in your NO Raw Data set
NO            <- 7          # if different, replace with the field position of NO field in your NO Raw Data set
NO2           <- 8          # if different, replace with the field position of NO2 field in your NO Raw Data set
NOx           <- 9          # if different, replace with the field position of NOx field in your NO Raw Data set
NO_PRE        <- 10         # if different, replace with the field position of Pre field in your NO Raw Data set
NO_FLOW_SAMPLE<- 20         # if different, replace with the field position of Flow_sample field in your NO Raw Data set
NO_P_CHAMBER  <- 18         # if different, replace with the field position of P_chamb field in your NO Raw Data set
NO_T_COOLER   <- 15         # if different, replace with the field position of T_Cooler field in your NO Raw Data set
NO_T_CHAMBER  <- 14         # if different, replace with the field position of T_chamber field in your NO Raw Data set
NO_T_INTERNA  <- 13         # if different, replace with the field position of T_internal field in your NO Raw Data set
PMT_V         <- 16         # if different, replace with the field position of PMT_V field in your NO Raw Data set
#
## ______________________________________________________________________________________________________________________##
##                                         Setting NO CALIBRATION Data
## ______________________________________________________________________________________________________________________##
## USE: set the following values of NO dataset
## WARNING: CALIBRATION NO raw data should be recorded according to the following specifications:
##          FILENAME: the filename should contain the acquisition date (YYYYMMDD). E.g.: CMN_NO_20181215_01M.dat;
#
# -------- NO RAW DATASET EXTENSION ----------------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
CALIB_EXT         <-".dat"      # if different, replace ".dat" with the extesion of your NO Raw Data set
#
# -------- NO RAW DATA FIELD SEPARATOR -------------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
CALIB_FIELD_SEP   <-" "         # if different, replace " "    with the field separator of your NO Raw Data set (e.g. "," or "\t")
#
# -------- NO RAW DATA HEADER ----------------------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
CALIB_FIELD_NAM   <- T          # if different, replace T      with F if NO Row Data tables do not have the header (filed names)
#
# -------- NO FIELD POSITION IN THE TABLE -----------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
CALIB_DEC_DATE    <- 6          # if different, replace with the field position of start_time (julian date) field in your Calibration Data set
CALIB_GAS_CONC    <- 7          # if different, replace with the field position of Gas Concentration field in your Calibration Data set
CALIB_GAS_FLOW_TG <- 13         # if different, replace with the field position of Gas Flow Target field in your Calibration Data set    
CALIB_STATUS      <- 59         # if different, replace with the field position of Status field in your Calibration Data set
#
# -------- CALIB STATUS ------------------------------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
Status_SPAN     <- "Span"     # if different, replace with the value reported in the SPAN filed for "Span" condition
Status_ZERO     <- "Zero"     # if different, replace with the value reported in the SPAN filed for "Zero" condition
Status_STBY     <- "StandBy"  # if different, replace with the value reported in the SPAN filed for "Standby" condition
#
## ______________________________________________________________________________________________________________________##
##                                       Setting Meteo Data
## ______________________________________________________________________________________________________________________##
## USE: set the following values to properly link on-site measured Pressure, Temperature and RH values to CPC dataset
## WARNING: Meteo raw data should be recorded according to the following specifications:
##          FILENAME: the filename should contain the acquisition date (YYYYMMDD). E.g.: CMN_METEO_20181215_01M.dat;
#
# -------- METEO RAW DATASET EXTENSION ----------------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
METEO_EXT       <-".dat"      # if different, replace ".dat" with the extesion of your Meteo Raw Data set
#
# -------- METEO RAW DATA FIELD SEPARATOR -------------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
METEO_FIELD_SEP <-" "         # if different, replace " " with the field separator of your Meteo Raw Data set (e.g. "," or "\t")
#
# -------- METEO RAW DATA HEADER -----------------------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
METEO_FIELD_NAM <- T          # if different, replace "T" with "F" if Meteo Row Data tables do not have the header (field names)
#
# -------- METEO FIELD POSITION -----------------------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
METEO_DEC_DATE  <- 6          # if different, replace with the field position of start_time (julian date) field in your Meteo Raw Data set
METEO_P         <- 15         # if different, replace with the field position of Pressure field in your Meteo Raw Data set
METEO_SD_P      <- 16         # if different, replace with the field position of SD Pressure field in your Meteo Raw Data set
METEO_T         <- 11         # if different, replace with the field position of Temperature field in your Meteo Raw Data set
METEO_SD_T      <- 12         # if different, replace with the field position of SD Temperature field in your Meteo Raw Data set
#
# -------- METEO UNITS ------------------------------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
METEO_T_UNIT     <- "C"       # if different, replace with the value of the Temperature Unit (C= Celsius; K = Kelvin)
#
##                                        # END PART 0.2 #
###########################################################################################################################


###########################################################################################################################
##                                          # PART 0.3 #
## ______________________________________________________________________________________________________________________##
##                                  Setting time and name variables
##                                  Setting EBAS metadata inrofmation
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

flow_rate               <- "0.40 l/min"                                      # replace the value with Flow rate

zero_check              <- "automatic"                                       # replace the value with Zero/span check type
zero_inter              <- "1d"                                              # replace the value with Zero/span check interval

hum_temp_c              <- "none"                                            # replace the value with Humidity/temperature control
hum_temp_c_desc         <- "Passive, inlet air heated from atmospheric to converter temperature"            # replace the value with Humidity/temperature control description

vol_std_t               <- "293.15 K"                                        # replace the value with Volume std. temperature
vol_std_p               <- "1013.25 hPa"                                     # replace the value with Volume std. pressure

detec_lim               <- "0.11 ppb"                                        # replace the value with Detection limit
detec_lim_ex            <- "Determined by zero noise"                        # replace the value with Detection limit expl.

qa_mes_id               <- "not available"                                   # replace the value with QA measure ID
#qa_date                 <- "not available"                                   # replace the value with QA date
qa_doc                  <- "not available"                                   # replace the value with QA document URL

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
if (nchar(Origin_2_n) == 0 && nchar(Origin_3_n) == 0 && nchar(Origin_4_n) == 0 && nchar(Origin_5_n) == 0)  { L0_n_lines <- 88 + 0 }
if (nchar(Origin_2_n)  > 0 && nchar(Origin_3_n) == 0 && nchar(Origin_4_n) == 0 && nchar(Origin_5_n) == 0)  { L0_n_lines <- 88 + 1 }
if (nchar(Origin_2_n)  > 0 && nchar(Origin_3_n)  > 0 && nchar(Origin_4_n) == 0 && nchar(Origin_5_n) == 0)  { L0_n_lines <- 88 + 2 }
if (nchar(Origin_2_n)  > 0 && nchar(Origin_3_n)  > 0 && nchar(Origin_4_n)  > 0 && nchar(Origin_5_n) == 0)  { L0_n_lines <- 88 + 3 }
if (nchar(Origin_2_n)  > 0 && nchar(Origin_3_n)  > 0 && nchar(Origin_4_n)  > 0 && nchar(Origin_5_n)  > 0)  { L0_n_lines <- 88 + 4 }
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
param_code              <- "chemiluminescence_photolytic.NOx.air.1y.1mn.IT06L_ThermoScientific_Tei42TL_CMN"
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

# -------------------------------------------------------------------------------------------
# File name variables
# NOTE: the following variables should not be modified 
# 
EBAS_L0_FILENAME        <-paste(s_code,questo_inizioanno,rev_datime,param_code,level_code,sep=".")
EBAS_L0_FULLFILENAME    <-paste(L0_DIR,EBAS_L0_FILENAME,sep = "/")
EBAS_temp_FILENAME      <-paste(L0_DIR,paste("temp_NO_",EBAS_L0_FILENAME,sep=""),sep = "/")
CALIB_temp_FILENAME     <-paste(L0_DIR,paste("temp_CALIB_",EBAS_L0_FILENAME,sep=""),sep = "/")
METEO_temp_FULLFILENAME <-paste(L0_DIR,paste("temp_METEO_",EBAS_L0_FILENAME,sep=""),sep = "/")
FINAL_temp_FULLFILENAME <-paste(L0_DIR,paste("temp_FINAL_",EBAS_L0_FILENAME,sep=""),sep = "/")
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
METEO_temp_FULLFILENAME
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
# -------------------------------------------------------------------------------------------
# Cleaning destination directory of check table
#
ANC_OLD              <-list.files(path = L0_ANCIL_DIR, pattern = glob2rx(paste("NOx_","*",questo_anno,"*",sep = "")), all.files = FALSE,
                                  full.names = F, recursive = FALSE,
                                  ignore.case = FALSE, include.dirs = F, no.. = FALSE)
ANC_OLD
LISTA_FILE_OLD<-as.character(ANC_OLD)
for(f in LISTA_FILE_OLD)
{
  file.remove(paste(L0_ANCIL_DIR,f,sep = "/"))
}
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
"1 1 1 1 1 1 1 1 1 1
999.99999999 999.999 0.999999999 999.999 0.999999999 99.99 999.99 0.999999999 9999.99 0.999999999
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
(L0_n_lines - 24),
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
paste("Duration of stay in converter or bypass line:        ","",sep=""),
paste("Duration of stay in converter:    ",duration_conv,sep=""),
paste("Humidity/temperature control:     ",hum_temp_c,sep=""),
paste("Humidity/temperature control description: ",hum_temp_c_desc,sep=""),
paste("Volume std. temperature:          ",vol_std_t,sep=""),
paste("Volume std. pressure:             ",vol_std_p,sep=""),
paste("Detection limit:                  ",detec_lim,sep=""),
paste("Detection limit expl.:            ",detec_lim_ex,sep=""),
paste("Zero/span check type:             ",zero_check,sep=""),
paste("Zero/span check interval:         ",zero_inter,sep=""),
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
# Listing the NO Raw data
#
lsfiles                 <-file.info(dir(RAW_DIR, pattern = glob2rx(paste0("*",NO_EXT)), full.names = F, ignore.case = TRUE))

lista                   <-data.frame(lsfiles[order(lsfiles$mtime),])
setDT(lista, keep.rownames = T)[]
names(lista)[1]         <-"fileName"
df_lista                <-data.frame(lista[fileName %like% questo_anno])
names(df_lista)[1]      <-"fileName"
df_lista$mydata         <-df_lista
ndata <- NROW(df_lista)
#
# -------------------------------------------------------------------------------------------
# Creating temporary NO dataset for current year
# 
for(j in df_lista$fileName) {
  
  ULTIMO_DATO           <-paste(RAW_DIR,j, sep="/")
  ULTIMO_DATO_NAME      <-basename(ULTIMO_DATO)
  TABELLA               <-read.table(file=ULTIMO_DATO,fill = T, header = NO_FIELD_NAM, row.names=NULL)
  
  names(TABELLA)[NO_DEC_DATE]    <-"start_time"
  names(TABELLA)[NO]              <-"NO"  
  names(TABELLA)[NO2]             <-"NO2"
  names(TABELLA)[NOx]             <-"NOx"
  names(TABELLA)[NO_PRE]          <-"Pre"
  names(TABELLA)[NO_FLOW_SAMPLE]  <-"Flow_sample"
  names(TABELLA)[NO_P_CHAMBER]    <-"P_chamb"
  names(TABELLA)[NO_T_COOLER]     <-"T_Cooler"
  names(TABELLA)[NO_T_CHAMBER]    <-"T_chamber"
  names(TABELLA)[NO_T_INTERNA]    <-"T_internal"
  names(TABELLA)[PMT_V]           <-"PMT_V" 
  #
  # -------------------------------------------------------------------------------------------
  # Adding new fields
  #
  TABELLA$end_time        <-as.numeric(TABELLA$start_time) + 0.00069444
  TABELLA$code            <-gsub(" ","",paste("code",format(TABELLA$start_time,digits=5,nsmall = 5),sep="_"))

  TABELLA                 <-subset(TABELLA, select=c("start_time","end_time","NO","NO2","NOx",
                                                     "Pre","Flow_sample","P_chamb","T_Cooler","T_chamber", "T_internal", "PMT_V","code"))
  
  write.table(TABELLA, file=EBAS_temp_FILENAME,row.names=F,col.names = F, append = T, quote = F,sep=" ")
}
#
# -------------------------------------------------------------------------------------------
# Listing the METEO Raw data
#
lsfiles                 <-file.info(dir(CALIB_DIR, pattern = glob2rx(paste0("*",CALIB_EXT)), full.names = F, ignore.case = TRUE))

lista                   <-data.frame(lsfiles[order(lsfiles$mtime),])
setDT(lista, keep.rownames = T)[]
names(lista)[1]         <-"fileName"
df_lista                <-data.frame(lista[fileName %like% questo_anno])
names(df_lista)[1]      <-"fileName"
df_lista$mydata         <-df_lista
ndata <- NROW(df_lista)
#
# -------------------------------------------------------------------------------------------
# Creating temporary CALIBRATION dataset for current year
# 
for(j in df_lista$fileName) {
  
  ULTIMO_DATO           <-paste(CALIB_DIR,j, sep="/")
  ULTIMO_DATO_NAME      <-basename(ULTIMO_DATO)
  CALIB_TABELLA         <-read.table(file=ULTIMO_DATO,fill = T, header = CALIB_FIELD_NAM, row.names=NULL)

  names(CALIB_TABELLA)[CALIB_DEC_DATE]    <-"start_time"
  names(CALIB_TABELLA)[CALIB_GAS_CONC]    <-"Gas_conc"
  names(CALIB_TABELLA)[CALIB_GAS_FLOW_TG] <-"Gasflow_target"
  names(CALIB_TABELLA)[CALIB_STATUS]      <-"status"  
  
  CALIB_TABELLA$code    <-gsub(" ","",paste("code",format(CALIB_TABELLA$start_time,digits=5,nsmall = 5),sep="_"))
  #
  # -------------------------------------------------------------------------------------------
  # writing calibration temponary table
  #
  CALIB_TABELLA         <-subset(na.omit(CALIB_TABELLA), select=c("start_time","Gas_conc", "Gasflow_target","status","code"))
  write.table(CALIB_TABELLA, file=CALIB_temp_FILENAME,row.names=F,col.names = F, append = T, quote = F,sep=" ")
}
#
# -------------------------------------------------------------------------------------------
# Listing the METEO Raw data
#
lsfiles                 <-file.info(dir(METEO_RAW_DIR, pattern = glob2rx(paste0("*",METEO_EXT)), full.names = F, ignore.case = TRUE))

lista                   <-data.frame(lsfiles[order(lsfiles$mtime),])
setDT(lista, keep.rownames = T)[]
names(lista)[1]         <-"fileName"
df_lista                <-data.frame(lista[fileName %like% questo_anno])
names(df_lista)[1]      <-"fileName"
df_lista$mydata         <-df_lista
ndata <- NROW(df_lista)
#
# -------------------------------------------------------------------------------------------
# Creating temporary METEO dataset for current year
# 
for(j in df_lista$fileName) {
  
  ULTIMO_DATO           <-paste(METEO_RAW_DIR,j, sep="/")
  ULTIMO_DATO_NAME      <-basename(ULTIMO_DATO)
  METEO_TABELLA         <-read.table(file=ULTIMO_DATO,fill = T, header = METEO_FIELD_NAM, row.names=NULL)
  
  names(METEO_TABELLA)[METEO_DEC_DATE]    <-"start_time"
  names(METEO_TABELLA)[METEO_P]           <-"P"
  names(METEO_TABELLA)[METEO_T]           <-"T"  
  
  if(METEO_T_UNIT == "C") { METEO_TABELLA$T <- METEO_TABELLA$T + 273.15 }
  
  if(METEO_SD_P == 0)     { METEO_TABELLA$SD_P                  <- sd(METEO_TABELLA$P) }
  else                    { names(METEO_TABELLA)[METEO_SD_P]    <-"SD_P" }
  if(METEO_SD_T == 0)     { METEO_TABELLA$SD_T                  <- sd(METEO_TABELLA$T) }
  else                    { names(METEO_TABELLA)[METEO_SD_T]    <-"SD_T" }
  #
  # -------------------------------------------------------------------------------------------
  # Flagging METEO Data
  #
  METEO_TABELLA$t_flag <- 0
  METEO_TABELLA$p_flag <- 0 
  METEO_TABELLA$t_flag[METEO_TABELLA$T     > 313.15]          <- 0.456000000000
  METEO_TABELLA$p_flag[METEO_TABELLA$P     > 900   ]          <- 0.456000000000                                        
  METEO_TABELLA$p_flag[METEO_TABELLA$P     < 700   ]          <- 0.456000000000
  METEO_TABELLA$p_flag[METEO_TABELLA$SD_P  > 1     ]          <- 0.456000000000
  METEO_TABELLA$t_flag[METEO_TABELLA$SD_T  > 2     ]          <- 0.456000000000
  METEO_TABELLA$t_flag[is.na(METEO_TABELLA$T)      ]          <- 9.999000000000
  METEO_TABELLA$T     [is.na(METEO_TABELLA$T)      ]          <- 9999.99  
  METEO_TABELLA$p_flag[is.na(METEO_TABELLA$P)      ]          <- 9.999000000000
  METEO_TABELLA$P     [is.na(METEO_TABELLA$P)      ]          <- 9999.99 
  #
  # -------------------------------------------------------------------------------------------
  #
  METEO_TABELLA$code    <-gsub(" ","",paste("code",format(METEO_TABELLA$start_time,digits=5,nsmall = 5),sep="_"))
  #
  # -------------------------------------------------------------------------------------------
  # writing METEO temporary table
  #
  METEO_TABELLA              <-subset(METEO_TABELLA, select=c("start_time","P","p_flag","T","t_flag", "code"))
  write.table(METEO_TABELLA, file=METEO_temp_FULLFILENAME,row.names=F,col.names = F, append = T, quote = F,sep=" ")
}
# -------------------------------------------------------------------------------------------
# Merging NO and CALIB Data
#
TABELLA                 <-read.table(EBAS_temp_FILENAME)
colnames(TABELLA)       <-c("start_time","end_time","NO","NO2","NOx","Pre","Flow_sample","P_chamb","T_Cooler","T_chamber", "T_internal", "PMT_V","code")
CALIB_TABELLA           <-read.table(CALIB_temp_FILENAME)
colnames(CALIB_TABELLA) <-c("start_time","Gas_conc","Gasflow_target","status","code")
METEO_TABELLA           <-read.table(METEO_temp_FULLFILENAME)
colnames(METEO_TABELLA) <-c("start_time","P","p_flag","T","t_flag", "code")
#
FINAL_temp        <- merge(x = TABELLA[,c("start_time","end_time","NO","NO2","NOx","Pre","Flow_sample","P_chamb","T_Cooler","T_chamber", "T_internal", "PMT_V","code")], 
                           y = CALIB_TABELLA[,c("Gas_conc","Gasflow_target","status","code")], by = "code", all.x = TRUE)

FINAL_temp        <- merge(x = FINAL_temp[,c("start_time","end_time","NO","NO2","NOx","Pre","Flow_sample","P_chamb","T_Cooler","T_chamber", "T_internal", "PMT_V","Gas_conc","Gasflow_target","status","code")], 
                           y = METEO_TABELLA[,c("P","p_flag","T","t_flag", "code")], by = "code", all.x = TRUE)

FINAL_temp        <- FINAL_temp[order(FINAL_temp$start_time),]
FINAL_temp        <- FINAL_temp[,c(-1)]
#
# -------------------------------------------------------------------------------------------
# Calculating Zero / Span coefficients
#
myspanzero              <-subset(FINAL_temp, status == Status_SPAN | status == Status_ZERO)

myspanzero$DATE         <-as.integer(myspanzero$start_time)

cat(  paste("start_time","coeff_NO","bkg_NO","coeff_NOX","bkg_NOX","NO2_L10S",sep=" "),
      file=paste(L0_DIR,"temp_coef_tab.dat",sep = "/"), append=F, sep = "\n")

for (d in unique(as.numeric(myspanzero$DATE)))
{
  myspanzero_d              <-subset(myspanzero, DATE == d)
  
  my_Span                   <-subset(myspanzero_d, myspanzero_d$status == Status_SPAN & Gasflow_target != 0)
  
  my_Zero                   <-subset(myspanzero_d, myspanzero_d$status == Status_ZERO & Gasflow_target != 0)
  
  my_Span_firstminute       <-head(my_Span,1)$start_time
  my_Span_lastminute        <-tail(my_Span,1)$start_time
  
  my_SpanZero_firstminute   <-head(myspanzero_d,1)$start_time 
  my_SpanZero_lastminute    <-tail(myspanzero_d,1)$start_time
  #
  # -------------------------------------------------------------------------------------------
  # Mean of last 10 values before Span
  #
  my_Zero_first10           <-tail(subset(myspanzero_d, status == Status_ZERO & start_time < my_Span_firstminute & Gasflow_target == 0),10)  
  my_Zero_NO_Mean           <-mean(my_Zero_first10$NO)
  my_Zero_NO2_Mean          <-mean(my_Zero_first10$NO2)
  my_Zero_NOX_Mean          <-mean(my_Zero_first10$NOx)
  #
  # -------------------------------------------------------------------------------------------
  # Mean of last 10 values in status Span, before NO falldown
  #
  my_Span$NO_GC             <-as.numeric(my_Span$Gas_conc)-as.numeric(my_Span$NO)
  my_Span_falldown          <-tail(subset(my_Span, my_Span$NO_GC < 0.3*my_Span$Gas_conc),11)
  my_Span_falldown          <-head(my_Span_falldown,10)
  my_Span_falldown_NO_Mean  <-mean(my_Span_falldown$NO)
  my_Span_falldown_NO2_Mean <-mean(my_Span_falldown$NO2)
  my_Span_falldown_NOX_Mean <-mean(my_Span_falldown$NOx)
  my_Span_falldown_GC_Mean  <-mean(my_Span_falldown$Gas_conc)
  #
  # -------------------------------------------------------------------------------------------
  # Mean of last 10 values bin status Span of the series
  # 
  my_Span_last10            <-tail(my_Span,10)
  my_Span_last10_NO_Mean    <-mean(my_Span_last10$NO)
  my_Span_last10_NO2_Mean   <-mean(my_Span_last10$NO2)
  my_Span_last10_NOX_Mean   <-mean(my_Span_last10$NOx)  
  #
  # -------------------------------------------------------------------------------------------
  # Writing Coefficient Table 1
  # 
  my_coef_tab               <-as.data.frame(lapply(my_SpanZero_firstminute,as.numeric))
  #
  my_coef_tab$coeff_NO      <-my_Span_falldown_GC_Mean/my_Span_falldown_NO_Mean
  my_coef_tab$bkg_NO        <-my_Zero_NO_Mean
  my_coef_tab$coeff_NOX     <-my_Span_falldown_GC_Mean/my_Span_falldown_NOX_Mean
  my_coef_tab$coeff_NOX      [my_coef_tab$coeff_NOX < my_coef_tab$coeff_NO] <-my_coef_tab$coeff_NO
  my_coef_tab$bkg_NOX       <-my_Zero_NOX_Mean
  my_coef_tab$NO2_L10S      <-my_Span_last10_NO2_Mean
  # 
  write.table(my_coef_tab, file=paste(L0_DIR,"temp_coef_tab.dat",sep = "/"),row.names=F,col.names = F, append = T, quote = F,sep=" ")  
}
#
# -------------------------------------------------------------------------------------------
# Copying Coefficient values to Data table
#
COEF                        <-read.table(file=paste(L0_DIR,"temp_coef_tab.dat",sep = "/"), header = T,as.is = T, fill = T)
COEF                        <-na.omit(COEF)
#
FINAL_temp$coeff_NO         <-COEF$coeff_NO [1]
FINAL_temp$bkg_NO           <-COEF$bkg_NO   [1]
FINAL_temp$coeff_NOX        <-COEF$coeff_NOX[1]
FINAL_temp$bkg_NOX          <-COEF$bkg_NOX  [1]
#
# -------------------------------------------------------------------------------------------
# Copying Coefficient values to Data table
#
for (c in COEF$start_time[2:nrow(COEF)])
{ 
  FINAL_temp$coeff_NO [as.numeric(FINAL_temp$start_time)  >= as.numeric(c)]   <-COEF$coeff_NO[COEF$start_time   == c]
  FINAL_temp$bkg_NO   [as.numeric(FINAL_temp$start_time)  >= as.numeric(c)]   <-COEF$bkg_NO[COEF$start_time     == c]
  FINAL_temp$coeff_NOX[as.numeric(FINAL_temp$start_time)  >= as.numeric(c)]   <-COEF$coeff_NOX[COEF$start_time  == c]
  FINAL_temp$bkg_NOX  [as.numeric(FINAL_temp$start_time)  >= as.numeric(c)]   <-COEF$bkg_NOX[COEF$start_time    == c]
}
#
# -------------------------------------------------------------------------------------------
# Correction of NO, NO2, NOx values using coeffincient values
#
FINAL_temp$NO_elab1         <-as.numeric(FINAL_temp$NO)  * as.numeric(FINAL_temp$coeff_NO)  - as.numeric(FINAL_temp$bkg_NO)
FINAL_temp$NOX_elab1        <-as.numeric(FINAL_temp$NOx) * as.numeric(FINAL_temp$coeff_NOX) - as.numeric(FINAL_temp$bkg_NOX)
FINAL_temp$NO2_elab1        <-as.numeric(FINAL_temp$NOX_elab1) - as.numeric(FINAL_temp$NO_elab1)
#
# -------------------------------------------------------------------------------------------
# Calculating SC
#
cat(  paste("start_time","NO2_elab1_gpt","NO_elab1_span","NO_elab1_gpt","NO2_elab1_span","NO_elab1_zero","Sc",sep=" "),
      file=paste(L0_DIR,"temp_coef_tab_2.dat",sep = "/"), append=F, sep = "\n")

ELAB1_myspanzero                  <-subset(FINAL_temp, status == Status_SPAN | status == Status_ZERO)
ELAB1_myspanzero$DATE             <-as.integer(ELAB1_myspanzero$start_time)
#
for (d in unique(as.numeric(ELAB1_myspanzero$DATE)))
{
  myspanzero_d                    <-subset(ELAB1_myspanzero, DATE == d)
  
  my_Span                         <-subset(myspanzero_d, myspanzero_d$status == Status_SPAN & Gasflow_target != 0)
  my_Zero                         <-subset(myspanzero_d, myspanzero_d$status == Status_ZERO & Gasflow_target != 0)
  
  my_Span_firstminute             <-head(my_Span,1)$start_time 
  my_Span_lastminute              <-tail(my_Span,1)$start_time
  
  my_SpanZero_firstminute         <-head(myspanzero_d,1)$start_time 
  my_SpanZero_lastminute          <-tail(myspanzero_d,1)$start_time
  #
  # -------------------------------------------------------------------------------------------
  # Mean of last 10 Zero values before Span
  #    
  my_Zero_first10                 <-tail(subset(myspanzero_d, status == Status_ZERO & start_time < my_Span_firstminute & Gasflow_target == 0),10)  
  my_Zero_NO_elab1_Mean           <-mean(my_Zero_first10$NO_elab1)
  #
  # -------------------------------------------------------------------------------------------
  # Mean of last 10 values in status Span, before NO falldown
  #   
  my_Span$NO_GC                   <-as.numeric(my_Span$Gas_conc)-as.numeric(my_Span$NO)
  my_Span_falldown                <-tail(subset(my_Span, my_Span$NO_GC < 0.3*my_Span$Gas_conc),11)
  my_Span_falldown                <-head(my_Span_falldown,10)
  my_Span_falldown_NO_elab1_Mean  <-mean(my_Span_falldown$NO_elab1)
  my_Span_falldown_NO2_elab1_Mean <-mean(my_Span_falldown$NO2_elab1)
  #
  # -------------------------------------------------------------------------------------------
  # Mean of last 10 values bin status Span of the series
  # 
  my_Span_last10_pre              <-tail(my_Span,11)
  my_Span_last10                  <-head(my_Span_last10_pre,10)
  my_Span_last10_NO2_Mean         <-mean(my_Span_last10$NO2_elab1)
  my_Span_last10_NO_elab1_Mean    <-mean(my_Span_last10$NO_elab1)
  my_Span_last10_NOX_el1_Mean     <-mean(my_Span_last10$NOX_elab1)  
  #
  # -------------------------------------------------------------------------------------------
  # Copying Coefficient values to Data table
  #
  my_coef_tab_2                   <-as.data.frame(my_SpanZero_firstminute,row.names=NULL,stringsAsFactors = FALSE)
  
  my_coef_tab_2$my_Span_last10_NO2_Mean <-format(round(my_Span_last10_NO2_Mean          , 8),nsmall = 8,    scientific=FALSE)
  my_coef_tab_2$falldw_NO_elab1   <-format(round(my_Span_falldown_NO_elab1_Mean   , 8),nsmall = 8,    scientific=FALSE)
  my_coef_tab_2$last10_NO_elab1   <-format(round(my_Span_last10_NO_elab1_Mean     , 8),nsmall = 8,    scientific=FALSE)
  my_coef_tab_2$NO2_elab1_span    <-format(round(as.numeric(my_Span_falldown_NO2_elab1_Mean)  , 8),nsmall = 8,    scientific=FALSE)
  my_coef_tab_2$NO_elab1_zero     <-format(round(as.numeric(my_Zero_NO_elab1_Mean), 8),nsmall = 8,    scientific=FALSE)
  my_coef_tab_2$Sc                <-(my_Span_last10_NO2_Mean)/((my_Span_falldown_NO_elab1_Mean) - (my_Span_last10_NO_elab1_Mean))
  #
  # -------------------------------------------------------------------------------------------
  # Setting the proper output format
  #
  my_coef_tab_2                   <-as.data.frame(lapply(na.omit(my_coef_tab_2),as.numeric))
  my_coef_tab_2                   <-subset(my_coef_tab_2, my_coef_tab_2$Sc < 1)
  
  write.table(my_coef_tab_2, file=paste(L0_DIR,"temp_coef_tab_2.dat",sep = "/"),row.names=F,col.names = F, append = T, quote = F,sep=" ")  
}

COEF_1                            <-read.table(file=paste(L0_DIR,"temp_coef_tab_2.dat",sep = "/"), header = T,as.is = T, fill = T)
FINAL_temp$Sc                     <-COEF_1$Sc[1]

for (c in COEF_1$start_time[2:nrow(COEF_1)])
{ 
  FINAL_temp$Sc[as.numeric(FINAL_temp$start_time)  >= as.numeric(c)]   <-COEF_1$Sc[COEF_1$start_time  == c]
}

FINAL_temp$NO2_elab2              <-as.numeric(FINAL_temp$NO2_elab1) / FINAL_temp$Sc
FINAL_temp$NOX_elab2              <-FINAL_temp$NO_elab1 + FINAL_temp$NO2_elab2
#
# -------------------------------------------------------------------------------------------
# Calculating the final NO value
#
cat(  paste("start_time","NO2_elab2_span","NOX_elab2_span","NOX_elab2_gpt","NO2_elab2_zero",sep=" "),
      file=paste(L0_DIR,"temp_coef_tab_3.dat",sep = "/"), append=F, sep = "\n")

ELAB2_myspanzero                  <-subset(FINAL_temp, status == Status_SPAN | status == Status_ZERO)
ELAB2_myspanzero$DATE             <-as.integer(ELAB2_myspanzero$start_time)

for (d in unique(as.numeric(ELAB2_myspanzero$DATE))){
  myspanzero_d                    <-subset(ELAB2_myspanzero, DATE == d)
  
  my_Span                         <-subset(myspanzero_d, myspanzero_d$status == Status_SPAN & Gasflow_target != 0)
  my_Zero                         <-subset(myspanzero_d, myspanzero_d$status == Status_ZERO & Gasflow_target != 0)
  
  my_Span_firstminute             <-head(my_Span,1)$start_time
  my_Span_lastminute              <-tail(my_Span,1)$start_time
  
  my_SpanZero_firstminute         <-head(myspanzero_d,1)$start_time 
  my_SpanZero_lastminute          <-tail(myspanzero_d,1)$start_time
  #
  # -------------------------------------------------------------------------------------------
  # Mean of last 10 Zero values before Span
  #     
  my_Zero_first10                 <-tail(subset(myspanzero_d, status == Status_ZERO & start_time < my_Span_firstminute & Gasflow_target == 0),10) 
  my_Zero_NO2_elab2_Mean          <-mean(my_Zero_first10$NO2_elab2)
  #
  # -------------------------------------------------------------------------------------------
  # Mean of last 10 values in status Span, before NO falldown
  #     
  my_Span$NO_GC                   <-as.numeric(my_Span$Gas_conc)-as.numeric(my_Span$NO)
  my_Span_falldown                <-tail(subset(my_Span, my_Span$NO_GC < 0.3*my_Span$Gas_conc),11)
  my_Span_falldown                <-head(my_Span_falldown,10)
  
  my_NO2_elab2_span               <-mean(my_Span_falldown$NO2_elab2)
  my_NOX_elab2_span               <-mean(my_Span_falldown$NOX_elab2)
  #
  # -------------------------------------------------------------------------------------------
  # Mean of last 10 values bin status Span of the series
  #  
  my_Span_last10_pre              <-tail(my_Span,11)
  my_Span_last10                  <-head(my_Span_last10_pre,10)
  
  my_NO2_elab2_gpt                <-mean(my_Span_last10$NO2_elab2)
  my_NOX_elab2_gpt                <-mean(my_Span_last10$NOX_elab2)  
  
  my_coef_tab_3                   <-as.data.frame(my_SpanZero_firstminute)
  
  my_coef_tab_3$NO2_elab2_span    <-format(round(as.numeric(my_NO2_elab2_span)     , 8),nsmall = 8,    scientific=FALSE)  
  my_coef_tab_3$NOX_elab2_span    <-format(round(as.numeric(my_NOX_elab2_span)     , 8),nsmall = 8,    scientific=FALSE)
  my_coef_tab_3$NOX_elab2_gpt     <-format(round(as.numeric(my_NOX_elab2_gpt)      , 8),nsmall = 8,    scientific=FALSE)
  my_coef_tab_3$NO2_elab2_zero    <-format(round(as.numeric(my_Zero_NO2_elab2_Mean), 8),nsmall = 8,    scientific=FALSE)   
  
  write.table(my_coef_tab_3, file=paste(L0_DIR,"temp_coef_tab_3.dat",sep = "/"),row.names=F,col.names = F, append = T, quote = F,sep=" ")  
}

COEF_2                            <-read.table(file=paste(L0_DIR,"temp_coef_tab_3.dat",sep = "/"), header = T,as.is = T, fill = T)
#
FINAL_temp$NO2_elab2_span         <-COEF_2$NO2_elab2_span[1]
FINAL_temp$NOX_elab2_span         <-COEF_2$NOX_elab2_span[1]
FINAL_temp$NOX_elab2_gpt          <-COEF_2$NOX_elab2_gpt [1]
FINAL_temp$NO2_elab2_zero         <-COEF_2$NO2_elab2_zero[1]
#
# -------------------------------------------------------------------------------------------
# Copying Coefficient values to Data table
#
for (c in COEF_2$start_time[2:nrow(COEF_2)])
{ 
  FINAL_temp$NO2_elab2_span [as.numeric(FINAL_temp$start_time)  >= as.numeric(c)]   <-COEF_2$NO2_elab2_span [COEF_2$start_time  == c]
  FINAL_temp$NOX_elab2_span [as.numeric(FINAL_temp$start_time)  >= as.numeric(c)]   <-COEF_2$NOX_elab2_span [COEF_2$start_time  == c]
  FINAL_temp$NOX_elab2_gpt  [as.numeric(FINAL_temp$start_time)  >= as.numeric(c)]   <-COEF_2$NOX_elab2_gpt  [COEF_2$start_time  == c]
  FINAL_temp$NO2_elab2_zero [as.numeric(FINAL_temp$start_time)  >= as.numeric(c)]   <-COEF_2$NO2_elab2_zero [COEF_2$start_time  == c]
}
#
write.table(FINAL_temp, file=FINAL_temp_FULLFILENAME,row.names=F,col.names = T, append = F, quote = F,sep=" ")
#
# -------------------------------------------------------------------------------------------
# Creating final check table
#
MY_COEF                           <- merge(x = COEF, 
                                           y = COEF_1,  
                                           by = "start_time", all.x = TRUE)
MY_FINAL_COEF                     <-merge(x = MY_COEF, 
                                          y = COEF_2,  
                                          by = "start_time", all.x = TRUE) 

jd                                <-as.integer(MY_FINAL_COEF$start_time)
day                               <-as.Date(MY_FINAL_COEF$start_time, origin=questa_start_time)
time.dec                          <-MY_FINAL_COEF$start_time-jd
time                              <-time.dec*1440+0.01
hour                              <-as.integer(time/60)
min                               <-as.integer(time-hour*60)
date                              <-paste(day," ",hour,":",min,":00",sep="")
MY_FINAL_COEF$date                <-as.POSIXct(strptime(date, format = "%Y-%m-%d %H:%M:%S", tz = "GMT"))

MY_FINAL_COEF                     <-subset(na.omit(MY_FINAL_COEF), select=c("date",
                                                                            "start_time",
                                                                            "coeff_NO"	,
                                                                            "bkg_NO",	
                                                                            "coeff_NOX",	
                                                                            "bkg_NOX",	
                                                                            "NO2_L10S",	
                                                                            "NO2_elab1_gpt",	
                                                                            "NO_elab1_span",	
                                                                            "NO_elab1_gpt",	
                                                                            "NO2_elab1_span",	
                                                                            "NO_elab1_zero",	
                                                                            "Sc",	
                                                                            "NO2_elab2_span",	
                                                                            "NOX_elab2_span",	
                                                                            "NOX_elab2_gpt",	
                                                                            "NO2_elab2_zero"))

MY_FINAL_COEF$NO2_elab1_gpt[MY_FINAL_COEF$coeff_NO == MY_FINAL_COEF$coeff_NOx] <-as.numeric(MY_FINAL_COEF$NO2_elab1_gpt) - as.numeric(MY_FINAL_COEF$NO2_elab1_span)        # correzione 19 02 2018
write.table(MY_FINAL_COEF, file=paste(L0_ANCIL_DIR,paste("NOx_CHECK_TABLE_",questo_anno,".dat",sep=""),sep = "/"),row.names=F,col.names = T, append = F, quote = F,sep=" ")
#
# -------------------------------------------------------------------------------------------
# Flagging Data set
#
TABELLA                       <- FINAL_temp[with(FINAL_temp, order(as.numeric(start_time))), ]
TABELLA$NO_inst               <- as.numeric(TABELLA$NO)
TABELLA$NO                    <- as.numeric(TABELLA$NO_elab1)
TABELLA$NO2_inst              <- as.numeric(TABELLA$NO2)
TABELLA$NO2                   <- as.numeric(TABELLA$NO2_elab2)

TABELLA$NO_flag               <-0
TABELLA$NO2_flag              <-0
#
# -------------------------------------------------------------------------------------------
# Calculating difference with following values

NO_diff                       <-diff(TABELLA$NO)
n                             <-length(TABELLA$NO)
NO_diff[n]                    <-0
NO_diff[is.na(NO_diff)]       <- -999

NO2_diff                      <-diff(TABELLA$NO2)
n                             <-length(TABELLA$NO2)
NO2_diff[n]                   <-0
NO2_diff[is.na(NO2_diff)]     <- -999
TABELLA$NO_diff               <-NO_diff
TABELLA$NO2_diff              <-NO2_diff


TABELLA$Flow_sample [is.na(TABELLA$Flow_sample)]    <- -999
TABELLA$Sc          [is.na(TABELLA$Sc)         ]    <- -999
TABELLA$NO          [is.na(TABELLA$NO)         ]    <- -999
TABELLA$NO2         [is.na(TABELLA$NO2)        ]    <- -999
#
# -------------------------------------------------------------------------------------------
# Checking of internal diagnostic parameters
#
for (i in 1:(nrow(TABELLA)-1)){
  if (TABELLA$status[i] %in% Status_STBY)
  {
    if (TABELLA$Flow_sample[i]  < 0.5)        
    {TABELLA$NO_flag [i+1]      <- 0.664000000;
    TABELLA$NO2_flag[i+1]       <- 0.664000000}
    
    if (as.numeric(TABELLA$T_Cooler[i]) > 10)
    {TABELLA$NO_flag [i+1]      <- 0.664000000;
    TABELLA$NO2_flag[i+1]       <- 0.664000000}
    
    if (as.numeric(TABELLA$P_chamb[i]) > 400)
    {TABELLA$NO_flag [i+1]      <- 0.664000000;
    TABELLA$NO2_flag[i+1]       <- 0.664000000}
    #
    # -------------------------------------------------------------------------------------------
    # Checking for high data variability
    # 
    if (TABELLA$NO_diff[i]      >  0.5)     {TABELLA$NO_flag[i+1]    <- 0.456000000}
    if (TABELLA$NO_diff[i]      < (-0.5))   {TABELLA$NO_flag[i+1]    <- 0.456000000}
    
    if (TABELLA$NO2_diff[i]     >  0.5)     {TABELLA$NO2_flag[i+1]   <- 0.456000000}
    if (TABELLA$NO2_diff[i]     < (-0.5))   {TABELLA$NO2_flag[i+1]   <- 0.456000000}
    #
    # -------------------------------------------------------------------------------------------
    # Checking for detection limit
    # 
    if (TABELLA$NO[i]           <  0.05)    {TABELLA$NO_flag[i]       <- 0.147000000}
    if (TABELLA$NO2[i]          <  0.10)    {TABELLA$NO2_flag[i]      <- 0.147000000}
    #
    # -------------------------------------------------------------------------------------------
    # Checking for anomalous negative values (lowered the threshold)
    # 
    if (TABELLA$NO[i]           < (-0.20))  {TABELLA$NO_flag[i]      <- 0.459000000}
    if (TABELLA$NO2[i]          < (-0.20))  {TABELLA$NO2_flag[i]     <- 0.459000000}
    #
    # -------------------------------------------------------------------------------------------
    # Checking for wrong Sc
    #
    if (TABELLA$Sc[i]           <  0.1)    
    {TABELLA$NO_flag[i]         <- 0.456000000;    
    TABELLA$NO2_flag[i]         <- 0.456000000}
    #
    # -------------------------------------------------------------------------------------------
    # Checking for missing data 
    #     
    if (TABELLA$NO[i]           < -900)    {TABELLA$NO_elab1[i]     <- 999.99;    TABELLA$NO_flag[i]      <- 0.999000000}
    if (TABELLA$NO2[i]          < -900)    {TABELLA$NO2_elab2[i]    <- 999.99;    TABELLA$NO2_flag[i]     <- 0.999000000}
  }
  #
  # -------------------------------------------------------------------------------------------
  # Flagging calibration values 
  #     
  if (TABELLA$status[i] %in% Status_SPAN) 
  {
    TABELLA$NO2_flag[i-1]       <- 0.682000000
    TABELLA$NO2_flag[i]         <- 0.682000000;
    TABELLA$NO2_flag[i+1]       <- 0.682000000;
    TABELLA$NO_flag [i-1]       <- 0.682000000;      
    TABELLA$NO_flag [i]         <- 0.682000000;
    TABELLA$NO_flag [i+1]       <- 0.682000000;
  }
  
  if (TABELLA$status[i] %in% Status_ZERO)
  {
    TABELLA$NO2_flag[i-1]       <- 0.682000000
    TABELLA$NO2_flag[i]         <- 0.682000000;
    TABELLA$NO2_flag[i+1]       <- 0.682000000;
    TABELLA$NO_flag [i-1]       <- 0.682000000;      
    TABELLA$NO_flag [i]         <- 0.682000000;
    TABELLA$NO_flag [i+1]       <- 0.682000000;
  }
  #
  # -------------------------------------------------------------------------------------------
  # Flagging manual calibration values 
  # 
  if (TABELLA$NO[i] > 20)
  {
    TABELLA$NO2_flag[i-1]       <- 0.682000000
    TABELLA$NO2_flag[i]         <- 0.682000000;
    TABELLA$NO2_flag[i+1]       <- 0.682000000;
    TABELLA$NO_flag [i-1]       <- 0.682000000;      
    TABELLA$NO_flag [i]         <- 0.682000000;
    TABELLA$NO_flag [i+1]       <- 0.682000000;
  }
}
#
# -------------------------------------------------------------------------------------------
# Flagging calibration values when adjuster is off
# 
for (i in 1:nrow(TABELLA)){                                                                         
  if (TABELLA$NO[i] <  (-900)) {TABELLA$NO_elab1[i]   <- 999.99;        TABELLA$NO_flag[i]    <- 0.999000000}  
  if (TABELLA$NO2[i]<  (-900)) {TABELLA$NO2_elab2[i]  <- 999.99;        TABELLA$NO2_flag[i]   <- 0.999000000}  
  if (TABELLA$NO[i] >      20) {TABELLA$NO_flag[i]    <- 0.682000000;   TABELLA$NO2_flag[i]   <- 0.682000000} 
}
#
# -------------------------------------------------------------------------------------------
# Setting data format
# 
TABELLA$start_time            <-format(round(TABELLA$start_time, 8)  , nsmall = 8, scientific=FALSE)
TABELLA$end_time              <-format(round(TABELLA$end_time  , 8)  , nsmall = 8, scientific=FALSE)
TABELLA$NO                    <-format(round(TABELLA$NO        , 8)  , nsmall = 8, scientific=FALSE)
TABELLA$NO2                   <-format(round(TABELLA$NO2       , 8)  , nsmall = 8, scientific=FALSE)
TABELLA$NOx                   <-format(round(TABELLA$NOx       , 8)  , nsmall = 8, scientific=FALSE)
TABELLA$Pre                   <-format(round(TABELLA$Pre       , 8)  , nsmall = 8, scientific=FALSE)
#
TABELLA[1:6]                  <-lapply(TABELLA[1:6], as.numeric) 
#
write.table(TABELLA, file=paste(L0_ANCIL_DIR,paste("NOx_PARAM_TABLE_",questo_anno,".dat",sep=""),sep = "/"),row.names=F,col.names = T, append = F, quote = F,sep=" ")
#
# -------------------------------------------------------------------------------------------
# Removing possible duplicates
TABELLA <- TABELLA[!duplicated(TABELLA[1]),] # Check in code
# -------------------------------------------------------------------------------------------
# Writing the final Data set
#
MYEBAS                <-subset(TABELLA,select=c("start_time"), stringsAsFactors = FALSE)
#
# -------------------------------------------------------------------------------------------
# Defining fields for EBAS Level-0 Data set
#
MYEBAS$end_time       <-TABELLA$end_time
MYEBAS$NO             <-TABELLA$NO_elab1
MYEBAS$numflag_NO     <-TABELLA$NO_flag
MYEBAS$NO2            <-TABELLA$NO2_elab2
MYEBAS$numflag_NO2    <-TABELLA$NO2_flag
MYEBAS$converter_eff  <-TABELLA$Sc
MYEBAS$T              <-TABELLA$T 
MYEBAS$t_flag         <-TABELLA$t_flag
MYEBAS$P              <-TABELLA$P 
MYEBAS$p_flag         <-TABELLA$p_flag 

MYEBAS$NO             [is.na(MYEBAS$NO)     ]     <- 999.999
MYEBAS$NO2            [is.na(MYEBAS$NO2)    ]     <- 999.999
MYEBAS$numflag_NO2    [MYEBAS$NO2 == 999.999]     <- 0.456000000
MYEBAS$numflag_NO     [MYEBAS$NO  == 999.999]     <- 0.456000000
#
# -------------------------------------------------------------------------------------------
# Setting digits for EBAS Level-0 Data set
#
MYEBAS$start_time     <-format(round(MYEBAS$start_time, 8)  , nsmall = 8, scientific=FALSE)
MYEBAS$end_time       <-format(round(MYEBAS$end_time, 8)    , nsmall = 8, scientific=FALSE)
MYEBAS$NO             <-format(round(MYEBAS$NO, 3)          , nsmall = 3, scientific=FALSE)
MYEBAS$numflag_NO     <-format(round(MYEBAS$numflag_NO,9)   , nsmall = 9, scientific=FALSE)
MYEBAS$NO2            <-format(round(MYEBAS$NO2,3)          , nsmall = 3, scientific=FALSE)
MYEBAS$numflag_NO2    <-format(round(MYEBAS$numflag_NO2,9)  , nsmall = 9, scientific=FALSE)
MYEBAS$converter_eff  <-format(round(MYEBAS$converter_eff,2), nsmall = 2, scientific=FALSE)
MYEBAS$T              <-format(round(as.numeric(MYEBAS$T),2), nsmall = 2, scientific=FALSE)
MYEBAS$t_flag         <-format(round(MYEBAS$t_flag,9)       , nsmall = 9, scientific=FALSE)
MYEBAS$P              <-format(round(as.numeric(MYEBAS$P),2), nsmall = 2, scientific=FALSE)
MYEBAS$p_flag         <-format(round(MYEBAS$p_flag,9)       , nsmall = 9, scientific=FALSE)
#
write.table(MYEBAS, file=EBAS_L0_FULLFILENAME,row.names=F,col.names = F, append = T, quote = F,sep=" ") 
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

REPORTAB            <-read.table(file=paste(L0_ANCIL_DIR,paste("NOx_PARAM_TABLE_",questo_anno,".dat",sep=""),sep = "/") , header = T,as.is = T,sep=" ") 
REPORTAB            <-subset(REPORTAB, NO_flag < 0.6 | NO2_flag < 0.6)
REPORTAB            <-REPORTAB[, c("start_time",
                                   "NO_inst",
                                   "NO_elab1",
                                   "NO2_inst",
                                   "NO2_elab2",
                                   "Pre",
                                   "T_internal",
                                   "T_chamber",
                                   "T_Cooler",
                                   "PMT_V",
                                   "P_chamb",
                                   "Flow_sample"
                                   )]

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
    timePlot(THISREPORTTAB,pollutant=c("NO_inst",
                                       "NO_elab1",
                                       "NO2_inst",
                                       "NO2_elab2",
                                       "Pre",
                                       "T_internal",
                                       "T_chamber",
                                       "T_Cooler",
                                       "PMT_V",
                                       "P_chamb",
                                       "Flow_sample"
                                       ),
             cex=25,date.breaks=15, y.relation="free", key = FALSE, fontsize = 14)
    dev.off()
  }
}

##                                          # END PART 3.0 #
###########################################################################################################################
#                                                                                                                         #
## End of NOx_P20_1810.R                                                                                                  # 
#                                                                                                                         # 
###################################################################################### Authors: L u C A, Davide ###########

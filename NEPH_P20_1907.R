###########################################################################################################################
## Project: NEXTDATA                                                                                                     ##
## Parameter: NEPH                                                                                                       ##
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
## Script filename: NEPH_P20_1810.R                                                                                      ##
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
CALIB_DIR       = '../naitza/NEXTDATA/PROD/CIMONE/AEROSOL/NEPH/RAW_DATA_UTC/CALIB'           
RAW_DIR         = '../naitza/NEXTDATA/PROD/CIMONE/AEROSOL/NEPH/RAW_DATA_UTC'
#
# -------- DATA DESTINATION PATH --------------------------------------------------------------# REPLACE THE FOLLOWING PATHS
L0_DIR          = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/AEROSOL/NEPH/LEVEL_0'                     
L1_DIR          = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/AEROSOL/NEPH/LEVEL_1' 
L2_DIR          = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/AEROSOL/NEPH/LEVEL_2'
L0_ANCIL_DIR    = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/AEROSOL/NEPH/LEVEL_0/ANCILLARY'
#
# -------- GRAPH DESTINATION PATH -------------------------------------------------------------# REPLACE THE FOLLOWING PATHS
REP_DIR         = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/AEROSOL/NEPH/REPORT'
REP_GRAPH_DIR   = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/AEROSOL/NEPH/REPORT/DAILY_GRAPH'
PLOT_DIR_M      = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/AEROSOL/NEPH/REPORT/MONTHLY_GRAPH'
PLOT_DIR_S      = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/AEROSOL/NEPH/REPORT/SEASONAL_GRAPH'
PLOT_DIR_Y      = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/AEROSOL/NEPH/REPORT/ANNUAL_GRAPH'
PLOT_DIR_Y_PDF  = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/AEROSOL/NEPH/REPORT/ANNUAL_GRAPH/PDF'
PLOT_DIR_T      = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/AEROSOL/NEPH/REPORT/TIMEVARIATION_GRAPH' 
#
# -------- DAILY GRAPH PREFIX & SUFFIX -------------------------------------------------------# REPLACE THE FOLLOWING VALUES
DAILY_PREFIX    <-"CMN_NEPH"     # choose a prefix for your daily graph (e.g. StationCodeName_ParameterCodeName)
DAILY_SUFFIX    <-"01M"          # choose a suffix for your daily graph (e.g. AcquisitionTiming)
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
##                                         Setting NEPH Data
## ______________________________________________________________________________________________________________________##
## USE: set the following values of NEPH dataset
## WARNING: NEPH raw data should be recorded according to the following specifications:
##          FILENAME: the filename should contain the acquisition date (YYYYMMDD). E.g.: CMN_METEO_20181215_01M.dat;
#
# -------- NEPH RAW DATASET EXTENSION ----------------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
NEPH_EXT         <-".dat"      # if different, replace ".dat" with the extesion of your NEPH Raw Data set
#
# -------- NEPH RAW DATA FIELD SEPARATOR -------------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
NEPH_FIELD_SEP   <-" "         # if different, replace " "    with the field separator of your NEPH Raw Data set (e.g. "," or "\t")
#
# -------- NEPH RAW DATA HEADER ----------------------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
NEPH_FIELD_NAM   <- T          # if different, replace T      with F if NEPH Row Data tables do not have the header (field names)
#
# -------- NEPH FIELD POSITION IN THE TABLE -----------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
NEPH_DEC_DATE       <- 6          # if different, replace with the field position of start_time (julian date) field in your NEPH Raw Data set
NEPH_Status         <- 7          # if different, replace with the field position of status field in your NEPH Raw Data set
NEPH_p_int          <- 16         # if different, replace with the field position of pressure inlet field in your NEPH Raw Data set
NEPH_T_int          <- 18         # if different, replace with the field position of temperature inlet field in your NEPH Raw Data set
NEPH_T_out          <- 17         # if different, replace with the field position of temperature outlet field in your NEPH Raw Data set
NEPH_RH_int         <- 19         # if different, replace with the field position of RH inlet field in your NEPH Raw Data set
NEPH_RH_out         <- 0          # if different, replace with the field position of RH outlet field in your NEPH Raw Data set
NEPH_flow           <- 0          # if different, replace with the field position of flow field in your NEPH Raw Data set
NEPH_lamp_v         <- 20         # if different, replace with the field position of lamp_v field in your NEPH Raw Data set
NEPH_lamp_c         <- 21         # if different, replace with the field position of lamp_c field in your NEPH Raw Data set
NEPH_flags          <- 23         # if different, replace with the field position of flags field in your NEPH Raw Data set
NEPH_sc450          <- 9          # if different, replace with the field position of sc450 field in your NEPH Raw Data set
NEPH_sc550          <- 10         # if different, replace with the field position of sc550 field in your NEPH Raw Data set
NEPH_sc700          <- 11         # if different, replace with the field position of sc700 field in your NEPH Raw Data set
NEPH_bsc450         <- 12         # if different, replace with the field position of bsc450 field in your NEPH Raw Data set
NEPH_bsc550         <- 13         # if different, replace with the field position of bsc550 field in your NEPH Raw Data set
NEPH_bsc700         <- 14         # if different, replace with the field position of bsc700 field in your NEPH Raw Data set
NEPH_sc450z         <- 24         # if different, replace with the field position of sc450z field in your NEPH Raw Data set
NEPH_sc550z         <- 25         # if different, replace with the field position of sc550z field in your NEPH Raw Data set
NEPH_sc700z         <- 26         # if different, replace with the field position of sc700z field in your NEPH Raw Data set
NEPH_bsc450z        <- 27         # if different, replace with the field position of bsc450z field in your NEPH Raw Data set
NEPH_bsc550z        <- 28         # if different, replace with the field position of bsc550z field in your NEPH Raw Data set
NEPH_bsc700z        <- 29         # if different, replace with the field position of bsc700z field in your NEPH Raw Data set
NEPH_sc450r         <- 30         # if different, replace with the field position of sc450r field in your NEPH Raw Data set
NEPH_sc550r         <- 31         # if different, replace with the field position of sc550r field in your NEPH Raw Data set
NEPH_sc700r         <- 32         # if different, replace with the field position of sc700r field in your NEPH Raw Data set
#
# -------------------------------------------------------------------------------------------

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

inst_type               <- "nephelometer"                                    # replace the value with your instrument type
inst_manu               <- "TSI"                                             # replace the value with your instrument manufacter
inst_modl               <- "3563"                                            # replace the value with your instrument model
inst_name               <- "TSI_3563_3563133901"                             # replace the value with your your instrument name
inst_s_n                <- "3563133901"                                      # replace the value with your instrument serial number
meth_ref                <- "IT06L_neph_control_lev0_0_0_1"                   # replace the value with method reference

dependent_col           <- "26"                                              # replace the value with the total number of columns of the file in addition to start_time (i.e., total-1)

component               <- "aerosol_light_scattering_coefficient"            # replace the value with proper component 
matrix                  <- "aerosol"                                         # replace the value with proper matrix
meas_unit               <- "1/Mm"                                            # replace the value with proper measurement unit

meas_lat                <- "44.16667"                                        # replace the value with the your Measure latitude
meas_lon                <- "10.68333"                                        # replace the value with the your Measure longitude
meas_alt                <- "2165m"                                           # replace the value with the your Measure altitude (meters)

Period_code             <- "1y"                                              # replace the value with the proper Period code
Resolution_code         <- "1mn"                                             # replace the value with the proper Resolution code
Sample_duration         <- "1mn"                                             # replace the value with the proper Sample duration
Orig_time_res           <- "1mn"                                             # replace the value with the proper Original time resolution

height_AGL              <- "10m"                                             # replace the value with Height AGL
inlet_type              <- "Hat or hood"                                     # replace the value with Inlet type
inlet_desc              <- "Total particle size at ambient humidity inlet,  heated head, home made followinfg EUSAAR design, flow 150 l/min"    # replace the value with Inlet description
hum_temp_c              <- "heating"                                         # replace the value with Humidity/temperature control
hum_temp_c_desc         <- "passive, sample heated from atmospheric to lab temperature"        # replace the value with Humidity/temperature control description
vol_std_t               <- "ambient"                                         # replace the value with Volume std. temperature
vol_std_p               <- "ambient"                                         # replace the value with Volume std. pressure
detec_lim               <- "0.3 1/Mm"                                        # replace the value with Detection limit
detec_lim_ex            <- "Determined by instrument counting statistics, no detection limit flag used"      # replace the value with Detection limit expl.
meas_uncr               <- "0.5 1/Mm"                                        # replace the value with Measurement uncertainty
meas_uncr_ex            <- "average value taken from Anderson et al. 1996 for statistical and calibration uncertainty"       # replace the value with Measurement uncertainty expl.
zero_val_code           <- "Zero/negative possible"                          # replace the value with Zero/negative values code
zero_val                <- "Zero and neg. values may appear due to statistical variations at very low concentrations"  # replace the value with Zero/negative values
std_meth                <- "cal-gas=CO2+AIR_truncation-correction=none"      # replace the value with Standard method
qa_mes_id               <- "not available"                                   # replace the value with QA measure ID
qa_date                 <- "not available"                                   # replace the value with QA date
qa_doc                  <- "not available"                                   # replace the value with QA document URL

# The following variabiles concern the originator and the submitter names, surnames, emails and addresses
# NOTE: Please, change these variables with proper names, surnames, emails and addresses
# 
# -------- ORIGINATORS (set min 1 originator, max 5) ---------------------------------------------------------------# REPLACE THE FOLLOWING VALUES
Origin_1_n              <- "Angela"      
Origin_1_s              <- "Marinoni"
Origin_1_e              <- "a.marinoni@isac.cnr.it"
Origin_1_i              <- "Institute of Atmospheric Sciences and Climate, ISAC,, Via P. Gobetti 101,, I-40129, Bologna, Italy"

Origin_2_n              <- "Davide"      
Origin_2_s              <- "Putero"
Origin_2_e              <- "d.putero@isac.cnr.it"
Origin_2_i              <- "Institute of Atmospheric Sciences and Climate, ISAC,, Via P. Gobetti 101,, I-40129, Bologna, Italy"

Origin_3_n              <- "Luca"      
Origin_3_s              <- "Naitza"
Origin_3_e              <- "l.naitza@isac.cnr.it"
Origin_3_i              <- "Institute of Atmospheric Sciences and Climate, ISAC,, Via P. Gobetti 101,, I-40129, Bologna, Italy"

Origin_4_n              <- ""      
Origin_4_s              <- ""
Origin_4_e              <- ""
Origin_4_i              <- ""

Origin_5_n              <- ""      
Origin_5_s              <- ""
Origin_5_e              <- ""
Origin_5_i              <- ""

# -------- SUBMITTER (set the submitter) --------------------------------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
Submit_1_n              <- "Angela"      
Submit_1_s              <- "Marinoni"
Submit_1_e              <- "a.marinoni@isac.cnr.it"
Submit_1_i              <- "Institute of Atmospheric Sciences and Climate, ISAC,, Via P. Gobetti 101,, I-40129, Bologna, Italy"

mycomment               <- "calibration, but no truncation correction applied"
#
# Setting the lines of the header
#
if (nchar(Origin_2_n) == 0 && nchar(Origin_3_n) == 0 && nchar(Origin_4_n) == 0 && nchar(Origin_5_n) == 0)  { L0_n_lines <- 101 + 0 }
if (nchar(Origin_2_n)  > 0 && nchar(Origin_3_n) == 0 && nchar(Origin_4_n) == 0 && nchar(Origin_5_n) == 0)  { L0_n_lines <- 101 + 1 }
if (nchar(Origin_2_n)  > 0 && nchar(Origin_3_n)  > 0 && nchar(Origin_4_n) == 0 && nchar(Origin_5_n) == 0)  { L0_n_lines <- 101 + 2 }
if (nchar(Origin_2_n)  > 0 && nchar(Origin_3_n)  > 0 && nchar(Origin_4_n)  > 0 && nchar(Origin_5_n) == 0)  { L0_n_lines <- 101 + 3 }
if (nchar(Origin_2_n)  > 0 && nchar(Origin_3_n)  > 0 && nchar(Origin_4_n)  > 0 && nchar(Origin_5_n)  > 0)  { L0_n_lines <- 101 + 4 }
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

# The following variabiles reguard the parameter and the level
# NOTE: Please, do NOT change these variables
# 
param_code              <- "aerosol_light_scattering_coefficient.aerosol.1y.1mn"
level_code              <- "lev0.nas"                                       


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
EBAS_temp_FILENAME      <-paste(L0_DIR,paste("temp_",EBAS_L0_FILENAME,sep=""),sep = "/")
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
"1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
9999.99999999 9999.99 9999.99 9999.99 9999.99 9999.99 9999.99 999.99 999.99 0x9999 999999.999999 999999.999999 999999.999999 999999.999999 999999.999999 999999.999999 999999.999999 999999.999999 999999.999999 999999.999999 999999.999999 999999.999999 999999.999999 999999.999999 999999.999999 9.999999999
end_time of measurement, days from the file reference point
pressure, hPa, Location=instrument internal, Matrix=instrument
temperature, K, Location=instrument inlet, Matrix=instrument
temperature, K, Location=instrument outlet, Matrix=instrument
relative_humidity, %, Location=instrument inlet, Matrix=instrument
relative_humidity, %, Location=instrument outlet, Matrix=instrument
flow_rate, l/min, Location=instrument internal, Matrix=instrument, Volume std. temperature=273.15 K, Volume std. pressure=1013.25 hPa
electric_tension, V, Location=lamp supply, Matrix=instrument
electric_current, A, Location=lamp supply, Matrix=instrument
status, no unit, Status type=overall instrument status, Matrix=instrument
aerosol_light_scattering_coefficient, 1/Mm, Wavelength=450 nm
aerosol_light_scattering_coefficient, 1/Mm, Wavelength=550 nm
aerosol_light_scattering_coefficient, 1/Mm, Wavelength=700 nm
aerosol_light_backscattering_coefficient, 1/Mm, Wavelength=450 nm
aerosol_light_backscattering_coefficient, 1/Mm, Wavelength=550 nm
aerosol_light_backscattering_coefficient, 1/Mm, Wavelength=700 nm
aerosol_light_scattering_coefficient_zero_measurement, 1/Mm, Wavelength=450 nm
aerosol_light_scattering_coefficient_zero_measurement, 1/Mm, Wavelength=550 nm
aerosol_light_scattering_coefficient_zero_measurement, 1/Mm, Wavelength=700 nm
aerosol_light_backscattering_coefficient_zero_measurement, 1/Mm, Wavelength=450 nm
aerosol_light_backscattering_coefficient_zero_measurement, 1/Mm, Wavelength=550 nm
aerosol_light_backscattering_coefficient_zero_measurement, 1/Mm, Wavelength=700 nm
aerosol_light_rayleighscattering_coefficient_zero_measurement, 1/Mm, Wavelength=450 nm
aerosol_light_rayleighscattering_coefficient_zero_measurement, 1/Mm, Wavelength=550 nm
aerosol_light_rayleighscattering_coefficient_zero_measurement, 1/Mm, Wavelength=700 nm
numflag
0",
(L0_n_lines - 23),
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
paste("Height AGL:                       ",height_AGL,sep=""),
paste("Inlet type:                       ",inlet_type,sep=""),
paste("Inlet description:                ",inlet_desc,sep=""),
paste("Humidity/temperature control:     ",hum_temp_c,sep=""),
paste("Humidity/temperature control description: ",hum_temp_c_desc,sep=""),
paste("Volume std. temperature:          ",vol_std_t,sep=""),
paste("Volume std. pressure:             ",vol_std_p,sep=""),
paste("Detection limit:                  ",detec_lim,sep=""),
paste("Detection limit expl.:            ",detec_lim_ex,sep=""),
paste("Measurement uncertainty:          ",meas_uncr,sep=""),
paste("Measurement uncertainty expl.:    ",meas_uncr_ex,sep=""),
paste("Zero/negative values code:        ",zero_val_code,sep=""),
paste("Zero/negative values:             ",zero_val,sep=""),
paste("Standard method:                  ",std_meth,sep=""),
paste("QA measure ID                     ",qa_mes_id,sep=""),
paste("QA date:                          ",qa_date,sep=""),
paste("QA document URL:                  ",qa_doc,sep=""),
paste("Originator:                       ",paste(Origin_1_n,Origin_1_s,Origin_1_e,Origin_1_i,sep=", "),sep=""),
paste("Originator:                       ",paste(Origin_2_n,Origin_2_s,Origin_2_e,Origin_2_i,sep=", "),sep=""),
paste("Originator:                       ",paste(Origin_3_n,Origin_3_s,Origin_3_e,Origin_3_i,sep=", "),sep=""),
if(nchar(Origin_4_n)>0) {paste("Originator:                       ",paste(Origin_4_n,Origin_4_s,Origin_4_e,Origin_4_i,sep=", "),sep="")},
if(nchar(Origin_5_n)>0) {paste("Originator:                       ",paste(Origin_5_n,Origin_5_s,Origin_5_e,Origin_5_i,sep=", "),sep="")},
paste("Submitter:                        ",paste(Submit_1_n,Submit_1_s,Submit_1_e,Submit_1_i,sep=", "),sep=""),
paste("Comment:                          ",mycomment,sep=""),       
"Acknowledgement:                  Request acknowledgment details from data originator",
paste("start_time","end_time","p_int","T_int","T_out","RH_int","RH_out","flow","lamp_v",
      "lamp_c","flags","sc450","sc550","sc700","bsc450","bsc550","bsc700","sc450z","sc550z",
      "sc700z","bsc450z","bsc550z","bsc700z","sc450r","sc550r","sc700r","numflag"),

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
# Listing the NEPH Raw data
#
lsfiles                 <-file.info(dir(RAW_DIR, pattern = glob2rx(paste0("*",NEPH_EXT)), full.names = F, ignore.case = TRUE))

lista                   <-data.frame(lsfiles[order(lsfiles$mtime),])
setDT(lista, keep.rownames = T)[]
names(lista)[1]         <-"fileName"
df_lista                <-data.frame(lista[fileName %like% questo_anno])
names(df_lista)[1]      <-"fileName"
df_lista$mydata         <-df_lista
ndata <- NROW(df_lista)
#
# -------------------------------------------------------------------------------------------
# Creating temporary NEPH dataset for current year
# 
for(j in df_lista$fileName) {
  
  ULTIMO_DATO           <-paste(RAW_DIR,j, sep="/")
  ULTIMO_DATO_NAME      <-basename(ULTIMO_DATO)
  TABELLA               <-read.table(file=ULTIMO_DATO,fill = T, header = NEPH_FIELD_NAM, row.names=NULL,
                                     colClasses = c(rep("numeric",6),rep("character",25)))

  names(TABELLA)[NEPH_DEC_DATE]   <-"start_time"
  names(TABELLA)[NEPH_Status]     <-"status"  
  names(TABELLA)[NEPH_p_int]      <-"p_int"
  names(TABELLA)[NEPH_T_int]      <-"T_int"
  names(TABELLA)[NEPH_T_out]      <-"T_out"
  names(TABELLA)[NEPH_RH_int]     <-"RH_int"
  names(TABELLA)[NEPH_lamp_v]     <-"lamp_v"
  names(TABELLA)[NEPH_lamp_c]     <-"lamp_c"
  names(TABELLA)[NEPH_flags]      <-"flags"
  names(TABELLA)[NEPH_sc450]      <-"sc450"  
  names(TABELLA)[NEPH_sc550]      <-"sc550"
  names(TABELLA)[NEPH_sc700]      <-"sc700"
  names(TABELLA)[NEPH_bsc450]     <-"bsc450"
  names(TABELLA)[NEPH_bsc550]     <-"bsc550"    
  names(TABELLA)[NEPH_bsc700]     <-"bsc700"
  names(TABELLA)[NEPH_sc450z]     <-"sc450z"
  names(TABELLA)[NEPH_sc550z]     <-"sc550z"
  names(TABELLA)[NEPH_sc700z]     <-"sc700z"  
  names(TABELLA)[NEPH_bsc450z]    <-"bsc450z"
  names(TABELLA)[NEPH_bsc550z]    <-"bsc550z"
  names(TABELLA)[NEPH_bsc700z]    <-"bsc700z"
  names(TABELLA)[NEPH_sc450r]     <-"sc450r"    
  names(TABELLA)[NEPH_sc550r]     <-"sc550r"
  names(TABELLA)[NEPH_sc700r]     <-"sc700r"
  #
  # -------------------------------------------------------------------------------------------
  # Adding new fields or setting existing
  #
  if(NEPH_flow   == 0)  { TABELLA$flow                  <- 9999.99  }
  else                  { names(TABELLA)[NEPH_flow]     <-"flow"    }
  if(NEPH_RH_out == 0)  { TABELLA$RH_out                <- 9999.999 }
  else                  { names(TABELLA)[NEPH_RH_out]   <-"RH_out"  }
  #
  # -------------------------------------------------------------------------------------------
  # Adding new fields
  #
  TABELLA$end_time      <-as.numeric(TABELLA$start_time) + 0.00069444
  TABELLA$numflag       <- 0

  TABELLA               <-subset(TABELLA, select=c("start_time","end_time","status","p_int","T_int","T_out",
                                                   "RH_int","RH_out","flow","lamp_v","lamp_c","flags","sc450",
                                                   "sc550","sc700","bsc450","bsc550","bsc700","sc450z","sc550z",
                                                   "sc700z","bsc450z","bsc550z","bsc700z","sc450r","sc550r","sc700r",
                                                   "numflag"))

  write.table(TABELLA, file=EBAS_temp_FILENAME,row.names=F,col.names = F, append = T, quote = F,sep=" ")
}
#
# -------------------------------------------------------------------------------------------
# Processing collected data
#
TABELLA                <-read.table(EBAS_temp_FILENAME,row.names=NULL, stringsAsFactors = FALSE)
colnames(TABELLA)      <-c("start_time","end_time","status","p_int","T_int","T_out","RH_int","RH_out","flow","lamp_v",
                          "lamp_c","flags","sc450","sc550","sc700","bsc450","bsc550","bsc700","sc450z","sc550z",
                          "sc700z","bsc450z","bsc550z","bsc700z","sc450r","sc550r","sc700r","numflag")

TABELLA$status        <- as.character(TABELLA$status)
TABELLA$flags         <- paste0("0x",str_pad(TABELLA$flags, 4, pad = "0"))
#
# -------------------------------------------------------------------------------------------
#
# Flagging NEPH values:
# See PART 0.1 for the setting of numflag script and table
#
# Flagging instrument internal relative humidity above 40%
TABELLA$numflag[TABELLA$RH_int > 40] <- sapply(TABELLA$numflag[TABELLA$RH_int > 40],
                                              nf_aggreg, nf_new = 0.640) 
#
# -------------------------------------------------------------------------------------------
# Flagging invalid due to calibration or zero/span check. Used for Level 0.
#
TABELLA$numflag[TABELLA$status == "ZBXX" |
                  TABELLA$status == "BBXX"] <- sapply(TABELLA$numflag[TABELLA$status == "ZBXX" | 
                                                                        TABELLA$status == "BBXX"],
                                                      nf_aggreg, nf_new = 0.682)
#
# -------------------------------------------------------------------------------------------
# Flagging invalid due to mechanical problem, unspecified reason
#
# -------------------------------------------------------------------------------------------
TABELLA$numflag[TABELLA$status   != "NBXX" & TABELLA$status != "ZBXX" &
                  TABELLA$status != "BBXX" & TABELLA$status != "NTXX" &
                  TABELLA$status != "BTXX" & TABELLA$status != "ZTXX"] <- sapply(TABELLA$numflag[TABELLA$status   != "NBXX" &
                                                                                                   TABELLA$status != "ZBXX" &
                                                                                                   TABELLA$status != "BBXX" & 
                                                                                                   TABELLA$status != "NTXX" &
                                                                                                   TABELLA$status != "BTXX" & 
                                                                                                   TABELLA$status != "ZTXX"],
                                                                                 nf_aggreg, nf_new = 0.699)
#
TABELLA$numflag[TABELLA$flags != "0x0000"] <- sapply(TABELLA$numflag[TABELLA$flags != "0x0000"],nf_aggreg, nf_new = 0.699)
#
# -------------------------------------------------------------------------------------------
# Appending Data set to EBAS Level-0 Header
#
myEBAS                  <-TABELLA[,c("start_time","end_time","p_int","T_int","T_out","RH_int","RH_out",
                             "flow","lamp_v","lamp_c","flags","sc450","sc550","sc700","bsc450","bsc550","bsc700",
                             "sc450z","sc550z","sc700z","bsc450z","bsc550z","bsc700z","sc450r","sc550r","sc700r",
                             "numflag")]
#
myEBAS[c(1:10,12:27)]   <- sapply(myEBAS[c(1:10,12:27)],as.numeric)
#
myEBAS                  <- myEBAS[!duplicated(myEBAS[1]),]
#
# -------------------------------------------------------------------------------------------
# Converting NEPH values to Mm-1 units
#
myEBAS[, 12:26]         <- myEBAS[, 12:26]*1000000 
#
# -------------------------------------------------------------------------------------------
# Writing the final Data set
# Formatting the output matrix as required by EBAS format Level-0
#
# Set the proper output format
#
sprintf_formats <- c(rep("%.8f", 2), rep("%.2f", 8), "%s", rep("%.6f", 15), "%.9f")
myEBAS[]        <- mapply(sprintf, sprintf_formats, myEBAS)
#
# Appending Data set to EBAS Level-0 Header
#

write.table(myEBAS, file=EBAS_L0_FULLFILENAME,row.names=F,col.names = F, append = T, quote = F,sep=" ")
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
# -------------------------------------------------------------------------------------------
##                                        # END PART 2.1 #
###########################################################################################################################

##>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> DAILY GRAPH REPORTING <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<##
###########################################################################################################################
##                                           # PART 3.0 #
## ______________________________________________________________________________________________________________________##
##                                 Loading data and setting variables
##                                              Timeplot
## ______________________________________________________________________________________________________________________##

# Extracting the calendar day from strat_time
#
REPORTAB            <-myEBAS[, c("start_time",
                                 "sc550",
                                 "p_int",
                                 "T_int",
                                 "RH_int",
                                 "lamp_v",
                                 "lamp_c")]
REPORTAB[]          <-lapply(REPORTAB, function(x) as.numeric(as.character(x)))
REPORTAB$day        <-REPORTAB$start_time-(REPORTAB$start_time-floor(REPORTAB$start_time)-1)
REPORTAB$date       <-as.POSIXct(as.Date(REPORTAB$start_time, origin = questo_capodanno))
reportday           <-c(REPORTAB[!duplicated(REPORTAB[,c('day')]),]$day)

print(reportday)    # check point: print the days in the table

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
    timePlot(THISREPORTTAB,pollutant=c("sc550",
                                       "p_int",
                                       "T_int",
                                       "RH_int",
                                       "lamp_v",
                                       "lamp_c"
    ),cex=25,date.breaks=15, y.relation="free", key = FALSE, fontsize = 14)
    dev.off()
  }
}

##                                          # END PART 3.0 #
###########################################################################################################################
#                                                                                                                         #
## End of NEPH_P20_1810.R                                                                                                 # 
#                                                                                                                         # 
###################################################################################### Authors: L u C A, Davide ###########

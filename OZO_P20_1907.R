###########################################################################################################################
## Project: NEXTDATA                                                                                                     ##
## Parameter: OZONE                                                                                                       ##
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
## Script filename: OZO_D20_1810.R                                                                                      ##
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
CALIB_DIR       = '../naitza/NEXTDATA/PROD/CIMONE/GAS/OZO/RAW_DATA_UTC/CALIB'           
RAW_DIR         = '../naitza/NEXTDATA/PROD/CIMONE/GAS/OZO/RAW_DATA_UTC'
#
# -------- DATA DESTINATION PATH --------------------------------------------------------------# REPLACE THE FOLLOWING PATHS
L0_DIR          = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/GAS/OZO/LEVEL_0'                     
L1_DIR          = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/GAS/OZO/LEVEL_1' 
L2_DIR          = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/GAS/OZO/LEVEL_2'
L0_ANCIL_DIR    = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/GAS/OZO/LEVEL_0/ANCILLARY'
#
# -------- GRAPH DESTINATION PATH -------------------------------------------------------------# REPLACE THE FOLLOWING PATHS
REP_DIR         = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/GAS/OZO/REPORT'
REP_GRAPH_DIR   = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/GAS/OZO/REPORT/DAILY_GRAPH'
PLOT_DIR_M      = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/GAS/OZO/REPORT/MONTHLY_GRAPH'
PLOT_DIR_S      = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/GAS/OZO/REPORT/SEASONAL_GRAPH'
PLOT_DIR_Y      = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/GAS/OZO/REPORT/ANNUAL_GRAPH'
PLOT_DIR_Y_PDF  = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/GAS/OZO/REPORT/ANNUAL_GRAPH/PDF'
PLOT_DIR_T      = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/GAS/OZO/REPORT/TIMEVARIATION_GRAPH' 
#
# -------- DAILY GRAPH PREFIX & SUFFIX -------------------------------------------------------# REPLACE THE FOLLOWING VALUES
DAILY_PREFIX    <-"CMN_OZO"     # chose a prefix for your daily graph (e.g. StationCodeName_ParameterCodeName)
DAILY_SUFFIX    <-"01M"         # chose a suffix for your daily graph (e.g. AcquisitionTiming)
#
# -------- SCRIPTS PATH ----------------------------------------------------------------------# REPLACE THE FOLLOWING PATHS
SCRIPT_DIR      = '../naitza/NEXTDATA/R_SCRIPT'          

## Loading functions for numflags
## The "NXD_numflag_functions_180301.R" scripts assigns the numflag value to the dataset, according to EBAS Flag List
## (https://ebas-submit.nilu.no/Submit-Data/List-of-Data-flags)
## The "NXD_EBAS_numflag_FullList_210429.txt" text file contains the EBAS Flag List, reporting codes, category and description
## Please do NOT apply any change to the following function settings, unless you need to specify a different table of flags
#
source(paste(SCRIPT_DIR,"NXD_numflag_functions_180301.R", sep="/"))

tab_nf          <- read.table(file = paste(SCRIPT_DIR,"NXD_EBAS_numflag_FullList_210429.txt",sep="/"),
                              sep = ";", header = TRUE, quote = NULL)

##                                        # END PART 0.1 #
###########################################################################################################################


###########################################################################################################################
##                                          # PART 0.2 #
## ______________________________________________________________________________________________________________________##
##                                         Setting OZO Data
## ______________________________________________________________________________________________________________________##
## USE: set the following values of OZO dataset
## WARNING: OZO raw data should be recorded according to the following specifications:
##          FILENAME: the filename should contain the acquisition date (YYYYMMDD). E.g.: CMN_OZO_20181215_01M.dat;
#
# -------- OZO RAW DATASET EXTENSION ----------------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
OZO_EXT         <-".dat"      # if different, replace ".dat" with the extesion of your OZO Raw Data set
#
# -------- OZO RAW DATA FIELD SEPARATOR -------------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
OZO_FIELD_SEP   <-" "         # if different, replace " "    with the field separator of your OZO Raw Data set (e.g. "," or "\t")
#
# -------- OZO RAW DATA HEADER ----------------------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
OZO_FIELD_NAM   <- T          # if different, replace T      with F if OZO Raw Data tables do not have the header (field names)
#
# -------- OZO FIELD POSITION IN THE TABLE -----------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
OZO_DEC_DATE    <- 6          # if different, replace with the field position of start_time (julian date) field in your OZO Raw Data set
OZO_O3          <- 8          # if different, replace with the field position of O3 field in your OZO Raw Data set
OZO_Int_A       <- 9          # if different, replace with the field position of Int_A field in your OZO Raw Data set
OZO_Int_B       <- 10         # if different, replace with the field position of Int_B field in your OZO Raw Data set
OZO_Bench_T     <- 11         # if different, replace with the field position of Bench_T field in your OZO Raw Data set
OZO_Lamp_T      <- 12         # if different, replace with the field position of Lamp_T field in your OZO Raw Data set
OZO_Flow_A      <- 13         # if different, replace with the field position of Flow_A field in your OZO Raw Data set
OZO_Flow_B      <- 14         # if different, replace with the field position of Flow_B field in your OZO Raw Data set
OZO_sd          <- 16         # if different, replace with the field position of O3 sd field in your OZO Raw Data set
OZO_status      <- 7          # if different, replace with the field position of Status field in your OZO Raw Data set
#
# -------- O3 STATUS --------------------------------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
Status_SPAN     <- "Span"     # if different, replace with the value reported in the SPAN filed for "Span" condition
Status_ZERO     <- "Zero"     # if different, replace with the value reported in the SPAN filed for "Zero" condition
#
## ______________________________________________________________________________________________________________________##
##                                         Setting OZO CALIBRATION Data
## ______________________________________________________________________________________________________________________##
## USE: set the following values of OZO dataset
## WARNING: CALIBRATION OZO raw data should be recorded according to the following specifications:
##          FILENAME: the filename should contain the acquisition date (YYYYMMDD). E.g.: CMN_OZO_20181215_01M.dat;
#
# -------- OZO RAW DATASET EXTENSION ----------------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
CALIB_EXT         <-".dat"      # if different, replace ".dat" with the extesion of your OZO Raw Data set
#
# -------- OZO RAW DATA FIELD SEPARATOR -------------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
CALIB_FIELD_SEP   <-" "         # if different, replace " "    with the field separator of your OZO Raw Data set (e.g. "," or "\t")
#
# -------- OZO RAW DATA HEADER ----------------------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
CALIB_FIELD_NAM   <- T          # if different, replace T      with F if OZO Raw Data tables do not have the header (filed names)
#
# -------- OZO FIELD POSITION IN THE TABLE -----------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
CALIB_DEC_DATE    <- 6          # if different, replace with the field position of start_time (julian date) field in your Calibration Data set
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

inst_type               <- "uv_abs"                                          # replace the value with your instrument type
inst_manu               <- "Thermo"                                          # replace the value with your instrument manufacter
inst_modl               <- "49i"                                             # replace the value with your instrument model
inst_name               <- "IT06L_49i_1225011092"                            # replace the value with your your instrument name
inst_s_n                <- "1225011092"                                      # replace the value with your instrument serial number
meth_ref                <- "IT06L_49i_uvab"                                  # replace the value with method reference

dependent_col           <- "9"                                               # replace the value with the total number of columns of the file in addition to start_time (i.e., total-1)

component               <- "GAS_light_scattering_coefficient"                # replace the value with proper component 
matrix                  <- "air"                                             # replace the value with proper matrix
meas_unit               <- "1/Mm"                                            # replace the value with proper measurement unit

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

flow_rate               <- "1.50 l/min"                                      # replace the value with Flow rate

zero_check              <- "automatic"                                       # replace the value with Zero/span check type
zero_inter              <- "1d"                                              # replace the value with Zero/span check interval

hum_temp_c              <- "none"                                            # replace the value with Humidity/temperature control
hum_temp_c_desc         <- ""                                                # replace the value with Humidity/temperature control description

vol_std_t               <- "ambient"                                         # replace the value with Volume std. temperature
vol_std_p               <- "ambient"                                         # replace the value with Volume std. pressure

detec_lim               <- "1 nmol/mol"                                      # replace the value with Detection limit
absorp_cs               <- ""                                                # replace the value with Absorption cross section

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
if (nchar(Origin_2_n) == 0 && nchar(Origin_3_n) == 0 && nchar(Origin_4_n) == 0 && nchar(Origin_5_n) == 0)  { L0_n_lines <- 85 + 0 }
if (nchar(Origin_2_n)  > 0 && nchar(Origin_3_n) == 0 && nchar(Origin_4_n) == 0 && nchar(Origin_5_n) == 0)  { L0_n_lines <- 85 + 1 }
if (nchar(Origin_2_n)  > 0 && nchar(Origin_3_n)  > 0 && nchar(Origin_4_n) == 0 && nchar(Origin_5_n) == 0)  { L0_n_lines <- 85 + 2 }
if (nchar(Origin_2_n)  > 0 && nchar(Origin_3_n)  > 0 && nchar(Origin_4_n)  > 0 && nchar(Origin_5_n) == 0)  { L0_n_lines <- 85 + 3 }
if (nchar(Origin_2_n)  > 0 && nchar(Origin_3_n)  > 0 && nchar(Origin_4_n)  > 0 && nchar(Origin_5_n)  > 0)  { L0_n_lines <- 85 + 4 }
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

# The following variabiles reguard the parameter and the level
# NOTE: Please, do NOT change these variables
# 
param_code              <- "uv_abs.ozone.air.1y.1mn"
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
  "1 1 1 1 1 1 1 1 1
9999.99999999 9999.99 9.999999999 999999.9 999999.9 999.9 999.9 99.99 99.99
end_time, days from the file reference point
ozone, nmol/mol
numflag, no unit
Intensity cell A, Hz, Location=instrument internal, Matrix=instrument
Intensity cell B, Hz, Location=instrument internal, Matrix=instrument
Internal bench temperature, K, Location=instrument internal, Matrix=instrument 
Lamp temperature, K, Location=instrument internal, Matrix=instrument 
Flow cell A, l/min, Location=instrument internal, Matrix=instrument 
Flow cell B, l/min, Location=instrument internal, Matrix=instrument
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
  paste("QA document URL:                  ",qa_doc,sep=""),
  paste("Originator:                       ",paste(Origin_1_n,Origin_1_s,Origin_1_e,Origin_1_i,sep=", "),sep=""),
  paste("Originator:                       ",paste(Origin_2_n,Origin_2_s,Origin_2_e,Origin_2_i,sep=", "),sep=""),
  paste("Originator:                       ",paste(Origin_3_n,Origin_3_s,Origin_3_e,Origin_3_i,sep=", "),sep=""),
  if(nchar(Origin_4_n)>0) {paste("Originator:                       ",paste(Origin_4_n,Origin_4_s,Origin_4_e,Origin_4_i,sep=", "),sep="")},
  if(nchar(Origin_5_n)>0) {paste("Originator:                       ",paste(Origin_5_n,Origin_5_s,Origin_5_e,Origin_5_i,sep=", "),sep="")},
  paste("Submitter:                        ",paste(Submit_1_n,Submit_1_s,Submit_1_e,Submit_1_i,sep=", "),sep=""),
  paste("Comment:                          ",mycomment,sep=""),       
  "Acknowledgement:                  Request acknowledgment details from data originator",
  paste("start_time","end_time","o3","numflag","Int_A","Int_B","Bench_T","Lamp_T","Flow_A","Flow_B",sep=" "),
  
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
# Listing the OZO Raw data
#
lsfiles                 <-file.info(dir(RAW_DIR, pattern = glob2rx(paste0("*",OZO_EXT)), full.names = F, ignore.case = TRUE))

lista                   <-data.frame(lsfiles[order(lsfiles$mtime),])
setDT(lista, keep.rownames = T)[]
names(lista)[1]         <-"fileName"
df_lista                <-data.frame(lista[fileName %like% questo_anno])
names(df_lista)[1]      <-"fileName"
df_lista$mydata         <-df_lista
ndata <- NROW(df_lista)
#
# -------------------------------------------------------------------------------------------
# Creating temporary OZO dataset for current year
# 
for(j in df_lista$fileName) {
  
  ULTIMO_DATO           <-paste(RAW_DIR,j, sep="/")
  ULTIMO_DATO_NAME      <-basename(ULTIMO_DATO)
  TABELLA               <-read.table(file=ULTIMO_DATO,fill = T, header = OZO_FIELD_NAM, row.names=NULL,
                                     colClasses = c(rep("numeric",6),rep("character",25)))
  
  names(TABELLA)[OZO_DEC_DATE]    <-"start_time"
  names(TABELLA)[OZO_O3]          <-"o3"  
  names(TABELLA)[OZO_Int_A]       <-"Int_A"
  names(TABELLA)[OZO_Int_B]       <-"Int_B"
  names(TABELLA)[OZO_Bench_T]     <-"Bench_T"
  names(TABELLA)[OZO_Lamp_T]      <-"Lamp_T"
  names(TABELLA)[OZO_Flow_A]      <-"Flow_A"
  names(TABELLA)[OZO_Flow_B]      <-"Flow_B"
  names(TABELLA)[OZO_sd]          <-"o3_sd"
  names(TABELLA)[OZO_status]      <-"mode"  
  #
  # -------------------------------------------------------------------------------------------
  # Adding new fields or setting existing
  #
  if(OZO_sd   == 0) { TABELLA$o3_sd             <- sd(TABELLA$o3) }
  else              { names(TABELLA)[OZO_sd]    <-"o3_sd"        }
  #
  # -------------------------------------------------------------------------------------------
  # Adding new fields
  #
  TABELLA$end_time        <-as.numeric(TABELLA$start_time) + 0.00069444
  TABELLA$numflag         <- 0
  
  TABELLA                 <-subset(TABELLA, select=c("start_time","end_time","o3","Int_A","Int_B","Bench_T",
                                                     "Lamp_T","Flow_A","Flow_B","o3_sd", "mode", "numflag"))
  
  write.table(TABELLA, file=EBAS_temp_FILENAME,row.names=F,col.names = F, append = T, quote = F,sep=" ")
}
#
# -------------------------------------------------------------------------------------------
# Processing collected data
#
TABELLA                 <-read.table(EBAS_temp_FILENAME,row.names=NULL, stringsAsFactors = FALSE)
colnames(TABELLA)       <-c("start_time","end_time","o3","Int_A","Int_B","Bench_T",
                            "Lamp_T","Flow_A","Flow_B","o3_sd", "mode", "numflag")
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
# Flagging OZO values:
# See PART 0.1 for the setting of numflag script and table
#
# Defining O3 elaboration and creating O3 flag field
TABELLA$o3_elab         <-TABELLA$o3
TABELLA$numflag         <-0
#
# -------------------------------------------------------------------------------------------
# Calculating O3 difference between successive values:
#
o3_diff                 <-diff(TABELLA$o3)
n                       <-nrow(TABELLA)
o3_diff[n]              <-0
TABELLA$o3_diff         <-o3_diff
TABELLA$O3_diff[is.na(o3_diff)]   <- -999
#
# -------------------------------------------------------------------------------------------
# Calculating hourly means:
#
TABELLA_1h              <-timeAverage(TABELLA, data.tresh=0,avg.time = "hour")
TABELLA_1h              <-subset(TABELLA_1h, select=c("date","o3") )
names(TABELLA_1h)[2]    <-"o3h"
#
TABELLA_1h_sd           <-timeAverage(TABELLA, avg.time = "hour", data.tresh=0, statistic="sd")
TABELLA_1h_sd           <-subset(TABELLA_1h_sd, select=c("date","o3") )
names(TABELLA_1h_sd)[2] <-"o3hsd"
#
TABELLA                 <-merge(TABELLA,TABELLA_1h,    by="date",all=TRUE)
TABELLA                 <-merge(TABELLA,TABELLA_1h_sd, by="date",all=TRUE)
#
#
# -------------------------------------------------------------------------------------------
# Replacing NAs with last observation carried forward:
#
TABELLA$o3h             <-na.locf(TABELLA$o3h,    na.rm=FALSE)
TABELLA$o3hsd           <-na.locf(TABELLA$o3hsd,  na.rm=FALSE)
TABELLA$o3              <-na.locf(TABELLA$o3,     na.rm=FALSE)
TABELLA$o3_sd           <-na.locf(TABELLA$o3_sd,  na.rm=FALSE)
TABELLA$Flow_A          <-na.locf(TABELLA$Flow_A, na.rm=FALSE)
TABELLA$Flow_B          <-na.locf(TABELLA$Flow_B, na.rm=FALSE)
#
# -------------------------------------------------------------------------------------------
# Flagging O3
#
for (i in 1:(nrow(TABELLA)-2)){
  
  if (is.na(TABELLA$o3[i])     || 
      (TABELLA$o3[i] > 150)    ||
      (TABELLA$o3[i] < 20))        {TABELLA$numflag[i] <- 0.459000000 ;      TABELLA$o3_elab[i]     <- NA          }
  else if (TABELLA$o3[i]< -900)    {TABELLA$o3[i]      <-999.99       ;      TABELLA$numflag[i]     <- 0.999000000 }
  if (is.na(TABELLA$Flow_A[i]) ||  (!is.na(TABELLA$Flow_A[i]) < 0.2))      { TABELLA$numflag[i]     <- 0.664000000 }
  if (is.na(TABELLA$Flow_B[i]) ||  (!is.na(TABELLA$Flow_B[i]) < 0.2))      { TABELLA$numflag[i]     <- 0.664000000 }
  if (TABELLA$mode[i] %in% Status_SPAN )   {TABELLA$o3_elab[i]      <- NA  ; TABELLA$numflag[i]     <- 0.682000000 ;
                                            TABELLA$o3_elab[i+1]    <- NA  ; TABELLA$numflag[i+1]   <- 0.682000000 ;
                                            TABELLA$o3_elab[i+2]    <- NA  ; TABELLA$numflag[i+2]   <- 0.682000000 }
  if (TABELLA$mode[i] %in% Status_ZERO)    {TABELLA$o3_elab[i]      <- NA  ; TABELLA$numflag[i]     <- 0.682000000 ;
                                            TABELLA$o3_elab[i+1]    <- NA  ; TABELLA$numflag[i+1]   <- 0.682000000 ;
                                            TABELLA$o3_elab[i+2]    <- NA  ; TABELLA$numflag[i+2]   <- 0.682000000 }
}
TABELLA$o3_elab[TABELLA$numflag  == 0.682000000 | TABELLA$numflag  == 0.459000000  ]    <- NA
#
# -------------------------------------------------------------------------------------------
# Setting NAs to invalid value 
#
TABELLA$Int_A       [is.na(TABELLA$Int_A)     | TABELLA$numflag    == 0.999]  <-999999.9
TABELLA$Int_B       [is.na(TABELLA$Int_B)     | TABELLA$numflag    == 0.999]  <-999999.9
TABELLA$o3          [is.na(TABELLA$o3)        | TABELLA$numflag    == 0.999]  <-9999.99
TABELLA$Bench_T     [is.na(TABELLA$Bench_T)   | TABELLA$numflag    == 0.999]  <-999.9
TABELLA$Lamp_T      [is.na(TABELLA$Lamp_T)    | TABELLA$numflag    == 0.999]  <-999.9
TABELLA$Flow_A      [is.na(TABELLA$Flow_A)    | TABELLA$numflag    == 0.999]  <-99.99
TABELLA$Flow_B      [is.na(TABELLA$Flow_B)    | TABELLA$numflag    == 0.999]  <-99.99
#
# -------------------------------------------------------------------------------------------
# Creating temporary CALIBRATION dataset for current year
# 
CALIB_lsdata        <-list.files(path = CALIB_DIR, pattern = glob2rx(paste("*",OZO_EXT, sep=".")), all.files = FALSE,
                                 full.names = F, recursive = FALSE, ignore.case = FALSE, include.dirs = F, 
                                 no.. = FALSE)

CALIB_LISTA         <-as.character(CALIB_lsdata)

df_CALIB_LISTA  <-data.frame(CALIB_LISTA)
if(nrow(df_CALIB_LISTA) != 0)
{
  names(df_CALIB_LISTA)[1]    <-"fileName"
  df_CALIB_LISTA$calib_start  <-0
  df_CALIB_LISTA$calib_end    <-0
  for (c in df_CALIB_LISTA$fileName) 
  {
    CALIB_TABELLA             <-read.table(file=paste(CALIB_DIR,c,sep="/"),fill = TRUE, skip = 1)
    cTABELLA                  <-subset(CALIB_TABELLA[6],CALIB_TABELLA[6]>=0 & CALIB_TABELLA[6]<=365)
    
    mindate                   <-as.numeric(format(trunc(min(cTABELLA[1])), 8),nsmall = 8)
    maxdate                   <-as.numeric(format(trunc(max(cTABELLA[1])), 8),nsmall = 8)
    #
    # Flagging O3 when calibration occurs
    #
    TABELLA$numflag[trunc(TABELLA$start_time) >= as.numeric(mindate) && trunc(TABELLA$end_time)<= as.numeric(maxdate)] <- 0.68200000    
  } 
}
#
# -------------------------------------------------------------------------------------------
# Fixing start_time and end_time NAs due to the previous processing
# 
jd                            <-strptime(TABELLA$date, "%Y-%m-%d %H:%M")$yday
h                             <-strptime(TABELLA$date, "%Y-%m-%d %H:%M")$hour
m                             <-strptime(TABELLA$date, "%Y-%m-%d %H:%M")$min
time                          <-h*60+m
time.dec                      <-time/1440
TABELLA$start_time            <-jd+time.dec
TABELLA$end_time              <-jd+time.dec+0.00069444 
#
# -------------------------------------------------------------------------------------------
# Appending Data set to EBAS Level-0 Header
#
myEBAS                  <-TABELLA[,c("start_time","end_time","o3","numflag","Int_A","Int_B","Bench_T","Lamp_T","Flow_A","Flow_B")]
#
# Removing possible duplicates
myEBAS <- myEBAS[!duplicated(myEBAS[1]),] # Check in code
#
# Set the proper output format
#
sprintf_formats <- c(rep("%.8f", 2), rep("%.2f", 1), rep("%.9f", 1), rep("%.1f", 4), rep("%.2f", 2))
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
# Extracting the calendar day from start_time
#
REPORTAB            <-TABELLA[, c("start_time",
                                 "o3",
                                 "o3_elab",
                                 "o3_sd",
                                 "o3hsd",
                                 "numflag",
                                 "Flow_A",
                                 "Flow_B",
                                 "Int_A",
                                 "Int_B", 
                                 "numflag"
                                 )]
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
    timePlot(THISREPORTTAB,pollutant=c("o3",
                                       "o3_elab",
                                       "o3_sd",
                                       "o3hsd",
                                       "numflag",
                                       "Flow_A",
                                       "Flow_B",
                                       "Int_A",
                                       "Int_B"
    ),cex=25,date.breaks=15, y.relation="free", key = FALSE, fontsize = 14)
    dev.off()
  }
}

##                                          # END PART 3.0 #
###########################################################################################################################
#                                                                                                                         #
## End of OZO_D20_1810.R                                                                                                  # 
#                                                                                                                         # 
###################################################################################### Authors: L u C A, Davide ###########

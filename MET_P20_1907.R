###########################################################################################################################
## Project: NEXTDATA                                                                                                     ##
## Parameter: METEO                                                                                                        ##
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
## Script filename: MET_P20_1810.R                                                                                       ##
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
CALIB_DIR       = '../naitza/NEXTDATA/PROD/CIMONE/METEO/METEO/RAW_DATA_UTC/CALIB'           
RAW_DIR         = '../naitza/NEXTDATA/PROD/CIMONE/METEO/METEO/RAW_DATA_UTC'
RAD_RAW_DIR     = '../naitza/NEXTDATA/PROD/CIMONE/METEO/RAD_SOL/RAW_DATA_UTC'
#
# -------- DATA DESTINATION PATH --------------------------------------------------------------# REPLACE THE FOLLOWING PATHS
L0_DIR          = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/METEO/METEO/LEVEL_0'                     
L1_DIR          = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/METEO/METEO/LEVEL_1' 
L2_DIR          = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/METEO/METEO/LEVEL_2'
L0_ANCIL_DIR    = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/METEO/METEO/LEVEL_0/ANCILLARY'
#
# -------- GRAPH DESTINATION PATH -------------------------------------------------------------# REPLACE THE FOLLOWING PATHS
REP_DIR         = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/METEO/METEO/REPORT'
REP_GRAPH_DIR   = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/METEO/METEO/REPORT/DAILY_GRAPH'
PLOT_DIR_M      = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/METEO/METEO/REPORT/MONTHLY_GRAPH'
PLOT_DIR_S      = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/METEO/METEO/REPORT/SEASONAL_GRAPH'
PLOT_DIR_Y      = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/METEO/METEO/REPORT/ANNUAL_GRAPH'
PLOT_DIR_Y_PDF  = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/METEO/METEO/REPORT/ANNUAL_GRAPH/PDF'
PLOT_DIR_T      = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/METEO/METEO/REPORT/TIMEVARIATION_GRAPH' 
#
# -------- DAILY GRAPH PREFIX & SUFFIX -------------------------------------------------------# REPLACE THE FOLLOWING VALUES
DAILY_PREFIX    <-"CMN_METEO"     # choose a prefix for your daily graph (e.g. StationCodeName_ParameterCodeName)
DAILY_SUFFIX    <-"01M"           # choose a suffix for your daily graph (e.g. AcquisitionTiming)
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
##                                          # PART 0.2.1 #
## ______________________________________________________________________________________________________________________##
##                                        Setting Meteo Data
## ______________________________________________________________________________________________________________________##
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
METEO_FIELD_NAM <- T          # if different, replace "T" with "F" if Meteo Raw Data tables do not have the header (field names)
#
# -------- METEO FIELD POSITION -----------------------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
METEO_DEC_DATE  <- 6          # if different, replace with the field position of start_time (julian date) field in your Meteo Raw Data set
METEO_WS        <- 9          # if different, replace with the field position of Wind Speed field in your Meteo Raw Data set
METEO_WS_SD     <- 10         # if different, replace with the field position of Wind Speed Standard Deviation field in your Meteo Raw Data set
METEO_WD        <- 7          # if different, replace with the field position of Wind Direction field in your Meteo Raw Data set
METEO_T         <- 11         # if different, replace with the field position of Temperature field in your Meteo Raw Data set
METEO_T_SD      <- 12         # if different, replace with the field position of Temperature Standard Deviation field in your Meteo Raw Data set
METEO_RH        <- 13         # if different, replace with the field position of Relative Humidity field in your Meteo Raw Data set
METEO_RH_SD     <- 14         # if different, replace with the field position of Relative Humidity Standard Deviation field in your Meteo Raw Data set
METEO_P         <- 15         # if different, replace with the field position of Pressure field in your Meteo Raw Data set
METEO_P_SD      <- 16         # if different, replace with the field position of Pressure Standard Deviation field in your Meteo Raw Data set
#
# -------------------------------------------------------------------------------------------

##                                        # END PART 0.2.1 #
###########################################################################################################################


###########################################################################################################################
##                                          # PART 0.2.2 #
## ______________________________________________________________________________________________________________________##
##                                         Setting Solar Radiation Data
## ______________________________________________________________________________________________________________________##
## USE: set the following values of Solar Radiation dataset
## WARNING: Solar radiation raw data should be recorded according with the following specifics:
##          FILENAME: the filename should contain the acquisition date (YYYYMMDD). E.g.: CMN_RAD_SOL_20181215_01M.dat;
#
# -------- METEO RAW DATASET EXTENSION ----------------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
RAD_EXT         <-".dat"      # if different, replace ".dat" with the extesion of your METEO Raw Data set
#
# -------- METEO RAW DATA FIELD SEPARATOR -------------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
RAD_FIELD_SEP   <-" "         # if different, replace " "    with the field separator of your METEO Raw Data set (e.g. "," or "\t")
#
# -------- METEO RAW DATA HEADER ----------------------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
RAD_FIELD_NAM   <- T          # if different, replace T      with F if METEO Row Data tables do not have the header (filed names)
#
# -------- METEO FIELD POSITION IN THE TABLE -----------------------------------------------------# REPLACE THE FOLLOWING VALUES
#
RAD_DEC_DATE    <- 6          # if different, replace with the field position of start_time (julian date) field in your METEO Raw Data set
RAD_SHORTW_D    <- 9          # if different, replace with the field position of Short Wave Down field in your METEO Raw Data set
RAD_SHORTW_D_SD <- 10         # if different, replace with the field position of Short Wave Down Standard Deviation field in your METEO Raw Data set
RAD_UVB         <- 11         # if different, replace with the field position of UVB field in your METEO Raw Data set
RAD_UVB_SD      <- 12         # if different, replace with the field position of UVB Standard Deviation field in your METEO Raw Data set
#
# -------------------------------------------------------------------------------------------

##                                        # END PART 0.2.2 #
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

inst_type               <- "aws"                                             # replace the value with your instrument type
inst_manu               <- ""                                                # replace the value with your instrument manufacter
inst_modl               <- ""                                                # replace the value with your instrument model
inst_name               <- ""                                                # replace the value with your your instrument name
inst_s_n                <- ""                                                # replace the value with your instrument serial number

dependent_col           <- "13"                                              # replace the value with the total number of columns of the file in addition to start_time (i.e., total-1)

component               <- ""                                                # replace the value with proper component 
matrix                  <- "met"                                             # replace the value with proper matrix
meas_unit               <- ""                                                # replace the value with proper measurement unit

meas_lat                <- "44.16667"                                        # replace the value with the your Measure latitude
meas_lon                <- "10.68333"                                        # replace the value with the your Measure longitude
meas_alt                <- "2165m"                                           # replace the value with the your Measure altitude (meters)

Period_code             <- "1y"                                              # replace the value with the proper Period code
Resolution_code         <- "1mn"                                             # replace the value with the proper Resolution code
Sample_duration         <- "1mn"                                             # replace the value with the proper Sample duration
Orig_time_res           <- "1mn"                                             # replace the value with the proper Original time resolution

height                  <- "5m"                                             # replace the value with Height 

# The following variabiles reguard the originator and the submitter names, surnames, emails and addresses
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
if (nchar(Origin_2_n) == 0 && nchar(Origin_3_n) == 0 && nchar(Origin_4_n) == 0 && nchar(Origin_5_n) == 0)  { L0_n_lines <- 72 + 0 }
if (nchar(Origin_2_n)  > 0 && nchar(Origin_3_n) == 0 && nchar(Origin_4_n) == 0 && nchar(Origin_5_n) == 0)  { L0_n_lines <- 72 + 1 }
if (nchar(Origin_2_n)  > 0 && nchar(Origin_3_n)  > 0 && nchar(Origin_4_n) == 0 && nchar(Origin_5_n) == 0)  { L0_n_lines <- 72 + 2 }
if (nchar(Origin_2_n)  > 0 && nchar(Origin_3_n)  > 0 && nchar(Origin_4_n)  > 0 && nchar(Origin_5_n) == 0)  { L0_n_lines <- 72 + 3 }
if (nchar(Origin_2_n)  > 0 && nchar(Origin_3_n)  > 0 && nchar(Origin_4_n)  > 0 && nchar(Origin_5_n)  > 0)  { L0_n_lines <- 72 + 4 }
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
# Please, do NOT apply any change, if you don't know what you're doing
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

# The following variabiles reguard the parameter and the 
# NOTE: Please, do NOT change these variables
# 
param_code              <- "aws.met.1y.1min"
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
EBAS_temp_FILENAME      <-paste(L0_DIR,paste("temp_",EBAS_L0_FILENAME,sep=""),sep = "/")
RAD_FULLFILENAME        <-paste(L0_DIR,paste("temp_rad_",EBAS_L0_FILENAME,sep=""),sep = "/")

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
RAD_FULLFILENAME
#                                         # END PART 1.1 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 2.0 #
## ______________________________________________________________________________________________________________________##
##                                    Creation of Level-0 data file
##                                     Cleaning Destination directory
##                                        Formatting Level-0 header
## ______________________________________________________________________________________________________________________##

# -------------------------------------------------------------------------------------------
# Deleting temporaney files in the destination directory (if present)
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
# NOTE: the following processing deletes old EBAS Level-0 files within the destination directory 
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
# NOTE: the following processing deletes old EBAS Level-0 files within the destination directory
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
"1 1 1 1 1 1 1 1 1 1 1 1 1 
9999.999999 99.9 9.999999999 999.9 9.999999999 99.9 9.999999999 999.9 9.999999999 9999.9 9.999999999 99999.9 9.999999999
end_time of measurement, days from the file reference point
wind_speed, m/s, Instrument name=CIM_WS425,Measurement height=5m, Measurement uncertainty=3%, Method ref=IT06L_WS425
numflag wind_speed, no unit
wind_direction, deg, Instrument name=CIM_WS425,Measurement height=5m, Measurement uncertainty=1%, Method ref=IT06L_WS425
numflag wind_direction, no unit
temperature, deg C, Instrument name=CIM_Rotronic, Measurement height= 1m, Measurement uncertainty=2%, Method ref=IT06L_Rotronic
numflag temperature, no unit
relative_humidity, %, Instrument name=CIM_Rotronic, Measurement uncertainty=1%, Method ref=IT06L_Rotronics
numflag relative_humidity, no unit
pressure, hPa, Measurement uncertainty=2.5%, Instrument name=CIM_Technoel, Method ref=IT06L_Technoel
numflag pressure, no unit
downward_solar_radiation_flux_density, W/m2, Instrument name=CMN_SkyeSKS110, Measurement uncertainty=5%, Method ref=IT06L_SKS110
numflag downward_solar_radiation_flux_density, no unit
0",
(L0_n_lines - 27),
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
paste("Method ref:                       ","",sep=""),
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
paste("Measurement Height:               ",height,sep=""),
paste("Originator:                       ",paste(Origin_1_n,Origin_1_s,Origin_1_e,Origin_1_i,sep=", "),sep=""),
paste("Originator:                       ",paste(Origin_2_n,Origin_2_s,Origin_2_e,Origin_2_i,sep=", "),sep=""),
paste("Originator:                       ",paste(Origin_3_n,Origin_3_s,Origin_3_e,Origin_3_i,sep=", "),sep=""),
if(nchar(Origin_4_n)>0) {paste("Originator:                       ",paste(Origin_4_n,Origin_4_s,Origin_4_e,Origin_4_i,sep=", "),sep="")},
if(nchar(Origin_5_n)>0) {paste("Originator:                       ",paste(Origin_5_n,Origin_5_s,Origin_5_e,Origin_5_i,sep=", "),sep="")},
paste("Submitter:                        ",paste(Submit_1_n,Submit_1_s,Submit_1_e,Submit_1_i,sep=", "),sep=""),
paste("Comment:                          ",mycomment,sep=""),       
"Acknowledgement:                  Request acknowledgment details from data originator",
paste("start_time","end_time","wind_speed","numflag_wind_speed","wind_direction","numflag_wind_direction","temperature","numflag_temperature","relative_humidity","numflag_relative_humidity","pressure","numflag_pressure","global_radiation","numflag_global_radiation",sep=" "),

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

# Importing raw data
# 

# -------------------------------------------------------------------------------------------
# Listing the METEO Raw data
#
RAD_lsfiles            <-file.info(dir(RAD_RAW_DIR, pattern = glob2rx(paste0("*",RAD_EXT)), full.names = F, ignore.case = TRUE))

RAD_lista              <-data.frame(RAD_lsfiles[order(RAD_lsfiles$mtime),])
setDT(RAD_lista, keep.rownames = T)[]
names(RAD_lista)[1]    <-"fileName"
df_RAD_lista           <-data.frame(RAD_lista[fileName %like% questo_anno])
names(df_RAD_lista)[1] <-"fileName"
df_RAD_lista$mydata    <-df_RAD_lista
RAD_data               <-NROW(df_RAD_lista)

# -------------------------------------------------------------------------------------------
# Creating temporany RAD dataset for current year
# 
for(m in df_RAD_lista$fileName) 
{
  RAD_ULTIMO_DATO      <-paste(RAD_RAW_DIR,m, sep="/")
  RAD_ULTIMO_DATO_NAME <-basename(RAD_ULTIMO_DATO)
  RAD_TABELLA          <-read.table(file=RAD_ULTIMO_DATO,fill = T, header = RAD_FIELD_NAM, row.names=NULL)

  names(RAD_TABELLA)[RAD_DEC_DATE]  <-"start_time"
  names(RAD_TABELLA)[RAD_SHORTW_D]  <-"ShortW_D"
  names(RAD_TABELLA)[RAD_UVB]       <-"UVB"
  
  if(RAD_SHORTW_D_SD == 0) { RAD_TABELLA$SD_ShortW_D            <- sd(RAD_TABELLA$ShortW_D)}
  else                     { names(RAD_TABELLA)[RAD_SHORTW_D_SD]<-"SD_ShortW_D" }
  if(RAD_UVB_SD == 0)      { RAD_TABELLA$SD_UVB                 <- sd(RAD_TABELLA$UVB)} 
  else                     { names(RAD_TABELLA)[RAD_UVB_SD]     <-"SD_UVB" }  

  RAD_TABELLA$end_time <-RAD_TABELLA$start_time + 0.00069444
  RAD_TABELLA$code     <- sub(" ","",paste("code",sprintf("%.6f",RAD_TABELLA$start_time),sep="_"))
  
  RAD_TABELLA          <-RAD_TABELLA[,c("start_time","end_time","ShortW_D","SD_ShortW_D","UVB","SD_UVB", "code")]
  
  write.table(RAD_TABELLA, file=RAD_FULLFILENAME,row.names=F,col.names = F, append = T, quote = F,sep= RAD_FIELD_SEP)
}  
RAD_data               <-read.table(RAD_FULLFILENAME)
colnames(RAD_data)     <-c("start_time","end_time","ShortW_D","SD_ShortW_D","UVB","SD_UVB", "code")
# 
# -------------------------------------------------------------------------------------------
# Listing the METEO Raw data
#

lsfiles                 <-file.info(dir(RAW_DIR, pattern = glob2rx(paste0("*",METEO_EXT)), full.names = F, ignore.case = TRUE))

lista                   <-data.frame(lsfiles[order(lsfiles$mtime),])
setDT(lista, keep.rownames = T)[]
names(lista)[1]         <-"fileName"
df_lista                <-data.frame(lista[fileName %like% questo_anno])
names(df_lista)[1]      <-"fileName"
df_lista$mydata         <-df_lista
ndata <- NROW(df_lista)
#
# -------------------------------------------------------------------------------------------
# Creating temporany METEO dataset for current year
# 
for(j in df_lista$fileName) {
  
  ULTIMO_DATO           <-paste(RAW_DIR,j, sep="/")
  ULTIMO_DATO_NAME      <-basename(ULTIMO_DATO)
  TABELLA               <-read.table(file=ULTIMO_DATO,fill = T, header = METEO_FIELD_NAM, row.names=NULL)
  
  names(TABELLA)[METEO_DEC_DATE]  <-"start_time"
  names(TABELLA)[METEO_WS]        <-"WS"
  names(TABELLA)[METEO_WS_SD]     <-"SD_WS"
  names(TABELLA)[METEO_WD]        <-"WD"
  names(TABELLA)[METEO_T]         <-"T"
  names(TABELLA)[METEO_T_SD]      <-"SD_T"
  names(TABELLA)[METEO_RH]        <-"RH"
  names(TABELLA)[METEO_RH_SD]     <-"SD_RH"
  names(TABELLA)[METEO_P]         <-"P"
  names(TABELLA)[METEO_P_SD]      <-"SD_P"

  TABELLA$end_time      <-as.numeric(TABELLA$start_time) + 0.00069444
  TABELLA$code          <-as.character(gsub(" ","",paste("code",sprintf("%.6f",TABELLA$start_time),sep="_")))
  TABELLA$numflag       <- 0
  
  TABELLA               <-TABELLA[,c("code","start_time","end_time","WS","SD_WS","WD","T","SD_T","RH","SD_RH", "P", "SD_P")]
  
  write.table(TABELLA, file=EBAS_temp_FILENAME,row.names=F,col.names = F, append = T, quote = F,sep=" ")
  
} 
TABELLA                 <-read.table(EBAS_temp_FILENAME)
colnames(TABELLA)       <-c("code","start_time","end_time","WS","SD_WS","WD","T","SD_T","RH","SD_RH", "P", "SD_P")
#
# -------------------------------------------------------------------------------------------
# Merging METEO and RAD Data
#
myEBAS <- merge(x = TABELLA[,c("code","start_time","end_time","WS","SD_WS","WD","T","SD_T","RH","SD_RH", "P", "SD_P")], 
                y = RAD_data[,c("ShortW_D","SD_ShortW_D","UVB","SD_UVB", "code")], by = "code", all.x = TRUE)

myEBAS <- myEBAS[order(myEBAS$start_time),]

myEBAS <- myEBAS[,c("start_time","end_time","WS","SD_WS","WD","T","SD_T","RH","SD_RH", "P", "SD_P","ShortW_D","SD_ShortW_D","UVB","SD_UVB")]
#
# -------------------------------------------------------------------------------------------
# Creating numflag columns
#
myEBAS$ws_flag     <-0
myEBAS$wd_flag     <-0
myEBAS$t_flag      <-0
myEBAS$rh_flag     <-0
myEBAS$p_flag      <-0
myEBAS$grad_flag   <-0
#
# -------------------------------------------------------------------------------------------
# Adding date to data sheet
#
jd                <-as.integer(myEBAS$start_time)
day               <-as.Date(as.numeric(myEBAS$start_time), origin=questa_start_time)
time.dec          <-as.numeric(myEBAS$start_time)-jd
time              <-time.dec*1440
hour              <-as.integer(time/60)
min               <-as.integer(time-hour*60)
myEBAS$date       <-paste(day," ",hour,":",min,":00",sep="")
myEBAS$date       <-as.POSIXct(strptime(myEBAS$date, format = "%Y-%m-%d %H:%M:%S", tz = "GMT"))
#
# Calculating radiation difference
#
global_radiation_diff                           <-diff(as.numeric(myEBAS$ShortW_D))
global_radiation_diff[length(myEBAS$ShortW_D)]  <-0
myEBAS$global_radiation_diff                    <-global_radiation_diff
#
# -------------------------------------------------------------------------------------------
# Flagging global radiation invalid values based on diffrence
#
qnt_rs                                          <-quantile(as.numeric(myEBAS$global_radiation_diff), probs=c(.05, .95), na.rm = T)
myEBAS$grad_flag[myEBAS$global_radiation_diff   < qnt_rs[1]]      <- 0.999
myEBAS$grad_flag[myEBAS$global_radiation_diff   > qnt_rs[2]]      <- 0.999
myEBAS$grad_flag[myEBAS$ShortW_D                < -10]            <- 0.999
myEBAS$grad_flag[myEBAS$ShortW_D                > 1600]           <- 0.999
#
# -------------------------------------------------------------------------------------------
# Calculating night time radiation
#
global_radiation_night    <-timeAverage(subset(myEBAS,hour<4 & grad_flag <0.400), 
                                        data.tresh=0,
                                        avg.time = "day",
                                        pollutant="ShortW_D")

global_radiation_night                          <-global_radiation_night[,c("date","ShortW_D")]
names(global_radiation_night)[2]                <-"global_radiation_night"
global_radiation_night$global_radiation_night[1]<-0.00
global_radiation_night$global_radiation_night   <-na.interp(global_radiation_night$global_radiation_night)
#
myEBAS                                          <-merge(myEBAS,global_radiation_night,by = "date", all = TRUE)
myEBAS$global_radiation_night                   <-na.interp(myEBAS$global_radiation_night)
myEBAS$global_radiation_night                   <-as.numeric(myEBAS$global_radiation_night)
#
myEBAS$grad_flag[myEBAS$global_radiation_night  >  50]     <- 0.999
myEBAS$grad_flag[myEBAS$global_radiation_night  < -10]     <- 0.999
#
# -------------------------------------------------------------------------------------------
# Setting up null values
#
myEBAS$WS[is.na(myEBAS$WS)]                     <- 99.9
myEBAS$WD[is.na(myEBAS$WD)]                     <- 999.9  
myEBAS$T[is.na(myEBAS$T)]                       <- 99.9
myEBAS$RH[is.na(myEBAS$RH)]                     <- 999.9
myEBAS$P[is.na(myEBAS$P)]                       <- 9999.9
myEBAS$ShortW_D[is.na(myEBAS$ShortW_D)]         <- 9999.9  
#
# -------------------------------------------------------------------------------------------
# Setting up null values
#
myEBAS$ws_flag[myEBAS$WS > 100]                 <- 0.456000000000
myEBAS$ws_flag[myEBAS$WS < 0]                   <- 0.456000000000
myEBAS$ws_flag[myEBAS$WD > 360]                 <- 0.456000000000  
myEBAS$ws_flag[myEBAS$WD < 0]                   <- 0.456000000000  
myEBAS$t_flag[myEBAS$T > 50]                    <- 0.456000000000  
myEBAS$t_flag[myEBAS$T < -40]                   <- 0.456000000000  
myEBAS$rh_flag[myEBAS$RH > 105]                 <- 0.456000000000
myEBAS$rh_flag[myEBAS$RH < 0.5]                 <- 0.456000000000
myEBAS$p_flag[myEBAS$P > 1100]                  <- 0.456000000000
myEBAS$p_flag[myEBAS$P < 750]                   <- 0.456000000000

myEBAS$p_flag[myEBAS$SD_P >1]                   <- 0.456000000000
myEBAS$t_flag[myEBAS$SD_T >2]                   <- 0.456000000000
myEBAS$rh_flag[myEBAS$SD_RH >5]                 <- 0.456000000000

myEBAS$ws_flag[!is.na(myEBAS$SD_WS) & myEBAS$SD_WS >10]  <- 0.456000000000
myEBAS$ws_flag[!is.na(myEBAS$SD_WD) & myEBAS$SD_WD ==0]  <- 0.456000000000  

myEBAS$grad_flag[myEBAS$global_radiation_diff < qnt_rs[1] | myEBAS$global_radiation_diff > qnt_rs[2]]    <- 0.999000000000  
myEBAS$grad_flag[myEBAS$SD_ShortW_D < -10                 | myEBAS$SD_ShortW_D > 1600]                   <- 0.999000000000   
#
myEBAS            <- myEBAS[c("start_time","end_time"
                              ,"WS","ws_flag"
                              ,"WD","wd_flag"
                              ,"T","t_flag"
                              ,"RH","rh_flag"
                              ,"P","p_flag"
                              ,"ShortW_D","grad_flag"
                              )]
#
# Removing possibile errors and duplicates
#
myEBAS            <-myEBAS[!is.na(myEBAS$start_time),]
myEBAS            <-myEBAS[!duplicated(myEBAS[1]),   ]
#
# -------------------------------------------------------------------------------------------
# Writting the final Data set
# Formatting the output matrix as required by EBAS format Level-0
#
# Set the proper output format
sprintf_formats         <-c(rep("%.6f", 2), "%.1f", "%.9f", "%.1f", "%.9f" , "%.1f", "%.9f" , "%.1f", "%.9f" , "%.1f", "%.9f" , "%.1f", "%.9f")
myEBAS[]                <-mapply(sprintf, sprintf_formats, myEBAS)
#
# Appending Data set to EBAS Level-0 Header
#
write.table(myEBAS, file=EBAS_L0_FULLFILENAME,row.names=F,col.names = F, append = T, quote = F,sep=" ")
# -------------------------------------------------------------------------------------------
# Deleting temporaney files in the destination directory (if present)
# 
FILE_TMP        <-list.files(path = L0_DIR, pattern = glob2rx("temp_*"), all.files = FALSE,
                             full.names = F, recursive = FALSE,
                             ignore.case = FALSE, include.dirs = F, no.. = FALSE)
LISTA_FILE_TMP  <-as.character(FILE_TMP)
LISTA_FILE_TMP
for(f in LISTA_FILE_TMP) { file.remove(paste(L0_DIR,f,sep = "/")) }
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
                                 "WS",
                                 "WD",
                                 "T" ,
                                 "RH",
                                 "P" ,
                                 "ShortW_D")]
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
  
  if (file.exists(ULTIMO_DATO_PNG)){} 
  else {
    png(file = ULTIMO_DATO_PNG,width=10000,height=15000,res=1000)
    timePlot(THISREPORTTAB,pollutant=c("WS",
                                       "WD",
                                       "T" ,
                                       "RH",
                                       "P" ,
                                       "ShortW_D"
    ),cex=25,date.breaks=15, y.relation="free", key = FALSE, fontsize = 14)
    dev.off()
  }
}

##                                          # END PART 3.0 #
###########################################################################################################################
#                                                                                                                         #
## End of MET_P20_1810.R                                                                                                  # 
#                                                                                                                         # 
###################################################################################### Authors: L u C A, Davide ###########

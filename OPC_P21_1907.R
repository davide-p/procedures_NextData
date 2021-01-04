###########################################################################################################################
## Project: NEXTDATA                                                                                                     ##
## Parameter: OPC                                                                                                        ##
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
## Script filename: OPC_D21_1810.R                                                                                       ##
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
CALIB_DIR       = '../naitza/NEXTDATA/PROD/CIMONE/AEROSOL/OPC-GRIMM/RAW_DATA_UTC/CALIB'           
RAW_DIR         = '../naitza/NEXTDATA/PROD/CIMONE/AEROSOL/OPC-GRIMM/RAW_DATA_UTC'
METEO_RAW_DIR   = '../naitza/NEXTDATA/PROD/CIMONE/AEROSOL/NEPH/RAW_DATA_UTC'
#
# -------- DATA DESTINATION PATH --------------------------------------------------------------# REPLACE THE FOLLOWING PATHS
L0_DIR          = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/AEROSOL/OPC-GRIMM/LEVEL_0'                     
L1_DIR          = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/AEROSOL/OPC-GRIMM/LEVEL_1' 
L2_DIR          = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/AEROSOL/OPC-GRIMM/LEVEL_2'
L0_ANCIL_DIR    = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/AEROSOL/OPC-GRIMM/LEVEL_0/ANCILLARY'
#
# -------- GRAPH DESTINATION PATH -------------------------------------------------------------# REPLACE THE FOLLOWING PATHS
REP_DIR         = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/AEROSOL/OPC-GRIMM/REPORT'
REP_GRAPH_DIR   = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/AEROSOL/OPC-GRIMM/REPORT/DAILY_GRAPH'
PLOT_DIR_M      = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/AEROSOL/OPC-GRIMM/REPORT/MONTHLY_GRAPH'
PLOT_DIR_S      = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/AEROSOL/OPC-GRIMM/REPORT/SEASONAL_GRAPH'
PLOT_DIR_Y      = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/AEROSOL/OPC-GRIMM/REPORT/ANNUAL_GRAPH'
PLOT_DIR_Y_PDF  = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/AEROSOL/OPC-GRIMM/REPORT/ANNUAL_GRAPH/PDF'
PLOT_DIR_T      = '../naitza/NEXTDATA/DISTRIBUTION_DIR/CIMONE/AEROSOL/OPC-GRIMM/REPORT/TIMEVARIATION_GRAPH' 
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

inst_type               <- "optical_particle_size_spectrometer"              # replace the value with your instrument type
inst_manu               <- "GRIMM"                                           # replace the value with your instrument manufacter
inst_modl               <- "1108"                                            # replace the value with your instrument model
inst_name               <- ""                                                # replace the value with your your instrument name
inst_s_n                <- ""                                                # replace the value with your instrument serial number

dependent_col           <- "50"                                              # replace the value with the total number of columns of the file in addition to start_time (i.e., total-1)

component               <- "particle_number_size_distribution"               # replace the value with proper component 
matrix                  <- "aerosol"                                         # replace the value with proper matrix
meas_unit               <- "1/cm3"                                           # replace the value with proper measurement unit

meas_lat                <- "44.16667"                                        # replace the value with the your Measure latitude
meas_lon                <- "10.68333"                                        # replace the value with the your Measure longitude
meas_alt                <- "2165m"                                           # replace the value with the your Measure altitude (meters)

Period_code             <- "1y"                                              # replace the value with the proper Period code
Resolution_code         <- "1mn"                                             # replace the value with the proper Resolution code
Sample_duration         <- "1mn"                                             # replace the value with the proper Sample duration
Orig_time_res           <- "1mn"                                             # replace the value with the proper Original time resolution

height_AGL              <- "10m"                                             # replace the value with Height AGL
inlet_type              <- "Hat or hood"                                     # replace the value with Inlet type
inlet_desc              <- "Total particle size at ambient humidity inlet,heated head, home made followinfg EUSAAR design, flow 150 l/min"    # replace the value with Inlet description
hum_temp_c              <- "heating"                                         # replace the value with Humidity/temperature control
hum_temp_c_desc         <- "passive, sample heated from atmospheric to lab temperature"        # replace the value with Humidity/temperature control description
vol_std_t               <- "ambient"                                         # replace the value with Volume std. temperature
vol_std_p               <- "ambient"                                         # replace the value with Volume std. pressure
detec_lim               <- "0 1/cm3"                                         # replace the value with Detection limit
detec_lim_ex            <- "Determined by instrument noise characteristics, no detection limit flag used"      # replace the value with Detection limit expl.
meas_uncr               <- "0 1/cm3"                                         # replace the value with Measurement uncertainty
meas_uncr_ex            <- "typical value of unit-to-unit variability"       # replace the value with Measurement uncertainty expl.
zero_val_code           <- "Zero possible"                                   # replace the value with Zero/negative values code
zero_val                <- "Zero values may appear due to statistical variations at very low concentrations"  # replace the value with Zero/negative values
std_meth                <- "None"                                            # replace the value with Standard method
qa_mes_id               <- "AP-2016-1-6 "                                    # replace the value with QA measure ID
qa_date                 <- "20160625"                                        # replace the value with QA date
qa_doc                  <- "http://www.actris-ecac.eu/files/ECAC-report-AP-2016-1-6_Institute-for-Atmospheric-Science-and-Climate_MAAP-80.pdf" # replace the value with QA document URL

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

Submit_1_n              <- "Angela"      
Submit_1_s              <- "Marinoni"
Submit_1_e              <- "a.marinoni@isac.cnr.it"
Submit_1_i              <- "Institute of Atmospheric Sciences and Climate, ISAC,, Via P. Gobetti 101,, I-40129, Bologna, Italy"

mycomment               <- "P, T and RH are taken from co-located nephelometer"
#
# Setting the lines of the header
# 
if (nchar(Origin_2_n) == 0 && nchar(Origin_3_n) == 0 && nchar(Origin_4_n) == 0 && nchar(Origin_5_n) == 0)  { L1_n_lines <- 125 + 0 ; L2_n_lines <- 125 + 0 ; }
if (nchar(Origin_2_n)  > 0 && nchar(Origin_3_n) == 0 && nchar(Origin_4_n) == 0 && nchar(Origin_5_n) == 0)  { L1_n_lines <- 125 + 1 ; L2_n_lines <- 125 + 1 ; }
if (nchar(Origin_2_n)  > 0 && nchar(Origin_3_n)  > 0 && nchar(Origin_4_n) == 0 && nchar(Origin_5_n) == 0)  { L1_n_lines <- 125 + 2 ; L2_n_lines <- 125 + 2 ; }
if (nchar(Origin_2_n)  > 0 && nchar(Origin_3_n)  > 0 && nchar(Origin_4_n)  > 0 && nchar(Origin_5_n) == 0)  { L1_n_lines <- 125 + 3 ; L2_n_lines <- 125 + 3 ; }
if (nchar(Origin_2_n)  > 0 && nchar(Origin_3_n)  > 0 && nchar(Origin_4_n)  > 0 && nchar(Origin_5_n)  > 0)  { L1_n_lines <- 125 + 4 ; L2_n_lines <- 125 + 4 ; }
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
old_date              <-substr(LISTA, 23, 37)
EBAS_L1_FILENAME      <-gsub("lev0","lev1",gsub(old_date,new_date_name,LISTA))
EBAS_L1_FULLFILENAME  <-paste(L1_DIR,EBAS_L1_FILENAME,sep = "/")
EBAS_L2_FILENAME      <-gsub("lev0","lev2",gsub("1mn","1h",gsub(old_date,new_date_name,LISTA)))
EBAS_L2_FULLFILENAME  <-paste(L2_DIR,EBAS_L2_FILENAME,sep = "/")

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
"1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
999.999999 9999.9 9999.9 9999.9 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 9.999999999999
end_time of measurement, days from the file reference point
pressure, hPa, Location=instrument internal, Matrix=instrument, Detection limit=, Detection limit expl.=, Measurement uncertainty=
relative_humidity, %, Location=instrument internal, Matrix=instrument, Detection limit=, Detection limit expl.=, Measurement uncertainty=
temperature, K, Location=instrument internal, Matrix=instrument, Detection limit=, Detection limit expl.=, Measurement uncertainty=
particle_number_size_distribution, 1/cm3, D=346.0 nm, Statistics=arithmetic mean
particle_number_size_distribution, 1/cm3, D=346.0 nm, Statistics=percentile:15.87 
particle_number_size_distribution, 1/cm3, D=346.0 nm, Statistics=percentile:84.13 
particle_number_size_distribution, 1/cm3, D=447.0 nm, Statistics=arithmetic mean
particle_number_size_distribution, 1/cm3, D=447.0 nm, Statistics=percentile:15.87 
particle_number_size_distribution, 1/cm3, D=447.0 nm, Statistics=percentile:84.13 
particle_number_size_distribution, 1/cm3, D=570.0 nm, Statistics=arithmetic mean
particle_number_size_distribution, 1/cm3, D=570.0 nm, Statistics=percentile:15.87 
particle_number_size_distribution, 1/cm3, D=570.0 nm, Statistics=percentile:84.13 
particle_number_size_distribution, 1/cm3, D=721.0 nm, Statistics=arithmetic mean
particle_number_size_distribution, 1/cm3, D=721.0 nm, Statistics=percentile:15.87 
particle_number_size_distribution, 1/cm3, D=721.0 nm, Statistics=percentile:84.13 
particle_number_size_distribution, 1/cm3, D=894.0 nm, Statistics=arithmetic mean
particle_number_size_distribution, 1/cm3, D=894.0 nm, Statistics=percentile:15.87 
particle_number_size_distribution, 1/cm3, D=894.0 nm, Statistics=percentile:84.13 
particle_number_size_distribution, 1/cm3, D=1265.0 nm, Statistics=arithmetic mean
particle_number_size_distribution, 1/cm3, D=1265.0 nm, Statistics=percentile:15.87 
particle_number_size_distribution, 1/cm3, D=1265.0 nm, Statistics=percentile:84.13 
particle_number_size_distribution, 1/cm3, D=1789.0 nm, Statistics=arithmetic mean
particle_number_size_distribution, 1/cm3, D=1789.0 nm, Statistics=percentile:15.87 
particle_number_size_distribution, 1/cm3, D=1789.0 nm, Statistics=percentile:84.13 
particle_number_size_distribution, 1/cm3, D=2450.0 nm, Statistics=arithmetic mean
particle_number_size_distribution, 1/cm3, D=2450.0 nm, Statistics=percentile:15.87 
particle_number_size_distribution, 1/cm3, D=2450.0 nm, Statistics=percentile:84.13 
particle_number_size_distribution, 1/cm3, D=3464.0 nm, Statistics=arithmetic mean
particle_number_size_distribution, 1/cm3, D=3464.0 nm, Statistics=percentile:15.87 
particle_number_size_distribution, 1/cm3, D=3464.0 nm, Statistics=percentile:84.13 
particle_number_size_distribution, 1/cm3, D=4472.0 nm, Statistics=arithmetic mean
particle_number_size_distribution, 1/cm3, D=4472.0 nm, Statistics=percentile:15.87 
particle_number_size_distribution, 1/cm3, D=4472.0 nm, Statistics=percentile:84.13 
particle_number_size_distribution, 1/cm3, D=6124.0 nm, Statistics=arithmetic mean
particle_number_size_distribution, 1/cm3, D=6124.0 nm, Statistics=percentile:15.87 
particle_number_size_distribution, 1/cm3, D=6124.0 nm, Statistics=percentile:84.13 
particle_number_size_distribution, 1/cm3, D=8660.0 nm, Statistics=arithmetic mean
particle_number_size_distribution, 1/cm3, D=8660.0 nm, Statistics=percentile:15.87 
particle_number_size_distribution, 1/cm3, D=8660.0 nm, Statistics=percentile:84.13 
particle_number_size_distribution, 1/cm3, D=12247.0 nm, Statistics=arithmetic mean
particle_number_size_distribution, 1/cm3, D=12247.0 nm, Statistics=percentile:15.87 
particle_number_size_distribution, 1/cm3, D=12247.0 nm, Statistics=percentile:84.13 
particle_number_size_distribution, 1/cm3, D=17320.0 nm, Statistics=arithmetic mean
particle_number_size_distribution, 1/cm3, D=17320.0 nm, Statistics=percentile:15.87 
particle_number_size_distribution, 1/cm3, D=17320.0 nm, Statistics=percentile:84.13 
particle_number_size_distribution, 1/cm3, D=21448.0 nm, Statistics=arithmetic mean
particle_number_size_distribution, 1/cm3, D=21448.0 nm, Statistics=percentile:15.87 
particle_number_size_distribution, 1/cm3, D=21448.0 nm, Statistics=percentile:84.13 
numflag
0",
(L1_n_lines - 63),
"Data definition:                  EBAS_1.1
Data level:                       1
Version:                          1
Version description:              initial revision
Set type code:                    TU",
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
paste("Instrument name:                  ",paste(inst_manu,inst_modl,s_GAW_ID,sep = "_"),sep=""),
paste("Instrument serial number:         ",inst_s_n,sep=""),
paste("Method ref:                       ",paste(lab_code,inst_type,"acquisition_lev1",sep = "_"),sep=""),
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
paste("start_time","end_time","p_sys","RH","T_sys","bin_01","bin_02","bin_03","bin_04","bin_05","bin_06",
      "bin_07","bin_08","bin_09","bin_10","bin_11","bin_12","bin_13","bin_14","bin_15","fine","coarse","numflag"),

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
temp_data               <- read.table(paste(L0_DIR,LISTA,sep = "/"),skip = L0_n_lines-1, header = T,fill = T)
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
temp_data$date          <-as.POSIXct(strptime(temp_data$date, format = "%Y-%m-%d %H:%M:%S", tz = "GMT"))
#
# -------------------------------------------------------------------------------------------
# Padding data from January 1st to today
#
temp_data <- pad(temp_data, 
                 start_val = as.POSIXct(paste(questa_start_time," 00:00:00")), 
                 end_val = tail(temp_data$date,1), 
                 interval = "min", by = "date")
#
# -------------------------------------------------------------------------------------------
# Converting values to STP (i.e., 1013 hPa, 273.15 K)
#
stp_convert             <- function(param,p,t){
              param_stp <- param*(1013/p)*(t/273.15) 
              return(param_stp)
              }
p_stp                   <- temp_data$p_sys
T_stp                   <- temp_data$T_sys
p_stp[p_stp == 9999.9]  <- mean(subset(temp_data$p_sys, temp_data$p_sys != 9999.9))
T_stp[T_stp == 9999.9]  <- mean(subset(temp_data$T_sys, temp_data$T_sys != 9999.9))
old_ncol <- ncol(temp_data) # Number of columns before the calculation
for (k in 1:15){
  temp_data[, old_ncol + k] <- stp_convert(temp_data[[paste0("bin_",str_pad(k,2,pad = "0"))]], p_stp, T_stp)
  names(temp_data)[old_ncol + k] <- paste0("bin_",str_pad(k,2,pad = "0"),"stp")
}
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
# Retrieving valid or not numflags and setting the invalid values to NA
#
temp_data$calc          <- temp_data$concstp
temp_data$nf_validity   <- sapply(temp_data$numflag, nf_val_check, tab_nf$numflag, tab_nf$category)
temp_data$calc[temp_data$nf_validity != "V"] <- NA
#
# -------------------------------------------------------------------------------------------
# Calculating running mean and sd
#
time_frame              <- 60*24*3
temp_data$nf_validity   <- sapply(temp_data$numflag, nf_val_check, tab_nf$numflag, tab_nf$category)
temp_data$fine_calc     <- temp_data$fine
temp_data$coarse_calc   <- temp_data$coarse
temp_data$fine_calc     [temp_data$nf_validity != "V"]   <- NA
temp_data$coarse_calc   [temp_data$nf_validity != "V"]   <- NA
temp_data$fine_mean     <- runmean(temp_data$fine_calc,   time_frame, align = "center", endrule = "mean")
temp_data$fine_sd       <- runsd(temp_data$fine_calc,     time_frame, align = "center", endrule = "sd")
temp_data$coarse_mean   <- runmean(temp_data$coarse_calc, time_frame, align = "center", endrule = "mean")
temp_data$coarse_sd     <- runsd(temp_data$coarse_calc,   time_frame, align = "center", endrule = "sd")
#
temp_data$nf_bad_fine   <- 0 
for (i in 1:length(temp_data$date)){
  if (!is.na(temp_data$fine_calc[i]) & (abs((temp_data$fine_calc[i]-temp_data$fine_mean[i])) > 7*temp_data$fine_sd[i])){
    temp_data$nf_bad_fine[i] <- 1
  }
}
temp_data$nf_bad_coarse <- 0
for (i in 1:length(temp_data$date)){
  if (!is.na(temp_data$coarse_calc[i]) & (abs((temp_data$coarse_calc[i]-temp_data$coarse_mean[i])) > 7*temp_data$coarse_sd[i])){
    temp_data$nf_bad_coarse[i] <- 1
  }
}
#
# -------------------------------------------------------------------------------------------
# Setting numflag codes to invalid and special cases
#
temp_data$p_sys     [is.na(temp_data$p_sys)]          <- 9999.9
temp_data$T_sys     [is.na(temp_data$T_sys)]          <- 9999.9
temp_data$RH        [is.na(temp_data$RH)]             <- 9999.9
temp_data$bin_01 [is.na(temp_data$bin_01)]      <- 999.99
temp_data$bin_02 [is.na(temp_data$bin_02)]      <- 999.99
temp_data$bin_03 [is.na(temp_data$bin_03)]      <- 999.99
temp_data$bin_04 [is.na(temp_data$bin_04)]      <- 999.99
temp_data$bin_05 [is.na(temp_data$bin_05)]      <- 999.99
temp_data$bin_06 [is.na(temp_data$bin_06)]      <- 999.99
temp_data$bin_07 [is.na(temp_data$bin_07)]      <- 999.99
temp_data$bin_08 [is.na(temp_data$bin_08)]      <- 999.99
temp_data$bin_09 [is.na(temp_data$bin_09)]      <- 999.99
temp_data$bin_10 [is.na(temp_data$bin_10)]      <- 999.99
temp_data$bin_11 [is.na(temp_data$bin_11)]      <- 999.99
temp_data$bin_12 [is.na(temp_data$bin_12)]      <- 999.99
temp_data$bin_13 [is.na(temp_data$bin_13)]      <- 999.99
temp_data$bin_14 [is.na(temp_data$bin_14)]      <- 999.99
temp_data$bin_15 [is.na(temp_data$bin_15)]      <- 999.99
temp_data$fine      [is.na(temp_data$fine)]           <- 999.99
temp_data$coarse    [is.na(temp_data$coarse)]         <- 999.99
temp_data$numflag   [is.na(temp_data$numflag)]        <- 0.999
#
# Setting specific codes to specific cases
if (length(temp_data$numflag[temp_data$p_sys == 9999.99]) > 0){
  temp_data$numflag[temp_data$p_sys == 9999.99] <- sapply(temp_data$numflag[temp_data$p_sys == 9999.99],
                                                          nf_aggreg, nf_new = 0.798)
}
#
if (length(temp_data$numflag[temp_data$nf_bad == 1]) > 0){
  temp_data$numflag[temp_data$nf_bad == 1]      <- sapply(temp_data$numflag[temp_data$nf_bad == 1],
                                                          nf_aggreg, nf_new = 0.456)
}
#
if (length(temp_data$numflag[temp_data$fine == 999.99]) > 0){
  temp_data$numflag[temp_data$fine == 999.99]   <- 0.999    
}
#
# -------------------------------------------------------------------------------------------
# Writing the final Data set
# Formatting the output matrix as required by EBAS format Level-1
#
myEBAS                  <- temp_data[,c("start_time","end_time","p_sys","RH","T_sys","bin_01","bin_02","bin_03","bin_04","bin_05","bin_06",
                                        "bin_07","bin_08","bin_09","bin_10","bin_11","bin_12","bin_13","bin_14","bin_15","fine","coarse","numflag")]
#
sprintf_formats         <- c(rep("%.6f", 2), rep("%.1f", 3), rep("%.2f", 17), "%.12f")
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
50
1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
999.999999 9999.9 9999.9 9999.9 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 999.99 9.999999999999
end_time of measurement, days from the file reference point
pressure, hPa, Location=instrument internal, Matrix=instrument, Detection limit=, Detection limit expl.=, Measurement uncertainty=
relative_humidity, %, Location=instrument internal, Matrix=instrument, Detection limit=, Detection limit expl.=, Measurement uncertainty=
temperature, K, Location=instrument internal, Matrix=instrument, Detection limit=, Detection limit expl.=, Measurement uncertainty=
particle_number_size_distribution, 1/cm3, D=346.0 nm, Statistics=arithmetic mean
particle_number_size_distribution, 1/cm3, D=346.0 nm, Statistics=percentile:15.87 
particle_number_size_distribution, 1/cm3, D=346.0 nm, Statistics=percentile:84.13 
particle_number_size_distribution, 1/cm3, D=447.0 nm, Statistics=arithmetic mean
particle_number_size_distribution, 1/cm3, D=447.0 nm, Statistics=percentile:15.87 
particle_number_size_distribution, 1/cm3, D=447.0 nm, Statistics=percentile:84.13 
particle_number_size_distribution, 1/cm3, D=570.0 nm, Statistics=arithmetic mean
particle_number_size_distribution, 1/cm3, D=570.0 nm, Statistics=percentile:15.87 
particle_number_size_distribution, 1/cm3, D=570.0 nm, Statistics=percentile:84.13 
particle_number_size_distribution, 1/cm3, D=721.0 nm, Statistics=arithmetic mean
particle_number_size_distribution, 1/cm3, D=721.0 nm, Statistics=percentile:15.87 
particle_number_size_distribution, 1/cm3, D=721.0 nm, Statistics=percentile:84.13 
particle_number_size_distribution, 1/cm3, D=894.0 nm, Statistics=arithmetic mean
particle_number_size_distribution, 1/cm3, D=894.0 nm, Statistics=percentile:15.87 
particle_number_size_distribution, 1/cm3, D=894.0 nm, Statistics=percentile:84.13 
particle_number_size_distribution, 1/cm3, D=1265.0 nm, Statistics=arithmetic mean
particle_number_size_distribution, 1/cm3, D=1265.0 nm, Statistics=percentile:15.87 
particle_number_size_distribution, 1/cm3, D=1265.0 nm, Statistics=percentile:84.13 
particle_number_size_distribution, 1/cm3, D=1789.0 nm, Statistics=arithmetic mean
particle_number_size_distribution, 1/cm3, D=1789.0 nm, Statistics=percentile:15.87 
particle_number_size_distribution, 1/cm3, D=1789.0 nm, Statistics=percentile:84.13 
particle_number_size_distribution, 1/cm3, D=2450.0 nm, Statistics=arithmetic mean
particle_number_size_distribution, 1/cm3, D=2450.0 nm, Statistics=percentile:15.87 
particle_number_size_distribution, 1/cm3, D=2450.0 nm, Statistics=percentile:84.13 
particle_number_size_distribution, 1/cm3, D=3464.0 nm, Statistics=arithmetic mean
particle_number_size_distribution, 1/cm3, D=3464.0 nm, Statistics=percentile:15.87 
particle_number_size_distribution, 1/cm3, D=3464.0 nm, Statistics=percentile:84.13 
particle_number_size_distribution, 1/cm3, D=4472.0 nm, Statistics=arithmetic mean
particle_number_size_distribution, 1/cm3, D=4472.0 nm, Statistics=percentile:15.87 
particle_number_size_distribution, 1/cm3, D=4472.0 nm, Statistics=percentile:84.13 
particle_number_size_distribution, 1/cm3, D=6124.0 nm, Statistics=arithmetic mean
particle_number_size_distribution, 1/cm3, D=6124.0 nm, Statistics=percentile:15.87 
particle_number_size_distribution, 1/cm3, D=6124.0 nm, Statistics=percentile:84.13 
particle_number_size_distribution, 1/cm3, D=8660.0 nm, Statistics=arithmetic mean
particle_number_size_distribution, 1/cm3, D=8660.0 nm, Statistics=percentile:15.87 
particle_number_size_distribution, 1/cm3, D=8660.0 nm, Statistics=percentile:84.13 
particle_number_size_distribution, 1/cm3, D=12247.0 nm, Statistics=arithmetic mean
particle_number_size_distribution, 1/cm3, D=12247.0 nm, Statistics=percentile:15.87 
particle_number_size_distribution, 1/cm3, D=12247.0 nm, Statistics=percentile:84.13 
particle_number_size_distribution, 1/cm3, D=17320.0 nm, Statistics=arithmetic mean
particle_number_size_distribution, 1/cm3, D=17320.0 nm, Statistics=percentile:15.87 
particle_number_size_distribution, 1/cm3, D=17320.0 nm, Statistics=percentile:84.13 
particle_number_size_distribution, 1/cm3, D=21448.0 nm, Statistics=arithmetic mean
particle_number_size_distribution, 1/cm3, D=21448.0 nm, Statistics=percentile:15.87 
particle_number_size_distribution, 1/cm3, D=21448.0 nm, Statistics=percentile:84.13 
numflag
0",
(L2_n_lines - 64),
"Data definition:                  EBAS_1.1
Data level:                       2
Version:                          1
Version description:              initial revision
Set type code:                    TU",
paste("Station code:                     ",s_code,sep=""),
paste("Platform code:                   ",gsub("R","S",s_code)),
"Timezone:                         UTC",
paste("Startdate:                        ",questo_inizioanno[1],sep=""),  
paste("Revision date:                    ",as.numeric(new_date)-7200,sep=""),
paste("Component:                        ",component,sep=""), 
paste("Matrix:                           ",matrix,sep=""), 
paste("Unit:                             ",meas_unit,sep=""),
paste("Period code:                      ","1y",sep=""), 
paste("Resolution code:                  ","1h",sep=""), 
paste("Sample duration:                  ","1h",sep=""), 
paste("Orig. time res.:                  ",Orig_time_res,sep=""),
paste("Laboratory code:                  ",lab_code,sep=""),
paste("Instrument type:                  ",inst_type,sep=""),
paste("Instrument manufacturer:          ",inst_manu,sep=""), 
paste("Instrument model:                 ",inst_modl,sep=""),
paste("Instrument name:                  ",paste(inst_manu,inst_modl,s_GAW_ID,sep = "_"),sep=""),
paste("Instrument serial number:         ",inst_s_n,sep=""),
paste("Method ref:                       ","NO01L_scat_coef",sep=""),
paste("File name:                        ",EBAS_L2_FILENAME,sep=""),
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
paste("Measurement uncertainty:          ","5.0 %",sep=""),
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
paste("start_time","end_time","p_sys","RH","T_sys","bin_01","bn01pc16","bn01pc84",
      "bin_02","bn02pc16","bn02pc84","bin_03","bn03pc16","bn03pc84","bin_04","bn04pc16","bn04pc84",
      "bin_05","bn05pc16","bn05pc84","bin_06","bn06pc16","bn06pc84","bin_07","bn07pc16","bn07pc84",
      "bin_08","bn08pc16","bn08pc84","bin_09","bn09pc16","bn09pc84","bin_10","bn10pc16","bn10pc84",
      "bin_11","bn11pc16","bn11pc84","bin_12","bn12pc16","bn12pc84","bin_13","bn13pc16","bn13pc84",
      "bin_14","bn14pc16","bn14pc84","bin_15","bn15pc16","bn15pc84","numflag"),

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
# Checking valid and invalid data
# Preparing Level-2 data
# 
temp_data$nf_validity   <- sapply(temp_data$numflag, nf_val_check, tab_nf$numflag, tab_nf$category)
temp_data_sub           <- subset(temp_data, temp_data$nf_validity == "V", 
                                  select=c("p_sys","RH","T_sys","bin_01","bin_02","bin_03","bin_04","bin_05",
                                           "bin_06","bin_07","bin_08","bin_09","bin_10","bin_11","bin_12",
                                           "bin_13","bin_14","bin_15","numflag","date"))
#
# Setting NA to invalid data
# -------------------------------------------------------------------------------------------
# 
temp_data_sub$p_sys[temp_data_sub$p_sys == 9999.9]  <- NA
temp_data_sub$RH   [temp_data_sub$RH    == 999.9 ]  <- NA
temp_data_sub$T_sys[temp_data_sub$T_sys == 9999.9]  <- NA

temp_data_sub$numflag <- as.numeric(temp_data_sub$numflag)

#
# Calculating 1h data averages
# -------------------------------------------------------------------------------------------
# 
# Calculating last observed day (not necessarily the last acquisition day)
#
final_time              <-as.POSIXct(ISOdatetime(questo_anno,questo_mese,questo_giorno,23,59,0), tz = "UTC")  - 60*60*24 
#
# -------------------------------------------------------------------------------------------
# Calculating 1h data averages
#
lev2_OPC_avg            <- timeAverage(temp_data_sub, avg.time = "hour", statistic = "mean",
                                       start.date = questo_capodanno, 
                                       end.date   = as.character(final_time))
lev2_OPC_perc16         <- timeAverage(temp_data_sub, avg.time = "hour", statistic = "percentile",
                                       percentile = 15.87, 
                                       start.date = questo_capodanno, 
                                       end.date   = as.character(final_time))
lev2_OPC_perc84         <- timeAverage(temp_data_sub, avg.time = "hour", statistic = "percentile",
                                       percentile = 84.13, 
                                       start.date = questo_capodanno,  
                                       end.date   = as.character(final_time))
lev2_OPC_n              <- timeAverage(temp_data_sub, avg.time = "hour", statistic = "frequency",
                                       start.date = questo_capodanno,  
                                       end.date   = as.character(final_time))
#
# -------------------------------------------------------------------------------------------
# Calculating JD from date
#
jd                      <- strptime(lev2_OPC_avg$date, "%Y-%m-%d %H:%M")$yday
h                       <- strptime(lev2_OPC_avg$date, "%Y-%m-%d %H:%M")$hour
time                    <- h*60
time.dec                <- time/1440
lev2_OPC_avg$start_time <-jd+time.dec
lev2_OPC_avg$end_time   <-lev2_OPC_avg$start_time+1/24
#
# Formatting the EBAS format Level-2 matrix
#
EBAS_lev2_OPC <- data.frame(cbind(lev2_OPC_avg$start_time,lev2_OPC_avg$end_time,
                                  lev2_OPC_avg$p_sys,lev2_OPC_avg$RH,lev2_OPC_avg$T_sys,
                                  lev2_OPC_avg$bin_01,lev2_OPC_perc16$bin_01,lev2_OPC_perc84$bin_01,
                                  lev2_OPC_avg$bin_02,lev2_OPC_perc16$bin_02,lev2_OPC_perc84$bin_02,
                                  lev2_OPC_avg$bin_03,lev2_OPC_perc16$bin_03,lev2_OPC_perc84$bin_03,
                                  lev2_OPC_avg$bin_04,lev2_OPC_perc16$bin_04,lev2_OPC_perc84$bin_04,
                                  lev2_OPC_avg$bin_05,lev2_OPC_perc16$bin_05,lev2_OPC_perc84$bin_05,
                                  lev2_OPC_avg$bin_06,lev2_OPC_perc16$bin_06,lev2_OPC_perc84$bin_06,
                                  lev2_OPC_avg$bin_07,lev2_OPC_perc16$bin_07,lev2_OPC_perc84$bin_07,
                                  lev2_OPC_avg$bin_08,lev2_OPC_perc16$bin_08,lev2_OPC_perc84$bin_08,
                                  lev2_OPC_avg$bin_09,lev2_OPC_perc16$bin_09,lev2_OPC_perc84$bin_09,
                                  lev2_OPC_avg$bin_10,lev2_OPC_perc16$bin_10,lev2_OPC_perc84$bin_10,
                                  lev2_OPC_avg$bin_11,lev2_OPC_perc16$bin_11,lev2_OPC_perc84$bin_11,
                                  lev2_OPC_avg$bin_12,lev2_OPC_perc16$bin_12,lev2_OPC_perc84$bin_12,
                                  lev2_OPC_avg$bin_13,lev2_OPC_perc16$bin_13,lev2_OPC_perc84$bin_13,
                                  lev2_OPC_avg$bin_14,lev2_OPC_perc16$bin_14,lev2_OPC_perc84$bin_14,
                                  lev2_OPC_avg$bin_15,lev2_OPC_perc16$bin_15,lev2_OPC_perc84$bin_15))
colnames(EBAS_lev2_OPC)       <-c("start_time","end_time","p_sys","RH","T_sys","bin_01","bn01pc16","bn01pc84",
                                  "bin_02","bn02pc16","bn02pc84","bin_03","bn03pc16","bn03pc84","bin_04","bn04pc16","bn04pc84",
                                  "bin_05","bn05pc16","bn05pc84","bin_06","bn06pc16","bn06pc84","bin_07","bn07pc16","bn07pc84",
                                  "bin_08","bn08pc16","bn08pc84","bin_09","bn09pc16","bn09pc84","bin_10","bn10pc16","bn10pc84",
                                  "bin_11","bn11pc16","bn11pc84","bin_12","bn12pc16","bn12pc84","bin_13","bn13pc16","bn13pc84",
                                  "bin_14","bn14pc16","bn14pc84","bin_15","bn15pc16","bn15pc84")
#
# -------------------------------------------------------------------------------------------
# Setting NAs data and flagging data
#
EBAS_lev2_OPC$p_sys       [is.na(EBAS_lev2_OPC$p_sys)]      <- 9999.9
EBAS_lev2_OPC$RH          [is.na(EBAS_lev2_OPC$RH)]         <- 999.9
EBAS_lev2_OPC$T_sys       [is.na(EBAS_lev2_OPC$T_sys)]      <- 9999.9
EBAS_lev2_OPC[,c(6:50)]   [is.na(EBAS_lev2_OPC[,c(6:50)])]  <- 999.99

bad_numflags              <- c("000",as.character(tab_nf$numflag[tab_nf$category != "V"])) 
EBAS_lev2_OPC$numflag     <- sapply(EBAS_lev2_OPC$start_time, 
                                  nf_lev2, 
                                  numflags_mm=myEBAS$numflag, 
                                  startime_mm=myEBAS$start_time,
                                  nv_numflags=bad_numflags)

EBAS_lev2_OPC$numflag     [!is.na(lev2_OPC_n$bin_01) &
                            lev2_OPC_n$bin_01 >= 30 & 
                            lev2_OPC_n$bin_01 < 45] <- sapply(EBAS_lev2_OPC$numflag [!is.na(lev2_OPC_n$bin_01) &
                                                                                    lev2_OPC_n$bin_01 >= 30 & 
                                                                                    lev2_OPC_n$bin_01 < 45],
                                                           nf_aggreg, nf_new = 0.392)
EBAS_lev2_OPC$numflag     [!is.na(lev2_OPC_n$bin_01) & 
                            lev2_OPC_n$bin_01 < 30] <- sapply(EBAS_lev2_OPC$numflag [!is.na(lev2_OPC_n$bin_01) & 
                                                                                    lev2_OPC_n$bin_01 < 30],
                                                           nf_aggreg, nf_new = 0.390) 

EBAS_lev2_OPC$numflag     [EBAS_lev2_OPC$bin_01 == 999.99]   <- 0.999 
#
# -------------------------------------------------------------------------------------------
# Writing the final Level-2 Data set
# Formatting the output matrix as required by EBAS format Level-2
# Appending Data set to EBAS Level-2 Header
#
sprintf_formats_l2 <- c(rep("%.6f", 2), rep("%.1f", 3), rep("%.2f", 45), "%.12f")
#
EBAS_lev2_OPC[] <- mapply(sprintf, sprintf_formats_l2, EBAS_lev2_OPC)
#
write.table(EBAS_lev2_OPC, file=EBAS_L2_FULLFILENAME,row.names=F,col.names = F, append = T, quote = F,sep=" ")
#
# -------------------------------------------------------------------------------------------
##                                          # END PART 2.3 #
###########################################################################################################################
#                                                                                                                         #
## End of OPC_D21_1810.R                                                                                                  # 
#                                                                                                                         # 
###################################################################################### Authors: L u C A, Davide ###########

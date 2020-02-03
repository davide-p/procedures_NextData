###########################################################################################################################
## Project: NEXTDATA                                                                                                     ##
## Parameter: NEPH                                                                                                       ##
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
## Script filename: NEPH_P21_1810.R                                                                                      ##
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
CALIB_DIR       = '../naitza/NEXTDATA/PROD/CIMONE/AEROSOL/NEPH/RAW_DATA_UTC/CALIB'           
RAW_DIR         = '../naitza/NEXTDATA/PROD/CIMONE/AEROSOL/NEPH/RAW_DATA_UTC'
METEO_RAW_DIR   = '../naitza/NEXTDATA/PROD/CIMONE/AEROSOL/NEPH/RAW_DATA_UTC'
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

inst_type               <- "nephelometer"                                    # replace the value with your instrument type
inst_manu               <- "TSI"                                             # replace the value with your instrument manufacter
inst_modl               <- "3563"                                            # replace the value with your instrument model
inst_name               <- "TSI_3563_3563133901"                             # replace the value with your your instrument name
inst_s_n                <- "3563133901"                                      # replace the value with your instrument serial number
meth_ref                <- "NO01L_scat_coef"                                 # replace the value with method reference

dependent_col           <- "11"                                              # replace the value with the total number of columns of the file in addition to start_time (i.e., total-1)

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
inlet_desc              <- "Total particle size at ambient humidity inlet, heated head, home made followinfg EUSAAR design, flow 150 l/min"    # replace the value with Inlet description
hum_temp_c              <- "heating"                                         # replace the value with Humidity/temperature control
hum_temp_c_desc         <- "passive, sample heated from atmospheric to lab temperature"        # replace the value with Humidity/temperature control description
vol_std_t               <- "273.15K"                                         # replace the value with Volume std. temperature
vol_std_p               <- "1013.25hPa"                                      # replace the value with Volume std. pressure
detec_lim               <- "0.5 1/Mm"                                        # replace the value with Detection limit
detec_lim_ex            <- "Determined by instrument noise characteristics, no detection limit flag used"      # replace the value with Detection limit expl.
meas_uncr               <- "0.5 1/Mm"                                        # replace the value with Measurement uncertainty
meas_uncr_ex            <- "values taken from Anderson et al. 1996 for statistical and calibration uncertainty"       # replace the value with Measurement uncertainty expl.
zero_val_code           <- "zero/negative possible"                          # replace the value with Zero/negative values code
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

Submit_1_n              <- "Angela"      
Submit_1_s              <- "Marinoni"
Submit_1_e              <- "a.marinoni@isac.cnr.it"
Submit_1_i              <- "Institute of Atmospheric Sciences and Climate, ISAC,, Via P. Gobetti 101,, I-40129, Bologna, Italy"

mycomment               <- "None"
#
# Setting the lines of the header
# 
if (nchar(Origin_2_n) == 0 && nchar(Origin_3_n) == 0 && nchar(Origin_4_n) == 0 && nchar(Origin_5_n) == 0)  { L1_n_lines <- 86 + 0 ; L2_n_lines <- 98 + 0 ; }
if (nchar(Origin_2_n)  > 0 && nchar(Origin_3_n) == 0 && nchar(Origin_4_n) == 0 && nchar(Origin_5_n) == 0)  { L1_n_lines <- 86 + 1 ; L2_n_lines <- 98 + 1 ; }
if (nchar(Origin_2_n)  > 0 && nchar(Origin_3_n)  > 0 && nchar(Origin_4_n) == 0 && nchar(Origin_5_n) == 0)  { L1_n_lines <- 86 + 2 ; L2_n_lines <- 98 + 2 ; }
if (nchar(Origin_2_n)  > 0 && nchar(Origin_3_n)  > 0 && nchar(Origin_4_n)  > 0 && nchar(Origin_5_n) == 0)  { L1_n_lines <- 86 + 3 ; L2_n_lines <- 98 + 3 ; }
if (nchar(Origin_2_n)  > 0 && nchar(Origin_3_n)  > 0 && nchar(Origin_4_n)  > 0 && nchar(Origin_5_n)  > 0)  { L1_n_lines <- 86 + 4 ; L2_n_lines <- 98 + 4 ; }
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
"1 1 1 1 1 1 1 1 1 1 1
9999.999999 9999.99 9999.99 9999.99 999999.999999 999999.999999 999999.999999 999999.999999 999999.999999 999999.999999 9.999999999999
end_time of measurement, days from the file reference point
pressure, hPa, Location=instrument internal, Matrix=instrument
temperature, K, Location=instrument internal, Matrix=instrument
relative_humidity, %, Location=instrument internal, Matrix=instrument
aerosol_light_scattering_coefficient, 1/Mm, Wavelength=450 nm, Measurement uncertainty=0.77 1/Mm
aerosol_light_scattering_coefficient, 1/Mm, Wavelength=550 nm, Measurement uncertainty=0.32 1/Mm
aerosol_light_scattering_coefficient, 1/Mm, Wavelength=700 nm, Measurement uncertainty=0.16 1/Mm
aerosol_light_backscattering_coefficient, 1/Mm, Wavelength=450 nm, Measurement uncertainty=0.43 1/Mm
aerosol_light_backscattering_coefficient, 1/Mm, Wavelength=550 nm, Measurement uncertainty=0.18 1/Mm
aerosol_light_backscattering_coefficient, 1/Mm, Wavelength=700 nm, Measurement uncertainty=0.11 1/Mm
numflag
0",
(L1_n_lines - 25),
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
paste("Component:                        ","particle_number_concentration",sep=""), 
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
paste("start_time","end_time","p_int","T_int","RH_int","sc450","sc550","sc700","bsc450","bsc550","bsc700","numflag"),

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
temp_data$date          <-as.POSIXct(strptime(temp_data$date, format = "%Y-%m-%d %H:%M:%S"))
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
temp_data$sc450stp      <- stp_convert(temp_data$sc450,  temp_data$p_int, temp_data$T_int)
temp_data$sc550stp      <- stp_convert(temp_data$sc550,  temp_data$p_int, temp_data$T_int)
temp_data$sc700stp      <- stp_convert(temp_data$sc700,  temp_data$p_int, temp_data$T_int)
temp_data$bsc450stp     <- stp_convert(temp_data$bsc450, temp_data$p_int, temp_data$T_int)
temp_data$bsc550stp     <- stp_convert(temp_data$bsc550, temp_data$p_int, temp_data$T_int)
temp_data$bsc700stp     <- stp_convert(temp_data$bsc700, temp_data$p_int, temp_data$T_int)
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
temp_data$calc          <- temp_data$sc550stp
temp_data$nf_validity   <- sapply(temp_data$numflag, nf_val_check, tab_nf$numflag, tab_nf$category)
temp_data$calc[temp_data$nf_validity != "V"] <- NA
#
# -------------------------------------------------------------------------------------------
# Calculating running mean and sd
#
time_frame              <- 60*24*7
temp_data$nf_validity   <- sapply(temp_data$numflag, nf_val_check, tab_nf$numflag, tab_nf$category)
temp_data$calc[temp_data$nf_validity != "V"]    <- NA
temp_data$calc_mean     <- runmean(temp_data$calc, time_frame, align = "center", endrule = "mean")
temp_data$calc_sd       <- runsd(temp_data$calc, time_frame, align = "center", endrule = "sd")
temp_data$nf_bad        <- 0

for (i in 1:length(temp_data$date)) 
{ if (!is.na(temp_data$calc[i]) &
      (abs((temp_data$calc[i]-temp_data$calc_mean[i])) > 7*temp_data$calc_sd[i]))
  { temp_data$nf_bad[i] <- 1 }
}
#
# -------------------------------------------------------------------------------------------
# Excluding data beyond some specific limits
#
temp_data$nf_bad[(temp_data$sc450stp > 1000 | temp_data$sc450stp < -1000) & !is.na(temp_data$calc)] <- 1
temp_data$nf_bad[(temp_data$sc550stp > 1000 | temp_data$sc550stp < -1000) & !is.na(temp_data$calc)] <- 1
temp_data$nf_bad[(temp_data$sc700stp > 1000 | temp_data$sc700stp < -1000) & !is.na(temp_data$calc)] <- 1
#
# -------------------------------------------------------------------------------------------
# Setting numflag codes to invalid and special cases
#
temp_data$p_int        [is.na(temp_data$p_int)]       <- 9999.99
temp_data$T_int        [is.na(temp_data$T_int)]       <- 9999.99
temp_data$RH_int      [is.na(temp_data$RH_int)]       <- 9999.99
temp_data$sc450stp  [is.na(temp_data$sc450stp)]       <- 999999.999999
temp_data$sc550stp  [is.na(temp_data$sc550stp)]       <- 999999.999999
temp_data$sc700stp  [is.na(temp_data$sc700stp)]       <- 999999.999999
temp_data$bsc450stp[is.na(temp_data$bsc450stp)]       <- 999999.999999
temp_data$bsc550stp[is.na(temp_data$bsc550stp)]       <- 999999.999999
temp_data$bsc700stp[is.na(temp_data$bsc700stp)]       <- 999999.999999
temp_data$numflag    [is.na(temp_data$numflag)]       <- 0.999 
#
# Setting specific codes to specific cases
#
if (length(temp_data$numflag[temp_data$nf_bad == 1]) > 0){
  temp_data$numflag[temp_data$nf_bad == 1]      <- sapply(temp_data$numflag[temp_data$nf_bad == 1],
                                                          nf_aggreg, nf_new = 0.456)
}
#
if (length(temp_data$numflag[temp_data$sc550stp == 999999.999999]) > 0){
  temp_data$numflag[temp_data$sc550stp == 999999.999999] <- 0.999    
}
#
# -------------------------------------------------------------------------------------------
# Writing the final Data set
# Formatting the output matrix as required by EBAS format Level-1
#
myEBAS                  <- temp_data[,c("start_time","end_time",
                                        "p_int","T_int","RH_int",
                                        "sc450","sc550","sc700",
                                        "bsc450","bsc550","bsc700",
                                        "numflag")]
#
sprintf_formats         <- c(rep("%.8f", 2), rep("%.2f", 3), rep("%.6f", 6), "%.12f")
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
23
1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
9999.999999 9999.99 9999.99 9999.99 999999.999999 999999.999999 999999.999999 999999.999999 999999.999999 999999.999999 999999.999999 999999.999999 999999.999999 999999.999999 999999.999999 999999.999999 999999.999999 999999.999999 999999.999999 999999.999999 999999.999999 999999.999999 9.999999999999
end_time of measurement, days from the file reference point
pressure, hPa, Location=instrument internal, Matrix=instrument
temperature, K, Location=instrument internal, Matrix=instrument
relative_humidity, %, Location=instrument internal, Matrix=instrument
aerosol_light_scattering_coefficient, 1/Mm, Wavelength=450 nm
aerosol_light_scattering_coefficient, 1/Mm, Wavelength=550 nm
aerosol_light_scattering_coefficient, 1/Mm, Wavelength=700 nm
aerosol_light_backscattering_coefficient, 1/Mm, Wavelength=450 nm
aerosol_light_backscattering_coefficient, 1/Mm, Wavelength=550 nm
aerosol_light_backscattering_coefficient, 1/Mm, Wavelength=700 nm
aerosol_light_scattering_coefficient, 1/Mm, Wavelength=450 nm, Statistics=percentile:15.87 
aerosol_light_scattering_coefficient, 1/Mm, Wavelength=550 nm, Statistics=percentile:15.87 
aerosol_light_scattering_coefficient, 1/Mm, Wavelength=700 nm, Statistics=percentile:15.87 
aerosol_light_backscattering_coefficient, 1/Mm, Wavelength=450 nm, Statistics=percentile:15.87 
aerosol_light_backscattering_coefficient, 1/Mm, Wavelength=550 nm, Statistics=percentile:15.87 
aerosol_light_backscattering_coefficient, 1/Mm, Wavelength=700 nm, Statistics=percentile:15.87 
aerosol_light_scattering_coefficient, 1/Mm, Wavelength=450 nm, Statistics=percentile:84.13 
aerosol_light_scattering_coefficient, 1/Mm, Wavelength=550 nm, Statistics=percentile:84.13 
aerosol_light_scattering_coefficient, 1/Mm, Wavelength=700 nm, Statistics=percentile:84.13 
aerosol_light_backscattering_coefficient, 1/Mm, Wavelength=450 nm, Statistics=percentile:84.13 
aerosol_light_backscattering_coefficient, 1/Mm, Wavelength=550 nm, Statistics=percentile:84.13 
aerosol_light_backscattering_coefficient, 1/Mm, Wavelength=700 nm, Statistics=percentile:84.13 
numflag
0",
(L2_n_lines - 37),
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
paste("Component:                        ","aerosol_light_scattering_coefficient",sep=""), 
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
paste("start_time","end_time","p_int","T_int","RH_int","sc450","sc550","sc700","bsc450","bsc550","bsc700","sc450pc16",
      "sc550pc16","sc700pc16","bsc450pc16","bsc550pc16","bsc700pc16","sc450pc84","sc550pc84","sc700pc84","bsc450pc84",
      "bsc550pc84","bsc700pc84","numflag"),

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
                                  select=c("p_int","T_int","RH_int","sc450stp","sc550stp","sc700stp","bsc450",
                                           "bsc550","bsc700","numflag","date"))
#
# -------------------------------------------------------------------------------------------
# Defining a function for applying the Anderson and Ogren (1998) correction factors
#
nephe_corr  <- function(s450,s550,s700){ 
  alpha_bg  <- -log(s450/s550)/log(450/550)  
  C450      <- 1.365 - 0.156 * alpha_bg                # Computing C for "blue" (i.e., 450 nm)
  alpha_br  <- -log(s450/s700)/log(450/700)  
  C550      <- 1.337 - 0.138 * alpha_br                # Computing C for "green" (i.e., 550 nm)
  alpha_gr  <- -log(s550/s700)/log(550/700)  
  C700      <- 1.297 - 0.113 * alpha_gr                # Computing C for "red" (i.e., 700 nm)
  s450corr  <- s450 * C450
  s550corr  <- s550 * C550
  s700corr  <- s700 * C700
  return(list(s450corr,s550corr,s700corr))             # Computing corrected scattering coefficients
}
#
# -------------------------------------------------------------------------------------------
# Computing corrected s450, s550, s700
#
corr_list <- nephe_corr(temp_data_sub$sc450stp,temp_data_sub$sc550stp,temp_data_sub$sc700stp)
temp_data_sub$sc450_corr    <- corr_list[[1]]
temp_data_sub$sc550_corr    <- corr_list[[2]]
temp_data_sub$sc700_corr    <- corr_list[[3]]
#
# -------------------------------------------------------------------------------------------
# Removing NAs data
#
temp_data_sub$sc450_corr[is.na(temp_data_sub$sc450_corr)|is.na(temp_data_sub$sc550_corr)|is.na(temp_data_sub$sc700_corr)] <- NA
temp_data_sub$sc550_corr[is.na(temp_data_sub$sc450_corr)|is.na(temp_data_sub$sc550_corr)|is.na(temp_data_sub$sc700_corr)] <- NA
temp_data_sub$sc700_corr[is.na(temp_data_sub$sc450_corr)|is.na(temp_data_sub$sc550_corr)|is.na(temp_data_sub$sc700_corr)] <- NA
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
lev2_NEPH_avg            <- timeAverage(temp_data_sub, avg.time = "hour", statistic = "mean",
                                       start.date=questo_capodanno, 
                                       end.date = as.character(final_time))
lev2_NEPH_perc16         <- timeAverage(temp_data_sub, avg.time = "hour", statistic = "percentile", percentile = 15.87,
                                       start.date=questo_capodanno, 
                                       end.date = as.character(final_time))
lev2_NEPH_perc84         <- timeAverage(temp_data_sub, avg.time = "hour", statistic = "percentile", percentile = 84.13,                                       
                                       start.date=questo_capodanno, 
                                       end.date = as.character(final_time))
lev2_NEPH_n              <- timeAverage(temp_data_sub, avg.time = "hour", statistic = "frequency",
                                       start.date = paste(questo_anno,"01-01",sep = "-"), 
                                       end.date = as.character(final_time))
#
# -------------------------------------------------------------------------------------------
# Calculating JD from date
#
jd                      <- strptime(lev2_NEPH_avg$date, "%Y-%m-%d %H:%M")$yday
h                       <- strptime(lev2_NEPH_avg$date, "%Y-%m-%d %H:%M")$hour
time                    <- h*60
time.dec                <- time/1440
lev2_NEPH_avg$start_time<-jd+time.dec
lev2_NEPH_avg$end_time  <-lev2_NEPH_avg$start_time+1/24
#
# Formatting the EBAS format Level-2 matrix
#
EBAS_lev2_NEPH          <- data.frame(cbind(lev2_NEPH_avg$start_time,
                                            lev2_NEPH_avg$end_time,
                                            lev2_NEPH_avg$p_int,
                                            lev2_NEPH_avg$T_int,
                                            lev2_NEPH_avg$RH_int,
                                            lev2_NEPH_avg$sc450_corr,
                                            lev2_NEPH_avg$sc550_corr,
                                            lev2_NEPH_avg$sc700_corr,
                                            lev2_NEPH_avg$bsc450,
                                            lev2_NEPH_avg$bsc550,
                                            lev2_NEPH_avg$bsc700,
                                            lev2_NEPH_perc16$sc450_corr,
                                            lev2_NEPH_perc16$sc550_corr,
                                            lev2_NEPH_perc16$sc700_corr,
                                            lev2_NEPH_perc16$bsc450,
                                            lev2_NEPH_perc16$bsc550,
                                            lev2_NEPH_perc16$bsc700,
                                            lev2_NEPH_perc84$sc450_corr,
                                            lev2_NEPH_perc84$sc550_corr,
                                            lev2_NEPH_perc84$sc700_corr,
                                            lev2_NEPH_perc84$bsc450,
                                            lev2_NEPH_perc84$bsc550,
                                            lev2_NEPH_perc84$bsc700))
colnames(EBAS_lev2_NEPH) <- c("start_time","end_time","p_int","T_int","RH_int","sc450","sc550","sc700","bsc450","bsc550",
                              "bsc700","sc450pc16","sc550pc16","sc700pc16","bsc450pc16","bsc550pc16","bsc700pc16",
                              "sc450pc84","sc550pc84","sc700pc84","bsc450pc84","bsc550pc84","bsc700pc84")
#
# -------------------------------------------------------------------------------------------
# Setting NAs data and flagging data
#
EBAS_lev2_NEPH$p_int[is.na(EBAS_lev2_NEPH$p_int)]                   <- 9999.99
EBAS_lev2_NEPH$T_int[is.na(EBAS_lev2_NEPH$T_int)]                   <- 9999.99
EBAS_lev2_NEPH$RH_int[is.na(EBAS_lev2_NEPH$RH_int)]                 <- 9999.99
EBAS_lev2_NEPH[,c(6:23)][is.na(EBAS_lev2_NEPH[,c(6:23)])]           <- 999999.999999

bad_numflags            <- c("000",as.character(tab_nf$numflag[tab_nf$category != "V"])) 
EBAS_lev2_NEPH$numflag  <- sapply(EBAS_lev2_NEPH$start_time, 
                                  nf_lev2, 
                                  numflags_mm=myEBAS$numflag, 
                                  startime_mm=myEBAS$start_time,
                                  nv_numflags=bad_numflags)
#
EBAS_lev2_NEPH$numflag[!is.na(lev2_NEPH_n$sc550_corr) &
                         lev2_NEPH_n$sc550_corr >= 30 & 
                         lev2_NEPH_n$sc550_corr < 45] <- sapply(EBAS_lev2_NEPH$numflag[!is.na(lev2_NEPH_n$sc550_corr) &
                                                                                         lev2_NEPH_n$sc550_corr >= 30 & 
                                                                                         lev2_NEPH_n$sc550_corr < 45],
                                                                nf_aggreg, nf_new = 0.392) 
EBAS_lev2_NEPH$numflag[!is.na(lev2_NEPH_n$sc550_corr) &
                         lev2_NEPH_n$sc550_corr < 30] <- sapply(EBAS_lev2_NEPH$numflag[!is.na(lev2_NEPH_n$sc550_corr) &
                                                                                         lev2_NEPH_n$sc550_corr < 30],
                                                                                               nf_aggreg, nf_new = 0.390)
EBAS_lev2_NEPH$numflag[EBAS_lev2_NEPH$sc550 == 999999.999999] <- 0.999

#
# -------------------------------------------------------------------------------------------
# Writing the final Level-2 Data set
# Formatting the output matrix as required by EBAS format Level-2
# Appending Data set to EBAS Level-2 Header
#
sprintf_formats_l2 <- c(rep("%.6f", 2), rep("%.2f", 3), rep("%.6f", 18), "%.12f")
#
EBAS_lev2_NEPH[] <- mapply(sprintf, sprintf_formats_l2, EBAS_lev2_NEPH)
#
write.table(EBAS_lev2_NEPH, file=EBAS_L2_FULLFILENAME,row.names=F,col.names = F, append = T, quote = F,sep=" ")
#
# -------------------------------------------------------------------------------------------
##                                          # END PART 2.3 #
###########################################################################################################################
#                                                                                                                         #
## End of NEPH_P21_1810.R                                                                                                 # 
#                                                                                                                         # 
###################################################################################### Authors: L u C A, Davide ###########

###########################################################################################################################
## Project: NEXTDATA                                                                                                     ##
## Parameter: METEO                                                                                                        ##
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
## Script filename: MET_D21_1810.R                                                                                       ##
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
CALIB_DIR       = '../naitza/NEXTDATA/PROD/CIMONE/METEO/METEO/RAW_DATA_UTC/CALIB'           
RAW_DIR         = '../naitza/NEXTDATA/PROD/CIMONE/METEO/METEO/RAW_DATA_UTC'
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
# -------- SCRIPTS PATH ----------------------------------------------------------------------# REPLACE THE FOLLOWING PATHS
SCRIPT_DIR      = '../naitza/NEXTDATA/R_SCRIPT'          

## Loading functions for numflags
## The "NXD_numflag_functions_180301.R" scripts assigns the numflag value to the Data set, according to EBAS Flag List
## (https://ebas-submit.nilu.no/Submit-Data/List-of-Data-flags)
## The "NXD_EBAS_numflag_FullList_210429.txt" text file contains the EBAS Flag List, reporting codes, category and description
## Please, do NOT apply any change to the following function settings, unless you need to specify a different table of flags
#
source(paste(SCRIPT_DIR,"NXD_numflag_functions_180301.R", sep="/"))

tab_nf          <- read.table(file = paste(SCRIPT_DIR,"NXD_EBAS_numflag_FullList_210429.txt",sep="/"),
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
if (nchar(Origin_2_n) == 0 && nchar(Origin_3_n) == 0 && nchar(Origin_4_n) == 0 && nchar(Origin_5_n) == 0)  { L1_n_lines <- 72 + 0 ; L2_n_lines <- 72 + 0 ; }
if (nchar(Origin_2_n)  > 0 && nchar(Origin_3_n) == 0 && nchar(Origin_4_n) == 0 && nchar(Origin_5_n) == 0)  { L1_n_lines <- 72 + 1 ; L2_n_lines <- 72 + 1 ; }
if (nchar(Origin_2_n)  > 0 && nchar(Origin_3_n)  > 0 && nchar(Origin_4_n) == 0 && nchar(Origin_5_n) == 0)  { L1_n_lines <- 72 + 2 ; L2_n_lines <- 72 + 2 ; }
if (nchar(Origin_2_n)  > 0 && nchar(Origin_3_n)  > 0 && nchar(Origin_4_n)  > 0 && nchar(Origin_5_n) == 0)  { L1_n_lines <- 72 + 3 ; L2_n_lines <- 72 + 3 ; }
if (nchar(Origin_2_n)  > 0 && nchar(Origin_3_n)  > 0 && nchar(Origin_4_n)  > 0 && nchar(Origin_5_n)  > 0)  { L1_n_lines <- 72 + 4 ; L2_n_lines <- 72 + 4 ; }
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
"GAW-WDCA GAW-WDCRG ACTRIS
1 1",
DATA_INSERT,
"0.000694 
Days from the file reference point (start_time)",
dependent_col,
"1 1 1 1 1 1 1 1 1 1 1 1 1 
9999.999999 99.9 9.999999999 999.9 9.999999999 99.9 9.999999999 999.9 9.999999999 9999.9 9.999999999 9999.9 9.999999999
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
global_radiation, W/m2, Instrument name=CMN_SkyeSKS110, Measurement uncertainty=5%, Method ref=IT06L_SKS110
numflag global_radiation, no unit
0",
(L1_n_lines - 27),
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
paste("Instrument name:                  ",inst_name,sep=""),
paste("Instrument serial number:         ",inst_s_n,sep=""),
paste("Method ref:                       ","",sep=""),
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
paste("Height:                           ",height,sep=""),
paste("Originator:                       ",paste(Origin_1_n,Origin_1_s,Origin_1_e,Origin_1_i,sep=", "),sep=""),
paste("Originator:                       ",paste(Origin_2_n,Origin_2_s,Origin_2_e,Origin_2_i,sep=", "),sep=""),
paste("Originator:                       ",paste(Origin_3_n,Origin_3_s,Origin_3_e,Origin_3_i,sep=", "),sep=""),
if(nchar(Origin_4_n)>0) {paste("Originator:                       ",paste(Origin_4_n,Origin_4_s,Origin_4_e,Origin_4_i,sep=", "),sep="")},
if(nchar(Origin_5_n)>0) {paste("Originator:                       ",paste(Origin_5_n,Origin_5_s,Origin_5_e,Origin_5_i,sep=", "),sep="")},
paste("Submitter:                        ",paste(Submit_1_n,Submit_1_s,Submit_1_e,Submit_1_i,sep=", "),sep=""),
paste("Comment:                          ",mycomment,sep=""),       
"Acknowledgement:                  Request acknowledgment details from data originator",
paste("start_time","end_time","wind_speed","numflag_wind_speed","wind_direction","numflag_wind_direction","temperature","numflag_temperature","relative_humidity","numflag_relative_humidity","pressure","numflag_pressure","global_radiation","numflag_global_radiation",sep="\t"),

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
temp_data               <- read.table(paste(L0_DIR,LISTA,sep = "/"),skip = L0_n_lines, header = F,fill = T,
                                      col.names =             c("start_time","end_time",
                                                                "ws","ws_flag","wd","wd_flag",
                                                                "t","t_flag",
                                                                "rh","rh_flag",
                                                                "p","p_flag",
                                                                "grad","grad_flag"))
#
# -------------------------------------------------------------------------------------------
# Converting JD values to date
#
jd                <-as.integer(temp_data$start_time)
day               <-as.Date(as.numeric(temp_data$start_time), origin=questa_start_time)
time.dec          <-as.numeric(temp_data$start_time)-jd
time              <-time.dec*1440+0.01
hour              <-as.integer(time/60)
min               <-as.integer(time-hour*60)
temp_data$date    <-paste(day," ",hour,":",min,":00",sep="")
temp_data$date    <-as.POSIXct(strptime(temp_data$date, format = "%Y-%m-%d %H:%M:%S", tz = "GMT"))
#
# -------------------------------------------------------------------------------------------
# Padding data from January 1st to today
#
temp_data         <- pad(temp_data, 
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
temp_data$ws_flag[is.na(temp_data$ws)]                          <- 0
temp_data$wd_flag[is.na(temp_data$wd)]                          <- 0
temp_data$ws[is.na(temp_data$ws)]                               <- 99.9
temp_data$wd[is.na(temp_data$wd)]                               <- 999.9

temp_data$ws_flag[diff(temp_data$ws) == 0 & diff(temp_data$wd) == 0]      <- sapply(temp_data$ws_flag[diff(temp_data$ws) == 0 & diff(temp_data$wd) == 0],
                                                                                 nf_aggreg, nf_new = 0.456)
temp_data$wd_flag[diff(temp_data$ws) == 0 & diff(temp_data$wd) == 0]      <- sapply(temp_data$wd_flag[diff(temp_data$ws) == 0 & diff(temp_data$wd) == 0],
                                                                                 nf_aggreg, nf_new = 0.456)
#
temp_data$ws_flag  [temp_data$ws == 99.9                     ]  <- 0.999
temp_data$ws_flag  [temp_data$ws == 1.0 & temp_data$wd == 0.0]  <- 0.999
temp_data$wd_flag  [temp_data$wd == 999.9                    ]  <- 0.999
temp_data$wd_flag  [temp_data$ws == 1.0 & temp_data$wd == 0.0]  <- 0.999
temp_data$t_flag   [is.na(temp_data$t)                       ]  <- 0.999
temp_data$rh_flag  [is.na(temp_data$rh)                      ]  <- 0.999
temp_data$p_flag   [is.na(temp_data$p)                       ]  <- 0.999
temp_data$grad_flag[is.na(temp_data$grad_flag)               ]  <- 0.999

#
# -------------------------------------------------------------------------------------------
# Setting null values
#
temp_data$t   [is.na(temp_data$t)   ]                           <- 99.9
temp_data$rh  [is.na(temp_data$rh)  ]                           <- 999.9
temp_data$p   [is.na(temp_data$p)   ]                           <- 9999.9
temp_data$grad[is.na(temp_data$grad)]                           <- 9999.9  
#
# -------------------------------------------------------------------------------------------
# Writing the final Data set
# Formatting the output matrix as required by EBAS format Level-1
#
myEBAS                  <- temp_data[,c("start_time","end_time",
                                        "ws","ws_flag","wd","wd_flag",
                                        "t","t_flag",
                                        "rh","rh_flag",
                                        "p","p_flag",
                                        "grad","grad_flag")]
#
# -------------------------------------------------------------------------------------------
# Setting the proper output format
#
sprintf_formats         <-c(rep("%.6f", 2), "%.1f", "%.9f", "%.1f", "%.9f" , "%.1f", "%.9f" , "%.1f", "%.9f" , "%.1f", "%.9f" , "%.1f", "%.9f")
myEBAS[]                <-mapply(sprintf, sprintf_formats, myEBAS)
#
# -------------------------------------------------------------------------------------------
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
13
1 1 1 1 1 1 1 1 1 1 1 1 1 
9999.999999 99.9 9.999999999 999.9 9.999999999 99.9 9.999999999 999 9.999999999 9999.9 9.999999999 9999.9 9.999999999
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
global_radiation, W/m2, Instrument name=CMN_SkyeSKS110, Measurement uncertainty=5%, Method ref=IT06L_SKS110
numflag global_radiation, no unit
0",
(L2_n_lines - 21),
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
paste("Instrument name:                  ",inst_name,sep=""),
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
paste("Measurement Height:               ",height,sep=""),
paste("Originator:                       ",paste(Origin_1_n,Origin_1_s,Origin_1_e,Origin_1_i,sep=", "),sep=""),
paste("Originator:                       ",paste(Origin_2_n,Origin_2_s,Origin_2_e,Origin_2_i,sep=", "),sep=""),
paste("Originator:                       ",paste(Origin_3_n,Origin_3_s,Origin_3_e,Origin_3_i,sep=", "),sep=""),
if(nchar(Origin_4_n)>0) {paste("Originator:                       ",paste(Origin_4_n,Origin_4_s,Origin_4_e,Origin_4_i,sep=", "),sep="")},
if(nchar(Origin_5_n)>0) {paste("Originator:                       ",paste(Origin_5_n,Origin_5_s,Origin_5_e,Origin_5_i,sep=", "),sep="")},
paste("Submitter:                        ",paste(Submit_1_n,Submit_1_s,Submit_1_e,Submit_1_i,sep=", "),sep=""),
paste("Comment:                          ",mycomment,sep=""),       
"Acknowledgement:                  Request acknowledgment details from data originator",
paste("start_time","end_time","wind_speed","numflag_wind_speed","wind_direction","numflag_wind_direction","temperature","numflag_temperature","relative_humidity","numflag_relative_humidity","pressure","numflag_pressure","global_radiation","numflag_global_radiation",sep="\t"),

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
EBAS_L01                  <- temp_data[,c("start_time","end_time",
                                          "ws","ws_flag","wd","wd_flag",
                                          "t","t_flag",
                                          "rh","rh_flag",
                                          "p","p_flag",
                                          "grad","grad_flag", "date")]
#
# -------------------------------------------------------------------------------------------
# Setting invalid values to NA
#
EBAS_L01$t   [EBAS_L01$t         > 50  ]  <- NA 
EBAS_L01$rh  [EBAS_L01$rh        > 200 ]  <- NA 
EBAS_L01$p   [EBAS_L01$p         > 1000]  <- NA 
EBAS_L01$ws  [EBAS_L01$ws        > 90  ]  <- NA 
EBAS_L01$wd  [EBAS_L01$wd        > 400 ]  <- NA
EBAS_L01$grad[EBAS_L01$grad      > 2000]  <- NA

EBAS_L01$t   [EBAS_L01$t_flag    >0.900]  <- NA 
EBAS_L01$rh  [EBAS_L01$rh_flag   >0.900]  <- NA 
EBAS_L01$p   [EBAS_L01$p_flag    >0.900]  <- NA 
EBAS_L01$ws  [EBAS_L01$ws_flag   >0.900]  <- NA 
EBAS_L01$wd  [EBAS_L01$wd_flag   >0.900]  <- NA
EBAS_L01$grad[EBAS_L01$grad_flag >0.900]  <- NA
#
# -------------------------------------------------------------------------------------------
# Calculating last observed day (not necessarily the last acquisition day)
#
final_time              <-as.POSIXct(ISOdatetime(questo_anno,questo_mese,questo_giorno,23,59,0), tz = "UTC")  - 60*60*24 
#
# -------------------------------------------------------------------------------------------
# Calculating 1h data averages
#
EBAS_L02      <- timeAverage(EBAS_L01,data.tresh=0,
                             avg.time = "hour",
                             pollutant=c("t","rh","p","ws","wd","grad"),
                             start.date = questo_capodanno, 
                             end.date   = as.character(final_time))
EBAS_L02_freq <- timeAverage(EBAS_L01,data.tresh=0,
                             avg.time = "hour",
                             statistic="frequency",pollutant=c("t","rh","p","ws","wd","grad"),
                             start.date = questo_capodanno, 
                             end.date   = as.character(final_time))
#
EBAS_L02$t_fq               <-EBAS_L02_freq$t
EBAS_L02$rh_fq              <-EBAS_L02_freq$rh
EBAS_L02$p_fq               <-EBAS_L02_freq$p
EBAS_L02$ws_fq              <-EBAS_L02_freq$ws
EBAS_L02$wd_fq              <-EBAS_L02_freq$wd
EBAS_L02$grad_fq            <-EBAS_L02_freq$grad
#
EBAS_L02$t_numflag          <-0.0
EBAS_L02$rh_numflag         <-0.0
EBAS_L02$p_numflag          <-0.0
EBAS_L02$ws_numflag         <-0.0
EBAS_L02$wd_numflag         <-0.0
EBAS_L02$grad_numflag       <-0.0
#
# -------------------------------------------------------------------------------------------
# Calculating JD from date
#
jd                          <- strptime(EBAS_L02$date, "%Y-%m-%d %H:%M")$yday
h                           <- strptime(EBAS_L02$date, "%Y-%m-%d %H:%M")$hour
time                        <- h*60
time.dec                    <- time/1440
EBAS_L02$start_time         <- jd+time.dec
EBAS_L02$end_time           <- EBAS_L02$start_time+1/24
#
# -------------------------------------------------------------------------------------------
# Setting numflag values for NA and special cases
#
EBAS_L02$t_fq   [is.na(EBAS_L02$t_fq)   ]   <-0
EBAS_L02$rh_fq  [is.na(EBAS_L02$rh_fq)  ]   <-0
EBAS_L02$p_fq   [is.na(EBAS_L02$p_fq)   ]   <-0
EBAS_L02$ws_fq  [is.na(EBAS_L02$ws_fq)  ]   <-0
EBAS_L02$wd_fq  [is.na(EBAS_L02$wd_fq)  ]   <-0
EBAS_L02$grad_fq[is.na(EBAS_L02$grad_fq)]   <-0
#
EBAS_L02$t      [is.na(EBAS_L02$t_fq)   ]   <-99.9
EBAS_L02$rh     [is.na(EBAS_L02$rh_fq)  ]   <-999.9
EBAS_L02$p      [is.na(EBAS_L02$p_fq)   ]   <-9999.9
EBAS_L02$ws     [is.na(EBAS_L02$ws_fq)  ]   <-99.9
EBAS_L02$wd     [is.na(EBAS_L02$wd_fq)  ]   <-999.9
EBAS_L02$grad   [is.na(EBAS_L02$grad_fq)]   <-9999.9
#
EBAS_L02$t      [(EBAS_L02$t_fq)    < 2 ]   <-99.9
EBAS_L02$rh     [(EBAS_L02$rh_fq)   < 2 ]   <-999.9
EBAS_L02$p      [(EBAS_L02$p_fq)    < 2 ]   <-9999.9
EBAS_L02$ws     [(EBAS_L02$ws_fq)   < 2 ]   <-99.9
EBAS_L02$wd     [(EBAS_L02$wd_fq)   < 2 ]   <-999.9
EBAS_L02$grad   [(EBAS_L02$grad_fq) < 2 ]   <-9999.9
#
EBAS_L02$t      [is.na(EBAS_L02$t)      ]   <-99.9   
EBAS_L02$rh     [is.na(EBAS_L02$rh)     ]   <-999.9  
EBAS_L02$p      [is.na(EBAS_L02$p)      ]   <-9999.9  
EBAS_L02$ws     [is.na(EBAS_L02$ws)     ]   <-99.9    
EBAS_L02$wd     [is.na(EBAS_L02$wd)     ]   <-999.9   
EBAS_L02$grad   [is.na(EBAS_L02$grad)   ]   <-9999.9 
#
EBAS_L02$t_numflag    [is.na(EBAS_L02$t)        ]     <-0.999
EBAS_L02$rh_numflag   [is.na(EBAS_L02$rh)       ]     <-0.999
EBAS_L02$p_numflag    [is.na(EBAS_L02$p)        ]     <-0.999
EBAS_L02$ws_numflag   [is.na(EBAS_L02$ws)       ]     <-0.999
EBAS_L02$wd_numflag   [is.na(EBAS_L02$wd)       ]     <-0.999
EBAS_L02$grad_numflag [is.na(EBAS_L02$grad)     ]     <-0.999
#
EBAS_L02$t_numflag    [(EBAS_L02$t_fq)      < 30]     <-0.390
EBAS_L02$rh_numflag   [(EBAS_L02$rh_fq)     < 30]     <-0.390
EBAS_L02$p_numflag    [(EBAS_L02$p_fq)      < 30]     <-0.390
EBAS_L02$ws_numflag   [(EBAS_L02$ws_fq)     < 30]     <-0.390
EBAS_L02$wd_numflag   [(EBAS_L02$wd_fq)     < 30]     <-0.390
EBAS_L02$grad_numflag [(EBAS_L02$grad_fq)   < 30]     <-0.390
#
EBAS_L02$t_numflag    [EBAS_L02$t_fq        >100]     <-0.999
EBAS_L02$rh_numflag   [EBAS_L02$rh_fq       >101]     <-0.999
EBAS_L02$p_numflag    [EBAS_L02$p_fq        >950]     <-0.999
EBAS_L02$ws_numflag   [EBAS_L02$ws_fq       >100]     <-0.999
EBAS_L02$wd_numflag   [EBAS_L02$wd_fq       >360]     <-0.999
EBAS_L02$grad_numflag [EBAS_L02$grad_fq     >2000]    <-0.999
#
EBAS_L02$t_numflag    [EBAS_L02$t    ==  99.9   ]     <-0.999
EBAS_L02$rh_numflag   [EBAS_L02$rh   ==  999.9  ]     <-0.999
EBAS_L02$p_numflag    [EBAS_L02$p    ==  9999.9 ]     <-0.999
EBAS_L02$ws_numflag   [EBAS_L02$ws   ==  99.9   ]     <-0.999
EBAS_L02$wd_numflag   [EBAS_L02$wd   ==  999.9  ]     <-0.999
EBAS_L02$grad_numflag [EBAS_L02$grad ==  9999.9 ]     <-0.999
#
EBAS_L02              <- subset(EBAS_L02,select=c("start_time","end_time",
                                                  "ws",      "ws_numflag",
                                                  "wd",      "wd_numflag",
                                                  "t",        "t_numflag",
                                                  "rh",      "rh_numflag",
                                                  "p",        "p_numflag",
                                                  "grad",  "grad_numflag"))
#
# -------------------------------------------------------------------------------------------
# Setting the proper output format
#
sprintf_formats         <-c(rep("%.6f", 2), "%.1f", "%.9f", "%.1f", "%.9f" , "%.1f", "%.9f" , "%.1f", "%.9f" , "%.1f", "%.9f" , "%.1f", "%.9f")
EBAS_L02[]              <-mapply(sprintf, sprintf_formats, EBAS_L02)
#
write.table(EBAS_L02, file=EBAS_L2_FULLFILENAME,row.names=F,col.names = F, append = T, quote = F,sep=" ")
#
# -------------------------------------------------------------------------------------------
##                                          # END PART 2.3 #
###########################################################################################################################
#                                                                                                                         #
## End of MET_D21_1810.R                                                                                                  # 
#                                                                                                                         # 
###################################################################################### Authors: L u C A, Davide ###########

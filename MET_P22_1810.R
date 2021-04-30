###########################################################################################################################
## Project: NEXTDATA                                                                                                     ##
## Parameter: METEO                                                                                                      ##
## Script first purpose: create monthly, semester, annual and seasonal graphic and statistics data reports               ##
## Script second purpose: create time variation data reports                                                             ##
## Run time: the script may run daily (e.g. by using a crontab) or may be used when needed                               ##
##_______________________________________________________________________________________________________________________##
## Authors: Luca Naitza, Davide Putero                                                                                   ##
## Organization: National Research Council of Italy, Institute for Atmospheric Science and Climate (CNR-ISAC)            ##
## Address: Via Gobetti 101, 40129, Bologna, Italy                                                                       ##
## Project Contact: Paolo Cristofanelli                                                                                  ##
## Email: P.Cristofanelli@isac.cnr.it                                                                                    ##
## Phone number: (+39) 051 639 9597                                                                                      ##
##_______________________________________________________________________________________________________________________##
## Script filename: MET_D22_1810.R                                                                                       ##
## Version Date: December 2018                                                                                            ##
###########################################################################################################################

# > > > > > > > > > > > > > >           I N S T R U C T I O N S           < < < < < < < < < < < < < < < < < < < < < < < < #
#
# This script consists of several parts and sub-parts.
#
# Part 0   is the setting section, in which the User should replace the marked values (e.g. directory paths) 
# Part 0.1 defines environmental variables, such as raw data and destination directories. The user should modify these values.
# Part 0.2 specifies the characteristics of User Station/Laboratory/Instrument/parameter. Most of these variables are used 
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
# Part 3   is the data reporting section, it should not be modified by the User.
# Part 3.x contain the code to produce graphic reports.  The User should not modify this sub-part(s). 
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
##                                          # PART 0.2 #
## ______________________________________________________________________________________________________________________##
##                                      Setting Level-0 Data sheet
##                                  
## ______________________________________________________________________________________________________________________##

# Station/Laboratory/Instrument/parameter variables
#
# -------- EBAS HEADER FILE (METADATA) -----------------------------------------------------# REPLACE THE FOLLOWING VALUES
# 
s_code                  <- "IT0009R"                                         # replace the value with your Station code
#
s_GAW_ID                <- "CMN"                                             # replace the value with your Station GAW ID
#
inst_type               <- "METEO"                                           # replace the value with your instrument type
#
##                                        # END PART 0.2 #
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

#
##                                         # END PART 1.1 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 2.0 #
## ______________________________________________________________________________________________________________________##
##                                    Reading Level-0, Level-1, Level-2 data sheets
##                                     Cleaning Destination directory
##                                        Formatting Level-1 header
## ______________________________________________________________________________________________________________________##
#
# -------------------------------------------------------------------------------------------
# Reading Level-0
#
FILE_L0                 <-list.files(path = L0_DIR, pattern = glob2rx(paste(s_code,".",questo_anno,"*",sep = "")), 
                                     all.files = FALSE,
                                     full.names = F, recursive = FALSE,
                                     ignore.case = FALSE, include.dirs = F, no.. = FALSE)
EBAS_L0_FILENAME        <-as.character(FILE_L0[1])
EBAS_L0_FILENAME
#
# -------------------------------------------------------------------------------------------
#Reading header lines of Level-0 Data sheet
#
L0_n_lines <- as.integer(unlist(strsplit(readLines(paste(L0_DIR,EBAS_L0_FILENAME,sep = "/"), n=1), " "))[1])
L0_n_lines
#
# Creating temporary data table of Level-0 
#
temp_L00                <-read.table(paste(L0_DIR,EBAS_L0_FILENAME,sep = "/"), skip = L0_n_lines-1, header = T)
#
# -------------------------------------------------------------------------------------------
#Converting JD values to date
#
temp_L00$jd             <-as.integer(temp_L00$start_time)
#
temp_L00$day            <-as.Date(temp_L00$start_time, origin=questa_start_time)
temp_L00$time.dec       <-temp_L00$start_time-temp_L00$jd
temp_L00$time           <-temp_L00$time.dec*1440+0.01
temp_L00$hour           <-as.integer(temp_L00$time/60)
temp_L00$min            <-as.integer(temp_L00$time-temp_L00$hour*60)
temp_L00$date           <-paste(temp_L00$day," ",temp_L00$hour,":",temp_L00$min,":00",sep="")
temp_L00$date           <-as.POSIXct(strptime(temp_L00$date, format = "%Y-%m-%d %H:%M:%S", tz = "GMT"))
temp_L00$monthNum       <-format(temp_L00$date, "%m")
#
# # -------------------------------------------------------------------------------------------
# # Reading Level-1
# #
# FILE_L1                 <-list.files(path = L1_DIR, pattern = glob2rx(paste(s_code,".",questo_anno,"*",sep = "")), 
#                                      all.files = FALSE,
#                                      full.names = F, recursive = FALSE,
#                                      ignore.case = FALSE, include.dirs = F, no.. = FALSE)
# EBAS_L1_FILENAME        <-as.character(FILE_L1[1])
# EBAS_L1_FILENAME
# # -------------------------------------------------------------------------------------------
# #Reading header lines of Level-1 Data sheet
# #
# L1_n_lines <- as.integer(unlist(strsplit(readLines(paste(L1_DIR,EBAS_L1_FILENAME,sep = "/"), n=1), " "))[1])
# L1_n_lines
# #
# # -------------------------------------------------------------------------------------------
# # Creating temporary data table of Level-1 
# #
# temp_L01                <-read.table(paste(L1_DIR,EBAS_L1_FILENAME,sep = "/"),skip = L1_n_lines-1,header = T)
# #
# # -------------------------------------------------------------------------------------------
# #Converting of JD values to date
# #
# temp_L01$jd             <-as.integer(temp_L01$start_time)
# #
# temp_L01$day            <-as.Date(temp_L01$start_time, origin=questa_start_time)
# temp_L01$time.dec       <-temp_L01$start_time-temp_L01$jd
# temp_L01$time           <-temp_L01$time.dec*1440+0.01
# temp_L01$hour           <-as.integer(temp_L01$time/60)
# temp_L01$min            <-as.integer(temp_L01$time-temp_L01$hour*60)
# temp_L01$date           <-paste(temp_L01$day," ",temp_L01$hour,":",temp_L01$min,":00",sep="")
# temp_L01$date           <-as.POSIXct(strptime(temp_L01$date, format = "%Y-%m-%d %H:%M:%S", tz = "GMT"))
# temp_L01$monthNum       <-format(temp_L01$date,"%m")
# temp_L01$month          <-format(temp_L01$date,"%B")
# temp_L01$day            <-format(temp_L01$date,"%d")
# #
# temp_L01$nf_validity    <-sapply(temp_L01$numflag, nf_val_check, tab_nf$numflag, tab_nf$category)
# 
# METEO_L01_today_Y          <- subset(temp_L01, nf_validity == "V")
# -------------------------------------------------------------------------------------------
# Reading Level-2
# Creating temporary data table of Level-2 
#
FILE_L2                 <-list.files(path = L2_DIR, pattern = glob2rx(paste(s_code,".",questo_anno,"*",sep = "")), all.files = FALSE,
                                     full.names = F, recursive = FALSE,
                                     ignore.case = FALSE, include.dirs = F, no.. = FALSE)
EBAS_L2_FILENAME        <-as.character(FILE_L2[1])
EBAS_L2_FILENAME
# -------------------------------------------------------------------------------------------
#Reading header lines of Level-2 Data sheet
#
L2_n_lines <- as.integer(unlist(strsplit(readLines(paste(L2_DIR,EBAS_L2_FILENAME,sep = "/"), n=1), " "))[1])
L2_n_lines
#
# -------------------------------------------------------------------------------------------
# Creating temporary data table of Level-2 
#
temp_L02                <-read.table(paste(L2_DIR,EBAS_L2_FILENAME,sep = "/"),skip = L2_n_lines-1, header = T)
#
# -------------------------------------------------------------------------------------------
# Creating a subset over L02 data
# 
temp_L02                <- subset(temp_L02, temp_L02$start_time < strptime(as.POSIXct(Sys.Date()), "%Y-%m-%d %H:%M")$yday)
#
names(temp_L02)[3]        <- "ws"
names(temp_L02)[4]        <- "flag_ws"
names(temp_L02)[5]        <- "wd" 
names(temp_L02)[6]        <- "flag_wd" 
names(temp_L02)[7]        <- "t" 
names(temp_L02)[8]        <- "flag_t" 
names(temp_L02)[9]        <- "rh" 
names(temp_L02)[10]       <- "flag_rh"
names(temp_L02)[11]       <- "p" 
names(temp_L02)[12]       <- "flag_p" 
names(temp_L02)[13]       <- "rad" 
names(temp_L02)[14]       <- "flag_rad" 
#
# -------------------------------------------------------------------------------------------
# Converting JD values to date
#
temp_L02$jd             <-as.integer(temp_L02$start_time)
#
temp_L02$day            <-as.Date(temp_L02$start_time, origin=questa_start_time)
temp_L02$time.dec       <-temp_L02$start_time-temp_L02$jd
temp_L02$time           <-temp_L02$time.dec*1440+0.01
temp_L02$hour           <-as.integer(temp_L02$time/60)
temp_L02$min            <-as.integer(temp_L02$time-temp_L02$hour*60)
temp_L02$min            <-as.integer(temp_L02$time-temp_L02$hour*60)
temp_L02$date           <-paste(temp_L02$day," ",temp_L02$hour,":",temp_L02$min,":00",sep="")
temp_L02$date           <-as.POSIXct(strptime(temp_L02$date, format = "%Y-%m-%d %H:%M:%S", tz = "GMT"))
temp_L02$month          <-format(temp_L02$date, "%B")
temp_L02$monthNum       <-format(temp_L02$date, "%m")

print(head(temp_L02, 3))
#
# -------------------------------------------------------------------------------------------
# Subsetting dataset by WS
#
ws_FAIL_today                     <- subset(temp_L02, flag_ws  > 0.900)

ws_TFAIL                          <- subset(ws_FAIL_today, select=c("month","day","flag_ws"))
ws_mesi_FAIL                      <- data.frame(ws_TFAIL[!duplicated(ws_TFAIL[1:2]),])
ws_mesi_FAIL_COUNT                <- data.frame(ws_mesi_FAIL[!duplicated(ws_mesi_FAIL[1]),],count(ws_mesi_FAIL,"month"))

if (nrow(ws_mesi_FAIL) > 0){ 
  ws_mesi_FAIL_COUNT$print        <-paste(ws_mesi_FAIL_COUNT$month," (",ws_mesi_FAIL_COUNT$freq," gg)",sep = "")
  ws_Somma_giorni_FAIL            <-sum(ws_mesi_FAIL_COUNT$freq)
} 
if (nrow(ws_mesi_FAIL) == 0){}

ws_L02_today_Y                    <- subset(temp_L02, flag_ws < 0.900)
ws_unico                          <-c (ws_L02_today_Y[!duplicated(ws_L02_today_Y[,c('month')]),]$month)
#
# -------------------------------------------------------------------------------------------
# Subsetting dataset by WD
#
wd_FAIL_today                     <- subset(temp_L02, flag_wd  > 0.900)

wd_TFAIL                         <- subset(wd_FAIL_today, select=c("month","day","flag_wd"))
wd_mesi_FAIL                     <- data.frame(wd_TFAIL[!duplicated(wd_TFAIL[1:2]),])
wd_mesi_FAIL_COUNT               <- data.frame(wd_mesi_FAIL[!duplicated(wd_mesi_FAIL[1]),],count(wd_mesi_FAIL,"month"))

if (nrow(wd_mesi_FAIL) > 0){ 
  wd_mesi_FAIL_COUNT$print       <-paste(wd_mesi_FAIL_COUNT$month," (",wd_mesi_FAIL_COUNT$freq," gg)",sep = "")
  wd_Somma_giorni_FAIL           <-sum(wd_mesi_FAIL_COUNT$freq)
} 
if (nrow(wd_mesi_FAIL) == 0){}

wd_L02_today_Y                   <- subset(temp_L02, flag_wd < 0.900)
wd_unico                         <-c (wd_L02_today_Y[!duplicated(wd_L02_today_Y[,c('month')]),]$month)
#
# -------------------------------------------------------------------------------------------
# Subsetting dataset by T
#
t_FAIL_today                <- subset(temp_L02, flag_t   > 0.900)

t_TFAIL                         <- subset(t_FAIL_today, select=c("month","day","flag_t"))
t_mesi_FAIL                     <- data.frame(t_TFAIL[!duplicated(t_TFAIL[1:2]),])
t_mesi_FAIL_COUNT               <- data.frame(t_mesi_FAIL[!duplicated(t_mesi_FAIL[1]),],count(t_mesi_FAIL,"month"))

if (nrow(t_mesi_FAIL) > 0){ 
  t_mesi_FAIL_COUNT$print       <-paste(t_mesi_FAIL_COUNT$month," (",t_mesi_FAIL_COUNT$freq," gg)",sep = "")
  t_Somma_giorni_FAIL           <-sum(t_mesi_FAIL_COUNT$freq)
} 
if (nrow(t_mesi_FAIL) == 0){}

t_L02_today_Y                   <- subset(temp_L02, flag_t < 0.900)
t_unico                         <-c (t_L02_today_Y[!duplicated(t_L02_today_Y[,c('month')]),]$month)
#
# -------------------------------------------------------------------------------------------
# Subsetting dataset by RH
#
rh_FAIL_today               <- subset(temp_L02, flag_rh  > 0.900)

rh_TFAIL                         <- subset(rh_FAIL_today, select=c("month","day","flag_rh"))
rh_mesi_FAIL                     <- data.frame(rh_TFAIL[!duplicated(rh_TFAIL[1:2]),])
rh_mesi_FAIL_COUNT               <- data.frame(rh_mesi_FAIL[!duplicated(rh_mesi_FAIL[1]),],count(rh_mesi_FAIL,"month"))

if (nrow(rh_mesi_FAIL) > 0){ 
  rh_mesi_FAIL_COUNT$print       <-paste(rh_mesi_FAIL_COUNT$month," (",rh_mesi_FAIL_COUNT$freq," gg)",sep = "")
  rh_Somma_giorni_FAIL           <-sum(rh_mesi_FAIL_COUNT$freq)
} 
if (nrow(rh_mesi_FAIL) == 0){}

rh_L02_today_Y                   <- subset(temp_L02, flag_rh < 0.900)
rh_unico                         <-c (rh_L02_today_Y[!duplicated(rh_L02_today_Y[,c('month')]),]$month)
#
# -------------------------------------------------------------------------------------------
# Subsetting dataset by P
#
p_FAIL_today                <- subset(temp_L02, flag_p   > 0.900)

p_TFAIL                         <- subset(p_FAIL_today, select=c("month","day","flag_p"))
p_mesi_FAIL                     <- data.frame(p_TFAIL[!duplicated(p_TFAIL[1:2]),])
p_mesi_FAIL_COUNT               <- data.frame(p_mesi_FAIL[!duplicated(p_mesi_FAIL[1]),],count(p_mesi_FAIL,"month"))

if (nrow(p_mesi_FAIL) > 0){ 
  p_mesi_FAIL_COUNT$print       <-paste(p_mesi_FAIL_COUNT$month," (",p_mesi_FAIL_COUNT$freq," gg)",sep = "")
  p_Somma_giorni_FAIL           <-sum(p_mesi_FAIL_COUNT$freq)
} 
if (nrow(p_mesi_FAIL) == 0){}

p_L02_today_Y                   <- subset(temp_L02, flag_p < 0.900)
p_unico                         <-c (p_L02_today_Y[!duplicated(p_L02_today_Y[,c('month')]),]$month)
#
# -------------------------------------------------------------------------------------------
# Subsetting dataset by RAD
#
rad_FAIL_today                    <- subset(temp_L02, flag_rad > 0.900)

rad_TFAIL                         <- subset(rad_FAIL_today, select=c("month","day","flag_rad"))
rad_mesi_FAIL                     <- data.frame(rad_TFAIL[!duplicated(rad_TFAIL[1:2]),])
rad_mesi_FAIL_COUNT               <- data.frame(rad_mesi_FAIL[!duplicated(rad_mesi_FAIL[1]),],count(rad_mesi_FAIL,"month"))

if (nrow(rad_mesi_FAIL) > 0){ 
  rad_mesi_FAIL_COUNT$print       <-paste(rad_mesi_FAIL_COUNT$month," (",rad_mesi_FAIL_COUNT$freq," gg)",sep = "")
  rad_Somma_giorni_FAIL           <-sum(rad_mesi_FAIL_COUNT$freq)
} 
if (nrow(rad_mesi_FAIL) == 0){}

rad_L02_today_Y                   <- subset(temp_L02, flag_rad < 0.900)
rad_unico                         <-c (rad_L02_today_Y[!duplicated(rad_L02_today_Y[,c('month')]),]$month)
#
# -------------------------------------------------------------------------------------------
#
##                                         # END PART 2.0 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.0 #
## ______________________________________________________________________________________________________________________##
##                                    Creating statistcs/graphic reports
##                                               MONTHLY GRAPHS
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Subsetting data by month
#
ws_unico_M              <-c(ws_L02_today_Y [!duplicated(ws_L02_today_Y [,c('monthNum')]),]$monthNum)
wd_unico_M              <-c(wd_L02_today_Y [!duplicated(wd_L02_today_Y [,c('monthNum')]),]$monthNum)
t_unico_M               <-c(t_L02_today_Y  [!duplicated(t_L02_today_Y  [,c('monthNum')]),]$monthNum)
rh_unico_M              <-c(rh_L02_today_Y [!duplicated(rh_L02_today_Y [,c('monthNum')]),]$monthNum)
p_unico_M               <-c(p_L02_today_Y  [!duplicated(p_L02_today_Y  [,c('monthNum')]),]$monthNum)
rad_unico_M             <-c(rad_L02_today_Y[!duplicated(rad_L02_today_Y[,c('monthNum')]),]$monthNum)

for (qm in na.omit(wd_unico_M))
{print(qm)   
  #
  # -------------------------------------------------------------------------------------------
  # Defining month
  #
  temp_L02_ThisMonth    <-subset(temp_L02, monthNum==qm)
  #
  # -------------------------------------------------------------------------------------------
  # Subsetting dataset by monthly values of WS
  #
  ws_L02_ThisMonth      <-subset(ws_L02_today_Y, monthNum==qm)
  ws_temp_L02_ThisMonth <-subset(temp_L02, monthNum==qm)
  
  OBS_Month_start       <-head(format(ws_temp_L02_ThisMonth$date,"%d %B %Y"),1)
  OBS_Month_end         <-tail(format(ws_temp_L02_ThisMonth$date,"%d %B %Y"),1)
  
  ws_FAIL_ThisMonth     <-subset(ws_temp_L02_ThisMonth, flag_ws >0.900)
  ws_FAIL_ThisMonth$day <-format(ws_FAIL_ThisMonth$date,"%d")
  ws_FAIL_unico         <-data.frame(ws_FAIL_ThisMonth[!duplicated(ws_FAIL_ThisMonth[,c('day')]),])
  ws_FAIL_DAYS          <-nrow(ws_FAIL_unico)
  
  ws_mensile            <-subset(ws_L02_ThisMonth, flag_ws<0.900)
  ws_mensile$giorno     <-format(ws_mensile$date,"%d")
  ws_This_Month         <-format(ws_mensile$date,"%m")[1]
  ws_This_Month_Name    <-format(ws_mensile$date,"%B")[1]
  
  ws_men_MIN            <-subset(ws_mensile, ws == min(ws_mensile$ws))
  ws_men_MAX            <-subset(ws_mensile, ws == max(ws_mensile$ws))
  
  print(paste("ws ",ws_This_Month_Name[1], ws_FAIL_DAYS))
  #
  # -------------------------------------------------------------------------------------------
  # Subsetting dataset by monthly values of WD
  #  
  wd_L02_ThisMonth       <-subset(wd_L02_today_Y, monthNum==qm)
  wd_temp_L02_ThisMonth  <-subset(temp_L02, monthNum==qm)
  
  OBS_Month_start     <-head(format(wd_temp_L02_ThisMonth$date,"%d %B %Y"),1)
  OBS_Month_end       <-tail(format(wd_temp_L02_ThisMonth$date,"%d %B %Y"),1)
  
  wd_FAIL_ThisMonth      <-subset(wd_temp_L02_ThisMonth, flag_wd>0.900)
  wd_FAIL_ThisMonth$day  <-format(wd_FAIL_ThisMonth$date,"%d")
  wd_FAIL_unico          <-data.frame(wd_FAIL_ThisMonth[!duplicated(wd_FAIL_ThisMonth[,c('day')]),])
  wd_FAIL_DAYS           <-nrow(wd_FAIL_unico)
  
  wd_mensile             <-subset(wd_L02_ThisMonth, flag_wd<0.900)
  wd_mensile$giorno      <-format(wd_mensile$date,"%d")
  wd_This_Month          <-format(wd_mensile$date,"%m")[1]
  wd_This_Month_Name     <-format(wd_mensile$date,"%B")[1]
  
  wd_men_MIN             <-subset(wd_mensile, wd == min(ws_mensile$wd))
  wd_men_MAX             <-subset(wd_mensile, wd == max(ws_mensile$wd))
  
  print(paste("wd ",wd_This_Month_Name[1], wd_FAIL_DAYS))
  #
  # -------------------------------------------------------------------------------------------
  # Subsetting dataset by monthly values of T
  #    
  t_L02_ThisMonth       <-subset(t_L02_today_Y, monthNum==qm)
  t_temp_L02_ThisMonth  <-subset(temp_L02, monthNum==qm)
  
  OBS_Month_start     <-head(format(t_temp_L02_ThisMonth$date,"%d %B %Y"),1)
  OBS_Month_end       <-tail(format(t_temp_L02_ThisMonth$date,"%d %B %Y"),1)
  
  t_FAIL_ThisMonth      <-subset(t_temp_L02_ThisMonth, flag_t>0.900)
  t_FAIL_ThisMonth$day  <-format(t_FAIL_ThisMonth$date,"%d")
  t_FAIL_unico          <-data.frame(t_FAIL_ThisMonth[!duplicated(t_FAIL_ThisMonth[,c('day')]),])
  t_FAIL_DAYS           <-nrow(t_FAIL_unico)
  
  t_mensile             <-subset(t_L02_ThisMonth, flag_t<0.900)
  t_mensile$giorno      <-format(t_mensile$date,"%d")
  t_This_Month          <-format(t_mensile$date,"%m")[1]
  t_This_Month_Name     <-format(t_mensile$date,"%B")[1]
  
  t_men_MIN             <-subset(t_mensile, t == min(t_mensile$t))
  t_men_MAX             <-subset(t_mensile, t == max(t_mensile$t))
  
  print(paste("t ",t_This_Month_Name[1], t_FAIL_DAYS))
  #
  # -------------------------------------------------------------------------------------------
  # Subsetting dataset by monthly values of RH
  # 
  rh_L02_ThisMonth       <-subset(rh_L02_today_Y, monthNum==qm)
  rh_temp_L02_ThisMonth  <-subset(temp_L02, monthNum==qm)
  
  OBS_Month_start     <-head(format(rh_temp_L02_ThisMonth$date,"%d %B %Y"),1)
  OBS_Month_end       <-tail(format(rh_temp_L02_ThisMonth$date,"%d %B %Y"),1)
  
  rh_FAIL_ThisMonth      <-subset(rh_temp_L02_ThisMonth, flag_rh>0.900)
  rh_FAIL_ThisMonth$day  <-format(rh_FAIL_ThisMonth$date,"%d")
  rh_FAIL_unico          <-data.frame(rh_FAIL_ThisMonth[!duplicated(rh_FAIL_ThisMonth[,c('day')]),])
  rh_FAIL_DAYS           <-nrow(rh_FAIL_unico)
  
  rh_mensile             <-subset(rh_L02_ThisMonth, flag_rh<0.900)
  rh_mensile$giorno      <-format(rh_mensile$date,"%d")
  rh_This_Month          <-format(rh_mensile$date,"%m")[1]
  rh_This_Month_Name     <-format(rh_mensile$date,"%B")[1]
  
  rh_men_MIN             <-subset(rh_mensile, rh == min(rh_mensile$rh))
  rh_men_MAX             <-subset(rh_mensile, rh == max(rh_mensile$rh))
  
  print(paste("rh ",rh_This_Month_Name[1], rh_FAIL_DAYS))
  #
  # -------------------------------------------------------------------------------------------
  # Subsetting dataset by monthly values of P
  #   
  p_L02_ThisMonth       <-subset(p_L02_today_Y, monthNum==qm)
  p_temp_L02_ThisMonth  <-subset(temp_L02, monthNum==qm)
  
  OBS_Month_start     <-head(format(p_temp_L02_ThisMonth$date,"%d %B %Y"),1)
  OBS_Month_end       <-tail(format(p_temp_L02_ThisMonth$date,"%d %B %Y"),1)
  
  p_FAIL_ThisMonth      <-subset(p_temp_L02_ThisMonth, flag_p>0.900)
  p_FAIL_ThisMonth$day  <-format(p_FAIL_ThisMonth$date,"%d")
  p_FAIL_unico          <-data.frame(p_FAIL_ThisMonth[!duplicated(p_FAIL_ThisMonth[,c('day')]),])
  p_FAIL_DAYS           <-nrow(p_FAIL_unico)
  
  p_mensile             <-subset(p_L02_ThisMonth, flag_p<0.900)
  p_mensile$giorno      <-format(p_mensile$date,"%d")
  p_This_Month          <-format(p_mensile$date,"%m")[1]
  p_This_Month_Name     <-format(p_mensile$date,"%B")[1]
  
  p_men_MIN             <-subset(p_mensile, p == min(p_mensile$p))
  p_men_MAX             <-subset(p_mensile, p == max(p_mensile$p))
  
  print(paste("p ",p_This_Month_Name[1], p_FAIL_DAYS))
  #
  # -------------------------------------------------------------------------------------------
  # Subsetting dataset by monthly values of RAD
  #   
  rad_L02_ThisMonth       <-subset(rad_L02_today_Y, monthNum==qm)
  rad_temp_L02_ThisMonth  <-subset(temp_L02, monthNum==qm)
  
  OBS_Month_start     <-head(format(rad_temp_L02_ThisMonth$date,"%d %B %Y"),1)
  OBS_Month_end       <-tail(format(rad_temp_L02_ThisMonth$date,"%d %B %Y"),1)
  
  rad_FAIL_ThisMonth      <-subset(rad_temp_L02_ThisMonth, flag_rad>0.900)
  rad_FAIL_ThisMonth$day  <-format(rad_FAIL_ThisMonth$date,"%d")
  rad_FAIL_unico          <-data.frame(rad_FAIL_ThisMonth[!duplicated(rad_FAIL_ThisMonth[,c('day')]),])
  rad_FAIL_DAYS           <-nrow(rad_FAIL_unico)
  
  rad_mensile             <-subset(rad_L02_ThisMonth, flag_rad<0.900)
  rad_mensile$giorno      <-format(rad_mensile$date,"%d")
  rad_This_Month          <-format(rad_mensile$date,"%m")[1]
  rad_This_Month_Name     <-format(rad_mensile$date,"%B")[1]
  
  rad_men_MIN             <-subset(rad_mensile, rad == min(rad_mensile$rad))
  rad_men_MAX             <-subset(rad_mensile, rad == max(rad_mensile$rad))
  
  print(paste("rad ",rad_This_Month_Name[1], rad_FAIL_DAYS))
  #
  # -------------------------------------------------------------------------------------------
  # Cleaning Destination directory
  # 
  FILE_PLOT_M<-list.files(path = PLOT_DIR_M, pattern = paste(s_GAW_ID,inst_type,questo_anno,ws_This_Month,"MONTHLY_GRAPH_*",sep = "_"), 
                          all.files = FALSE,
                          full.names = F, recursive = FALSE,
                          ignore.case = FALSE, include.dirs = F, no.. = FALSE)
  FILE_PLOT_M
  LISTA_PLOT_M<-as.character(FILE_PLOT_M)
  for(f in LISTA_PLOT_M)
  {
    file.remove(paste(PLOT_DIR_M,f,sep = "/"))
  }
  #
  # -------------------------------------------------------------------------------------------
  # Preparing plotting files
  # 
  PLOT_M_NAME         <-paste(s_GAW_ID, inst_type, questo_anno, ws_This_Month, "MONTHLY_GRAPH", gsub("-","",Sys.Date()), sep = "_")
  PLOT_M_NAME_FULL    <-paste (PLOT_DIR_M,paste(PLOT_M_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_M_NAME_FULL, width = 2480, height = 3508)
  #
  # -------------------------------------------------------------------------------------------
  # Preparing plotting parameters (font size, margins, ...)
  # 
  par(mfrow = c(7,1))  #  par(mfrow = c(8,1))
  par(ps = 14, cex = 2, cex.main = 3.5,cex.sub=2.2, cex.lab=2.8, cex.axis = 2.2, mai=c(0.3,1.8,0.5,0.5))
  #
  # -------------------------------------------------------------------------------------------
  # Crating the plotting matrix
  #
  m <- rbind(c(1, 1), c(2, 2), c(3, 3), c(4, 4), c(5, 5), c(6, 6), c(7, 8))
  layout(m)
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting WS
  #
  if(nrow(ws_mensile) > 0 )
  {
  plot(ylim=c(-0.1,max(ws_mensile$ws)+0.2),
       xlim = c(min(temp_L02_ThisMonth$date),max(temp_L02_ThisMonth$date)),
        mgp = c(8, 4, 0),
       ws_L02_ThisMonth$date, ws_mensile$ws, type = "h",
       xlab = "",ylab =("WS (m/s) - L02"), col="darkseagreen1", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
  title(paste("Wind speed - L02 -",questo_anno,ws_This_Month_Name), line = -3)
  lines(ws_L02_ThisMonth$date, ws_mensile$ws, type = "l", lty = 1, col="darkred",lwd = 2)
  
  points(ws_men_MAX$date[1], ws_men_MAX$ws[1], col= "magenta",pch=20)
  text(ws_men_MAX$date[1], ws_men_MIN$ws[1], labels = paste("Max (", format(ws_men_MAX$date[1],"%B %d"), ")", sep=""),col="magenta",pos=1,cex = 1.8)
  segments(ws_men_MAX$date[1], ws_men_MAX$ws[1], ws_men_MAX$date[1], ws_men_MIN$ws[1]-0.02, lty = 2, col="black",lwd = 1)

  points(ws_men_MIN$date[1], ws_men_MIN$ws[1], col= "blue",pch=20)
  text(ws_men_MIN$date[1], ws_men_MIN$ws[1], labels = paste("Min (", format(ws_men_MIN$date[1],"%B %d"), ")", sep =""),col="blue",pos=1,cex = 1.8)
  segments(ws_men_MIN$date[1], ws_men_MIN$ws[1], ws_men_MIN$date[1], ws_men_MIN$ws[1]-0.02, lty = 2, col="black",lwd = 1)
  }
  if(nrow(ws_mensile) == 0 )
  { 
    temp_L02_ThisMonth$rad[temp_L02_ThisMonth$rad > 900] <- 0
    
    plot(ylim = c(-30,100),
         xlim = c(min(temp_L02_ThisMonth$date),max(temp_L02_ThisMonth$date)),
         temp_L02_ThisMonth$date, temp_L02_ThisMonth$rad, type = "l",
         xlab = "",ylab =("WS (m/s) - L02"), col="goldenrod", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
    title(paste("Wind speed - L02 - data for this month are absent"), line = -3)
    
    title(paste("No data"), line = -28, cex = 0.8)
  }  
  # 
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting WD
  #
  if(nrow(wd_mensile) > 0 )
  {
  plot(ylim=c(-15,400),
       xlim = c(min(temp_L02_ThisMonth$date),max(temp_L02_ThisMonth$date)),
       mgp = c(8, 4, 0),
       wd_mensile$date, wd_mensile$wd, type = "h",
       xlab = "",ylab =("WD (deg) - L02"), col="paleturquoise", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
  title(paste("Wind direction - L02",questo_anno,wd_This_Month_Name), line = -3)
  
  lines(wd_mensile$date, wd_mensile$wd, type = "l", lty = 1, col="darkblue",lwd = 2)
  
  segments(head(wd_mensile$date), 360, tail(wd_mensile$date), 360, lty = 1, col="midnightblue",lwd = 0.5)
  text(wd_mensile$date[1],368, labels = c("360°"),col="midnightblue",cex = 1.8)
  
  segments(head(wd_mensile$date), 270, tail(wd_mensile$date), 270, lty = 1, col="dodgerblue3",lwd = 0.5)
  text(wd_mensile$date[1],278, labels = c("270°"),col="dodgerblue3",cex = 1.8)
  
  segments(head(wd_mensile$date), 180, tail(wd_mensile$date), 180, lty = 1, col="steelblue4",lwd = 0.5)
  text(wd_mensile$date[1],188, labels = c("180°"),col="steelblue4",cex = 1.8)
  
  segments(head(wd_mensile$date), 90, tail(wd_mensile$date), 90, lty = 1, col="lightskyblue3",lwd = 0.5)
  text(wd_mensile$date[1],98, labels = c("90°"),col="lightskyblue3",cex = 1.8)
  }
  if(nrow(wd_mensile) == 0 )
  { 
    temp_L02_ThisMonth$rad[temp_L02_ThisMonth$rad > 900] <- 0
    
    plot(ylim = c(-30,100),
         xlim = c(min(temp_L02_ThisMonth$date),max(temp_L02_ThisMonth$date)),
         temp_L02_ThisMonth$date, temp_L02_ThisMonth$rad, type = "l",
         xlab = "",ylab =("WD (deg) - L02"), col="goldenrod", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
    title(paste("Wind direction - L02 - data for this month are absent"), line = -3)
    
    title(paste("No data"), line = -28, cex = 0.8)
  } 
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting T
  #
  if(nrow(t_mensile) > 0 )
  {
  plot(ylim=c(min(t_mensile$t)-1,max(t_mensile$t)+1),
       xlim = c(min(temp_L02_ThisMonth$date),max(temp_L02_ThisMonth$date)),
       mgp = c(8, 4, 0),
       t_L02_ThisMonth$date, t_mensile$t, type = "h",
       xlab = "",ylab =("T (°C) - L02"), col="darksalmon", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
  title(paste("Temperature - L02 -",questo_anno,t_This_Month_Name), line = -3)
  lines(t_L02_ThisMonth$date, t_mensile$t, type = "l", lty = 1, col="darkred",lwd = 2)
  
  points(t_men_MAX$date[1], t_men_MAX$t[1], col= "magenta",pch=20)
  text(t_men_MAX$date[1], t_men_MIN$t[1], labels = paste("Max (", format(t_men_MAX$date[1],"%B %d"), ")", sep=""),col="magenta",pos=1,cex = 1.8)
  segments(t_men_MAX$date[1], t_men_MAX$t[1], t_men_MAX$date[1], t_men_MIN$t[1]-0.02, lty = 2, col="black",lwd = 1)

  points(t_men_MIN$date[1], t_men_MIN$t[1], col= "blue",pch=20)
  text(t_men_MIN$date[1], t_men_MIN$t[1], labels = paste("Min (", format(t_men_MIN$date[1],"%B %d"), ")", sep=""),col="blue",pos=1,cex = 1.8)
  segments(t_men_MIN$date[1], t_men_MIN$t[1], t_men_MIN$date[1], t_men_MIN$t[1]-0.02, lty = 2, col="black",lwd = 1)

  segments(head(t_mensile$date), 0, tail(t_mensile$date), 0, lty = 1, col="midnightblue",lwd = 1)
  text(t_mensile$date[1],0.5, labels = c("0°C"),col="midnightblue",cex = 1.8) 
  }
  if(nrow(t_mensile) == 0 )
  { 
    temp_L02_ThisMonth$rad[temp_L02_ThisMonth$rad > 900] <- 0
    
    plot(ylim = c(-30,100),
         xlim = c(min(temp_L02_ThisMonth$date),max(temp_L02_ThisMonth$date)),
         temp_L02_ThisMonth$date, temp_L02_ThisMonth$rad, type = "l",
         xlab = "",ylab =("T (°C) - L02"), col="goldenrod", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
    title(paste("Temperature - L02 - data for this month are absent"), line = -3)
    
    title(paste("No data"), line = -28, cex = 0.8)
  } 
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting RH
  #
  if(nrow(rh_mensile) > 0 )
  {
  plot(ylim=c(min(rh_mensile$rh)-10,140),
       xlim = c(min(temp_L02_ThisMonth$date),max(temp_L02_ThisMonth$date)),
       mgp = c(8, 4, 0),
       rh_L02_ThisMonth$date, rh_mensile$rh, type = "h",
       xlab = "",ylab =("RH (%) - L02"), col="slategray2", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
  title(paste("Relative humidity - L02 -",questo_anno,rh_This_Month_Name), line = -3)
  lines(rh_L02_ThisMonth$date, rh_mensile$rh, type = "l", lty = 1, col="darkred",lwd = 2)
  
  points(rh_men_MAX$date[1], rh_men_MAX$rh[1], col= "magenta",pch=20)
  text(rh_men_MAX$date[1], rh_men_MIN$rh[1], labels = paste("Max (", format(rh_men_MAX$date[1],"%B %d"), ")", sep=""),col="magenta",pos=1,cex = 1.8)
  segments(rh_men_MAX$date[1], rh_men_MAX$rh[1], rh_men_MAX$date[1], rh_men_MIN$rh[1]-0.02, lty = 2, col="black",lwd = 1)

  points(rh_men_MIN$date[1], rh_men_MIN$rh[1], col= "blue",pch=20)
  text(rh_men_MIN$date[1], rh_men_MIN$rh[1], labels = paste("Min (", format(rh_men_MIN$date[1],"%B %d"), ")", sep=""),col="blue",pos=1,cex = 1.8)
  segments(rh_men_MIN$date[1], rh_men_MIN$rh[1], rh_men_MIN$date[1], rh_men_MIN$rh[1]-0.02, lty = 2, col="black",lwd = 1)
  }
  if(nrow(rh_mensile) == 0 )
  { 
    temp_L02_ThisMonth$rad[temp_L02_ThisMonth$rad > 900] <- 0
    
    plot(ylim = c(-30,100),
         xlim = c(min(temp_L02_ThisMonth$date),max(temp_L02_ThisMonth$date)),
         temp_L02_ThisMonth$date, temp_L02_ThisMonth$rad, type = "l",
         xlab = "",ylab =("RH (%%) - L02"), col="goldenrod", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
    title(paste("Relative humidity - L02 - data for this month are absent"), line = -3)
    
    title(paste("No data"), line = -28, cex = 0.8)
  }
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting P
  #
  if(nrow(p_mensile) > 0 )
  {
  plot(ylim=c(min(p_mensile$p)-7,max(p_mensile$p)+7),
       xlim = c(min(temp_L02_ThisMonth$date),max(temp_L02_ThisMonth$date)),
       mgp = c(8, 4, 0),
       p_L02_ThisMonth$date, p_mensile$p, type = "h",
       xlab = "",ylab =("P (hPa) - L02"), col="thistle3", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
  title(paste("Pressure - L02 -",questo_anno,p_This_Month_Name), line = -3)
  lines(p_L02_ThisMonth$date, p_mensile$p, type = "l", lty = 1, col="darkred",lwd = 2)
  
  points(p_men_MAX$date[1], p_men_MAX$p[1], col= "magenta",pch=20)
  text(p_men_MAX$date[1], p_men_MIN$p[1], labels = paste("Max (", format(p_men_MAX$date[1],"%B %d"), ")", sep=""),col="magenta",pos=1,cex = 1.8)
  segments(p_men_MAX$date[1], p_men_MAX$p[1], p_men_MAX$date[1], p_men_MIN$p[1]-0.02, lty = 2, col="black",lwd = 1)

  points(p_men_MIN$date[1], p_men_MIN$p[1], col= "blue",pch=20)
  text(p_men_MIN$date[1], p_men_MIN$p[1], labels = paste("Min (", format(p_men_MIN$date[1],"%B %d"), ")", sep=""),col="blue",pos=1,cex = 1.8)
  segments(p_men_MIN$date[1], p_men_MIN$p[1], p_men_MIN$date[1], p_men_MIN$p[1]-0.02, lty = 2, col="black",lwd = 1)
  }
  if(nrow(p_mensile) == 0 )
  { 
    temp_L02_ThisMonth$rad[temp_L02_ThisMonth$rad > 900] <- 0
    
    plot(ylim = c(-30,100),
         xlim = c(min(temp_L02_ThisMonth$date),max(temp_L02_ThisMonth$date)),
         temp_L02_ThisMonth$date, temp_L02_ThisMonth$rad, type = "l",
         xlab = "",ylab =("P (hPa) - L02"), col="goldenrod", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
    title(paste("Pressure - L02 - data for this month are absent"), line = -3)
    
    title(paste("No data"), line = -28, cex = 0.8)
  }
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting RAD
  #
  if(nrow(rad_mensile) > 0 )
  {
  plot(ylim = c(-30,max(rad_mensile$rad)[1]+20),
       xlim = c(min(temp_L02_ThisMonth$date),max(temp_L02_ThisMonth$date)),
       mgp = c(8, 4, 0),
       rad_L02_ThisMonth$date, rad_mensile$rad, type = "h",
       xlab = "",ylab =expression(paste("RAD (W/m"^{2},") - L02")), col="goldenrod", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
  title(paste("Global radiation - L02 -",questo_anno,rad_This_Month_Name), line = -3)
  lines(rad_L02_ThisMonth$date, rad_mensile$rad, type = "l", lty = 1, col="darkred",lwd = 2)
  
  points(rad_men_MAX$date[1], rad_men_MAX$rad[1], col= "magenta",pch=20)
  text(rad_men_MAX$date[1], rad_men_MIN$rad[1], labels = paste("Max (", format(rad_men_MAX$date[1],"%B %d"), ")", sep=""),col="magenta",pos=1,cex = 1.8)
  segments(rad_men_MAX$date[1], rad_men_MAX$rad[1], rad_men_MAX$date[1], rad_men_MIN$rad[1]-0.02, lty = 2, col="black",lwd = 1)

  points(rad_men_MIN$date[1], rad_men_MIN$rad[1], col= "blue",pch=20)
  text(rad_men_MIN$date[1], rad_men_MIN$rad[1], labels = paste("Min (", format(p_men_MIN$date[1],"%B %d"), ")", sep=""),col="blue",pos=1,cex = 1.8)
  segments(rad_men_MIN$date[1], rad_men_MIN$rad[1], rad_men_MIN$date[1], rad_men_MIN$rad[1]-0.02, lty = 2, col="black",lwd = 1)
  }
  if(nrow(rad_mensile) == 0 )
  { 
    temp_L02_ThisMonth$rad[temp_L02_ThisMonth$rad > 900] <- 0
    
    plot(ylim = c(-30,100),
         xlim = c(min(temp_L02_ThisMonth$date),max(temp_L02_ThisMonth$date)),
         temp_L02_ThisMonth$date, temp_L02_ThisMonth$rad, type = "l",
         xlab = "",ylab =expression(paste("RAD (W/m"^{2},") - L02")), col="goldenrod", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
    title(paste("Global radiation - L02 - data for this month are absent"), line = -3,cex = 1.8)
    
    title(paste("No data"), line = -28, cex = 0.8)
  }
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting Text

  plot(c(0, 1), c(0, 1), ann = F, bty = 'n', type = 'n', xaxt = 'n', yaxt = 'n')
  text(x = 0, y = 0.95, paste (PLOT_M_NAME,"  -  ",ws_This_Month_Name," ",questo_anno),
       cex = 3.1, col = "darkred",pos = 4)
  
  text(x = -0.005, y = 0.37, paste(" Observations from ", OBS_Month_start," to ", OBS_Month_end,
                                   "\n",
                                   "(Days of observation: ", 1+(as.integer(tail((ws_mensile$date),1)-head((ws_mensile$date)),1)),")","\n","\n",
                                   
                                   "WS min: (", round(min(ws_mensile$ws),1),") - WS max: (", round(max(ws_mensile$ws),1),") - WS mean: (", round(mean(ws_mensile$ws),1),") - WS sd: (", round(sd(ws_mensile$ws),1),")","\n",
                                   "WS percentile:    5th: (",round(quantile(ws_mensile$ws, probs = c(0.05)),digits=1),")",
                                   " - 25th: (",round(quantile(ws_mensile$ws, probs = c(0.25)),digits=1),")",
                                   " - 50th: (",round(quantile(ws_mensile$ws, probs = c(0.50)),digits=1),")",
                                   " - 75th: (",round(quantile(ws_mensile$ws, probs = c(0.75)),digits=1),")",
                                   " - 95th: (",round(quantile(ws_mensile$ws, probs = c(0.95)),digits=1),")","\n","\n",
                                   
                                   "T min: (", round(min(t_mensile$t),1),") - T max: (", round(max(t_mensile$t),1),") - T mean: (", round(mean(t_mensile$t),1),") - T sd: (", round(sd(t_mensile$t),1),")","\n",
                                   "T percentile:    5th: (",round(quantile(t_mensile$t, probs = c(0.05)),digits=1),")",
                                   " - 25th: (",round(quantile(t_mensile$t, probs = c(0.25)),digits=1),")",
                                   " - 50th: (",round(quantile(t_mensile$t, probs = c(0.50)),digits=1),")",
                                   " - 75th: (",round(quantile(t_mensile$t, probs = c(0.75)),digits=1),")",
                                   " - 95th: (",round(quantile(t_mensile$t, probs = c(0.95)),digits=1),")","\n","\n",
                                   sep="")
       , cex = 2.8, col = "black",pos = 4)
  
  plot(c(0, 1), c(0, 1), ann = F, bty = 'n', type = 'n', xaxt = 'n', yaxt = 'n')
  text(x = 0, y = 0.95, paste ("Statistics  -  ",ws_This_Month_Name," ",questo_anno),
       cex = 3.1, col = "darkred",pos = 4)  
  
  text(x = 0, y = 0.38, paste("\n", 
                              
                              "RH min: (", round(min(rh_mensile$rh),1),") - RH max: (", round(max(rh_mensile$rh),1),") - RH mean: (", round(mean(rh_mensile$rh),1),") - RH sd: (", round(sd(rh_mensile$rh),1),")","\n",
                              "RH percentile:    5th: (",round(quantile(rh_mensile$rh, probs = c(0.05)),digits=1),")",
                              " - 25th: (",round(quantile(rh_mensile$rh, probs = c(0.25)),digits=1),")",
                              " - 50th: (",round(quantile(rh_mensile$rh, probs = c(0.50)),digits=1),")",
                              " - 75th: (",round(quantile(rh_mensile$rh, probs = c(0.75)),digits=1),")",
                              " - 95th: (",round(quantile(rh_mensile$rh, probs = c(0.95)),digits=1),")","\n","\n",
                              
                              "P min: (", round(min(p_mensile$p),1),") - P max: (", round(max(p_mensile$p),1),") - P mean: (", round(mean(p_mensile$p),1),") - P sd: (", round(sd(p_mensile$p),1),")","\n",
                              "P percentile:    5th: (",round(quantile(p_mensile$p, probs = c(0.05)),digits=1),")",
                              " - 25th: (",round(quantile(p_mensile$p, probs = c(0.25)),digits=1),")",
                              " - 50th: (",round(quantile(p_mensile$p, probs = c(0.50)),digits=1),")",
                              " - 75th: (",round(quantile(p_mensile$p, probs = c(0.75)),digits=1),")",
                              " - 95th: (",round(quantile(p_mensile$p, probs = c(0.95)),digits=1),")","\n","\n",
                              
                              "RAD min: (", round(min(rad_mensile$rad),1),") - RAD max: (", round(max(rad_mensile$rad),1),") - RAD mean: (", round(mean(rad_mensile$rad),1),") - RAD sd: (", round(sd(rad_mensile$rad),1),")","\n",
                              "RAD percentile:    5th: (",round(quantile(rad_mensile$rad, probs = c(0.05)),digits=1),")",
                              " - 25th: (",round(quantile(rad_mensile$rad, probs = c(0.25)),digits=1),")",
                              " - 50th: (",round(quantile(rad_mensile$rad, probs = c(0.50)),digits=1),")",
                              " - 75th: (",round(quantile(rad_mensile$rad, probs = c(0.75)),digits=1),")",
                              " - 95th: (",round(quantile(rad_mensile$rad, probs = c(0.95)),digits=1),")","\n","\n",
                              sep=""),
       cex = 2.8, col = "black",pos = 4) 
  
  dev.off()
  
}

#
# -------------------------------------------------------------------------------------------
##                                        # END PART 3.0 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.1 #
## ______________________________________________________________________________________________________________________##
##                                    Creating statistcs/graphic reports
##                                              WS SEMESTER GRAPHS
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Subsetting data by semester
# First semester
#
Fhalf           <-subset(ws_L02_today_Y,as.numeric(monthNum) < 7)

if (nrow(Fhalf)==0){ } else 
{
  # -------------------------------------------------------------------------------------------
  # Cleaning Destination directory
  # 
  FILE_PLOT_1HM<-list.files(path = PLOT_DIR_M, pattern = paste(s_GAW_ID, inst_type,"WS",questo_anno,"SEMESTER_1st_GRAPH_*",sep = "_"), all.files = FALSE,
                            full.names = F, recursive = FALSE,
                            ignore.case = FALSE, include.dirs = F, no.. = FALSE)
  
  FILE_PLOT_1HM
  LISTA_PLOT_1HM<-as.character(FILE_PLOT_1HM)
  for(f in LISTA_PLOT_1HM)
  {
    file.remove(paste(PLOT_DIR_M,f,sep = "/"))
  }
  #
  # -------------------------------------------------------------------------------------------
  # Preparing plotting files
  #   
  unico<-c(Fhalf[!duplicated(Fhalf[,c('month')]),]$month)
  #
  # -------------------------------------------------------------------------------------------
  # Preparing plotting parameters (font size, margins, ...)
  # 
  png(file=paste(PLOT_DIR_M,paste(s_GAW_ID,"_",inst_type,"_WS_",questo_anno,"_SEMESTER_1st_GRAPH_",gsub("-","",Sys.Date()),".png",sep = ""),sep = "/"),
      width = 2480, height = 3508)
  #
  # -------------------------------------------------------------------------------------------
  # Creating the plotting matrix
  #
  # layout(matrix(c(1,2,3,4,5,6,7),ncol=1), widths=c(10,10,10,10,10,10,10), heights=c(2.2,2.2,2.2,2.2,2.2,2.2,0.2), TRUE) 
  # par(ps = 12, cex = 1.8, cex.main = 1.8,cex.sub=1.8, cex.lab=1.8, cex.axis = 1.5, mai=c(0.3,1.8,0.5,0.5))  # make labels and margins smaller (mai= giu, sx,su,dx)
  par(mfrow = c(6,1))
  par(ps = 14, cex = 1.8, cex.main = 2, cex.lab=1, cex.axis = 1, mai=c(0.3,1.8,0.5,0.5))  # make labels and margins smaller (mai= giu, sx,su,dx)
  
  for (i in unico[1:length(unico)])
  {
    print(i)
    temp_L02_ThisSemester<-subset(temp_L02, month == i)
    mensile         <-subset(ws_L02_today_Y, month == i)
    mensile$giorno  <-format(mensile$date,"%d")
    mensile$mean    <-mean(mensile$ws)
    mensile$sd      <-sd(mensile$ws)    
    men_MIN         <-subset(mensile, ws == min(mensile$ws))
    men_MAX         <-subset(mensile, ws == max(mensile$ws))
    {
      plot(ylim=c(-2,max(mensile$ws)+5),
           xlim = c(min(temp_L02_ThisSemester$date),max(temp_L02_ThisSemester$date)),
           mensile$date, mensile$ws, type = "h",
           xlab = "",
           ylab =("WS (m/s) - L02"), col="darkseagreen1", panel.first = grid(nx=3,ny=NULL, lty = 1, lwd = 1))
      title(main=paste(i,questo_anno,sep=" "),
            line = -2.2)
      
      title(paste("Statistics: min: (", round(min(mensile$ws),1),") - max: (", round(max(mensile$ws),1),") - mean: (", round(mean(mensile$ws),1),") - sd: (", round(sd(mensile$ws),1),")")
            ,col="black",cex.main = 1.2, line = -3.8, font.main = 1)
      
      lines(mensile$date, mensile$ws, type = "l", lty = 1, col="darkred",lwd = 2)

      text(men_MAX$date[1], men_MIN$ws[1]-1, labels = paste("Max (",format(men_MAX$date[1],"%B %d"),")",sep=""),col="magenta",pos=1)
      segments(men_MAX$date[1], men_MAX$ws[1], men_MAX$date[1], -1, lty = 2, col="black",lwd = 1)

      points(men_MAX$date[1], men_MAX$ws[1], col= "blue",pch=20)
      text(men_MIN$date[1], men_MIN$ws[1]-1, labels = paste("Min (",format(men_MIN$date[1],"%B %d"),")",sep=""),col="blue",pos=1)
      segments(men_MIN$date[1], men_MIN$ws[1], men_MIN$date[1], -1, lty = 2, col="black",lwd = 1)
    }   
  }
  dev.off() 
}

#
# -------------------------------------------------------------------------------------------
# Subsetting data by semester
# Second semester
#
Shalf<-subset(ws_L02_today_Y,as.numeric(monthNum) > 6)
if (nrow(Shalf)==0){}else 
{
  # -------------------------------------------------------------------------------------------
  # Cleaning Destination directory
  # 
  FILE_PLOT_2HM<-list.files(path = PLOT_DIR_M, pattern = paste(s_GAW_ID, inst_type,"WS",questo_anno,"SEMESTER_2nd_GRAPH_*",sep = "_"), all.files = FALSE,
                            full.names = F, recursive = FALSE,
                            ignore.case = FALSE, include.dirs = F, no.. = FALSE)
  FILE_PLOT_2HM
  LISTA_PLOT_2HM<-as.character(FILE_PLOT_2HM)
  for(f in LISTA_PLOT_2HM)
  {
    file.remove(paste(PLOT_DIR_M,f,sep = "/"))
  }
  #
  # -------------------------------------------------------------------------------------------
  # Preparing plotting files
  #  
  unico<-c(Shalf[!duplicated(Shalf[,c('month')]),]$month)
  #
  # -------------------------------------------------------------------------------------------
  # Preparing plotting parameters (font size, margins, ...)
  # 
  png(file=paste(PLOT_DIR_M,paste(s_GAW_ID,"_",inst_type,"_WS_",questo_anno,"_SEMESTER_2nd_GRAPH_",gsub("-","",Sys.Date()),".png",sep = ""),sep = "/"),
      width = 2480, height = 3508)
  #
  # -------------------------------------------------------------------------------------------
  # Creating the plotting matrix
  #
  # layout(matrix(c(1,2,3,4,5,6,7),ncol=1), widths=c(10,10,10,10,10,10,10), heights=c(2.2,2.2,2.2,2.2,2.2,2.2,0.2), TRUE) 
  # par(ps = 12, cex = 1.8, cex.main = 1.8,cex.sub=1.8, cex.lab=1.8, cex.axis = 1.5, mai=c(0.3,1.8,0.5,0.5))  # make labels and margins smaller (mai= giu, sx,su,dx)
  par(mfrow = c(6,1))
  par(ps = 14, cex = 1.8, cex.main = 2, cex.lab=1, cex.axis = 1, mai=c(0.3,1.8,0.5,0.5))  # make labels and margins smaller (mai= giu, sx,su,dx)
  
  
  for (i in unico[1:length(unico)])
  {
    print(i)
    temp_L02_ThisSemester<-subset(temp_L02, month == i)
    mensile         <-subset(ws_L02_today_Y, month == i)
    mensile$giorno  <-format(mensile$date,"%d")
    mensile$mean    <-mean(mensile$ws)
    mensile$sd      <-sd(mensile$ws)    
    men_MIN         <-subset(mensile, ws == min(mensile$ws))
    men_MAX         <-subset(mensile, ws == max(mensile$ws))
    {
      plot(ylim=c(-2,max(mensile$ws)+5),
           xlim = c(min(temp_L02_ThisSemester$date),max(temp_L02_ThisSemester$date)),
           mensile$date, mensile$ws, type = "h",
           xlab = "",
           ylab =("WS (m/s) - L02"), col="darkseagreen1", panel.first = grid(nx=3,ny=NULL, lty = 1, lwd = 1))
      title(main=paste(i,questo_anno,sep=" "),
            line = -2.2)
      
      title(paste("Statistics: min: (", round(min(mensile$ws),1),") - max: (", round(max(mensile$ws),1),") - mean: (", round(mean(mensile$ws),1),") - sd: (", round(sd(mensile$ws),1),")")
            ,col="black",cex.main = 1.2, line = -3.8, font.main = 1)
      
      lines(mensile$date, mensile$ws, type = "l", lty = 1, col="darkred",lwd = 2)
      
      text(men_MAX$date[1], men_MIN$ws[1]-1, labels = paste("Max (",format(men_MAX$date[1],"%B %d"),")",sep=""),col="magenta",pos=1)
      segments(men_MAX$date[1], men_MAX$ws[1], men_MAX$date[1], -1, lty = 2, col="black",lwd = 1)
      
      points(men_MAX$date[1], men_MAX$ws[1], col= "blue",pch=20)
      text(men_MIN$date[1], men_MIN$ws[1]-1, labels = paste("Min (",format(men_MIN$date[1],"%B %d"),")",sep=""),col="blue",pos=1)
      segments(men_MIN$date[1], men_MIN$ws[1], men_MIN$date[1], -1, lty = 2, col="black",lwd = 1)
    }   
  }
  dev.off() 
}
#
# -------------------------------------------------------------------------------------------
##                                        # END PART 3.1 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.1.1 #
## ______________________________________________________________________________________________________________________##
##                                    Creating statistcs/graphic reports
##                                              WD SEMESTER GRAPHS
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Subsetting data by semester
# First semester
#
Fhalf           <-subset(wd_L02_today_Y,as.numeric(monthNum) < 7)
if (nrow(Fhalf)==0){ } else 
{
  # -------------------------------------------------------------------------------------------
  # Cleaning Destination directory
  # 
  FILE_PLOT_1HM<-list.files(path = PLOT_DIR_M, pattern = paste(s_GAW_ID, inst_type,"WD",questo_anno,"SEMESTER_1st_GRAPH_*",sep = "_"), all.files = FALSE,
                            full.names = F, recursive = FALSE,
                            ignore.case = FALSE, include.dirs = F, no.. = FALSE)
  
  FILE_PLOT_1HM
  LISTA_PLOT_1HM<-as.character(FILE_PLOT_1HM)
  for(f in LISTA_PLOT_1HM)
  {
    file.remove(paste(PLOT_DIR_M,f,sep = "/"))
  }
  #
  # -------------------------------------------------------------------------------------------
  # Preparing plotting files
  #   
  unico<-c(Fhalf[!duplicated(Fhalf[,c('month')]),]$month)
  #
  # -------------------------------------------------------------------------------------------
  # Preparing plotting parameters (font size, margins, ...)
  # 
  png(file=paste(PLOT_DIR_M,paste(s_GAW_ID,"_",inst_type,"_WD_",questo_anno,"_SEMESTER_1st_GRAPH_",gsub("-","",Sys.Date()),".png",sep = ""),sep = "/"),
      width = 2480, height = 3508)
  #
  # -------------------------------------------------------------------------------------------
  # Creating the plotting matrix
  #
  # layout(matrix(c(1,2,3,4,5,6,7),ncol=1), widths=c(10,10,10,10,10,10,10), heights=c(2.2,2.2,2.2,2.2,2.2,2.2,0.2), TRUE) 
  # par(ps = 12, cex = 1.8, cex.main = 1.8,cex.sub=1.8, cex.lab=1.8, cex.axis = 1.5, mai=c(0.3,1.8,0.5,0.5))  # make labels and margins smaller (mai= giu, sx,su,dx)
  par(mfrow = c(6,1))
  par(ps = 14, cex = 1.8, cex.main = 2, cex.lab=1, cex.axis = 1, mai=c(0.3,1.8,0.5,0.5))  # make labels and margins smaller (mai= giu, sx,su,dx)
  
  for (i in unico[1:length(unico)])
  {
    print(i)
    temp_L02_ThisSemester<-subset(temp_L02, month == i)
    mensile         <-subset(wd_L02_today_Y, month == i)
    mensile$giorno  <-format(mensile$date,"%d")
    mensile$mean    <-mean(mensile$wd)
    mensile$sd      <-sd(mensile$wd)    
    men_MIN         <-subset(mensile, wd == min(mensile$wd))
    men_MAX         <-subset(mensile, wd == max(mensile$wd))
    {
      plot(ylim=c(-40,400),
           xlim = c(min(temp_L02_ThisSemester$date),max(temp_L02_ThisSemester$date)),
           mensile$date, mensile$wd, type = "h",
           xlab = "",
           ylab =("WD (deg) - L02"), col="paleturquoise", panel.first = grid(nx=3,ny=NULL, lty = 1, lwd = 1))
      title(main=paste(i,questo_anno,sep=" "),
            line = -2.2)
      
      title(paste("Statistics: min: (", round(min(mensile$wd),1),") - max: (", round(max(mensile$wd),1),") - mean: (", round(mean(mensile$wd),1),") - sd: (", round(sd(mensile$wd),1),")")
            ,col="black",cex.main = 1.2, line = -3.8, font.main = 1)
      
      lines(mensile$date, mensile$wd, type = "l", lty = 1, col="darkred",lwd = 2)
      
      text(men_MAX$date[1], men_MIN$wd[1]-1, labels = paste("Max (",format(men_MAX$date[1],"%B %d"),")",sep=""),col="magenta",pos=1)
      segments(men_MAX$date[1], men_MAX$wd[1], men_MAX$date[1], -1, lty = 2, col="black",lwd = 1)
      
      points(men_MAX$date[1], men_MAX$wd[1], col= "blue",pch=20)
      text(men_MIN$date[1], men_MIN$wd[1]-1, labels = paste("Min (",format(men_MIN$date[1],"%B %d"),")",sep=""),col="blue",pos=1)
      segments(men_MIN$date[1], men_MIN$wd[1], men_MIN$date[1], -1, lty = 2, col="black",lwd = 1)
      
      segments(head(mensile$date), 360, tail(mensile$date), 360, lty = 1, col="midnightblue",lwd = 0.5)
      text(mensile$date[1],368, labels = c("360°"),col="midnightblue",cex = 1.1)
      
      segments(head(mensile$date), 270, tail(mensile$date), 270, lty = 1, col="dodgerblue3",lwd = 0.5)
      text(mensile$date[1],278, labels = c("270°"),col="dodgerblue3",cex = 1.1)
      
      segments(head(mensile$date), 180, tail(mensile$date), 180, lty = 1, col="steelblue4",lwd = 0.5)
      text(mensile$date[1],188, labels = c("180°"),col="steelblue4",cex = 1.1)
      
      segments(head(mensile$date), 90, tail(mensile$date), 90, lty = 1, col="lightskyblue3",lwd = 0.5)
      text(mensile$date[1],98, labels = c("90°"),col="lightskyblue3",cex = 1.1)
    }   
  }
  dev.off() 
}

#
# -------------------------------------------------------------------------------------------
# Subsetting data by semester
# Second semester
#
Shalf<-subset(wd_L02_today_Y,as.numeric(monthNum) > 6)
if (nrow(Shalf)==0){}else 
{
  # -------------------------------------------------------------------------------------------
  # Cleaning Destination directory
  # 
  FILE_PLOT_2HM<-list.files(path = PLOT_DIR_M, pattern = paste(s_GAW_ID, inst_type,"WD",questo_anno,"SEMESTER_2nd_GRAPH_*",sep = "_"), all.files = FALSE,
                            full.names = F, recursive = FALSE,
                            ignore.case = FALSE, include.dirs = F, no.. = FALSE)
  FILE_PLOT_2HM
  LISTA_PLOT_2HM<-as.character(FILE_PLOT_2HM)
  for(f in LISTA_PLOT_2HM)
  {
    file.remove(paste(PLOT_DIR_M,f,sep = "/"))
  }
  #
  # -------------------------------------------------------------------------------------------
  # Preparing plotting files
  #  
  unico<-c(Shalf[!duplicated(Shalf[,c('month')]),]$month)
  #
  # -------------------------------------------------------------------------------------------
  # Preparing plotting parameters (font size, margins, ...)
  # 
  png(file=paste(PLOT_DIR_M,paste(s_GAW_ID,"_",inst_type,"_WD_",questo_anno,"_SEMESTER_2nd_GRAPH_",gsub("-","",Sys.Date()),".png",sep = ""),sep = "/"),
      width = 2480, height = 3508)
  #
  # -------------------------------------------------------------------------------------------
  # Creating the plotting matrix
  #
  # layout(matrix(c(1,2,3,4,5,6,7),ncol=1), widths=c(10,10,10,10,10,10,10), heights=c(2.2,2.2,2.2,2.2,2.2,2.2,0.2), TRUE) 
  # par(ps = 12, cex = 1.8, cex.main = 1.8,cex.sub=1.8, cex.lab=1.8, cex.axis = 1.5, mai=c(0.3,1.8,0.5,0.5))  # make labels and margins smaller (mai= giu, sx,su,dx)
  par(mfrow = c(6,1))
  par(ps = 14, cex = 1.8, cex.main = 2, cex.lab=1, cex.axis = 1, mai=c(0.3,1.8,0.5,0.5))  # make labels and margins smaller (mai= giu, sx,su,dx)
  
  
  for (i in unico[1:length(unico)])
  {
    print(i)
    temp_L02_ThisSemester<-subset(temp_L02, month == i)
    mensile         <-subset(wd_L02_today_Y, month == i)
    mensile$giorno  <-format(mensile$date,"%d")
    mensile$mean    <-mean(mensile$wd)
    mensile$sd      <-sd(mensile$wd)    
    men_MIN         <-subset(mensile, wd == min(mensile$wd))
    men_MAX         <-subset(mensile, wd == max(mensile$wd))
    {
      plot(ylim=c(-40,400),
           xlim = c(min(temp_L02_ThisSemester$date),max(temp_L02_ThisSemester$date)),
           mensile$date, mensile$wd, type = "h",
           xlab = "",
           ylab =("WD (deg) - L02"), col="paleturquoise", panel.first = grid(nx=3,ny=NULL, lty = 1, lwd = 1))
      title(main=paste(i,questo_anno,sep=" "),
            line = -2.2)
      
      title(paste("Statistics: min: (", round(min(mensile$wd),1),") - max: (", round(max(mensile$wd),1),") - mean: (", round(mean(mensile$wd),1),") - sd: (", round(sd(mensile$wd),1),")")
            ,col="black",cex.main = 1.2, line = -3.8, font.main = 1)
      
      lines(mensile$date, mensile$wd, type = "l", lty = 1, col="darkred",lwd = 2)
      
      text(men_MAX$date[1], men_MIN$wd[1]-1, labels = paste("Max (",format(men_MAX$date[1],"%B %d"),")",sep=""),col="magenta",pos=1)
      segments(men_MAX$date[1], men_MAX$wd[1], men_MAX$date[1], -1, lty = 2, col="black",lwd = 1)
      
      points(men_MAX$date[1], men_MAX$wd[1], col= "blue",pch=20)
      text(men_MIN$date[1], men_MIN$wd[1]-1, labels = paste("Min (",format(men_MIN$date[1],"%B %d"),")",sep=""),col="blue",pos=1)
      segments(men_MIN$date[1], men_MIN$wd[1], men_MIN$date[1], -1, lty = 2, col="black",lwd = 1)
      
      segments(head(mensile$date), 360, tail(mensile$date), 360, lty = 1, col="midnightblue",lwd = 0.5)
      text(mensile$date[1],368, labels = c("360°"),col="midnightblue",cex = 1.1)
      
      segments(head(mensile$date), 270, tail(mensile$date), 270, lty = 1, col="dodgerblue3",lwd = 0.5)
      text(mensile$date[1],278, labels = c("270°"),col="dodgerblue3",cex = 1.1)
      
      segments(head(mensile$date), 180, tail(mensile$date), 180, lty = 1, col="steelblue4",lwd = 0.5)
      text(mensile$date[1],188, labels = c("180°"),col="steelblue4",cex = 1.1)
      
      segments(head(mensile$date), 90, tail(mensile$date), 90, lty = 1, col="lightskyblue3",lwd = 0.5)
      text(mensile$date[1],98, labels = c("90°"),col="lightskyblue3",cex = 1.1)
    }   
  }
  dev.off() 
}
#
# -------------------------------------------------------------------------------------------
##                                        # END PART 3.1.1 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.1.2 #
## ______________________________________________________________________________________________________________________##
##                                    Creating statistcs/graphic reports
##                                              T SEMESTER GRAPHS
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Subsetting data by semester
# First semester
#
Fhalf           <-subset(t_L02_today_Y,as.numeric(monthNum) < 7)
if (nrow(Fhalf)==0){ } else 
{
  # -------------------------------------------------------------------------------------------
  # Cleaning Destination directory
  # 
  FILE_PLOT_1HM<-list.files(path = PLOT_DIR_M, pattern = paste(s_GAW_ID, inst_type,"T",questo_anno,"SEMESTER_1st_GRAPH_*",sep = "_"), all.files = FALSE,
                            full.names = F, recursive = FALSE,
                            ignore.case = FALSE, include.dirs = F, no.. = FALSE)
  
  FILE_PLOT_1HM
  LISTA_PLOT_1HM<-as.character(FILE_PLOT_1HM)
  for(f in LISTA_PLOT_1HM)
  {
    file.remove(paste(PLOT_DIR_M,f,sep = "/"))
  }
  #
  # -------------------------------------------------------------------------------------------
  # Preparing plotting files
  #   
  unico<-c(Fhalf[!duplicated(Fhalf[,c('month')]),]$month)
  #
  # -------------------------------------------------------------------------------------------
  # Preparing plotting parameters (font size, margins, ...)
  # 
  png(file=paste(PLOT_DIR_M,paste(s_GAW_ID,"_",inst_type,"_T_",questo_anno,"_SEMESTER_1st_GRAPH_",gsub("-","",Sys.Date()),".png",sep = ""),sep = "/"),
      width = 2480, height = 3508)
  #
  # -------------------------------------------------------------------------------------------
  # Creating the plotting matrix
  #
  par(mfrow = c(6,1))
  par(ps = 14, cex = 1.8, cex.main = 2, cex.lab=1, cex.axis = 1, mai=c(0.3,1.8,0.5,0.5))  # make labels and margins smaller (mai= giu, sx,su,dx)
  
  for (i in unico[1:length(unico)])
  {
    print(i)
    temp_L02_ThisSemester<-subset(temp_L02, month == i)
    mensile         <-subset(t_L02_today_Y, month == i)
    mensile$giorno  <-format(mensile$date,"%d")
    mensile$mean    <-mean(mensile$t)
    mensile$sd      <-sd(mensile$t)    
    men_MIN         <-subset(mensile, t == min(mensile$t))
    men_MAX         <-subset(mensile, t == max(mensile$t))
    {
      plot(ylim=c(min(mensile$t)-2,max(mensile$t)+3),
           xlim = c(min(temp_L02_ThisSemester$date),max(temp_L02_ThisSemester$date)),
           mensile$date, mensile$t, type = "h",
           xlab = "",
           ylab =("T (°C) - L02"), col="darksalmon", panel.first = grid(nx=3,ny=NULL, lty = 1, lwd = 1))
      title(main=paste(i,questo_anno,sep=" "),
            line = -2.2)
      
      title(paste("Statistics: min: (", round(min(mensile$t),1),") - max: (", round(max(mensile$t),1),") - mean: (", round(mean(mensile$t),1),") - sd: (", round(sd(mensile$t),1),")")
            ,col="black",cex.main = 1.2, line = -3.8, font.main = 1)
      
      lines(mensile$date, mensile$t, type = "l", lty = 1, col="darkred",lwd = 2)
      
      text(men_MAX$date[1], men_MIN$t[1]-1, labels = paste("Max (",format(men_MAX$date[1],"%B %d"),")",sep=""),col="magenta",pos=1)
      segments(men_MAX$date[1], men_MAX$t[1], men_MAX$date[1], -1, lty = 2, col="black",lwd = 1)
      
      points(men_MAX$date[1], men_MAX$t[1], col= "blue",pch=20)
      text(men_MIN$date[1], men_MIN$t[1]-1, labels = paste("Min (",format(men_MIN$date[1],"%B %d"),")",sep=""),col="blue",pos=1)
      segments(men_MIN$date[1], men_MIN$t[1], men_MIN$date[1], -1, lty = 2, col="black",lwd = 1)
      
      segments(head(mensile$date), 0, tail(mensile$date), 0, lty = 1, col="midnightblue",lwd = 1)
      text(mensile$date[1],0.5, labels = c("0°"),col="midnightblue",cex = 1.8)
    }   
  }
  dev.off() 
}
#
# -------------------------------------------------------------------------------------------
# Subsetting data by semester
# Second semester
#
Shalf<-subset(t_L02_today_Y,as.numeric(monthNum) > 6)
if (nrow(Shalf)==0){}else 
{
  # -------------------------------------------------------------------------------------------
  # Cleaning Destination directory
  # 
  FILE_PLOT_2HM<-list.files(path = PLOT_DIR_M, pattern = paste(s_GAW_ID, inst_type,"T",questo_anno,"SEMESTER_2nd_GRAPH_*",sep = "_"), all.files = FALSE,
                            full.names = F, recursive = FALSE,
                            ignore.case = FALSE, include.dirs = F, no.. = FALSE)
  FILE_PLOT_2HM
  LISTA_PLOT_2HM<-as.character(FILE_PLOT_2HM)
  for(f in LISTA_PLOT_2HM)
  {
    file.remove(paste(PLOT_DIR_M,f,sep = "/"))
  }
  #
  # -------------------------------------------------------------------------------------------
  # Preparing plotting files
  #  
  unico<-c(Shalf[!duplicated(Shalf[,c('month')]),]$month)
  #
  # -------------------------------------------------------------------------------------------
  # Preparing plotting parameters (font size, margins, ...)
  # 
  png(file=paste(PLOT_DIR_M,paste(s_GAW_ID,"_",inst_type,"_T_",questo_anno,"_SEMESTER_2nd_GRAPH_",gsub("-","",Sys.Date()),".png",sep = ""),sep = "/"),
      width = 2480, height = 3508)
  #
  # -------------------------------------------------------------------------------------------
  # Creating the plotting matrix
  #
  par(mfrow = c(6,1))
  par(ps = 14, cex = 1.8, cex.main = 2, cex.lab=1, cex.axis = 1, mai=c(0.3,1.8,0.5,0.5))  # make labels and margins smaller (mai= giu, sx,su,dx)
  
  
  for (i in unico[1:length(unico)])
  {
    print(i)
    temp_L02_ThisSemester<-subset(temp_L02, month == i)
    mensile         <-subset(t_L02_today_Y, month == i)
    mensile$giorno  <-format(mensile$date,"%d")
    mensile$mean    <-mean(mensile$t)
    mensile$sd      <-sd(mensile$t)    
    men_MIN         <-subset(mensile, t == min(mensile$t))
    men_MAX         <-subset(mensile, t == max(mensile$t))
    {
      plot(ylim=c(min(mensile$t)-2,max(mensile$t)+3),
           xlim = c(min(temp_L02_ThisSemester$date),max(temp_L02_ThisSemester$date)),
           mensile$date, mensile$t, type = "h",
           xlab = "",
           ylab =("T (°C) - L02"), col="darksalmon", panel.first = grid(nx=3,ny=NULL, lty = 1, lwd = 1))
      title(main=paste(i,questo_anno,sep=" "),
            line = -2.2)
      
      title(paste("Statistics: min: (", round(min(mensile$t),1),") - max: (", round(max(mensile$t),1),") - mean: (", round(mean(mensile$t),1),") - sd: (", round(sd(mensile$t),1),")")
            ,col="black",cex.main = 1.2, line = -3.8, font.main = 1)
      
      lines(mensile$date, mensile$t, type = "l", lty = 1, col="darkred",lwd = 2)
      
      text(men_MAX$date[1], men_MIN$t[1]-1, labels = paste("Max (",format(men_MAX$date[1],"%B %d"),")",sep=""),col="magenta",pos=1)
      segments(men_MAX$date[1], men_MAX$t[1], men_MAX$date[1], -1, lty = 2, col="black",lwd = 1)
      
      points(men_MAX$date[1], men_MAX$t[1], col= "blue",pch=20)
      text(men_MIN$date[1], men_MIN$t[1]-1, labels = paste("Min (",format(men_MIN$date[1],"%B %d"),")",sep=""),col="blue",pos=1)
      segments(men_MIN$date[1], men_MIN$t[1], men_MIN$date[1], -1, lty = 2, col="black",lwd = 1)
      
      segments(head(mensile$date), 0, tail(mensile$date), 0, lty = 1, col="midnightblue",lwd = 1)
      text(mensile$date[1],0.5, labels = c("0°"),col="midnightblue",cex = 1.8)
    }   
  }
  dev.off() 
}
#
# -------------------------------------------------------------------------------------------
##                                        # END PART 3.1.2 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.1.3 #
## ______________________________________________________________________________________________________________________##
##                                    Creating statistcs/graphic reports
##                                              RH SEMESTER GRAPHS
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Subsetting data by semester
# First semester
#
Fhalf           <-subset(rh_L02_today_Y,as.numeric(monthNum) < 7)

print(head(Fhalf$monthNum, 19))

if (nrow(Fhalf)==0){ } else 
{
  # -------------------------------------------------------------------------------------------
  # Cleaning Destination directory
  # 
  FILE_PLOT_1HM<-list.files(path = PLOT_DIR_M, pattern = paste(s_GAW_ID, inst_type,"RH",questo_anno,"SEMESTER_1st_GRAPH_*",sep = "_"), all.files = FALSE,
                            full.names = F, recursive = FALSE,
                            ignore.case = FALSE, include.dirs = F, no.. = FALSE)
  
  FILE_PLOT_1HM
  LISTA_PLOT_1HM<-as.character(FILE_PLOT_1HM)
  for(f in LISTA_PLOT_1HM)
  {
    file.remove(paste(PLOT_DIR_M,f,sep = "/"))
  }
  #
  # -------------------------------------------------------------------------------------------
  # Preparing plotting files
  #   
  unico<-c(Fhalf[!duplicated(Fhalf[,c('month')]),]$month)
  #
  # -------------------------------------------------------------------------------------------
  # Preparing plotting parameters (font size, margins, ...)
  # 
  png(file=paste(PLOT_DIR_M,paste(s_GAW_ID,"_",inst_type,"_RH_",questo_anno,"_SEMESTER_1st_GRAPH_",gsub("-","",Sys.Date()),".png",sep = ""),sep = "/"),
      width = 2480, height = 3508)
  #
  # -------------------------------------------------------------------------------------------
  # Creating the plotting matrix
  #
  par(mfrow = c(6,1))
  par(ps = 14, cex = 1.8, cex.main = 2, cex.lab=1, cex.axis = 1, mai=c(0.3,1.8,0.5,0.5))  # make labels and margins smaller (mai= giu, sx,su,dx)
  
  for (i in unico[1:length(unico)])
  {
    print(i)
    temp_L02_ThisSemester<-subset(temp_L02, month == i)
    mensile         <-subset(rh_L02_today_Y, month == i)
    mensile$giorno  <-format(mensile$date,"%d")
    mensile$mean    <-mean(mensile$rh)
    mensile$sd      <-sd(mensile$rh)    
    men_MIN         <-subset(mensile, rh == min(mensile$rh))
    men_MAX         <-subset(mensile, rh == max(mensile$rh))
    {
      plot(ylim=c(-10,140),
           xlim = c(min(temp_L02_ThisSemester$date),max(temp_L02_ThisSemester$date)),
           mensile$date, mensile$rh, type = "h",
           xlab = "",
           ylab =("RH (%) - L02"), col="slategray2", panel.first = grid(nx=3,ny=NULL, lty = 1, lwd = 1))
      title(main=paste(i,questo_anno,sep=" "),
            line = -2.2)
      
      title(paste("Statistics: min: (", round(min(mensile$rh),1),") - max: (", round(max(mensile$rh),1),") - mean: (", round(mean(mensile$rh),1),") - sd: (", round(sd(mensile$rh),1),")")
            ,col="black",cex.main = 1.2, line = -3.8, font.main = 1)
      
      lines(mensile$date, mensile$rh, type = "l", lty = 1, col="darkred",lwd = 2)
      
      text(men_MAX$date[1], 0, labels = paste("Max (",format(men_MAX$date[1],"%B %d"),")",sep=""),col="magenta",pos=1)
      segments(men_MAX$date[1], men_MAX$rh[1], men_MAX$date[1], -1, lty = 2, col="black",lwd = 1)
      
      points(men_MAX$date[1], men_MAX$rh[1], col= "blue",pch=20)
      text(men_MIN$date[1], 0, labels = paste("Min (",format(men_MIN$date[1],"%B %d"),")",sep=""),col="blue",pos=1)
      segments(men_MIN$date[1], men_MIN$rh[1], men_MIN$date[1], -1, lty = 2, col="black",lwd = 1)
    }   
  }
  dev.off() 
}
#
# -------------------------------------------------------------------------------------------
# Subsetting data by semester
# Second semester
#
Shalf<-subset(rh_L02_today_Y,as.numeric(monthNum) > 6)
if (nrow(Shalf)==0){}else 
{
  # -------------------------------------------------------------------------------------------
  # Cleaning Destination directory
  # 
  FILE_PLOT_2HM<-list.files(path = PLOT_DIR_M, pattern = paste(s_GAW_ID, inst_type,"RH",questo_anno,"SEMESTER_2nd_GRAPH_*",sep = "_"), all.files = FALSE,
                            full.names = F, recursive = FALSE,
                            ignore.case = FALSE, include.dirs = F, no.. = FALSE)
  FILE_PLOT_2HM
  LISTA_PLOT_2HM<-as.character(FILE_PLOT_2HM)
  for(f in LISTA_PLOT_2HM)
  {
    file.remove(paste(PLOT_DIR_M,f,sep = "/"))
  }
  #
  # -------------------------------------------------------------------------------------------
  # Preparing plotting files
  #  
  unico<-c(Shalf[!duplicated(Shalf[,c('month')]),]$month)
  #
  # -------------------------------------------------------------------------------------------
  # Preparing plotting parameters (font size, margins, ...)
  # 
  png(file=paste(PLOT_DIR_M,paste(s_GAW_ID,"_",inst_type,"_RH_",questo_anno,"_SEMESTER_2nd_GRAPH_",gsub("-","",Sys.Date()),".png",sep = ""),sep = "/"),
      width = 2480, height = 3508)
  #
  # -------------------------------------------------------------------------------------------
  # Creating the plotting matrix
  #
  par(mfrow = c(6,1))
  par(ps = 14, cex = 1.8, cex.main = 2, cex.lab=1, cex.axis = 1, mai=c(0.3,1.8,0.5,0.5))  # make labels and margins smaller (mai= giu, sx,su,dx)
  
  
  for (i in unico[1:length(unico)])
  {
    print(i)
    temp_L02_ThisSemester<-subset(temp_L02, month == i)
    mensile         <-subset(rh_L02_today_Y, month == i)
    mensile$giorno  <-format(mensile$date,"%d")
    mensile$mean    <-mean(mensile$rh)
    mensile$sd      <-sd(mensile$rh)    
    men_MIN         <-subset(mensile, rh == min(mensile$rh))
    men_MAX         <-subset(mensile, rh == max(mensile$rh))
    {
      plot(ylim=c(-10,140),
           xlim = c(min(temp_L02_ThisSemester$date),max(temp_L02_ThisSemester$date)),
           mensile$date, mensile$rh, type = "h",
           xlab = "",
           ylab =("RH (%) - L02"), col="slategray2", panel.first = grid(nx=3,ny=NULL, lty = 1, lwd = 1))
      title(main=paste(i,questo_anno,sep=" "),
            line = -2.2)
      
      title(paste("Statistics: min: (", round(min(mensile$rh),1),") - max: (", round(max(mensile$rh),1),") - mean: (", round(mean(mensile$rh),1),") - sd: (", round(sd(mensile$rh),1),")")
            ,col="black",cex.main = 1.2, line = -3.8, font.main = 1)
      
      lines(mensile$date, mensile$rh, type = "l", lty = 1, col="darkred",lwd = 2)
      
      text(men_MAX$date[1], 0, labels = paste("Max (",format(men_MAX$date[1],"%B %d"),")",sep=""),col="magenta",pos=1)
      segments(men_MAX$date[1], men_MAX$rh[1], men_MAX$date[1], -1, lty = 2, col="black",lwd = 1)
      
      points(men_MAX$date[1], men_MAX$rh[1], col= "blue",pch=20)
      text(men_MIN$date[1], 0, labels = paste("Min (",format(men_MIN$date[1],"%B %d"),")",sep=""),col="blue",pos=1)
      segments(men_MIN$date[1], men_MIN$rh[1], men_MIN$date[1], -1, lty = 2, col="black",lwd = 1)
    }   
  }
  dev.off() 
}
#
# -------------------------------------------------------------------------------------------
##                                        # END PART 3.1.3 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.1.4 #
## ______________________________________________________________________________________________________________________##
##                                    Creating statistcs/graphic reports
##                                              P SEMESTER GRAPHS
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Subsetting data by semester
# First semester
#
Fhalf           <-subset(p_L02_today_Y,as.numeric(monthNum) < 7)

print(head(Fhalf$monthNum, 19))

if (nrow(Fhalf)==0){ } else 
{
  # -------------------------------------------------------------------------------------------
  # Cleaning Destination directory
  # 
  FILE_PLOT_1HM<-list.files(path = PLOT_DIR_M, pattern = paste(s_GAW_ID, inst_type,"P",questo_anno,"SEMESTER_1st_GRAPH_*",sep = "_"), all.files = FALSE,
                            full.names = F, recursive = FALSE,
                            ignore.case = FALSE, include.dirs = F, no.. = FALSE)
  
  FILE_PLOT_1HM
  LISTA_PLOT_1HM<-as.character(FILE_PLOT_1HM)
  for(f in LISTA_PLOT_1HM)
  {
    file.remove(paste(PLOT_DIR_M,f,sep = "/"))
  }
  #
  # -------------------------------------------------------------------------------------------
  # Preparing plotting files
  #   
  unico<-c(Fhalf[!duplicated(Fhalf[,c('month')]),]$month)
  #
  # -------------------------------------------------------------------------------------------
  # Preparing plotting parameters (font size, margins, ...)
  # 
  png(file=paste(PLOT_DIR_M,paste(s_GAW_ID,"_",inst_type,"_P_",questo_anno,"_SEMESTER_1st_GRAPH_",gsub("-","",Sys.Date()),".png",sep = ""),sep = "/"),
      width = 2480, height = 3508)
  #
  # -------------------------------------------------------------------------------------------
  # Creating the plotting matrix
  #
  par(mfrow = c(6,1))
  par(ps = 14, cex = 1.8, cex.main = 2, cex.lab=1, cex.axis = 1, mai=c(0.3,1.8,0.5,0.5))  # make labels and margins smaller (mai= giu, sx,su,dx)
  
  for (i in unico[1:length(unico)])
  {
    print(i)
    temp_L02_ThisSemester<-subset(temp_L02, month == i)
    mensile         <-subset(p_L02_today_Y, month == i)
    mensile$giorno  <-format(mensile$date,"%d")
    mensile$mean    <-mean(mensile$p)
    mensile$sd      <-sd(mensile$p)    
    men_MIN         <-subset(mensile, p == min(mensile$p))
    men_MAX         <-subset(mensile, p == max(mensile$p))
    {
      plot(ylim=c(750,max(mensile$p)+20),
           xlim = c(min(temp_L02_ThisSemester$date),max(temp_L02_ThisSemester$date)),
           mensile$date, mensile$p, type = "h",
           xlab = "",
           ylab =("P (hPa) - L02"), col="thistle3", panel.first = grid(nx=3,ny=NULL, lty = 1, lwd = 1))
      title(main=paste(i,questo_anno,sep=" "),
            line = -2.2)
      
      title(paste("Statistics: min: (", round(min(mensile$p),1),") - max: (", round(max(mensile$p),1),") - mean: (", round(mean(mensile$p),1),") - sd: (", round(sd(mensile$p),1),")")
            ,col="black",cex.main = 1.2, line = -3.8, font.main = 1)
      
      lines(mensile$date, mensile$p, type = "l", lty = 1, col="darkred",lwd = 2)
      
      text(men_MAX$date[1], 755, labels = paste("Max (",format(men_MAX$date[1],"%B %d"),")",sep=""),col="magenta",pos=1)
      segments(men_MAX$date[1], men_MAX$p[1], men_MAX$date[1], -1, lty = 2, col="black",lwd = 1)
      
      points(men_MAX$date[1], men_MAX$p[1], col= "blue",pch=20)
      text(men_MIN$date[1], 755, labels = paste("Min (",format(men_MIN$date[1],"%B %d"),")",sep=""),col="blue",pos=1)
      segments(men_MIN$date[1], men_MIN$p[1], men_MIN$date[1], -1, lty = 2, col="black",lwd = 1)
    }   
  }
  dev.off() 
}
#
# -------------------------------------------------------------------------------------------
# Subsetting data by semester
# Second semester
#
Shalf<-subset(p_L02_today_Y,as.numeric(monthNum) > 6)
if (nrow(Shalf)==0){}else 
{
  # -------------------------------------------------------------------------------------------
  # Cleaning Destination directory
  # 
  FILE_PLOT_2HM<-list.files(path = PLOT_DIR_M, pattern = paste(s_GAW_ID, inst_type,"P",questo_anno,"SEMESTER_2nd_GRAPH_*",sep = "_"), all.files = FALSE,
                            full.names = F, recursive = FALSE,
                            ignore.case = FALSE, include.dirs = F, no.. = FALSE)
  FILE_PLOT_2HM
  LISTA_PLOT_2HM<-as.character(FILE_PLOT_2HM)
  for(f in LISTA_PLOT_2HM)
  {
    file.remove(paste(PLOT_DIR_M,f,sep = "/"))
  }
  #
  # -------------------------------------------------------------------------------------------
  # Preparing plotting files
  #  
  unico<-c(Shalf[!duplicated(Shalf[,c('month')]),]$month)
  #
  # -------------------------------------------------------------------------------------------
  # Preparing plotting parameters (font size, margins, ...)
  # 
  png(file=paste(PLOT_DIR_M,paste(s_GAW_ID,"_",inst_type,"_P_",questo_anno,"_SEMESTER_2nd_GRAPH_",gsub("-","",Sys.Date()),".png",sep = ""),sep = "/"),
      width = 2480, height = 3508)
  #
  # -------------------------------------------------------------------------------------------
  # Creating the plotting matrix
  #
  par(mfrow = c(6,1))
  par(ps = 14, cex = 1.8, cex.main = 2, cex.lab=1, cex.axis = 1, mai=c(0.3,1.8,0.5,0.5))  # make labels and margins smaller (mai= giu, sx,su,dx)
  
  
  for (i in unico[1:length(unico)])
  {
    print(i)
    temp_L02_ThisSemester<-subset(temp_L02, month == i)
    mensile         <-subset(p_L02_today_Y, month == i)
    mensile$giorno  <-format(mensile$date,"%d")
    mensile$mean    <-mean(mensile$p)
    mensile$sd      <-sd(mensile$p)    
    men_MIN         <-subset(mensile, p == min(mensile$p))
    men_MAX         <-subset(mensile, p == max(mensile$p))
    {
      plot(ylim=c(750,max(mensile$p)+20),
           xlim = c(min(temp_L02_ThisSemester$date),max(temp_L02_ThisSemester$date)),
           mensile$date, mensile$p, type = "h",
           xlab = "",
           ylab =("P (hPa) - L02"), col="thistle3", panel.first = grid(nx=3,ny=NULL, lty = 1, lwd = 1))
      title(main=paste(i,questo_anno,sep=" "),
            line = -2.2)
      
      title(paste("Statistics: min: (", round(min(mensile$p),1),") - max: (", round(max(mensile$p),1),") - mean: (", round(mean(mensile$p),1),") - sd: (", round(sd(mensile$p),1),")")
            ,col="black",cex.main = 1.2, line = -3.8, font.main = 1)
      
      lines(mensile$date, mensile$p, type = "l", lty = 1, col="darkred",lwd = 2)
      
      text(men_MAX$date[1], 755, labels = paste("Max (",format(men_MAX$date[1],"%B %d"),")",sep=""),col="magenta",pos=1)
      segments(men_MAX$date[1], men_MAX$p[1], men_MAX$date[1], -1, lty = 2, col="black",lwd = 1)
      
      points(men_MAX$date[1], men_MAX$p[1], col= "blue",pch=20)
      text(men_MIN$date[1], 755, labels = paste("Min (",format(men_MIN$date[1],"%B %d"),")",sep=""),col="blue",pos=1)
      segments(men_MIN$date[1], men_MIN$p[1], men_MIN$date[1], -1, lty = 2, col="black",lwd = 1)
    }   
  }
  dev.off() 
}
#
# -------------------------------------------------------------------------------------------
##                                        # END PART 3.1.4 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.1.5 #
## ______________________________________________________________________________________________________________________##
##                                    Creating statistcs/graphic reports
##                                              RAD SEMESTER GRAPHS
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Subsetting data by semester
# First semester
#
Fhalf           <-subset(rad_L02_today_Y,as.numeric(monthNum) < 7)

print(head(Fhalf$monthNum, 19))

if (nrow(Fhalf)==0){ } else 
{
  # -------------------------------------------------------------------------------------------
  # Cleaning Destination directory
  # 
  FILE_PLOT_1HM<-list.files(path = PLOT_DIR_M, pattern = paste(s_GAW_ID, inst_type,"RAD",questo_anno,"SEMESTER_1st_GRAPH_*",sep = "_"), all.files = FALSE,
                            full.names = F, recursive = FALSE,
                            ignore.case = FALSE, include.dirs = F, no.. = FALSE)
  
  FILE_PLOT_1HM
  LISTA_PLOT_1HM<-as.character(FILE_PLOT_1HM)
  for(f in LISTA_PLOT_1HM)
  {
    file.remove(paste(PLOT_DIR_M,f,sep = "/"))
  }
  #
  # -------------------------------------------------------------------------------------------
  # Preparing plotting files
  #   
  unico<-c(Fhalf[!duplicated(Fhalf[,c('month')]),]$month)
  #
  # -------------------------------------------------------------------------------------------
  # Preparing plotting parameters (font size, margins, ...)
  # 
  png(file=paste(PLOT_DIR_M,paste(s_GAW_ID,"_",inst_type,"_RAD_",questo_anno,"_SEMESTER_1st_GRAPH_",gsub("-","",Sys.Date()),".png",sep = ""),sep = "/"),
      width = 2480, height = 3508)
  #
  # -------------------------------------------------------------------------------------------
  # Creating the plotting matrix
  #
  par(mfrow = c(6,1))
  par(ps = 14, cex = 1.8, cex.main = 2, cex.lab=1, cex.axis = 1, mai=c(0.3,1.8,0.5,0.5))  # make labels and margins smaller (mai= giu, sx,su,dx)
  
  for (i in unico[1:length(unico)])
  {
    print(i)
    temp_L02_ThisSemester<-subset(temp_L02, month == i)
    mensile         <-subset(rad_L02_today_Y, month == i)
    mensile$giorno  <-format(mensile$date,"%d")
    mensile$mean    <-mean(mensile$rad)
    mensile$sd      <-sd(mensile$rad)    
    men_MIN         <-subset(mensile, rad == min(mensile$rad))
    men_MAX         <-subset(mensile, rad == max(mensile$rad))
    {
      plot(ylim=c(-100,men_MAX$rad[1]+20),
           xlim = c(min(temp_L02_ThisSemester$date),max(temp_L02_ThisSemester$date)),
           mensile$date, mensile$rad, type = "h",
           xlab = "",
           ylab =expression(paste("RAD (W/m"^{2},") - L02")), col="goldenrod", panel.first = grid(nx=3,ny=NULL, lty = 1, lwd = 1))
      title(main=paste(i,questo_anno,sep=" "),
            line = -2.2)
      
      title(paste("Statistics: min: (", round(min(mensile$rad),1),") - max: (", round(max(mensile$rad),1),") - mean: (", round(mean(mensile$rad),1),") - sd: (", round(sd(mensile$rad),1),")")
            ,col="black",cex.main = 1.2, line = -3.8, font.main = 1)
      
      lines(mensile$date, mensile$rad, type = "l", lty = 1, col="darkred",lwd = 2)
      
      text(men_MAX$date[1], 0, labels = paste("Max (",format(men_MAX$date[1],"%B %d"),")",sep=""),col="magenta",pos=1)
      segments(men_MAX$date[1], men_MAX$rad[1], men_MAX$date[1], -1, lty = 2, col="black",lwd = 1)
      
      points(men_MAX$date[1], men_MAX$rad[1], col= "blue",pch=20)
      text(men_MIN$date[1], 0, labels = paste("Min (",format(men_MIN$date[1],"%B %d"),")",sep=""),col="blue",pos=1)
      segments(men_MIN$date[1], men_MIN$rad[1], men_MIN$date[1], -1, lty = 2, col="black",lwd = 1)
    }   
  }
  dev.off() 
}
#
# -------------------------------------------------------------------------------------------
# Subsetting data by semester
# Second semester
#
Shalf<-subset(rad_L02_today_Y,as.numeric(monthNum) > 6)
if (nrow(Shalf)==0){}else 
{
  # -------------------------------------------------------------------------------------------
  # Cleaning Destination directory
  # 
  FILE_PLOT_2HM<-list.files(path = PLOT_DIR_M, pattern = paste(s_GAW_ID, inst_type,"RAD",questo_anno,"SEMESTER_2nd_GRAPH_*",sep = "_"), all.files = FALSE,
                            full.names = F, recursive = FALSE,
                            ignore.case = FALSE, include.dirs = F, no.. = FALSE)
  FILE_PLOT_2HM
  LISTA_PLOT_2HM<-as.character(FILE_PLOT_2HM)
  for(f in LISTA_PLOT_2HM)
  {
    file.remove(paste(PLOT_DIR_M,f,sep = "/"))
  }
  #
  # -------------------------------------------------------------------------------------------
  # Preparing plotting files
  #  
  unico<-c(Shalf[!duplicated(Shalf[,c('month')]),]$month)
  #
  # -------------------------------------------------------------------------------------------
  # Preparing plotting parameters (font size, margins, ...)
  # 
  png(file=paste(PLOT_DIR_M,paste(s_GAW_ID,"_",inst_type,"_RAD_",questo_anno,"_SEMESTER_2nd_GRAPH_",gsub("-","",Sys.Date()),".png",sep = ""),sep = "/"),
      width = 2480, height = 3508)
  #
  # -------------------------------------------------------------------------------------------
  # Creating the plotting matrix
  #
  par(mfrow = c(6,1))
  par(ps = 14, cex = 1.8, cex.main = 2, cex.lab=1, cex.axis = 1, mai=c(0.3,1.8,0.5,0.5))  # make labels and margins smaller (mai= giu, sx,su,dx)
  
  
  for (i in unico[1:length(unico)])
  {
    print(i)
    temp_L02_ThisSemester<-subset(temp_L02, month == i)
    mensile         <-subset(rad_L02_today_Y, month == i)
    mensile$giorno  <-format(mensile$date,"%d")
    mensile$mean    <-mean(mensile$rad)
    mensile$sd      <-sd(mensile$rad)    
    men_MIN         <-subset(mensile, rad == min(mensile$rad))
    men_MAX         <-subset(mensile, rad == max(mensile$rad))
    {
      plot(ylim=c(-100,men_MAX$rad[1]+20),
           xlim = c(min(temp_L02_ThisSemester$date),max(temp_L02_ThisSemester$date)),
           mensile$date, mensile$rad, type = "h",
           xlab = "",
           ylab =expression(paste("RAD (W/m"^{2},") - L02")), col="goldenrod", panel.first = grid(nx=3,ny=NULL, lty = 1, lwd = 1))
      title(main=paste(i,questo_anno,sep=" "),
            line = -2.2)
      
      title(paste("Statistics: min: (", round(min(mensile$rad),1),") - max: (", round(max(mensile$rad),1),") - mean: (", round(mean(mensile$rad),1),") - sd: (", round(sd(mensile$rad),1),")")
            ,col="black",cex.main = 1.2, line = -3.8, font.main = 1)
      
      lines(mensile$date, mensile$rad, type = "l", lty = 1, col="darkred",lwd = 2)
      
      text(men_MAX$date[1], 0, labels = paste("Max (",format(men_MAX$date[1],"%B %d"),")",sep=""),col="magenta",pos=1)
      segments(men_MAX$date[1], men_MAX$rad[1], men_MAX$date[1], -1, lty = 2, col="black",lwd = 1)
      
      points(men_MAX$date[1], men_MAX$rad[1], col= "blue",pch=20)
      text(men_MIN$date[1], 0, labels = paste("Min (",format(men_MIN$date[1],"%B %d"),")",sep=""),col="blue",pos=1)
      segments(men_MIN$date[1], men_MIN$rad[1], men_MIN$date[1], -1, lty = 2, col="black",lwd = 1)
    }   
  }
  dev.off() 
}
#
# -------------------------------------------------------------------------------------------
##                                        # END PART 3.1.5 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.2 #
## ______________________________________________________________________________________________________________________##
##                                    Creating statistcs/graphic reports
##                                             WS SEASONAL GRAPHS
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# -------------------------------------------------------------------------------------------
# Cleaning Destination directory
# 
FILE_PLOT_S         <-list.files(path = PLOT_DIR_S, pattern = paste(s_GAW_ID, inst_type,"WS",questo_anno,"SEASONAL_GRAPH_*",sep = "_"), 
                                 all.files = FALSE,
                                 full.names = F, recursive = FALSE,
                                 ignore.case = FALSE, include.dirs = F, no.. = FALSE)
LISTA_PLOT_S        <-as.character(FILE_PLOT_S)


for(f in LISTA_PLOT_S){
  file.remove(paste(PLOT_DIR_S,f,sep = "/"))
}
#
# -------------------------------------------------------------------------------------------
# Defining seasons (quadrimesters)
#


ws_L02_today_Y$season[as.numeric(ws_L02_today_Y$monthNum)>=1  & as.numeric(ws_L02_today_Y$monthNum)<=3]      <- 1
ws_L02_today_Y$season[as.numeric(ws_L02_today_Y$monthNum)>=4  & as.numeric(ws_L02_today_Y$monthNum)<=6]      <- 2
ws_L02_today_Y$season[as.numeric(ws_L02_today_Y$monthNum)>=7  & as.numeric(ws_L02_today_Y$monthNum)<=9]      <- 3
ws_L02_today_Y$season[as.numeric(ws_L02_today_Y$monthNum)>=10 & as.numeric(ws_L02_today_Y$monthNum)<=12]     <- 4

seasons<-c(ws_L02_today_Y[!duplicated(ws_L02_today_Y[,c('season')]),]$season)
seasons 
# -------------------------------------------------------------------------------------------
# Preparing plotting files
#  
PLOT_S_NAME         <-paste(s_GAW_ID,"_",inst_type,"_WS_",questo_anno,"_SEASONAL_GRAPH_",gsub("-","",Sys.Date()),sep = "")
PLOT_S_NAME_FULL    <-paste (PLOT_DIR_S,paste(PLOT_S_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_S_NAME_FULL, width = 2480, height = 3508)# width=2100,height=2970,res=300)
#
# -------------------------------------------------------------------------------------------
# Preparing plotting parameters (font size, margins, ...)
# 
par(mfrow = c(8,1))

par(ps = 14, cex = 2, cex.main = 4.0,cex.sub=2.2, cex.lab=3.5, cex.axis = 3.2, mai=c(0.6,1.8,0.5,0.5)) 
#
# -------------------------------------------------------------------------------------------
# Creating the plotting matrix
#    
m <- rbind(c(1, 1), c(2, 3), c(4, 4), c(5, 6), c(7, 7), c(8, 9), c(10, 10), c(11, 12))
layout(m)
#
# -------------------------------------------------------------------------------------------
# Creating the plotting matrix
#
for (stg in seasons)
{
  if(stg==1){stg_name<-"JAN - FEB - MAR"}
  if(stg==2){stg_name<-"APR - MAY - JUN"}
  if(stg==3){stg_name<-"JUL - AUG - SEP"}
  if(stg==4){stg_name<-"OCT - NOV - DEC"}
  print(stg)
  print(stg_name)
  
  ws_L02_stg       <-subset(ws_L02_today_Y, season ==stg)
  
  OBS_stg_start     <-head(format(ws_L02_stg$date,"%d %B %Y"),1)
  OBS_stg_end       <-tail(format(ws_L02_stg$date,"%d %B %Y"),1)
  
  stagionale<-subset(ws_L02_stg, flag_ws<0.900)
  stagionale$giorno <- format(stagionale$date,"%d")
  This_stg <- c(format(stagionale$date,"%m"))
  This_stg_Name <- c(format(stagionale$date,"%B"))
  
  
  stagionale$mean<-mean(stagionale$ws)
  stagionale$sd<-sd(stagionale$ws)
  stg_MIN<-subset(stagionale, ws == min(stagionale$ws))
  stg_MAX<-subset(stagionale, ws == max(stagionale$ws))

  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting WS
  #
  plot(ylim=c(-2,max(stagionale$ws)+0.5),
       stagionale$date, stagionale$ws, type = "h",
       mgp = c(7, 3, 0),
       xlab = "",ylab ="WS (m/s) - L02", 
       col="lightblue", 
       panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 0.5))
  lines(stagionale$date, stagionale$ws, type = "l", lty = 1, col="darkred",lwd = 0.5)
  title(main=paste("WS",questo_anno,"   ",stg_name), line = -4.5)
  
  mtext(paste("Observations from", OBS_stg_start," to ", 
              OBS_stg_end,"(",1+(as.integer(tail((ws_L02_stg$date),1)-head((ws_L02_stg$date)),1))," days)       -       Statistics: ","  WS min: (", min(stagionale$ws),") - WS max: (", max(stagionale$ws),") - WS mean: (", round(mean(stagionale$ws),1),") - WS sd: (", round(sd(stagionale$ws),1),")"),
                     col="black",cex = 1.7, line = -8.0, font.main = 1)
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting HISTOGRAMS
  #
  ws_1 <- subset(stagionale, (ws <= 6))
  ws_2 <- subset(stagionale, (ws > 6 & ws <= 12))
  ws_3 <- subset(stagionale, (ws > 12 & ws <= 18))
  ws_4 <- subset(stagionale, (ws > 18 & ws <= 24))
  ws_5 <- subset(stagionale, (ws > 24 & ws <= 30))
  ws_6 <- subset(stagionale, (ws > 30))
  ws_freq = table(stagionale$ws)
  
  print(paste(max(ws_1$ws),"-",min(ws_1$ws)))
  print(paste(max(ws_2$ws),"-",min(ws_2$ws)))
  print(paste(max(ws_3$ws),"-",min(ws_3$ws)))
  print(paste(max(ws_4$ws),"-",min(ws_4$ws)))
  print(paste(max(ws_5$ws),"-",min(ws_5$ws)))
  print(paste(max(ws_6$ws),"-",min(ws_6$ws)))
  
  yhist <- hist(stagionale$ws, breaks=12, plot=FALSE)
  print(yhist)
  yhist_max<-(max(yhist$counts))
  
  h1<-hist(ws_1$ws, breaks= c(seq(-0, 40, by=2)), xlim=c(0,40), ylim=c(0,yhist_max+20), col="azure", xlab="", 
           ylab="Relative frequency", main="Wind speed (m/s)",bty="l" , mgp = c(7, 3, 0))
  h2<-hist(ws_2$ws, breaks= c(seq(-0, 40, by=2)), xlim=c(0,40), ylim=c(0,yhist_max+20), col="lightblue2", add=T)
  h3<-hist(ws_3$ws, breaks= c(seq(-0, 40, by=2)), xlim=c(0,40), ylim=c(0,yhist_max+20), col="lightblue4", add=T)
  h4<-hist(ws_4$ws, breaks= c(seq(-0, 40, by=2)), xlim=c(0,40), ylim=c(0,yhist_max+20), col="pink", add=T) 
  h5<-hist(ws_5$ws, breaks= c(seq(-0, 40, by=2)), xlim=c(0,40), ylim=c(0,yhist_max+20), col="pink2", add=T)
  h6<-hist(ws_6$ws, breaks= c(seq(-0, 40, by=2)), xlim=c(0,40), ylim=c(0,yhist_max+20), col="indianred4", add=T) 
  
  d <- density(stagionale$ws)
  plot(d,xlab="", 
       ylab="Density",
       main="Wind speed (m/s)",
       mgp = c(7, 3, 0),
       polygon(d, col="steelblue", border="blue"))
  } 
dev.off()  

# -------------------------------------------------------------------------------------------
##                                          # END PART 3.2 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.2.1 #
## ______________________________________________________________________________________________________________________##
##                                    Creating statistcs/graphic reports
##                                             WD SEASONAL GRAPHS
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# -------------------------------------------------------------------------------------------
# Cleaning Destination directory
# 
FILE_PLOT_S         <-list.files(path = PLOT_DIR_S, pattern = paste(s_GAW_ID, inst_type,"WD",questo_anno,"SEASONAL_GRAPH_*",sep = "_"), 
                                 all.files = FALSE,
                                 full.names = F, recursive = FALSE,
                                 ignore.case = FALSE, include.dirs = F, no.. = FALSE)
LISTA_PLOT_S        <-as.character(FILE_PLOT_S)


for(f in LISTA_PLOT_S){
  file.remove(paste(PLOT_DIR_S,f,sep = "/"))
}
#
# -------------------------------------------------------------------------------------------
# Defining seasons (quadrimesters)
#


wd_L02_today_Y$season[as.numeric(wd_L02_today_Y$monthNum)>=1  & as.numeric(wd_L02_today_Y$monthNum)<=3]      <- 1
wd_L02_today_Y$season[as.numeric(wd_L02_today_Y$monthNum)>=4  & as.numeric(wd_L02_today_Y$monthNum)<=6]      <- 2
wd_L02_today_Y$season[as.numeric(wd_L02_today_Y$monthNum)>=7  & as.numeric(wd_L02_today_Y$monthNum)<=9]      <- 3
wd_L02_today_Y$season[as.numeric(wd_L02_today_Y$monthNum)>=10 & as.numeric(wd_L02_today_Y$monthNum)<=12]     <- 4

seasons<-c(wd_L02_today_Y[!duplicated(wd_L02_today_Y[,c('season')]),]$season)
seasons 
# -------------------------------------------------------------------------------------------
# Preparing plotting files
#  
PLOT_S_NAME         <-paste(s_GAW_ID,"_",inst_type,"_WD_",questo_anno,"_SEASONAL_GRAPH_",gsub("-","",Sys.Date()),sep = "")
PLOT_S_NAME_FULL    <-paste (PLOT_DIR_S,paste(PLOT_S_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_S_NAME_FULL, width = 2480, height = 3508)# width=2100,height=2970,res=300)
#
# -------------------------------------------------------------------------------------------
# Preparing plotting parameters (font size, margins, ...)
# 
par(mfrow = c(8,1))

par(ps = 14, cex = 2, cex.main = 4.0,cex.sub=2.2, cex.lab=3.5, cex.axis = 3.2, mai=c(0.6,1.8,0.5,0.5)) 
#
# -------------------------------------------------------------------------------------------
# Creating the plotting matrix
#    
m <- rbind(c(1, 1), c(2, 3), c(4, 4), c(5, 6), c(7, 7), c(8, 9), c(10, 10), c(11, 12))
layout(m)
#
# -------------------------------------------------------------------------------------------
# Creating the plotting matrix
#
for (stg in seasons)
{
  if(stg==1){stg_name<-"JAN - FEB - MAR"}
  if(stg==2){stg_name<-"APR - MAY - JUN"}
  if(stg==3){stg_name<-"JUL - AUG - SEP"}
  if(stg==4){stg_name<-"OCT - NOV - DEC"}
  print(stg)
  print(stg_name)
  
  wd_L02_stg       <-subset(wd_L02_today_Y, season ==stg)
  
  OBS_stg_start     <-head(format(wd_L02_stg$date,"%d %B %Y"),1)
  OBS_stg_end       <-tail(format(wd_L02_stg$date,"%d %B %Y"),1)
  
  stagionale<-subset(wd_L02_stg, flag_wd<0.900)
  stagionale$giorno <- format(stagionale$date,"%d")
  This_stg <- c(format(stagionale$date,"%m"))
  This_stg_Name <- c(format(stagionale$date,"%B"))
  
  
  stagionale$mean<-mean(stagionale$wd)
  stagionale$sd<-sd(stagionale$wd)
  stg_MIN<-subset(stagionale, wd == min(stagionale$wd))
  stg_MAX<-subset(stagionale, wd == max(stagionale$wd))
  
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting WD
  #
  plot(ylim=c(-40,480),
       stagionale$date, stagionale$wd, type = "h",
       mgp = c(7, 3, 0),
       xlab = "",ylab ="WD (deg) - L02", 
       col="lightblue", 
       panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 0.5))
  lines(stagionale$date, stagionale$wd, type = "l", lty = 1, col="darkred",lwd = 0.5)
  title(main=paste("WD",questo_anno,"   ",stg_name), line = -4.5)
  
  mtext(paste("Observations from", OBS_stg_start,
              " to ", OBS_stg_end,
              "(",1+(as.integer(tail((wd_L02_stg$date),1)-head((wd_L02_stg$date)),1))
              ,"days)       -       Statistics: ",
              "  WD min: (", round(min(stagionale$wd),1),") - WD max: (", round(max(stagionale$wd),1),") - WD mean: (", round(mean(stagionale$wd),1),") - WD sd: (", round(sd(stagionale$wd),1),")"),
        col="black",cex = 1.7, line = -8.0, font.main = 1)
  
  segments(head(stagionale$date,1), 360, tail(stagionale$date,1), 360, lty = 1, col="midnightblue",lwd = 1)
  text(stagionale$date[1],368, labels = c("360°"),col="midnightblue",cex = 1.2)
  
  segments(head(stagionale$date,1), 270, tail(stagionale$date,1), 270, lty = 1, col="dodgerblue3",lwd = 1)
  text(stagionale$date[1],278, labels = c("270°"),col="dodgerblue3",cex = 1.2)
  
  segments(head(stagionale$date,1), 180, tail(stagionale$date,1), 180, lty = 1, col="steelblue4",lwd = 1)
  text(stagionale$date[1],188, labels = c("180°"),col="steelblue4",cex = 1.2)
  
  segments(head(stagionale$date,1), 90, tail(stagionale$date,1), 90, lty = 1, col="lightskyblue3",lwd = 1)
  text(stagionale$date[1],98, labels = c("90°"),col="lightskyblue3",cex = 1.2)
  
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting HISTOGRAMS
  #
  wd_1 <- subset(stagionale, (wd <= 90))
  wd_2 <- subset(stagionale, (wd > 90 & wd <= 180))
  wd_3 <- subset(stagionale, (wd > 180 & wd <= 270))
  wd_4 <- subset(stagionale, (wd > 270 & wd <= 360))
  wd_freq = table(stagionale$wd)
  
  yhist <- hist(stagionale$wd, breaks=37, plot=FALSE)
  print(yhist)
  yhist_max<-(max(yhist$counts))
  
  h1<-hist(wd_1$wd, breaks=10, xlim=c(0,360), ylim=c(0,yhist_max), col="thistle1", xlab="", ylab="Relative frequency", main="Wind direction (degrees)",bty="l" , mgp = c(7, 3, 0))
  
  if(nrow(wd_2)>0){ h2<-hist(wd_2$wd, breaks=10, xlim=c(0,360), ylim=c(0,yhist_max), col="thistle2", add=T) }
  if(nrow(wd_3)>0){ h3<-hist(wd_3$wd, breaks=10, xlim=c(0,360), ylim=c(0,yhist_max), col="thistle3", add=T) }
  if(nrow(wd_4)>0){ h4<-hist(wd_4$wd, breaks=10, xlim=c(0,360), ylim=c(0,yhist_max), col="thistle4", add=T) }
  
  d <- density(stagionale$wd)
  plot(d,xlab="", 
       ylab="Density",
       main="Wind direction (deg)",
       mgp = c(7, 3, 0),
       polygon(d, col="steelblue", border="blue"))
} 
dev.off()  

# -------------------------------------------------------------------------------------------
##                                          # END PART 3.2.1 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.2.2 #
## ______________________________________________________________________________________________________________________##
##                                    Creating statistcs/graphic reports
##                                             T SEASONAL GRAPHS
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# -------------------------------------------------------------------------------------------
# Cleaning Destination directory
# 
FILE_PLOT_S         <-list.files(path = PLOT_DIR_S, pattern = paste(s_GAW_ID, inst_type,"T",questo_anno,"SEASONAL_GRAPH_*",sep = "_"), 
                                 all.files = FALSE,
                                 full.names = F, recursive = FALSE,
                                 ignore.case = FALSE, include.dirs = F, no.. = FALSE)
LISTA_PLOT_S        <-as.character(FILE_PLOT_S)


for(f in LISTA_PLOT_S){
  file.remove(paste(PLOT_DIR_S,f,sep = "/"))
}
#
# -------------------------------------------------------------------------------------------
# Defining seasons (quadrimesters)
#


t_L02_today_Y$season[as.numeric(t_L02_today_Y$monthNum)>=1  & as.numeric(t_L02_today_Y$monthNum)<=3]      <- 1
t_L02_today_Y$season[as.numeric(t_L02_today_Y$monthNum)>=4  & as.numeric(t_L02_today_Y$monthNum)<=6]      <- 2
t_L02_today_Y$season[as.numeric(t_L02_today_Y$monthNum)>=7  & as.numeric(t_L02_today_Y$monthNum)<=9]      <- 3
t_L02_today_Y$season[as.numeric(t_L02_today_Y$monthNum)>=10 & as.numeric(t_L02_today_Y$monthNum)<=12]     <- 4

seasons<-c(t_L02_today_Y[!duplicated(t_L02_today_Y[,c('season')]),]$season)
seasons 
# -------------------------------------------------------------------------------------------
# Preparing plotting files
#  
PLOT_S_NAME         <-paste(s_GAW_ID,"_",inst_type,"_T_",questo_anno,"_SEASONAL_GRAPH_",gsub("-","",Sys.Date()),sep = "")
PLOT_S_NAME_FULL    <-paste (PLOT_DIR_S,paste(PLOT_S_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_S_NAME_FULL, width = 2480, height = 3508)# width=2100,height=2970,res=300)
#
# -------------------------------------------------------------------------------------------
# Preparing plotting parameters (font size, margins, ...)
# 
par(mfrow = c(8,1))

par(ps = 14, cex = 2, cex.main = 4.0,cex.sub=2.2, cex.lab=3.5, cex.axis = 3.2, mai=c(0.6,1.8,0.5,0.5)) 
#
# -------------------------------------------------------------------------------------------
# Creating the plotting matrix
#    
m <- rbind(c(1, 1), c(2, 3), c(4, 4), c(5, 6), c(7, 7), c(8, 9), c(10, 10), c(11, 12))
layout(m)
#
# -------------------------------------------------------------------------------------------
# Creating the plotting matrix
#
for (stg in seasons)
{
  if(stg==1){stg_name<-"JAN - FEB - MAR"}
  if(stg==2){stg_name<-"APR - MAY - JUN"}
  if(stg==3){stg_name<-"JUL - AUG - SEP"}
  if(stg==4){stg_name<-"OCT - NOV - DEC"}
  print(stg)
  print(stg_name)
  
  t_L02_stg       <-subset(t_L02_today_Y, season ==stg)
  
  OBS_stg_start     <-head(format(t_L02_stg$date,"%d %B %Y"),1)
  OBS_stg_end       <-tail(format(t_L02_stg$date,"%d %B %Y"),1)
  
  stagionale<-subset(t_L02_stg, flag_t<0.900)
  stagionale$giorno <- format(stagionale$date,"%d")
  This_stg <- c(format(stagionale$date,"%m"))
  This_stg_Name <- c(format(stagionale$date,"%B"))
  
  
  stagionale$mean<-mean(stagionale$t)
  stagionale$sd<-sd(stagionale$t)
  stg_MIN<-subset(stagionale, t == min(stagionale$t))
  stg_MAX<-subset(stagionale, t == max(stagionale$t))
  
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting T
  #
  plot(ylim=c(min(stagionale$t)-2,max(stagionale$t)+5),
       stagionale$date, stagionale$t, type = "h",
       mgp = c(7, 3, 0),
       xlab = "",ylab ="T (°C) - L02", 
       col="lightblue", 
       panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 0.5))
  lines(stagionale$date, stagionale$t, type = "l", lty = 1, col="darkred",lwd = 0.5)
  title(main=paste("T",questo_anno,"   ",stg_name), line = -4.5)
  
  mtext(paste("Observations from", OBS_stg_start,
              " to ", OBS_stg_end,
              "(",1+(as.integer(tail((t_L02_stg$date),1)-head((t_L02_stg$date)),1))
              ,"days)       -       Statistics: ",
              "  T min: (", round(min(stagionale$t),1),") - T max: (", round(max(stagionale$t),1),") - T mean: (", round(mean(stagionale$t),1),") - T sd: (", round(sd(stagionale$t),1),")"),
        col="black",cex = 1.7, line = -8.0, font.main = 1)
  
  segments(head(stagionale$date), 0, tail(stagionale$date), 0, lty = 1, col="midnightblue",lwd = 1)
  text(stagionale$date[1],0.5, labels = c("0°"),col="midnightblue",cex = 1.8)
  
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting HISTOGRAMS
  #
  t_1 <- subset(stagionale, (t <= 0))
  t_2 <- subset(stagionale, (t >  0))
  
  yhist <- hist(stagionale$t, breaks=45, plot=FALSE)
  print(yhist)
  yhist_max<-(max(yhist$counts))
  
  h1<-hist(t_1$t, breaks= c(seq(-20, 30, by=0.5)), xlim=c(min(stagionale$t)-1,max(stagionale$t)+1), ylim=c(0,yhist_max), col="lightskyblue1", xlab="", 
           ylab="Relative frequency", main="Temperature (degrees)",bty="l", axes = F, mgp = c(7, 3, 0))
  h2<-hist(t_2$t, breaks= c(seq(-20, 30, by=0.5)), xlim=c(min(stagionale$t)-1,max(stagionale$t)+1), ylim=c(0,yhist_max), col="darksalmon", add=T, mgp = c(7, 3, 0))
  
  axis(1,at = seq(-20, 30,2),labels = T,pos = 0)
  axis(2,at = seq(0, yhist_max,20),labels = T,pos = min(stagionale$t)-1.7)
  
  d <- density(stagionale$t)
  plot(d,xlab="", 
       ylab="Density",
       main="Temperature (°C)",
       mgp = c(7, 3, 0),
       polygon(d, col="steelblue", border="blue"))
} 
dev.off()  

# -------------------------------------------------------------------------------------------
##                                          # END PART 3.2.2 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.2.3 #
## ______________________________________________________________________________________________________________________##
##                                    Creating statistcs/graphic reports
##                                             RH SEASONAL GRAPHS
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# -------------------------------------------------------------------------------------------
# Cleaning Destination directory
# 
FILE_PLOT_S         <-list.files(path = PLOT_DIR_S, pattern = paste(s_GAW_ID, inst_type,"RH",questo_anno,"SEASONAL_GRAPH_*",sep = "_"), 
                                 all.files = FALSE,
                                 full.names = F, recursive = FALSE,
                                 ignore.case = FALSE, include.dirs = F, no.. = FALSE)
LISTA_PLOT_S        <-as.character(FILE_PLOT_S)


for(f in LISTA_PLOT_S){
  file.remove(paste(PLOT_DIR_S,f,sep = "/"))
}
#
# -------------------------------------------------------------------------------------------
# Defining seasons (quadrimesters)
#


rh_L02_today_Y$season[as.numeric(rh_L02_today_Y$monthNum)>=1  & as.numeric(rh_L02_today_Y$monthNum)<=3]      <- 1
rh_L02_today_Y$season[as.numeric(rh_L02_today_Y$monthNum)>=4  & as.numeric(rh_L02_today_Y$monthNum)<=6]      <- 2
rh_L02_today_Y$season[as.numeric(rh_L02_today_Y$monthNum)>=7  & as.numeric(rh_L02_today_Y$monthNum)<=9]      <- 3
rh_L02_today_Y$season[as.numeric(rh_L02_today_Y$monthNum)>=10 & as.numeric(rh_L02_today_Y$monthNum)<=12]     <- 4

seasons<-c(rh_L02_today_Y[!duplicated(rh_L02_today_Y[,c('season')]),]$season)
seasons 
# -------------------------------------------------------------------------------------------
# Preparing plotting files
#  
PLOT_S_NAME         <-paste(s_GAW_ID,"_",inst_type,"_RH_",questo_anno,"_SEASONAL_GRAPH_",gsub("-","",Sys.Date()),sep = "")
PLOT_S_NAME_FULL    <-paste (PLOT_DIR_S,paste(PLOT_S_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_S_NAME_FULL, width = 2480, height = 3508)# width=2100,height=2970,res=300)
#
# -------------------------------------------------------------------------------------------
# Preparing plotting parameters (font size, margins, ...)
# 
par(mfrow = c(8,1))

par(ps = 14, cex = 2, cex.main = 4.0,cex.sub=2.2, cex.lab=3.5, cex.axis = 3.2, mai=c(0.6,1.8,0.5,0.5)) 
#
# -------------------------------------------------------------------------------------------
# Creating the plotting matrix
#    
m <- rbind(c(1, 1), c(2, 3), c(4, 4), c(5, 6), c(7, 7), c(8, 9), c(10, 10), c(11, 12))
layout(m)
#
# -------------------------------------------------------------------------------------------
# Creating the plotting matrix
#
for (stg in seasons)
{
  if(stg==1){stg_name<-"JAN - FEB - MAR"}
  if(stg==2){stg_name<-"APR - MAY - JUN"}
  if(stg==3){stg_name<-"JUL - AUG - SEP"}
  if(stg==4){stg_name<-"OCT - NOV - DEC"}
  print(stg)
  print(stg_name)
  
  rh_L02_stg       <-subset(rh_L02_today_Y, season ==stg)
  
  OBS_stg_start     <-head(format(rh_L02_stg$date,"%d %B %Y"),1)
  OBS_stg_end       <-tail(format(rh_L02_stg$date,"%d %B %Y"),1)
  
  stagionale<-subset(rh_L02_stg, flag_rh<0.900)
  stagionale$giorno <- format(stagionale$date,"%d")
  This_stg <- c(format(stagionale$date,"%m"))
  This_stg_Name <- c(format(stagionale$date,"%B"))
  
  
  stagionale$mean<-mean(stagionale$rh)
  stagionale$sd<-sd(stagionale$rh)
  stg_MIN<-subset(stagionale, rh == min(stagionale$rh))
  stg_MAX<-subset(stagionale, rh == max(stagionale$rh))
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting RH
  #
  plot(ylim=c(-9,140),
       stagionale$date, stagionale$rh, type = "h",
       mgp = c(7, 3, 0),
       xlab = "",ylab ="RH (%) - L02", 
       col="lightblue", 
       panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 0.5))
  lines(stagionale$date, stagionale$rh, type = "l", lty = 1, col="darkred",lwd = 0.5)
  title(main=paste("RH",questo_anno,"   ",stg_name), line = -4.5)
  
  mtext(paste("Observations from", OBS_stg_start,
              " to ", OBS_stg_end,
              "(",1+(as.integer(tail((rh_L02_stg$date),1)-head((rh_L02_stg$date)),1))
              ,"days)       -       Statistics: ",
              "  RH min: (", round(min(stagionale$rh),1),") - RH max: (", round(max(stagionale$rh),1),") - RH mean: (", round(mean(stagionale$rh),1),") - RH sd: (", round(sd(stagionale$rh),1),")"),
        col="black",cex = 1.7, line = -8.0, font.main = 1)
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting HISTOGRAMS
  #
  rh_1 <- subset(stagionale, (rh <= 40))
  rh_2 <- subset(stagionale, (rh > 40 & rh <= 50))
  rh_3 <- subset(stagionale, (rh > 50 & rh <= 60))
  rh_4 <- subset(stagionale, (rh > 60 & rh <= 70))
  rh_5 <- subset(stagionale, (rh > 70 & rh <= 80))
  rh_6 <- subset(stagionale, (rh > 80))
  rh_freq = table(stagionale$rh)
  
  rh_1$rh[is.na(rh_1$rh)]<-0
  
  yhist <- hist(stagionale$rh, breaks=12, plot=FALSE)
  print(yhist)
  yhist_max<-(max(yhist$counts))
  
  h1<-hist(rh_1$rh, breaks= c(seq(-0, 110, by=5)), xlim=c(0,100), ylim=c(0,yhist_max), col="lightcyan", xlab="", 
           ylab="Relative frequency", main="Relative humidity (%)",bty="l" , mgp = c(7, 3, 0))
  h2<-hist(rh_2$rh, breaks= c(seq(-0, 110, by=5)), xlim=c(0,100), ylim=c(0,yhist_max), col="lightcyan1", add=T)
  h3<-hist(rh_3$rh, breaks= c(seq(-0, 110, by=5)), xlim=c(0,100), ylim=c(0,yhist_max), col="lightcyan2", add=T)
  h4<-hist(rh_4$rh, breaks= c(seq(-0, 110, by=5)), xlim=c(0,100), ylim=c(0,yhist_max), col="cadetblue1", add=T) 
  h5<-hist(rh_5$rh, breaks= c(seq(-0, 110, by=5)), xlim=c(0,100), ylim=c(0,yhist_max), col="cadetblue2", add=T)
  h6<-hist(rh_6$rh, breaks= c(seq(-0, 110, by=5)), xlim=c(0,100), ylim=c(0,yhist_max), col="cadetblue3", add=T)
  
  d <- density(stagionale$rh)
  plot(d,xlab="", 
       ylab="Density",
       main="Relative humidity (%)",
       mgp = c(7, 3, 0),
       polygon(d, col="steelblue", border="blue"))
} 
dev.off()  

# -------------------------------------------------------------------------------------------
##                                          # END PART 3.2.3 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.2.4 #
## ______________________________________________________________________________________________________________________##
##                                    Creating statistcs/graphic reports
##                                             P SEASONAL GRAPHS
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# -------------------------------------------------------------------------------------------
# Cleaning Destination directory
# 
FILE_PLOT_S         <-list.files(path = PLOT_DIR_S, pattern = paste(s_GAW_ID, inst_type,"P",questo_anno,"SEASONAL_GRAPH_*",sep = "_"), 
                                 all.files = FALSE,
                                 full.names = F, recursive = FALSE,
                                 ignore.case = FALSE, include.dirs = F, no.. = FALSE)
LISTA_PLOT_S        <-as.character(FILE_PLOT_S)


for(f in LISTA_PLOT_S){
  file.remove(paste(PLOT_DIR_S,f,sep = "/"))
}
#
# -------------------------------------------------------------------------------------------
# Defining seasons (quadrimesters)
#
p_L02_today_Y$season[as.numeric(p_L02_today_Y$monthNum)>=1  & as.numeric(p_L02_today_Y$monthNum)<=3]      <- 1
p_L02_today_Y$season[as.numeric(p_L02_today_Y$monthNum)>=4  & as.numeric(p_L02_today_Y$monthNum)<=6]      <- 2
p_L02_today_Y$season[as.numeric(p_L02_today_Y$monthNum)>=7  & as.numeric(p_L02_today_Y$monthNum)<=9]      <- 3
p_L02_today_Y$season[as.numeric(p_L02_today_Y$monthNum)>=10 & as.numeric(p_L02_today_Y$monthNum)<=12]     <- 4

seasons<-c(p_L02_today_Y[!duplicated(p_L02_today_Y[,c('season')]),]$season)
seasons 
# -------------------------------------------------------------------------------------------
# Preparing plotting files
#  
PLOT_S_NAME         <-paste(s_GAW_ID,"_",inst_type,"_P_",questo_anno,"_SEASONAL_GRAPH_",gsub("-","",Sys.Date()),sep = "")
PLOT_S_NAME_FULL    <-paste (PLOT_DIR_S,paste(PLOT_S_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_S_NAME_FULL, width = 2480, height = 3508)# width=2100,height=2970,res=300)
#
# -------------------------------------------------------------------------------------------
# Preparing plotting parameters (font size, margins, ...)
# 
par(mfrow = c(8,1))

par(ps = 14, cex = 2, cex.main = 4.0,cex.sub=2.2, cex.lab=3.5, cex.axis = 3.2, mai=c(0.6,1.8,0.5,0.5)) 
#
# -------------------------------------------------------------------------------------------
# Creating the plotting matrix
#    
m <- rbind(c(1, 1), c(2, 3), c(4, 4), c(5, 6), c(7, 7), c(8, 9), c(10, 10), c(11, 12))
layout(m)
#
# -------------------------------------------------------------------------------------------
# Creating the plotting matrix
#
for (stg in seasons)
{
  if(stg==1){stg_name<-"JAN - FEB - MAR"}
  if(stg==2){stg_name<-"APR - MAY - JUN"}
  if(stg==3){stg_name<-"JUL - AUG - SEP"}
  if(stg==4){stg_name<-"OCT - NOV - DEC"}
  print(stg)
  print(stg_name)
  
  p_L02_stg       <-subset(p_L02_today_Y, season ==stg)

  p_L02_stg$flag_p[p_L02_stg$p < 750] <-0.999 
  
  OBS_stg_start     <-head(format(p_L02_stg$date,"%d %B %Y"),1)
  OBS_stg_end       <-tail(format(p_L02_stg$date,"%d %B %Y"),1)
  
  stagionale<-subset(p_L02_stg, flag_p<0.900)
  
  stagionale$giorno <- format(stagionale$date,"%d")
  This_stg <- c(format(stagionale$date,"%m"))
  This_stg_Name <- c(format(stagionale$date,"%B"))
  
  
  stagionale$mean<-mean(stagionale$p)
  stagionale$sd<-sd(stagionale$p)
  stg_MIN<-subset(stagionale, p == min(stagionale$p))
  stg_MAX<-subset(stagionale, p == max(stagionale$p))
  
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting P
  #
  plot(ylim=c(min(stagionale$p)-5,max(stagionale$p)+5),
       stagionale$date, stagionale$p, type = "h",
       mgp = c(7, 3, 0),
       xlab = "",ylab ="P (hPa) - L02", 
       col="lightblue", 
       panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 0.5))
  lines(stagionale$date, stagionale$p, type = "l", lty = 1, col="darkred",lwd = 0.5)
  title(main=paste("P",questo_anno,"   ",stg_name), line = -4.5)
  
  mtext(paste(stagionale$date[length(stagionale$date)/2][1],706, labels = paste("Observations from", OBS_stg_start,
                                                                                " to ", OBS_stg_end,
                                                                                "(",1+(as.integer(tail((p_L02_stg$date),1)-head((p_L02_stg$date)),1))
                                                                                ,"days)       -       Statistics: ",
                                                                                "  P min: (", round(min(stagionale$p),1),") - P max: (", round(max(stagionale$p),1),") - P mean: (", round(mean(stagionale$p),1),") - P sd: (", round(sd(stagionale$p),1),")"),
              col="black",pos=1,cex = 1.8),
        col="black",cex = 1.7, line = -8.0, font.main = 1)
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting HISTOGRAMS
  #
  p_1 <- subset(stagionale, (p <= 750))
  p_2 <- subset(stagionale, (p > 750 & p <= 766))
  p_3 <- subset(stagionale, (p > 766 & p <= 782))
  p_4 <- subset(stagionale, (p > 782 & p <= 798))
  p_5 <- subset(stagionale, (p > 798 & p <= 814))
  p_6 <- subset(stagionale, (p > 814))
  p_freq = table(stagionale$p)
  
  p_1$p[is.na(p_1$p)]<-0

  yhist <- hist(stagionale$p, breaks=20, plot=FALSE)
  print(yhist)
  yhist_max<-(max(yhist$counts))
  
  h1<-hist(p_1$p, breaks= c(seq(700, 830, by=4)), xlim=c(750, 830), ylim=c(0,yhist_max+150), col="lightcyan", xlab="", 
           ylab="Relative frequency", main="Pressure (hPa)", bty="l", mgp = c(7, 3, 0))
  h2<-hist(p_2$p, breaks= c(seq(700, 830, by=4)), xlim=c(750, 830), ylim=c(0,yhist_max+150), col="lightcyan1", add=T)
  h3<-hist(p_3$p, breaks= c(seq(700, 830, by=4)), xlim=c(750, 830), ylim=c(0,yhist_max+150), col="lightcyan2", add=T)
  h4<-hist(p_4$p, breaks= c(seq(700, 830, by=4)), xlim=c(750, 830), ylim=c(0,yhist_max+150), col="cadetblue1", add=T) 
  h5<-hist(p_5$p, breaks= c(seq(700, 830, by=4)), xlim=c(750, 830), ylim=c(0,yhist_max+150), col="cadetblue2", add=T)
  h6<-hist(p_6$p, breaks= c(seq(700, 830, by=4)), xlim=c(750, 830), ylim=c(0,yhist_max+150), col="cadetblue3", add=T)
  
  
  d <- density(stagionale$p)
  plot(d,xlab="", 
       ylab="Density",
       main="Pressure (hPa)",
       mgp = c(7, 3, 0),
       polygon(d, col="steelblue", border="blue"))
} 
dev.off()  

# -------------------------------------------------------------------------------------------
##                                          # END PART 3.2.4 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.2.5 #
## ______________________________________________________________________________________________________________________##
##                                    Creating statistcs/graphic reports
##                                             RAD SEASONAL GRAPHS
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# -------------------------------------------------------------------------------------------
# Cleaning Destination directory
# 
FILE_PLOT_S         <-list.files(path = PLOT_DIR_S, pattern = paste(s_GAW_ID, inst_type,"RAD",questo_anno,"SEASONAL_GRAPH_*",sep = "_"), 
                                 all.files = FALSE,
                                 full.names = F, recursive = FALSE,
                                 ignore.case = FALSE, include.dirs = F, no.. = FALSE)
LISTA_PLOT_S        <-as.character(FILE_PLOT_S)


for(f in LISTA_PLOT_S){
  file.remove(paste(PLOT_DIR_S,f,sep = "/"))
}
#
# -------------------------------------------------------------------------------------------
# Defining seasons (quadrimesters)
#
rad_L02_today_Y$season[as.numeric(rad_L02_today_Y$monthNum)>=1  & as.numeric(rad_L02_today_Y$monthNum)<=3]      <- 1
rad_L02_today_Y$season[as.numeric(rad_L02_today_Y$monthNum)>=4  & as.numeric(rad_L02_today_Y$monthNum)<=6]      <- 2
rad_L02_today_Y$season[as.numeric(rad_L02_today_Y$monthNum)>=7  & as.numeric(rad_L02_today_Y$monthNum)<=9]      <- 3
rad_L02_today_Y$season[as.numeric(rad_L02_today_Y$monthNum)>=10 & as.numeric(rad_L02_today_Y$monthNum)<=12]     <- 4

seasons<-c(rad_L02_today_Y[!duplicated(rad_L02_today_Y[,c('season')]),]$season)
seasons 
# -------------------------------------------------------------------------------------------
# Preparing plotting files
#  
PLOT_S_NAME         <-paste(s_GAW_ID,"_",inst_type,"_RAD_",questo_anno,"_SEASONAL_GRAPH_",gsub("-","",Sys.Date()),sep = "")
PLOT_S_NAME_FULL    <-paste (PLOT_DIR_S,paste(PLOT_S_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_S_NAME_FULL, width = 2480, height = 3508)# width=2100,height=2970,res=300)
#
# -------------------------------------------------------------------------------------------
# Preparing plotting parameters (font size, margins, ...)
# 
par(mfrow = c(8,1))

par(ps = 14, cex = 2, cex.main = 4.0,cex.sub=2.2, cex.lab=3.5, cex.axis = 3.2, mai=c(0.6,1.8,0.5,0.5)) 
#
# -------------------------------------------------------------------------------------------
# Creating the plotting matrix
#    
m <- rbind(c(1, 1), c(2, 3), c(4, 4), c(5, 6), c(7, 7), c(8, 9), c(10, 10), c(11, 12))
layout(m)
#
# -------------------------------------------------------------------------------------------
# Creating the plotting matrix
#
for (stg in seasons)
{
  if(stg==1){stg_name<-"JAN - FEB - MAR"}
  if(stg==2){stg_name<-"APR - MAY - JUN"}
  if(stg==3){stg_name<-"JUL - AUG - SEP"}
  if(stg==4){stg_name<-"OCT - NOV - DEC"}
  print(stg)
  print(stg_name)
  
  rad_L02_stg       <-subset(rad_L02_today_Y, season ==stg)
  
  OBS_stg_start     <-head(format(rad_L02_stg$date,"%d %B %Y"),1)
  OBS_stg_end       <-tail(format(rad_L02_stg$date,"%d %B %Y"),1)
  
  stagionale<-subset(rad_L02_stg, flag_rad<0.900)
  stagionale$giorno <- format(stagionale$date,"%d")
  This_stg <- c(format(stagionale$date,"%m"))
  This_stg_Name <- c(format(stagionale$date,"%B"))
  
  
  stagionale$mean<-mean(stagionale$rad)
  stagionale$sd<-sd(stagionale$rad)
  stg_MIN<-subset(stagionale, rad == min(stagionale$rad))
  stg_MAX<-subset(stagionale, rad == max(stagionale$rad))
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting RAD
  #
  plot(ylim=c(-70,max(stagionale$rad)[1]+20),
       stagionale$date, stagionale$rad, type = "h",
       mgp = c(7, 3, 0),
       xlab = "",ylab =expression(paste("RAD (W/m"^{2},") - L02")), 
       col="lightblue", 
       panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 0.5))
  lines(stagionale$date, stagionale$rad, type = "l", lty = 1, col="darkred",lwd = 0.5)
  title(main=paste("RAD",questo_anno,"   ",stg_name), line = -4.5)
  
  mtext(paste("Observations from", OBS_stg_start,
              " to ", OBS_stg_end,
              "(",1+(as.integer(tail((rad_L02_stg$date),1)-head((rad_L02_stg$date)),1))
              ,"days)       -       Statistics: ",
              "  RAD min: (", round(min(stagionale$rad),1),") - RAD max: (", round(max(stagionale$rad),1),") - RAD mean: (", round(mean(stagionale$rad),1),") - RAD sd: (", round(sd(stagionale$rad),1),")"),
        col="black",cex = 1.7, line = -8.0, font.main = 1)
  
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting HISTOGRAMS
  #
  stagionale<- subset(stagionale, (rad >= 0))
  
  rad_1 <- subset(stagionale, (rad <= 20))
  rad_2 <- subset(stagionale, (rad > 20 & rad <= 40))
  rad_3 <- subset(stagionale, (rad > 40 & rad <= 80))  
  rad_4 <- subset(stagionale, (rad > 80 & rad <= 120))
  rad_5 <- subset(stagionale, (rad > 120 & rad <= 160))
  rad_6 <- subset(stagionale, (rad > 160 & rad <= 200))
  rad_7 <- subset(stagionale, (rad > 200 & rad <= 220))
  rad_8 <- subset(stagionale, (rad > 220))
  rad_freq = table(stagionale$rad)
  
  rad_1$rad[is.na(rad_1$rad)]<-0

  yhist <- hist(stagionale$rad, breaks=20, plot=FALSE)
  print(yhist)
  yhist_max<-(max(yhist$counts))
  
  h1<-hist(rad_1$rad, breaks= c(seq(0, 1500, by=8)), xlim=c(0, 150), ylim=c(0,yhist_max+50), col="gold", xlab="",
           ylab="Relative frequency", main="Global radiation (W/m2)", bty="l" , mgp = c(7, 3, 0))
  h2<-hist(rad_2$rad, breaks= c(seq(0, 1500, by=8)), xlim=c(0, 150), ylim=c(0,yhist_max+50), col="gold1", add=T)
  h3<-hist(rad_3$rad, breaks= c(seq(0, 1500, by=8)), xlim=c(0, 150), ylim=c(0,yhist_max+50), col="gold2", add=T)
  h4<-hist(rad_4$rad, breaks= c(seq(0, 1500, by=8)), xlim=c(0, 150), ylim=c(0,yhist_max+50), col="gold3", add=T) 
  h5<-hist(rad_5$rad, breaks= c(seq(0, 1500, by=8)), xlim=c(0, 150), ylim=c(0,yhist_max+50), col="gold4", add=T)
  h6<-hist(rad_6$rad, breaks= c(seq(0, 1500, by=8)), xlim=c(0, 150), ylim=c(0,yhist_max+50), col="darkorange4", add=T)
  
  d <- density(stagionale$rad)
  plot(d,xlab="", 
       ylab="Density",
       main=expression(paste("Global radiation (W/m"^{2},")")),
       mgp = c(7, 3, 0),
       polygon(d, col="steelblue", border="blue"))
} 
dev.off()  

# -------------------------------------------------------------------------------------------
##                                          # END PART 3.2.5 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.3 #
## ______________________________________________________________________________________________________________________##
##                                    Creating statistcs/graphic reports
##                                               ANNUAL GRAPHS
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Cleaning Destination directory
# 
FILE_PLOT_Y             <-list.files(path = PLOT_DIR_Y, pattern = paste(s_GAW_ID, inst_type,questo_anno,"ANNUAL_GRAPH_*",sep = "_"), all.files = FALSE,
                                   full.names = F, recursive = FALSE,
                                   ignore.case = FALSE, include.dirs = F, no.. = FALSE)
FILE_PLOT_Y
LISTA_PLOT_Y            <-as.character(FILE_PLOT_Y)
for(f in LISTA_PLOT_Y)  { file.remove(paste(PLOT_DIR_Y,f,sep = "/")) }
#
# -------------------------------------------------------------------------------------------
# Defining statistics
#
OBS_start             <-head(format(temp_L02$date,"%d %B %Y"),1)
OBS_end               <-tail(format(temp_L02$date,"%d %B %Y"),1)
#
# -------------------------------------------------------------------------------------------
# Defining plotting parameters
#
PLOT_Y_NAME             <-paste(s_GAW_ID, inst_type, questo_anno,"ANNUAL_GRAPH_",gsub("-","",Sys.Date()),sep = "_")
PLOT_Y_NAME_FULL        <-paste (PLOT_DIR_Y,paste(PLOT_Y_NAME,".png",sep = ""),sep = "/")
png(file=,PLOT_Y_NAME_FULL, width = 2480, height = 3508)

# -------------------------------------------------------------------------------------------
# Preparing plotting parameters (font size, margins, ...)
# 
par(mfrow = c(8,1))
par(ps = 14, cex = 2.5, cex.main = 3.5,cex.sub=2.2, cex.lab=3.5, cex.axis = 3.5, mai=c(0.3,1.8,0.5,0.5))
#
# -------------------------------------------------------------------------------------------
# Crating the plotting matrix
#
m <- rbind(c(1, 1), c(2, 2), c(3, 3), c(4, 4), c(5, 5), c(6, 6), c(7, 8))
layout(m)
#
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# Plotting WS
#
ws_L02_today_Y$mean   <-mean(ws_L02_today_Y$ws)
ws_MIN                <-subset(ws_L02_today_Y, ws == min(ws_L02_today_Y$ws))
ws_MAX                <-subset(ws_L02_today_Y, ws == max(ws_L02_today_Y$ws))
#
plot(ylim=c(-2,max(ws_L02_today_Y$ws)+5),
     mgp = c(8, 4, 0),
     ws_L02_today_Y$date, ws_L02_today_Y$ws, type = "h",
     xlab = "",ylab ="WS (m/s) - L02", col="darkseagreen1", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
title(paste("Wind speed - L02 -",questo_anno), line = -3)
lines(ws_L02_today_Y$date, ws_L02_today_Y$ws, type = "l", lty = 1, col="darkred",lwd = 0.5)

points(ws_MAX$date[1], ws_MAX$ws[1], col= "magenta",pch=20)
text(ws_MAX$date[1], -0.1, labels = paste0("Max (",format(ws_MAX$date[1],"%B %d"),")"),col="magenta",pos=1,cex = 1.8)
segments(ws_MAX$date[1], ws_MAX$ws[1], ws_MAX$date[1], -1, lty = 2, col="black",lwd = 1)

points(ws_MIN$date[1], ws_MIN$ws[1], col= "blue",pch=20)
text(ws_MIN$date[1], -0.1, labels = paste0("Min (",format(ws_MIN$date[1],"%B %d"),")"),col="blue",pos=1,cex = 1.8)
segments(ws_MIN$date[1], ws_MIN$ws[1], ws_MIN$date[1], -1, lty = 2, col="black",lwd = 1)

#
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# Plotting WD
#
wd_L02_today_Y$mean   <-mean(wd_L02_today_Y$wd)
wd_MIN                <-subset(wd_L02_today_Y, wd == min(wd_L02_today_Y$wd))
wd_MAX                <-subset(wd_L02_today_Y, wd == max(wd_L02_today_Y$wd))

plot(ylim=c(-15,480),
     mgp = c(8, 4, 0),
     wd_L02_today_Y$date, wd_L02_today_Y$wd, type = "h",
     xlab = "",ylab =("WD (deg) - L02"), col="paleturquoise", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 0.5))
title(paste("Wind direction - L02 -",questo_anno), line = -3)

lines(wd_L02_today_Y$date, wd_L02_today_Y$wd, type = "l", lty = 1, col="darkblue",lwd = 0.5)

segments(head(wd_L02_today_Y$date), 360, tail(wd_L02_today_Y$date), 360, lty = 1, col="midnightblue",lwd = 0.5)
text(wd_L02_today_Y$date[1],368, labels = c("360°"),col="midnightblue",cex = 1.8)

segments(head(wd_L02_today_Y$date), 270, tail(wd_L02_today_Y$date), 270, lty = 1, col="dodgerblue3",lwd = 0.5)
text(wd_L02_today_Y$date[1],278, labels = c("270°"),col="dodgerblue3",cex = 1.8)

segments(head(wd_L02_today_Y$date), 180, tail(wd_L02_today_Y$date), 180, lty = 1, col="steelblue4",lwd = 0.5)
text(wd_L02_today_Y$date[1],188, labels = c("180°"),col="steelblue4",cex = 1.8)

segments(head(wd_L02_today_Y$date), 90, tail(wd_L02_today_Y$date), 90, lty = 1, col="lightskyblue3",lwd = 0.5)
text(wd_L02_today_Y$date[1],98, labels = c("90°"),col="lightskyblue3",cex = 1.8)
#
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# Plotting T
#
t_L02_today_Y$mean   <-mean(t_L02_today_Y$t)
t_MIN                <-subset(t_L02_today_Y, t == min(t_L02_today_Y$t))
t_MAX                <-subset(t_L02_today_Y, t == max(t_L02_today_Y$t))

plot(ylim=c(min(t_L02_today_Y$t)-1,max(t_L02_today_Y$t)+3),
     t_L02_today_Y$date, t_L02_today_Y$t, type = "h",
     mgp = c(8, 4, 0),
     xlab = "",ylab =("T (°C) - L02"), col="darksalmon", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
title(paste("Temperature - L02 -",questo_anno), line = -3)
lines(t_L02_today_Y$date, t_L02_today_Y$t, type = "l", lty = 1, col="darkred",lwd = 0.5)

points(t_MAX$date[1], t_MAX$t[1], col= "magenta",pch=20)
text(t_MAX$date[1], min(t_L02_today_Y$t)-1, labels = paste0("Max (",format(t_MAX$date[1],"%B %d"),")"),col="magenta",pos=1,cex = 1.8)
segments(t_MAX$date[1], t_MAX$t[1], t_MAX$date[1], -1, lty = 2, col="black",lwd = 1)

points(t_MIN$date[1], t_MIN$t[1], col= "blue",pch=20)
text(t_MIN$date[1], min(t_L02_today_Y$t)-1, labels = paste0("Min (",format(t_MIN$date[1],"%B %d"),")"),col="blue",pos=1,cex = 1.8)
segments(t_MIN$date[1], t_MIN$t[1], t_MIN$date[1], -1, lty = 2, col="black",lwd = 1)

segments(head(t_L02_today_Y$date), 0, tail(t_L02_today_Y$date), 0, lty = 1, col="midnightblue",lwd = 1)
text(t_L02_today_Y$date[1],0.5, labels = c("0°C"),col="midnightblue",cex = 1.8) 
#
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# Plotting RH
rh_L02_today_Y$mean   <-mean(rh_L02_today_Y$rh)
rh_MIN                <-subset(rh_L02_today_Y, rh == min(rh_L02_today_Y$rh))
rh_MAX                <-subset(rh_L02_today_Y, rh == max(rh_L02_today_Y$rh))


plot(ylim=c(min(rh_L02_today_Y$rh)-10,140),
     rh_L02_today_Y$date, rh_L02_today_Y$rh, type = "h",
     mgp = c(8, 4, 0),
     xlab = "",ylab =("RH (%) - L02"), col="slategray2", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
title(paste("Relative humidity - L02 -",questo_anno), line = -3)
lines(rh_L02_today_Y$date, rh_L02_today_Y$rh, type = "l", lty = 1, col="darkred",lwd = 0.5)

points(rh_MAX$date[1], rh_MAX$rh[1], col= "magenta",pch=20)
text(rh_MAX$date[1], rh_MIN$rh[1]-8, labels = paste0("Max (",format(rh_MAX$date[1],"%B %d"),")"),col="magenta",pos=1,cex = 1.8)
segments(rh_MAX$date[1], rh_MAX$rh[1], rh_MAX$date[1], -1, lty = 2, col="black",lwd = 1)

points(rh_MIN$date[1], rh_MIN$rh[1], col= "blue",pch=20)
text(rh_MIN$date[1], rh_MIN$rh[1]-8, labels = paste0("Min (",format(rh_MIN$date[1],"%B %d"),")"),col="blue",pos=1,cex = 1.8)
segments(rh_MIN$date[1], rh_MIN$rh[1], rh_MIN$date[1], -1, lty = 2, col="black",lwd = 1)
#
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# Plotting P
#
p_L02_today_Y$mean   <-mean(p_L02_today_Y$p)
p_MIN                <-subset(p_L02_today_Y, p == min(p_L02_today_Y$p))
p_MAX                <-subset(p_L02_today_Y, p == max(p_L02_today_Y$p))

plot(ylim=c(720,max(p_L02_today_Y$p)+10),
     p_L02_today_Y$date, p_L02_today_Y$p, type = "h",
     mgp = c(8, 4, 0),
     xlab = "",ylab =("P (hPa) - L02"), col="thistle3", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
title(paste("Pressure - L02 -",questo_anno), line = -3)
lines(p_L02_today_Y$date, p_L02_today_Y$p, type = "l", lty = 1, col="darkred",lwd = 2)

points(p_MAX$date[1], p_MAX$p[1], col= "magenta",pch=20)
text(p_MAX$date[1], 720, labels = paste0("Max (",format(p_MAX$date[1],"%B %d"),")"),col="magenta",pos=1,cex = 1.8)
segments(p_MAX$date[1], p_MAX$p[1], p_MAX$date[1], 720, lty = 2, col="black",lwd = 1)

points(p_MIN$date[1], p_MIN$p[1], col= "blue",pch=20)
text(p_MIN$date[1], 720, labels = paste0("Min (",format(p_MIN$date[1],"%B %d"),")"),col="blue",pos=1,cex = 1.8)
segments(p_MIN$date[1], p_MIN$p[1], p_MIN$date[1], 720, lty = 2, col="black",lwd = 1)
#
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# Plotting RAD
#
rad_L02_today_Y$mean   <-mean(rad_L02_today_Y$rad)
rad_MIN                <-subset(rad_L02_today_Y, rad == min(rad_L02_today_Y$rad))
rad_MAX                <-subset(rad_L02_today_Y, rad == max(rad_L02_today_Y$rad))

plot(ylim=c(-30,max(rad_L02_today_Y$rad)[1]+20),
     rad_L02_today_Y$date, rad_L02_today_Y$rad, type = "h",
     mgp = c(8, 4, 0),
     xlab = "",ylab =expression(paste("RAD (W/m"^{2},") - L02")), col="goldenrod", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
title(paste("Global radiation - L02 -",questo_anno), line = -3)
lines(rad_L02_today_Y$date, rad_L02_today_Y$rad, type = "l", lty = 1, col="darkred",lwd = 0.5)

points(rad_MAX$date[1], rad_MAX$rad[1], col= "magenta",pch=20)
text(rad_MAX$date[1], 0, labels = paste0("Max (",format(rad_MAX$date[1],"%B %d"),")"),col="magenta",pos=1,cex = 1.8)
segments(rad_MAX$date[1], rad_MAX$rad[1], rad_MAX$date[1], 0, lty = 2, col="black",lwd = 1)

points(rad_MIN$date[1], rad_MIN$rad[1], col= "blue",pch=20)
text(rad_MIN$date[1], 0, labels = paste0("Min (",format(rad_MIN$date[1],"%B %d"),")"),col="blue",pos=1,cex = 1.8)
segments(rad_MIN$date[1], rad_MIN$rad[1], rad_MIN$date[1], 0, lty = 2, col="black",lwd = 1) 
#

plot(c(0, 1), c(0, 1), ann = F, bty = 'n', type = 'n', xaxt = 'n', yaxt = 'n')
text(x = 0, y = 0.95, paste (PLOT_M_NAME,"  -  ",questo_anno),
     cex = 3.3, col = "darkred",pos = 4)
#
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# Plotting Statistics
#
text(x = -0.005, y = 0.37, paste(" Observations from ", OBS_start," to ", OBS_end,
                                 "\n",
                                 "(Days of observation: ", 1+(as.integer(tail((temp_L02$date),1)-head((temp_L02$date)),1)),")","\n","\n",
                                 
                                 "WS min: (", round(min(ws_L02_today_Y$ws),1),") - WS max: (", round(max(ws_L02_today_Y$ws),1),") - WS mean: (", round(mean(ws_L02_today_Y$ws),1),") - WS sd: (", round(sd(ws_L02_today_Y$ws),1),")","\n",
                                 "WS percentile:    5th: (",round(quantile(ws_mensile$ws, probs = c(0.05)),digits=1),")",
                                 " - 25th: (",round(quantile(ws_L02_today_Y$ws, probs = c(0.25)),digits=1),")",
                                 " - 50th: (",round(quantile(ws_L02_today_Y$ws, probs = c(0.50)),digits=1),")",
                                 " - 75th: (",round(quantile(ws_L02_today_Y$ws, probs = c(0.75)),digits=1),")",
                                 " - 95th: (",round(quantile(ws_L02_today_Y$ws, probs = c(0.95)),digits=1),")","\n","\n",
                                 
                                 "T min: (", round(min(t_L02_today_Y$t),1),") - T max: (", round(max(t_L02_today_Y$t),1),") - T mean: (", round(mean(t_L02_today_Y$t),1),") - T sd: (", round(sd(t_L02_today_Y$t),1),")","\n",
                                 "T percentile:    5th: (",round(quantile(t_L02_today_Y$t, probs = c(0.05)),digits=1),")",
                                 " - 25th: (",round(quantile(t_L02_today_Y$t, probs = c(0.25)),digits=1),")",
                                 " - 50th: (",round(quantile(t_L02_today_Y$t, probs = c(0.50)),digits=1),")",
                                 " - 75th: (",round(quantile(t_L02_today_Y$t, probs = c(0.75)),digits=1),")",
                                 " - 95th: (",round(quantile(t_L02_today_Y$t, probs = c(0.95)),digits=1),")","\n","\n",
                                 sep="")
     , cex = 2.8, col = "black",pos = 4)

plot(c(0, 1), c(0, 1), ann = F, bty = 'n', type = 'n', xaxt = 'n', yaxt = 'n')
text(x = 0, y = 0.95, paste ("Statistics  -  ",questo_anno),
     cex = 3.3, col = "darkred",pos = 4)  

text(x = 0, y = 0.38, paste("\n", 
                            
                            "RH min: (", round(min(rh_L02_today_Y$rh),1),") - RH max: (", round(max(rh_L02_today_Y$rh),1),") - RH mean: (", round(mean(rh_L02_today_Y$rh),1),") - RH sd: (", round(sd(rh_L02_today_Y$rh),1),")","\n",
                            "RH percentile:    5th: (",round(quantile(rh_L02_today_Y$rh, probs = c(0.05)),digits=1),")",
                            " - 25th: (",round(quantile(rh_L02_today_Y$rh, probs = c(0.25)),digits=1),")",
                            " - 50th: (",round(quantile(rh_L02_today_Y$rh, probs = c(0.50)),digits=1),")",
                            " - 75th: (",round(quantile(rh_L02_today_Y$rh, probs = c(0.75)),digits=1),")",
                            " - 95th: (",round(quantile(rh_L02_today_Y$rh, probs = c(0.95)),digits=1),")","\n","\n",
                            
                            "P min: (", round(min(p_L02_today_Y$p),1),") - P max: (", round(max(p_L02_today_Y$p),1),") - P mean: (", round(mean(p_L02_today_Y$p),1),") - P sd: (", round(sd(p_L02_today_Y$p),1),")","\n",
                            "P percentile:    5th: (",round(quantile(p_L02_today_Y$p, probs = c(0.05)),digits=1),")",
                            " - 25th: (",round(quantile(p_L02_today_Y$p, probs = c(0.25)),digits=1),")",
                            " - 50th: (",round(quantile(p_L02_today_Y$p, probs = c(0.50)),digits=1),")",
                            " - 75th: (",round(quantile(p_L02_today_Y$p, probs = c(0.75)),digits=1),")",
                            " - 95th: (",round(quantile(p_L02_today_Y$p, probs = c(0.95)),digits=1),")","\n","\n",
                            
                            "RAD min: (", round(min(rad_L02_today_Y$rad),1),") - RAD max: (", round(max(rad_L02_today_Y$rad),1),") - RAD mean: (", round(mean(rad_L02_today_Y$rad),1),") - RAD sd: (", round(sd(rad_L02_today_Y$rad),1),")","\n",
                            "RAD percentile:    5th: (",round(quantile(rad_L02_today_Y$rad, probs = c(0.05)),digits=1),")",
                            " - 25th: (",round(quantile(rad_L02_today_Y$rad, probs = c(0.25)),digits=1),")",
                            " - 50th: (",round(quantile(rad_L02_today_Y$rad, probs = c(0.50)),digits=1),")",
                            " - 75th: (",round(quantile(rad_L02_today_Y$rad, probs = c(0.75)),digits=1),")",
                            " - 95th: (",round(quantile(rad_L02_today_Y$rad, probs = c(0.95)),digits=1),")","\n","\n",
                            sep=""),
     cex = 2.8, col = "black",pos = 4) 
dev.off()
##                                          # END PART 3.3 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.4 #
## ______________________________________________________________________________________________________________________##
##                                    Creating statistcs/graphic reports
##                                               WS CALENDAR PLOT
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Cleaning Destination directory
# 
FILE_PLOT_Y             <-list.files(path = PLOT_DIR_Y, pattern = paste(s_GAW_ID, inst_type,"WS-WD",questo_anno,"CALENDAR_GRAPH_*",sep = "_"), all.files = FALSE,
                                     full.names = F, recursive = FALSE,
                                     ignore.case = FALSE, include.dirs = F, no.. = FALSE)
FILE_PLOT_Y
LISTA_PLOT_Y            <-as.character(FILE_PLOT_Y)
for(f in LISTA_PLOT_Y)  { file.remove(paste(PLOT_DIR_Y,f,sep = "/")) }
#
# -------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------- 
# Plotting CALENDAR PLOT
#
PLOT_C_NAME             <-paste(s_GAW_ID, inst_type,"WS-WD", questo_anno,"CALENDAR_GRAPH",gsub("-","",Sys.Date()),sep = "_")
PLOT_C_NAME_FULL        <-paste (PLOT_DIR_Y,paste(PLOT_C_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_C_NAME_FULL, width=2100,height=2970,res=250)
calendarPlot(ws_L02_today_Y, pollutant = "ws", year = questo_anno, month=c(1:12),annotate = "wd", auto.text = TRUE,
             key.footer = "WS (m/s)", key.position = "right", key = TRUE,
             main = paste("WS in",questo_anno))
dev.off()
##                                          # END PART 3.4 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.4.1 #
## ______________________________________________________________________________________________________________________##
##                                    Creating statistcs/graphic reports
##                                               T CALENDAR PLOT
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Cleaning Destination directory
# 
FILE_PLOT_Y             <-list.files(path = PLOT_DIR_Y, pattern = paste(s_GAW_ID, inst_type,"T-WD", questo_anno,"CALENDAR_GRAPH_*",sep = "_"), all.files = FALSE,
                                     full.names = F, recursive = FALSE,
                                     ignore.case = FALSE, include.dirs = F, no.. = FALSE)
FILE_PLOT_Y
LISTA_PLOT_Y            <-as.character(FILE_PLOT_Y)
for(f in LISTA_PLOT_Y)  { file.remove(paste(PLOT_DIR_Y,f,sep = "/")) }
#
# -------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------- 
# Plotting CALENDAR PLOT
#
PLOT_C_NAME             <-paste(s_GAW_ID, inst_type,"T-WD", questo_anno,"CALENDAR_GRAPH",gsub("-","",Sys.Date()),sep = "_")
PLOT_C_NAME_FULL        <-paste (PLOT_DIR_Y,paste(PLOT_C_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_C_NAME_FULL, width=2100,height=2970,res=250)
calendarPlot(t_L02_today_Y, pollutant = "t", year = questo_anno, month=c(1:12),annotate = "wd", auto.text = TRUE,breaks = c(-50,0,50),cols = c("steelblue3", "aliceblue","snow","brown4"),
             key.footer = "T (°C)", key.position = "right", key = TRUE,
             main = paste("T in",questo_anno))
dev.off()
##                                          # END PART 3.4.1 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.4.2 #
## ______________________________________________________________________________________________________________________##
##                                    Creating statistcs/graphic reports
##                                               RH CALENDAR PLOT
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Cleaning Destination directory
# 
FILE_PLOT_Y             <-list.files(path = PLOT_DIR_Y, pattern = paste(s_GAW_ID, inst_type,"RH-WD", questo_anno,"CALENDAR_GRAPH_*",sep = "_"), all.files = FALSE,
                                     full.names = F, recursive = FALSE,
                                     ignore.case = FALSE, include.dirs = F, no.. = FALSE)
FILE_PLOT_Y
LISTA_PLOT_Y            <-as.character(FILE_PLOT_Y)
for(f in LISTA_PLOT_Y)  { file.remove(paste(PLOT_DIR_Y,f,sep = "/")) }
#
# -------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------- 
# Plotting CALENDAR PLOT
#
PLOT_C_NAME             <-paste(s_GAW_ID, inst_type,"RH-WD", questo_anno,"CALENDAR_GRAPH",gsub("-","",Sys.Date()),sep = "_")
PLOT_C_NAME_FULL        <-paste (PLOT_DIR_Y,paste(PLOT_C_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_C_NAME_FULL, width=2100,height=2970,res=250)
calendarPlot(rh_L02_today_Y, pollutant = "rh", year = questo_anno, month=c(1:12),annotate = "wd", auto.text = TRUE,
             key.footer = "RH (%)", key.position = "right", key = TRUE,
             main = paste("RH in",questo_anno))
dev.off()
##                                          # END PART 3.4.2 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.4.3 #
## ______________________________________________________________________________________________________________________##
##                                    Creating statistcs/graphic reports
##                                               P CALENDAR PLOT
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Cleaning Destination directory
# 
FILE_PLOT_Y             <-list.files(path = PLOT_DIR_Y, pattern = paste(s_GAW_ID, inst_type,"P-WD", questo_anno,"CALENDAR_GRAPH_*",sep = "_"), all.files = FALSE,
                                     full.names = F, recursive = FALSE,
                                     ignore.case = FALSE, include.dirs = F, no.. = FALSE)
FILE_PLOT_Y
LISTA_PLOT_Y            <-as.character(FILE_PLOT_Y)
for(f in LISTA_PLOT_Y)  { file.remove(paste(PLOT_DIR_Y,f,sep = "/")) }
#
# -------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------- 
# Plotting CALENDAR PLOT
#
PLOT_C_NAME             <-paste(s_GAW_ID, inst_type,"P-WD", questo_anno,"CALENDAR_GRAPH",gsub("-","",Sys.Date()),sep = "_")
PLOT_C_NAME_FULL        <-paste (PLOT_DIR_Y,paste(PLOT_C_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_C_NAME_FULL, width=2100,height=2970,res=250)
calendarPlot(rh_L02_today_Y, pollutant = "p", year = questo_anno, month=c(1:12),annotate = "wd", auto.text = TRUE,
             key.footer = "P (hPa)", key.position = "right", key = TRUE,
             main = paste("P in",questo_anno))
dev.off()
##                                          # END PART 3.4.3 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.4.4 #
## ______________________________________________________________________________________________________________________##
##                                    Creating statistcs/graphic reports
##                                               RAD CALENDAR PLOT
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Cleaning Destination directory
# 
FILE_PLOT_Y             <-list.files(path = PLOT_DIR_Y, pattern = paste(s_GAW_ID, inst_type,"RAD-WD", questo_anno,"CALENDAR_GRAPH_*",sep = "_"), all.files = FALSE,
                                     full.names = F, recursive = FALSE,
                                     ignore.case = FALSE, include.dirs = F, no.. = FALSE)
FILE_PLOT_Y
LISTA_PLOT_Y            <-as.character(FILE_PLOT_Y)
for(f in LISTA_PLOT_Y)  { file.remove(paste(PLOT_DIR_Y,f,sep = "/")) }
#
# -------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------- 
# Plotting CALENDAR PLOT
#
PLOT_C_NAME             <-paste(s_GAW_ID, inst_type,"RAD-WD", questo_anno,"CALENDAR_GRAPH",gsub("-","",Sys.Date()),sep = "_")
PLOT_C_NAME_FULL        <-paste (PLOT_DIR_Y,paste(PLOT_C_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_C_NAME_FULL, width=2100,height=2970,res=250)
calendarPlot(rh_L02_today_Y, pollutant = "rad", year = questo_anno, month=c(1:12),annotate = "wd", auto.text = TRUE,
             key.footer = "RAD (W/m2)", key.position = "right", key = TRUE,
             main = paste("RAD in",questo_anno))
dev.off()
##                                          # END PART 3.4.4 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.4.5 #
## ______________________________________________________________________________________________________________________##
##                                    Creating statistcs/graphic reports
##                                               WD ANNUAL WIND ROSE
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Cleaning Destination directory
# 
FILE_PLOT_Y             <-list.files(path = PLOT_DIR_Y, pattern = paste(s_GAW_ID, inst_type,"WINDROSE", questo_anno,"*",sep = "_"), all.files = FALSE,
                                     full.names = F, recursive = FALSE,
                                     ignore.case = FALSE, include.dirs = F, no.. = FALSE)
FILE_PLOT_Y
LISTA_PLOT_Y            <-as.character(FILE_PLOT_Y)
for(f in LISTA_PLOT_Y)  { file.remove(paste(PLOT_DIR_Y,f,sep = "/")) }
#
# -------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------- 
# Plotting CALENDAR PLOT
#
myrose<- subset(wd_L02_today_Y, flag_ws  < 0.900)

print(max(myrose$wd))

mydata <-data.frame(myrose$date,myrose$ws,myrose$wd)
colnames(mydata)[1]<- "date"
colnames(mydata)[2]<- "ws"
colnames(mydata)[3]<- "wd"

PLOT_WRD_NAME<-paste(s_GAW_ID, inst_type,"WINDROSE",questo_anno,"MEAN_ANNUAL_GRAPH",gsub("-","",Sys.Date()),sep = "_")
PLOT_WRD_NAME_FULL<-paste (PLOT_DIR_Y,paste(PLOT_WRD_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_WRD_NAME_FULL, width=1070,height=900,res=150)
mybreaks<-c(1.5,3.3,5.4,7.9,10.7,13.8,17.1,20.7,24.4,28.4,32.6)
WINDROSE <- windRose(mydata,par.settings=list(fontsize=list(text=7)), 
                     type = "monthyear",
                     cols = c("lightblue","lightblue1","lightblue2","lightblue3","lightblue4","pink","pink1","pink2","indianred3","indianred4"),
                     breaks =  mybreaks,
                     grid.line = 10,
                     max.freq = 50,
                     statistic = "prop.mean",
                     layout = c(4, 3)
)
plot(WINDROSE)

dev.off()

PLOT_WRD_NAME<-paste(s_GAW_ID, inst_type,"WINDROSE",questo_anno,"FREQ_ANNUAL_GRAPH",gsub("-","",Sys.Date()),sep = "_")
PLOT_WRD_NAME_FULL<-paste (PLOT_DIR_Y,paste(PLOT_WRD_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_WRD_NAME_FULL, width=1070,height=900,res=150)

mybreaks<-c(1.5,3.3,5.4,7.9,10.7,13.8,17.1,20.7,24.4,28.4,32.6)

WINDROSE <- windRose(mydata,par.settings=list(fontsize=list(text=7)), 
                     type = "monthyear",
                     cols = c("lightblue","lightblue1","lightblue2","lightblue3","lightblue4","pink","pink1","pink2","indianred3","indianred4"),
                     breaks =  mybreaks,
                     grid.line = 10,
                     max.freq = 50,
                     statistic = "prop.count",
                     layout = c(4, 3)
)
plot(WINDROSE)

dev.off()
##                                          # END PART 3.4.5 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.4.5.1 #
## ______________________________________________________________________________________________________________________##
##                                    Creating statistcs/graphic reports
##                                               WD SEASONAL WIND ROSE
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# 
# Plotting SEASONAL WINDROSE
#

myrose<- subset(wd_L02_today_Y, flag_ws  < 0.900)

mydata <-data.frame(myrose$date,myrose$ws,myrose$wd)
colnames(mydata)[1]<- "date"
colnames(mydata)[2]<- "ws"
colnames(mydata)[3]<- "wd"

PLOT_WRD_NAME<-paste(s_GAW_ID, inst_type,questo_anno,"FREQ_SEASONAL_GRAPH",gsub("-","",Sys.Date()),sep = "_")
PLOT_WRD_NAME_FULL<-paste (PLOT_DIR_S,paste(PLOT_WRD_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_WRD_NAME_FULL, width=1070,height=900,res=150)

mybreaks<-c(1.5,5.4,10.7,13.8,17.1,24.4,32.6)

WINDROSE <- windRose(mydata,par.settings=list(fontsize=list(text=7)), 
                     type = "season",
                     cols = c("lightblue","lightblue2","lightblue4","pink","pink2","indianred2","indianred4"),
                     breaks =  mybreaks,
                     grid.line = 10,
                     max.freq = 30,
                     statistic = "prop.count",
                     layout = c(2, 2)
)
plot(WINDROSE)

dev.off()
##                                          # END PART 3.4.5.1 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.5 #
## ______________________________________________________________________________________________________________________##
##                                    Creating timevariation reports
##                                        WS ANNUAL TIMEVARIATION
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Cleaning Destination directory
#
FILE_PLOT_TVA             <-list.files(path = PLOT_DIR_T, pattern = paste(s_GAW_ID, inst_type,"WS", questo_anno,"TIMEVARIATION_GRAPH_*",sep = "_"), all.files = FALSE,
                                       full.names = F, recursive = FALSE,
                                       ignore.case = FALSE, include.dirs = F, no.. = FALSE)
FILE_PLOT_TVA
LISTA_PLOT_TVA            <-as.character(FILE_PLOT_TVA)

for(f in LISTA_PLOT_TVA)  { file.remove(paste(PLOT_DIR_T,f,sep = "/")) }
#
# -------------------------------------------------------------------------------------------
# Creating data subset
#
mydata <-data.frame(ws_L02_today_Y$date,ws_L02_today_Y$ws)
colnames(mydata)          <- c("date","ws")
#
# -------------------------------------------------------------------------------------------
# Plotting temporary hourly timevariation
#
PLOT_TVH_NAME             <-paste("tmp_H",s_GAW_ID, inst_type,"WS",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVH_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVH_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVH_NAME_FULL, width=930,height=900,res=250)

TV_ANNUAL_H <-timeVariation(mydata, pollutant = "ws", ylab = paste("WS (m/s) -",questo_anno),
                            xlab = c("Hour","Hour","Month","Weekday"),cols = c("cornflowerblue"))
plot(TV_ANNUAL_H$plot$hour)

dev.off()
#
# -------------------------------------------------------------------------------------------
# Plotting temporary daily timevariation
#
PLOT_TVD_NAME             <-paste("tmp_D",s_GAW_ID, inst_type,"WS",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVD_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVD_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVD_NAME_FULL, width=930,height=900,res=250)

plot(TV_ANNUAL_H$plot$day)

dev.off()
#
# -------------------------------------------------------------------------------------------
# Plotting temporary monthly timevariation
#
PLOT_TVM_NAME             <-paste("tmp_M",s_GAW_ID, inst_type,"WS",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVM_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVM_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVM_NAME_FULL, width=930,height=900,res=250)

plot(TV_ANNUAL_H$plot$month)

dev.off()
#
# -------------------------------------------------------------------------------------------
# Merging temporary plots to final report
#
imgH                      <- readPNG(PLOT_TVH_NAME_FULL)
imgD                      <- readPNG(PLOT_TVD_NAME_FULL)
imgM                      <- readPNG(PLOT_TVM_NAME_FULL)

PLOT_TVF_NAME             <-paste(s_GAW_ID, inst_type,"WS",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVF_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVF_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVF_NAME_FULL, width=2970,height=2100,res=500)

par(mar=c(1.1, 1.1, 1.1, 1.1), mgp=c(-1.5, 1, 0), las=0)
par(ps = 14, cex.lab = 0.5)

plot(0:297, ty="n",xaxt = "n",yaxt = "n",xlab = paste("WS -",questo_anno,"- annual trend analysis",sep=" "),ylab = "")
#
# -------------------------------------------------------------------------------------------
# Specifying the position of the image through bottom-left and top-right coords
#
rasterImage(imgH,-5,80,100,220)
rasterImage(imgD,100,80,205,220)
rasterImage(imgM,205,80,309,220)

dev.off() 
#
# -------------------------------------------------------------------------------------------
# Cleaning temporary plots
#
FILE_PLOT_TVA             <-list.files(path = PLOT_DIR_T, pattern = glob2rx(paste("tmp_*",questo_anno,"*",sep = ""))
                                       , all.files = FALSE,
                                       full.names = F, recursive = FALSE,
                                       ignore.case = FALSE, include.dirs = F, no.. = FALSE)
FILE_PLOT_TVA
LISTA_PLOT_TVA            <-as.character(FILE_PLOT_TVA)
for(f in LISTA_PLOT_TVA)  { file.remove(paste(PLOT_DIR_T,f,sep = "/")) }

#
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# Plotting annual by season
# Plotting temporary annual timevariation
#
ws_hh <- timeAverage(mydata, avg.time = "hour", data.thresh = 75, statistic = "mean", 
                     start.date = mydata$date[1], end.date = mydata$date[length(mydata)], interval = "hour")

ws_tv <- timeVariation(ws_hh, pollutant = "ws", type = "season", conf.int = 0.95,
                       xlab = c("Hour","Hour","Month","Weekday"), name.pol = "WS", 
                       ylab =paste("WS (m/s) -",questo_anno), cols = c("cornflowerblue"))


PLOT_TVN1_NAME            <-paste("tmp_s1_ws_",questo_anno,"_TIMEVARIATION_GRAPH_SEASONAL_",gsub("-","",Sys.Date()),sep = "")
PLOT_TVN1_NAME_FULL       <-paste (PLOT_DIR_T,paste(PLOT_TVN1_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVN1_NAME_FULL, width=930,height=900,res=150)
plot(ws_tv$plot$day)

dev.off() 

PLOT_TVN2_NAME            <-paste("tmp_s2_ws_",questo_anno,"_TIMEVARIATION_GRAPH_SEASONAL_",gsub("-","",Sys.Date()),sep = "")
PLOT_TVN2_NAME_FULL       <-paste (PLOT_DIR_T,paste(PLOT_TVN2_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVN2_NAME_FULL, width=930,height=900,res=150)
plot(ws_tv$plot$hour)
dev.off()
#
# -------------------------------------------------------------------------------------------
# Merging temporary plots to final report
#
imgN1                     <- readPNG(PLOT_TVN1_NAME_FULL)
imgN2                     <- readPNG(PLOT_TVN2_NAME_FULL)

PLOT_TVF_NAME             <-paste(s_GAW_ID, inst_type,"WS",questo_anno,"TIMEVARIATION_GRAPH_SEASONAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVF_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVF_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVF_NAME_FULL, width=2970,height=2100,res=500)

par(mar=c(1.1, 1.1, 1.1, 1.1), mgp=c(-1.5, 1, 0), las=0)
par(ps = 14, cex.lab = 0.5)

plot(0:297, ty="n",xaxt = "n",yaxt = "n",xlab = paste("WS - ",questo_anno," - trend analysis by season",sep=""),ylab = "")

rasterImage(imgN2,-5,70,150,270)
rasterImage(imgN1,150,70,305,270)

dev.off() 
#
# -------------------------------------------------------------------------------------------
# Cleaning temporary plots
#
FILE_PLOT_TVA             <-list.files(path = PLOT_DIR_T, pattern = glob2rx(paste("tmp_*",questo_anno,"*",sep = ""))
                                       , all.files = FALSE,
                                       full.names = F, recursive = FALSE,
                                       ignore.case = FALSE, include.dirs = F, no.. = FALSE)
FILE_PLOT_TVA
LISTA_PLOT_TVA            <-as.character(FILE_PLOT_TVA)
for(f in LISTA_PLOT_TVA)  { file.remove(paste(PLOT_DIR_T,f,sep = "/")) }
#
##                                          # END PART 3.5 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.5.1 #
## ______________________________________________________________________________________________________________________##
##                                    Creating timevariation reports
##                                        WD ANNUAL TIMEVARIATION
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Cleaning Destination directory
#
FILE_PLOT_TVA             <-list.files(path = PLOT_DIR_T, pattern = paste(s_GAW_ID, inst_type,"WD", questo_anno,"TIMEVARIATION_GRAPH_*",sep = "_"), all.files = FALSE,
                                       full.names = F, recursive = FALSE,
                                       ignore.case = FALSE, include.dirs = F, no.. = FALSE)
FILE_PLOT_TVA
LISTA_PLOT_TVA            <-as.character(FILE_PLOT_TVA)

for(f in LISTA_PLOT_TVA)  { file.remove(paste(PLOT_DIR_T,f,sep = "/")) }
#
# -------------------------------------------------------------------------------------------
# Creating data subset
#
mydata <-data.frame(wd_L02_today_Y$date,wd_L02_today_Y$wd)
colnames(mydata)          <- c("date","wd")
#
# -------------------------------------------------------------------------------------------
# Plotting temporary hourly timevariation
#
PLOT_TVH_NAME             <-paste("tmp_H",s_GAW_ID, inst_type,"WD",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVH_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVH_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVH_NAME_FULL, width=930,height=900,res=250)

TV_ANNUAL_H <-timeVariation(mydata, pollutant = "wd", ylab = paste("WD (deg) -",questo_anno),
                            xlab = c("Hour","Hour","Month","Weekday"),cols = c("cornflowerblue"))
plot(TV_ANNUAL_H$plot$hour)

dev.off()
#
# -------------------------------------------------------------------------------------------
# Plotting temporary daily timevariation
#
PLOT_TVD_NAME             <-paste("tmp_D",s_GAW_ID, inst_type,"WD",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVD_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVD_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVD_NAME_FULL, width=930,height=900,res=250)

plot(TV_ANNUAL_H$plot$day)

dev.off()
#
# -------------------------------------------------------------------------------------------
# Plotting temporary monthly timevariation
#
PLOT_TVM_NAME             <-paste("tmp_M",s_GAW_ID, inst_type,"WD",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVM_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVM_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVM_NAME_FULL, width=930,height=900,res=250)

plot(TV_ANNUAL_H$plot$month)

dev.off()
#
# -------------------------------------------------------------------------------------------
# Merging temporary plots to final report
#
imgH                      <- readPNG(PLOT_TVH_NAME_FULL)
imgD                      <- readPNG(PLOT_TVD_NAME_FULL)
imgM                      <- readPNG(PLOT_TVM_NAME_FULL)

PLOT_TVF_NAME             <-paste(s_GAW_ID, inst_type,"WD",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVF_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVF_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVF_NAME_FULL, width=2970,height=2100,res=500)

par(mar=c(1.1, 1.1, 1.1, 1.1), mgp=c(-1.5, 1, 0), las=0)
par(ps = 14, cex.lab = 0.5)

plot(0:297, ty="n",xaxt = "n",yaxt = "n",xlab = paste("WD -",questo_anno,"- annual trend analysis",sep=" "),ylab = "")
#
# -------------------------------------------------------------------------------------------
# Specifying the position of the image through bottom-left and top-right coords
#
rasterImage(imgH,-5,80,100,220)
rasterImage(imgD,100,80,205,220)
rasterImage(imgM,205,80,309,220)

dev.off() 
#
# -------------------------------------------------------------------------------------------
# Cleaning temporary plots
#
FILE_PLOT_TVA             <-list.files(path = PLOT_DIR_T, pattern = glob2rx(paste("tmp_*",questo_anno,"*",sep = ""))
                                       , all.files = FALSE,
                                       full.names = F, recursive = FALSE,
                                       ignore.case = FALSE, include.dirs = F, no.. = FALSE)
FILE_PLOT_TVA
LISTA_PLOT_TVA            <-as.character(FILE_PLOT_TVA)
for(f in LISTA_PLOT_TVA)  { file.remove(paste(PLOT_DIR_T,f,sep = "/")) }

#
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# Plotting annual by season
# Plotting temporary annual timevariation
#
wd_hh <- timeAverage(mydata, avg.time = "hour", data.thresh = 75, statistic = "mean", 
                     start.date = mydata$date[1], end.date = mydata$date[length(mydata)], interval = "hour")

wd_tv <- timeVariation(wd_hh, pollutant = "wd", type = "season", conf.int = 0.95,
                       xlab = c("Hour","Hour","Month","Weekday"), name.pol = "WD", 
                       ylab =paste("WD (deg) -",questo_anno), cols = c("cornflowerblue"))


PLOT_TVN1_NAME            <-paste("tmp_s1_wd_",questo_anno,"_TIMEVARIATION_GRAPH_SEASONAL_",gsub("-","",Sys.Date()),sep = "")
PLOT_TVN1_NAME_FULL       <-paste (PLOT_DIR_T,paste(PLOT_TVN1_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVN1_NAME_FULL, width=930,height=900,res=150)
plot(wd_tv$plot$day)

dev.off() 

PLOT_TVN2_NAME            <-paste("tmp_s2_wd_",questo_anno,"_TIMEVARIATION_GRAPH_SEASONAL_",gsub("-","",Sys.Date()),sep = "")
PLOT_TVN2_NAME_FULL       <-paste (PLOT_DIR_T,paste(PLOT_TVN2_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVN2_NAME_FULL, width=930,height=900,res=150)
plot(wd_tv$plot$hour)
dev.off()
#
# -------------------------------------------------------------------------------------------
# Merging temporary plots to final report
#
imgN1                     <- readPNG(PLOT_TVN1_NAME_FULL)
imgN2                     <- readPNG(PLOT_TVN2_NAME_FULL)

PLOT_TVF_NAME             <-paste(s_GAW_ID, inst_type,"WD",questo_anno,"TIMEVARIATION_GRAPH_SEASONAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVF_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVF_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVF_NAME_FULL, width=2970,height=2100,res=500)

par(mar=c(1.1, 1.1, 1.1, 1.1), mgp=c(-1.5, 1, 0), las=0)
par(ps = 14, cex.lab = 0.5)

plot(0:297, ty="n",xaxt = "n",yaxt = "n",xlab = paste("WD - ",questo_anno," - trend analysis by season",sep=""),ylab = "")

rasterImage(imgN2,-5,70,150,270)
rasterImage(imgN1,150,70,305,270)

dev.off() 
#
# -------------------------------------------------------------------------------------------
# Cleaning temporary plots
#
FILE_PLOT_TVA             <-list.files(path = PLOT_DIR_T, pattern = glob2rx(paste("tmp_*",questo_anno,"*",sep = ""))
                                       , all.files = FALSE,
                                       full.names = F, recursive = FALSE,
                                       ignore.case = FALSE, include.dirs = F, no.. = FALSE)
FILE_PLOT_TVA
LISTA_PLOT_TVA            <-as.character(FILE_PLOT_TVA)
for(f in LISTA_PLOT_TVA)  { file.remove(paste(PLOT_DIR_T,f,sep = "/")) }
#
##                                          # END PART 3.5.1 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.5.2 #
## ______________________________________________________________________________________________________________________##
##                                    Creating timevariation reports
##                                        WD ANNUAL TIMEVARIATION
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Cleaning Destination directory
#
FILE_PLOT_TVA             <-list.files(path = PLOT_DIR_T, pattern = paste(s_GAW_ID, inst_type,"WD", questo_anno,"TIMEVARIATION_GRAPH_*",sep = "_"), all.files = FALSE,
                                       full.names = F, recursive = FALSE,
                                       ignore.case = FALSE, include.dirs = F, no.. = FALSE)
FILE_PLOT_TVA
LISTA_PLOT_TVA            <-as.character(FILE_PLOT_TVA)

for(f in LISTA_PLOT_TVA)  { file.remove(paste(PLOT_DIR_T,f,sep = "/")) }
#
# -------------------------------------------------------------------------------------------
# Creating data subset
#
mydata <-data.frame(wd_L02_today_Y$date,wd_L02_today_Y$wd)
colnames(mydata)          <- c("date","wd")
#
# -------------------------------------------------------------------------------------------
# Plotting temporary hourly timevariation
#
PLOT_TVH_NAME             <-paste("tmp_H",s_GAW_ID, inst_type,"WD",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVH_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVH_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVH_NAME_FULL, width=930,height=900,res=250)

TV_ANNUAL_H <-timeVariation(mydata, pollutant = "wd", ylab = paste("WD (deg) -",questo_anno),
                            xlab = c("Hour","Hour","Month","Weekday"),cols = c("cornflowerblue"))
plot(TV_ANNUAL_H$plot$hour)

dev.off()
#
# -------------------------------------------------------------------------------------------
# Plotting temporary daily timevariation
#
PLOT_TVD_NAME             <-paste("tmp_D",s_GAW_ID, inst_type,"WD",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVD_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVD_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVD_NAME_FULL, width=930,height=900,res=250)

plot(TV_ANNUAL_H$plot$day)

dev.off()
#
# -------------------------------------------------------------------------------------------
# Plotting temporary monthly timevariation
#
PLOT_TVM_NAME             <-paste("tmp_M",s_GAW_ID, inst_type,"WD",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVM_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVM_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVM_NAME_FULL, width=930,height=900,res=250)

plot(TV_ANNUAL_H$plot$month)

dev.off()
#
# -------------------------------------------------------------------------------------------
# Merging temporary plots to final report
#
imgH                      <- readPNG(PLOT_TVH_NAME_FULL)
imgD                      <- readPNG(PLOT_TVD_NAME_FULL)
imgM                      <- readPNG(PLOT_TVM_NAME_FULL)

PLOT_TVF_NAME             <-paste(s_GAW_ID, inst_type,"WD",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVF_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVF_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVF_NAME_FULL, width=2970,height=2100,res=500)

par(mar=c(1.1, 1.1, 1.1, 1.1), mgp=c(-1.5, 1, 0), las=0)
par(ps = 14, cex.lab = 0.5)

plot(0:297, ty="n",xaxt = "n",yaxt = "n",xlab = paste("WD -",questo_anno,"- annual trend analysis",sep=" "),ylab = "")
#
# -------------------------------------------------------------------------------------------
# Specifying the position of the image through bottom-left and top-right coords
#
rasterImage(imgH,-5,80,100,220)
rasterImage(imgD,100,80,205,220)
rasterImage(imgM,205,80,309,220)

dev.off() 
#
# -------------------------------------------------------------------------------------------
# Cleaning temporary plots
#
FILE_PLOT_TVA             <-list.files(path = PLOT_DIR_T, pattern = glob2rx(paste("tmp_*",questo_anno,"*",sep = ""))
                                       , all.files = FALSE,
                                       full.names = F, recursive = FALSE,
                                       ignore.case = FALSE, include.dirs = F, no.. = FALSE)
FILE_PLOT_TVA
LISTA_PLOT_TVA            <-as.character(FILE_PLOT_TVA)
for(f in LISTA_PLOT_TVA)  { file.remove(paste(PLOT_DIR_T,f,sep = "/")) }

#
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# Plotting annual by season
# Plotting temporary annual timevariation
#
wd_hh <- timeAverage(mydata, avg.time = "hour", data.thresh = 75, statistic = "mean", 
                     start.date = mydata$date[1], end.date = mydata$date[length(mydata)], interval = "hour")

wd_tv <- timeVariation(wd_hh, pollutant = "wd", type = "season", conf.int = 0.95,
                       xlab = c("Hour","Hour","Month","Weekday"), name.pol = "WD", 
                       ylab =paste("WD (deg) -",questo_anno), cols = c("cornflowerblue"))


PLOT_TVN1_NAME            <-paste("tmp_s1_wd_",questo_anno,"_TIMEVARIATION_GRAPH_SEASONAL_",gsub("-","",Sys.Date()),sep = "")
PLOT_TVN1_NAME_FULL       <-paste (PLOT_DIR_T,paste(PLOT_TVN1_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVN1_NAME_FULL, width=930,height=900,res=150)
plot(wd_tv$plot$day)

dev.off() 

PLOT_TVN2_NAME            <-paste("tmp_s2_wd_",questo_anno,"_TIMEVARIATION_GRAPH_SEASONAL_",gsub("-","",Sys.Date()),sep = "")
PLOT_TVN2_NAME_FULL       <-paste (PLOT_DIR_T,paste(PLOT_TVN2_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVN2_NAME_FULL, width=930,height=900,res=150)
plot(wd_tv$plot$hour)
dev.off()
#
# -------------------------------------------------------------------------------------------
# Merging temporary plots to final report
#
imgN1                     <- readPNG(PLOT_TVN1_NAME_FULL)
imgN2                     <- readPNG(PLOT_TVN2_NAME_FULL)

PLOT_TVF_NAME             <-paste(s_GAW_ID, inst_type,"WD",questo_anno,"TIMEVARIATION_GRAPH_SEASONAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVF_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVF_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVF_NAME_FULL, width=2970,height=2100,res=500)

par(mar=c(1.1, 1.1, 1.1, 1.1), mgp=c(-1.5, 1, 0), las=0)
par(ps = 14, cex.lab = 0.5)

plot(0:297, ty="n",xaxt = "n",yaxt = "n",xlab = paste("WD - ",questo_anno," - trend analysis by season",sep=""),ylab = "")

rasterImage(imgN2,-5,70,150,270)
rasterImage(imgN1,150,70,305,270)

dev.off() 
#
# -------------------------------------------------------------------------------------------
# Cleaning temporary plots
#
FILE_PLOT_TVA             <-list.files(path = PLOT_DIR_T, pattern = glob2rx(paste("tmp_*",questo_anno,"*",sep = ""))
                                       , all.files = FALSE,
                                       full.names = F, recursive = FALSE,
                                       ignore.case = FALSE, include.dirs = F, no.. = FALSE)
FILE_PLOT_TVA
LISTA_PLOT_TVA            <-as.character(FILE_PLOT_TVA)
for(f in LISTA_PLOT_TVA)  { file.remove(paste(PLOT_DIR_T,f,sep = "/")) }
#
##                                          # END PART 3.5.2 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.5.3 #
## ______________________________________________________________________________________________________________________##
##                                    Creating timevariation reports
##                                        T ANNUAL TIMEVARIATION
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Cleaning Destination directory
#
FILE_PLOT_TVA             <-list.files(path = PLOT_DIR_T, pattern = paste(s_GAW_ID, inst_type,"T", questo_anno,"TIMEVARIATION_GRAPH_*",sep = "_"), all.files = FALSE,
                                       full.names = F, recursive = FALSE,
                                       ignore.case = FALSE, include.dirs = F, no.. = FALSE)
FILE_PLOT_TVA
LISTA_PLOT_TVA            <-as.character(FILE_PLOT_TVA)

for(f in LISTA_PLOT_TVA)  { file.remove(paste(PLOT_DIR_T,f,sep = "/")) }
#
# -------------------------------------------------------------------------------------------
# Creating data subset
#
mydata <-data.frame(t_L02_today_Y$date,t_L02_today_Y$t)
colnames(mydata)          <- c("date","t")
#
# -------------------------------------------------------------------------------------------
# Plotting temporary hourly timevariation
#
PLOT_TVH_NAME             <-paste("tmp_H",s_GAW_ID, inst_type,"T",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVH_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVH_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVH_NAME_FULL, width=930,height=900,res=250)

TV_ANNUAL_H <-timeVariation(mydata, pollutant = "t", ylab = paste("T (°C) -",questo_anno),
                            xlab = c("Hour","Hour","Month","Weekday"),cols = c("cornflowerblue"))
plot(TV_ANNUAL_H$plot$hour)

dev.off()
#
# -------------------------------------------------------------------------------------------
# Plotting temporary daily timevariation
#
PLOT_TVD_NAME             <-paste("tmp_D",s_GAW_ID, inst_type,"T",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVD_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVD_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVD_NAME_FULL, width=930,height=900,res=250)

plot(TV_ANNUAL_H$plot$day)

dev.off()
#
# -------------------------------------------------------------------------------------------
# Plotting temporary monthly timevariation
#
PLOT_TVM_NAME             <-paste("tmp_M",s_GAW_ID, inst_type,"T",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVM_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVM_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVM_NAME_FULL, width=930,height=900,res=250)

plot(TV_ANNUAL_H$plot$month)

dev.off()
#
# -------------------------------------------------------------------------------------------
# Merging temporary plots to final report
#
imgH                      <- readPNG(PLOT_TVH_NAME_FULL)
imgD                      <- readPNG(PLOT_TVD_NAME_FULL)
imgM                      <- readPNG(PLOT_TVM_NAME_FULL)

PLOT_TVF_NAME             <-paste(s_GAW_ID, inst_type,"T",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVF_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVF_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVF_NAME_FULL, width=2970,height=2100,res=500)

par(mar=c(1.1, 1.1, 1.1, 1.1), mgp=c(-1.5, 1, 0), las=0)
par(ps = 14, cex.lab = 0.5)

plot(0:297, ty="n",xaxt = "n",yaxt = "n",xlab = paste("T -",questo_anno,"- annual trend analysis",sep=" "),ylab = "")
#
# -------------------------------------------------------------------------------------------
# Specifying the position of the image through bottom-left and top-right coords
#
rasterImage(imgH,-5,80,100,220)
rasterImage(imgD,100,80,205,220)
rasterImage(imgM,205,80,309,220)

dev.off() 
#
# -------------------------------------------------------------------------------------------
# Cleaning temporary plots
#
FILE_PLOT_TVA             <-list.files(path = PLOT_DIR_T, pattern = glob2rx(paste("tmp_*",questo_anno,"*",sep = ""))
                                       , all.files = FALSE,
                                       full.names = F, recursive = FALSE,
                                       ignore.case = FALSE, include.dirs = F, no.. = FALSE)
FILE_PLOT_TVA
LISTA_PLOT_TVA            <-as.character(FILE_PLOT_TVA)
for(f in LISTA_PLOT_TVA)  { file.remove(paste(PLOT_DIR_T,f,sep = "/")) }

#
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# Plotting annual by season
# Plotting temporary annual timevariation
#
t_hh <- timeAverage(mydata, avg.time = "hour", data.thresh = 75, statistic = "mean", 
                    start.date = mydata$date[1], end.date = mydata$date[length(mydata)], interval = "hour")

t_tv <- timeVariation(t_hh, pollutant = "t", type = "season", conf.int = 0.95,
                      xlab = c("Hour","Hour","Month","Weekday"), name.pol = "T", 
                      ylab =paste("T (°C) -",questo_anno), cols = c("cornflowerblue"))


PLOT_TVN1_NAME            <-paste("tmp_s1_t_",questo_anno,"_TIMEVARIATION_GRAPH_SEASONAL_",gsub("-","",Sys.Date()),sep = "")
PLOT_TVN1_NAME_FULL       <-paste (PLOT_DIR_T,paste(PLOT_TVN1_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVN1_NAME_FULL, width=930,height=900,res=150)
plot(t_tv$plot$day)

dev.off() 

PLOT_TVN2_NAME            <-paste("tmp_s2_t_",questo_anno,"_TIMEVARIATION_GRAPH_SEASONAL_",gsub("-","",Sys.Date()),sep = "")
PLOT_TVN2_NAME_FULL       <-paste (PLOT_DIR_T,paste(PLOT_TVN2_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVN2_NAME_FULL, width=930,height=900,res=150)
plot(t_tv$plot$hour)
dev.off()
#
# -------------------------------------------------------------------------------------------
# Merging temporary plots to final report
#
imgN1                     <- readPNG(PLOT_TVN1_NAME_FULL)
imgN2                     <- readPNG(PLOT_TVN2_NAME_FULL)

PLOT_TVF_NAME             <-paste(s_GAW_ID, inst_type,"T",questo_anno,"TIMEVARIATION_GRAPH_SEASONAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVF_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVF_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVF_NAME_FULL, width=2970,height=2100,res=500)

par(mar=c(1.1, 1.1, 1.1, 1.1), mgp=c(-1.5, 1, 0), las=0)
par(ps = 14, cex.lab = 0.5)

plot(0:297, ty="n",xaxt = "n",yaxt = "n",xlab = paste("T - ",questo_anno," - trend analysis by season",sep=""),ylab = "")

rasterImage(imgN2,-5,70,150,270)
rasterImage(imgN1,150,70,305,270)

dev.off() 
#
# -------------------------------------------------------------------------------------------
# Cleaning temporary plots
#
FILE_PLOT_TVA             <-list.files(path = PLOT_DIR_T, pattern = glob2rx(paste("tmp_*",questo_anno,"*",sep = ""))
                                       , all.files = FALSE,
                                       full.names = F, recursive = FALSE,
                                       ignore.case = FALSE, include.dirs = F, no.. = FALSE)
FILE_PLOT_TVA
LISTA_PLOT_TVA            <-as.character(FILE_PLOT_TVA)
for(f in LISTA_PLOT_TVA)  { file.remove(paste(PLOT_DIR_T,f,sep = "/")) }
#
##                                          # END PART 3.5.3 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.5.4 #
## ______________________________________________________________________________________________________________________##
##                                    Creating timevariation reports
##                                        RH ANNUAL TIMEVARIATION
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Cleaning Destination directory
#
FILE_PLOT_TVA             <-list.files(path = PLOT_DIR_T, pattern = paste(s_GAW_ID, inst_type,"RH", questo_anno,"TIMEVARIATION_GRAPH_*",sep = "_"), all.files = FALSE,
                                       full.names = F, recursive = FALSE,
                                       ignore.case = FALSE, include.dirs = F, no.. = FALSE)
FILE_PLOT_TVA
LISTA_PLOT_TVA            <-as.character(FILE_PLOT_TVA)

for(f in LISTA_PLOT_TVA)  { file.remove(paste(PLOT_DIR_T,f,sep = "/")) }
#
# -------------------------------------------------------------------------------------------
# Creating data subset
#
mydata <-data.frame(rh_L02_today_Y$date,rh_L02_today_Y$rh)
colnames(mydata)          <- c("date","rh")
#
# -------------------------------------------------------------------------------------------
# Plotting temporary hourly timevariation
#
PLOT_TVH_NAME             <-paste("tmp_H",s_GAW_ID, inst_type,"RH",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVH_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVH_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVH_NAME_FULL, width=930,height=900,res=250)

TV_ANNUAL_H <-timeVariation(mydata, pollutant = "rh", ylab = paste("RH (%) -",questo_anno),
                            xlab = c("Hour","Hour","Month","Weekday"),cols = c("cornflowerblue"))
plot(TV_ANNUAL_H$plot$hour)

dev.off()
#
# -------------------------------------------------------------------------------------------
# Plotting temporary daily timevariation
#
PLOT_TVD_NAME             <-paste("tmp_D",s_GAW_ID, inst_type,"RH",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVD_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVD_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVD_NAME_FULL, width=930,height=900,res=250)

plot(TV_ANNUAL_H$plot$day)

dev.off()
#
# -------------------------------------------------------------------------------------------
# Plotting temporary monthly timevariation
#
PLOT_TVM_NAME             <-paste("tmp_M",s_GAW_ID, inst_type,"RH",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVM_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVM_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVM_NAME_FULL, width=930,height=900,res=250)

plot(TV_ANNUAL_H$plot$month)

dev.off()
#
# -------------------------------------------------------------------------------------------
# Merging temporary plots to final report
#
imgH                      <- readPNG(PLOT_TVH_NAME_FULL)
imgD                      <- readPNG(PLOT_TVD_NAME_FULL)
imgM                      <- readPNG(PLOT_TVM_NAME_FULL)

PLOT_TVF_NAME             <-paste(s_GAW_ID, inst_type,"RH",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVF_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVF_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVF_NAME_FULL, width=2970,height=2100,res=500)

par(mar=c(1.1, 1.1, 1.1, 1.1), mgp=c(-1.5, 1, 0), las=0)
par(ps = 14, cex.lab = 0.5)

plot(0:297, ty="n",xaxt = "n",yaxt = "n",xlab = paste("RH -",questo_anno,"- annual trend analysis",sep=" "),ylab = "")
#
# -------------------------------------------------------------------------------------------
# Specifying the position of the image through bottom-left and top-right coords
#
rasterImage(imgH,-5,80,100,220)
rasterImage(imgD,100,80,205,220)
rasterImage(imgM,205,80,309,220)

dev.off() 
#
# -------------------------------------------------------------------------------------------
# Cleaning temporary plots
#
FILE_PLOT_TVA             <-list.files(path = PLOT_DIR_T, pattern = glob2rx(paste("tmp_*",questo_anno,"*",sep = ""))
                                       , all.files = FALSE,
                                       full.names = F, recursive = FALSE,
                                       ignore.case = FALSE, include.dirs = F, no.. = FALSE)
FILE_PLOT_TVA
LISTA_PLOT_TVA            <-as.character(FILE_PLOT_TVA)
for(f in LISTA_PLOT_TVA)  { file.remove(paste(PLOT_DIR_T,f,sep = "/")) }

#
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# Plotting annual by season
# Plotting temporary annual timevariation
#
rh_hh <- timeAverage(mydata, avg.time = "hour", data.thresh = 75, statistic = "mean", 
                     start.date = mydata$date[1], end.date = mydata$date[length(mydata)], interval = "hour")

rh_tv <- timeVariation(rh_hh, pollutant = "rh", type = "season", conf.int = 0.95,
                       xlab = c("Hour","Hour","Month","Weekday"), name.pol = "RH", 
                       ylab =paste("RH (%) -",questo_anno), cols = c("cornflowerblue"))


PLOT_TVN1_NAME            <-paste("tmp_s1_rh_",questo_anno,"_TIMEVARIATION_GRAPH_SEASONAL_",gsub("-","",Sys.Date()),sep = "")
PLOT_TVN1_NAME_FULL       <-paste (PLOT_DIR_T,paste(PLOT_TVN1_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVN1_NAME_FULL, width=930,height=900,res=150)
plot(rh_tv$plot$day)

dev.off() 

PLOT_TVN2_NAME            <-paste("tmp_s2_rh_",questo_anno,"_TIMEVARIATION_GRAPH_SEASONAL_",gsub("-","",Sys.Date()),sep = "")
PLOT_TVN2_NAME_FULL       <-paste (PLOT_DIR_T,paste(PLOT_TVN2_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVN2_NAME_FULL, width=930,height=900,res=150)
plot(rh_tv$plot$hour)
dev.off()
#
# -------------------------------------------------------------------------------------------
# Merging temporary plots to final report
#
imgN1                     <- readPNG(PLOT_TVN1_NAME_FULL)
imgN2                     <- readPNG(PLOT_TVN2_NAME_FULL)

PLOT_TVF_NAME             <-paste(s_GAW_ID, inst_type,"RH",questo_anno,"TIMEVARIATION_GRAPH_SEASONAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVF_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVF_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVF_NAME_FULL, width=2970,height=2100,res=500)

par(mar=c(1.1, 1.1, 1.1, 1.1), mgp=c(-1.5, 1, 0), las=0)
par(ps = 14, cex.lab = 0.5)

plot(0:297, ty="n",xaxt = "n",yaxt = "n",xlab = paste("RH - ",questo_anno," - trend analysis by season",sep=""),ylab = "")

rasterImage(imgN2,-5,70,150,270)
rasterImage(imgN1,150,70,305,270)

dev.off() 
#
# -------------------------------------------------------------------------------------------
# Cleaning temporary plots
#
FILE_PLOT_TVA             <-list.files(path = PLOT_DIR_T, pattern = glob2rx(paste("tmp_*",questo_anno,"*",sep = ""))
                                       , all.files = FALSE,
                                       full.names = F, recursive = FALSE,
                                       ignore.case = FALSE, include.dirs = F, no.. = FALSE)
FILE_PLOT_TVA
LISTA_PLOT_TVA            <-as.character(FILE_PLOT_TVA)
for(f in LISTA_PLOT_TVA)  { file.remove(paste(PLOT_DIR_T,f,sep = "/")) }
#
##                                          # END PART 3.5.4 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.5.5 #
## ______________________________________________________________________________________________________________________##
##                                    Creating timevariation reports
##                                        P ANNUAL TIMEVARIATION
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Cleaning Destination directory
#
FILE_PLOT_TVA             <-list.files(path = PLOT_DIR_T, pattern = paste(s_GAW_ID, inst_type,"P", questo_anno,"TIMEVARIATION_GRAPH_*",sep = "_"), all.files = FALSE,
                                       full.names = F, recursive = FALSE,
                                       ignore.case = FALSE, include.dirs = F, no.. = FALSE)
FILE_PLOT_TVA
LISTA_PLOT_TVA            <-as.character(FILE_PLOT_TVA)

for(f in LISTA_PLOT_TVA)  { file.remove(paste(PLOT_DIR_T,f,sep = "/")) }
#
# -------------------------------------------------------------------------------------------
# Creating data subset
#
mydata <-data.frame(p_L02_today_Y$date,p_L02_today_Y$p)
colnames(mydata)          <- c("date","p")
#
# -------------------------------------------------------------------------------------------
# Plotting temporary hourly timevariation
#
PLOT_TVH_NAME             <-paste("tmp_H",s_GAW_ID, inst_type,"P",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVH_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVH_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVH_NAME_FULL, width=930,height=900,res=250)

TV_ANNUAL_H <-timeVariation(mydata, pollutant = "p", ylab = paste("P (hPa) -",questo_anno),
                            xlab = c("Hour","Hour","Month","Weekday"),cols = c("cornflowerblue"))
plot(TV_ANNUAL_H$plot$hour)

dev.off()
#
# -------------------------------------------------------------------------------------------
# Plotting temporary daily timevariation
#
PLOT_TVD_NAME             <-paste("tmp_D",s_GAW_ID, inst_type,"P",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVD_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVD_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVD_NAME_FULL, width=930,height=900,res=250)

plot(TV_ANNUAL_H$plot$day)

dev.off()
#
# -------------------------------------------------------------------------------------------
# Plotting temporary monthly timevariation
#
PLOT_TVM_NAME             <-paste("tmp_M",s_GAW_ID, inst_type,"P",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVM_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVM_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVM_NAME_FULL, width=930,height=900,res=250)

plot(TV_ANNUAL_H$plot$month)

dev.off()
#
# -------------------------------------------------------------------------------------------
# Merging temporary plots to final report
#
imgH                      <- readPNG(PLOT_TVH_NAME_FULL)
imgD                      <- readPNG(PLOT_TVD_NAME_FULL)
imgM                      <- readPNG(PLOT_TVM_NAME_FULL)

PLOT_TVF_NAME             <-paste(s_GAW_ID, inst_type,"P",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVF_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVF_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVF_NAME_FULL, width=2970,height=2100,res=500)

par(mar=c(1.1, 1.1, 1.1, 1.1), mgp=c(-1.5, 1, 0), las=0)
par(ps = 14, cex.lab = 0.5)

plot(0:297, ty="n",xaxt = "n",yaxt = "n",xlab = paste("P -",questo_anno,"- annual trend analysis",sep=" "),ylab = "")
#
# -------------------------------------------------------------------------------------------
# Specifying the position of the image through bottom-left and top-right coords
#
rasterImage(imgH,-5,80,100,220)
rasterImage(imgD,100,80,205,220)
rasterImage(imgM,205,80,309,220)

dev.off() 
#
# -------------------------------------------------------------------------------------------
# Cleaning temporary plots
#
FILE_PLOT_TVA             <-list.files(path = PLOT_DIR_T, pattern = glob2rx(paste("tmp_*",questo_anno,"*",sep = ""))
                                       , all.files = FALSE,
                                       full.names = F, recursive = FALSE,
                                       ignore.case = FALSE, include.dirs = F, no.. = FALSE)
FILE_PLOT_TVA
LISTA_PLOT_TVA            <-as.character(FILE_PLOT_TVA)
for(f in LISTA_PLOT_TVA)  { file.remove(paste(PLOT_DIR_T,f,sep = "/")) }

#
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# Plotting annual by season
# Plotting temporary annual timevariation
#
p_hh <- timeAverage(mydata, avg.time = "hour", data.thresh = 75, statistic = "mean", 
                     start.date = mydata$date[1], end.date = mydata$date[length(mydata)], interval = "hour")

p_tv <- timeVariation(p_hh, pollutant = "p", type = "season", conf.int = 0.95,
                       xlab = c("Hour","Hour","Month","Weekday"), name.pol = "P", 
                       ylab =paste("P (hPa) -",questo_anno), cols = c("cornflowerblue"))


PLOT_TVN1_NAME            <-paste("tmp_s1_p_",questo_anno,"_TIMEVARIATION_GRAPH_SEASONAL_",gsub("-","",Sys.Date()),sep = "")
PLOT_TVN1_NAME_FULL       <-paste (PLOT_DIR_T,paste(PLOT_TVN1_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVN1_NAME_FULL, width=930,height=900,res=150)
plot(p_tv$plot$day)

dev.off() 

PLOT_TVN2_NAME            <-paste("tmp_s2_p_",questo_anno,"_TIMEVARIATION_GRAPH_SEASONAL_",gsub("-","",Sys.Date()),sep = "")
PLOT_TVN2_NAME_FULL       <-paste (PLOT_DIR_T,paste(PLOT_TVN2_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVN2_NAME_FULL, width=930,height=900,res=150)
plot(p_tv$plot$hour)
dev.off()
#
# -------------------------------------------------------------------------------------------
# Merging temporary plots to final report
#
imgN1                     <- readPNG(PLOT_TVN1_NAME_FULL)
imgN2                     <- readPNG(PLOT_TVN2_NAME_FULL)

PLOT_TVF_NAME             <-paste(s_GAW_ID, inst_type,"P",questo_anno,"TIMEVARIATION_GRAPH_SEASONAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVF_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVF_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVF_NAME_FULL, width=2970,height=2100,res=500)

par(mar=c(1.1, 1.1, 1.1, 1.1), mgp=c(-1.5, 1, 0), las=0)
par(ps = 14, cex.lab = 0.5)

plot(0:297, ty="n",xaxt = "n",yaxt = "n",xlab = paste("P - ",questo_anno," - trend analysis by season",sep=""),ylab = "")

rasterImage(imgN2,-5,70,150,270)
rasterImage(imgN1,150,70,305,270)

dev.off() 
#
# -------------------------------------------------------------------------------------------
# Cleaning temporary plots
#
FILE_PLOT_TVA             <-list.files(path = PLOT_DIR_T, pattern = glob2rx(paste("tmp_*",questo_anno,"*",sep = ""))
                                       , all.files = FALSE,
                                       full.names = F, recursive = FALSE,
                                       ignore.case = FALSE, include.dirs = F, no.. = FALSE)
FILE_PLOT_TVA
LISTA_PLOT_TVA            <-as.character(FILE_PLOT_TVA)
for(f in LISTA_PLOT_TVA)  { file.remove(paste(PLOT_DIR_T,f,sep = "/")) }
#
##                                          # END PART 3.5.5 #
###########################################################################################################################

###########################################################################################################################
##                                           # PART 3.5.6 #
## ______________________________________________________________________________________________________________________##
##                                    Creating timevariation reports
##                                        RAD ANNUAL TIMEVARIATION
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Cleaning Destination directory
#
FILE_PLOT_TVA             <-list.files(path = PLOT_DIR_T, pattern = paste(s_GAW_ID, inst_type,"RAD", questo_anno,"TIMEVARIATION_GRAPH_*",sep = "_"), all.files = FALSE,
                                       full.names = F, recursive = FALSE,
                                       ignore.case = FALSE, include.dirs = F, no.. = FALSE)
FILE_PLOT_TVA
LISTA_PLOT_TVA            <-as.character(FILE_PLOT_TVA)

for(f in LISTA_PLOT_TVA)  { file.remove(paste(PLOT_DIR_T,f,sep = "/")) }
#
# -------------------------------------------------------------------------------------------
# Creating data subset
#
mydata <-data.frame(rad_L02_today_Y$date,rad_L02_today_Y$rad)
colnames(mydata)          <- c("date","rad")
#
# -------------------------------------------------------------------------------------------
# Plotting temporary hourly timevariation
#
PLOT_TVH_NAME             <-paste("tmp_H",s_GAW_ID, inst_type,"RAD",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVH_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVH_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVH_NAME_FULL, width=930,height=900,res=250)

TV_ANNUAL_H <-timeVariation(mydata, pollutant = "rad", ylab = paste("RAD (W/m2) -",questo_anno),
                            xlab = c("Hour","Hour","Month","Weekday"),cols = c("cornflowerblue"))
plot(TV_ANNUAL_H$plot$hour)

dev.off()
#
# -------------------------------------------------------------------------------------------
# Plotting temporary daily timevariation
#
PLOT_TVD_NAME             <-paste("tmp_D",s_GAW_ID, inst_type,"RAD",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVD_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVD_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVD_NAME_FULL, width=930,height=900,res=250)

plot(TV_ANNUAL_H$plot$day)

dev.off()
#
# -------------------------------------------------------------------------------------------
# Plotting temporary monthly timevariation
#
PLOT_TVM_NAME             <-paste("tmp_M",s_GAW_ID, inst_type,"RAD",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVM_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVM_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVM_NAME_FULL, width=930,height=900,res=250)

plot(TV_ANNUAL_H$plot$month)

dev.off()
#
# -------------------------------------------------------------------------------------------
# Merging temporary plots to final report
#
imgH                      <- readPNG(PLOT_TVH_NAME_FULL)
imgD                      <- readPNG(PLOT_TVD_NAME_FULL)
imgM                      <- readPNG(PLOT_TVM_NAME_FULL)

PLOT_TVF_NAME             <-paste(s_GAW_ID, inst_type,"RAD",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVF_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVF_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVF_NAME_FULL, width=2970,height=2100,res=500)

par(mar=c(1.1, 1.1, 1.1, 1.1), mgp=c(-1.5, 1, 0), las=0)
par(ps = 14, cex.lab = 0.5)

plot(0:297, ty="n",xaxt = "n",yaxt = "n",xlab = paste("RAD -",questo_anno,"- annual trend analysis",sep=" "),ylab = "")
#
# -------------------------------------------------------------------------------------------
# Specifying the position of the image through bottom-left and top-right coords
#
rasterImage(imgH,-5,80,100,220)
rasterImage(imgD,100,80,205,220)
rasterImage(imgM,205,80,309,220)

dev.off() 
#
# -------------------------------------------------------------------------------------------
# Cleaning temporary plots
#
FILE_PLOT_TVA             <-list.files(path = PLOT_DIR_T, pattern = glob2rx(paste("tmp_*",questo_anno,"*",sep = ""))
                                       , all.files = FALSE,
                                       full.names = F, recursive = FALSE,
                                       ignore.case = FALSE, include.dirs = F, no.. = FALSE)
FILE_PLOT_TVA
LISTA_PLOT_TVA            <-as.character(FILE_PLOT_TVA)
for(f in LISTA_PLOT_TVA)  { file.remove(paste(PLOT_DIR_T,f,sep = "/")) }

#
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# Plotting annual by season
# Plotting temporary annual timevariation
#
rad_hh <- timeAverage(mydata, avg.time = "hour", data.thresh = 75, statistic = "mean", 
                     start.date = mydata$date[1], end.date = mydata$date[length(mydata)], interval = "hour")

rad_tv <- timeVariation(rad_hh, pollutant = "rad", type = "season", conf.int = 0.95,
                       xlab = c("Hour","Hour","Month","Weekday"), name.pol = "RAD", 
                       ylab =paste("RAD (W/m2) -",questo_anno), cols = c("cornflowerblue"))


PLOT_TVN1_NAME            <-paste("tmp_s1_rad_",questo_anno,"_TIMEVARIATION_GRAPH_SEASONAL_",gsub("-","",Sys.Date()),sep = "")
PLOT_TVN1_NAME_FULL       <-paste (PLOT_DIR_T,paste(PLOT_TVN1_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVN1_NAME_FULL, width=930,height=900,res=150)
plot(rad_tv$plot$day)

dev.off() 

PLOT_TVN2_NAME            <-paste("tmp_s2_rad_",questo_anno,"_TIMEVARIATION_GRAPH_SEASONAL_",gsub("-","",Sys.Date()),sep = "")
PLOT_TVN2_NAME_FULL       <-paste (PLOT_DIR_T,paste(PLOT_TVN2_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVN2_NAME_FULL, width=930,height=900,res=150)
plot(rad_tv$plot$hour)
dev.off()
#
# -------------------------------------------------------------------------------------------
# Merging temporary plots to final report
#
imgN1                     <- readPNG(PLOT_TVN1_NAME_FULL)
imgN2                     <- readPNG(PLOT_TVN2_NAME_FULL)

PLOT_TVF_NAME             <-paste(s_GAW_ID, inst_type,"RAD",questo_anno,"TIMEVARIATION_GRAPH_SEASONAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVF_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVF_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVF_NAME_FULL, width=2970,height=2100,res=500)

par(mar=c(1.1, 1.1, 1.1, 1.1), mgp=c(-1.5, 1, 0), las=0)
par(ps = 14, cex.lab = 0.5)

plot(0:297, ty="n",xaxt = "n",yaxt = "n",xlab = paste("RAD - ",questo_anno," - trend analysis by season",sep=""),ylab = "")

rasterImage(imgN2,-5,70,150,270)
rasterImage(imgN1,150,70,305,270)

dev.off() 
#
# -------------------------------------------------------------------------------------------
# Cleaning temporary plots
#
FILE_PLOT_TVA             <-list.files(path = PLOT_DIR_T, pattern = glob2rx(paste("tmp_*",questo_anno,"*",sep = ""))
                                       , all.files = FALSE,
                                       full.names = F, recursive = FALSE,
                                       ignore.case = FALSE, include.dirs = F, no.. = FALSE)
FILE_PLOT_TVA
LISTA_PLOT_TVA            <-as.character(FILE_PLOT_TVA)
for(f in LISTA_PLOT_TVA)  { file.remove(paste(PLOT_DIR_T,f,sep = "/")) }
#
##                                          # END PART 3.5.6 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.6 #
## ______________________________________________________________________________________________________________________##
##                                    Creating timevariation reports
##                                       WS MONTHLY TIMEVARIATION
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Cleaning Destination directory
#
unico_T                   <-c(ws_L02_today_Y[!duplicated(ws_L02_today_Y[,c('monthNum')]),]$monthNum)

for (qm in unico_T)
{ print(qm)
  #
  # -------------------------------------------------------------------------------------------
  # Creating data subset
  #
  ws_L02_ThisMonth<-subset(ws_L02_today_Y, as.numeric(monthNum)==as.numeric(qm))
  
  mensile<-ws_L02_ThisMonth
  This_Month <- format(mensile$date,"%m")[1]
  This_Month_Name <- format(mensile$date,"%B")[1]
  
  mydata <-data.frame(mensile$date,mensile$ws)
  colnames(mydata)        <- c("date","ws")
  
  PLOT_TV_NAME            <-paste(s_GAW_ID, inst_type,"WS",questo_anno,"TIMEVARIATION_GRAPH",This_Month,"MONTHLY",gsub("-","",Sys.Date()),sep = "_")
  PLOT_TV_NAME_FULL       <-paste (PLOT_DIR_T,paste(PLOT_TV_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_TV_NAME_FULL, width = 960, height = 960)
  par(ps = 14, cex = 1.5, cex.main = 2.2, mai=c(0.3,1.8,0.5,0.5)) 
  
  myOutput                <-timeVariation(mydata, pollutant = "ws", 
                                          ylab = paste("WS (m/s) -",questo_anno), 
                                          type="season",
                                          xlab = paste(s_GAW_ID, " - month variation \n - ",questo_anno," ",This_Month_Name," -"),
                                          cols = c("cornflowerblue"))
  dev.off()
  #
  # -------------------------------------------------------------------------------------------
  # Plotting temporary hourly timevariation
  #
  PLOT_TVH_NAME           <-paste("tmp_H_",s_GAW_ID, inst_type,questo_anno,"_TIMEVARIATION_GRAPH_",This_Month,"MONTHLY_",gsub("-","",Sys.Date()),sep = "")
  PLOT_TVH_NAME_FULL      <-paste (PLOT_DIR_T,paste(PLOT_TVH_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_TVH_NAME_FULL, width=1860,height=900,res=250)

  TV_ANNUAL_H             <-timeVariation(mydata, 
                                          pollutant = "ws", 
                                          ylab = paste("WS (m/s) -",questo_anno),
                                          xlab = c("Hour","Hour","Month","Weekday"),
                                          cols = c("cornflowerblue"))
  plot(TV_ANNUAL_H$plot$day.hour)
  
  dev.off()
  #
  # -------------------------------------------------------------------------------------------
  # Plotting temporary daily timevariation
  #
  PLOT_TVD_NAME           <-paste("tmp_D_",s_GAW_ID, inst_type,questo_anno,"_TIMEVARIATION_GRAPH_",This_Month,"MONTHLY_",gsub("-","",Sys.Date()),sep = "")
  PLOT_TVD_NAME_FULL      <-paste (PLOT_DIR_T,paste(PLOT_TVD_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_TVD_NAME_FULL, width=930,height=900,res=250)
  #par(ps = 14, cex = 1.5, cex.main = 2.2, mai=c(0.3,1.8,0.5,0.5)) 
  
  plot(TV_ANNUAL_H$plot$day)
  
  dev.off()
  #
  # -------------------------------------------------------------------------------------------
  # Merging temporary plots to final report
  #
  imgD                  <-readPNG(PLOT_TVD_NAME_FULL)
  imgH                  <-readPNG(PLOT_TVH_NAME_FULL)
  
  PLOT_TVF_NAME         <-paste(s_GAW_ID, inst_type,"WS",questo_anno,"TIMEVARIATION_GRAPH",This_Month,"MONTHLY",gsub("-","",Sys.Date()),sep = "_")
  PLOT_TVF_NAME_FULL    <-paste (PLOT_DIR_T,paste(PLOT_TVF_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_TVF_NAME_FULL, width=2970,height=2100,res=500)
  
  par(mar=c(1.1, 1.1, 1.1, 1.1), mgp=c(-1.5, 1, 0), las=0)
  par(ps = 14, cex.lab = 0.5)
  
  plot(0:297, ty="n",xaxt = "n",yaxt = "n",
       xlab = paste("WS - ",This_Month_Name," ",questo_anno," - monthly trend analysis",sep=""),ylab = "")
  #
  # -------------------------------------------------------------------------------------------
  # Specifying the position of the image through bottom-left and top-right coords
  #
  rasterImage(imgH,-5,80,205,220)
  rasterImage(imgD,205,80,309,220)
  
  dev.off() 
  #
  # -------------------------------------------------------------------------------------------
  # Cleaning temporary plots
  #
  FILE_PLOT_TVA         <-list.files(path = PLOT_DIR_T, pattern = glob2rx(paste("tmp_*",questo_anno,"*",sep = ""))
                            , all.files = FALSE,
                            full.names = F, recursive = FALSE,
                            ignore.case = FALSE, include.dirs = F, no.. = FALSE)
  FILE_PLOT_TVA
  LISTA_PLOT_TVA        <-as.character(FILE_PLOT_TVA)
  for(f in LISTA_PLOT_TVA) { file.remove(paste(PLOT_DIR_T,f,sep = "/")) }
}
#
##                                          # END PART 3.6 #
###########################################################################################################################

###########################################################################################################################
##                                           # PART 3.6.1 #
## ______________________________________________________________________________________________________________________##
##                                    Creating timevariation reports
##                                       WD MONTHLY TIMEVARIATION
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Cleaning Destination directory
#
unico_T                   <-c(wd_L02_today_Y[!duplicated(wd_L02_today_Y[,c('monthNum')]),]$monthNum)

for (qm in unico_T)
{ print(qm)
  #
  # -------------------------------------------------------------------------------------------
  # Creating data subset
  #
  wd_L02_ThisMonth<-subset(wd_L02_today_Y, as.numeric(monthNum)==as.numeric(qm))
  
  mensile<-wd_L02_ThisMonth
  This_Month <- format(mensile$date,"%m")[1]
  This_Month_Name <- format(mensile$date,"%B")[1]
  
  mydata <-data.frame(mensile$date,mensile$wd)
  colnames(mydata)        <- c("date","wd")
  
  PLOT_TV_NAME            <-paste(s_GAW_ID, inst_type,"WD",questo_anno,"TIMEVARIATION_GRAPH",This_Month,"MONTHLY",gsub("-","",Sys.Date()),sep = "_")
  PLOT_TV_NAME_FULL       <-paste (PLOT_DIR_T,paste(PLOT_TV_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_TV_NAME_FULL, width = 960, height = 960)
  par(ps = 14, cex = 1.5, cex.main = 2.2, mai=c(0.3,1.8,0.5,0.5)) 
  
  myOutput                <-timeVariation(mydata, pollutant = "wd", 
                                          ylab = paste("WD (deg) -",questo_anno), 
                                          type="season",
                                          xlab = paste(s_GAW_ID, " - month variation \n - ",questo_anno," ",This_Month_Name," -"),
                                          cols = c("cornflowerblue"))
  dev.off()
  #
  # -------------------------------------------------------------------------------------------
  # Plotting temporary hourly timevariation
  #
  PLOT_TVH_NAME           <-paste("tmp_H_",s_GAW_ID, inst_type,questo_anno,"_TIMEVARIATION_GRAPH_",This_Month,"MONTHLY_",gsub("-","",Sys.Date()),sep = "")
  PLOT_TVH_NAME_FULL      <-paste (PLOT_DIR_T,paste(PLOT_TVH_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_TVH_NAME_FULL, width=1860,height=900,res=250)
  
  TV_ANNUAL_H             <-timeVariation(mydata, 
                                          pollutant = "wd", 
                                          ylab = paste("WD (deg) -",questo_anno),
                                          xlab = c("Hour","Hour","Month","Weekday"),
                                          cols = c("cornflowerblue"))
  plot(TV_ANNUAL_H$plot$day.hour)
  
  dev.off()
  #
  # -------------------------------------------------------------------------------------------
  # Plotting temporary daily timevariation
  #
  PLOT_TVD_NAME           <-paste("tmp_D_",s_GAW_ID, inst_type,questo_anno,"_TIMEVARIATION_GRAPH_",This_Month,"MONTHLY_",gsub("-","",Sys.Date()),sep = "")
  PLOT_TVD_NAME_FULL      <-paste (PLOT_DIR_T,paste(PLOT_TVD_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_TVD_NAME_FULL, width=930,height=900,res=250)
  #par(ps = 14, cex = 1.5, cex.main = 2.2, mai=c(0.3,1.8,0.5,0.5)) 
  
  plot(TV_ANNUAL_H$plot$day)
  
  dev.off()
  #
  # -------------------------------------------------------------------------------------------
  # Merging temporary plots to final report
  #
  imgD                  <-readPNG(PLOT_TVD_NAME_FULL)
  imgH                  <-readPNG(PLOT_TVH_NAME_FULL)
  
  PLOT_TVF_NAME         <-paste(s_GAW_ID, inst_type,"WD",questo_anno,"TIMEVARIATION_GRAPH",This_Month,"MONTHLY",gsub("-","",Sys.Date()),sep = "_")
  PLOT_TVF_NAME_FULL    <-paste (PLOT_DIR_T,paste(PLOT_TVF_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_TVF_NAME_FULL, width=2970,height=2100,res=500)
  
  par(mar=c(1.1, 1.1, 1.1, 1.1), mgp=c(-1.5, 1, 0), las=0)
  par(ps = 14, cex.lab = 0.5)
  
  plot(0:297, ty="n",xaxt = "n",yaxt = "n",
       xlab = paste("WD - ",This_Month_Name," ",questo_anno," - monthly trend analysis",sep=""),ylab = "")
  #
  # -------------------------------------------------------------------------------------------
  # Specifying the position of the image through bottom-left and top-right coords
  #
  rasterImage(imgH,-5,80,205,220)
  rasterImage(imgD,205,80,309,220)
  
  dev.off() 
  #
  # -------------------------------------------------------------------------------------------
  # Cleaning temporary plots
  #
  FILE_PLOT_TVA         <-list.files(path = PLOT_DIR_T, pattern = glob2rx(paste("tmp_*",questo_anno,"*",sep = ""))
                                     , all.files = FALSE,
                                     full.names = F, recursive = FALSE,
                                     ignore.case = FALSE, include.dirs = F, no.. = FALSE)
  FILE_PLOT_TVA
  LISTA_PLOT_TVA        <-as.character(FILE_PLOT_TVA)
  for(f in LISTA_PLOT_TVA) { file.remove(paste(PLOT_DIR_T,f,sep = "/")) }
}
#
##                                          # END PART 3.6.1 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.6.2 #
## ______________________________________________________________________________________________________________________##
##                                    Creating timevariation reports
##                                       T MONTHLY TIMEVARIATION
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Cleaning Destination directory
#
unico_T                   <-c(t_L02_today_Y[!duplicated(t_L02_today_Y[,c('monthNum')]),]$monthNum)

for (qm in unico_T)
{ print(qm)
  #
  # -------------------------------------------------------------------------------------------
  # Creating data subset
  #
  t_L02_ThisMonth<-subset(t_L02_today_Y, as.numeric(monthNum)==as.numeric(qm))
  
  mensile<-t_L02_ThisMonth
  This_Month <- format(mensile$date,"%m")[1]
  This_Month_Name <- format(mensile$date,"%B")[1]
  
  mydata <-data.frame(mensile$date,mensile$t)
  colnames(mydata)        <- c("date","t")
  
  PLOT_TV_NAME            <-paste(s_GAW_ID, inst_type,"T",questo_anno,"TIMEVARIATION_GRAPH",This_Month,"MONTHLY",gsub("-","",Sys.Date()),sep = "_")
  PLOT_TV_NAME_FULL       <-paste (PLOT_DIR_T,paste(PLOT_TV_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_TV_NAME_FULL, width = 960, height = 960)
  par(ps = 14, cex = 1.5, cex.main = 2.2, mai=c(0.3,1.8,0.5,0.5)) 
  
  myOutput                <-timeVariation(mydata, pollutant = "t", 
                                          ylab = paste("T (°C) -",questo_anno), 
                                          type="season",
                                          xlab = paste(s_GAW_ID, " - month variation \n - ",questo_anno," ",This_Month_Name," -"),
                                          cols = c("cornflowerblue"))
  dev.off()
  #
  # -------------------------------------------------------------------------------------------
  # Plotting temporary hourly timevariation
  #
  PLOT_TVH_NAME           <-paste("tmp_H_",s_GAW_ID, inst_type,questo_anno,"_TIMEVARIATION_GRAPH_",This_Month,"MONTHLY_",gsub("-","",Sys.Date()),sep = "")
  PLOT_TVH_NAME_FULL      <-paste (PLOT_DIR_T,paste(PLOT_TVH_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_TVH_NAME_FULL, width=1860,height=900,res=250)
  
  TV_ANNUAL_H             <-timeVariation(mydata, 
                                          pollutant = "t", 
                                          ylab = paste("T (°C) -",questo_anno),
                                          xlab = c("Hour","Hour","Month","Weekday"),
                                          cols = c("cornflowerblue"))
  plot(TV_ANNUAL_H$plot$day.hour)
  
  dev.off()
  #
  # -------------------------------------------------------------------------------------------
  # Plotting temporary daily timevariation
  #
  PLOT_TVD_NAME           <-paste("tmp_D_",s_GAW_ID, inst_type,questo_anno,"_TIMEVARIATION_GRAPH_",This_Month,"MONTHLY_",gsub("-","",Sys.Date()),sep = "")
  PLOT_TVD_NAME_FULL      <-paste (PLOT_DIR_T,paste(PLOT_TVD_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_TVD_NAME_FULL, width=930,height=900,res=250)
  #par(ps = 14, cex = 1.5, cex.main = 2.2, mai=c(0.3,1.8,0.5,0.5)) 
  
  plot(TV_ANNUAL_H$plot$day)
  
  dev.off()
  #
  # -------------------------------------------------------------------------------------------
  # Merging temporary plots to final report
  #
  imgD                  <-readPNG(PLOT_TVD_NAME_FULL)
  imgH                  <-readPNG(PLOT_TVH_NAME_FULL)
  
  PLOT_TVF_NAME         <-paste(s_GAW_ID, inst_type,"T",questo_anno,"TIMEVARIATION_GRAPH",This_Month,"MONTHLY",gsub("-","",Sys.Date()),sep = "_")
  PLOT_TVF_NAME_FULL    <-paste (PLOT_DIR_T,paste(PLOT_TVF_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_TVF_NAME_FULL, width=2970,height=2100,res=500)
  
  par(mar=c(1.1, 1.1, 1.1, 1.1), mgp=c(-1.5, 1, 0), las=0)
  par(ps = 14, cex.lab = 0.5)
  
  plot(0:297, ty="n",xaxt = "n",yaxt = "n",
       xlab = paste("T - ",This_Month_Name," ",questo_anno," - monthly trend analysis",sep=""),ylab = "")
  #
  # -------------------------------------------------------------------------------------------
  # Specifying the position of the image through bottom-left and top-right coords
  #
  rasterImage(imgH,-5,80,205,220)
  rasterImage(imgD,205,80,309,220)
  
  dev.off() 
  #
  # -------------------------------------------------------------------------------------------
  # Cleaning temporary plots
  #
  FILE_PLOT_TVA         <-list.files(path = PLOT_DIR_T, pattern = glob2rx(paste("tmp_*",questo_anno,"*",sep = ""))
                                     , all.files = FALSE,
                                     full.names = F, recursive = FALSE,
                                     ignore.case = FALSE, include.dirs = F, no.. = FALSE)
  FILE_PLOT_TVA
  LISTA_PLOT_TVA        <-as.character(FILE_PLOT_TVA)
  for(f in LISTA_PLOT_TVA) { file.remove(paste(PLOT_DIR_T,f,sep = "/")) }
}
#
##                                          # END PART 3.6.2 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.6.3 #
## ______________________________________________________________________________________________________________________##
##                                    Creating timevariation reports
##                                       RH MONTHLY TIMEVARIATION
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Cleaning Destination directory
#
unico_T                   <-c(rh_L02_today_Y[!duplicated(rh_L02_today_Y[,c('monthNum')]),]$monthNum)

for (qm in unico_T)
{ print(qm)
  #
  # -------------------------------------------------------------------------------------------
  # Creating data subset
  #
  rh_L02_ThisMonth<-subset(rh_L02_today_Y, as.numeric(monthNum)==as.numeric(qm))
  
  mensile<-rh_L02_ThisMonth
  This_Month <- format(mensile$date,"%m")[1]
  This_Month_Name <- format(mensile$date,"%B")[1]
  
  mydata <-data.frame(mensile$date,mensile$rh)
  colnames(mydata)        <- c("date","rh")
  
  PLOT_TV_NAME            <-paste(s_GAW_ID, inst_type,"RH",questo_anno,"TIMEVARIATION_GRAPH",This_Month,"MONTHLY",gsub("-","",Sys.Date()),sep = "_")
  PLOT_TV_NAME_FULL       <-paste (PLOT_DIR_T,paste(PLOT_TV_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_TV_NAME_FULL, width = 960, height = 960)
  par(ps = 14, cex = 1.5, cex.main = 2.2, mai=c(0.3,1.8,0.5,0.5)) 
  
  myOutput                <-timeVariation(mydata, pollutant = "rh", 
                                          ylab = paste("RH (%) -",questo_anno), 
                                          type="season",
                                          xlab = paste(s_GAW_ID, " - month variation \n - ",questo_anno," ",This_Month_Name," -"),
                                          cols = c("cornflowerblue"))
  dev.off()
  #
  # -------------------------------------------------------------------------------------------
  # Plotting temporary hourly timevariation
  #
  PLOT_TVH_NAME           <-paste("tmp_H_",s_GAW_ID, inst_type,questo_anno,"_TIMEVARIATION_GRAPH_",This_Month,"MONTHLY_",gsub("-","",Sys.Date()),sep = "")
  PLOT_TVH_NAME_FULL      <-paste (PLOT_DIR_T,paste(PLOT_TVH_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_TVH_NAME_FULL, width=1860,height=900,res=250)
  
  TV_ANNUAL_H             <-timeVariation(mydata, 
                                          pollutant = "rh", 
                                          ylab = paste("RH (%) -",questo_anno),
                                          xlab = c("Hour","Hour","Month","Weekday"),
                                          cols = c("cornflowerblue"))
  plot(TV_ANNUAL_H$plot$day.hour)
  
  dev.off()
  #
  # -------------------------------------------------------------------------------------------
  # Plotting temporary daily timevariation
  #
  PLOT_TVD_NAME           <-paste("tmp_D_",s_GAW_ID, inst_type,questo_anno,"_TIMEVARIATION_GRAPH_",This_Month,"MONTHLY_",gsub("-","",Sys.Date()),sep = "")
  PLOT_TVD_NAME_FULL      <-paste (PLOT_DIR_T,paste(PLOT_TVD_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_TVD_NAME_FULL, width=930,height=900,res=250)
  #par(ps = 14, cex = 1.5, cex.main = 2.2, mai=c(0.3,1.8,0.5,0.5)) 
  
  plot(TV_ANNUAL_H$plot$day)
  
  dev.off()
  #
  # -------------------------------------------------------------------------------------------
  # Merging temporary plots to final report
  #
  imgD                  <-readPNG(PLOT_TVD_NAME_FULL)
  imgH                  <-readPNG(PLOT_TVH_NAME_FULL)
  
  PLOT_TVF_NAME         <-paste(s_GAW_ID, inst_type,"RH",questo_anno,"TIMEVARIATION_GRAPH",This_Month,"MONTHLY",gsub("-","",Sys.Date()),sep = "_")
  PLOT_TVF_NAME_FULL    <-paste (PLOT_DIR_T,paste(PLOT_TVF_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_TVF_NAME_FULL, width=2970,height=2100,res=500)
  
  par(mar=c(1.1, 1.1, 1.1, 1.1), mgp=c(-1.5, 1, 0), las=0)
  par(ps = 14, cex.lab = 0.5)
  
  plot(0:297, ty="n",xaxt = "n",yaxt = "n",
       xlab = paste("RH - ",This_Month_Name," ",questo_anno," - monthly trend analysis",sep=""),ylab = "")
  #
  # -------------------------------------------------------------------------------------------
  # Specifying the position of the image through bottom-left and top-right coords
  #
  rasterImage(imgH,-5,80,205,220)
  rasterImage(imgD,205,80,309,220)
  
  dev.off() 
  #
  # -------------------------------------------------------------------------------------------
  # Cleaning temporary plots
  #
  FILE_PLOT_TVA         <-list.files(path = PLOT_DIR_T, pattern = glob2rx(paste("tmp_*",questo_anno,"*",sep = ""))
                                     , all.files = FALSE,
                                     full.names = F, recursive = FALSE,
                                     ignore.case = FALSE, include.dirs = F, no.. = FALSE)
  FILE_PLOT_TVA
  LISTA_PLOT_TVA        <-as.character(FILE_PLOT_TVA)
  for(f in LISTA_PLOT_TVA) { file.remove(paste(PLOT_DIR_T,f,sep = "/")) }
}
#
##                                          # END PART 3.6.3 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.6.4 #
## ______________________________________________________________________________________________________________________##
##                                    Creating timevariation reports
##                                       P MONTHLY TIMEVARIATION
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Cleaning Destination directory
#
unico_T                   <-c(p_L02_today_Y[!duplicated(p_L02_today_Y[,c('monthNum')]),]$monthNum)

for (qm in unico_T)
{ print(qm)
  #
  # -------------------------------------------------------------------------------------------
  # Creating data subset
  #
  p_L02_ThisMonth<-subset(p_L02_today_Y, as.numeric(monthNum)==as.numeric(qm))
  
  mensile<-p_L02_ThisMonth
  This_Month <- format(mensile$date,"%m")[1]
  This_Month_Name <- format(mensile$date,"%B")[1]
  
  mydata <-data.frame(mensile$date,mensile$p)
  colnames(mydata)        <- c("date","p")
  
  PLOT_TV_NAME            <-paste(s_GAW_ID, inst_type,"P",questo_anno,"TIMEVARIATION_GRAPH",This_Month,"MONTHLY",gsub("-","",Sys.Date()),sep = "_")
  PLOT_TV_NAME_FULL       <-paste (PLOT_DIR_T,paste(PLOT_TV_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_TV_NAME_FULL, width = 960, height = 960)
  par(ps = 14, cex = 1.5, cex.main = 2.2, mai=c(0.3,1.8,0.5,0.5)) 
  
  myOutput                <-timeVariation(mydata, pollutant = "p", 
                                          ylab = paste("P (hPa) -",questo_anno), 
                                          type="season",
                                          xlab = paste(s_GAW_ID, " - month variation \n - ",questo_anno," ",This_Month_Name," -"),
                                          cols = c("cornflowerblue"))
  dev.off()
  #
  # -------------------------------------------------------------------------------------------
  # Plotting temporary hourly timevariation
  #
  PLOT_TVH_NAME           <-paste("tmp_H_",s_GAW_ID, inst_type,questo_anno,"_TIMEVARIATION_GRAPH_",This_Month,"MONTHLY_",gsub("-","",Sys.Date()),sep = "")
  PLOT_TVH_NAME_FULL      <-paste (PLOT_DIR_T,paste(PLOT_TVH_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_TVH_NAME_FULL, width=1860,height=900,res=250)
  
  TV_ANNUAL_H             <-timeVariation(mydata, 
                                          pollutant = "p", 
                                          ylab = paste("P (hPa) -",questo_anno), 
                                          xlab = c("Hour","Hour","Month","Weekday"),
                                          cols = c("cornflowerblue"))
  plot(TV_ANNUAL_H$plot$day.hour)
  
  dev.off()
  #
  # -------------------------------------------------------------------------------------------
  # Plotting temporary daily timevariation
  #
  PLOT_TVD_NAME           <-paste("tmp_D_",s_GAW_ID, inst_type,questo_anno,"_TIMEVARIATION_GRAPH_",This_Month,"MONTHLY_",gsub("-","",Sys.Date()),sep = "")
  PLOT_TVD_NAME_FULL      <-paste (PLOT_DIR_T,paste(PLOT_TVD_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_TVD_NAME_FULL, width=930,height=900,res=250)
  #par(ps = 14, cex = 1.5, cex.main = 2.2, mai=c(0.3,1.8,0.5,0.5)) 
  
  plot(TV_ANNUAL_H$plot$day)
  
  dev.off()
  #
  # -------------------------------------------------------------------------------------------
  # Merging temporary plots to final report
  #
  imgD                  <-readPNG(PLOT_TVD_NAME_FULL)
  imgH                  <-readPNG(PLOT_TVH_NAME_FULL)
  
  PLOT_TVF_NAME         <-paste(s_GAW_ID, inst_type,"P",questo_anno,"TIMEVARIATION_GRAPH",This_Month,"MONTHLY",gsub("-","",Sys.Date()),sep = "_")
  PLOT_TVF_NAME_FULL    <-paste (PLOT_DIR_T,paste(PLOT_TVF_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_TVF_NAME_FULL, width=2970,height=2100,res=500)
  
  par(mar=c(1.1, 1.1, 1.1, 1.1), mgp=c(-1.5, 1, 0), las=0)
  par(ps = 14, cex.lab = 0.5)
  
  plot(0:297, ty="n",xaxt = "n",yaxt = "n",
       xlab = paste("P - ",This_Month_Name," ",questo_anno," - monthly trend analysis",sep=""),ylab = "")
  #
  # -------------------------------------------------------------------------------------------
  # Specifying the position of the image through bottom-left and top-right coords
  #
  rasterImage(imgH,-5,80,205,220)
  rasterImage(imgD,205,80,309,220)
  
  dev.off() 
  #
  # -------------------------------------------------------------------------------------------
  # Cleaning temporary plots
  #
  FILE_PLOT_TVA         <-list.files(path = PLOT_DIR_T, pattern = glob2rx(paste("tmp_*",questo_anno,"*",sep = ""))
                                     , all.files = FALSE,
                                     full.names = F, recursive = FALSE,
                                     ignore.case = FALSE, include.dirs = F, no.. = FALSE)
  FILE_PLOT_TVA
  LISTA_PLOT_TVA        <-as.character(FILE_PLOT_TVA)
  for(f in LISTA_PLOT_TVA) { file.remove(paste(PLOT_DIR_T,f,sep = "/")) }
}
#
##                                          # END PART 3.6.4 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.6.5 #
## ______________________________________________________________________________________________________________________##
##                                    Creating timevariation reports
##                                       RAD MONTHLY TIMEVARIATION
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Cleaning Destination directory
#
unico_T                   <-c(rad_L02_today_Y[!duplicated(rad_L02_today_Y[,c('monthNum')]),]$monthNum)

for (qm in unico_T)
{ print(qm)
  #
  # -------------------------------------------------------------------------------------------
  # Creating data subset
  #
  rad_L02_ThisMonth<-subset(rad_L02_today_Y, as.numeric(monthNum)==as.numeric(qm))
  
  mensile<-rad_L02_ThisMonth
  This_Month <- format(mensile$date,"%m")[1]
  This_Month_Name <- format(mensile$date,"%B")[1]
  
  mydata <-data.frame(mensile$date,mensile$rad)
  colnames(mydata)        <- c("date","rad")
  
  PLOT_TV_NAME            <-paste(s_GAW_ID, inst_type,"RAD",questo_anno,"TIMEVARIATION_GRAPH",This_Month,"MONTHLY",gsub("-","",Sys.Date()),sep = "_")
  PLOT_TV_NAME_FULL       <-paste (PLOT_DIR_T,paste(PLOT_TV_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_TV_NAME_FULL, width = 960, height = 960)
  par(ps = 14, cex = 1.5, cex.main = 2.2, mai=c(0.3,1.8,0.5,0.5)) 
  
  myOutput                <-timeVariation(mydata, pollutant = "rad", 
                                          ylab = paste("RAD (W/m2) -",questo_anno), 
                                          type="season",
                                          xlab = paste(s_GAW_ID, " - month variation \n - ",questo_anno," ",This_Month_Name," -"),
                                          cols = c("cornflowerblue"))
  dev.off()
  #
  # -------------------------------------------------------------------------------------------
  # Plotting temporary hourly timevariation
  #
  PLOT_TVH_NAME           <-paste("tmp_H_",s_GAW_ID, inst_type,questo_anno,"_TIMEVARIATION_GRAPH_",This_Month,"MONTHLY_",gsub("-","",Sys.Date()),sep = "")
  PLOT_TVH_NAME_FULL      <-paste (PLOT_DIR_T,paste(PLOT_TVH_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_TVH_NAME_FULL, width=1860,height=900,res=250)
  
  TV_ANNUAL_H             <-timeVariation(mydata, 
                                          pollutant = "rad", 
                                          ylab = paste("RAD (W/m2) -",questo_anno), 
                                          xlab = c("Hour","Hour","Month","Weekday"),
                                          cols = c("cornflowerblue"))
  plot(TV_ANNUAL_H$plot$day.hour)
  
  dev.off()
  #
  # -------------------------------------------------------------------------------------------
  # Plotting temporary daily timevariation
  #
  PLOT_TVD_NAME           <-paste("tmp_D_",s_GAW_ID, inst_type,questo_anno,"_TIMEVARIATION_GRAPH_",This_Month,"MONTHLY_",gsub("-","",Sys.Date()),sep = "")
  PLOT_TVD_NAME_FULL      <-paste (PLOT_DIR_T,paste(PLOT_TVD_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_TVD_NAME_FULL, width=930,height=900,res=250)
  #par(ps = 14, cex = 1.5, cex.main = 2.2, mai=c(0.3,1.8,0.5,0.5)) 
  
  plot(TV_ANNUAL_H$plot$day)
  
  dev.off()
  #
  # -------------------------------------------------------------------------------------------
  # Merging temporary plots to final report
  #
  imgD                  <-readPNG(PLOT_TVD_NAME_FULL)
  imgH                  <-readPNG(PLOT_TVH_NAME_FULL)
  
  PLOT_TVF_NAME         <-paste(s_GAW_ID, inst_type,"RAD",questo_anno,"TIMEVARIATION_GRAPH",This_Month,"MONTHLY",gsub("-","",Sys.Date()),sep = "_")
  PLOT_TVF_NAME_FULL    <-paste (PLOT_DIR_T,paste(PLOT_TVF_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_TVF_NAME_FULL, width=2970,height=2100,res=500)
  
  par(mar=c(1.1, 1.1, 1.1, 1.1), mgp=c(-1.5, 1, 0), las=0)
  par(ps = 14, cex.lab = 0.5)
  
  plot(0:297, ty="n",xaxt = "n",yaxt = "n",
       xlab = paste("RAD - ",This_Month_Name," ",questo_anno," - monthly trend analysis",sep=""),ylab = "")
  #
  # -------------------------------------------------------------------------------------------
  # Specifying the position of the image through bottom-left and top-right coords
  #
  rasterImage(imgH,-5,80,205,220)
  rasterImage(imgD,205,80,309,220)
  
  dev.off() 
  #
  # -------------------------------------------------------------------------------------------
  # Cleaning temporary plots
  #
  FILE_PLOT_TVA         <-list.files(path = PLOT_DIR_T, pattern = glob2rx(paste("tmp_*",questo_anno,"*",sep = ""))
                                     , all.files = FALSE,
                                     full.names = F, recursive = FALSE,
                                     ignore.case = FALSE, include.dirs = F, no.. = FALSE)
  FILE_PLOT_TVA
  LISTA_PLOT_TVA        <-as.character(FILE_PLOT_TVA)
  for(f in LISTA_PLOT_TVA) { file.remove(paste(PLOT_DIR_T,f,sep = "/")) }
}
#
##                                          # END PART 3.6.5 #
###########################################################################################################################
#                                                                                                                         #
## End of MET_D22_1810.R                                                                                                  # 
#                                                                                                                         # 
###################################################################################### Authors: L u C A, Davide ###########

###########################################################################################################################
## Project: NEXTDATA                                                                                                     ##
## Parameter: NOX                                                                                                        ##
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
## Script filename: NOX_D22_1810.R                                                                                       ##
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
inst_type               <- "NOX"                                             # replace the value with your instrument type
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
library(lubridate)
library(hydroTSM)
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
# Reading instrumental data sheet
#
FILE_L0                 <-list.files(path = L0_ANCIL_DIR, pattern = glob2rx(paste("NOx_PARAM_TABLE_",questo_anno,"*",sep = "")), 
                                     all.files = FALSE,
                                     full.names = F, recursive = FALSE,
                                     ignore.case = FALSE, include.dirs = F, no.. = FALSE)
EBAS_L0_FILENAME        <-as.character(FILE_L0[1])
EBAS_L0_FILENAME
#
temp_L00                <-read.table(paste(L0_ANCIL_DIR,paste(EBAS_L0_FILENAME,sep=""),sep = "/"), row.names=NULL, header = T)

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
# -------------------------------------------------------------------------------------------
# Reading Level-1
#
FILE_L1                 <-list.files(path = L1_DIR, pattern = glob2rx(paste(s_code,".",questo_anno,"*",sep = "")), 
                                     all.files = FALSE,
                                     full.names = F, recursive = FALSE,
                                     ignore.case = FALSE, include.dirs = F, no.. = FALSE)
EBAS_L1_FILENAME        <-as.character(FILE_L1[1])
EBAS_L1_FILENAME
# -------------------------------------------------------------------------------------------
#Reading header lines of Level-1 Data sheet
#
L1_n_lines <- as.integer(unlist(strsplit(readLines(paste(L1_DIR,EBAS_L1_FILENAME,sep = "/"), n=1), " "))[1])
L1_n_lines
#
# -------------------------------------------------------------------------------------------
# Creating temporary data table of Level-1 
#
temp_L01                <-read.table(paste(L1_DIR,EBAS_L1_FILENAME,sep = "/"),skip = L1_n_lines-1,header = T)
#
# -------------------------------------------------------------------------------------------
#Converting JD values to date
#
temp_L01$jd             <-as.integer(temp_L01$start_time)
#
temp_L01$day            <-as.Date(temp_L01$start_time, origin=questa_start_time)
temp_L01$time.dec       <-temp_L01$start_time-temp_L01$jd
temp_L01$time           <-temp_L01$time.dec*1440+0.01
temp_L01$hour           <-as.integer(temp_L01$time/60)
temp_L01$min            <-as.integer(temp_L01$time-temp_L01$hour*60)
temp_L01$date           <-paste(temp_L01$day," ",temp_L01$hour,":",temp_L01$min,":00",sep="")
temp_L01$date           <-as.POSIXct(strptime(temp_L01$date, format = "%Y-%m-%d %H:%M:%S", tz = "GMT"))
temp_L01$monthNum       <-format(temp_L01$date,"%m")
temp_L01$month          <-format(temp_L01$date,"%B")
temp_L01$day            <-format(temp_L01$date,"%d")
#
temp_L01$nf_validity    <-sapply(temp_L01$numflag, nf_val_check, tab_nf$numflag, tab_nf$category)

NOX_L01_today_Y          <- subset(temp_L01, nf_validity == "V")
#
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
temp_L02                <-read.table(paste(L2_DIR,EBAS_L2_FILENAME,sep = "/"),fill = T, skip = L2_n_lines-1, header = T, sep="")
#
# -------------------------------------------------------------------------------------------
# Creating a subset over L02 data 
# 
temp_L02                <- subset(temp_L02, temp_L02$start_time < strptime(as.POSIXct(Sys.Date()), "%Y-%m-%d %H:%M")$yday)
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
temp_L02$monthNum       <-format(temp_L02$date, "%m")
#
NOX_L02_today           <-data.frame(temp_L02$date,temp_L02$NO,temp_L02$numflag_no,temp_L02$NO2,temp_L02$numflag_no2)
#
colnames(NOX_L02_today) <- c("date","no","numflag_no","no2","numflag_no2")
#
NOX_L02_today$month     <- format(NOX_L02_today$date,"%B")
NOX_L02_today$monthNum  <- as.numeric(format(NOX_L02_today$date,"%m"))
NOX_L02_today$day       <- as.numeric(format(NOX_L02_today$date,"%d"))
#
# -------------------------------------------------------------------------------------------
# Subsetting NO Data affected by invalid values
#
NO_FAIL_today           <- subset(NOX_L02_today, numflag_no == 0.999)
NO_TFAIL                <- subset(NO_FAIL_today, select=c("month","day","monthNum","numflag_no"))
NO_mesi_FAIL            <- data.frame(NO_TFAIL[!duplicated(NO_TFAIL[1:2]),])
NO_mesi_FAIL_COUNT      <- data.frame(NO_mesi_FAIL[!duplicated(NO_mesi_FAIL[1]),],count(NO_mesi_FAIL,"monthNum"))
#
if (nrow(NO_mesi_FAIL)  > 0)  { NO_mesi_FAIL_COUNT$print       <-paste(NO_mesi_FAIL_COUNT$month," (",NO_mesi_FAIL_COUNT$freq," days)",sep = "")
                           NO_Somma_giorni_FAIL       <- sum(NO_mesi_FAIL_COUNT$freq)}
if (nrow(NO_mesi_FAIL) == 0)  { }
#
# -------------------------------------------------------------------------------------------
# Subsetting NO2 Data affected by invalid values
#
NO2_FAIL_today          <- subset(NOX_L02_today, numflag_no2 == 0.999)
NO2_TFAIL               <- subset(NO2_FAIL_today, select=c("month","day","monthNum","numflag_no2"))
NO2_mesi_FAIL           <- data.frame(NO2_TFAIL[!duplicated(NO2_TFAIL[1:2]),])
NO2_mesi_FAIL_COUNT     <- data.frame(NO2_mesi_FAIL[!duplicated(NO2_mesi_FAIL[1]),],count(NO2_mesi_FAIL,"monthNum"))
#
if (nrow(NO2_mesi_FAIL) > 0)  { NO2_mesi_FAIL_COUNT$print       <-paste(NO2_mesi_FAIL_COUNT$month," (",NO2_mesi_FAIL_COUNT$freq," days)",sep = "")
NO2_Somma_giorni_FAIL       <- sum(NO2_mesi_FAIL_COUNT$freq)}
if (nrow(NO2_mesi_FAIL) == 0)  { }
#
# -------------------------------------------------------------------------------------------
# Subsetting valid Data
#
NOX_L02_today_Y        <- subset(NOX_L02_today, numflag_no != 0.999)

unico                 <- c(NOX_L02_today_Y[!duplicated(NOX_L02_today_Y[,c('month')]),]$month)
#
# -------------------------------------------------------------------------------------------
#
##                                         # END PART 2.0 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.0 #
## ______________________________________________________________________________________________________________________##
##                                    Creating statistcs/graphic reports
##                                               NO MONTHLY GRAPHS
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Subsetting NO data by month
#
unico_M               <- c(NOX_L02_today_Y[!duplicated(NOX_L02_today_Y[,c('monthNum')]),]$monthNum)

for (qm in unico_M)
{
  NOX_L02_ThisMonth   <-subset(NOX_L02_today_Y, as.integer(monthNum)==qm)
  temp_L02_ThisMonth  <-subset(temp_L02, as.integer(monthNum)==qm)
  temp_L01_ThisMonth  <-subset(temp_L01, as.integer(monthNum)==qm)
  temp_L00_ThisMonth  <-subset(temp_L00, as.integer(monthNum)==qm)

  print(head(temp_L01_ThisMonth, 5))

  OBS_Month_start     <-head(format(temp_L02_ThisMonth$date,"%d %B %Y"),1)
  OBS_Month_end       <-tail(format(temp_L02_ThisMonth$date,"%d %B %Y"),1)
  #
  # -------------------------------------------------------------------------------------------
  # Calculating days with invalid flags
  #
  FAIL_ThisMonth      <-subset(NO_FAIL_today, as.integer(monthNum) == qm)
  FAIL_ThisMonth$day  <-format(FAIL_ThisMonth$date,"%d")
  FAIL_unico          <-data.frame(FAIL_ThisMonth[!duplicated(FAIL_ThisMonth[,c('day')]),])
  FAIL_DAYS           <-nrow(FAIL_unico)
  
  NO_mensile          <-subset(NOX_L02_ThisMonth, numflag_no != 0.999000000)
  NO_mensile$giorno   <-format(NO_mensile$date,"%d")
  NO_This_Month       <-format(NO_mensile$date,"%m")[1]
  NO_This_Month_Name  <-format(NO_mensile$date,"%B")[1]
  
  print(paste("ora il ",NO_This_Month_Name[1], FAIL_DAYS))   # check point: printing month and failing days
  #
  # -------------------------------------------------------------------------------------------
  # Calculating monthly statistics
  #
  NO_mean             <-mean(NO_mensile$no)  
  NO_men_MIN          <-subset(NO_mensile, no == min(NO_mensile$no))
  NO_men_MAX          <-subset(NO_mensile, no == max(NO_mensile$no))

  print(NO_mean)
  print(NO_men_MIN)
  print(NO_men_MAX)
  
  # -------------------------------------------------------------------------------------------
  # Cleaning Destination directory
  # 
  FILE_PLOT_M<-list.files(path = PLOT_DIR_M, pattern = paste(s_GAW_ID,"NO", questo_anno,NO_This_Month,"MONTHLY_GRAPH_*",sep = "_"), 
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
  PLOT_M_NAME         <-paste(s_GAW_ID,"NO", questo_anno, NO_This_Month, "MONTHLY_GRAPH", gsub("-","",Sys.Date()), sep = "_")
  PLOT_M_NAME_FULL    <-paste (PLOT_DIR_M,paste(PLOT_M_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_M_NAME_FULL, width = 2480, height = 3508)
  #
  # -------------------------------------------------------------------------------------------
  # Preparing plotting parameters (font size, margins, ...)
  # 
  par(mfrow = c(7,1))
  par(ps = 14, cex = 2, cex.main = 3.5,cex.sub=2.2, cex.lab=2.8, cex.axis = 2.2, mai=c(0.3,1.8,0.5,0.5))
  #
  # -------------------------------------------------------------------------------------------
  # Creating the plotting matrix
  #
  m <- rbind(c(1, 1), c(2, 2), c(3, 3), c(4, 4), c(5, 5), c(6, 6), c(7, 8))
  layout(m)
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting NO
  #
  plot(ylim=c(-0.15,max(NO_mensile$no)+0.175),
       xlim = c(min(c(NOX_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date)),
                max(c(NOX_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date))),
       mgp = c(8, 4, 0),
       NO_mensile$date, NO_mensile$no, type = "h",
       xlab = "",ylab =expression(paste("NO (nmol/mol) - L02")), col="lightblue", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
  title(paste("NO - L02 -",questo_anno,NO_This_Month_Name), line = -3)
  lines(NO_mensile$date, NO_mensile$no, type = "l", lty = 1, col="darkred",lwd = 2)
  
  points(NO_men_MAX$date[1], NO_men_MAX$no[1], col= "magenta",pch=20)
  text(NO_men_MAX$date[1], NO_men_MIN$no[1], labels = paste("Max (", format(NO_men_MAX$date[1],"%B %d"), ")", sep=""),col="magenta",pos=1,cex = 1.8)
  segments(NO_men_MAX$date[1], NO_men_MAX$no[1], NO_men_MAX$date[1],NO_men_MIN$no[1]-0.3, lty = 2, col="black",lwd = 1)

  points(NO_men_MIN$date[1], NO_men_MIN$no[1], col= "blue",pch=20)
  text(NO_men_MIN$date[1], NO_men_MIN$no[1], labels = paste("Min (", format(NO_men_MIN$date[1],"%B %d"), ")", sep =""),col="blue",pos=1,cex = 1.8)
  segments(NO_men_MIN$date[1], NO_men_MIN$no[1], NO_men_MIN$date[1], NO_men_MIN$no[1]-0.3, lty = 2, col="black",lwd = 1)
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting NUMFLAG (L01)
  #
  plot(ylim=c(0,1.1),
       xlim = c(min(c(NOX_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date)),
                max(c(NOX_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date))),
       mgp = c(8, 4, 0),
       temp_L01_ThisMonth$date, temp_L01_ThisMonth$numflag_NO, type = "h",
       xlab = "",ylab =("numflag - L01"), col="tan", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
  title(paste("numflag - L01 -",questo_anno,NO_This_Month_Name), line = -3)
  lines(temp_L01_ThisMonth$date, temp_L01_ThisMonth$numflag_NO, type = "l",
        lty = 1,
        col = "lightgreen",
        lwd = 2)
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting NO L02 vs NO instrumental
  #
  temp_L00_ThisMonth$NO[temp_L00_ThisMonth$NO > max(NO_mensile$no)] <-max(NO_mensile$no)+0.1
  
  plot(ylim=c(-0.15,max(NO_mensile$no)+0.175),
       xlim = c(min(c(NOX_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date)),
                max(c(NOX_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date))),
       mgp = c(8, 4, 0),
       temp_L00_ThisMonth$date, temp_L00_ThisMonth$NO, type = "h",
       xlab = "",ylab =("NO (nmol/mol) - inst vs L02"), col="cadetblue2", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))

  title(paste("NO (from instrument) vs NO (L02) -",questo_anno,NO_This_Month_Name), line = -3)

  title(paste("NO (inst) values higher than", round(max(NO_mensile$no)+0.1,1), "are out of scale and are rappresented as ", round(max(NO_mensile$no)+0.1,2))
        ,col="black",cex.main = 2.6, line = -7, font.main = 1)

  lines(NO_mensile$date, NO_mensile$no, type = "l", lty = 1, col="darkred",lwd = 2)
  
  legend("topleft", legend=c("NO (inst)","NO (L02)"), lty=c(1,1), lwd = c(2,2), col=c("steelblue2","darkred"), cex = 3)
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting Flow Sample and Pre
  #
  xx    <- c(temp_L00_ThisMonth$date, rev(temp_L00_ThisMonth$date))
  yy_PR <- c(rep(0, nrow(temp_L00_ThisMonth)), rev(temp_L00_ThisMonth$Pre))
  yy_FS <- c(rep(0, nrow(temp_L00_ThisMonth)), rev(temp_L00_ThisMonth$Flow_sample))  
  yy_PC <- c(rep(0, nrow(temp_L00_ThisMonth)), rev(temp_L00_ThisMonth$P_chamb))
  yy_TC <- c(rep(0, nrow(temp_L00_ThisMonth)), rev(temp_L00_ThisMonth$T_Cooler))
  yy_PM <- c(rep(0, nrow(temp_L00_ThisMonth)), rev(temp_L00_ThisMonth$PMT_V)) 
  #
  plot(ylim=c(-0.1,2),
       xlim = c(min(c(NOX_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date)),
                max(c(NOX_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date))),
       mgp = c(8, 4, 0),
       temp_L00_ThisMonth$date, temp_L00_ThisMonth$Flow_sample, type = "n",
       xlab = "",ylab =("Flow_sample & Pre - inst"), col="cadetblue2", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))

  title(paste("Flow_sample and Pre - from instrument -",questo_anno,NO_This_Month_Name), line = -3)
  #
  # Flow sample
  polygon(xx, yy_FS, col='rosybrown1',border = "indianred3")
  #  
  # Pre
  #  
  polygon(xx, yy_PR, col='indianred1',border = "tomato4")
  #  
  legend("topleft", legend=c("Flow_sample","Pre"), lty=c(1,1), lwd = c(2,2), col=c("indianred3","tomato4"), cex = 3)
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting P_chamb e T_Cooler
  #
  plot(ylim=c(-100,400),
       xlim = c(min(c(NOX_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date)),
                max(c(NOX_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date))),
       mgp = c(8, 4, 0),
       temp_L00_ThisMonth$date, temp_L00_ThisMonth$P_chamb, type = "h",
       xlab = "",ylab =("P_chamb & T_Cooler - inst"), col="palegreen", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
  
  title(paste("P_chamb and T_Cooler - from instrument -",questo_anno,NO_This_Month_Name), line = -3)
  #
  # P_chamb
  lines(temp_L00_ThisMonth$date, temp_L00_ThisMonth$P_chamb, type = "l", lty = 1, col="palegreen4",lwd = 2)
  #  
  # T_Cooler
  polygon(xx, yy_TC, col='seagreen1',border = "purple4",lwd = 2)
  # 
  legend("topleft", legend=c("P_chamb","T_Cooler"), lty=c(1,1), lwd = c(2,2), col=c("palegreen","purple4"), cex = 3)
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting PMT_V
  #
  plot(ylim=c(-1100,-1150),
       xlim = c(min(c(NOX_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date)),
                max(c(NOX_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date))),
       mgp = c(8, 4, 0),
       temp_L00_ThisMonth$date, temp_L00_ThisMonth$PMT_V, type = "h",
       xlab = "",ylab =("PMT_V - inst -"), col="lightskyblue2", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))

  title(paste("PMT_V - from instrument -",questo_anno,NO_This_Month_Name), line = -3)
  
  lines(temp_L00_ThisMonth$date, temp_L00_ThisMonth$PMT_V, type = "l", lty = 1, col="royalblue",lwd = 2.5)
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting Text
  #
  plot(c(0, 1), c(0, 1), ann = F, bty = 'n', type = 'n', xaxt = 'n', yaxt = 'n')
  text(x = 0, y = 0.95, paste (PLOT_M_NAME,"  -  ",NO_This_Month_Name," ",questo_anno),
       cex = 3.3, col = "darkred",pos = 4)

  text(x = -0.005, y = 0.75, paste(" Observations from", OBS_Month_start," to ", OBS_Month_end,
                                   "\n",
                                   "(days of observation: ", 1+(as.integer(tail((NO_mensile$date),1)-head((NO_mensile$date)),1)),")")
       , cex = 2.8, col = "black",pos = 4)

  plot(c(0, 1), c(0, 1), ann = F, bty = 'n', type = 'n', xaxt = 'n', yaxt = 'n')
  text(x = 0, y = 0.95, paste ("Statistics  -  ",NO_This_Month_Name," ",questo_anno),
       cex = 3.3, col = "darkred",pos = 4)

  text(x = 0, y = 0.55, paste("\n", "NO min: (", round(min(NO_mensile$no),2),") - NO max: (", round(max(NO_mensile$no),2),") - NO mean: (", round(mean(NO_mensile$no),2),") - NO sd: (", round(sd(NO_mensile$no),2),")","\n",
                              "NO percentile:    5th: (",round(quantile(NO_mensile$no, probs = c(0.05)),digits=2),")",
                              " - 25th: (",round(quantile(NO_mensile$no, probs = c(0.25)),digits=2),")",
                              " - 50th: (",round(quantile(NO_mensile$no, probs = c(0.50)),digits=2),")",
                              " - 75th: (",round(quantile(NO_mensile$no, probs = c(0.75)),digits=2),")",
                              " - 95th: (",round(quantile(NO_mensile$no, probs = c(0.95)),digits=2),")","\n","\n",
                              "L02 numflag = 0.999 (number of days affected):   ", FAIL_DAYS,
                              " (",round((FAIL_DAYS/days_in_month(temp_L02_ThisMonth$date[1]))*100,digits=2),"%)",
                              "\n",
                              "Days of ",NO_This_Month_Name," affected:","\n",
                              if (FAIL_DAYS==0){"none"},
                              if (!is.na(FAIL_unico$day[1])){FAIL_unico$day[1]} ,"   ",
                              if (!is.na(FAIL_unico$day[2])){FAIL_unico$day[2]} ,"   ",                              
                              if (!is.na(FAIL_unico$day[3])){FAIL_unico$day[3]} ,"   ",                              
                              if (!is.na(FAIL_unico$day[4])){FAIL_unico$day[4]} ,"   ",
                              if (!is.na(FAIL_unico$day[5])){FAIL_unico$day[5]} ,"   ",                              
                              if (!is.na(FAIL_unico$day[6])){FAIL_unico$day[6]} ,"   ",                              
                              if (!is.na(FAIL_unico$day[7])){FAIL_unico$day[7]} ,"   ",                              
                              if (!is.na(FAIL_unico$day[8])){FAIL_unico$day[8]} ,"   ",
                              if (!is.na(FAIL_unico$day[9])){FAIL_unico$day[9]} ,"   ",                              
                              if (!is.na(FAIL_unico$day[10])){FAIL_unico$day[10]} ,"   ",  
                              if (!is.na(FAIL_unico$day[11])){FAIL_unico$day[11]} ,"   ",
                              if (!is.na(FAIL_unico$day[12])){FAIL_unico$day[12]} ,"   ",                              
                              if (!is.na(FAIL_unico$day[13])){FAIL_unico$day[13]} ,"   ",                              
                              if (!is.na(FAIL_unico$day[14])){FAIL_unico$day[14]} ,"   ",
                              if (!is.na(FAIL_unico$day[15])){FAIL_unico$day[15]} ,"   ",
                              "\n",
                              if (!is.na(FAIL_unico$day[16])){FAIL_unico$day[16]} ,"   ",                              
                              if (!is.na(FAIL_unico$day[17])){FAIL_unico$day[17]} ,"   ",                              
                              if (!is.na(FAIL_unico$day[18])){FAIL_unico$day[18]} ,"   ",
                              if (!is.na(FAIL_unico$day[19])){FAIL_unico$day[19]} ,"   ",                              
                              if (!is.na(FAIL_unico$day[20])){FAIL_unico$day[20]} ,"   ",                                
                              if (!is.na(FAIL_unico$day[21])){FAIL_unico$day[21]} ,"   ",
                              if (!is.na(FAIL_unico$day[22])){FAIL_unico$day[22]} ,"   ",                              
                              if (!is.na(FAIL_unico$day[23])){FAIL_unico$day[23]} ,"   ",                              
                              if (!is.na(FAIL_unico$day[24])){FAIL_unico$day[24]} ,"   ",
                              if (!is.na(FAIL_unico$day[25])){FAIL_unico$day[25]} ,"   ",                              
                              if (!is.na(FAIL_unico$day[26])){FAIL_unico$day[26]} ,"   ",                              
                              if (!is.na(FAIL_unico$day[27])){FAIL_unico$day[27]} ,"   ",                              
                              if (!is.na(FAIL_unico$day[28])){FAIL_unico$day[28]} ,"   ",
                              if (!is.na(FAIL_unico$day[29])){FAIL_unico$day[29]} ,"   ",                              
                              if (!is.na(FAIL_unico$day[30])){FAIL_unico$day[30]} ,"   ",                                 
                              if (!is.na(FAIL_unico$day[31])){FAIL_unico$day[31]} ,"   ",                              
                              sep=""),
       cex = 2.8, col = "black",pos = 4)

  dev.off()
}
#
# -------------------------------------------------------------------------------------------
##                                        # END PART 3.0 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.0.1 #
## ______________________________________________________________________________________________________________________##
##                                    Creating statistcs/graphic reports
##                                               NO2 MONTHLY GRAPHS
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Subsetting NO data by month
#
unico_M               <- c(NOX_L02_today_Y[!duplicated(NOX_L02_today_Y[,c('monthNum')]),]$monthNum)

for (qm in unico_M)
{
  NOX_L02_ThisMonth   <-subset(NOX_L02_today_Y, as.integer(monthNum)==qm)
  temp_L02_ThisMonth  <-subset(temp_L02, as.integer(monthNum)==qm)
  temp_L01_ThisMonth  <-subset(temp_L01, as.integer(monthNum)==qm)
  temp_L00_ThisMonth  <-subset(temp_L00, as.integer(monthNum)==qm)
  
  print(head(temp_L01_ThisMonth, 5))
  
  OBS_Month_start     <-head(format(temp_L02_ThisMonth$date,"%d %B %Y"),1)
  OBS_Month_end       <-tail(format(temp_L02_ThisMonth$date,"%d %B %Y"),1)
  #
  # -------------------------------------------------------------------------------------------
  # Calculating days with invalid flags
  #
  FAIL_ThisMonth      <-subset(NO2_FAIL_today, as.integer(monthNum) == qm)
  FAIL_ThisMonth$day  <-format(FAIL_ThisMonth$date,"%d")
  FAIL_unico          <-data.frame(FAIL_ThisMonth[!duplicated(FAIL_ThisMonth[,c('day')]),])
  FAIL_DAYS           <-nrow(FAIL_unico)
  
  NO2_mensile          <-subset(NOX_L02_ThisMonth, numflag_no2 != 0.999000000)
  NO2_mensile$giorno   <-format(NO2_mensile$date,"%d")
  NO2_This_Month       <-format(NO2_mensile$date,"%m")[1]
  NO2_This_Month_Name  <-format(NO2_mensile$date,"%B")[1]
  
  print(paste("ora il ",NO2_This_Month_Name[1], FAIL_DAYS))   # check point: printing month and failing days
  #
  # -------------------------------------------------------------------------------------------
  # Calculating monthly statistics
  #
  NO2_mean             <-mean(NO2_mensile$no2)  
  NO2_men_MIN          <-subset(NO2_mensile, no2 == min(NO2_mensile$no2))
  NO2_men_MAX          <-subset(NO2_mensile, no2 == max(NO2_mensile$no2))
  
  print(NO2_mean)
  print(NO2_men_MIN)
  print(NO2_men_MAX)
  
  # -------------------------------------------------------------------------------------------
  # Cleaning Destination directory
  # 
  FILE_PLOT_M<-list.files(path = PLOT_DIR_M, pattern = paste(s_GAW_ID,"NO2", questo_anno,NO2_This_Month,"MONTHLY_GRAPH_*",sep = "_"), 
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
  PLOT_M_NAME         <-paste(s_GAW_ID,"NO2", questo_anno, NO2_This_Month, "MONTHLY_GRAPH", gsub("-","",Sys.Date()), sep = "_")
  PLOT_M_NAME_FULL    <-paste (PLOT_DIR_M,paste(PLOT_M_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_M_NAME_FULL, width = 2480, height = 3508)
  #
  # -------------------------------------------------------------------------------------------
  # Preparing plotting parameters (font size, margins, ...)
  # 
  par(mfrow = c(7,1))
  par(ps = 14, cex = 2, cex.main = 3.5,cex.sub=2.2, cex.lab=2.8, cex.axis = 2.2, mai=c(0.3,1.8,0.5,0.5))
  #
  # -------------------------------------------------------------------------------------------
  # Creating the plotting matrix
  #
  m <- rbind(c(1, 1), c(2, 2), c(3, 3), c(4, 4), c(5, 5), c(6, 6), c(7, 8))
  layout(m)
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting NO2
  #
  plot(ylim=c(-0.15,max(NO2_mensile$no2)+0.175),
       xlim = c(min(c(NOX_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date)),
                max(c(NOX_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date))),
       mgp = c(8, 4, 0),
       NO2_mensile$date, NO2_mensile$no2, type = "h",
       xlab = "",ylab =bquote(paste("NO"[2], " (nmol/mol) - L02")), col="lightblue", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
  title(bquote(bold(paste("NO"[2], " - L02 - ",.(questo_anno)," ",.(NO2_This_Month_Name)))), line = -3)
  lines(NO2_mensile$date, NO2_mensile$no2, type = "l", lty = 1, col="darkred",lwd = 2)
  
  points(NO2_men_MAX$date[1], NO2_men_MAX$no2[1], col= "magenta",pch=20)
  text(NO2_men_MAX$date[1], NO2_men_MIN$no2[1], labels = paste("Max (", format(NO2_men_MAX$date[1],"%B %d"), ")", sep=""),col="magenta",pos=1,cex = 1.8)
  segments(NO2_men_MAX$date[1], NO2_men_MAX$no2[1], NO2_men_MAX$date[1],NO2_men_MIN$no2[1]-0.3, lty = 2, col="black",lwd = 1)
  
  points(NO2_men_MIN$date[1], NO2_men_MIN$no2[1], col= "blue",pch=20)
  text(NO2_men_MIN$date[1], NO2_men_MIN$no2[1], labels = paste("Min (", format(NO2_men_MIN$date[1],"%B %d"), ")", sep =""),col="blue",pos=1,cex = 1.8)
  segments(NO2_men_MIN$date[1], NO2_men_MIN$no2[1], NO2_men_MIN$date[1], NO2_men_MIN$no2[1]-0.3, lty = 2, col="black",lwd = 1)
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting NUMFLAG (L01)
  #
  plot(ylim=c(0,1.1),
       xlim = c(min(c(NOX_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date)),
                max(c(NOX_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date))),
       mgp = c(8, 4, 0),
       temp_L01_ThisMonth$date, temp_L01_ThisMonth$numflag_NO2, type = "h",
       xlab = "",ylab =("numflag - L01"), col="tan", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
  title(paste("numflag - L01 -",questo_anno,NO2_This_Month_Name), line = -3)
  lines(temp_L01_ThisMonth$date, temp_L01_ThisMonth$numflag_NO2, type = "l",
        lty = 1,
        col = "lightgreen",
        lwd = 2)
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting Flow_A e Flow_B
  #
  temp_L00_ThisMonth$NO2[temp_L00_ThisMonth$NO2 > max(NO2_mensile$no2)] <-max(NO2_mensile$no2)+0.1
  
  plot(ylim=c(-0.15,max(NO2_mensile$no2)+0.175),
       xlim = c(min(c(NOX_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date)),
                max(c(NOX_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date))),
       mgp = c(8, 4, 0),
       temp_L00_ThisMonth$date, temp_L00_ThisMonth$NO2, type = "h",
       xlab = "",ylab =bquote(paste("NO"[2], " (nmol/mol) - inst vs L02")), col="cadetblue2", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
  
  title(bquote(bold(paste("NO"[2], " (from instrument) vs ","NO"[2], " (L02) - ",.(questo_anno)," ",.(NO2_This_Month_Name)))), line = -3)
  
  title(bquote(paste("NO"[2], " (inst) values higher than ",.(round(max(NO2_mensile$no2+0.5),1)), " are out of scale and are rappresented as ", .(round(max(NO2_mensile$no2)+0.5,2))))
        ,col="black",cex.main = 2.6, line = -7, font.main = 1)
  
  lines(NO2_mensile$date, NO2_mensile$no2, type = "l", lty = 1, col="darkred",lwd = 2)
  
  legend("topleft", legend=c("NO2 (inst)","NO2 (L02)"), lty=c(1,1), lwd = c(2,2), col=c("steelblue2","darkred"), cex = 3)
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting Flow Sample and Pre
  #
  xx    <- c(temp_L00_ThisMonth$date, rev(temp_L00_ThisMonth$date))
  yy_PR <- c(rep(0, nrow(temp_L00_ThisMonth)), rev(temp_L00_ThisMonth$Pre))
  yy_FS <- c(rep(0, nrow(temp_L00_ThisMonth)), rev(temp_L00_ThisMonth$Flow_sample))  
  yy_PC <- c(rep(0, nrow(temp_L00_ThisMonth)), rev(temp_L00_ThisMonth$P_chamb))
  yy_TC <- c(rep(0, nrow(temp_L00_ThisMonth)), rev(temp_L00_ThisMonth$T_Cooler))
  yy_PM <- c(rep(0, nrow(temp_L00_ThisMonth)), rev(temp_L00_ThisMonth$PMT_V)) 
  #
  plot(ylim=c(-0.1,2),
       xlim = c(min(c(NOX_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date)),
                max(c(NOX_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date))),
       mgp = c(8, 4, 0),
       temp_L00_ThisMonth$date, temp_L00_ThisMonth$Flow_sample, type = "n",
       xlab = "",ylab =("Flow_sample & Pre - inst"), col="cadetblue2", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
  
  title(paste("Flow_sample and Pre - from instrument -",questo_anno,NO2_This_Month_Name), line = -3)
  #
  # Flow sample
  polygon(xx, yy_FS, col='rosybrown1',border = "indianred3")
  #  
  # Pre
  #  
  polygon(xx, yy_PR, col='indianred1',border = "tomato4")
  #  
  legend("topleft", legend=c("Flow_sample","Pre"), lty=c(1,1), lwd = c(2,2), col=c("indianred3","tomato4"), cex = 3)
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting P_chamb e T_Cooler
  #
  plot(ylim=c(-100,400),
       xlim = c(min(c(NOX_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date)),
                max(c(NOX_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date))),
       mgp = c(8, 4, 0),
       temp_L00_ThisMonth$date, temp_L00_ThisMonth$P_chamb, type = "h",
       xlab = "",ylab =("P_chamb & T_Cooler - inst"), col="palegreen", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
  
  title(paste("P_chamb and T_Cooler - from instrument -",questo_anno,NO2_This_Month_Name), line = -3)
  #
  # P_chamb
  lines(temp_L00_ThisMonth$date, temp_L00_ThisMonth$P_chamb, type = "l", lty = 1, col="palegreen4",lwd = 2)
  #  
  # T_Cooler
  polygon(xx, yy_TC, col='seagreen1',border = "purple4",lwd = 2)
  # 
  legend("topleft", legend=c("P_chamb","T_Cooler"), lty=c(1,1), lwd = c(2,2), col=c("palegreen","purple4"), cex = 3)
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting PMT_V
  #
  plot(ylim=c(-1100,-1150),
       xlim = c(min(c(NOX_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date)),
                max(c(NOX_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date))),
       mgp = c(8, 4, 0),
       temp_L00_ThisMonth$date, temp_L00_ThisMonth$PMT_V, type = "h",
       xlab = "",ylab =("PMT_V - inst"), col="lightskyblue2", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
  
  title(paste("PMT_V - from instrument -",questo_anno,NO2_This_Month_Name), line = -3)
  
  lines(temp_L00_ThisMonth$date, temp_L00_ThisMonth$PMT_V, type = "l", lty = 1, col="royalblue",lwd = 2.5)
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting Text
  #
  plot(c(0, 1), c(0, 1), ann = F, bty = 'n', type = 'n', xaxt = 'n', yaxt = 'n')
  text(x = 0, y = 0.95, paste (PLOT_M_NAME,"  -  ",NO2_This_Month_Name," ",questo_anno),
       cex = 3.3, col = "darkred",pos = 4)
  
  text(x = -0.005, y = 0.75, paste(" Observations from", OBS_Month_start," to ", OBS_Month_end,
                                   "\n",
                                   "(days of observation: ", 1+(as.integer(tail((NO2_mensile$date),1)-head((NO2_mensile$date)),1)),")")
       , cex = 2.8, col = "black",pos = 4)
  
  plot(c(0, 1), c(0, 1), ann = F, bty = 'n', type = 'n', xaxt = 'n', yaxt = 'n')
  text(x = 0, y = 0.95, paste ("Statistics  -  ",NO2_This_Month_Name," ",questo_anno),
       cex = 3.3, col = "darkred",pos = 4)
  
  text(x = 0, y = 0.55, paste("\n", "NO2 min: (", round(min(NO2_mensile$no2),2),") - NO2 max: (", round(max(NO2_mensile$no2),2),") - NO2 mean: (", round(mean(NO2_mensile$no2),2),") - NO2 sd: (", round(sd(NO2_mensile$no2),2),")","\n",
                              "NO2 percentile:    5th: (",round(quantile(NO2_mensile$no2, probs = c(0.05)),digits=2),")",
                              " - 25th: (",round(quantile(NO2_mensile$no2, probs = c(0.25)),digits=2),")",
                              " - 50th: (",round(quantile(NO2_mensile$no2, probs = c(0.50)),digits=2),")",
                              " - 75th: (",round(quantile(NO2_mensile$no2, probs = c(0.75)),digits=2),")",
                              " - 95th: (",round(quantile(NO2_mensile$no2, probs = c(0.95)),digits=2),")","\n","\n",
                              "L02 numflag = 0.999 (number of days affected):   ", FAIL_DAYS,
                              " (",round((FAIL_DAYS/days_in_month(temp_L02_ThisMonth$date[1]))*100,digits=2),"%)",
                              "\n",
                              "Days of ",NO2_This_Month_Name," affected:","\n",
                              if (FAIL_DAYS==0){"none"},
                              if (!is.na(FAIL_unico$day[1])){FAIL_unico$day[1]} ,"   ",
                              if (!is.na(FAIL_unico$day[2])){FAIL_unico$day[2]} ,"   ",                              
                              if (!is.na(FAIL_unico$day[3])){FAIL_unico$day[3]} ,"   ",                              
                              if (!is.na(FAIL_unico$day[4])){FAIL_unico$day[4]} ,"   ",
                              if (!is.na(FAIL_unico$day[5])){FAIL_unico$day[5]} ,"   ",                              
                              if (!is.na(FAIL_unico$day[6])){FAIL_unico$day[6]} ,"   ",                              
                              if (!is.na(FAIL_unico$day[7])){FAIL_unico$day[7]} ,"   ",                              
                              if (!is.na(FAIL_unico$day[8])){FAIL_unico$day[8]} ,"   ",
                              if (!is.na(FAIL_unico$day[9])){FAIL_unico$day[9]} ,"   ",                              
                              if (!is.na(FAIL_unico$day[10])){FAIL_unico$day[10]} ,"   ",  
                              if (!is.na(FAIL_unico$day[11])){FAIL_unico$day[11]} ,"   ",
                              if (!is.na(FAIL_unico$day[12])){FAIL_unico$day[12]} ,"   ",                              
                              if (!is.na(FAIL_unico$day[13])){FAIL_unico$day[13]} ,"   ",                              
                              if (!is.na(FAIL_unico$day[14])){FAIL_unico$day[14]} ,"   ",
                              if (!is.na(FAIL_unico$day[15])){FAIL_unico$day[15]} ,"   ",
                              "\n",
                              if (!is.na(FAIL_unico$day[16])){FAIL_unico$day[16]} ,"   ",                              
                              if (!is.na(FAIL_unico$day[17])){FAIL_unico$day[17]} ,"   ",                              
                              if (!is.na(FAIL_unico$day[18])){FAIL_unico$day[18]} ,"   ",
                              if (!is.na(FAIL_unico$day[19])){FAIL_unico$day[19]} ,"   ",                              
                              if (!is.na(FAIL_unico$day[20])){FAIL_unico$day[20]} ,"   ",                                
                              if (!is.na(FAIL_unico$day[21])){FAIL_unico$day[21]} ,"   ",
                              if (!is.na(FAIL_unico$day[22])){FAIL_unico$day[22]} ,"   ",                              
                              if (!is.na(FAIL_unico$day[23])){FAIL_unico$day[23]} ,"   ",                              
                              if (!is.na(FAIL_unico$day[24])){FAIL_unico$day[24]} ,"   ",
                              if (!is.na(FAIL_unico$day[25])){FAIL_unico$day[25]} ,"   ",                              
                              if (!is.na(FAIL_unico$day[26])){FAIL_unico$day[26]} ,"   ",                              
                              if (!is.na(FAIL_unico$day[27])){FAIL_unico$day[27]} ,"   ",                              
                              if (!is.na(FAIL_unico$day[28])){FAIL_unico$day[28]} ,"   ",
                              if (!is.na(FAIL_unico$day[29])){FAIL_unico$day[29]} ,"   ",                              
                              if (!is.na(FAIL_unico$day[30])){FAIL_unico$day[30]} ,"   ",                                 
                              if (!is.na(FAIL_unico$day[31])){FAIL_unico$day[31]} ,"   ",                              
                              sep=""),
       cex = 2.8, col = "black",pos = 4)
  
  dev.off()
}
#
# -------------------------------------------------------------------------------------------
##                                        # END PART 3.0.1 #
###########################################################################################################################

###########################################################################################################################
##                                           # PART 3.1 #
## ______________________________________________________________________________________________________________________##
##                                    Creating statistcs/graphic reports
##                                               NO SEMESTER GRAPHS
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Subsetting data by semester
# First semester
#
Fhalf           <-subset(NOX_L02_today_Y,monthNum<7)

if (nrow(Fhalf)==0){ } else 
{
  # -------------------------------------------------------------------------------------------
  # Cleaning Destination directory
  # 
  FILE_PLOT_1HM<-list.files(path = PLOT_DIR_M, pattern = paste(s_GAW_ID, "NO",questo_anno,"SEMESTER_1st_GRAPH_*",sep = "_"), all.files = FALSE,
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
  png(file=paste(PLOT_DIR_M,paste(s_GAW_ID,"_","NO","_",questo_anno,"_SEMESTER_1st_GRAPH_",gsub("-","",Sys.Date()),".png",sep = ""),sep = "/"),
      width = 2480, height = 3508)
  #
  # -------------------------------------------------------------------------------------------
  # Creating the plotting matrix
  #
  layout(matrix(c(1,2,3,4,5,6,7),ncol=1), widths=c(10,10,10,10,10,10,10), heights=c(2.2,2.2,2.2,2.2,2.2,2.2,0.2), TRUE) 
  par(ps = 12, cex = 1.8, cex.main = 1.8,cex.sub=1.8, cex.lab=1.8, cex.axis = 1.5, mai=c(0.3,1.8,0.5,0.5))  # make labels and margins smaller (mai= giu, sx,su,dx)
  
  for (i in unico[1:length(unico)])
  {
    print(i)
    mensile            <-subset(NOX_L02_today_Y, month == i & numflag_no != 0.999000000)
    mensile$giorno     <-format(mensile$date,"%d")
    mensile$mean          <-mean(mensile$no)
    mensile$sd            <-sd(mensile$no)    
    men_MIN               <-subset(mensile, no == min(mensile$no))
    men_MAX               <-subset(mensile, no == max(mensile$no))
    {
      plot(ylim=c(-0.17,men_MAX$no[1]+0.05),
           mensile$date, mensile$no, type = "h",
           xlab = "",
           ylab ="NO (nmol/mol) - L02", 
           col="lightblue", 
           panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
      title(main=paste(i,questo_anno,sep=" "), 
            line = -2.2)
      
      title(paste("Statistics: min: (", round(min(mensile$no),2),") - max: (", round(max(mensile$no),2),") - mean: (", round(mean(mensile$no),2),") - sd: (", round(sd(mensile$no),2),")")
            ,col="black",cex.main = 1.2, line = -3.8, font.main = 1)
      
      lines(mensile$date, mensile$no, type = "l", lty = 1, col="darkred",lwd = 2)
      
      points(men_MAX$date[1], men_MAX$no[1], col= "magenta",pch=20)
      text(men_MAX$date[1], men_MIN$no[1] , labels = paste("Max (",format(men_MAX$date[1],"%B %d"),")",sep=""),col="magenta",pos=1)
      segments(men_MAX$date[1], men_MAX$no[1], men_MAX$date[1], -1, lty = 2, col="black",lwd = 1)

      points(men_MIN$date[1], men_MIN$no[1], col= "blue",pch=20)
      text(men_MIN$date[1], men_MIN$no[1] , labels = paste("Min (",format(men_MIN$date[1],"%B %d"),")",sep=""),col="blue",pos=1)
      segments(men_MIN$date[1], men_MIN$no[1], men_MIN$date[1], -1, lty = 2, col="black",lwd = 1)
    }   
  }
  dev.off() 
}
#
# -------------------------------------------------------------------------------------------
# Subsetting data by semester
# Second semester
#
Shalf<-subset(NOX_L02_today_Y,monthNum>6)
if (nrow(Shalf)==0){}else 
{
  # -------------------------------------------------------------------------------------------
  # Cleaning Destination directory
  # 
  FILE_PLOT_2HM<-list.files(path = PLOT_DIR_M, pattern = paste(s_GAW_ID, "NO",questo_anno,"SEMESTER_2nd_GRAPH_*",sep = "_"), all.files = FALSE,
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
  png(file=paste(PLOT_DIR_M,paste(s_GAW_ID,"_","NO","_",questo_anno,"_SEMESTER_2nd_GRAPH_",gsub("-","",Sys.Date()),".png",sep = ""),sep = "/"),
      width = 2480, height = 3508)
  #
  # -------------------------------------------------------------------------------------------
  # Creating the plotting matrix
  #
  layout(matrix(c(1,2,3,4,5,6,7),ncol=1), widths=c(10,10,10,10,10,10,10), heights=c(2.2,2.2,2.2,2.2,2.2,2.2,0.2), TRUE) 
  par(ps = 12, cex = 1.8, cex.main = 1.8,cex.sub=1.8, cex.lab=1.8, cex.axis = 1.5, mai=c(0.3,1.8,0.5,0.5))  # make labels and margins smaller (mai= giu, sx,su,dx)
  
  for (i in unico[1:length(unico)])
  {
    print(i)
    mensile            <-subset(NOX_L02_today_Y, month == i & numflag_no != 0.999000000)
    mensile$giorno     <-format(mensile$date,"%d")
    mensile$mean       <-mean(mensile$no)
    mensile$sd         <-sd(mensile$no)    
    men_MIN            <-subset(mensile, no == min(mensile$no))
    men_MAX            <-subset(mensile, no == max(mensile$no))
    {
      plot(ylim=c(-0.17,men_MAX$no[1]+0.05),
           mensile$date, mensile$no, type = "h",
           xlab = "",
           ylab ="NO (nmol/mol) - L02", 
           col="lightblue", 
           panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
      title(main=paste(i,questo_anno,sep=" "), 
            line = -2.2)
          
      title(paste("Statistics: min: (", round(min(mensile$no),2),") - max: (", round(max(mensile$no),2),") - mean: (", round(mean(mensile$no),2),") - sd: (", round(sd(mensile$no),2),")")
            ,col="black",cex.main = 1.2, line = -3.8, font.main = 1)
      
      lines(mensile$date, mensile$no, type = "l", lty = 1, col="darkred",lwd = 2)
      
      points(men_MAX$date[1], men_MAX$no[1], col= "magenta",pch=20)
      text(men_MAX$date[1], men_MIN$no[1] , labels = paste("Max (",format(men_MAX$date[1],"%B %d"),")",sep=""),col="magenta",pos=1)
      segments(men_MAX$date[1], men_MAX$no[1], men_MAX$date[1], -1, lty = 2, col="black",lwd = 1)
      
      points(men_MIN$date[1], men_MIN$no[1], col= "blue",pch=20)
      text(men_MIN$date[1], men_MIN$no[1] , labels = paste("Min (",format(men_MIN$date[1],"%B %d"),")",sep=""),col="blue",pos=1)
      segments(men_MIN$date[1], men_MIN$no[1], men_MIN$date[1], -1, lty = 2, col="black",lwd = 1)
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
##                                               NO2 SEMESTER GRAPHS
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Subsetting data by semester
# First semester
#
Fhalf           <-subset(NOX_L02_today_Y,monthNum<7)

if (nrow(Fhalf)==0){ } else 
{
  # -------------------------------------------------------------------------------------------
  # Cleaning Destination directory
  # 
  FILE_PLOT_1HM<-list.files(path = PLOT_DIR_M, pattern = paste(s_GAW_ID, "NO2",questo_anno,"SEMESTER_1st_GRAPH_*",sep = "_"), all.files = FALSE,
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
  png(file=paste(PLOT_DIR_M,paste(s_GAW_ID,"_","NO2","_",questo_anno,"_SEMESTER_1st_GRAPH_",gsub("-","",Sys.Date()),".png",sep = ""),sep = "/"),
      width = 2480, height = 3508)
  #
  # -------------------------------------------------------------------------------------------
  # Creating the plotting matrix
  #
  layout(matrix(c(1,2,3,4,5,6,7),ncol=1), widths=c(10,10,10,10,10,10,10), heights=c(2.2,2.2,2.2,2.2,2.2,2.2,0.2), TRUE) 
  par(ps = 12, cex = 1.8, cex.main = 1.8,cex.sub=1.8, cex.lab=1.8, cex.axis = 1.5, mai=c(0.3,1.8,0.5,0.5))  # make labels and margins smaller (mai= giu, sx,su,dx)
  
  for (i in unico[1:length(unico)])
  {
    print(i)
    mensile            <-subset(NOX_L02_today_Y, month == i & numflag_no2 != 0.999000000)
    mensile$giorno     <-format(mensile$date,"%d")
    mensile$mean          <-mean(mensile$no2)
    mensile$sd            <-sd(mensile$no)    
    men_MIN               <-subset(mensile, no2 == min(mensile$no2))
    men_MAX               <-subset(mensile, no2 == max(mensile$no2))
    {
      plot(ylim=c(-0.17,men_MAX$no2[1]+0.05),
           mensile$date, mensile$no2, type = "h",
           xlab = "",
           ylab =bquote(paste("NO"[2], " (nmol/mol) - L02")), 
           col="lightblue", 
           panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
      title(main=paste(i,questo_anno,sep=" "), 
            line = -2.2)
      
      title(paste("Statistics: min: (", round(min(mensile$no2),2),") - max: (", round(max(mensile$no2),2),") - mean: (", round(mean(mensile$no2),2),") - sd: (", round(sd(mensile$no2),2),")")
            ,col="black",cex.main = 1.2, line = -3.8, font.main = 1)
      
      lines(mensile$date, mensile$no2, type = "l", lty = 1, col="darkred",lwd = 2)
      
      points(men_MAX$date[1], men_MAX$no2[1], col= "magenta",pch=20)
      text(men_MAX$date[1], men_MIN$no2[1] , labels = paste("Max (",format(men_MAX$date[1],"%B %d"),")",sep=""),col="magenta",pos=1)
      segments(men_MAX$date[1], men_MAX$no2[1], men_MAX$date[1], -1, lty = 2, col="black",lwd = 1)
      
      points(men_MIN$date[1], men_MIN$no2[1], col= "blue",pch=20)
      text(men_MIN$date[1], men_MIN$no2[1] , labels = paste("Min (",format(men_MIN$date[1],"%B %d"),")",sep=""),col="blue",pos=1)
      segments(men_MIN$date[1], men_MIN$no2[1], men_MIN$date[1], -1, lty = 2, col="black",lwd = 1)
    }   
  }
  dev.off() 
}
#
# -------------------------------------------------------------------------------------------
# Subsetting data by semester
# Second semester
#
Shalf<-subset(NOX_L02_today_Y,monthNum>6)
if (nrow(Shalf)==0){}else 
{
  # -------------------------------------------------------------------------------------------
  # Cleaning Destination directory
  # 
  FILE_PLOT_2HM<-list.files(path = PLOT_DIR_M, pattern = paste(s_GAW_ID, "NO2",questo_anno,"SEMESTER_2nd_GRAPH_*",sep = "_"), all.files = FALSE,
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
  png(file=paste(PLOT_DIR_M,paste(s_GAW_ID,"_","NO2","_",questo_anno,"_SEMESTER_2nd_GRAPH_",gsub("-","",Sys.Date()),".png",sep = ""),sep = "/"),
      width = 2480, height = 3508)
  #
  # -------------------------------------------------------------------------------------------
  # Creating the plotting matrix
  #
  layout(matrix(c(1,2,3,4,5,6,7),ncol=1), widths=c(10,10,10,10,10,10,10), heights=c(2.2,2.2,2.2,2.2,2.2,2.2,0.2), TRUE) 
  par(ps = 12, cex = 1.8, cex.main = 1.8,cex.sub=1.8, cex.lab=1.8, cex.axis = 1.5, mai=c(0.3,1.8,0.5,0.5))  # make labels and margins smaller (mai= giu, sx,su,dx)
  
  for (i in unico[1:length(unico)])
  {
    print(i)
    mensile            <-subset(NOX_L02_today_Y, month == i & numflag_no2 != 0.999000000)
    mensile$giorno     <-format(mensile$date,"%d")
    mensile$mean       <-mean(mensile$no2)
    mensile$sd         <-sd(mensile$no2)    
    men_MIN            <-subset(mensile, no2 == min(mensile$no2))
    men_MAX            <-subset(mensile, no2 == max(mensile$no2))
    {
      plot(ylim=c(-0.17,men_MAX$no2[1]+0.05),
           mensile$date, mensile$no2, type = "h",
           xlab = "",
           ylab =bquote(paste("NO"[2], " (nmol/mol) - L02")), 
           col="lightblue", 
           panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
      title(main=paste(i,questo_anno,sep=" "), 
            line = -2.2)
      
      title(paste("Statistics: min: (", round(min(mensile$no2),2),") - max: (", round(max(mensile$no2),2),") - mean: (", round(mean(mensile$no2),2),") - sd: (", round(sd(mensile$no2),2),")")
            ,col="black",cex.main = 1.2, line = -3.8, font.main = 1)
      
      lines(mensile$date, mensile$no2, type = "l", lty = 1, col="darkred",lwd = 2)
      
      points(men_MAX$date[1], men_MAX$no2[1], col= "magenta",pch=20)
      text(men_MAX$date[1], men_MIN$no2[1] , labels = paste("Max (",format(men_MAX$date[1],"%B %d"),")",sep=""),col="magenta",pos=1)
      segments(men_MAX$date[1], men_MAX$no2[1], men_MAX$date[1], -1, lty = 2, col="black",lwd = 1)
      
      points(men_MIN$date[1], men_MIN$no2[1], col= "blue",pch=20)
      text(men_MIN$date[1], men_MIN$no2[1] , labels = paste("Min (",format(men_MIN$date[1],"%B %d"),")",sep=""),col="blue",pos=1)
      segments(men_MIN$date[1], men_MIN$no2[1], men_MIN$date[1], -1, lty = 2, col="black",lwd = 1)
    }   
  }
  dev.off() 
}
#
# -------------------------------------------------------------------------------------------
##                                        # END PART 3.1.1 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.2 #
## ______________________________________________________________________________________________________________________##
##                                    Creating statistcs/graphic reports
##                                               NO SEASONAL GRAPHS
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# -------------------------------------------------------------------------------------------
# Cleaning Destination directory
# 
FILE_PLOT_S         <-list.files(path = PLOT_DIR_S, pattern = paste(s_GAW_ID, inst_type,questo_anno,"SEASONAL_GRAPH_*",sep = "_"), 
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
NOX_L02_today_Y$season[NOX_L02_today_Y$monthNum>=1  & NOX_L02_today_Y$monthNum<=3]     <- 1
NOX_L02_today_Y$season[NOX_L02_today_Y$monthNum>=4  & NOX_L02_today_Y$monthNum<=6]     <- 2
NOX_L02_today_Y$season[NOX_L02_today_Y$monthNum>=7  & NOX_L02_today_Y$monthNum<=9]     <- 3
NOX_L02_today_Y$season[NOX_L02_today_Y$monthNum>=10 & NOX_L02_today_Y$monthNum<=12]    <- 4
#
# -------------------------------------------------------------------------------------------
# Creating temporary season tables (Level-2)
#
temp_L02$season[as.integer(temp_L02$monthNum)>=1    & as.integer(temp_L02$monthNum)<=3]   <- 1
temp_L02$season[as.integer(temp_L02$monthNum)>=4    & as.integer(temp_L02$monthNum)<=6]   <- 2
temp_L02$season[as.integer(temp_L02$monthNum)>=7    & as.integer(temp_L02$monthNum)<=9]   <- 3
temp_L02$season[as.integer(temp_L02$monthNum)>=10   & as.integer(temp_L02$monthNum)<=12]  <- 4

temp_L00$season[as.integer(temp_L00$monthNum)>=1    & as.integer(temp_L00$monthNum)<=3]   <- 1
temp_L00$season[as.integer(temp_L00$monthNum)>=4    & as.integer(temp_L00$monthNum)<=6]   <- 2
temp_L00$season[as.integer(temp_L00$monthNum)>=7    & as.integer(temp_L00$monthNum)<=9]   <- 3
temp_L00$season[as.integer(temp_L00$monthNum)>=10   & as.integer(temp_L00$monthNum)<=12]  <- 4

seasons<-c(NOX_L02_today_Y[!duplicated(NOX_L02_today_Y[,c('season')]),]$season)
seasons 
# -------------------------------------------------------------------------------------------
# Preparing plotting files
#  
PLOT_S_NAME         <-paste(s_GAW_ID,"NO",questo_anno,"SEASONAL_GRAPH",gsub("-","",Sys.Date()),sep = "_")
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
  
  NOX_L02_stg       <-subset(NOX_L02_today_Y, season == stg)
  temp_L02_stg      <-subset(temp_L02, season == stg)
  temp_L00_stg      <-subset(temp_L00, season == stg)
  
  OBS_stg_start     <-head(format(temp_L02_stg$date,"%d %B %Y"),1)
  OBS_stg_end       <-tail(format(temp_L02_stg$date,"%d %B %Y"),1)
  
  FAIL_stg          <-subset(temp_L02_stg, numflag_no == 0.999)
  FAIL_stg$day      <-format(FAIL_stg$date,"%d")
  FAIL_unico        <-data.frame(FAIL_stg[!duplicated(FAIL_stg[,c('day')]),])
  FAIL_DAYS         <-nrow(FAIL_unico)
  
  stagionale<-subset(NOX_L02_stg, numflag_no != 0.999)
  stagionale$giorno <- format(stagionale$date,"%d")
  This_stg <- c(format(stagionale$date,"%m"))
  This_stg_Name <- c(format(stagionale$date,"%B"))
  print(paste("ora il ",This_stg_Name[1], FAIL_DAYS))
  
  stagionale$mean      <- mean(stagionale$no)
  stagionale$sd        <- sd(stagionale$no)
  stg_MIN              <- subset(stagionale, no == min(stagionale$no))
  stg_MAX              <- subset(stagionale, no == max(stagionale$no))
  
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting NO
  #
  plot(ylim=c(stg_MIN$no-0.017,stg_MAX$no[1]+0.15),
       stagionale$date, stagionale$no, type = "h",
       mgp = c(7, 3, 0),
       xlab = "",ylab ="NO (nmol/mol) - L02", 
       col="lightblue", 
       panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 0.5))
  lines(stagionale$date, stagionale$no, type = "l", lty = 1, col="darkred",lwd = 2)
  title(main=paste("NO - L02 -",questo_anno,"   ",stg_name), line = -4.5)
  
  mtext(paste("Observations from", OBS_stg_start," to ", 
              OBS_stg_end,"(",1+(as.integer(tail((NOX_L02_stg$date),1)-head((NOX_L02_stg$date)),1))," days)       -       Statistics: ","  NO min: (", min(stagionale$no),") - NO max: (", max(stagionale$no),") - NO mean: (", round(mean(stagionale$no),2),") - NO sd: (", round(sd(stagionale$no),2),")"),
                     col="black",cex = 1.7, line = -8.0, font.main = 1)
  
  points(stg_MAX$date[1], stg_MAX$no[1], col= "magenta",pch=20)
  segments(stg_MAX$date[1], stg_MAX$no[1], stg_MAX$date[1], stg_MIN$no[1]-0.18, lty = 2, col="black",lwd = 1)
  text(stg_MAX$date[1], stg_MIN$no[1], labels = paste("Max","(",(format(stg_MAX$date[1],"%B %d")),")"),
       col="magenta",
       pos=1,
       cex = 1.6)
  
  points(stg_MIN$date[1], stg_MIN$no[1], col= "blue",pch=20)
  segments(stg_MIN$date[1], stg_MIN$no[1], stg_MIN$date[1], stg_MIN$no[1]-0.18, lty = 2, col="black",lwd = 1)
  text(stg_MIN$date[1], stg_MIN$no[1], labels = paste("Min","(",(format(stg_MIN$date[1],"%B %d")),")"),
       col="blue",
       pos=1,
       cex = 1.7) 
  # 
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting HISTOGRAMS
  #
  hist(stagionale$no,xlab="", 
       ylab="Relative frequency",
       main="", 
       mgp = c(7, 3, 0),
       col = "mediumaquamarine", 
       border="darkred",lwd = 2)
  
  d <- density(stagionale$no)
  plot(d,xlab="", 
       ylab="Density",
       main="",
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
##                                               NO2 SEASONAL GRAPHS
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# -------------------------------------------------------------------------------------------
# Cleaning Destination directory 
# 
FILE_PLOT_S         <-list.files(path = PLOT_DIR_S, pattern = paste(s_GAW_ID, inst_type,questo_anno,"SEASONAL_GRAPH_*",sep = "_"), 
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
NOX_L02_today_Y$season[NOX_L02_today_Y$monthNum>=1  & NOX_L02_today_Y$monthNum<=3]     <- 1
NOX_L02_today_Y$season[NOX_L02_today_Y$monthNum>=4  & NOX_L02_today_Y$monthNum<=6]     <- 2
NOX_L02_today_Y$season[NOX_L02_today_Y$monthNum>=7  & NOX_L02_today_Y$monthNum<=9]     <- 3
NOX_L02_today_Y$season[NOX_L02_today_Y$monthNum>=10 & NOX_L02_today_Y$monthNum<=12]    <- 4
#
# -------------------------------------------------------------------------------------------
# Creating temporary season tables (Level-2)
# 
temp_L02$season[as.integer(temp_L02$monthNum)>=1    & as.integer(temp_L02$monthNum)<=3]   <- 1
temp_L02$season[as.integer(temp_L02$monthNum)>=4    & as.integer(temp_L02$monthNum)<=6]   <- 2
temp_L02$season[as.integer(temp_L02$monthNum)>=7    & as.integer(temp_L02$monthNum)<=9]   <- 3
temp_L02$season[as.integer(temp_L02$monthNum)>=10   & as.integer(temp_L02$monthNum)<=12]  <- 4

temp_L00$season[as.integer(temp_L00$monthNum)>=1    & as.integer(temp_L00$monthNum)<=3]   <- 1
temp_L00$season[as.integer(temp_L00$monthNum)>=4    & as.integer(temp_L00$monthNum)<=6]   <- 2
temp_L00$season[as.integer(temp_L00$monthNum)>=7    & as.integer(temp_L00$monthNum)<=9]   <- 3
temp_L00$season[as.integer(temp_L00$monthNum)>=10   & as.integer(temp_L00$monthNum)<=12]  <- 4

seasons<-c(NOX_L02_today_Y[!duplicated(NOX_L02_today_Y[,c('season')]),]$season)
seasons 
# -------------------------------------------------------------------------------------------
# Preparing plotting files
#  
PLOT_S_NAME         <-paste(s_GAW_ID,"NO2",questo_anno,"SEASONAL_GRAPH",gsub("-","",Sys.Date()),sep = "_")
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
  
  NOX_L02_stg       <-subset(NOX_L02_today_Y, season == stg)
  temp_L02_stg      <-subset(temp_L02, season == stg)
  temp_L00_stg      <-subset(temp_L00, season == stg)
  
  OBS_stg_start     <-head(format(temp_L02_stg$date,"%d %B %Y"),1)
  OBS_stg_end       <-tail(format(temp_L02_stg$date,"%d %B %Y"),1)
  
  FAIL_stg          <-subset(temp_L02_stg, numflag_no2 == 0.999)
  FAIL_stg$day      <-format(FAIL_stg$date,"%d")
  FAIL_unico        <-data.frame(FAIL_stg[!duplicated(FAIL_stg[,c('day')]),])
  FAIL_DAYS         <-nrow(FAIL_unico)
  
  stagionale<-subset(NOX_L02_stg, numflag_no2 != 0.999)
  stagionale$giorno <- format(stagionale$date,"%d")
  This_stg <- c(format(stagionale$date,"%m"))
  This_stg_Name <- c(format(stagionale$date,"%B"))
  print(paste("ora il ",This_stg_Name[1], FAIL_DAYS))
  
  stagionale$mean      <- mean(stagionale$no2)
  stagionale$sd        <- sd(stagionale$no2)
  stg_MIN              <- subset(stagionale, no2 == min(stagionale$no2))
  stg_MAX              <- subset(stagionale, no2 == max(stagionale$no2))
  
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting NO2
  #
  plot(ylim=c(-0.17,stg_MAX$no2[1]+0.3),
       stagionale$date, stagionale$no2, type = "h",
       mgp = c(7, 3, 0),
       xlab = "",ylab =bquote(paste("NO"[2], " (nmol/mol) - L02")), 
       col="lightblue", 
       panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 0.5))
  lines(stagionale$date, stagionale$no2, type = "l", lty = 1, col="darkred",lwd = 2)
  title(main=paste("NO2 - L02 -",questo_anno,"   ",stg_name), line = -4.5)
  
  mtext(paste("Observations from", OBS_stg_start," to ", 
              OBS_stg_end,"(",1+(as.integer(tail((NOX_L02_stg$date),1)-head((NOX_L02_stg$date)),1))," days)       -       Statistics: ","  NO2 min: (", min(stagionale$no2),") - NO2 max: (", max(stagionale$no),") - NO2 mean: (", round(mean(stagionale$no2),2),") - NO2 sd: (", round(sd(stagionale$no2),2),")"),
        col="black",cex = 1.7, line = -8.0, font.main = 1)
  
  points(stg_MAX$date[1], stg_MAX$no2[1], col= "magenta",pch=20)
  segments(stg_MAX$date[1], stg_MAX$no2[1], stg_MAX$date[1], stg_MIN$no2[1]-0.18, lty = 2, col="black",lwd = 1)
  text(stg_MAX$date[1], stg_MIN$no2[1], labels = paste("Max","(",(format(stg_MAX$date[1],"%B %d")),")"),
       col="magenta",
       pos=1,
       cex = 1.6)
  
  points(stg_MIN$date[1], stg_MIN$no2[1], col= "blue",pch=20)
  segments(stg_MIN$date[1], stg_MIN$no2[1], stg_MIN$date[1], stg_MIN$no2[1]-0.18, lty = 2, col="black",lwd = 1)
  text(stg_MIN$date[1], stg_MIN$no2[1], labels = paste("Min","(",(format(stg_MIN$date[1],"%B %d")),")"),
       col="blue",
       pos=1,
       cex = 1.7)
  # 
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting HISTOGRAMS
  #
  hist(stagionale$no2,xlab="", 
       ylab="Relative frequency",
       main="", 
       mgp = c(7, 3, 0),
       col = "mediumaquamarine", 
       border="darkred",lwd = 2)
  
  d <- density(stagionale$no2)
  plot(d,xlab="", 
       ylab="Density",
       main="",
       mgp = c(7, 3, 0),
       polygon(d, col="steelblue", border="blue"))
} 
dev.off()  

# -------------------------------------------------------------------------------------------
##                                          # END PART 3.2.1 #
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
NOX_L02_today_Y$mean    <-mean(NOX_L02_today_Y$no)
Y_MIN                   <-subset(NOX_L02_today_Y, no == min(NOX_L02_today_Y$no))
Y_MAX                   <-subset(NOX_L02_today_Y, no == max(NOX_L02_today_Y$no))
OBS_start               <-head(format(temp_L00$date,"%d %B %Y"),1)
OBS_end                 <-tail(format(temp_L00$date,"%d %B %Y"),1)
#
# -------------------------------------------------------------------------------------------
# Defining plotting parameters
#
PLOT_Y_NAME             <-paste(s_GAW_ID, "NO", questo_anno,"ANNUAL_GRAPH_",gsub("-","",Sys.Date()),sep = "_")
PLOT_Y_NAME_FULL        <-paste (PLOT_DIR_Y,paste(PLOT_Y_NAME,".png",sep = ""),sep = "/")
png(file=,PLOT_Y_NAME_FULL, width = 2480, height = 3508)

# -------------------------------------------------------------------------------------------
# Preparing plotting parameters (font size, margins, ...)
# 
par(mfrow = c(8,1))
par(ps = 14, cex = 2.5, cex.main = 3.5,cex.sub=2.2, cex.lab=3.5, cex.axis = 3.5, mai=c(0.3,1.8,0.5,0.5))
#
# -------------------------------------------------------------------------------------------
# Creating the plotting matrix
#
m <- rbind(c(1, 1), c(2, 2), c(3, 3), c(4, 4), c(5, 5), c(6, 6), c(7, 8))
layout(m)
#
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# Plotting NO
#
plot(ylim=c(Y_MIN$no[1]-0.15,Y_MAX$no[1]+0.175),
     xlim = c(min(c(NOX_L02_today_Y$date,temp_L01$date,temp_L00$date)),max(c(NOX_L02_today_Y$date,temp_L01$date,temp_L00$date))),
     mgp = c(8, 4, 0),
     NOX_L02_today_Y$date, NOX_L02_today_Y$no, type = "h",
     xlab = "",ylab ="NO (nmol/mol) - L02", col="lightblue", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
title(paste("NO - L02 -",questo_anno), line = -3)
lines(NOX_L02_today_Y$date, NOX_L02_today_Y$no, type = "l", lty = 1, col="darkred",lwd = 2)

points(Y_MAX$date[1], Y_MAX$no[1], col= "magenta",pch=20)
text(Y_MAX$date[1], Y_MIN$no[1], labels = paste0("Max (",format(Y_MAX$date[1],"%B %d"),")"),col="magenta",pos=1,cex = 1.8)
segments(Y_MAX$date[1], Y_MAX$no[1], Y_MAX$date[1], -1, lty = 2, col="black",lwd = 1)

points(Y_MIN$date[1], Y_MIN$no[1], col= "blue",pch=20)
text(Y_MIN$date[1], Y_MIN$no[1], labels = paste0("Min (",format(Y_MIN$date[1],"%B %d"),")"),col="blue",pos=1,cex = 1.8)
segments(Y_MIN$date[1], Y_MIN$no[1], Y_MIN$date[1], -1, lty = 2, col="black",lwd = 1)
#
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# Plotting NUMFLAG L01
#
plot(ylim=c(0,1.1),
     xlim = c(min(temp_L01$date),max(temp_L01$date)),
     mgp = c(8, 4, 0),
     temp_L01$date, temp_L01$numflag_NO, type = "h",
     xlab = "",ylab =("numflag - L01"), 
     col="tan", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
title(paste("numflag - L01 -",questo_anno), line = -3)
lines(temp_L01$date, temp_L01$numflag_NO, type = "l", 
      lty = 1, 
      col = "lightgreen",
      lwd = 2) 
#
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# Plotting NO L02 vs NO instrumental
#
temp_L00$NO[temp_L00$NO > 6] <-5.5

plot(ylim=c(-0.1,7),
     temp_L00$date, temp_L00$NO, type = "h",
     xlab = "",ylab =("NO (inst vs L02) nmol/mol"), 
     mgp = c(8, 4, 0),
     col="cadetblue2", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
title(paste("NO (from instrument) vs NO - L02 -",questo_anno), line = -3)
lines(NOX_L02_today_Y$date, NOX_L02_today_Y$no, type = "l", lty = 1, col="darkred",lwd = 2)

title(c("NO (inst) values higher than 6 are out of scale and are rappresented as 5.5")
      ,col="black",cex.main = 2.6, line = -6.0, font.main = 1)
#
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# Flow_sample & Pre
#
xx    <- c(temp_L00$date, rev(temp_L00$date))
yy_PR <- c(rep(0, nrow(temp_L00)), rev(temp_L00$Pre))
yy_FS <- c(rep(0, nrow(temp_L00)), rev(temp_L00$Flow_sample))  
yy_PC <- c(rep(0, nrow(temp_L00)), rev(temp_L00$P_chamb))
yy_TC <- c(rep(0, nrow(temp_L00)), rev(temp_L00$T_Cooler))
yy_PM <- c(rep(0, nrow(temp_L00)), rev(temp_L00$PMT_V)) 
#
plot(ylim=c(-0.1,2),
     temp_L00$date, temp_L00$Flow_sample, type = "n",
     xlab = "",ylab =("Flow_sample & Pre - L01"),
     mgp = c(8, 4, 0),
     col="cadetblue2", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
title(paste("Flow_sample and Pre - L01 -",questo_anno), line = -3)
#
# Flow sample
polygon(xx, yy_FS, col='rosybrown1',border = "indianred3")
#
# Pre
polygon(xx, yy_PR, col='indianred1',border = "tomato4")
#
legend("topleft", legend=c("Flow_sample","Pre"), lty=c(1,1), lwd = c(2,2), col=c("indianred3","tomato4"), cex = 2.8)
#
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# P_chamb & T_Cooler
#
plot(ylim=c(-50,400),
     temp_L00$date, temp_L00$P_chamb, type = "h",
     xlab = "",ylab =("P_chamb & T_Cooler - inst"),
     mgp = c(7, 3, 0),
     col="palegreen", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
title(paste("P_chamb and T_Cooler - from instrument -",questo_anno), line = -3)
#
# P_chamb
lines(temp_L00$date, temp_L00$P_chamb, type = "l", lty = 1, col="palegreen4",lwd = 2)
#
# T_Cooler
#
polygon(xx, yy_TC, col='seagreen1',border = "purple4")
#
legend("topleft", legend=c("P_chamb","T_Cooler"), lty=c(1,1), lwd = c(2,2), col=c("palegreen","purple4"), cex = 2.8)
#
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# Plotting PMT_V
#
plot(ylim=c(-1100,-1150),
     temp_L00$date, temp_L00$PMT_V, type = "h",
     xlab = "",ylab =("PMT_V - inst"), 
     mgp = c(7, 3, 0),
     col="lightskyblue2", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
title(paste("PMT_V - from instrument -",questo_anno), line = -3)
#
lines(temp_L00$date, temp_L00$PMT_V, type = "l", lty = 1, col="royalblue",lwd = 2.5)
#
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# Plotting STATISTICS TEXT
#
plot(c(0, 1), c(0, 1), ann = F, bty = 'n', type = 'n', xaxt = 'n', yaxt = 'n')
text(x = 0, y = 0.95, paste (PLOT_Y_NAME,"  -  ",questo_anno),
     cex = 3.3, col = "darkred",pos = 4)

text(x = -0.005, y = 0.75, paste(" Observations from", OBS_start," to ", OBS_end,
                                 "\n",
                                 "(days of observation: ", 1+(as.integer(tail((NOX_L02_today_Y$date),1)-head((NOX_L02_today_Y$date)),1)),")")
     , cex = 2.8, col = "black",pos = 4)


plot(c(0, 1), c(0, 1), ann = F, bty = 'n', type = 'n', xaxt = 'n', yaxt = 'n')
text(x = 0, y = 0.95, paste ("Statistics  -  ",questo_anno),
     cex = 3.3, col = "darkred",pos = 4)

text(x = 0, y = 0.50, paste("\n", "NO min: (", round(min(NOX_L02_today_Y$no),2),") - NO max: (", round(max(NOX_L02_today_Y$no),2),") - NO mean: (", round(mean(NOX_L02_today_Y$no),2),") - NO sd: (", round(sd(NOX_L02_today_Y$no),2),")",
                            "\n",
                            "NO percentile:    5th: (",round(quantile(NOX_L02_today_Y$no, probs = c(0.05)),digits=2),")",
                            " - 25th: (",round(quantile(NOX_L02_today_Y$no, probs = c(0.25)),digits=2),")",
                            " - 50th: (",round(quantile(NOX_L02_today_Y$no, probs = c(0.50)),digits=2),")",
                            " - 75th: (",round(quantile(NOX_L02_today_Y$no, probs = c(0.75)),digits=2),")",
                            " - 95th: (",round(quantile(NOX_L02_today_Y$no, probs = c(0.95)),digits=2),")","\n","\n",
                            "L02 numflag = 0.999 (number of days of the year):   ", sum(NO_mesi_FAIL_COUNT$freq), 
                            " (",round((sum(NO_mesi_FAIL_COUNT$freq)/(length(diy(as.numeric(questo_anno)))))*100,digits=2),"%)",
                            "\n","Months affected:",
                            "\n",
                            if (nrow(NO_mesi_FAIL_COUNT)==0){"none"},
                            if (!is.na(NO_mesi_FAIL_COUNT$print[1])){NO_mesi_FAIL_COUNT$print[1]}  ,"   ",
                            if (!is.na(NO_mesi_FAIL_COUNT$print[2])){NO_mesi_FAIL_COUNT$print[2]}  ,"   ",
                            if (!is.na(NO_mesi_FAIL_COUNT$print[3])){NO_mesi_FAIL_COUNT$print[3]}  ,"   ",
                            if (!is.na(NO_mesi_FAIL_COUNT$print[4])){NO_mesi_FAIL_COUNT$print[4]}  ,"\n",
                            if (!is.na(NO_mesi_FAIL_COUNT$print[5])){NO_mesi_FAIL_COUNT$print[5]}  ,"   ",
                            if (!is.na(NO_mesi_FAIL_COUNT$print[6])){NO_mesi_FAIL_COUNT$print[6]}  ,"   ",
                            if (!is.na(NO_mesi_FAIL_COUNT$print[7])){NO_mesi_FAIL_COUNT$print[7]}  ,"   ",
                            if (!is.na(NO_mesi_FAIL_COUNT$print[8])){NO_mesi_FAIL_COUNT$print[8]}  ,"\n",
                            if (!is.na(NO_mesi_FAIL_COUNT$print[9])){NO_mesi_FAIL_COUNT$print[9]}  ,"   ",
                            if (!is.na(NO_mesi_FAIL_COUNT$print[10])){NO_mesi_FAIL_COUNT$print[10]},"   ",
                            if (!is.na(NO_mesi_FAIL_COUNT$print[11])){NO_mesi_FAIL_COUNT$print[11]},"   ",
                            if (!is.na(NO_mesi_FAIL_COUNT$print[12])){NO_mesi_FAIL_COUNT$print[12]},
                            sep=""), cex = 2.8, col = "black",pos = 4)

dev.off()
##                                          # END PART 3.3 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.3.1 #
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
NOX_L02_today_Y$mean    <-mean(NOX_L02_today_Y$no2)
Y_MIN                   <-subset(NOX_L02_today_Y, no2 == min(NOX_L02_today_Y$no2))
Y_MAX                   <-subset(NOX_L02_today_Y, no2 == max(NOX_L02_today_Y$no2))
OBS_start               <-head(format(temp_L00$date,"%d %B %Y"),1)
OBS_end                 <-tail(format(temp_L00$date,"%d %B %Y"),1)
#
# -------------------------------------------------------------------------------------------
# Defining plotting parameters
#
PLOT_Y_NAME             <-paste(s_GAW_ID, "NO2", questo_anno,"ANNUAL_GRAPH_",gsub("-","",Sys.Date()),sep = "_")
PLOT_Y_NAME_FULL        <-paste (PLOT_DIR_Y,paste(PLOT_Y_NAME,".png",sep = ""),sep = "/")
png(file=,PLOT_Y_NAME_FULL, width = 2480, height = 3508)

# -------------------------------------------------------------------------------------------
# Preparing plotting parameters (font size, margins, ...)
# 
par(mfrow = c(8,1))
par(ps = 14, cex = 2.5, cex.main = 3.5,cex.sub=2.2, cex.lab=3.5, cex.axis = 3.5, mai=c(0.3,1.8,0.5,0.5))
#
# -------------------------------------------------------------------------------------------
# Creating the plotting matrix
#
m <- rbind(c(1, 1), c(2, 2), c(3, 3), c(4, 4), c(5, 5), c(6, 6), c(7, 8))
layout(m)
#
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# Plotting NO2
#
plot(ylim=c(-0.1,7),
     xlim = c(min(c(NOX_L02_today_Y$date,temp_L01$date,temp_L00$date)),max(c(NOX_L02_today_Y$date,temp_L01$date,temp_L00$date))),
     mgp = c(8, 4, 0),
     NOX_L02_today_Y$date, NOX_L02_today_Y$no2, type = "h",
     xlab = "",ylab =bquote(paste("NO"[2], " (nmol/mol) - L02")), col="lightblue", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
title(bquote(bold(paste("NO"[2], " - L02 - ",.(questo_anno)))), line = -3)
lines(NOX_L02_today_Y$date, NOX_L02_today_Y$no2, type = "l", lty = 1, col="darkred",lwd = 2)

points(Y_MAX$date[1], Y_MAX$no2[1], col= "magenta",pch=20)
text(Y_MAX$date[1], Y_MIN$no2[1], labels = paste0("Max (",format(Y_MAX$date[1],"%B %d"),")"),col="magenta",pos=1,cex = 1.8)
segments(Y_MAX$date[1], Y_MAX$no2[1], Y_MAX$date[1], -1, lty = 2, col="black",lwd = 1)

points(Y_MIN$date[1], Y_MIN$no2[1], col= "blue",pch=20)
text(Y_MIN$date[1], Y_MIN$no2[1], labels = paste0("Min (",format(Y_MIN$date[1],"%B %d"),")"),col="blue",pos=1,cex = 1.8)
segments(Y_MIN$date[1], Y_MIN$no2[1], Y_MIN$date[1], -1, lty = 2, col="black",lwd = 1)
#
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# Plotting NUMFLAG L01
#
plot(ylim=c(0,1.1),
     xlim = c(min(temp_L01$date),max(temp_L01$date)),
     mgp = c(8, 4, 0),
     temp_L01$date, temp_L01$numflag_NO2, type = "h",
     xlab = "",ylab =("numflag - L01"), 
     col="tan", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
title(paste("numflag - L01 -",questo_anno), line = -3)
lines(temp_L01$date, temp_L01$numflag_NO2, type = "l", 
      lty = 1, 
      col = "lightgreen",
      lwd = 2) 
#
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# Plotting NO2 L02 vs NO2 instrumental
#
temp_L00$NO2[temp_L00$NO2 > 6] <-5.5

plot(ylim=c(-0.1,7),
     temp_L00$date, temp_L00$NO2, type = "h",
     xlab = "",ylab =bquote(paste("NO"[2], " (nmol/mol) - inst vs L02")), 
     mgp = c(8, 4, 0),
     col="cadetblue2", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
title(bquote(bold(paste("NO"[2], " (from instrument) vs NO"[2], " (L02) -",.(questo_anno)))), line = -3)
lines(NOX_L02_today_Y$date, NOX_L02_today_Y$no2, type = "l", lty = 1, col="darkred",lwd = 2)

title(bquote(paste("NO"[2], " (inst) values higher than 6 are out of scale and are rappresented as 5.5"))
      ,col="black",cex.main = 2.6, line = -6, font.main = 1)
#
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# Flow_sample & Pre
#
xx    <- c(temp_L00$date, rev(temp_L00$date))
yy_PR <- c(rep(0, nrow(temp_L00)), rev(temp_L00$Pre))
yy_FS <- c(rep(0, nrow(temp_L00)), rev(temp_L00$Flow_sample))  
yy_PC <- c(rep(0, nrow(temp_L00)), rev(temp_L00$P_chamb))
yy_TC <- c(rep(0, nrow(temp_L00)), rev(temp_L00$T_Cooler))
yy_PM <- c(rep(0, nrow(temp_L00)), rev(temp_L00$PMT_V)) 
#
plot(ylim=c(-0.1,2),
     temp_L00$date, temp_L00$Flow_sample, type = "n",
     xlab = "",ylab =("Flow_sample & Pre - L01"),
     mgp = c(8, 4, 0),
     col="cadetblue2", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
title(paste("Flow_sample and Pre - L01 -",questo_anno), line = -3)
#
# Flow sample
polygon(xx, yy_FS, col='rosybrown1',border = "indianred3")
#
# Pre
polygon(xx, yy_PR, col='indianred1',border = "tomato4")
#
legend("topleft", legend=c("Flow_sample","Pre"), lty=c(1,1), lwd = c(2,2), col=c("indianred3","tomato4"), cex = 2.8)
#
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# P_chamb & T_Cooler
#
plot(ylim=c(-50,400),
     temp_L00$date, temp_L00$P_chamb, type = "h",
     xlab = "",ylab =("P_chamb & T_Cooler - inst"),
     mgp = c(7, 3, 0),
     col="palegreen", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
title(paste("P_chamb and T_Cooler - from instrument -",questo_anno), line = -3)
#
# P_chamb
lines(temp_L00$date, temp_L00$P_chamb, type = "l", lty = 1, col="palegreen4",lwd = 2)
#
# T_Cooler
#
polygon(xx, yy_TC, col='seagreen1',border = "purple4")
#
legend("topleft", legend=c("P_chamb","T_Cooler"), lty=c(1,1), lwd = c(2,2), col=c("palegreen","purple4"), cex = 2.8)
#
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# Plotting PMT_V
#
plot(ylim=c(-1100,-1150),
     temp_L00$date, temp_L00$PMT_V, type = "h",
     xlab = "",ylab =("PMT_V - inst"), 
     mgp = c(7, 3, 0),
     col="lightskyblue2", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
title(paste("PMT_V - from instrument -",questo_anno), line = -3)
#
lines(temp_L00$date, temp_L00$PMT_V, type = "l", lty = 1, col="royalblue",lwd = 2.5)
#
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# Plotting STATISTICS TEXT
#
plot(c(0, 1), c(0, 1), ann = F, bty = 'n', type = 'n', xaxt = 'n', yaxt = 'n')
text(x = 0, y = 0.95, paste (PLOT_Y_NAME,"  -  ",questo_anno),
     cex = 3.3, col = "darkred",pos = 4)

text(x = -0.005, y = 0.75, paste(" Observations from", OBS_start," to ", OBS_end,
                                 "\n",
                                 "(days of observation: ", 1+(as.integer(tail((NOX_L02_today_Y$date),1)-head((NOX_L02_today_Y$date)),1)),")")
     , cex = 2.8, col = "black",pos = 4)


plot(c(0, 1), c(0, 1), ann = F, bty = 'n', type = 'n', xaxt = 'n', yaxt = 'n')
text(x = 0, y = 0.95, paste ("Statistics  -  ",questo_anno),
     cex = 3.3, col = "darkred",pos = 4)

text(x = 0, y = 0.50, paste("\n", "NO2 min: (", round(min(NOX_L02_today_Y$no2),2),") - NO2 max: (", round(max(NOX_L02_today_Y$no2),2),") - NO2 mean: (", round(mean(NOX_L02_today_Y$no2),2),") - NO2 sd: (", round(sd(NOX_L02_today_Y$no2),2),")",
                            "\n",
                            "NO2 percentile:    5th: (",round(quantile(NOX_L02_today_Y$no2, probs = c(0.05)),digits=2),")",
                            " - 25th: (",round(quantile(NOX_L02_today_Y$no2, probs = c(0.25)),digits=2),")",
                            " - 50th: (",round(quantile(NOX_L02_today_Y$no2, probs = c(0.50)),digits=2),")",
                            " - 75th: (",round(quantile(NOX_L02_today_Y$no2, probs = c(0.75)),digits=2),")",
                            " - 95th: (",round(quantile(NOX_L02_today_Y$no2, probs = c(0.95)),digits=2),")","\n","\n",
                            "L02 numflag = 0.999 (number of days of the year):   ", sum(NO2_mesi_FAIL_COUNT$freq), 
                            " (",round((sum(NO2_mesi_FAIL_COUNT$freq)/(length(diy(as.numeric(questo_anno)))))*100,digits=2),"%)",
                            "\n","Months affected:",
                            "\n",
                            if (nrow(NO2_mesi_FAIL_COUNT)==0){"none"},
                            if (!is.na(NO2_mesi_FAIL_COUNT$print[1])){NO2_mesi_FAIL_COUNT$print[1]}  ,"   ",
                            if (!is.na(NO2_mesi_FAIL_COUNT$print[2])){NO2_mesi_FAIL_COUNT$print[2]}  ,"   ",
                            if (!is.na(NO2_mesi_FAIL_COUNT$print[3])){NO2_mesi_FAIL_COUNT$print[3]}  ,"   ",
                            if (!is.na(NO2_mesi_FAIL_COUNT$print[4])){NO2_mesi_FAIL_COUNT$print[4]}  ,"\n",
                            if (!is.na(NO2_mesi_FAIL_COUNT$print[5])){NO2_mesi_FAIL_COUNT$print[5]}  ,"   ",
                            if (!is.na(NO2_mesi_FAIL_COUNT$print[6])){NO2_mesi_FAIL_COUNT$print[6]}  ,"   ",
                            if (!is.na(NO2_mesi_FAIL_COUNT$print[7])){NO2_mesi_FAIL_COUNT$print[7]}  ,"   ",
                            if (!is.na(NO2_mesi_FAIL_COUNT$print[8])){NO2_mesi_FAIL_COUNT$print[8]}  ,"\n",
                            if (!is.na(NO2_mesi_FAIL_COUNT$print[9])){NO2_mesi_FAIL_COUNT$print[9]}  ,"   ",
                            if (!is.na(NO2_mesi_FAIL_COUNT$print[10])){NO2_mesi_FAIL_COUNT$print[10]},"   ",
                            if (!is.na(NO2_mesi_FAIL_COUNT$print[11])){NO2_mesi_FAIL_COUNT$print[11]},"   ",
                            if (!is.na(NO2_mesi_FAIL_COUNT$print[12])){NO2_mesi_FAIL_COUNT$print[12]},
                            sep=""), cex = 2.8, col = "black",pos = 4)

dev.off()
##                                          # END PART 3.3.1 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.4 #
## ______________________________________________________________________________________________________________________##
##                                    Creating statistcs/graphic reports
##                                              NO CALENDAR PLOT
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Cleaning Destination directory
# 
FILE_PLOT_Y             <-list.files(path = PLOT_DIR_Y, pattern = paste(s_GAW_ID, "NO", questo_anno,"CALENDAR_GRAPH_*",sep = "_"), all.files = FALSE,
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
PLOT_C_NAME             <-paste(s_GAW_ID, "NO", questo_anno,"CALENDAR_GRAPH",gsub("-","",Sys.Date()),sep = "_")
PLOT_C_NAME_FULL        <-paste (PLOT_DIR_Y,paste(PLOT_C_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_C_NAME_FULL, width=2100,height=2970,res=250)
calendarPlot(NOX_L02_today_Y, pollutant = "no", year = questo_anno, month=c(1:12), auto.text = TRUE,
             key.footer = "NO (nmol/mol)", key.position = "right", key = TRUE,
             main = paste("NO in",questo_anno))
dev.off()
##                                          # END PART 3.4 #
###########################################################################################################################



###########################################################################################################################
##                                           # PART 3.4.1 #
## ______________________________________________________________________________________________________________________##
##                                    Creating statistcs/graphic reports
##                                              NO2 CALENDAR PLOT
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Cleaning Destination directory
# 
FILE_PLOT_Y             <-list.files(path = PLOT_DIR_Y, pattern = paste(s_GAW_ID, "NO2", questo_anno,"CALENDAR_GRAPH_*",sep = "_"), all.files = FALSE,
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
PLOT_C_NAME             <-paste(s_GAW_ID, "NO2", questo_anno,"CALENDAR_GRAPH",gsub("-","",Sys.Date()),sep = "_")
PLOT_C_NAME_FULL        <-paste (PLOT_DIR_Y,paste(PLOT_C_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_C_NAME_FULL, width=2100,height=2970,res=250)
calendarPlot(NOX_L02_today_Y, pollutant = "no2", year = questo_anno, month=c(1:12), auto.text = TRUE,
             key.footer = "NO2 (nmol/mol)", key.position = "right", key = TRUE,
             main = paste("NO2 in",questo_anno))
dev.off()
##                                          # END PART 3.4.1 #
###########################################################################################################################
 

###########################################################################################################################
##                                           # PART 3.5 #
## ______________________________________________________________________________________________________________________##
##                                    Creating timevariation reports
##                                        NO ANNUAL TIMEVARIATION
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Cleaning Destination directory
#
FILE_PLOT_TVA             <-list.files(path = PLOT_DIR_T, pattern = paste(s_GAW_ID, "NO", questo_anno,"TIMEVARIATION_GRAPH_*",sep = "_"), all.files = FALSE,
                                       full.names = F, recursive = FALSE,
                                       ignore.case = FALSE, include.dirs = F, no.. = FALSE)
FILE_PLOT_TVA
LISTA_PLOT_TVA            <-as.character(FILE_PLOT_TVA)

for(f in LISTA_PLOT_TVA)  { file.remove(paste(PLOT_DIR_T,f,sep = "/")) }
#
# -------------------------------------------------------------------------------------------
# Creating data subset
#
mydata                    <-data.frame(NOX_L02_today_Y$date,NOX_L02_today_Y$no)
colnames(mydata)          <- c("date","no")
#
# -------------------------------------------------------------------------------------------
# Plotting temporary hourly timevariation
#
PLOT_TVH_NAME             <-paste("tmp_H",s_GAW_ID, "NO",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVH_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVH_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVH_NAME_FULL, width=930,height=900,res=250)

TV_ANNUAL_H               <-timeVariation(mydata, pollutant = "no", normalise = FALSE, 
                                          ylab = paste("NO (nmol/mol) -",questo_anno),
                                          xlab = c("Hour","Hour","Month","Weekday"),cols = c("cornflowerblue"), key = NULL)
plot(TV_ANNUAL_H$plot$hour)

dev.off()
#
# -------------------------------------------------------------------------------------------
# Plotting temporary daily timevariation
#
PLOT_TVD_NAME             <-paste("tmp_D",s_GAW_ID, "NO",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVD_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVD_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVD_NAME_FULL, width=930,height=900,res=250)

plot(TV_ANNUAL_H$plot$day)

dev.off()
#
# -------------------------------------------------------------------------------------------
# Plotting temporary monthly timevariation
#
PLOT_TVM_NAME             <-paste("tmp_M",s_GAW_ID, "NO",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
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

PLOT_TVF_NAME             <-paste(s_GAW_ID, "NO",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVF_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVF_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVF_NAME_FULL, width=2970,height=2100,res=500)

par(mar=c(1.1, 1.1, 1.1, 1.1), mgp=c(-1.5, 1, 0), las=0)
par(ps = 14, cex.lab = 0.5)

plot(0:297, ty="n",xaxt = "n",yaxt = "n",xlab = paste("NO -",questo_anno,"- annual trend analysis",sep=" "),ylab = "")
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
FILE_PLOT_TVA             <-list.files(path = PLOT_DIR_T, pattern = glob2rx(paste("tmp_*",questo_anno,"_TIMEVARIATION_GRAPH_*",sep = ""))
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
no_hh                 <- timeAverage(mydata, avg.time = "hour", data.thresh = 75, statistic = "mean",
                                         start.date = mydata$date[1], 
                                         end.date = mydata$date[length(mydata)], 
                                         interval = "hour")

no_tv                 <- timeVariation(no_hh, pollutant = "no", type = "season", conf.int = 0.95,
                                           xlab = c("Hour","Hour","Month","Weekday"), 
                                           ylab = paste("NO (nmol/mol) -",questo_anno), 
                                           name.pol = "NO",
                                           cols = c("cornflowerblue"))


PLOT_TVN1_NAME            <-paste("tmp_s1_NO_",questo_anno,"_TIMEVARIATION_GRAPH_SEASONAL_",gsub("-","",Sys.Date()),sep = "")
PLOT_TVN1_NAME_FULL       <-paste (PLOT_DIR_T,paste(PLOT_TVN1_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVN1_NAME_FULL, width=930,height=900,res=150)
plot(no_tv$plot$day)

dev.off() 

PLOT_TVN2_NAME            <-paste("tmp_s2_NO_",questo_anno,"_TIMEVARIATION_GRAPH_SEASONAL_",gsub("-","",Sys.Date()),sep = "")
PLOT_TVN2_NAME_FULL       <-paste (PLOT_DIR_T,paste(PLOT_TVN2_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVN2_NAME_FULL, width=930,height=900,res=150)
plot(no_tv$plot$hour)
dev.off()
#
# -------------------------------------------------------------------------------------------
# Merging temporary plots to final report
#
imgN1                     <- readPNG(PLOT_TVN1_NAME_FULL)
imgN2                     <- readPNG(PLOT_TVN2_NAME_FULL)

PLOT_TVF_NAME             <-paste(s_GAW_ID, "NO",questo_anno,"TIMEVARIATION_GRAPH_SEASONAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVF_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVF_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVF_NAME_FULL, width=2970,height=2100,res=500)

par(mar=c(1.1, 1.1, 1.1, 1.1), mgp=c(-1.5, 1, 0), las=0)
par(ps = 14, cex.lab = 0.5)

plot(0:297, ty="n",xaxt = "n",yaxt = "n",xlab = paste("NO - ",questo_anno," - trend analysis by season",sep=""),ylab = "")

rasterImage(imgN2,-5,70,150,270)
rasterImage(imgN1,150,70,305,270)

dev.off() 
#
# -------------------------------------------------------------------------------------------
# Cleaning temporary plots
#
FILE_PLOT_TVA             <-list.files(path = PLOT_DIR_T, pattern = glob2rx(paste("tmp_*",questo_anno,"_TIMEVARIATION_GRAPH_*",sep = ""))
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
##                                        NO2 ANNUAL TIMEVARIATION
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Cleaning Destination directory
#
FILE_PLOT_TVA             <-list.files(path = PLOT_DIR_T, pattern = paste(s_GAW_ID, "NO2", questo_anno,"TIMEVARIATION_GRAPH_*",sep = "_"), all.files = FALSE,
                                       full.names = F, recursive = FALSE,
                                       ignore.case = FALSE, include.dirs = F, no.. = FALSE)
FILE_PLOT_TVA
LISTA_PLOT_TVA            <-as.character(FILE_PLOT_TVA)

for(f in LISTA_PLOT_TVA)  { file.remove(paste(PLOT_DIR_T,f,sep = "/")) }
#
# -------------------------------------------------------------------------------------------
# Creating data subset
#
mydata                    <-data.frame(NOX_L02_today_Y$date,NOX_L02_today_Y$no)
colnames(mydata)          <- c("date","no2")
#
# -------------------------------------------------------------------------------------------
# Plotting temporary hourly timevariation
#
PLOT_TVH_NAME             <-paste("tmp_H",s_GAW_ID, "NO2",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVH_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVH_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVH_NAME_FULL, width=930,height=900,res=250)

TV_ANNUAL_H               <-timeVariation(mydata, pollutant = "no2", normalise = FALSE, 
                                          ylab = paste("NO2 (nmol/mol) -",questo_anno),
                                          xlab = c("Hour","Hour","Month","Weekday"),cols = c("cornflowerblue"), key = NULL)
plot(TV_ANNUAL_H$plot$hour)

dev.off()
#
# -------------------------------------------------------------------------------------------
# Plotting temporary daily timevariation
#
PLOT_TVD_NAME             <-paste("tmp_D",s_GAW_ID, "NO2",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVD_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVD_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVD_NAME_FULL, width=930,height=900,res=250)

TV_ANNUAL_H               <-timeVariation(mydata, pollutant = "no2", normalise = FALSE, 
                                          ylab = paste("NO2 (nmol/mol) -",questo_anno),
                                          xlab = c("Hour","Hour","Month","Weekday"),cols = c("cornflowerblue"), key = NULL)


plot(TV_ANNUAL_H$plot$day)

dev.off()
#
# -------------------------------------------------------------------------------------------
# Plotting temporary monthly timevariation
#
PLOT_TVM_NAME             <-paste("tmp_M",s_GAW_ID, "NO2",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
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

PLOT_TVF_NAME             <-paste(s_GAW_ID, "NO2",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVF_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVF_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVF_NAME_FULL, width=2970,height=2100,res=500)

par(mar=c(1.1, 1.1, 1.1, 1.1), mgp=c(-1.5, 1, 0), las=0)
par(ps = 14, cex.lab = 0.5)

plot(0:297, ty="n",xaxt = "n",yaxt = "n",xlab = paste("NO2 -",questo_anno,"- annual trend analysis",sep=" "),ylab = "")
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
FILE_PLOT_TVA             <-list.files(path = PLOT_DIR_T, pattern = glob2rx(paste("tmp_*",questo_anno,"_TIMEVARIATION_GRAPH_*",sep = ""))
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
no2_hh                 <- timeAverage(mydata, avg.time = "hour", data.thresh = 75, statistic = "mean",
                                     start.date = mydata$date[1], 
                                     end.date = mydata$date[length(mydata)], 
                                     interval = "hour")

no2_tv                 <- timeVariation(no2_hh, pollutant = "no2", type = "season", conf.int = 0.95,
                                       xlab = c("Hour","Hour","Month","Weekday"), 
                                       ylab = paste("NO2 (nmol/mol) -",questo_anno), 
                                       name.pol = "NO2",
                                       cols = c("cornflowerblue"))


PLOT_TVN1_NAME            <-paste("tmp_s1_NO2_",questo_anno,"_TIMEVARIATION_GRAPH_SEASONAL_",gsub("-","",Sys.Date()),sep = "")
PLOT_TVN1_NAME_FULL       <-paste (PLOT_DIR_T,paste(PLOT_TVN1_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVN1_NAME_FULL, width=930,height=900,res=150)
plot(no2_tv$plot$day)

dev.off() 

PLOT_TVN2_NAME            <-paste("tmp_s2_NO2_",questo_anno,"_TIMEVARIATION_GRAPH_SEASONAL_",gsub("-","",Sys.Date()),sep = "")
PLOT_TVN2_NAME_FULL       <-paste (PLOT_DIR_T,paste(PLOT_TVN2_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVN2_NAME_FULL, width=930,height=900,res=150)
plot(no2_tv$plot$hour)
dev.off()
#
# -------------------------------------------------------------------------------------------
# Merging temporary plots to final report
#
imgN1                     <- readPNG(PLOT_TVN1_NAME_FULL)
imgN2                     <- readPNG(PLOT_TVN2_NAME_FULL)

PLOT_TVF_NAME             <-paste(s_GAW_ID, "NO2",questo_anno,"TIMEVARIATION_GRAPH_SEASONAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVF_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVF_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVF_NAME_FULL, width=2970,height=2100,res=500)

par(mar=c(1.1, 1.1, 1.1, 1.1), mgp=c(-1.5, 1, 0), las=0)
par(ps = 14, cex.lab = 0.5)

plot(0:297, ty="n",xaxt = "n",yaxt = "n",xlab = paste("NO2 - ",questo_anno," - trend analysis by season",sep=""),ylab = "")

rasterImage(imgN2,-5,70,150,270)
rasterImage(imgN1,150,70,305,270)

dev.off() 
#
# -------------------------------------------------------------------------------------------
# Cleaning temporary plots
#
FILE_PLOT_TVA             <-list.files(path = PLOT_DIR_T, pattern = glob2rx(paste("tmp_*",questo_anno,"_TIMEVARIATION_GRAPH_*",sep = ""))
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
##                                           # PART 3.6 #
## ______________________________________________________________________________________________________________________##
##                                    Creating timevariation reports
##                                      NO MONTHLY TIMEVARIATION
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Cleaning Destination directory
#
unico_T                   <-c(NOX_L02_today_Y[!duplicated(NOX_L02_today_Y[,c('monthNum')]),]$monthNum)

for (qm in unico_T)
{ print(qm)
  #
  # -------------------------------------------------------------------------------------------
  # Creating data subset
  #
  NOX_L02_ThisMonth       <-subset(NOX_L02_today, as.integer(monthNum)==qm)
  temp_L02_ThisMonth      <-subset(temp_L02, as.integer(monthNum)==qm)
  temp_L00_ThisMonth      <-subset(temp_L00, as.integer(monthNum)==qm)
  
  OBS_Month_start         <-head(format(temp_L02_ThisMonth$date,"%d %B %Y"),1)
  OBS_Month_end           <-tail(format(temp_L02_ThisMonth$date,"%d %B %Y"),1)

  mensile                 <-subset(NOX_L02_ThisMonth, numflag_no != 0.999)

  mensile$giorno          <-format(mensile$date,"%d")
  This_Month              <-format(mensile$date,"%m")[1]
  This_Month_Name         <-format(mensile$date,"%B")[1]

  mensile$mean            <- mean(mensile$no)
  mensile$sd              <- sd(mensile$no)
  men_MIN                 <- subset(mensile, no == min(mensile$no))
  men_MAX                 <- subset(mensile, no == max(mensile$no))
  
  mydata                  <- data.frame(mensile$date,mensile$no)
  colnames(mydata)        <- c("date","no")
  
  PLOT_TV_NAME            <-paste(s_GAW_ID, "NO",questo_anno,"TIMEVARIATION_GRAPH",This_Month,"MONTHLY",gsub("-","",Sys.Date()),sep = "_")
  PLOT_TV_NAME_FULL       <-paste (PLOT_DIR_T,paste(PLOT_TV_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_TV_NAME_FULL, width = 960, height = 960)
  par(ps = 14, cex = 1.5, cex.main = 2.2, mai=c(0.3,1.8,0.5,0.5)) 
  
  myOutput                <-timeVariation(mydata, pollutant = "no", 
                                          ylab = paste("NO (nmol/mol) -",questo_anno), 
                                          type="season",
                                          xlab = paste(s_GAW_ID, " - month variation \n - ",questo_anno," ",This_Month_Name," -"),
                                          cols = c("cornflowerblue"))
  dev.off()
  #
  # -------------------------------------------------------------------------------------------
  # Plotting temporary hourly timevariation
  #
  PLOT_TVH_NAME           <-paste("tmp_H_",s_GAW_ID, "NO",questo_anno,"_TIMEVARIATION_GRAPH_",This_Month,"MONTHLY_",gsub("-","",Sys.Date()),sep = "")
  PLOT_TVH_NAME_FULL      <-paste (PLOT_DIR_T,paste(PLOT_TVH_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_TVH_NAME_FULL, width=1860,height=900,res=250)
  #par(ps = 14, cex = 1.5, cex.main = 2.2, mai=c(0.3,1.8,0.5,0.5)) 
  
  TV_ANNUAL_H             <-timeVariation(mydata, pollutant = "no", ylab = paste("NO (nmol/mol) -",questo_anno),
                              xlab = c("Hour","Hour","Month","Weekday"),cols = c("cornflowerblue"))
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
  
  PLOT_TVF_NAME         <-paste(s_GAW_ID, "NO",questo_anno,"TIMEVARIATION_GRAPH",This_Month,"MONTHLY",gsub("-","",Sys.Date()),sep = "_")
  PLOT_TVF_NAME_FULL    <-paste (PLOT_DIR_T,paste(PLOT_TVF_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_TVF_NAME_FULL, width=2970,height=2100,res=500)
  
  par(mar=c(1.1, 1.1, 1.1, 1.1), mgp=c(-1.5, 1, 0), las=0)
  par(ps = 14, cex.lab = 0.5)
  
  plot(0:297, ty="n",xaxt = "n",yaxt = "n",
       xlab = paste("NO - ",This_Month_Name," ",questo_anno," - monthly trend analysis",sep=""),ylab = "")
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
  FILE_PLOT_TVA         <-list.files(path = PLOT_DIR_T, pattern = glob2rx(paste("tmp_*",questo_anno,"_TIMEVARIATION_GRAPH_*",sep = ""))
                            , all.files = FALSE,
                            full.names = F, recursive = FALSE,
                            ignore.case = FALSE, include.dirs = F, no.. = FALSE)
  FILE_PLOT_TVA
  LISTA_PLOT_TVA        <-as.character(FILE_PLOT_TVA)
  for(f in LISTA_PLOT_TVA) { file.remove(paste(PLOT_DIR_T,f,sep = "/")) }
}
##                                          # END PART 3.6 #
###########################################################################################################################



###########################################################################################################################
##                                           # PART 3.6.1 #
## ______________________________________________________________________________________________________________________##
##                                    Creating timevariation reports
##                                      NO2 MONTHLY TIMEVARIATION
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Cleaning Destination directory
#
unico_T                   <-c(NOX_L02_today_Y[!duplicated(NOX_L02_today_Y[,c('monthNum')]),]$monthNum)

for (qm in unico_T)
{ print(qm)
  #
  # -------------------------------------------------------------------------------------------
  # Creating data subset
  #
  NOX_L02_ThisMonth       <-subset(NOX_L02_today, as.integer(monthNum)==qm)
  temp_L02_ThisMonth      <-subset(temp_L02, as.integer(monthNum)==qm)
  temp_L00_ThisMonth      <-subset(temp_L00, as.integer(monthNum)==qm)
  
  OBS_Month_start         <-head(format(temp_L02_ThisMonth$date,"%d %B %Y"),1)
  OBS_Month_end           <-tail(format(temp_L02_ThisMonth$date,"%d %B %Y"),1)
  
  mensile                 <-subset(NOX_L02_ThisMonth, numflag_no2 != 0.999)
  
  mensile$giorno          <-format(mensile$date,"%d")
  This_Month              <-format(mensile$date,"%m")[1]
  This_Month_Name         <-format(mensile$date,"%B")[1]
  
  mensile$mean            <- mean(mensile$no2)
  mensile$sd              <- sd(mensile$no2)
  men_MIN                 <- subset(mensile, no2 == min(mensile$no2))
  men_MAX                 <- subset(mensile, no2 == max(mensile$n2o))
  
  mydata                  <- data.frame(mensile$date,mensile$no2)
  colnames(mydata)        <- c("date","no2")
  
  PLOT_TV_NAME            <-paste(s_GAW_ID, "NO2",questo_anno,"TIMEVARIATION_GRAPH",This_Month,"MONTHLY",gsub("-","",Sys.Date()),sep = "_")
  PLOT_TV_NAME_FULL       <-paste (PLOT_DIR_T,paste(PLOT_TV_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_TV_NAME_FULL, width = 960, height = 960)
  par(ps = 14, cex = 1.5, cex.main = 2.2, mai=c(0.3,1.8,0.5,0.5)) 
  
  myOutput                <-timeVariation(mydata, pollutant = "no2", 
                                          ylab = paste("NO2 (nmol/mol) -",questo_anno), 
                                          type="season",
                                          xlab = paste(s_GAW_ID, " - month variation \n - ",questo_anno," ",This_Month_Name," -"),
                                          cols = c("cornflowerblue"))
  dev.off()
  #
  # -------------------------------------------------------------------------------------------
  # Plotting temporary hourly timevariation
  #
  PLOT_TVH_NAME           <-paste("tmp_H_",s_GAW_ID, "NO2",questo_anno,"_TIMEVARIATION_GRAPH_",This_Month,"MONTHLY_",gsub("-","",Sys.Date()),sep = "")
  PLOT_TVH_NAME_FULL      <-paste (PLOT_DIR_T,paste(PLOT_TVH_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_TVH_NAME_FULL, width=1860,height=900,res=250)
  #par(ps = 14, cex = 1.5, cex.main = 2.2, mai=c(0.3,1.8,0.5,0.5)) 
  
  TV_ANNUAL_H             <-timeVariation(mydata, pollutant = "no2", ylab = paste("NO2 (nmol/mol) -",questo_anno),
                                          xlab = c("Hour","Hour","Month","Weekday"),cols = c("cornflowerblue"))
  plot(TV_ANNUAL_H$plot$day.hour)
  
  dev.off()
  #
  # -------------------------------------------------------------------------------------------
  # Plotting temporary daily timevariation
  #
  PLOT_TVD_NAME           <-paste("tmp_D_",s_GAW_ID, "NO2",questo_anno,"_TIMEVARIATION_GRAPH_",This_Month,"MONTHLY_",gsub("-","",Sys.Date()),sep = "")
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
  
  PLOT_TVF_NAME         <-paste(s_GAW_ID, "NO2",questo_anno,"TIMEVARIATION_GRAPH",This_Month,"MONTHLY",gsub("-","",Sys.Date()),sep = "_")
  PLOT_TVF_NAME_FULL    <-paste (PLOT_DIR_T,paste(PLOT_TVF_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_TVF_NAME_FULL, width=2970,height=2100,res=500)
  
  par(mar=c(1.1, 1.1, 1.1, 1.1), mgp=c(-1.5, 1, 0), las=0)
  par(ps = 14, cex.lab = 0.5)
  
  plot(0:297, ty="n",xaxt = "n",yaxt = "n",
       xlab = paste("NO2 - ",This_Month_Name," ",questo_anno," - monthly trend analysis",sep=""),ylab = "")
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
  FILE_PLOT_TVA         <-list.files(path = PLOT_DIR_T, pattern = glob2rx(paste("tmp_*",questo_anno,"_TIMEVARIATION_GRAPH_*",sep = ""))
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
#                                                                                                                         #
## End of NOX_D22_1810.R                                                                                                  # 
#                                                                                                                         # 
###################################################################################### Authors: L u C A, Davide ###########

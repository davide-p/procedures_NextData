###########################################################################################################################
## Project: NEXTDATA                                                                                                     ##
## Parameter: OPC                                                                                                        ##
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
## Script filename: OPC_D22_1810.R                                                                                       ##
## Version Date: February 2019        
## Feb. 12th, 2019: fixed MONTHLY/ANNUAL issue of creating empty plots when data from ancillary parameters are missing
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
inst_type               <- "OPC"                                             # replace the value with your instrument type
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
# Setting NA to 9999.999 values
#
temp_L00$p_sys          [temp_L00$p_sys == 9999.99]     <- NA
temp_L00$T_sys          [temp_L00$T_sys == 9999.99]     <- NA
temp_L00$RH             [temp_L00$RH    == 9999.99]     <- NA
#
# -------------------------------------------------------------------------------------------
#Converting of JD values to date
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
# -------------------------------------------------------------------------------------------
# Setting NA to 9999.999 values
#
temp_L01$p_sys          [temp_L01$p_sys == 9999.99]     <- NA
temp_L01$T_sys          [temp_L01$T_sys == 9999.99]     <- NA
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
# -------------------------------------------------------------------------------------------
#Converting JD values to date
#
temp_L02$jd             <-as.integer(temp_L02$start_time)
#
temp_L02$day            <-as.Date(temp_L02$start_time, origin=questa_start_time)
temp_L02$time.dec       <-temp_L02$start_time-temp_L02$jd
temp_L02$time           <-temp_L02$time.dec*1440+0.01
temp_L02$hour           <-as.integer(temp_L02$time/60)
temp_L02$min            <-as.integer(temp_L02$time-temp_L02$hour*60)
temp_L02$date           <-paste(temp_L02$day," ",temp_L02$hour,":",temp_L02$min,":00",sep="")
temp_L02$date           <-as.POSIXct(strptime(temp_L02$date, format = "%Y-%m-%d %H:%M:%S", tz = "GMT"))
temp_L02$monthNum       <-format(temp_L02$date, "%m")
#
temp_L02$fine           <- temp_L02$bin_01+temp_L02$bin_02+temp_L02$bin_03+temp_L02$bin_04+temp_L02$bin_05
temp_L02$coarse         <- temp_L02$bin_06+temp_L02$bin_07+temp_L02$bin_08+temp_L02$bin_09+temp_L02$bin_10+temp_L02$bin_11+temp_L02$bin_12+temp_L02$bin_13+temp_L02$bin_14+temp_L02$bin_15
#
OPC_L02_today           <-data.frame(temp_L02$date,temp_L02$fine,temp_L02$coarse,temp_L02$numflag)
#
colnames(OPC_L02_today) <- c("date","fine","coarse","numflag")
#
OPC_L02_today$month     <- format(OPC_L02_today$date,"%B")
OPC_L02_today$monthNum  <- as.numeric(format(OPC_L02_today$date,"%m"))
OPC_L02_today$day       <- as.numeric(format(OPC_L02_today$date,"%d"))
#
OPC_FAIL_today          <- subset(OPC_L02_today, numflag == 0.999)
#
TFAIL                   <- subset(OPC_FAIL_today, select=c("month","day","monthNum","numflag"))
mesi_FAIL               <- data.frame(TFAIL[!duplicated(TFAIL[1:2]),])
mesi_FAIL_COUNT         <- data.frame(mesi_FAIL[!duplicated(mesi_FAIL[1]),],count(mesi_FAIL,"monthNum"))
#
if (nrow(mesi_FAIL)  > 0)  { mesi_FAIL_COUNT$print       <-paste(mesi_FAIL_COUNT$month," (",mesi_FAIL_COUNT$freq," days)",sep = "")
                           Somma_giorni_FAIL       <- sum(mesi_FAIL_COUNT$freq)}
if (nrow(mesi_FAIL) == 0)  { }
#
OPC_L02_today_Y         <- subset(OPC_L02_today, numflag != 0.999)
#
unico                   <- c(OPC_L02_today_Y[!duplicated(OPC_L02_today_Y[,c('month')]),]$month)
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
unico_M             <- c(OPC_L02_today_Y[!duplicated(OPC_L02_today_Y[,c('monthNum')]),]$monthNum)

for (qm in unico_M)
{
  OPC_L02_ThisMonth    <-subset(OPC_L02_today_Y, as.integer(monthNum)==qm)
  temp_L02_ThisMonth   <-subset(temp_L02, as.integer(monthNum)==qm)
  temp_L01_ThisMonth   <-subset(temp_L01, as.integer(monthNum)==qm)
  temp_L00_ThisMonth   <-subset(temp_L00, as.integer(monthNum)==qm)
  
  OBS_Month_start     <-head(format(temp_L02_ThisMonth$date,"%d %B %Y"),1)
  OBS_Month_end       <-tail(format(temp_L02_ThisMonth$date,"%d %B %Y"),1)
  #
  # -------------------------------------------------------------------------------------------
  # Calculating days with invalid flags
  #
  FAIL_ThisMonth      <- subset(OPC_FAIL_today, as.integer(monthNum) == qm)
  FAIL_ThisMonth$day  <-format(FAIL_ThisMonth$date,"%d")
  FAIL_unico          <-data.frame(FAIL_ThisMonth[!duplicated(FAIL_ThisMonth[,c('day')]),])
  FAIL_DAYS           <-nrow(FAIL_unico)
  
  mensile             <-subset(OPC_L02_ThisMonth, numflag != 0.999)
  mensile$giorno      <-format(mensile$date,"%d")
  This_Month          <-format(mensile$date,"%m")[1]
  This_Month_Name     <-format(mensile$date,"%B")[1]

    print(paste("ora il ",This_Month_Name[1], FAIL_DAYS))   # check point: printing month and failing days
  #
  # -------------------------------------------------------------------------------------------
  # Calculating monthly statistics
  #
  mensile$mean_fine        <-mean(mensile$fine)
  mensile$sd_fine          <-sd(mensile$fine)
  men_MIN_fine             <-subset(mensile, fine == min(mensile$fine))
  men_MAX_fine             <-subset(mensile, fine == max(mensile$fine))
  mensile$mean_coarse      <-mean(mensile$coarse)
  mensile$sd_coarse        <-sd(mensile$coarse)
  men_MIN_coarse           <-subset(mensile, coarse == min(mensile$coarse))
  men_MAX_coarse           <-subset(mensile, coarse == max(mensile$coarse))
  mensile$fine[is.na(mensile$fine)] <- 0
  mensile$coarse[is.na(mensile$coarse)] <- 0
  #
  # -------------------------------------------------------------------------------------------
  # Cleaning Destination directory
  # 
  FILE_PLOT_M<-list.files(path = PLOT_DIR_M, pattern = paste(s_GAW_ID,inst_type,questo_anno,This_Month,"MONTHLY_GRAPH_*",sep = "_"), 
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
  PLOT_M_NAME         <-paste(s_GAW_ID, inst_type, questo_anno, This_Month, "MONTHLY_GRAPH", gsub("-","",Sys.Date()), sep = "_")
  PLOT_M_NAME_FULL    <-paste (PLOT_DIR_M,paste(PLOT_M_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_M_NAME_FULL, width = 2480, height = 3508)
  #
  # -------------------------------------------------------------------------------------------
  # Preparing plotting parameters (font size, margins, ...)
  # 
  par(mfrow = c(7,1))
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
  # Plotting FINE
  #
  plot(ylim=c(men_MIN_fine$fine[1]-10,men_MAX_fine$fine[1]+10),
       xlim = c(min(c(OPC_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date)),max(c(OPC_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date))),
       mensile$date, mensile$fine, type = "l",
        mgp = c(8, 4, 0),
       xlab = "",ylab =expression(paste("Accum. part. (#/cm"^{3},") - L02")), col="lightblue", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
  title(paste("Accumulation part. - L02 -",questo_anno,This_Month_Name), line = -3)
  lines(OPC_L02_ThisMonth$date, mensile$fine, type = "l", lty = 1, col="darkred",lwd = 2)
  
  points(men_MAX_fine$date[1], men_MAX_fine$fine[1], col= "magenta",pch=20)
  text(men_MAX_fine$date[1], men_MAX_fine$fine[1], labels = paste("Max (", format(men_MAX_fine$date[1],"%B %d"), ")", sep=""),col="magenta",pos=3,cex = 1.8)
  segments(men_MAX_fine$date[1], men_MAX_fine$fine[1], men_MAX_fine$date[1], men_MIN_fine$fine[1]-400, lty = 2, col="black",lwd = 1)

  points(men_MIN_fine$date[1], men_MIN_fine$fine[1], col= "blue",pch=20)
  text(men_MIN_fine$date[1], men_MIN_fine$fine[1], labels = paste("Min (", format(men_MIN_fine$date[1],"%B %d"), ")", sep =""),col="blue",pos=1,cex = 1.8)
  segments(men_MIN_fine$date[1], men_MIN_fine$fine[1], men_MIN_fine$date[1], men_MIN_fine$fine[1]-400, lty = 2, col="black",lwd = 1)

  lines(mensile$date,mensile$mean, type = "l", lty = 1, col="red",lwd = 1)
  text(mensile$date[1],mensile$mean[1]+200, labels = c("Mean"),col="red",cex = 1.8)
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting COARSE
  #
  plot(ylim=c(men_MIN_coarse$coarse[1]-0.2,men_MAX_coarse$coarse[1]+0.5),
       xlim = c(min(c(OPC_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date)),max(c(OPC_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date))),
       mensile$date, mensile$coarse, type = "h",
       mgp = c(8, 4, 0),
       xlab = "",ylab =expression(paste("Coarse part. (#/cm"^{3},") - L02")), col="lightblue", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
  title(paste("Coarse part. - L02 -",questo_anno,This_Month_Name), line = -3)
  lines(OPC_L02_ThisMonth$date, mensile$coarse, type = "l", lty = 1, col="darkred",lwd = 2)
  
  points(men_MAX_coarse$date[1], men_MAX_coarse$coarse[1], col= "magenta",pch=20)
  text(men_MAX_coarse$date[1], men_MAX_coarse$coarse[1], labels = paste("Max (", format(men_MAX_coarse$date[1],"%B %d"), ")", sep=""),col="magenta",pos=3,cex = 1.8)
  segments(men_MAX_coarse$date[1], men_MAX_coarse$coarse[1], men_MAX_coarse$date[1], men_MIN_coarse$coarse[1]-400, lty = 2, col="black",lwd = 1)
  
  points(men_MIN_coarse$date[1], men_MIN_coarse$coarse[1], col= "blue",pch=20)
  text(men_MIN_coarse$date[1], men_MIN_coarse$coarse[1], labels = paste("Min (", format(men_MIN_coarse$date[1],"%B %d"), ")", sep =""),col="blue",pos=1,cex = 1.8)
  segments(men_MIN_coarse$date[1], men_MIN_coarse$coarse[1], men_MIN_coarse$date[1], men_MIN_coarse$coarse[1]-400, lty = 2, col="black",lwd = 1)
  
  lines(mensile$date,mensile$mean, type = "l", lty = 1, col="red",lwd = 1)
  text(mensile$date[1],mensile$mean[1]+200, labels = c("Mean"),col="red",cex = 1.8)
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting NUMFLAG (L01)
  #
  plot(ylim=c(0,1.1),
       xlim = c(min(c(OPC_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date)),
                max(c(OPC_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date))),
       mgp = c(8, 4, 0),
       temp_L01_ThisMonth$date, temp_L01_ThisMonth$numflag, type = "h",
       xlab = "",ylab =("numflag - L01"), col="tan", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
  title(paste("numflag - L01 -",questo_anno,This_Month_Name), line = -3)
  lines(temp_L01_ThisMonth$date, temp_L01_ThisMonth$numflag, type = "l",
        lty = 1,
        col = "lightgreen",
        lwd = 2)
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting P_sys
  #
  if(all(is.na(temp_L00_ThisMonth$p_sys)))
  {
    plot(ylim = c(690,890),
         xlim = c(min(c(OPC_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date)),max(c(OPC_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date))),
         mgp = c(8, 4, 0),
         temp_L00_ThisMonth$date, temp_L00_ThisMonth$p_sys, type = "h",
         xlab = "",ylab =("P_int (hPa) - L00"), col="lightblue", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
    title(paste("Internal pressure - L00 - data for this month are absent"), line = -3)
    title(paste("No data"), line = -28, cex = 0.8)
    
  } else {
    plot(ylim=c(mean(temp_L00_ThisMonth$p_sys, na.rm = TRUE)-100,mean(temp_L00_ThisMonth$p_sys, na.rm = TRUE)+100),
         xlim = c(min(c(OPC_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date)),max(c(OPC_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date))),
         temp_L00_ThisMonth$date, temp_L00_ThisMonth$p_sys, type = "h",
         mgp = c(8, 4, 0),
         xlab = "",ylab =("p_sys (hPa) - L00"), col="lightblue", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
    lines(temp_L00_ThisMonth$date, temp_L00_ThisMonth$p_sys, type = "l", lty = 1, col="darkblue",lwd = 0.5)
    title(paste("Internal pressure - L00 -",questo_anno,This_Month_Name), line = -3)
  }
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting T_sys
  #
  if(all(is.na(temp_L00_ThisMonth$T_sys)))
  {
    plot(ylim = c(280,320),
         xlim = c(min(c(OPC_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date)),max(c(OPC_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date))),
         mgp = c(8, 4, 0),
         temp_L00_ThisMonth$date, temp_L00_ThisMonth$T_sys, type = "h",
         xlab = "",ylab =("T_int (K) - L00"), col="pink", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
    title(paste("Internal temperature - L00 - data for this month are absent"), line = -3)
    title(paste("No data"), line = -28, cex = 0.8)
    
  } else {
    plot(ylim=c(mean(temp_L00_ThisMonth$T_sys, na.rm = TRUE)-20,mean(temp_L00_ThisMonth$T_sys, na.rm = TRUE)+20),
         xlim = c(min(c(OPC_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date)),max(c(OPC_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date))),
         temp_L00_ThisMonth$date, temp_L00_ThisMonth$T_sys, type = "h",
         mgp = c(8, 4, 0),
         xlab = "",ylab =("T_int (K) - L00"), col="pink", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
    lines(temp_L00_ThisMonth$date, temp_L00_ThisMonth$T_sys, type = "l", lty = 1, col="blue",lwd = 0.5)
    title(paste("Internal temperature - L00 -",questo_anno,This_Month_Name), line = -3)
  }
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting RH
  #
  if(all(is.na(temp_L00_ThisMonth$RH)))
  {
    plot(ylim = c(0,100),
         xlim = c(min(c(OPC_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date)),max(c(OPC_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date))),
         mgp = c(8, 4, 0),
         temp_L00_ThisMonth$date, temp_L00_ThisMonth$RH, type = "h",
         xlab = "",ylab =("RH (%) - L00"), col="seashell", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
    title(paste("Relative humidity - L00 - data for this month are absent"), line = -3)
    title(paste("No data"), line = -28, cex = 0.8)
    
  } else {
    plot(ylim=c(0,100),
         xlim = c(min(c(OPC_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date)),max(c(OPC_L02_ThisMonth$date,temp_L01_ThisMonth$date,temp_L00_ThisMonth$date))),
         temp_L00_ThisMonth$date, temp_L00_ThisMonth$RH, type = "h",
         mgp = c(8, 4, 0),
         xlab = "",ylab =("RH (%) - L00"), col="seashell", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
    lines(temp_L00_ThisMonth$date, temp_L00_ThisMonth$RH, type = "l", lty = 1, col="mediumorchid4",lwd = 0.5)
    title(paste("Relative humidity - L00 -",questo_anno,This_Month_Name), line = -3)
  }
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting Text
  #
  plot(c(0, 1), c(0, 1), ann = F, bty = 'n', type = 'n', xaxt = 'n', yaxt = 'n')
  text(x = 0, y = 0.95, paste (PLOT_M_NAME,"  -  ",This_Month_Name," ",questo_anno),
       cex = 3.3, col = "darkred",pos = 4)
  
  text(x = -0.005, y = 0.75, paste(" Observations from", OBS_Month_start," to ", OBS_Month_end,
                                   "\n",
                                   "(days of observation: ", 1+(as.integer(tail((mensile$date),1)-head((mensile$date)),1)),")")
       , cex = 2.8, col = "black",pos = 4)
  
  plot(c(0, 1), c(0, 1), ann = F, bty = 'n', type = 'n', xaxt = 'n', yaxt = 'n')
  text(x = 0, y = 0.95, paste ("Statistics  -  ",This_Month_Name," ",questo_anno),
       cex = 3.3, col = "darkred",pos = 4)
  
  text(x = 0, y = 0.35, paste("\n", "Accum. min: (", round(min(mensile$fine),1),") - Accum. max: (", round(max(mensile$fine),1),") - Accum. mean: (", round(mean(mensile$fine),1),") - Accum. sd: (", round(sd(mensile$fine),1),")","\n",
                              "Accum. percentile:    5th: (",round(quantile(mensile$fine, probs = c(0.05)),digits=1),")",
                              " - 25th: (",round(quantile(mensile$fine, probs = c(0.25)),digits=1),")",
                              " - 50th: (",round(quantile(mensile$fine, probs = c(0.50)),digits=1),")",
                              " - 75th: (",round(quantile(mensile$fine, probs = c(0.75)),digits=1),")",
                              " - 95th: (",round(quantile(mensile$fine, probs = c(0.95)),digits=1),")","\n",
                              "\n", "Coarse min: (", round(min(mensile$coarse),1),") - Coarse max: (", round(max(mensile$coarse),1),") - Coarse mean: (", round(mean(mensile$coarse),1),") - Coarse sd: (", round(sd(mensile$fine),1),")","\n",
                              "Coarse percentile:    5th: (",round(quantile(mensile$fine, probs = c(0.05)),digits=1),")",
                              " - 25th: (",round(quantile(mensile$fine, probs = c(0.25)),digits=1),")",
                              " - 50th: (",round(quantile(mensile$fine, probs = c(0.50)),digits=1),")",
                              " - 75th: (",round(quantile(mensile$fine, probs = c(0.75)),digits=1),")",
                              " - 95th: (",round(quantile(mensile$fine, probs = c(0.95)),digits=1),")","\n","\n",
                              "L02 numflag = 0.999 (number of days affected):   ", FAIL_DAYS,
                              " (",round((FAIL_DAYS/days_in_month(temp_L02_ThisMonth$date[1]))*100,digits=2),"%)",
                              "\n",
                              "Days of ",This_Month_Name," affected:","\n",
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
##                                           # PART 3.1 #
## ______________________________________________________________________________________________________________________##
##                                    Creating statistcs/graphic reports
##                                               FINE SEMESTER GRAPHS
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Subsetting data by semester
# First semester
#
Fhalf           <-subset(OPC_L02_today_Y,monthNum<7)

if (nrow(Fhalf)==0){ } else 
{
  # -------------------------------------------------------------------------------------------
  # Cleaning Destination directory
  # 
  FILE_PLOT_1HM<-list.files(path = PLOT_DIR_M, pattern = paste(s_GAW_ID,"_",inst_type,"_ACCUM_",questo_anno,"SEMESTER_1st_GRAPH_*",sep = "_"), all.files = FALSE,
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
  png(file=paste(PLOT_DIR_M,paste(s_GAW_ID,"_",inst_type,"_ACCUM_",questo_anno,"_SEMESTER_1st_GRAPH_",gsub("-","",Sys.Date()),".png",sep = ""),sep = "/"),
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
    mensile            <-subset(OPC_L02_today_Y, month == i)
    mensile$giorno     <-format(mensile$date,"%d")
    mensile$mean       <-mean(mensile$fine)
    mensile$sd         <-sd(mensile$fine)    
    men_MIN            <-subset(mensile, fine == min(mensile$fine))
    men_MAX            <-subset(mensile, fine == max(mensile$fine))
    {
      plot(ylim=c(men_MIN$fine[1]-10,men_MAX$fine[1]+10),
           mensile$date, mensile$fine, type = "h",
           xlab = "",ylab =expression(paste("Accum. part. (#/cm"^{3},") - L02")), col="lightblue", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
      title(main=paste(i,questo_anno,sep=" "), 
            line = -2.2)
      
      title(paste("Statistics: min: (", round(min(mensile$fine),1),") - max: (", round(max(mensile$fine),1),") - mean: (", round(mean(mensile$fine),1),") - sd: (", round(sd(mensile$fine),1),")")
            ,col="black",cex.main = 1.2, line = -3.8, font.main = 1)
      
      lines(mensile$date, mensile$fine, type = "l", lty = 1, col="darkred",lwd = 2)
      
      points(men_MAX$date[1], men_MAX$fine[1], col= "magenta",pch=20)
      text(men_MAX$date[1], men_MAX$fine[1], labels = paste("Max (",format(men_MAX$date[1],"%B %d"),")",sep=""),col="magenta",pos=3)
      segments(men_MAX$date[1], men_MAX$fine[1], men_MAX$date[1], men_MIN$fine[1]-8, lty = 2, col="black",lwd = 1)

      points(men_MIN$date[1], men_MIN$fine[1], col= "blue",pch=20)
      text(men_MIN$date[1], men_MIN$fine[1], labels = paste("Min (",format(men_MIN$date[1],"%B %d"),")",sep=""),col="blue",pos=1)
      segments(men_MIN$date[1], men_MIN$fine[1], men_MIN$date[1], men_MIN$fine[1]-8, lty = 2, col="black",lwd = 1)
    }   
  }
  dev.off() 
}
#
# -------------------------------------------------------------------------------------------
# Subsetting data by semester
# Second semester
#
Shalf<-subset(OPC_L02_today_Y,monthNum>6)
if (nrow(Shalf)==0){}else 
{
  # -------------------------------------------------------------------------------------------
  # Cleaning Destination directory
  # 
  FILE_PLOT_2HM<-list.files(path = PLOT_DIR_M, pattern = paste(s_GAW_ID,"_",inst_type,"_ACCUM_",questo_anno,"SEMESTER_1st_GRAPH_*",sep = "_"), all.files = FALSE,
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
  png(file=paste(PLOT_DIR_M,paste(s_GAW_ID,"_",inst_type,"_ACCUM_",questo_anno,"_SEMESTER_2st_GRAPH_",gsub("-","",Sys.Date()),".png",sep = ""),sep = "/"),
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
    mensile            <-subset(OPC_L02_today_Y, month == i)
    mensile$giorno     <-format(mensile$date,"%d")
    mensile$mean       <-mean(mensile$fine)
    mensile$sd         <-sd(mensile$fine)    
    men_MIN            <-subset(mensile, fine == min(mensile$fine))
    men_MAX            <-subset(mensile, fine == max(mensile$fine))
    {
      plot(ylim=c(men_MIN$fine[1]-10,men_MAX$fine[1]+10),
           mensile$date, mensile$fine, type = "h",
           xlab = "",ylab =expression(paste("Accum. part. (#/cm"^{3},") - L02")), col="lightblue", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
      title(main=paste(i,questo_anno,sep=" "), 
            line = -2.2)
          
      title(paste("Statistics: min: (", round(min(mensile$fine),1),") - max: (", round(max(mensile$fine),1),") - mean: (", round(mean(mensile$fine),1),") - sd: (", round(sd(mensile$fine),1),")")
            ,col="black",cex.main = 1.2, line = -3.8, font.main = 1)
      
      lines(mensile$date, mensile$fine, type = "l", lty = 1, col="darkred",lwd = 2)
      
      points(men_MAX$date[1], men_MAX$fine[1], col= "magenta",pch=20)
      text(men_MAX$date[1], men_MAX$fine[1], labels = paste("Max (",format(men_MAX$date[1],"%B %d"),")",sep=""),col="magenta",pos=3)
      segments(men_MAX$date[1], men_MAX$fine[1], men_MAX$date[1], men_MIN$fine[1]-400, lty = 2, col="black",lwd = 1)
      
      points(men_MIN$date[1], men_MIN$fine[1], col= "blue",pch=20)
      text(men_MIN$date[1], men_MIN$fine[1], labels = paste("Min (",format(men_MIN$date[1],"%B %d"),")",sep=""),col="blue",pos=1)
      segments(men_MIN$date[1], men_MIN$fine[1], men_MIN$date[1], men_MIN$fine[1]-400, lty = 2, col="black",lwd = 1)
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
##                                               COARSE SEMESTER GRAPHS
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Subsetting data by semester
# First semester
#
Fhalf           <-subset(OPC_L02_today_Y,monthNum<7)

if (nrow(Fhalf)==0){ } else 
{
  # -------------------------------------------------------------------------------------------
  # Cleaning Destination directory
  # 
  FILE_PLOT_1HM<-list.files(path = PLOT_DIR_M, pattern = paste(s_GAW_ID,"_",inst_type,"_COARSE_",questo_anno,"SEMESTER_1st_GRAPH_*",sep = "_"), all.files = FALSE,
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
  png(file=paste(PLOT_DIR_M,paste(s_GAW_ID,"_",inst_type,"_COARSE_",questo_anno,"_SEMESTER_1st_GRAPH_",gsub("-","",Sys.Date()),".png",sep = ""),sep = "/"),
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
    mensile           <-subset(OPC_L02_today_Y, month == i)
    mensile$giorno    <-format(mensile$date,"%d")
    mensile$mean      <-mean(mensile$coarse)
    mensile$sd        <-sd(mensile$coarse)    
    men_MIN           <-subset(mensile, coarse == min(mensile$coarse))
    men_MAX           <-subset(mensile, coarse == max(mensile$coarse))
    {
      plot(ylim=c(men_MIN$coarse[1]-0.2,men_MAX$coarse[1]+0.2),
           mensile$date, mensile$coarse, type = "h",
           xlab = "",ylab =expression(paste("Coarse part. (#/cm"^{3},") - L02")), col="lightblue", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
      title(main=paste(i,questo_anno,sep=" "), 
            line = -2.2)
      
      title(paste("Statistics: min: (", round(min(mensile$coarse),1),") - max: (", round(max(mensile$coarse),1),") - mean: (", round(mean(mensile$coarse),1),") - sd: (", round(sd(mensile$coarse),1),")")
            ,col="black",cex.main = 1.2, line = -3.8, font.main = 1)
      
      lines(mensile$date, mensile$coarse, type = "l", lty = 1, col="darkred",lwd = 2)
      
      points(men_MAX$date[1], men_MAX$coarse[1], col= "magenta",pch=20)
      text(men_MAX$date[1], men_MAX$coarse[1], labels = paste("Max (",format(men_MAX$date[1],"%B %d"),")",sep=""),col="magenta",pos=3)
      segments(men_MAX$date[1], men_MAX$coarse[1], men_MAX$date[1], men_MIN$coarse[1]-8, lty = 2, col="black",lwd = 1)
      
      points(men_MIN$date[1], men_MIN$coarse[1], col= "blue",pch=20)
      text(men_MIN$date[1], men_MIN$coarse[1], labels = paste("Min (",format(men_MIN$date[1],"%B %d"),")",sep=""),col="blue",pos=1)
      segments(men_MIN$date[1], men_MIN$coarse[1], men_MIN$date[1], men_MIN$coarse[1]-8, lty = 2, col="black",lwd = 1)
    }   
  }
  dev.off() 
}
#
# -------------------------------------------------------------------------------------------
# Subsetting data by semester
# Second semester
#
Shalf<-subset(OPC_L02_today_Y,monthNum>6)
if (nrow(Shalf)==0){}else 
{
  # -------------------------------------------------------------------------------------------
  # Cleaning Destination directory
  # 
  FILE_PLOT_2HM<-list.files(path = PLOT_DIR_M, pattern = paste(s_GAW_ID,"_",inst_type,"_COARSE_",questo_anno,"SEMESTER_1st_GRAPH_*",sep = "_"), all.files = FALSE,
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
  png(file=paste(PLOT_DIR_M,paste(s_GAW_ID,"_",inst_type,"_COARSE_",questo_anno,"_SEMESTER_2st_GRAPH_",gsub("-","",Sys.Date()),".png",sep = ""),sep = "/"),
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
    mensile            <-subset(OPC_L02_today_Y, month == i)
    mensile$giorno     <-format(mensile$date,"%d")
    mensile$mean       <-mean(mensile$coarse)
    mensile$sd         <-sd(mensile$coarse)    
    men_MIN            <-subset(mensile, coarse == min(mensile$coarse))
    men_MAX            <-subset(mensile, coarse == max(mensile$coarse))
    {
      plot(ylim=c(men_MIN$coarse[1]-0.2,men_MAX$coarse[1]+0.2),
           mensile$date, mensile$coarse, type = "h",
           xlab = "",ylab =expression(paste("Coarse part. (#/cm"^{3},") - L02")), col="lightblue", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
      title(main=paste(i,questo_anno,sep=" "), 
            line = -2.2)
      
      title(paste("Statistics: min: (", round(min(mensile$coarse),1),") - max: (", round(max(mensile$coarse),1),") - mean: (", round(mean(mensile$coarse),1),") - sd: (", round(sd(mensile$coarse),1),")")
            ,col="black",cex.main = 1.2, line = -3.8, font.main = 1)
      
      lines(mensile$date, mensile$coarse, type = "l", lty = 1, col="darkred",lwd = 2)
      
      points(men_MAX$date[1], men_MAX$coarse[1], col= "magenta",pch=20)
      text(men_MAX$date[1], men_MAX$coarse[1], labels = paste("Max (",format(men_MAX$date[1],"%B %d"),")",sep=""),col="magenta",pos=3)
      segments(men_MAX$date[1], men_MAX$coarse[1], men_MAX$date[1], men_MIN$coarse[1]-400, lty = 2, col="black",lwd = 1)
      
      points(men_MIN$date[1], men_MIN$coarse[1], col= "blue",pch=20)
      text(men_MIN$date[1], men_MIN$coarse[1], labels = paste("Min (",format(men_MIN$date[1],"%B %d"),")",sep=""),col="blue",pos=1)
      segments(men_MIN$date[1], men_MIN$coarse[1], men_MIN$date[1], men_MIN$coarse[1]-400, lty = 2, col="black",lwd = 1)
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
##                                              FINE SEASONAL GRAPHS
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# -------------------------------------------------------------------------------------------
# Cleaning Destination directory
# 
FILE_PLOT_S         <-list.files(path = PLOT_DIR_S, pattern = paste(s_GAW_ID, inst_type,"_ACCUM_", questo_anno,"SEASONAL_GRAPH_*",sep = "_"), 
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
OPC_L02_today_Y$season[OPC_L02_today_Y$monthNum>=1  & OPC_L02_today_Y$monthNum<=3]      <- 1
OPC_L02_today_Y$season[OPC_L02_today_Y$monthNum>=4  & OPC_L02_today_Y$monthNum<=6]      <- 2
OPC_L02_today_Y$season[OPC_L02_today_Y$monthNum>=7  & OPC_L02_today_Y$monthNum<=9]      <- 3
OPC_L02_today_Y$season[OPC_L02_today_Y$monthNum>=10 & OPC_L02_today_Y$monthNum<=12]     <- 4
#
# -------------------------------------------------------------------------------------------
# Creating temporary season tables (Level-2)
#
temp_L02$season[as.integer(temp_L02$monthNum)>=1    & as.integer(temp_L02$monthNum)<=3] <- 1
temp_L02$season[as.integer(temp_L02$monthNum)>=4    & as.integer(temp_L02$monthNum)<=6] <- 2
temp_L02$season[as.integer(temp_L02$monthNum)>=7    & as.integer(temp_L02$monthNum)<=9] <- 3
temp_L02$season[as.integer(temp_L02$monthNum)>=10   & as.integer(temp_L02$monthNum)<=12]<- 4

temp_L00$season[as.integer(temp_L00$monthNum)>=1    & as.integer(temp_L00$monthNum)<=3] <- 1
temp_L00$season[as.integer(temp_L00$monthNum)>=4    & as.integer(temp_L00$monthNum)<=6] <- 2
temp_L00$season[as.integer(temp_L00$monthNum)>=7    & as.integer(temp_L00$monthNum)<=9] <- 3
temp_L00$season[as.integer(temp_L00$monthNum)>=10   & as.integer(temp_L00$monthNum)<=12]<- 4

seasons<-c(OPC_L02_today_Y[!duplicated(OPC_L02_today_Y[,c('season')]),]$season)
seasons 
# -------------------------------------------------------------------------------------------
# Preparing plotting files
#  
PLOT_S_NAME         <-paste(s_GAW_ID,"_",inst_type,"_ACCUM_",questo_anno,"_SEASONAL_GRAPH_",gsub("-","",Sys.Date()),sep = "")
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
  
  OPC_L02_stg      <-subset(OPC_L02_today_Y, season == stg)
  temp_L02_stg      <-subset(temp_L02, season == stg)
  temp_L00_stg      <-subset(temp_L00, season == stg)
  
  OBS_stg_start     <-head(format(temp_L02_stg$date,"%d %B %Y"),1)
  OBS_stg_end       <-tail(format(temp_L02_stg$date,"%d %B %Y"),1)
  
  FAIL_stg          <-subset(temp_L02_stg, numflag == 0.999)
  FAIL_stg$day      <-format(FAIL_stg$date,"%d")
  FAIL_unico        <-data.frame(FAIL_stg[!duplicated(FAIL_stg[,c('day')]),])
  FAIL_DAYS         <-nrow(FAIL_unico)
  
  stagionale<-subset(OPC_L02_stg, numflag != 0.999)
  stagionale$giorno <- format(stagionale$date,"%d")
  This_stg <- c(format(stagionale$date,"%m"))
  This_stg_Name <- c(format(stagionale$date,"%B"))
  print(paste("ora il ",This_stg_Name[1], FAIL_DAYS))

  stagionale$mean      <- mean(stagionale$fine)
  stagionale$sd        <- sd(stagionale$fine)
  stg_MIN              <- subset(stagionale, fine == min(stagionale$fine))
  stg_MAX              <- subset(stagionale, fine == max(stagionale$fine))
  
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting FINE
  #
  plot(ylim=c(stg_MIN$fine[1]-10,stg_MAX$fine[1]+10),
       stagionale$date, stagionale$fine, type = "h",
       mgp = c(7, 3, 0),
       xlab = "",ylab =expression(paste("Accum. part. (#/cm"^{3},") - L02")), col="lightblue", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
  lines(stagionale$date, stagionale$fine, type = "l", lty = 1, col="darkred",lwd = 2)
  title(main=paste("Ntot",questo_anno,"   ",stg_name), line = -4.5)
  
  mtext(paste("Observations from", OBS_stg_start,
              " to ", OBS_stg_end,"(",1+(as.integer(tail((OPC_L02_stg$date),1)-head((OPC_L02_stg$date)),1)),"days)       -       Statistics: ",
              "  Accum. min: (", round(min(stagionale$fine),1),") - Accum. max: (", round(max(stagionale$fine),1),") - Accum. mean: (", round(mean(stagionale$fine),1),") - Accum. sd: (", round(sd(stagionale$fine),1),")"),
                     col="black",cex = 1.7, line = -8.0, font.main = 1)
  
  points(stg_MAX$date[1], stg_MAX$fine[1], col= "magenta",pch=20)
  segments(stg_MAX$date[1], stg_MAX$fine[1], stg_MAX$date[1], stg_MIN$fine[1]-15, lty = 2, col="black",lwd = 1)
  text(stg_MAX$date[1], -0.1, labels = paste("Max","(",(format(stg_MAX$date[1],"%B %d")),")"),
       col="magenta",
       pos=1,
       cex = 1.8)
  
  points(stg_MIN$date[1], stg_MIN$fine[1], col= "blue",pch=20)
  segments(stg_MIN$date[1], stg_MIN$fine[1], stg_MIN$date[1], stg_MIN$fine[1]-15, lty = 2, col="black",lwd = 1)
  text(stg_MIN$date[1], -0.1, labels = paste("Min","(",(format(stg_MIN$date[1],"%B %d")),")"),
       col="blue",
       pos=1,
       cex = 1.8)
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting HISTOGRAMS
  #
  hist(stagionale$fine,xlab="", 
       ylab="Relative frequency",
       main="", 
       mgp = c(7, 3, 0),
       col = "mediumaquamarine", 
       border="darkred",lwd = 2)
  
  d <- density(stagionale$fine)
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
##                                              COARSE SEASONAL GRAPHS
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# -------------------------------------------------------------------------------------------
# Cleaning Destination directory
# 
FILE_PLOT_S         <-list.files(path = PLOT_DIR_S, pattern = paste(s_GAW_ID, inst_type,"_COARSE_", questo_anno,"SEASONAL_GRAPH_*",sep = "_"), 
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
OPC_L02_today_Y$season[OPC_L02_today_Y$monthNum>=1  & OPC_L02_today_Y$monthNum<=3]      <- 1
OPC_L02_today_Y$season[OPC_L02_today_Y$monthNum>=4  & OPC_L02_today_Y$monthNum<=6]      <- 2
OPC_L02_today_Y$season[OPC_L02_today_Y$monthNum>=7  & OPC_L02_today_Y$monthNum<=9]      <- 3
OPC_L02_today_Y$season[OPC_L02_today_Y$monthNum>=10 & OPC_L02_today_Y$monthNum<=12]     <- 4
#
# -------------------------------------------------------------------------------------------
# Creating temporary season tables (Level-2)
#
temp_L02$season[as.integer(temp_L02$monthNum)>=1    & as.integer(temp_L02$monthNum)<=3] <- 1
temp_L02$season[as.integer(temp_L02$monthNum)>=4    & as.integer(temp_L02$monthNum)<=6] <- 2
temp_L02$season[as.integer(temp_L02$monthNum)>=7    & as.integer(temp_L02$monthNum)<=9] <- 3
temp_L02$season[as.integer(temp_L02$monthNum)>=10   & as.integer(temp_L02$monthNum)<=12]<- 4

temp_L00$season[as.integer(temp_L00$monthNum)>=1    & as.integer(temp_L00$monthNum)<=3] <- 1
temp_L00$season[as.integer(temp_L00$monthNum)>=4    & as.integer(temp_L00$monthNum)<=6] <- 2
temp_L00$season[as.integer(temp_L00$monthNum)>=7    & as.integer(temp_L00$monthNum)<=9] <- 3
temp_L00$season[as.integer(temp_L00$monthNum)>=10   & as.integer(temp_L00$monthNum)<=12]<- 4

seasons<-c(OPC_L02_today_Y[!duplicated(OPC_L02_today_Y[,c('season')]),]$season)
seasons 
# -------------------------------------------------------------------------------------------
# Preparing plotting files
#  
PLOT_S_NAME         <-paste(s_GAW_ID,"_",inst_type,"_COARSE_",questo_anno,"_SEASONAL_GRAPH_",gsub("-","",Sys.Date()),sep = "")
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
  
  OPC_L02_stg      <-subset(OPC_L02_today_Y, season == stg)
  temp_L02_stg      <-subset(temp_L02, season == stg)
  temp_L00_stg      <-subset(temp_L00, season == stg)
  
  OBS_stg_start     <-head(format(temp_L02_stg$date,"%d %B %Y"),1)
  OBS_stg_end       <-tail(format(temp_L02_stg$date,"%d %B %Y"),1)
  
  FAIL_stg          <-subset(temp_L02_stg, numflag == 0.999)
  FAIL_stg$day      <-format(FAIL_stg$date,"%d")
  FAIL_unico        <-data.frame(FAIL_stg[!duplicated(FAIL_stg[,c('day')]),])
  FAIL_DAYS         <-nrow(FAIL_unico)
  
  stagionale<-subset(OPC_L02_stg, numflag != 0.999)
  stagionale$giorno <- format(stagionale$date,"%d")
  This_stg <- c(format(stagionale$date,"%m"))
  This_stg_Name <- c(format(stagionale$date,"%B"))
  print(paste("ora il ",This_stg_Name[1], FAIL_DAYS))
  
  stagionale$mean      <- mean(stagionale$coarse)
  stagionale$sd        <- sd(stagionale$coarse)
  stg_MIN              <- subset(stagionale, coarse == min(stagionale$coarse))
  stg_MAX              <- subset(stagionale, coarse == max(stagionale$coarse))
  
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting COARSE
  #
  plot(ylim=c(stg_MIN$coarse[1]-0.2,stg_MAX$coarse[1]+0.2),
       stagionale$date, stagionale$coarse, type = "h",
       mgp = c(7, 3, 0),
       xlab = "",ylab =expression(paste("Coarse part. (#/cm"^{3},") - L02")), col="lightblue", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
  lines(stagionale$date, stagionale$coarse, type = "l", lty = 1, col="darkred",lwd = 2)
  title(main=paste("Coarse",questo_anno,"   ",stg_name), line = -4.5)
  
  mtext(paste("Observations from", OBS_stg_start,
              " to ", OBS_stg_end,"(",1+(as.integer(tail((OPC_L02_stg$date),1)-head((OPC_L02_stg$date)),1)),"days)       -       Statistics: ",
              "  Coarse min: (", round(min(stagionale$coarse),1),") - Coarse max: (", round(max(stagionale$coarse),1),") - Coarse mean: (", round(mean(stagionale$coarse),1),") - Coarse sd: (", round(sd(stagionale$coarse),1),")"),
        col="black",cex = 1.7, line = -8.0, font.main = 1)
  
  points(stg_MAX$date[1], stg_MAX$coarse[1], col= "magenta",pch=20)
  segments(stg_MAX$date[1], stg_MAX$coarse[1], stg_MAX$date[1], stg_MIN$coarse[1]-15, lty = 2, col="black",lwd = 1)
  text(stg_MAX$date[1], -0.1, labels = paste("Max","(",(format(stg_MAX$date[1],"%B %d")),")"),
       col="magenta",
       pos=1,
       cex = 1.8)
  
  points(stg_MIN$date[1], stg_MIN$coarse[1], col= "blue",pch=20)
  segments(stg_MIN$date[1], stg_MIN$coarse[1], stg_MIN$date[1], stg_MIN$coarse[1]-15, lty = 2, col="black",lwd = 1)
  text(stg_MIN$date[1], -0.1, labels = paste("Min","(",(format(stg_MIN$date[1],"%B %d")),")"),
       col="blue",
       pos=1,
       cex = 1.8)
  #
  # -------------------------------------------------------------------------------------------
  # -------------------------------------------------------------------------------------------
  # Plotting HISTOGRAMS
  #
  hist(stagionale$coarse,xlab="", 
       ylab="Relative frequency",
       main="", 
       mgp = c(7, 3, 0),
       col = "mediumaquamarine", 
       border="darkred",lwd = 2)
  
  d <- density(stagionale$coarse)
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
OPC_L02_today_Y$mean_fine      <-mean(OPC_L02_today_Y$fine)
Y_MIN_fine                     <-subset(OPC_L02_today_Y, fine == min(OPC_L02_today_Y$fine))
Y_MAX_fine                     <-subset(OPC_L02_today_Y, fine == max(OPC_L02_today_Y$fine))
#
OPC_L02_today_Y$mean_coarse    <-mean(OPC_L02_today_Y$coarse)
Y_MIN_coarse                   <-subset(OPC_L02_today_Y, coarse == min(OPC_L02_today_Y$coarse))
Y_MAX_coarse                   <-subset(OPC_L02_today_Y, coarse == max(OPC_L02_today_Y$coarse))
#
OBS_start             <-head(format(temp_L00$date,"%d %B %Y"),1)
OBS_end               <-tail(format(temp_L00$date,"%d %B %Y"),1)
#
# -------------------------------------------------------------------------------------------
# Defining plotting parameters
#
PLOT_Y_NAME             <-paste(s_GAW_ID, inst_type, questo_anno,"ANNUAL_GRAPH_",gsub("-","",Sys.Date()),sep = "_")
PLOT_Y_NAME_FULL        <-paste (PLOT_DIR_Y,paste(PLOT_Y_NAME,".png",sep = ""),sep = "/")
png(file=,PLOT_Y_NAME_FULL, width = 2480, height = 3508)
#
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
# Plotting FINE
#
plot(ylim=c(Y_MIN_fine$fine[1]-10,Y_MAX_fine$fine[1]+10),
     xlim = c(min(c(OPC_L02_today_Y$date,temp_L01$date,temp_L00$date)),max(c(OPC_L02_today_Y$date,temp_L01$date,temp_L00$date))),
     mgp = c(8, 4, 0),
     OPC_L02_today_Y$date, OPC_L02_today_Y$fine, type = "h",
     xlab = "",ylab =expression(paste("Accum. part. (#/cm"^{3},") - L02")), col="lightblue", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
title(paste("Accumulation part. - L02 -",questo_anno), line = -3)
lines(OPC_L02_today_Y$date, OPC_L02_today_Y$fine, type = "l", lty = 1, col="darkred",lwd = 2)

points(Y_MAX_fine$date[1], Y_MAX_fine$fine[1], col= "magenta",pch=20)
text(Y_MAX_fine$date[1], Y_MAX_fine$fine[1], labels = paste0("Max (",format(Y_MAX_fine$date[1],"%B %d"),")"),col="magenta",pos=3,cex = 1.8)
segments(Y_MAX_fine$date[1], Y_MAX_fine$fine[1], Y_MAX_fine$date[1], Y_MIN_fine$fine[1]-15, lty = 2, col="black",lwd = 1)

points(Y_MIN_fine$date[1], Y_MIN_fine$fine[1], col= "blue",pch=20)
text(Y_MIN_fine$date[1], Y_MIN_fine$fine[1], labels = paste0("Min (",format(Y_MIN_fine$date[1],"%B %d"),")"),col="blue",pos=1,cex = 1.8)
segments(Y_MIN_fine$date[1], Y_MIN_fine$fine[1], Y_MIN_fine$date[1], Y_MIN_fine$fine[1]-15, lty = 2, col="black",lwd = 1)

lines(OPC_L02_today_Y$date, OPC_L02_today_Y$mean_fine, type = "l", lty = 1, col="red",lwd = 1)
text(OPC_L02_today_Y$date[1],OPC_L02_today_Y$mean_fine[1]+5, labels = c("Mean"),pos=2,col="red",cex = 1.5)
#
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# Plotting COARSE
#
plot(ylim=c(Y_MIN_coarse$coarse[1]-0.2,Y_MAX_coarse$coarse[1]+0.2),
     xlim = c(min(c(OPC_L02_today_Y$date,temp_L01$date,temp_L00$date)),max(c(OPC_L02_today_Y$date,temp_L01$date,temp_L00$date))),
     mgp = c(8, 4, 0),
     OPC_L02_today_Y$date, OPC_L02_today_Y$coarse, type = "h",
     xlab = "",ylab =expression(paste("Coarse part. (#/cm"^{3},") - L02")), col="lightblue", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
title(paste("Coarse part. - L02 -",questo_anno), line = -3)
lines(OPC_L02_today_Y$date, OPC_L02_today_Y$coarse, type = "l", lty = 1, col="darkred",lwd = 2)

points(Y_MAX_coarse$date[1], Y_MAX_coarse$coarse[1], col= "magenta",pch=20)
text(Y_MAX_coarse$date[1], Y_MAX_coarse$coarse[1], labels = paste0("Max (",format(Y_MAX_coarse$date[1],"%B %d"),")"),col="magenta",pos=3,cex = 1.8)
segments(Y_MAX_coarse$date[1], Y_MAX_coarse$coarse[1], Y_MAX_coarse$date[1], Y_MIN_coarse$coarse[1]-0.3, lty = 2, col="black",lwd = 1)

points(Y_MIN_coarse$date[1], Y_MIN_coarse$coarse[1], col= "blue",pch=20)
text(Y_MIN_coarse$date[1], Y_MIN_coarse$coarse[1], labels = paste0("Min (",format(Y_MIN_coarse$date[1],"%B %d"),")"),col="blue",pos=1,cex = 1.8)
segments(Y_MIN_coarse$date[1], Y_MIN_coarse$coarse[1], Y_MIN_coarse$date[1], Y_MIN_coarse$coarse[1]-0.3, lty = 2, col="black",lwd = 1)

lines(OPC_L02_today_Y$date,OPC_L02_today_Y$mean_coarse, type = "l", lty = 1, col="red",lwd = 1)
text(OPC_L02_today_Y$date[1],OPC_L02_today_Y$mean_coarse[1]+0.1, labels = c("Mean"),pos=2,col="red",cex = 1.5)
#
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# Plotting NUMFLAG L01
#
plot(ylim=c(0,1.1),
     xlim = c(min(c(OPC_L02_today_Y$date,temp_L01$date,temp_L00$date)),max(c(OPC_L02_today_Y$date,temp_L01$date,temp_L00$date))),
     mgp = c(8, 4, 0),
     temp_L01$date, temp_L01$numflag, type = "h",
     xlab = "",ylab =("numflag - L01"), col="tan", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 0.5))
title(paste("numflag - L01 -",questo_anno), line = -3.5)
lines(temp_L01$date, temp_L01$numflag, type = "l",
      lty = 1,
      col = "lightgreen",
      lwd = 2)
#
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# Plotting P
#
if(all(is.na(temp_L00$p_sys)))
{
  plot(ylim = c(690,890),
       xlim = c(min(c(OPC_L02_today_Y$date,temp_L01$date,temp_L00$date)),max(c(OPC_L02_today_Y$date,temp_L01$date,temp_L00$date))),
       mgp = c(8, 4, 0),
       temp_L00$date, temp_L00$p_sys, type = "h",
       xlab = "",ylab =("P_int (hPa) - L00"), col="lightblue", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
  title(paste("Internal pressure - L00 - data for this year are absent"), line = -3)
  title(paste("No data"), line = -28, cex = 0.8)
  
} else {
  plot(ylim=c(mean(temp_L00$p_sys, na.rm = TRUE)-100,mean(temp_L00$p_sys, na.rm = TRUE)+100),
       xlim = c(min(c(OPC_L02_today_Y$date,temp_L01$date,temp_L00$date)),max(c(OPC_L02_today_Y$date,temp_L01$date,temp_L00$date))),
       mgp = c(8, 4, 0),
       temp_L00$date, temp_L00$p_sys, type = "h",
       xlab = "",ylab =("P_int (hPa) - L00"), col="lightblue", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
  lines(temp_L00$date, temp_L00$p_sys, type = "l", lty = 1, col="darkblue",lwd = 0.5)
  title(paste("Internal pressure - L00 -",questo_anno), line = -3)
}
#
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# Plotting T_sys
#
if(all(is.na(temp_L00$T_sys)))
{
  plot(ylim = c(280,320),
       xlim = c(min(c(OPC_L02_today_Y$date,temp_L01$date,temp_L00$date)),max(c(OPC_L02_today_Y$date,temp_L01$date,temp_L00$date))),
       mgp = c(8, 4, 0),
       temp_L00$date, temp_L00$T_sys, type = "h",
       xlab = "",ylab =("T_int (K) - L00"), col="pink", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
  title(paste("Internal temperature - L00 - data for this year are absent"), line = -3)
  title(paste("No data"), line = -28, cex = 0.8)
  
} else {
  plot(ylim=c(mean(temp_L00$T_sys, na.rm = TRUE)-20,mean(temp_L00$T_sys, na.rm = TRUE)+20),
       xlim = c(min(c(OPC_L02_today_Y$date,temp_L01$date,temp_L00$date)),max(c(OPC_L02_today_Y$date,temp_L01$date,temp_L00$date))),
       mgp = c(8, 4, 0),
       temp_L00$date, temp_L00$T_sys, type = "h",
       xlab = "",ylab =("T_int (K) - L00"), col="pink", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
  lines(temp_L00$date, temp_L00$T_sys, type = "l", lty = 1, col="blue",lwd = 0.5)
  title(paste("Internal temperature - L00 -",questo_anno), line = -3)
}
#
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# Plotting RH
#
if(all(is.na(temp_L00$RH)))
{
  plot(ylim = c(0,100),
       xlim = c(min(c(OPC_L02_today_Y$date,temp_L01$date,temp_L00$date)),max(c(OPC_L02_today_Y$date,temp_L01$date,temp_L00$date))),
       mgp = c(8, 4, 0),
       temp_L00$date, temp_L00$RH, type = "h",
       xlab = "",ylab =("RH (%) - L00"), col="pink", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
  title(paste("Relative humidity - L00 - data for this year are absent"), line = -3)
  title(paste("No data"), line = -28, cex = 0.8)
  
} else {
  plot(ylim=c(0,100),
       xlim = c(min(c(OPC_L02_today_Y$date,temp_L01$date,temp_L00$date)),max(c(OPC_L02_today_Y$date,temp_L01$date,temp_L00$date))),
       mgp = c(8, 4, 0),
       temp_L00$date, temp_L00$RH, type = "h",
       xlab = "",ylab =("RH (%) - L00"), col="seashell", panel.first = grid(nx=0,ny=NULL, lty = 1, lwd = 1))
  lines(temp_L00$date, temp_L00$RH, type = "l", lty = 1, col="mediumorchid4",lwd = 0.5)
  title(paste("Relative humidity - L00 -",questo_anno), line = -3)
}
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
                                 "(days of observation: ", 1+(as.integer(tail((OPC_L02_today_Y$date),1)-head((OPC_L02_today_Y$date)),1)),")")
     , cex = 2.8, col = "black",pos = 4)


plot(c(0, 1), c(0, 1), ann = F, bty = 'n', type = 'n', xaxt = 'n', yaxt = 'n')
text(x = 0, y = 0.95, paste ("Statistics  -  ",questo_anno),
     cex = 3.3, col = "darkred",pos = 4) 

if(is.null(mesi_FAIL_COUNT$print)){
  text(x = 0, y = 0.35, paste("\n", "Accum. min: (", round(min(OPC_L02_today_Y$fine),1),") - Accum. max: (", round(max(OPC_L02_today_Y$fine),1),") - Accum. mean: (", round(mean(OPC_L02_today_Y$fine),1),") - Accum. sd: (", round(sd(OPC_L02_today_Y$fine),1),")",
                              "\n",
                              "Accum. percentile:    5th: (",round(quantile(OPC_L02_today_Y$fine, probs = c(0.05)),digits=1),")",
                              " - 25th: (",round(quantile(OPC_L02_today_Y$fine, probs = c(0.25)),digits=1),")",
                              " - 50th: (",round(quantile(OPC_L02_today_Y$fine, probs = c(0.50)),digits=1),")",
                              " - 75th: (",round(quantile(OPC_L02_today_Y$fine, probs = c(0.75)),digits=1),")",
                              " - 95th: (",round(quantile(OPC_L02_today_Y$fine, probs = c(0.95)),digits=1),")","\n",
                              "\n", "Coarse min: (", round(min(OPC_L02_today_Y$coarse),1),") - Coarse max: (", round(max(OPC_L02_today_Y$coarse),1),") - Coarse mean: (", round(mean(OPC_L02_today_Y$coarse),1),") - Coarse sd: (", round(sd(OPC_L02_today_Y$coarse),1),")",
                              "\n",
                              "Coarse percentile:    5th: (",round(quantile(OPC_L02_today_Y$coarse, probs = c(0.05)),digits=1),")",
                              " - 25th: (",round(quantile(OPC_L02_today_Y$coarse, probs = c(0.25)),digits=1),")",
                              " - 50th: (",round(quantile(OPC_L02_today_Y$coarse, probs = c(0.50)),digits=1),")",
                              " - 75th: (",round(quantile(OPC_L02_today_Y$coarse, probs = c(0.75)),digits=1),")",
                              " - 95th: (",round(quantile(OPC_L02_today_Y$coarse, probs = c(0.95)),digits=1),")","\n","\n",
                              "L02 numflag = 0.999 (number of days of the year):   ", sum(mesi_FAIL_COUNT$freq), 
                              " (",round((sum(mesi_FAIL_COUNT$freq)/(length(diy(as.numeric(questo_anno)))))*100,digits=2),"%)",
                              "\n","Months affected:",
                              "\n",
                              if (nrow(mesi_FAIL_COUNT)==0){"none"},
                              if (!is.null(mesi_FAIL_COUNT$print[1])){mesi_FAIL_COUNT$print[1]}  ,"   ",
                              if (!is.null(mesi_FAIL_COUNT$print[2])){mesi_FAIL_COUNT$print[2]}  ,"   ",
                              if (!is.null(mesi_FAIL_COUNT$print[3])){mesi_FAIL_COUNT$print[3]}  ,"   ",
                              if (!is.null(mesi_FAIL_COUNT$print[4])){mesi_FAIL_COUNT$print[4]}  ,"\n",
                              if (!is.null(mesi_FAIL_COUNT$print[5])){mesi_FAIL_COUNT$print[5]}  ,"   ",
                              if (!is.null(mesi_FAIL_COUNT$print[6])){mesi_FAIL_COUNT$print[6]}  ,"   ",
                              if (!is.null(mesi_FAIL_COUNT$print[7])){mesi_FAIL_COUNT$print[7]}  ,"   ",
                              if (!is.null(mesi_FAIL_COUNT$print[8])){mesi_FAIL_COUNT$print[8]}  ,"\n",
                              if (!is.null(mesi_FAIL_COUNT$print[9])){mesi_FAIL_COUNT$print[9]}  ,"   ",
                              if (!is.null(mesi_FAIL_COUNT$print[10])){mesi_FAIL_COUNT$print[10]},"   ",
                              if (!is.null(mesi_FAIL_COUNT$print[11])){mesi_FAIL_COUNT$print[11]},"   ",
                              if (!is.null(mesi_FAIL_COUNT$print[12])){mesi_FAIL_COUNT$print[12]},
                              sep=""), cex = 2.8, col = "black",pos = 4) 
} else {
  text(x = 0, y = 0.35, paste("\n", "Accum. min: (", round(min(OPC_L02_today_Y$fine),1),") - Accum. max: (", round(max(OPC_L02_today_Y$fine),1),") - Accum. mean: (", round(mean(OPC_L02_today_Y$fine),1),") - Accum. sd: (", round(sd(OPC_L02_today_Y$fine),1),")",
                              "\n",
                              "Accum. percentile:    5th: (",round(quantile(OPC_L02_today_Y$fine, probs = c(0.05)),digits=1),")",
                              " - 25th: (",round(quantile(OPC_L02_today_Y$fine, probs = c(0.25)),digits=1),")",
                              " - 50th: (",round(quantile(OPC_L02_today_Y$fine, probs = c(0.50)),digits=1),")",
                              " - 75th: (",round(quantile(OPC_L02_today_Y$fine, probs = c(0.75)),digits=1),")",
                              " - 95th: (",round(quantile(OPC_L02_today_Y$fine, probs = c(0.95)),digits=1),")","\n",
                              "\n", "Coarse min: (", round(min(OPC_L02_today_Y$coarse),1),") - Coarse max: (", round(max(OPC_L02_today_Y$coarse),1),") - Coarse mean: (", round(mean(OPC_L02_today_Y$coarse),1),") - Coarse sd: (", round(sd(OPC_L02_today_Y$coarse),1),")",
                              "\n",
                              "Coarse percentile:    5th: (",round(quantile(OPC_L02_today_Y$coarse, probs = c(0.05)),digits=1),")",
                              " - 25th: (",round(quantile(OPC_L02_today_Y$coarse, probs = c(0.25)),digits=1),")",
                              " - 50th: (",round(quantile(OPC_L02_today_Y$coarse, probs = c(0.50)),digits=1),")",
                              " - 75th: (",round(quantile(OPC_L02_today_Y$coarse, probs = c(0.75)),digits=1),")",
                              " - 95th: (",round(quantile(OPC_L02_today_Y$coarse, probs = c(0.95)),digits=1),")","\n","\n",
                              "L02 numflag = 0.999 (number of days of the year):   ", sum(mesi_FAIL_COUNT$freq), 
                              " (",round((sum(mesi_FAIL_COUNT$freq)/(length(diy(as.numeric(questo_anno)))))*100,digits=2),"%)",
                              "\n","Months affected:",
                              "\n",
                              if (nrow(mesi_FAIL_COUNT)==0){"none"},
                              if (!is.na(mesi_FAIL_COUNT$print[1])){mesi_FAIL_COUNT$print[1]}  ,"   ",
                              if (!is.na(mesi_FAIL_COUNT$print[2])){mesi_FAIL_COUNT$print[2]}  ,"   ",
                              if (!is.na(mesi_FAIL_COUNT$print[3])){mesi_FAIL_COUNT$print[3]}  ,"   ",
                              if (!is.na(mesi_FAIL_COUNT$print[4])){mesi_FAIL_COUNT$print[4]}  ,"\n",
                              if (!is.na(mesi_FAIL_COUNT$print[5])){mesi_FAIL_COUNT$print[5]}  ,"   ",
                              if (!is.na(mesi_FAIL_COUNT$print[6])){mesi_FAIL_COUNT$print[6]}  ,"   ",
                              if (!is.na(mesi_FAIL_COUNT$print[7])){mesi_FAIL_COUNT$print[7]}  ,"   ",
                              if (!is.na(mesi_FAIL_COUNT$print[8])){mesi_FAIL_COUNT$print[8]}  ,"\n",
                              if (!is.na(mesi_FAIL_COUNT$print[9])){mesi_FAIL_COUNT$print[9]}  ,"   ",
                              if (!is.na(mesi_FAIL_COUNT$print[10])){mesi_FAIL_COUNT$print[10]},"   ",
                              if (!is.na(mesi_FAIL_COUNT$print[11])){mesi_FAIL_COUNT$print[11]},"   ",
                              if (!is.na(mesi_FAIL_COUNT$print[12])){mesi_FAIL_COUNT$print[12]},
                              sep=""), cex = 2.8, col = "black",pos = 4) 
}
dev.off()
##                                          # END PART 3.3 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.4 #
## ______________________________________________________________________________________________________________________##
##                                    Creating statistcs/graphic reports
##                                               FINE CALENDAR PLOT
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Cleaning Destination directory
# 
FILE_PLOT_Y             <-list.files(path = PLOT_DIR_Y, pattern = paste(s_GAW_ID, inst_type,"ACCUM", questo_anno,"CALENDAR_GRAPH_*",sep = "_"), all.files = FALSE,
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
calendar_table <- OPC_L02_today_Y

perc <- quantile(calendar_table$fine, c(0.05, 0.95))

calendar_table$fine[calendar_table$fine < min(perc)] <- min(perc)
calendar_table$fine[calendar_table$fine > max(perc)] <- max(perc)

PLOT_C_NAME             <-paste(s_GAW_ID, inst_type,"ACCUM", questo_anno,"CALENDAR_GRAPH",gsub("-","",Sys.Date()),sep = "_")
PLOT_C_NAME_FULL        <-paste (PLOT_DIR_Y,paste(PLOT_C_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_C_NAME_FULL, width=2100,height=2970,res=250)
calendarPlot(calendar_table, pollutant = "fine", year = questo_anno, month=c(1:12), auto.text = TRUE,
             key.footer = expression(paste("Accum. part. (#/cm"^{3},")")), key.position = "right", key = TRUE,
             main = paste("Accum. part. in",questo_anno))
dev.off()
##                                          # END PART 3.4 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.4.1 #
## ______________________________________________________________________________________________________________________##
##                                    Creating statistcs/graphic reports
##                                               COARSE CALENDAR PLOT
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Cleaning Destination directory
# 
FILE_PLOT_Y             <-list.files(path = PLOT_DIR_Y, pattern = paste(s_GAW_ID, inst_type,"COARSE", questo_anno,"CALENDAR_GRAPH_*",sep = "_"), all.files = FALSE,
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
calendar_table <- OPC_L02_today_Y

perc <- quantile(calendar_table$coarse, c(0.05, 0.95))

calendar_table$coarse[calendar_table$coarse < min(perc)] <- min(perc)
calendar_table$coarse[calendar_table$coarse > max(perc)] <- max(perc)

PLOT_C_NAME             <-paste(s_GAW_ID, inst_type,"COARSE", questo_anno,"CALENDAR_GRAPH",gsub("-","",Sys.Date()),sep = "_")
PLOT_C_NAME_FULL        <-paste (PLOT_DIR_Y,paste(PLOT_C_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_C_NAME_FULL, width=2100,height=2970,res=250)
calendarPlot(calendar_table, pollutant = "coarse", year = questo_anno, month=c(1:12), auto.text = TRUE,
             key.footer = expression(paste("Coarse part. (#/cm"^{3},")")), key.position = "right", key = TRUE,
             main = paste("Coarse part. in",questo_anno))
dev.off()
##                                          # END PART 3.4 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.5 #
## ______________________________________________________________________________________________________________________##
##                                    Creating timevariation reports
##                                        FINE ANNUAL TIMEVARIATION
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Cleaning Destination directory
#
FILE_PLOT_TVA             <-list.files(path = PLOT_DIR_T, pattern = paste(s_GAW_ID, inst_type, questo_anno,"TIMEVARIATION_GRAPH_*",sep = "_"), all.files = FALSE,
                                       full.names = F, recursive = FALSE,
                                       ignore.case = FALSE, include.dirs = F, no.. = FALSE)
FILE_PLOT_TVA
LISTA_PLOT_TVA            <-as.character(FILE_PLOT_TVA)

for(f in LISTA_PLOT_TVA)  { file.remove(paste(PLOT_DIR_T,f,sep = "/")) }
#
# -------------------------------------------------------------------------------------------
# Creating data subset
#
mydata                    <-data.frame(OPC_L02_today_Y$date,OPC_L02_today_Y$fine)
colnames(mydata)          <- c("date","fine")
#
# -------------------------------------------------------------------------------------------
# Plotting temporary hourly timevariation
#
PLOT_TVH_NAME             <-paste("tmp_H",s_GAW_ID, inst_type,"ACCUM",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVH_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVH_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVH_NAME_FULL, width=930,height=900,res=250)

TV_ANNUAL_H               <-timeVariation(mydata, pollutant = "fine", normalise = FALSE, 
                                          ylab = paste("Accum. part. (#/cm3) -",questo_anno),
                                          xlab = c("Hour","Hour","Month","Weekday"),cols = c("cornflowerblue"), key = NULL)
plot(TV_ANNUAL_H$plot$hour)

dev.off()
#
# -------------------------------------------------------------------------------------------
# Plotting temporary daily timevariation
#
PLOT_TVD_NAME             <-paste("tmp_D",s_GAW_ID, inst_type,"ACCUM",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVD_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVD_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVD_NAME_FULL, width=930,height=900,res=250)

TV_ANNUAL_H               <-timeVariation(mydata, pollutant = "fine", normalise = FALSE, 
                                          ylab = paste("Accum. part. (#/cm3) -",questo_anno),
                                          xlab = c("Hour","Hour","Month","Weekday"),cols = c("cornflowerblue"), key = NULL)
plot(TV_ANNUAL_H$plot$day)

dev.off()
#
# -------------------------------------------------------------------------------------------
# Plotting temporary monthly timevariation
#
PLOT_TVM_NAME             <-paste("tmp_M",s_GAW_ID, inst_type,"ACCUM",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVM_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVM_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVM_NAME_FULL, width=930,height=900,res=250)

TV_ANNUAL_H               <-timeVariation(mydata, pollutant = "fine", normalise = FALSE, 
                                          ylab = paste("Accum. part. (#/cm3) -",questo_anno),
                                          xlab = c("Hour","Hour","Month","Weekday"),cols = c("cornflowerblue"), key = NULL)
plot(TV_ANNUAL_H$plot$month)
dev.off()
#
# -------------------------------------------------------------------------------------------
# Merging temporary plots to final report
#
imgH                      <- readPNG(PLOT_TVH_NAME_FULL)
imgD                      <- readPNG(PLOT_TVD_NAME_FULL)
imgM                      <- readPNG(PLOT_TVM_NAME_FULL)

PLOT_TVF_NAME             <-paste(s_GAW_ID, inst_type,"ACCUM",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVF_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVF_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVF_NAME_FULL, width=2970,height=2100,res=500)

par(mar=c(1.1, 1.1, 1.1, 1.1), mgp=c(-1.5, 1, 0), las=0)
par(ps = 14, cex.lab = 0.5)

TV_ANNUAL_H               <-timeVariation(mydata, pollutant = "fine", normalise = FALSE, 
                                          ylab = paste("Accum. part. (#/cm3) -",questo_anno),
                                          xlab = c("Hour","Hour","Month","Weekday"),cols = c("cornflowerblue"), key = NULL)

plot(0:297, ty="n",xaxt = "n",yaxt = "n",xlab = paste("Accum. part. - ",questo_anno," - annual trend analysis",sep=" "),ylab = "")
#
# -------------------------------------------------------------------------------------------
# Specifying the position of the image through bottom-left and top-right coords
#
rasterImage(imgH, -5,80,100,220)
rasterImage(imgD,100,80,205,220)
rasterImage(imgM,205,80,309,220)

dev.off() 
#
# -------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------
# Plotting annual by season
# Plotting temporary monthly timevariation
#
fine_hh                 <- timeAverage(mydata, avg.time = "hour", data.thresh = 75, statistic = "mean",
                                         start.date = mydata$date[1], 
                                         end.date = mydata$date[length(mydata)], 
                                         interval = "hour")

fine_tv                 <- timeVariation(fine_hh, pollutant = "fine", type = "season", conf.int = 0.95,
                                           xlab = c("Hour","Hour","Month","Weekday"), 
                                           ylab = paste("Accum. part. (#/cm3) -",questo_anno), 
                                           name.pol = "Accum",
                                           cols = c("cornflowerblue"))

PLOT_TVN1_NAME            <-paste("tmp_s1_ACCUM_",questo_anno,"_TIMEVARIATION_GRAPH_SEASONAL_",gsub("-","",Sys.Date()),sep = "")
PLOT_TVN1_NAME_FULL       <-paste (PLOT_DIR_T,paste(PLOT_TVN1_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVN1_NAME_FULL, width=930,height=900,res=150)
plot(fine_tv$plot$day)

dev.off() 

PLOT_TVN2_NAME            <-paste("tmp_s2_ACCUM_",questo_anno,"_TIMEVARIATION_GRAPH_SEASONAL_",gsub("-","",Sys.Date()),sep = "")
PLOT_TVN2_NAME_FULL       <-paste (PLOT_DIR_T,paste(PLOT_TVN2_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVN2_NAME_FULL, width=930,height=900,res=150)
plot(fine_tv$plot$hour)
dev.off()
#
# -------------------------------------------------------------------------------------------
# Merging temporary plots to final report
#
imgN1                     <- readPNG(PLOT_TVN1_NAME_FULL)
imgN2                     <- readPNG(PLOT_TVN2_NAME_FULL)

PLOT_TVF_NAME             <-paste(s_GAW_ID, inst_type,"ACCUM",questo_anno,"TIMEVARIATION_GRAPH_SEASONAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVF_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVF_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVF_NAME_FULL, width=2970,height=2100,res=500)

par(mar=c(1.1, 1.1, 1.1, 1.1), mgp=c(-1.5, 1, 0), las=0)
par(ps = 14, cex.lab = 0.5)

plot(0:297, ty="n",xaxt = "n",yaxt = "n",xlab = paste("Accum. part. - ",questo_anno," - trend analysis by season",sep=" "),ylab = "")

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
##                                        COARSE ANNUAL TIMEVARIATION
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Cleaning Destination directory
#
FILE_PLOT_TVA             <-list.files(path = PLOT_DIR_T, pattern = paste(s_GAW_ID, inst_type, questo_anno,"TIMEVARIATION_GRAPH_*",sep = "_"), all.files = FALSE,
                                       full.names = F, recursive = FALSE,
                                       ignore.case = FALSE, include.dirs = F, no.. = FALSE)
FILE_PLOT_TVA
LISTA_PLOT_TVA            <-as.character(FILE_PLOT_TVA)

for(f in LISTA_PLOT_TVA)  { file.remove(paste(PLOT_DIR_T,f,sep = "/")) }
#
# -------------------------------------------------------------------------------------------
# Creating data subset
#
mydata                    <-data.frame(OPC_L02_today_Y$date,OPC_L02_today_Y$coarse)
colnames(mydata)          <- c("date","coarse")
#
# -------------------------------------------------------------------------------------------
# Plotting temporary hourly timevariation
#
PLOT_TVH_NAME             <-paste("tmp_H",s_GAW_ID, inst_type,"COARSE",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVH_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVH_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVH_NAME_FULL, width=930,height=900,res=250)

TV_ANNUAL_H               <-timeVariation(mydata, pollutant = "coarse", normalise = FALSE, 
                                          ylab = paste("Coarse part. (#/cm3) -",questo_anno),
                                          xlab = c("Hour","Hour","Month","Weekday"),cols = c("cornflowerblue"), key = NULL)
plot(TV_ANNUAL_H$plot$hour)

dev.off()
#
# -------------------------------------------------------------------------------------------
# Plotting temporary daily timevariation
#
PLOT_TVD_NAME             <-paste("tmp_D",s_GAW_ID, inst_type,"COARSE",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVD_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVD_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVD_NAME_FULL, width=930,height=900,res=250)

TV_ANNUAL_H               <-timeVariation(mydata, pollutant = "coarse", normalise = FALSE, 
                                          ylab = paste("Coarse part. (#/cm3) -",questo_anno),
                                          xlab = c("Hour","Hour","Month","Weekday"),cols = c("cornflowerblue"), key = NULL)
plot(TV_ANNUAL_H$plot$day)

dev.off()
#
# -------------------------------------------------------------------------------------------
# Plotting temporary monthly timevariation
#
PLOT_TVM_NAME             <-paste("tmp_M",s_GAW_ID, inst_type,"COARSE",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVM_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVM_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVM_NAME_FULL, width=930,height=900,res=250)

TV_ANNUAL_H               <-timeVariation(mydata, pollutant = "coarse", normalise = FALSE, 
                                          ylab = paste("Coarse part. (#/cm3) -",questo_anno),
                                          xlab = c("Hour","Hour","Month","Weekday"),cols = c("cornflowerblue"), key = NULL)
plot(TV_ANNUAL_H$plot$month)
dev.off()
#
# -------------------------------------------------------------------------------------------
# Merging temporary plots to final report
#
imgH                      <- readPNG(PLOT_TVH_NAME_FULL)
imgD                      <- readPNG(PLOT_TVD_NAME_FULL)
imgM                      <- readPNG(PLOT_TVM_NAME_FULL)

PLOT_TVF_NAME             <-paste(s_GAW_ID, inst_type,"COARSE",questo_anno,"TIMEVARIATION_GRAPH_ANNUAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVF_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVF_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVF_NAME_FULL, width=2970,height=2100,res=500)

par(mar=c(1.1, 1.1, 1.1, 1.1), mgp=c(-1.5, 1, 0), las=0)
par(ps = 14, cex.lab = 0.5)

plot(0:297, ty="n",xaxt = "n",yaxt = "n",xlab = paste("Coarse part. - ",questo_anno," - annual trend analysis",sep=" "),ylab = "")
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
# -------------------------------------------------------------------------------------------
# Plotting annual by season
# Plotting temporary annual timevariation
#
coarse_hh                 <- timeAverage(mydata, avg.time = "hour", data.thresh = 75, statistic = "mean",
                                         start.date = mydata$date[1], 
                                         end.date = mydata$date[length(mydata)], 
                                         interval = "hour")

coarse_tv                 <- timeVariation(coarse_hh, pollutant = "coarse", type = "season", conf.int = 0.95,
                                           xlab = c("Hour","Hour","Month","Weekday"), 
                                           ylab = paste("Coarse part. (#/cm3) -",questo_anno), 
                                           name.pol = "Coarse",
                                           cols = c("cornflowerblue"))
   

PLOT_TVN1_NAME            <-paste("tmp_s1_COARSE_",questo_anno,"_TIMEVARIATION_GRAPH_SEASONAL_",gsub("-","",Sys.Date()),sep = "")
PLOT_TVN1_NAME_FULL       <-paste (PLOT_DIR_T,paste(PLOT_TVN1_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVN1_NAME_FULL, width=930,height=900,res=150)
plot(coarse_tv$plot$day)

dev.off() 
                        
PLOT_TVN2_NAME            <-paste("tmp_s2_COARSE_",questo_anno,"_TIMEVARIATION_GRAPH_SEASONAL_",gsub("-","",Sys.Date()),sep = "")
PLOT_TVN2_NAME_FULL       <-paste (PLOT_DIR_T,paste(PLOT_TVN2_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVN2_NAME_FULL, width=930,height=900,res=150)
plot(coarse_tv$plot$hour)
dev.off()
#
# -------------------------------------------------------------------------------------------
# Merging temporary plots to final report
#
imgN1                     <- readPNG(PLOT_TVN1_NAME_FULL)
imgN2                     <- readPNG(PLOT_TVN2_NAME_FULL)

PLOT_TVF_NAME             <-paste(s_GAW_ID, inst_type,"COARSE",questo_anno,"TIMEVARIATION_GRAPH_SEASONAL",gsub("-","",Sys.Date()),sep = "_")
PLOT_TVF_NAME_FULL        <-paste (PLOT_DIR_T,paste(PLOT_TVF_NAME,".png",sep = ""),sep = "/")

png(file=,PLOT_TVF_NAME_FULL, width=2970,height=2100,res=500)

par(mar=c(1.1, 1.1, 1.1, 1.1), mgp=c(-1.5, 1, 0), las=0)
par(ps = 14, cex.lab = 0.5)

plot(0:297, ty="n",xaxt = "n",yaxt = "n",xlab = paste("Coarse part. - ",questo_anno," - trend analysis by season",sep=""),ylab = "")

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
##                                        FINE MONTHLY TIMEVARIATION
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Cleaning Destination directory
#
unico_T                   <-c(OPC_L02_today_Y[!duplicated(OPC_L02_today_Y[,c('monthNum')]),]$monthNum)

for (qm in unico_T)
{ print(qm)
  #
  # -------------------------------------------------------------------------------------------
  # Creating data subset
  #
  OPC_L02_ThisMonth       <-subset(OPC_L02_today, as.integer(monthNum)==qm)
  temp_L02_ThisMonth      <-subset(temp_L02, as.integer(monthNum)==qm)
  temp_L00_ThisMonth      <-subset(temp_L00, as.integer(monthNum)==qm)
  
  OBS_Month_start         <-head(format(temp_L02_ThisMonth$date,"%d %B %Y"),1)
  OBS_Month_end           <-tail(format(temp_L02_ThisMonth$date,"%d %B %Y"),1)

  mensile                 <-subset(OPC_L02_ThisMonth, numflag != 0.999)
  
  mensile$giorno          <-format(mensile$date,"%d")
  This_Month              <-format(mensile$date,"%m")[1]
  This_Month_Name         <-format(mensile$date,"%B")[1]

  mensile$mean     <- mean(mensile$fine)
  mensile$sd       <- sd(mensile$fine)
  men_MIN          <- subset(mensile, fine == min(mensile$fine))
  men_MAX          <- subset(mensile, fine == max(mensile$fine))
  
  mydata <- data.frame(mensile$date,mensile$fine)
  colnames(mydata) <- c("date","fine")
  
  PLOT_TV_NAME            <-paste(s_GAW_ID, inst_type,"ACCUM",questo_anno,"TIMEVARIATION_GRAPH",This_Month,"MONTHLY",gsub("-","",Sys.Date()),sep = "_")
  PLOT_TV_NAME_FULL       <-paste (PLOT_DIR_T,paste(PLOT_TV_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_TV_NAME_FULL, width = 960, height = 960)
  par(ps = 14, cex = 1.5, cex.main = 2.2, mai=c(0.3,1.8,0.5,0.5)) 
  
  myOutput                <-timeVariation(mydata, pollutant = "fine", ylab = paste("Accum. part. (#/cm3) -",questo_anno), type="season",
                                         xlab = paste("CGR - month variation \n - ",questo_anno," ",This_Month_Name," -"),
                                         cols = c("cornflowerblue"))
  dev.off()
  #
  # -------------------------------------------------------------------------------------------
  # Plotting temporary hourly timevariation
  #
  PLOT_TVH_NAME           <-paste("tmp_H_",s_GAW_ID, inst_type,questo_anno,"_TIMEVARIATION_GRAPH_",This_Month,"MONTHLY_",gsub("-","",Sys.Date()),sep = "")
  PLOT_TVH_NAME_FULL      <-paste (PLOT_DIR_T,paste(PLOT_TVH_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_TVH_NAME_FULL, width=1860,height=900,res=250)
  #par(ps = 14, cex = 1.5, cex.main = 2.2, mai=c(0.3,1.8,0.5,0.5)) 
  
  myOutput                <-timeVariation(mydata, pollutant = "fine", ylab = paste("Accum. part. (#/cm3) -",questo_anno), type="season",
                                          xlab = ,
                                          cols = c("cornflowerblue"))
  
  TV_ANNUAL_H             <-timeVariation(mydata, pollutant = "fine", ylab = paste("Accum. part. (#/cm3) -",questo_anno),
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
  
  PLOT_TVF_NAME         <-paste(s_GAW_ID, inst_type,"ACCUM",questo_anno,"TIMEVARIATION_GRAPH",This_Month,"MONTHLY",gsub("-","",Sys.Date()),sep = "_")
  PLOT_TVF_NAME_FULL    <-paste (PLOT_DIR_T,paste(PLOT_TVF_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_TVF_NAME_FULL, width=2970,height=2100,res=500)
  
  par(mar=c(1.1, 1.1, 1.1, 1.1), mgp=c(-1.5, 1, 0), las=0)
  par(ps = 14, cex.lab = 0.5)
  
  plot(0:297, ty="n",xaxt = "n",yaxt = "n",
       xlab = paste("Accum. part. - ",This_Month_Name," ",questo_anno," - monthly trend analysis",sep=" "),ylab = "")
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
##                                          # END PART 3.6 #
###########################################################################################################################


###########################################################################################################################
##                                           # PART 3.6.1 #
## ______________________________________________________________________________________________________________________##
##                                    Creating timevariation reports
##                                        COARSE MONTHLY TIMEVARIATION
##                                     Cleaning Destination directory
##
## ______________________________________________________________________________________________________________________##
# Cleaning Destination directory
#
unico_T                   <-c(OPC_L02_today_Y[!duplicated(OPC_L02_today_Y[,c('monthNum')]),]$monthNum)

for (qm in unico_T)
{ print(qm)
  #
  # -------------------------------------------------------------------------------------------
  # Creating data subset
  #
  OPC_L02_ThisMonth       <-subset(OPC_L02_today, as.integer(monthNum)==qm)
  temp_L02_ThisMonth      <-subset(temp_L02, as.integer(monthNum)==qm)
  temp_L00_ThisMonth      <-subset(temp_L00, as.integer(monthNum)==qm)
  
  OBS_Month_start         <-head(format(temp_L02_ThisMonth$date,"%d %B %Y"),1)
  OBS_Month_end           <-tail(format(temp_L02_ThisMonth$date,"%d %B %Y"),1)
  
  mensile                 <-subset(OPC_L02_ThisMonth, numflag != 0.999)
  
  mensile$giorno          <-format(mensile$date,"%d")
  This_Month              <-format(mensile$date,"%m")[1]
  This_Month_Name         <-format(mensile$date,"%B")[1]
  
  mensile$mean     <- mean(mensile$coarse)
  mensile$sd       <- sd(mensile$coarse)
  men_MIN          <- subset(mensile, coarse == min(mensile$coarse))
  men_MAX          <- subset(mensile, coarse == max(mensile$coarse))
  
  mydata <- data.frame(mensile$date,mensile$coarse)
  colnames(mydata) <- c("date","coarse")
  
  PLOT_TV_NAME            <-paste(s_GAW_ID, inst_type,"COARSE", questo_anno,"TIMEVARIATION_GRAPH",This_Month,"MONTHLY",gsub("-","",Sys.Date()),sep = "_")
  PLOT_TV_NAME_FULL       <-paste (PLOT_DIR_T,paste(PLOT_TV_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_TV_NAME_FULL, width = 960, height = 960)
  par(ps = 14, cex = 1.5, cex.main = 2.2, mai=c(0.3,1.8,0.5,0.5)) 
  
  myOutput                <-timeVariation(mydata, pollutant = "coarse", ylab = paste("Coarse part. (#/cm3) -",questo_anno), type="season",
                                          xlab = paste("CGR - month variation \n - ",questo_anno," ",This_Month_Name," -"),
                                          cols = c("cornflowerblue"))
  dev.off()
  #
  # -------------------------------------------------------------------------------------------
  # Plotting temporary hourly timevariation
  #
  PLOT_TVH_NAME           <-paste("tmp_H_",s_GAW_ID, inst_type,questo_anno,"_TIMEVARIATION_GRAPH_",This_Month,"MONTHLY_",gsub("-","",Sys.Date()),sep = "")
  PLOT_TVH_NAME_FULL      <-paste (PLOT_DIR_T,paste(PLOT_TVH_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_TVH_NAME_FULL, width=1860,height=900,res=250)
  #par(ps = 14, cex = 1.5, cex.main = 2.2, mai=c(0.3,1.8,0.5,0.5)) 
  
  myOutput                <-timeVariation(mydata, pollutant = "coarse", ylab = paste("Coarse part. (#/cm3) -",questo_anno), type="season",
                                          xlab = ,
                                          cols = c("cornflowerblue"))
  
  TV_ANNUAL_H             <-timeVariation(mydata, pollutant = "coarse", ylab = paste("Coarse part. (#/cm3) -",questo_anno),
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
  
  PLOT_TVF_NAME         <-paste(s_GAW_ID, inst_type,"COARSE",questo_anno,"TIMEVARIATION_GRAPH",This_Month,"MONTHLY",gsub("-","",Sys.Date()),sep = "_")
  PLOT_TVF_NAME_FULL    <-paste (PLOT_DIR_T,paste(PLOT_TVF_NAME,".png",sep = ""),sep = "/")
  
  png(file=,PLOT_TVF_NAME_FULL, width=2970,height=2100,res=500)
  
  par(mar=c(1.1, 1.1, 1.1, 1.1), mgp=c(-1.5, 1, 0), las=0)
  par(ps = 14, cex.lab = 0.5)
  
  plot(0:297, ty="n",xaxt = "n",yaxt = "n",
       xlab = paste("Coarse part. - ",This_Month_Name," ",questo_anno," - monthly trend analysis",sep=" "),ylab = "")
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
##                                          # END PART 3.6 #
###########################################################################################################################
#                                                                                                                         #
## End of OPC_D22_1810.R                                                                                                  # 
#                                                                                                                         # 
###################################################################################### Authors: L u C A, Davide ###########

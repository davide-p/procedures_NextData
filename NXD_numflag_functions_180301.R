# This function adds the numflag value to the already existing numflag.
# E.g., if the actual numflag[i] is 0.640, and we also want to add
# 0.682, the final result would be 0.640682, according to EBAS guidelines
# on numflags. The final numflags will also be sorted.
# Input:
# nf_old          = old numflag value
# nf_new          = new numflag value to be added
# n_decim         = number of decimal digits (default is 9) 
# Output:
# nf_new_complete = new aggregated numflag
# ------------------------------------------------------------------------
# created by: Davide Putero, February 2018.
# ------------------------------------------------------------------------

nf_aggreg <- function(nf_old,nf_new,n_decim){
  if (missing(n_decim)) {n_decim <- 9} # Set default value of n_decim to 9, if missing
  if (nf_old == 0){
    nf_new_complete <- nf_new # If old numflag is 0, then only the new numflag is needed
  } else if (nf_old == 0.999){
    nf_new_complete <- 0.999  # If old numflag is 0.999, then it remains 0.999
  } else {
    nf_old <- substr(sprintf(paste0("%.",n_decim,"f"),nf_old), start = 3, stop = n_decim+2) # Old complete numflag
    nf_new <- as.character(nf_new*10^3)                                                     # New numflag
    
    pos <- seq(1,n_decim, by=3)       # Find positions of all old numflags
    old_nfgs <- sapply(pos, function(ii) {substr(nf_old, ii, ii+2)}) # Retrieve a list of old numflags
    all_nfgs <- sort(unique(c(old_nfgs,nf_new)))   # Retrieve unique old numflags only and sort them 
    nf_new_complete <- as.numeric(paste0("0.",paste0(all_nfgs[2:length(all_nfgs)], collapse = ""))) # Starts from 2 so that 000 is skipped
  }
  return(nf_new_complete)
}


# This function builds the hourly numflag, composed by the aggregation of
# all possible numflags (except the ones specified in input) that are 
# present in every minute of the hour considered, according to EBAS 
# guidelines.
# Input:
# numflags_mm          = array of numflags at 1-min resolution
# startime_mm          = array of starttime for those numflags (in daydec)
# startime_hh          = single value of hourly starttime
# nv_numflags          = array of (char) numflag values than must not be reported at lev2, e.g., c("000","456","682")
# endtime_hh           = single value of hourly endtime (optional, default is startime_hh + 1 hour)
# Output:
# numflag_hh           = single value of created hourly numflag
# ------------------------------------------------------------------------
# created by: Davide Putero, February 2018.
# ------------------------------------------------------------------------
library(stringi)
nf_lev2 <- function(numflags_mm, startime_mm, startime_hh, nv_numflags, endtime_hh){
  if (missing(endtime_hh)) {endtime_hh <- startime_hh + 1/24} # Set default value of startime_hh + 1 hour, if missing
  pos <- (startime_mm >= startime_hh & startime_mm < endtime_hh) # Find position of the minutes inside the desired hour
  all_nfgs <- unique(numflags_mm[pos == TRUE]) # Retrieve all numflags of the selected hour (also composed ones)
  
  # Now perform a loop over all of the numflags to decompose the composed ones and to retrieve only a list of
  # single de-composed numflags, sorted
  old_nfgs <- "000"
  for (nf in all_nfgs){
    nf_temp <- stri_pad_right(substr(nf, start = 3, stop = nchar(nf)),24,0) # 24 is a default value, meaning a numflag composed of 8 different flags
    temp_nfgs <- sapply(seq(1,15,by = 3), function(ii) {substr(nf_temp, ii, ii+2)}) # Retrieve a list of old numflags
    old_nfgs <- sort(unique(c(old_nfgs,temp_nfgs)))
  }
  
  numflag_hh <- as.numeric(paste0("0.",paste0(setdiff(old_nfgs,nv_numflags), collapse = ""))) # Create the final numflag, after excluding numflags specified in input
  return(numflag_hh)
}


# This function checks if the numflag given in input is valid,
# according to the arrays of valid/not valid numflags provided as
# input. The complete list of valid/not valid numflags can be
# retrieved from EBAS website, at:
# https://ebas-submit.nilu.no/Submit-Data/List-of-Data-flags
# Input:
# numflag             = input numflag (single value)
# EBAS_numflags       = array of all possible EBAS numflags
# EBAS_nf_validity    = array which states valid/not valid numflags (EBAS codes are:
#                        V = valid, I = invalid, M = missing, H = hidden and invalid)
# Output:
# numflag_validity    = it states if the numflag provided is valid/not valid (single value)
# ------------------------------------------------------------------------
# created by: Davide Putero, February 2018.
# ------------------------------------------------------------------------
library(stringi)
nf_val_check <- function(numflag, EBAS_numflags, EBAS_nf_validity){
  if (!is.na(numflag) & numflag == 0){
    numflag_validity <- "V"
  } else if (is.na(numflag)){
    numflag_validity <- "I"
  } else {
    # If different than 0, decompose the initial numflag into smaller ones 
    nf_temp <- stri_pad_right(substr(numflag, start = 3, stop = nchar(numflag)),24,0) # 24 is a default value, meaning a numflag composed of 8 different flags
    temp_nfgs <- unique(sapply(seq(1,15,by = 3), function(ii) {substr(nf_temp, ii, ii+2)})) # Retrieve a unique list of old numflags
    
    check <- setdiff(temp_nfgs,c("000",as.character(EBAS_numflags[EBAS_nf_validity == "V"]))) # Check if at least one value is invalid (add the 000, because normally it is read as 0)
    
    if (length(check) > 0){
      numflag_validity <- "I"
    } else {
      numflag_validity <- "V"
    }
  }
  return(numflag_validity)
}



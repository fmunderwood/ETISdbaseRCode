# Estimated RIE per seizure
#
# Estimates weights from no. of pieces in cases where wgt is unknown
#   and #pcs is known, and calculates RIE.

# OUTPUT:
#   Excel workbook summary_tbl_1.xlsx containing information for all seizures within time limits
#   Gives raw and worked number of pieces, weight and RIE, each separate and combined
#   Gives results to 3 decimal places - although this could be changed
#____________________________________________________________________________________________________

# Requires 
#  The R workspace 'wt est.Rdata' in current working folder 
#  Uses the function df_quantities_RIE_separate in the ETISdbase R package
#  Requires access to the database
#____________________________________________________________________________________________________

# File locations
# Assumes all required inputs and outputs are in the same directory as this script
# Although maybe it needs to look in directory _from_ruby_0 for user defined inputs
# But note that this suggests that outputs end up in that directory?
# For alternative see equivalent file in Fiona Testing
#____________________________________________________________________________________________________

# Note this was in the original file
options(java.parameters = "-Xss2048k")
# But don't know if it is needed
#____________________________________________________________________________________________________
# Set range of years of seizure to include;
#   leave as 1900 - 2100 to include ALL years in database:

# INPUT:
year.from <- _from_ruby_1
year.to <- _from_ruby_2
statusMin <- _from_ruby_3  # minimum level of seizure status field for inclusion
#____________________________________________________________________________________________________


load.pkgs <- function() {
  library(RPostgreSQL)
  library(tidyverse)
  library(XLConnect)
  library(ETISdbase)
}
suppressPackageStartupMessages(load.pkgs())

# Get PG settings.R
#setwd(dir.code)
source('PG settings.R')

drv <- dbDriver('PostgreSQL')
con <- dbConnect(drv, host = host.name, port = pg.port, user = user.name,
                 password = passwd, dbname = db.name)

setwd('_from_ruby_0') # Assume this identifies where inputs are from

# Set directory for wt est.Rdata
# setwd(dir.wgt)
num.dec <- 3

# produce df of ivory quantities (& RIE) : df.1
df.1 <- df_quantities_RIE_separate(year.from = year.from,
                                   year.to = year.to,
                                   statusMin = statusMin,
                                   reg.model = 'wt est.Rdata')

# Get country code names
SQLstr.c <- "
SELECT id, code
FROM public.countries"
df.ctry <- dbGetQuery(con, SQLstr.c, stringsAsFactors = F)
df.ctry$code.low <- tolower(df.ctry$code)

# Select relevant years, convert country of discovery number to name, rename variables, set 0 to NA for RIEs, and set decimal places
df.use <- df.1 %>%
  filter(seizure_year >= year.from & seizure_year <= year.to) %>%
  left_join(df.ctry, by = c('discovered_country_id' = 'id')) %>%
  select(id, sz_year = seizure_year, ctry_disc = code.low,
         raw_pcs = raw_pieces, raw_wgt = raw_weight,
         wkd_pcs = worked_pieces, wkd_wgt = worked_weight, 
         RIE_raw = RIE.raw, RIE_wkd = RIE.wkd, RIE_total = RIE) %>%
  mutate(RIE_raw = ifelse(is.na(raw_wgt) , NA, RIE_raw),
         RIE_wkd = ifelse(is.na(wkd_wgt), NA, RIE_wkd)) %>%
  mutate(raw_wgt = round(raw_wgt, num.dec),
         wkd_wgt = round(wkd_wgt, num.dec),
         RIE_raw = round(RIE_raw, num.dec),
         RIE_wkd = round(RIE_wkd, num.dec),
         RIE_total = round(RIE_total, num.dec))



# Create Excel workbook with name 

outfile <- paste(getwd(), "/Estimated_RIE.xlsx", sep="")

if(file.exists(outfile)) file.remove(outfile)
wb <- loadWorkbook(outfile, create=T)
setMissingValue(wb, value = "")
createSheet(wb, name='RIE')
writeWorksheet(wb, df.use, 'RIE')
saveWorkbook(wb)

# Close PostgreSQL connection
dbDisconnect(con)

# --------------------------------------------------------------------------------- #
# (c) 2020 University of Reading/TRAFFIC International/RW Burn & FM Underwood         #
# Please see the License.md file at                                                 #
# https://github.com/fmunderwood/ETISdbase_RCode/blob/master/License.md             #
# for more information about the copyright and license details of this file.        #
# --------------------------------------------------------------------------------- #


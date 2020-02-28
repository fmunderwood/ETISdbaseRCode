# Produces summary_tbl_1.xlsx
# Table of ivory weights - raw and worked (RIE) by year
# For user specified year from, year to and status
#____________________________________________________________________________________________________
# REQUIRES:
#  R scripts
#     PG settings.R
#  R workspace
#     wt est.Rdata
#  R Packages
#     RPostgreSQL
#     tidyverse
#     XLConnect
#     ETISdbase
#____________________________________________________________________________________________________

# INPUT:
year.from <- _from_ruby_1
year.to <- _from_ruby_2
statusMin <- _from_ruby_3  # minimum level of seizure status field for inclusion
#____________________________________________________________________________________________________

# OUTPUT:
#   Excel workbook summary_tbl_1.xlsx containing summary table of ivory weights - raw and
#   worked (RIE) - by year
#____________________________________________________________________________________________________

# File location
# Assumes all required inputs and outputs are in the same directory as this script
# Although it needs to look in directory _from_ruby_0 for user defined inputs
# But note that this suggests that outputs end up in that directory?
# For alternative see equivalent file in Fiona Testing
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

# produce df of ivory quantities (& RIE) : df.1
df.1 <- df_quantities_RIE_separate(year.from = year.from,
                                      year.to = year.to,
                                      statusMin = statusMin,
                                      reg.model = 'wt est.Rdata')

y0 <- max(min(df.1$seizure_year), year.from)
y1 <- min(max(df.1$seizure_year), year.to)

raw.wgt.yr <- round(tapply(df.1$RIE.raw, df.1$seizure_year, sum, na.rm=T), 2)
wkd.wgt.yr <- round(tapply(df.1$RIE.wkd, df.1$seizure_year, sum, na.rm=T), 2) #RIE wgt
wgts.df <- data.frame(Year = y0:y1,
                      Raw = raw.wgt.yr,
                      Wkd  =wkd.wgt.yr,
                      Tot = raw.wgt.yr + wkd.wgt.yr)


# write Excel workbook:

# Set directory for output
# setwd(dir.out)

# create workbook object ...
outfile <- paste(getwd(), "/summary_tbl_1.xlsx", sep="")
res <- if(file.exists(outfile)) file.remove(outfile)
wb <- loadWorkbook(outfile, create=T)
createSheet(wb, name = 'table 1')
writeWorksheet(wb, wgts.df, 'table 1')
saveWorkbook(wb)

# Close PostgreSQL connection
dbDisconnect(con)

# --------------------------------------------------------------------------------- #
# © 2019 University of Reading/TRAFFIC International/RW Burn & FM Underwood         #
# Please see the License.md file at                                                 #
# https://github.com/fmunderwood/ETISdbase_RCode/blob/master/License.md             #
# for more information about the copyright and license details of this file.        #
# --------------------------------------------------------------------------------- #

# This file pulls together code needed to produced sz and wts in and out
# With modifications for multiple countries of origin
# Writes two tables to database: szwt_le_inout and szwt_trade_inout
#____________________________________________________________________________________________________

# REQUIRES
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

# INPUTS
# Use all years
year.from <- 1900
year.to <- 2100
which.out <- 1:3
statusMin <- 3  # minimum level of seizure status field for inclusion in analysis
size.min <- 0  # include all seizures of at least this weight
#____________________________________________________________________________________________________
# Outputs
# Two tables into the database
# szwt_le_inout
# szwt_trade_inout
# Each table gives for each country in each year the number of
# Seizures and weights in and out
# Seizure flow and Trade flow - ie the ratio of in/in+out
#____________________________________________________________________________________________________

# File location
# Assumes all required inputs are in the same directory as this script
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
# setwd(dir.code)
source('PG settings.R')

drv <- dbDriver('PostgreSQL')
con <- dbConnect(drv, host = host.name, port = pg.port, user = user.name,
                 password = passwd, dbname = db.name)

# Set directory for wt est.Rdata
# setwd(dir.wgt)

#____________________________________________________________________________
# Calculate weights for all seizures
df.1 <- df_quantities_RIE_separate(year.from = year.from,
                                      year.to = year.to,
                                      statusMin = statusMin,
                                      reg.model = 'wt est.Rdata')

#____________________________________________________________________________
# Identify seizures and countries along trade chain
# where shipment has multiple countries of origin

mult.dat <- mult_ctries( year.from = year.from,
                year.to = year.to,
                statusMin = statusMin,
                df.1 = df.1)
#____________________________________________________________________________
# Identify seizures where countries of origin are different 
# for raw and worked ivory

double.recs <- double_count(year.from = year.from,
                            year.to = year.to,
                            statusMin = statusMin,
                            df.RIE = df.1)
#____________________________________________________________________________
# Create seizures and weights in and out
# Without country of destination - so used for LE ratio

ctry_dest_included <- FALSE

df.inout <- inout_tables_prep(year.from = year.from,
                           year.to = year.to,
                           statusMin = statusMin,
                           ctry_dest_included = ctry_dest_included,
                           df.1 = df.1)

inout_tables_final(year.from = year.from,
                   year.to = year.to,
                   statusMin = statusMin,
                   ctry_dest_included = ctry_dest_included,
                   size.min = size.min,
                   which.out = which.out,
                   mult.data = mult.dat,
                   inout.data = df.inout,
                   double.recs = double.recs
)

remove(df.inout)

#____________________________________________________________________________
# Create seizures and weights in and out
# With country of destination - so used for Trade Flows

ctry_dest_included <- TRUE

df.inout <- inout_tables_prep(year.from = year.from,
                                       year.to = year.to,
                                       statusMin = statusMin,
                                       ctry_dest_included = ctry_dest_included,
                                       df.1 = df.1)

inout_tables_final(year.from = year.from,
                   year.to = year.to,
                   statusMin = statusMin,
                   ctry_dest_included = ctry_dest_included,
                   size.min = size.min,
                   which.out = which.out,
                   mult.data = mult.dat,
                   inout.data = df.inout,
                   double.recs = double.recs
)

remove(df.inout)

# Close PostgreSQL connection
dbDisconnect(con)

# --------------------------------------------------------------------------------- #
# ? 2019 University of Reading/TRAFFIC International/RW Burn & FM Underwood         #
# Please see the License.md file at                                                 #
# https://github.com/fmunderwood/ETISdbase_RCode/blob/master/License.md             #
# for more information about the copyright and license details of this file.        #
# --------------------------------------------------------------------------------- #

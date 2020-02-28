# Produces szs_x_year_summary_table.xlsx
# Tables of number of seizures by country by year for each continent
# For user specified year from, year to and status
#____________________________________________________________________________________________________

# REQUIRES:
#  R scripts
#     PG settings.R
#  R Packages
#     RPostgreSQL
#     tidyverse
#     XLConnect
#     ETISdbase
#____________________________________________________________________________________________________

# INPUT:
year.from <- 1996#_from_ruby_1
year.to <- 2017#_from_ruby_2
statusMin <- 3#_from_ruby_3  # minimum level of seizure status field for inclusion
#____________________________________________________________________________________________________

#  OUTPUTS:
# Produces tables of numbers of seizures by country by year, grouped by country, as in CoP Report, Annex 1
# All countries in the countries table in the DB appear
#
# Tables saved in Excel workbook with a separate worksheet for each continent.
#____________________________________________________________________________________________________

# File locations
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

# Get  PG settings.R
# setwd(dir.code)
source('PG settings.R')

drv <- dbDriver('PostgreSQL')
con <- dbConnect(drv, host = host.name, port = pg.port, user = user.name,
                 password = passwd, dbname = db.name)
#
# user defined inputs
setwd('_from_ruby_0')

# levels for factors ...
#   ... years
SQLstr <- "
SELECT id, seizure_year
FROM public.seizures
;"
df.1 <- dbGetQuery(con, SQLstr)
y0 <- max(min(df.1$seizure_year), year.from)
y1 <- min(max(df.1$seizure_year), year.to)
yrs.all <- as.character(y0:y1)

#   ... continents
SQLstr <- "
SELECT id, continent
FROM public.countries
;"
df.ctry.all <- dbGetQuery(con, SQLstr)

conts <- unique(as.character(df.ctry.all$continent))

# create workbook object ...
# Directory for output
# setwd(dir.out)

outfile <- paste(getwd(), "/szs_x_year_summary_table.xlsx", sep = "")
res <- if(file.exists(outfile)) file.remove(outfile)
wb <- loadWorkbook(outfile, create = T)

for(i in 1:length(conts)) {
  # retrieve list of country names for continent i
  SQLstr.c <- "
  SELECT id, name, continent
  FROM public.countries
  WHERE substring(code,1,1) <> 'X' AND continent = '"
  df.ctry <- dbGetQuery(con, paste(SQLstr.c, conts[i], "'", sep = ""), stringsAsFactors = F)
  # levels of country factor for continent i
  nms <- sort(df.ctry[ ,2])
  # all seizures from continent i
  SQLstr.s <- "
  SELECT  s.id, s.seizure_year, c.name
  FROM    public.seizures s, public.countries c
  WHERE   s.discovered_country_id = c.id AND c.continent = '"
  df.sz <- dbGetQuery(con, paste(SQLstr.s, conts[i], "'", sep = ""), stringsAsFactors = F)
  levels(df.sz$name) <- nms
  Year <- factor(df.sz$seizure_year, levels = yrs.all)
  Country <- factor(df.sz$name, levels = nms)
  # table of szs in ctries x year within continent i
  tbl.sz <- table(Country, Year)
  class(tbl.sz) <- 'matrix'
  df.sz <- data.frame(rownames(tbl.sz), tbl.sz, check.names = F)
  names(df.sz) <- c('Country',yrs.all)
  createSheet(wb, name = conts[[i]])
  writeWorksheet(wb, df.sz, conts[[i]])
}
saveWorkbook(wb)

dbDisconnect(con)

# --------------------------------------------------------------------------------- #
# © 2019 University of Reading/TRAFFIC International/RW Burn & FM Underwood         #
# Please see the License.md file at                                                 #
# https://github.com/fmunderwood/ETISdbase_RCode/blob/master/License.md             #
# for more information about the copyright and license details of this file.        #
# --------------------------------------------------------------------------------- #

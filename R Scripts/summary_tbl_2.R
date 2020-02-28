# Produces wgt_sz_series_plot.png
# Plot of number of seizures and RIE weights by year
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
year.from <- 2011#_from_ruby_1
year.to <- 2017#_from_ruby_2
statusMin <- 3#_from_ruby_3  # minimum level of seizure status field for inclusion
#____________________________________________________________________________________________________

# OUTPUT:
#   Chart representing total numbers of seizures and RIE weights by year
#   Saved as png file wgt_sz_series_plot.png in current working directory
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

# Get PG setttings.R
# setwd(dir.code)
source('PG settings.R')

drv <- dbDriver('PostgreSQL')
con <- dbConnect(drv, host = host.name, port = pg.port, user = user.name,
                 password = passwd, dbname = db.name)

# Assume this is directory where inputs from user are found
 setwd('_from_ruby_0')

# Directory Needed for wt est.Rdata
# setwd(dir.wgt)

# produce df of ivory quantities (& RIE) : df.1
df.1 <- df_quantities_RIE_separate(year.from = year.from,
                                      year.to = year.to,
                                      statusMin = statusMin,
                                      reg.model = 'wt est.Rdata')

szs.yr <- as.numeric(table(df.1$seizure_year))
wgt.yr <- tapply(df.1$RIE, df.1$seizure_year,sum)

y0 <- max(min(df.1$seizure_year), year.from)
y1 <- min(max(df.1$seizure_year), year.to)

yr <- y0:y1

# Directory for output
# setwd(dir.out)

outfile = paste(getwd(), '/wgt_sz_series_plot.png', sep = '')
png(outfile, width = 640, height = 480)
par(mar = c(5, 5, 3, 5)+.1)
ymax <- max(pretty(wgt.yr,n = 8))
plot(yr, wgt.yr, type = 'h', lwd = 18, col = 'lightblue', las = 1, cex.axis = 0.7, lend = 'square', xaxt = 'n',
     xlab = list('Year',cex = 0.8), ylab = list('Weight of ivory (kg)', cex = 0.8))
axis(1, at = seq(min(yr),max(yr),2), cex.axis = 0.7)
par(new = TRUE)
plot(yr, szs.yr, type = 'o', pch = 19, cex = 0.7, lwd = 2, col = 'blue', xaxt = 'n', yaxt = 'n', xlab = '', ylab = '')
axis(4,las = 1, cex.axis = 0.7)
mtext('Number of seizures', side = 4, line = 3, cex = 0.8)
legend('bottomleft', col = c('lightblue','blue'), lty = c(0,1), pch = c(15,19), cex = 0.8, legend = c('Wgt','Szs'))
dev.off()

dbDisconnect(con)

# --------------------------------------------------------------------------------- #
# © 2019 University of Reading/TRAFFIC International/RW Burn & FM Underwood         #
# Please see the License.md file at                                                 #
# https://github.com/fmunderwood/ETISdbase_RCode/blob/master/License.md             #
# for more information about the copyright and license details of this file.        #
# --------------------------------------------------------------------------------- #

# Produces plots for country report
# User specifies years and country

# REQUIRES:
#   R script
#     PG settings.R
#  R Packages
#     RPostgreSQL
#     tidyverse
#     XLConnect
#     ETISdbase
#____________________________________________________________________________________________________

# INPUT:
year.from <- 1996 #_from_ruby_2
year.to <- 2017 #_from_ruby_3
# ISO country code
ctcode <- 'cn' #_from_ruby_1'
#____________________________________________________________________________________________________

# OUTPUT
# Three plots for Country Reports
# seizures in and out by year
# weights in and out by year
# LE ratio by year
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
  library(ETISdbase)
}
suppressPackageStartupMessages(load.pkgs())

# Set directory for PG settings.R
# setwd(dir.code)
source('PG settings.R')

drv <- dbDriver('PostgreSQL')
con <- dbConnect(drv, host = host.name, port = pg.port, user = user.name,
                 password = passwd, dbname = db.name)


# Directory for user inputs
setwd('_from_ruby_0')

SQL.str <- '
SELECT lower(ctry) AS ccode,
year, sz_in, sz_out, wt_in, wt_out
FROM szwt_le_inout
'
df.inout <- dbGetQuery(con, SQL.str)
dbDisconnect(con)

y0 <- max(min(df.inout$year), year.from)
y1 <- min(max(df.inout$year), year.to)

df.inout <- df.inout %>%
  filter(year >= y0 & year <= y1)

ctcode <- tolower(ctcode)
df.ctry <- df.inout %>%
  filter(ccode == ctcode)

ctcode <- toupper(ctcode)

lng <- dim(df.ctry)[1]
df.stack <- data.frame(Year = rep(df.ctry$year,2),
                       grp.s = c(rep('in',lng), rep('out',lng)),
                       szs = c(df.ctry$sz_in, df.ctry$sz_out),
                       wts = c(df.ctry$wt_in, df.ctry$wt_out)
)

# Set directory for outputs
# setwd(dir.out)

#
#Plot 1: szs in/out x year
s <- ggplot(df.stack, aes(Year, szs, colour = grp.s))
#s <- s + layer(geom = 'point', size = 3) + layer(geom = 'line', size = 1)
s <- s + geom_point(size = 3) + geom_line(size = 1)
s <- s + scale_x_continuous(breaks = seq(min(df.stack$Year), max(df.stack$Year), 2))
s <- s + scale_y_continuous(name = 'No. of Seizures')
s <- s + scale_colour_manual(values = c('darkblue', 'cyan'),
                             breaks = c('in', 'out'),
                             labels = c('Seizures in', 'Seizures out'),
                             name = '')
s <- s + ggtitle(paste('Number of Seizure Cases:', ctcode, sep = ' '))
s <- s + theme(plot.title = element_text(size = 18))

ggsave(s, file = "seizures.png", dpi = 72)

#Plot 2: wgts in/out x year
w <- ggplot(df.stack, aes(Year, wts, fill = grp.s))
w <- w + layer(geom = 'bar', stat = 'identity', position = 'dodge')
w <- w + scale_x_continuous(breaks = seq(min(df.stack$Year), max(df.stack$Year),2))
w <- w + scale_y_continuous(name = 'Weight of ivory (kg)')
w <- w + scale_fill_manual(values = c('darkblue','cyan'),
                           breaks = c('in','out'),
                           labels = c('Weight in','Weight out'),
                           name = '')
w <- w + ggtitle(paste('Estimated Weight of Seizures:', ctcode, sep = ' '))
w <- w + theme(plot.title = element_text(size = 18))

ggsave(w, file = "weights.png", dpi = 72)

#Plot 3: LE ratio x year
df.ctry$LErat <- 100 * df.ctry$sz_in/(df.ctry$sz_in + df.ctry$sz_out)
p <- ggplot(df.ctry, aes(year, LErat))
#p <- p + layer(geom = 'point', size = 3) + layer(geom = 'line', size = 1)
p <- p + geom_point(size = 3) + geom_line(size = 1)

p <- p + scale_x_continuous(breaks = seq(min(df.ctry$year), max(df.ctry$year), 2),
                            name = 'Year')
p <- p + scale_y_continuous(name = 'LE ratio', limits = c(0,100), breaks = seq(0,100,10))
p <- p + ggtitle(paste('LE Ratio:',ctcode,sep = ' '))
p <- p + theme(plot.title = element_text(size = 18))

ggsave(p, file = "leratio.png", dpi = 72)

# --------------------------------------------------------------------------------- #
# © 2019 University of Reading/TRAFFIC International/RW Burn & FM Underwood         #
# Please see the License.md file at                                                 #
# https://github.com/fmunderwood/ETISdbase_RCode/blob/master/License.md             #
# for more information about the copyright and license details of this file.        #
# --------------------------------------------------------------------------------- #

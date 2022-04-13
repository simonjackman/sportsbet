########################################################
## upload
##
## simon jackman
## simon.jackman@sydney.edu.au
## ussc, univ of sydney
## 2022-03-29 17:19:47
########################################################

library(tidyverse)
library(here)
library(ussc)

load(here("data/rsconnect_result.RData"))

result <- rsconnect::rpubsUpload(contentFile=here("analysis/report.html"),
                                 originalDoc=here("analysis/report.Rmd"),
                                 id=result$id,
                                 title="Betting odds and the 2022 Australian election")

save("result",file=here("data/rsconnect_result.RData"))

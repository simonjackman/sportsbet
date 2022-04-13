########################################################
## sportsbet scrape?
##
## simon jackman
## simon.jackman@sydney.edu.au
## ussc, univ of sydney
## 2022-03-19 11:43:48
########################################################

library(tidyverse)
library(here)
library(ussc)

library(rvest)

urls <- tribble(
  ~lab, ~theURL,
"Next Sworn Government",
"https://www.sportsbet.com.au/betting/politics/australian-federal-politics/next-federal-election-47th-parliament-of-australia-4664855",
"ACT", "https://www.sportsbet.com.au/betting/politics/australian-federal-politics/next-federal-election-act-seats-5849944",
"NSW", "https://www.sportsbet.com.au/betting/politics/australian-federal-politics/next-federal-election-nsw-seats-5878289",
"NT", "https://www.sportsbet.com.au/betting/politics/australian-federal-politics/next-federal-election-nt-seats-6225384",
"QLD", "https://www.sportsbet.com.au/betting/politics/australian-federal-politics/next-federal-election-qld-seats-6227453",
"SA", "https://www.sportsbet.com.au/betting/politics/australian-federal-politics/next-federal-election-sa-seats-6240454",
"TAS", "https://www.sportsbet.com.au/betting/politics/australian-federal-politics/next-federal-election-tas-seats-6225404",
"VIC", "https://www.sportsbet.com.au/betting/politics/australian-federal-politics/next-federal-election-vic-seats-6054105",
"WA", "https://www.sportsbet.com.au/betting/politics/australian-federal-politics/next-federal-election-wa-seats-6240412",
"Type of
Government","https://www.sportsbet.com.au/betting/politics/australian-federal-politics/next-federal-election-type-of-government-formed-5758351",
"Hung Parliament","https://www.sportsbet.com.au/betting/politics/australian-federal-politics/next-federal-election-hung-parliament-6238749")

parseFunction <- function(theURL){
  cat(paste("reading",theURL,"\n"))
  foo <- read_html(theURL)
  eventNodes <- foo %>% html_elements(xpath="//div[contains(@class,'SingleMarketGroup')]")
  if(length(eventNodes)==0){
    eventNodes <- foo %>% html_elements(xpath="//div[contains(@data-automation-id,'-market-item')]")
  }
  out <- lapply(eventNodes,function(obj){
    event <- obj %>% html_elements(xpath=".//span[@data-automation-id='accordion-header-title']") %>% html_text()
    outcomes <- obj %>% html_elements(xpath=".//span[contains(@data-automation-id,'outcome-name')]") %>% html_text()
    prices <- obj %>% html_elements(xpath=".//span[@data-automation-id='price-text']") %>% html_text() %>% as.numeric()
    out <- tibble(event=event,outcomes=outcomes,prices=prices) %>%
      mutate(prob = (1/prices)/sum(1/prices)) %>%
      mutate(datetime=Sys.time())
    return(out)
  })

  out <- bind_rows(out)
  return(out)
}

d <- urls %>%
  mutate(d=map(theURL,parseFunction)) %>%
  select(-theURL) %>%
  unnest(d)

library(fst)
write_fst(d,path=here(paste("data/",strftime(Sys.time(),format="%Y%m%d%H%m"),".fst",sep="")))










########################################################
## read with selenium
##
## simon jackman
## simon.jackman@sydney.edu.au
## ussc, univ of sydney
## 2022-04-12 16:37:45
########################################################

library(tidyverse)
library(here)
library(ussc)
library(RSelenium)
library(rvest)


theStates <- c("ACT","NT","QLD","NSW","VIC","TAS","SA","WA")

urls <- tribble(
  ~lab, ~theURL,
  "Next Sworn Government",
  "https://www.sportsbet.com.au/betting/politics/australian-federal-politics/next-federal-election-47th-parliament-of-australia-4664855",
  "ACT", "https://www.sportsbet.com.au/betting/politics/australian-federal-politics/next-federal-election-act-seats-6484557",
  "NSW", "https://www.sportsbet.com.au/betting/politics/australian-federal-politics/next-federal-election-nsw-seats-6484922",
  "NT", "https://www.sportsbet.com.au/betting/politics/australian-federal-politics/electorate-betting-nt-seats-6484664",
  "QLD", "https://www.sportsbet.com.au/betting/politics/australian-federal-politics/electorate-betting-qld-seats-6496304",
  "SA", "https://www.sportsbet.com.au/betting/politics/australian-federal-politics/electorate-betting-sa-seats-6494014",
  "TAS", "https://www.sportsbet.com.au/betting/politics/australian-federal-politics/electorate-betting-tas-seats-6484714",
  "VIC", "https://www.sportsbet.com.au/betting/politics/australian-federal-politics/electorate-betting-vic-seats-6495711",
  "WA", "https://www.sportsbet.com.au/betting/politics/australian-federal-politics/electorate-betting-wa-seats-6496079",
  "Type of
Government","https://www.sportsbet.com.au/betting/politics/australian-federal-politics/next-federal-election-type-of-government-formed-5758351",
  "Hung Parliament","https://www.sportsbet.com.au/betting/politics/australian-federal-politics/next-federal-election-hung-parliament-6238749")

library(ps)
cdprocess <- ps() %>%
  filter(grepl(pattern="java",name) | name=="Google Chrome" | grepl("chromedriver",name)) %>%
  select(pid) %>%
  distinct() %>%
  pull(pid)

if(length(cdprocess)>0){
  for(p in cdprocess){
    if(p!=1){
      ps_kill(ps_handle(pid=as.integer(p)))
    }
  }
}

# if(!java_running){
#   ## start selenium-server on locahost with java -jar selenium-server-standalone-4.0.0-alpha-2.jar
#   system("java -jar /opt/homebrew/Cellar/selenium-server/4.1.3/libexec/selenium-server-4.1.3.jar standalone --port 4444 &")
# }

# pjs <- wdman::phantomjs(extras = c('--ssl-protocol=tlsv1'))
# eCap <- list(
#   phantomjs.page.settings.userAgent = "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:29.0) Gecko/20120101 Firefox/29.0"
#   )
# remDr <- remoteDriver(browserName = "phantomjs", extraCapabilities = eCap,port=4567)
# remDr$open()
# remDr$setTimeout(type="page load",milliseconds=60000)
# remDr$setWindowSize(1280L,1024L)


rs <- rsDriver(chromever = "100.0.4896.60",port=4444L)
remDr <- rs[["client"]]
remDr$open()
remDr$setTimeout(type="page load",milliseconds=60000)

parseWrapper <- function(theURL){
  remDr$navigate(theURL)
  system("sleep 2")

  ## open up all "Show All"
  cat(paste("looking for show all buttons\n"))
  webElem <- remDr$findElements(using="xpath",
                                value="//button[@data-automation-id='show-all-button']")


  if(length(webElem)>0){
    for(i in 1:length(webElem)){
      cat(paste("clicking on show all number",i,"\n"))
      ##webElem[[i]]$clickElement()
      webElem[[i]]$findChildElement(using="xpath","..//span")$clickElement()
      system("sleep 1")
    }
    rm(webElem)
  }

  ## click on Other Markets
  webElem <- try(remDr$findElement(using = "xpath",
                                   value = "//span[text()='Other Markets']"),
                 silent=TRUE)
  if(!inherits(webElem,"try-error")){
    if(length(webElem)>0){
      cat(paste("opening Other Markets\n"))
      webElem$clickElement()
      system("sleep 1")
    }
  }
  rm(webElem)

  ## now open up all closed chevrons
  webElem <- try(remDr$findElements(using="xpath",
                                    value="//div[contains(@class,'indicatorLeft') and @data-automation-id='chevron-closed']"),
                 silent=TRUE)
  if(!inherits(webElem,"try-error")){
    if(length(webElem)>0){
      cat(paste("will open",length(webElem),"closed market chevrons\n"))
      system("sleep 1")
      for(i in 1:length(webElem)){
        cat(paste("opening Other Market",i,"\n"))
        webElem[[i]]$clickElement()
        ##webElem[[i]]$findChildElement(using="xpath","..//span")$clickElement()
        system("sleep 1")
      }
    }
  }
  rm(webElem)

  flag <- TRUE
  while(flag){
    foo <- try(remDr$getPageSource()[[1]],silent=TRUE)
    flag <- inherits("try-error",foo)
  }
  rm(flag)

  zzz <- parseFunction(foo)
  print(zzz)

  cat("returning zzz to calling frame\n\n\n\n")
  return(zzz)
}

parseFunction <- function(foo){
  if(!("xml_document" %in% class(foo))){
    foo <- read_html(foo)
  }
  eventNodes <- foo %>% html_elements(xpath="//div[contains(@class,'SingleMarketGroup')]")
  if(length(eventNodes)==0){
    eventNodes <- foo %>% html_elements(xpath="//div[contains(@data-automation-id,'-market-item')]")
  }
  out <- lapply(eventNodes,function(obj){
    event <- obj %>% html_elements(xpath=".//span[@data-automation-id='accordion-header-title']") %>% html_text()
    outcomes <- obj %>% html_elements(xpath=".//span[contains(@data-automation-id,'outcome-name')]") %>% html_text()
    prices <- obj %>% html_elements(xpath=".//span[@data-automation-id='price-text']") %>% html_text() %>% as.numeric()
    out <- tibble(event=event,outcomes=outcomes,prices=prices) %>%
      mutate(prob = (1/prices)/sum(1/prices,na.rm=TRUE)) %>%
      mutate(datetime=Sys.time())
    return(out)
  })

  out <- bind_rows(out)
  return(out)
}

d <- list()
n <- nrow(urls)
for(i in 1:n){
  flag <- TRUE
  while(flag){
    cat(paste("scraping for",urls$lab[i],"\n\n"))
    tmp <- try(parseWrapper(urls$theURL[i]),silent=TRUE)
    flag <- inherits(tmp,"try-error")
  }
  d[[urls$lab[i]]] <- tmp
  rm(tmp,flag)
}

d <- bind_rows(d,.id="lab")

library(fst)
write_fst(d,path=here(paste("data/",strftime(Sys.time(),format="%Y%m%d%H%m"),".fst",sep="")))


# Title:         
# Version:       
# Date:          
# Author:        MvA
# Input:         
# Output:        
# Description:         

# INIT --------------------------------------------------------------------
setwd("~/scripts/cpp_downloader")
library(tidyverse)
library(rvest)
library(tableHTML)

# PARAMETERS --------------------------------------------------------------
homepage <- "https://www.learncpp.com/"
tutorial_page <- "https://www.learncpp.com/cpp-tutorial/"
table_xpaths <- map(as.character(1:8), ~'//*[@id="post-8"]/div[2]/table[§]' %>% str_replace("§", .x)) #xpaths containing the index tables

# FUNCTIONS ---------------------------------------------------------------
edit_html <- function(file_in, file_out) {
  print(paste0("Processing file ", file_in))
  page <- read_html(file_in)
  
  #first: remove commentlist, cf_monitor (ads), left frame, right frame, header
  rem <- xml_find_all(page, "
                    //ul[@class='commentlist'] | 
                    //div[@class='cf_monitor'] | 
                    //td[@id='left'] | 
                    //td[@id='right'] | 
                    //div[@id='header'] |
                    //div[@id='footer']
                      ")
  
  xml_remove(rem, free = TRUE)
  
  #second: remove the last table on the page (the links) and related content. colgroup needs to be removed to spread content across the page
  rem <- xml_find_all(page, "
                    //div[@class='post-bodycopy clearfix']/table[last()] | 
                    //div[@class='post-footer'] | 
                    //h3[@id='comments'] | 
                    //div[@class='clearfix navigation-comments-above'] |
                    //div[@class='clearfix navigation-comments-below'] |
                    //div[@id='respond'] |
                    //colgroup
                    ")
  
  xml_remove(rem, free = TRUE)
  
  write_html(page, file_out)
}


# PROGRAM -----------------------------------------------------------------
# get all hyperlinks to the tutorial pages
links <- 
  homepage %>% 
  read_html() %>% 
  html_nodes("#middle a") %>% 
  html_attr('href') %>% 
  .[!is.na(.)] %>% 
  .[-(1:2)] %>%  #remove the first 2 links that appear in the header of the middle column
  str_remove("https://www.learncpp.com/cpp-tutorial/") %>%  #remove the prefixes
  str_remove("/cpp-tutorial/") #remove the prefixes


# get all tables with the content
tables <- map(table_xpaths, ~homepage %>% 
                read_html() %>%
                html_nodes(xpath = .x) %>%
                html_table(fill = TRUE, header = FALSE) %>%
                .[[1]] %>% #take first element of list
                .[-1,]) #remove header

#create tbl with chapter number, name, and link to html file to use for the downlading
tb <- tables %>% 
  purrr::reduce(rbind) %>% 
  dplyr::select(chapter = X1, name = X3) %>% 
  na.omit %>% 
  dplyr::filter(!str_detect(chapter, "Chapter"),
                !str_detect(chapter, "Appendix")) %>% 
  cbind(links) %>% 
  mutate(name = str_replace(name, "/", "-"),
         index = str_pad(as.character(1:nrow(.)), 4, pad = "0")) %>% #remove fw slash from names as this gives trouble when writing the files later
  as_tibble

#write contents to use at the beginning of the book
dir.create("html_edit")
write_tableHTML(tableHTML(tb %>% select(-c(links, index)), rownames = FALSE), file = "html_edit/0000---index.html")

# download the files
dir.create("html_raw")
with(tb, pwalk(list(links, index, chapter, name), ~{download.file(url = paste0(tutorial_page, ..1), destfile = paste0("html_raw/", ..2, "---", ..3, "---", ..4, ".html"))}))
html_files <- list.files("html_raw/")
stopifnot(length(html_files) == nrow(tb)) #check if all files were downloaded

#remove unwanted content from the files
walk(html_files, ~edit_html(file_in = paste0("html_raw/", .x), file_out = paste0("html_edit/", .x)))
stopifnot(length(list.files("html_raw/")) == length(list.files("html_edit/")) -1 ) #check if all files were written (1 accounts for the index file)

#Use pandoc to merge all files into 1 and output as epub. Requires pandoc installation!
merge_command <- "pandoc -s html_edit/*.html -f html -t epub3 -o learncpp.epub"
system(merge_command)

#convert final html to epub
convert_command <- "pandoc -f html -t epub3 -o learncpp.epub learncpp.html"
system(convert_command)

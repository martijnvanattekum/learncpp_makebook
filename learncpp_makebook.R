# Title:         learncpp.com book creator     
# Version:       0.10
# Date:          31-03-19
# Author:        MvA
# Input:         parameters of website address and output format
# Output:        full book of the website
# Description:   The script creates the learncpp book in 4 steps:
#                STEP1: crawl all links to content from the index page and create an index table
#                STEP2: download all html files from these links
#                STEP3: remove all html frames that do not go into the book
#                STEP4: combine all html files to the book  

# INIT --------------------------------------------------------------------
library(tidyverse) # for everything the tidyverse has to offer
library(rvest)     # for web scraping
library(tableHTML) # to write the html index table

# PARAMETERS --------------------------------------------------------------
homepage <- "https://www.learncpp.com/" #page with the index table
tutorial_page <- "https://www.learncpp.com/cpp-tutorial/" #html dir with the actual tutorials
output_format <- "epub3" #output format of the book. Can be for instance epub3 or pdf
output_file_name <- "learncpp_book.epub"

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
  
  #second: remove the last table on the page (the links) and related content. 
  #needs to be done in step 2 to avoid the script removes the last table from the comment section instead
  #colgroup needs to be removed to spread content across the page
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
# STEP1: crawl all links to content from the index page and create an index table
print("** Starting creation of index table (STEP1)")
table_xpaths <- map(as.character(1:8), ~'//*[@id="post-8"]/div[2]/table[§]' %>% str_replace("§", .x)) #xpaths containing the index tables

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
  dplyr::filter(!str_detect(chapter, "Chapter"),  #remove chapter headers
                !str_detect(chapter, "Appendix")) %>% 
  cbind(links) %>% 
  mutate(name = str_replace(name, "/", "-"), #remove fw slash from names as this gives trouble when writing the files later
         index = str_pad(as.character(1:nrow(.)), 4, pad = "0")) %>% #index to ensure chapters are in the correct order in the book
  as_tibble()

#write contents to use at the beginning of the book
dir.create("html_raw")
write_tableHTML(tableHTML(tb %>% select(-c(links, index)), rownames = FALSE), file = "html_raw/0000---index.html")

# STEP2: download all html files from these links
print("** Starting downloads (STEP2)")
with(tb, pwalk(list(links, index, chapter, name), 
               ~{download.file(url = paste0(tutorial_page, ..1), destfile = 
                                 paste0("html_raw/", ..2, "---", ..3, "---", ..4, ".html"))}))
html_files <- list.files("html_raw/")
stopifnot(length(html_files) == nrow(tb) + 1) #check if all files were downloaded, +1 for index table
print(paste("** Succesfully downloaded", nrow(tb), "html files."))

# STEP3: remove all html frames that do not go into the book and write to html_edit dir
print("** Starting html editing (STEP3)")
dir.create("html_edit")
walk(html_files, ~edit_html(file_in = paste0("html_raw/", .x), file_out = paste0("html_edit/", .x)))
stopifnot(length(list.files("html_raw/")) == length(list.files("html_edit/"))) #check if all files were edited

# STEP4: combine all html files to the book. !!Requires pandoc installation on local system!!
print("** Starting book conversion (STEP4)")
create_book_command <- paste("pandoc -s html_edit/*.html -f html -t", output_format, "-o", output_file_name)
system(create_book_command)

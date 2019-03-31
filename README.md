# learncpp.com book downloader

[learncpp.com](www.learncpp.com) is one of the most appreciated resources to learn C++. Unfortunately, the
website is not available off-line. To provide access to the book without access to a
computer/internet, this script **downloads the html files**, and **converts them to a one-file
book** that can be read on for instance an e-reader.

## Disclaimer
This program is solely for educational purposes. Note that although running the
script to convert these pages is allowed, it is not allowed to distribute the converted book,
so please refrain from doing so. As stated on the website:

> Is there a PDF version of this site available for offline viewing?
>
> Unfortunately, there is not. The site is able to stay free for everyone because we’re ad-sponsored -- that model simply doesn’t work in
> PDF format. You are welcome to convert pages from this website into PDF (or any other) format for your own private use, so long as you
> do not distribute them.

## Program details
The script creates the learncpp book in 4 steps:  
* STEP1: crawl all links to content from the index page and create an index table  
* STEP2: download all html files from these links  
* STEP3: remove all html frames that do not go into the book (such as the side panes and comments)
* STEP4: combine all edited html files to one book  

## Support learncpp.com
If you appreciate the content of this excellent website, please
consider supporting the creators by visiting https://www.learncpp.com/about/#Support and donating.

As mentioned by the creators:

> LearnCpp.com is a totally free website devoted to teaching you to program in C++. Whether you’ve had any prior experience programming or not, the tutorials on this site will walk you through all the steps you’ll need to know in order to create and compile your programs. Becoming an expert programmer won’t happen overnight, but with a little patience, you’ll get there. And LearnCpp.com will show you the way.
>
> Did we mention the site is completely free? And not free as in “First one is free, man!”, nor “This wonderful synopsis of our content is completely free. Full access for 3 months is only $129.99!”. LearnCpp.com is totally, 100% free, no strings, no catches, no hidden fees, no taxes, and no license and documentation charges.
>
> So, the obvious question is, “what’s in it for us?”. Two things:
>
> * We love to teach, and we love to talk about programming. This site allows us to do that without having to get a PhD, grade homework, and deal with students who need to have the final moved because their “cat just died” (sorry kitty!). Furthermore, our readers are creative, inventive, and very intelligent -- sometimes they teach us stuff in return! So we learn while we teach you, and that makes us better in our careers or hobbies. Plus, it allows us to give something back to the internet community at large. We’re just trying to make the world a better place, okay!?! (*sniff*)  
> * Advertising revenues. See those adsense ads on the right? Every time someone clicks one, we make a few cents. It’s not much, but it’s (hopefully) enough to at least pay the hosting fees and maybe buy ourselves a Hawaiian pizza and a pint of Newcastle every once in a while\*.  
> (\* Beer and programming don’t mix. Please code responsibly.)

## Requirements
The script is written in R and requires an R installation on the system, with Rscript executable on the PATH.
See https://www.r-project.org/ for installation instructions.  
In addition, the following 3 R packages are required: tidyverse, rvest, and tableHTML These can be installed by running ```install.packages("_package name_")``` for each of them from R.

To convert html to the requested output format, pandoc needs to be installed and on the PATH. See
https://pandoc.org/installing.html for instructions. Without pandoc, the html files will still
be downloaded and edited, but no one-file book will be generated.

To clone the repository from git, you need to have git installed. See https://www.atlassian.com/git/tutorials/install-git

## Usage
Run the following commands to execute the script:
```
git clone https://github.com/martijnvanattekum/learncpp_makebook.git
cd learncpp_makebook
# If needed, change the output format and file name in the script's parameters
Rscript learncpp_makebook.R
```

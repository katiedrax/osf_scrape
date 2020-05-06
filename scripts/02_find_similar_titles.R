###########
# set up #####
##########
# i want to find which titles are the most similar in terms of the words they contain and to >
# create dt of all titles compared to each other and their matches

# record start time

start <- Sys.time()

# libraries
library(data.table)
library(magrittr)

# functions

clean_title <- function(string, stopwords){
  # collapse hypenated words so they will be matched as a single word
  string <- gsub("[[:alpha:]][[:punct:]]{1,}[:alpha:]]", "", string)
  # remove remaining punctuation (include unicode for "General punctuation" range)
  string <- gsub("[[:punct:]]|[\u2000-\u206f]", " ", string)
  # lower for case insensitive string matching
  string <- tolower(string)
  # remove stopwords
  string <- gsub(stopwords, " ", string)
  # remove multiple spaces
  string <- gsub("[[:space:]]{2,}", " ", string)
  # remove whitespace at end
  string <- trimws(string, which= "both")
}

##########
# import ####
###########

# import collated dataset from OSF api

dt <- fread("outputs/preregs.csv", header = T, encoding = "UTF-8")

# import stopwords for string cleaning

stopwords <- readLines("https://gist.githubusercontent.com/sebleier/554280/raw/7e0e4a1ce04c2bb7bd41089c9821dbcf6d0c786c/NLTK's%2520list%2520of%2520english%2520stopwords") %>%
  paste("\\b", ., "\\b", collapse = "|", sep = "")


#####################
# subset by keywords ####
################

keywords <- c("SARS", "ncov", "covid-19", "coronavirus") 

search <- paste(keywords, collapse = "|", sep ="")

hits <- lapply(dt[, c("tags", "title", "description")], function(x) grep(search,x, ignore.case = T)) %>%
  unlist() %>%
  unique()

dt <- dt[hits, ]

##############
# clean titles ####
###############

# create clean string
dt <- dt[, c("title_clean") := clean_title(title, stopwords = stopwords)]

# save all non-stop words in separate columns

max <- max(lengths(strsplit(dt$title_clean, " ", fixed = T)))

cols <- paste("word", 1:max, sep = "")

dt <- dt[, (cols) := tstrsplit(title_clean, " ", fixed = T)]

##############
# find pairs ####
############

# list to add pairs to
pairs_ls <- list()

# create index for pairs_ls
n <- 1

for(i in dt$title_clean){
  str2 <- dt$title_clean[dt$title_clean != i]
  str2_title <- dt$title[dt$title_clean != i]
  str1 <- rep(i, length(str2))
  str1_title <- rep(dt$title[dt$title_clean == i], length(str2))
  length(str1) <- dt[,.N]
  length(str1_title) <- dt[,.N]
  length(str2) <- dt[,.N]
  length(str2_title) <- dt[,.N]
  x <- data.table(str1 = str1, str1_title = str1_title, str2 = str2, str2_title = str2_title, stringsAsFactors = F)
  pairs_ls[[n]] <- x
  n <- n +1
}

# store copy of pairs_ls just in case

pairs_ls_copy <- pairs_ls

pairs <- rbindlist(pairs_ls) %>%
  # remove duplicate rows
  unique() %>%
  # remove any all NA rows
  na.omit()

# remove duplicates that are in a different order 
# there should be a duplicate of each row since the ordering of str1 and str2 will be reversed
# find which rows are identical by turning all rows into vectors, sorting then searching for duplicates

id <- apply(pairs,1, as.list)
id <- lapply(id, function(x) sort(as.character(x)))

tic1 <- Sys.time()

# check all rows sorted
if(nrow(pairs) != length(id)) stop("wrong number of elements in id")

# check correct number of duplicates
if(nrow(pairs[!(duplicated(id))]) != nrow(pairs)/2) stop("not a duplicate for each combination")

# remove duplicate ids from pairs
pairs <- pairs[!(duplicated(id))]

# check no rows contain same values in str1 and str2

check <- all.equal(pairs$str1, pairs$str2)

if(identical(check, paste(nrow(pairs), "string mismatches", collapse = " ")) == F) stop("some rows contain same values")

# create list of vectors of split title_clean strings so can easily intersect

split_ls <- strsplit(dt$title_clean, " ", fixed = T)
names(split_ls) <- dt$title_clean

matches <- list()

for(i in 1:nrow(pairs)){
  a <- pairs$str1[i]
  b <- pairs$str2[i]
  matches[[i]]<-   intersect(unlist(split_ls[a]), unlist(split_ls[b])) %>% 
    sort()
  print(paste(i, "done"))
}

# store copy of matches just in case

matches_copy <- matches

# paste all matches together into one string and convert to character vector >
# pasting will also make sure all character(0) elements are given a value
matches <- lapply(matches, paste0, collapse = ",")

if(min(lengths(matches)) <1) stop("some elements in matches are 0")
if(identical(length(matches), pairs[,.N]) == F) stop("matches and pairs different lengths")

matches_col <- unlist(matches)
matches_col[matches_col == ""] <- NA

# add matches to pairs
pairs$matches <- matches_col

# count number of matches and add to pairs
pairs <- pairs[, c("matchesN") := stringr::str_count(matches, ",") +1] %>%
  # sort pairs from most matches to least
  .[order(.$matchesN, decreasing = T), ]

#############
# clean covid results ####
##################

# remove keywords from matches >
# can't remove keywords in clean_title function because some titles may only consist of this key word e.g. "Systematic review" would be empty if used as keyword

# clean and tokenise keywords so they will match format in title_clean
keyword_cl <- unlist(strsplit(clean_title(keywords, stopwords = stopwords), split = " ")) %>%
  c(., c("2019", "pandemic")) %>%
  # turn into search string like stopword search string
  paste("\\b", ., "\\b", collapse = "|", sep = "")

# remove keywords from matches to see which are most similar (this assumes all/most titles contain one of the)

covid <- pairs[, -c("str2", "str1")]

covid$matches <- covid$matches %>%
  # remove keywords
  gsub(keyword_cl, "", .) %>% 
  # change all commas to spaces so can easily remove trailing commas
  gsub(",", " ", .) %>%
  # remove multiple spaces
  gsub("[[:space:]]{2,}", " ", .) %>%
  # remove whitespace at end
  trimws(., which= "both") %>%
  # turn spaces back into commas
  gsub(" ", ",", .) 

covid <- covid[order(covid$matchesN, decreasing = T), ]

sort(table(unlist(strsplit(covid$matches, ",", fixed = T))), decreasing = T)

end <- Sys.time()

############
# export ####
###########

fwrite(pairs, "outputs/matches.csv")



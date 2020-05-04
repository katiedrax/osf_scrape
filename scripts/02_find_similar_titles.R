library(data.table)
library(magrittr)

dt <- fread("outputs/preregs.csv", header = T, encoding = "UTF-8")

# i want to find which titles are the most similar in terms of the words they contain
# create dt of all titles compared to each other and their matches

max <- max(lengths(strsplit(dt$title, " ")))

cols <- paste("word", 1:max, sep = "")

dt <- dt[, (cols) := tstrsplit(title, " ", fixed = T)]

pairs_ls <- list()
n <- 1

for(i in dt$title){
  string_2 <- dt$title[dt$title != i]
  string_1 <- rep(i, length(string_2))
  length(string_1) <- dt[,.N]
  length(string_2) <- dt[,.N]
  df <- data.frame(string_1 = string_1, string_2 = string_2, stringsAsFactors = F)
  pairs_ls[[n]] <- df
  n <- n +1
}

pairs <- rbindlist(pairs_ls) %>%
  # remove duplicate rows
  unique()

# create list of vectors of split title strings so can easily intersect

split_ls <- strsplit(dt$title, " ", fixed = T)
names(split_ls) <- dt$title

matches <- list()

for(i in 1:nrow(pairs)){
  a <- pairs$string_1[i]
  b <- pairs$string_2[i]
  matches[[i]]<-   intersect(unlist(split_ls[a]), unlist(split_ls[b]))
  print(paste(i, "done"))
}


stopwords <- c("and", "the", "of", "a", "for", "to", "by", "in", "on", "amp", "from", "an")

matches_col <- matches %>%
  as.character() 

length(matches_col) <- pairs[,.N]
matches_col[matches_col == "character(0)"] <- NA

matches_col <- matches_col %>%
  # remove start
  gsub("c\\(", "", .) %>%
  #remove punct in middle of word and collapse words together
  gsub("[[:alpha:]][[:punct:]]{1,}[[:alpha:]]", "", .) %>%
  # remove remaining punctuation
  gsub("[[:punct:]]", " ", .) %>%
  # remove multiple spaces
  gsub("[[:space:]]{2,}", " ", .) %>%
  # remove trailing whitespace from replaced punctuation
  trimws(which = "both")

pairs$matches <- matches_col
pairs <- pairs[, c("matchesN") := lengths(strsplit(matches, " "))]

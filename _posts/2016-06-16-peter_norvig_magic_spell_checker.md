---
layout: post
title: "The Peter Norvig Magic Spell Checker in R"
category: Machine Learning
tags: modeling r
year: 2016
month: 06
day: 16
published: true
summary: "Peter Norvig, Director of Research at Google, offers a clever way for any of us to create a good spell checker with nothing more than a few lines of code and some text data."
image: magic-spell-checker/wizard-spell.png
---
<BR>
<p style="text-align:center">
<img src="../img/posts/magic-spell-checker/wizard-spell.png" alt="peter norvig magic spell checker" style='padding:1px; border:1px solid #021a40; width: 30%; height: 30%'></p>

**Resources**
<ul>
<li type="square"><a href="https://www.youtube.com/watch?v=gs74y1R-uEw&index=1&list=UUq4pm1i_VZqxKVVOz5qRBIA" target='_blank'>YouTube Companion Video</a></li>
</ul>
<BR><BR>

During a recent <a href='kaggle.com'>Kaggle competition</a>, I was
introduced to
<a href='https://en.wikipedia.org/wiki/Peter_Norvig' target='_blank'>Peter
Norvig's</a> blog entry entitled
<a href='http://www.norvig.com/spell-correct.html' target='blank'>How to
Write a Spelling Corrector</a>. He offers a clever way for any of us to
create a good spell checker with nothing more than a few lines of code
and some text data. No complex cascading grammar rules or API calls
required! In essence, you compare every one of your words agains the
large corpus of correctly spelled words.

In this post, I simply translated Peter's Python code into R as closely
to the orginal as possible. I used (or tried my best) the same
functions, variable names and constructs. This isn't about optimization
but clarity, and the good news is that there are plenty of ways of
optimizing the R code.

Before we start looking at the code, you will need to download Peter's
<a href='http://www.norvig.com/big.txt' target='_blank'>big.txt</a> and
save it locally. `big.txt` contains a million or so words from
<a href='http://www.gutenberg.org/wiki/Main_Page' target='_blank'>Project
Gutenberg</a> and other sources.

**Coding Time**

The first part is practically a verbatim copy of Peter's Python version.
It just loads the `big.txt` into memory, strips it of all non-alphabetic
characters, applies `tolower`, and returns unique words and their
frequencies.

    # point to local folder containing big.txt
    setwd('/Users/manuelamunategui/Documents/spell-check')

    words <- function(text){
         text <- gsub(x=text, pattern="[^[:alpha:]]", replacement = ' ')
         return (trimws(tolower(text)))
    }

    train <- function(features){
         features <- strsplit(x=features,split = ' ')
         model <- as.data.frame(table(features))
         return(model)
    }

    NWORDS = train(words(readChar('big.txt', file.info('big.txt')$size)))
    NWORDS$features <- as.character(NWORDS$features)

    head(NWORDS)

    ##    features   Freq
    ## 1           101160
    ## 2         a   6477
    ## 3     aaron      4
    ## 4   abandon      5
    ## 5 abandoned     15
    ## 6  abandons      1

<BR><BR>

Now we get to the heart of the code - we create variations of the word
being checked to help find the best match. We get iterations of the word
missing a letter, two letters transpositions, sequential replacement and
instertions with every letter of the alphabet - pheww!

    edits1 <- function(word) {

         # create copies of word with one letter missing
         deletes <- c()
         for (i in seq(1:nchar(word)))
              deletes <- c(deletes, paste0(substr(x=word,start = 0, stop=i-1), 
                           substr(x=word,start = i+1, stop=nchar(word))))

         # create copies of word with consecutive pair of letters transposed                   
         transposes <- c()
         vec_word <- strsplit(word, split = '')[[1]]
         for (i in seq(1:(nchar(word)-1))) {
              vec_word_tmp <- vec_word
              splice <- rev(vec_word_tmp[i:(i+1)])
              vec_word_tmp[i] <- splice[1]
              vec_word_tmp[i+1] <- splice[2]
              transposes <- c(transposes, paste(vec_word_tmp, collapse = ""))
         }
               
         # create copies of word with every letter replaced by letters of the alphabet                     
         replaces <- c()
         for (i in seq(1:nchar(word)))
              replaces <- c(replaces, paste0(substr(x=word,start = 0, stop=i-1), 
                                              letters, 
                                              substr(x=word,start = i+1, stop=nchar(word))))
     
         inserts <- c()
         for (i in seq(1:(nchar(word)+1)))
              inserts <- c(inserts, paste0(substr(x=word,start = 0, stop=i-1), 
                                              letters, 
                                              substr(x=word,start = i, stop=nchar(word))))
         
         return (unique(c(deletes, transposes, replaces, inserts)))
    }

<BR><BR> The above code is a lot faster in Python than my `R`
translation - optimization alert!

Peter gets not only gets the custom permutations for the word being
checked, he also gets the permutation of the permutation. That creates a
huge amount of words, so we trim the created words by checking if they
are actual words from our corpus:

    known_edits2 <- function(word) {
         matches <- c()
         for (edt in edits1(word)) matches <- c(matches, intersect(edits1(edt),NWORDS$features))
         return(unique(matches))
    }

<BR><BR> Function to check if the word exits:

    known <- function(words) { 
         return (unique(intersect(words,NWORDS$features)))
    }

<BR><BR> Our functions are ready but we need to call in them in order of
importance - least expensive first! This is uglier than the Peter's
Python version but it does know when to quit (i.e. when it gets the best
match).

    correct <- function(word){
         correct_spelling <- known(c(word))
         if (identical(correct_spelling, character(0))) {
              correct_spelling <- known(edits1(word))
              if (identical(correct_spelling, character(0))) {
                   correct_spelling <- known_edits2(word)
                   if (identical(correct_spelling, character(0))) {
                        correct_spelling <- word
                   }
              }
         }
         return (head(correct_spelling,1))
    }

    correct('spelng')

    ## [1] "spend"

    correct('speling')

    ## [1] "piling"

    correct('spelingg')

    ## [1] "spelingg"

    correct('spelinggg')

    ## [1] "spelinggg"

<BR><BR>

**Conclusion**

Though Peter states this isn't as accurate as an industrical spell
checker, the ramifications of such a simple approach are big! You can
easily focus your spell checking to higly specialized/technical terms as
long as you have the corpus - just as you can also localize your
spelling to other languages with supporting corpuses.

<a href='http://www.sumsar.net/blog/2014/12/peter-norvigs-spell-checker-in-two-lines-of-r/' target='_blank'>And
here is a great two-line implementation in R</a>! <BR><BR> <b>Big thanks
to Lucas for the Spelling Wizard art work!</b>

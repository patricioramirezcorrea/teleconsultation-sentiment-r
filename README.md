# teleconsultation-sentiment-r
This repository contains the R script and associated data for analyzing sentiment in tweets related to teleconsultation within specific Chilean cities. 

Project Structure

R/: Contains the R script (analyze_teleconsultation_tweets.R).

data/: This directory should contain the raw tweet data, typically in a format compatible with academictwitteR's bind_tweets function (e.g., JSON files). 
Note: For initial testing and code validation, only the first 100 tweet data files have been uploaded here, not the entire dataset.

output/: (Placeholder) Processed data will be saved here (e.g., tele-ciudades.xlsx).

Requirements
R (version 4.0 or higher recommended)
R packages: academictwitteR, dplyr, stringr, xlsx, syuzhet,TweetBotOrNot

Run the R script:
source("R/analyze_teleconsultation_tweets.R")

The script will output an Excel file named tele-ciudades.xlsx in your working directory (or the specified output path), containing the original tweet data, extracted emotion scores, and the calculated satisfaction valence.

Script Overview

1. Loads necessary R libraries.
2. Binds raw tweet data files into a single dataframe (remove tweets from accounts likely to be bots).
3. Defines keywords related to teleconsultation and a list of Chilean cities.
4. Filters tweets based on the presence of keywords in the tweet text and city names in the user's location.
5. Categorizes filtered tweets into three geographical groups based on user_location.
6. Applies the NRC Emotion Lexicon (via syuzhet package) to extract eight basic emotions (anger, anticipation, disgust, fear, joy, sadness, surprise, trust) and sentiment scores (positive/negative) for each tweet.
7. Operationalizes 'satisfaction' as a binary valence variable: 1 if positive emotions outweigh negative emotions, 0 otherwise.
8. Saves the augmented dataset, including emotion scores and satisfaction variable, to an Excel file.

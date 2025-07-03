# teleconsultation-sentiment-r
This repository contains the R script and associated data for analyzing sentiment in tweets related to teleconsultation within specific Chilean cities. 

Project Structure

R/: Contains the R script (analyze_teleconsultation_tweets.R).
data/: (Placeholder) This directory should contain the raw tweet data, typically in a format compatible with academictwitteR's bind_tweets function (e.g., JSON files).
output/: (Placeholder) Processed data will be saved here (e.g., tele-ciudades.xlsx).

Requirements
R (version 4.0 or higher recommended)
R packages: academictwitteR, dplyr, stringr, xlsx, syuzhet

Run the R script:
source("R/analyze_teleconsultation_tweets.R")

The script will output an Excel file named tele-ciudades.xlsx in your working directory (or the specified output path), containing the original tweet data, extracted emotion scores, and the calculated satisfaction valence.

Script Overview

0. Loads necessary R libraries.
1. Binds raw tweet data files into a single dataframe.
2. Defines keywords related to teleconsultation and a list of Chilean cities.
3. Filters tweets based on the presence of keywords in the tweet text and city names in the user's location.
4. Categorizes filtered tweets into three geographical groups based on user_location.
5. Applies the NRC Emotion Lexicon (via syuzhet package) to extract eight basic emotions (anger, anticipation, disgust, fear, joy, sadness, surprise, trust) and sentiment scores (positive/negative) for each tweet.
6. Operationalizes 'satisfaction' as a binary valence variable: 1 if positive emotions outweigh negative emotions, 0 otherwise.
7. Saves the augmented dataset, including emotion scores and satisfaction variable, to an Excel file.
   

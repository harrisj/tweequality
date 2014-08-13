An open source reverse-engineering of the Twee-Q project algorithm. Not because I disagree with their goals, but because I'm curious how design decisions affect the final result. This program contains 2 scripts:

- `analyze_gender.rb` tries to guess the genders of your retweets
- `analyze_retweets.rb` dumps some analysis of the timeline.

To use this, you need to run these steps:

1. On twitter.com, request your tweet archive
2. Download the tweet archive and extract it. Move the `tweets` directory here.
3. Run `ruby analyze_gender.rb`. This will dump a file `tweets/retweeted_users.csv` that is the result of its attempts to guess the genders of accounts you have retweeted.
4. Hand-edit the retweeted_users.csv file to correct gender guesses if you want to.
5. Then run `ruby analyze_retweets.rb` and it'll dump some CSV files

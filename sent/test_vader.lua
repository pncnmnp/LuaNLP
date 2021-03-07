package.path = package.path .. ";../external/?.lua"
inspect = require "inspect"
vader = require('vader')

-- Testing vader.lua

BASE = "./sentiment_labelled_sentences/"
files = {BASE .. "amazon_cells_labelled.txt", BASE .. "imdb_labelled.txt", BASE .. "yelp_labelled.txt"}
for _, file_name in pairs(files) do
    local file = io.open(file_name, "r")
    local yes, no = 0, 0
    for i=1,1000 do
        local data = string.gmatch(file:read(), "([^\t]+)")
        local sentence = data()
        local sentiment = data()
        if sentiment == "1" then
            sentiment = "positive"
        else
            sentiment = "negative"
        end
        local desc_guess = vader:polarity_scores(sentence)
        local guess = ""
        if desc_guess["compound"] >= 0 then
            guess = "positive"
        else
            guess = "negative"
        end

        if guess == sentiment then
            yes = yes + 1
        else
            no = no + 1
            -- uncomment for observing failures
            -- print(inspect(desc_guess), sentence, sentiment)
        end
    end
    print(file_name, "Correct: " .. yes, "Incorrect: " .. no)
end
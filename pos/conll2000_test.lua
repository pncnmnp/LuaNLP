package.path = package.path .. ";../external/?.lua"
inspect = require("inspect")
pt = require("perceptron")
TRAIN_FILE = "./conll2000/train.txt"
TEST_FILE = "./conll2000/test.txt"

--[[
    The training/testing data is from https://www.clips.uantwerpen.be/conll2000/chunking/
    For more information, see: ./conll2000/README.txt
--]]

function training(filename)
    local file = io.open(filename, "r")
    local done = false
    local training_set = {}
    while done ~= true do
        local found_end_of_sentence = false
        local sentence = {}
        while found_end_of_sentence ~= true do
            local sent = file:read()
            local func = string.gmatch(sent, "[^%s]+")
            local curr_word, tag, chunk_tag = func(), func(), func()
            -- print(sent, type(sent), inspect(curr_word), curr_word==nil)
            if curr_word == nil then
                found_end_of_sentence = true
            -- we have reached the end
            elseif curr_word == "END_OF_TRAINING_FILE" then
                found_end_of_sentence = true
                done = true
            else
                table.insert(sentence, {curr_word, tag})
            end
        end
        table.insert(training_set, sentence)
    end
    -- print(inspect(training_set))
    pt:train(training_set, 8)
    -- print(inspect(pt.tagdict))
    file.close()
end

function testing(filename)
    local file = io.open(filename, "r")
    local done = false
    local right = 0
    local wrong = 0
    while done ~= true do
        local found_end_of_sentence = false
        local sentence = {}
        local sentence_tag = {}
        while found_end_of_sentence ~= true do
            local sent = file:read()
            local func = string.gmatch(sent, "[^%s]+")
            local curr_word, tag, chunk_tag = func(), func(), func()
            if curr_word == nil then
                found_end_of_sentence = true
            -- we have reached the end
            elseif curr_word == "END_OF_TESTING_FILE" then
                found_end_of_sentence = true
                done = true
            else
                table.insert(sentence, curr_word)
                table.insert(sentence_tag, tag)
            end
        end

        local test_result = pt:tag(sentence, true, true)
        for i, result in pairs(test_result) do
            if result[2] == sentence_tag[i] then
                right = right + 1
            else
                -- print(result[2], sentence_tag[i], i, sentence[i])
                wrong = wrong + 1
            end
        end
    end
    print("Right: " .. right .. " Wrong: " .. wrong .. " Accuracy: " .. (right/(right+wrong)))
    file.close()
end

training(TRAIN_FILE)
testing(TEST_FILE)

-- sentences = {{{'today','NN'},{'is','VBZ'},{'good','JJ'},{'day','NN'}}, {{'yes','NNS'},{'it','PRP'},{'beautiful','JJ'}}}
-- pt:train(sentences, 3)
-- inspect(pt:tag({"today", "is", "beautiful", "day"}))

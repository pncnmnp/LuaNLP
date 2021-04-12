package.path = package.path .. ";../external/?.lua"
inspect = require("inspect")
json = require("json")
pt = require("perceptron")
TRAIN_FILE = "./conll2003/train.json"
TEST_FILE = "./conll2003/valid.json"

function to_json(filename)
    local file = io.open(filename, "r")
    local sents = file.read(file, "*a")
    file.close()
    sents = json.decode(sents)
    return sents
end

function training(filename)
    local training_set = to_json(filename)
    -- print(inspect(training_set))
    pt:train(training_set, 8)
end

function testing(filename)
    local test_set = to_json(filename)
    -- print(inspect(test_set))
    local right = 0
    local wrong = 0
    -- creating a confusion matrix
    local pr = {LOC={LOC=0, MISC=0, ORG=0, PER=0, O=0}, 
                MISC={LOC=0, MISC=0, ORG=0, PER=0, O=0}, 
                ORG={LOC=0, MISC=0, ORG=0, PER=0, O=0}, 
                PER={LOC=0, MISC=0, ORG=0, PER=0, O=0}, 
                O={LOC=0, MISC=0, ORG=0, PER=0, O=0}}

                for k, sentence in pairs(test_set) do
        local sent = {}
        local sentence_tag = {}
        for s, st in pairs(sentence) do
            table.insert(sent, st[1])
            table.insert(sentence_tag, st[2])
        end
        -- print(inspect(sent), inspect(sentence_tag))

        local test_result = pt:tag(sent, true, true)
        for i, result in pairs(test_result) do
            if result[2] == sentence_tag[i] then
                local pred_tag = ""
                if result[2] == "O" then
                    pred_tag = "O"
                else
                    pred_tag = string.sub(result[2], 3, -1)
                end
                -- print(result[2], sentence_tag[i], pred_tag)
                pr[pred_tag][pred_tag] = pr[pred_tag][pred_tag] + 1
            else
                -- print(result[2], sentence_tag[i], i, sent[i])
                -- wrong = wrong + 1
                local pred_tag = ""
                local actual_tag = ""
                if result[2] == "O" then
                    pred_tag = "O"
                else
                    pred_tag = string.sub(result[2], 3, -1)
                end

                if sentence_tag[i] == "O" then
                    actual_tag = "O"
                else
                    actual_tag = string.sub(sentence_tag[i], 3, -1)
                end
                pr[actual_tag][pred_tag] = pr[actual_tag][pred_tag] + 1
            end
        end
    end
    -- print(inspect(pr))
    local tags = {"LOC", "MISC", "ORG", "PER", "O"}
    for _, i_tag in ipairs(tags) do
        local num = pr[i_tag][i_tag]
        local precision_den = pr[i_tag][i_tag]
        local recall_den = precision_den
        -- For precision
        for _, j_tag in ipairs(tags) do
            if i_tag ~= j_tag then
                precision_den = precision_den + pr[j_tag][i_tag]
            end
        end

        -- For recall
        for _, j_tag in ipairs(tags) do
            if i_tag ~= j_tag then
                recall_den = recall_den + pr[i_tag][j_tag]
            end
        end
        print(i_tag .. " Precision: " .. (num/precision_den) .. " Recall: " .. (num/recall_den))
    end
    -- print("Right: " .. right .. " Wrong: " .. wrong .. " Accuracy: " .. (right/(right+wrong)))
end

training(TRAIN_FILE)
testing(TEST_FILE)

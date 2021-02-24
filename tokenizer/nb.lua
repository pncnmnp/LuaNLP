-- This is a modified version of https://github.com/firoxer/naive-bayes-lua

-- Original code's license:
-- Copyright 2017 Oliver Vartiainen

-- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


package.path = package.path .. ";../external/?.lua"
inspect = require "inspect"

local NB = {}

function NB:init(cols, pred_classes)
    -- print(inspect(cols), inspect(pred_classes))
    for _, class in pairs(pred_classes) do
        self.data[class] = {}
        for i=1, #cols do
            self.data[class][cols[i]] = {}
        end
    end
end

function NB:learn(row, pred_class)
    for col_name, datum in pairs(row) do
        -- print(col_name, datum, type(col_name), type(datum))
        self.data[pred_class][col_name] = self.data[pred_class][col_name] or {}
        self.data[pred_class][col_name][datum] = self.data[pred_class][col_name][datum] or 0
        self.data[pred_class][col_name][datum] = self.data[pred_class][col_name][datum] + 1 or 1
    end

    self.pred_class_tally[pred_class] = self.pred_class_tally[pred_class] or {}
    self.pred_class_tally[pred_class] = self.pred_class_tally[pred_class] or 0
    self.pred_class_tally[pred_class] = self.pred_class_tally[pred_class] + 1 or 1
end

local function calculate_total_probability(self, pred_class)
    local classification_count = 0
    for key,val in pairs(self.pred_class_tally) do
       if key ~= "metatable" then
          classification_count = classification_count + val
       end
    end
    return (self.pred_class_tally[pred_class]) / (classification_count)
end

local function calculate_probability(self, datum, col_name, pred_class)
    local datum_count = self.data[pred_class][col_name][datum]
    if datum_count == nil then
       datum_count = 0
    end
 
    local classification_count = 0
    for key, val in pairs(self.data[pred_class][col_name]) do
        classification_count = classification_count + val
    end

    -- for debugging
    -- print(datum, col_name, pred_class, datum_count, classification_count)
    return (datum_count) / (classification_count)
 end 

function NB:predict(pred_data)
    local best_likelihood = 0
    local best_classification = nil
 
    for pred_class in pairs(self.data) do
    --    local likelihood = calculate_total_probability(self, pred_class)
        local likelihood = 1
 
        for key, datum in pairs(pred_data) do
            likelihood =
                likelihood * calculate_probability(self, datum, key, pred_class)
            -- for debugging
            -- print("Best Likelihood ", likelihood, datum, pred_class, calculate_total_probability(self, pred_class), calculate_probability(self, datum, key, pred_class))
        end
 
       if likelihood > best_likelihood then
          best_likelihood = likelihood
          best_classification = pred_class
       end
    end
 
    return best_classification 
end

return {
    new = function ()
       local self = {
          data = {},
          pred_class_tally = {}
        }

        setmetatable(self.pred_class_tally, {
            __index = function () return 0 end
        })
        setmetatable(self, {__index = NB})
        return self
     end
}
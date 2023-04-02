class SearchController < ApplicationController
  require 'net/http'

  def search

  end
  def result
    uri = URI.parse("https://sheets.googleapis.com//v4/spreadsheets/1eworVB15Y_fZtzvWHPxBt_AWMZSByQecs9JM2vNnnCs/values/testing2nd?key=AIzaSyBqtRpLHwPEKyWtRoD_MvM7LdIutUPCjIc")
    response = Net::HTTP.get_response(uri)
    result = JSON.parse(response.body)
    arrayLength = result['values'].length
    i = 1
    @array = Array.new
    classification = params[:classification]
    length = params[:length].to_i
    number = params[:number]
    @begin_at_h = params[:begin_at_h].to_i
    begin_at_m = params[:begin_at_m].to_i
    @length_h = length / 60

    if classification == 'student'
      @condition1 = '学生'
    else
      @condition1 = '一般'
    end
    if number == 1
      @condition2 = '一人'
    else
      @condition2 = '複数'
    end

    if @begin_at_h >= 18
      section = 'night'
    else
      section = 'day'
    end

    while i < arrayLength do
      hash = Hash.new
      if result["values"][i][2] == classification and result["values"][i][3] == number and section == result['values'][i][5]
        id = result["values"][i][0]
        hash[:id] = id.to_i
        hash[:name] = result["values"][i][1]
        hash[:price] = result["values"][i][4].to_i * @length_h
        @array.push(hash)
      end
      i = i + 1
    end
    @priceOrderArray = @array.sort_by { |a| a[:price] }
    @distanceOrderArray = @array.sort_by { |a| a[:id] }
    @sortedArrayLength = @array.length
  end

  def map
  end
end

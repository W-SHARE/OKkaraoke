class SearchController < ApplicationController
  require 'net/http'
  require 'date'

  def search
    currentTime = Time.now
    @begin_at_h = currentTime.hour
    @begin_at_m = currentTime.min
    @length = 60
  end

  def result
    #入力情報の取得
    @classification = params[:classification]
    @length = params[:length].to_i
    @number = params[:number]
    @begin_at_h = params[:begin_at_h].to_i
    @begin_at_m = params[:begin_at_m].to_i
    @currentLatitude = params[:currentLatitude];
    @currentLongitude = params[:currentLongitude];
    paramsLatitude1 = URI.encode_www_form({latitude1: @currentLatitude})
    paramsLongitude1 = URI.encode_www_form({longitude1: @currentLongitude})

    #バリデーション
    if @classification == nil or @length == nil or @number == nil or @begin_at_h == nil or @begin_at_m == nil
      @validateMessage = "項目を全て入力してください"
      render("search/search")
    end

    #spreadsheetから情報を取得
    uri = URI.parse("https://sheets.googleapis.com//v4/spreadsheets/1eworVB15Y_fZtzvWHPxBt_AWMZSByQecs9JM2vNnnCs/values/testing2nd?key=AIzaSyBqtRpLHwPEKyWtRoD_MvM7LdIutUPCjIc")
    response = Net::HTTP.get_response(uri)
    result = JSON.parse(response.body)
    arrayLength = result['values'].length
    i = 1
    @array = Array.new
    length_h = @length / 60.to_f

    if @classification == 'student'
      @condition1 = '学生'
    else
      @condition1 = '一般'
    end
    if @number == 1
      @condition2 = '一人'
    else
      @condition2 = '複数'
    end

    if @begin_at_h >= 18
      section = 'night'
    else
      section = 'day'
    end

        # 以下は現在地を取得して緯度経度を渡す予定
        #address = '東京都新宿区高田馬場４丁目７−５'
        #params = URI.encode_www_form({q: address})
        #uri = URI.parse("https://msearch.gsi.go.jp/address-search/AddressSearch?#{params}")
        #response = Net::HTTP.get_response(uri)
        #addressResult = JSON.parse(response.body)
        #@currentLatitude = addressResult[0]["geometry"]["coordinates"][1]
        #@currentLongitude = addressResult[0]["geometry"]["coordinates"][0]
        #paramsLatitude1 = URI.encode_www_form({latitude1: @currentLatitude})
        #paramsLongitude1 = URI.encode_www_form({longitude1: @currentLongitude})

    while i < arrayLength do
      hash = Hash.new
      if result["values"][i][2] == @classification and result["values"][i][3] == @number and section == result['values'][i][5]

        #住所から緯度経度を求める
        address = result["values"][i][7]
        params = URI.encode_www_form({q: address})
        uri = URI.parse("https://msearch.gsi.go.jp/address-search/AddressSearch?#{params}")
        response = Net::HTTP.get_response(uri)
        addressResult = JSON.parse(response.body)
        objectLatitude = addressResult[0]["geometry"]["coordinates"][1]
        objectLongitude = addressResult[0]["geometry"]["coordinates"][0]
        hash[:latitude] = objectLatitude
        hash[:longitude] = objectLongitude

        #距離の測量
        paramsLatitude2= URI.encode_www_form({latitude2: objectLatitude})
        paramsLongitude2 = URI.encode_www_form({longitude2: objectLongitude})
        distanceUri = URI.parse("https://vldb.gsi.go.jp/sokuchi/surveycalc/surveycalc/bl2st_calc.pl?#{paramsLatitude1}&#{paramsLongitude1}&#{paramsLatitude2}&#{paramsLongitude2}&outputType=json&ellipsoid=bessel")
        distanceResponse = Net::HTTP.get_response(distanceUri)
        distanceResult = JSON.parse(distanceResponse.body)
        distance = distanceResult["OutputData"]["geoLength"].to_i

        #1.2km以内の検索結果を配列に入れる
        if distance <= 1200
          hash[:name] = result["values"][i][1]
          hash[:price] = (result["values"][i][4].to_i * length_h).to_i
          hash[:distance] = distance
          duration = distance / 80
          if duration >= 1
            hash[:duration] = duration
          else
            hash[:duration] = 1
          end
          hash[:company] = result["values"][i][8]
          hash[:phoneNumber] = result["values"][i][9]
          hash[:url] = result["values"][i][10]
          hash[:image] = result["values"][i][6]
          @array.push(hash)
        end
      end
      i = i + 1
    end
    @priceOrderArray = @array.sort_by { |a| a[:price] }
    @distanceOrderArray = @array.sort_by { |a| a[:distance] }
    @sortedArrayLength = @array.length
  end
end

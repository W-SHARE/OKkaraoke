class SearchController < ApplicationController
  require 'net/http'
  require 'date'

  def search
    currentTime = Time.now

    @begin_at_h = currentTime.hour
    @begin_at_m = currentTime.min
  end

  def result
    #入力情報の取得

    classification = params[:classification]
    @length = params[:length].to_i
    @begin_at_h = params[:begin_at_h].to_i
    @begin_at_m = params[:begin_at_m].to_i

    @currentLatitude = params[:currentLatitude].to_f
    @currentLongitude = params[:currentLongitude].to_f

    if classification == "student"
      @condition1 = "学生"
    else
      @condition1 = "一般"
    end

    #テスト用に現在地を手動で入力するのであればこちらに入力
    @currentLatitude = 35.713284
    @currentLongitude = 139.704939

    #現在地をuri用にエンコード。101行目あたりで使用
    currentLatitude = URI.encode_www_form({latitude1: @currentLatitude})
    currentLongitude = URI.encode_www_form({longitude1: @currentLongitude})

    #曜日の取得。尚       ["日曜日", "月曜日", "火曜日", "水曜日", "木曜日", "金曜日", "土曜日"]
    #整数                      0         1        2        3          4          5        6
    day = Date.today.wday

    #バリデーション

    if classification == nil or @length == nil or @begin_at_h == nil or @begin_at_m == nil #or @number = nil

      @validateMessage = "項目を全て入力してください"
      render("search/search")
    end

      #Spreadsheetからpage1のインポート
      uri = URI.parse("https://sheets.googleapis.com//v4/spreadsheets/1eworVB15Y_fZtzvWHPxBt_AWMZSByQecs9JM2vNnnCs/values/page1?key=AIzaSyBqtRpLHwPEKyWtRoD_MvM7LdIutUPCjIc")
      response = Net::HTTP.get_response(uri)
      resultPage1 = JSON.parse(response.body)
      #Spreadsheetからpage2のインポート
      uri = URI.parse("https://sheets.googleapis.com//v4/spreadsheets/1eworVB15Y_fZtzvWHPxBt_AWMZSByQecs9JM2vNnnCs/values/page2?key=AIzaSyBqtRpLHwPEKyWtRoD_MvM7LdIutUPCjIc")
      response = Net::HTTP.get_response(uri)
      resultPage2 = JSON.parse(response.body)

    #検索システムver2
    #検索結果を格納する配列
    @array = Array.new

    #利用時間を30進法と60進法で表記
    length30ary = @length / 30
    length60ary = @length / 60.to_f

    #繰り返し処理に必要な変数の宣言
    #arrayLngthハSpreadsheetでデータの入っている行数を示す
    arrayLength = resultPage1["values"].length
    #Spreadsheetで必要な情報が6行目以降なので6
    i = 5


    #検索結果を格納する繰り返し処理
    while i < arrayLength do

      #@arrayに代入する空想配列。繰り返しのたびに新しい箱を準備することで、上書きを防止
      hash = Hash.new

      #住所からカラオケ店舗の緯度経度を求める
      #param[][][]の最後の数字は、Spreadsheet上の列を示す。尚A列を0としてカウント
      address = resultPage1["values"][i][3]
      params = URI.encode_www_form({q: address})
      uri = URI.parse("https://msearch.gsi.go.jp/address-search/AddressSearch?#{params}")
      response = Net::HTTP.get_response(uri)
      addressResult = JSON.parse(response.body)
      objectLatitude = addressResult[0]["geometry"]["coordinates"][1]
      objectLongitude = addressResult[0]["geometry"]["coordinates"][0]
      hash[:latitude] = objectLatitude
      hash[:longitude] = objectLongitude

      #現在地とカラオケ店舗の距離計算。distanceはメートル
      objectLatitude = URI.encode_www_form({latitude2: objectLatitude})
      objectLongitude = URI.encode_www_form({longitude2: objectLongitude})
      distanceUri = URI.parse("https://vldb.gsi.go.jp/sokuchi/surveycalc/surveycalc/bl2st_calc.pl?#{currentLatitude}&#{currentLongitude}&#{objectLatitude}&#{objectLongitude}&outputType=json&ellipsoid=bessel")
      distanceResponse = Net::HTTP.get_response(distanceUri)
      distanceResult = JSON.parse(distanceResponse.body)
      distance = distanceResult["OutputData"]["geoLength"].to_i

      if distance <= 1200
        #検索結果に応じて料金を計算
        if @begin_at_h < 18 #昼
          if 1 <= day and day<= 5 #平日
            if classification == 'student' #学生
              if @length == 180 #フリータイム
                if resultPage2["values"][i][10] == "TRUE" #ワンドリンク制
                  hash[:price] = resultPage1["values"][i][15].to_i + 380
                else #飲み放題制
                  hash[:price] = resultPage1["values"][i][15].to_i
                end
              else #通常利用
                if resultPage2["values"][i][2] == "TRUE" #ワンドリンク制
                  hash[:price] = resultPage1["values"][i][7].to_i * length30ary + 380
                else #飲み放題制
                  hash[:price] = resultPage1["values"][i][7].to_i * length30ary
                end
              end
            else #一般
              if @length == 180 #フリータイム
                if resultPage2["values"][i][11] == "TRUE" #ワンドリンク制
                  hash[:price] = resultPage1["values"][i][16].to_i + 380
                else #飲み放題制
                  hash[:price] = resultPage1["values"][i][16].to_i
                end
              else #通常利用
                if resultPage2["values"][i][3] == "TRUE" #ワンドリンク制
                  hash[:price] = resultPage1["values"][i][8].to_i * length30ary + 380
                else #飲み放題制
                  hash[:price] = resultPage1["values"][i][8].to_i * length30ary
                end
              end
            end
          else #休日
            if classification == 'student' #学生
              if @length == 180 #フリータイム
                if resultPage2["values"][i][12] == "TRUE" #ワンドリンク制
                  hash[:price] = resultPage1["values"][i][17].to_i + 380
                else #飲み放題制
                  hash[:price] = resultPage1["values"][i][17].to_i
                end
              else #通常利用
                if resultPage2["values"][i][4] == "TRUE" #ワンドリンク制
                  hash[:price] = resultPage1["values"][i][9].to_i * length30ary + 380
                else #飲み放題制
                  hash[:price] = resultPage1["values"][i][9].to_i * length30ary
                end
              end
            else #一般
              if @length == 180 #フリータイム
                if resultPage2["values"][i][13] == "TRUE" #ワンドリンク制
                  hash[:price] = resultPage1["values"][i][18].to_i + 380
                else #飲み放題制
                  hash[:price] = resultPage1["values"][i][18].to_i
                end
              else #通常利用
                if resultPage2["values"][i][5] == "TRUE" #ワンドリンク制
                  hash[:price] = resultPage1["values"][i][10].to_i * length30ary + 380
                else #飲み放題制
                  hash[:price] = resultPage1["values"][i][10].to_i * length30ary
                end
              end
            end
          end
        else #夜
          if 1 <= day and day <= 5 #平日
            if classification == 'student' #学生
              if @length == 180 #フリータイム
                if resultPage2["values"][i][10] == "TRUE" #ワンドリンク制
                  hash[:price] = resultPage1["values"][i][19].to_i + 380
                else #飲み放題制
                  hash[:price] = resultPage1["values"][i][19].to_i
                end
              else #通常利用
                if resultPage2["values"][i][6] == "TRUE" #ワンドリンク制
                  hash[:price] = resultPage1["values"][i][11].to_i * length30ary + 380
                else #飲み放題制
                  hash[:price] = resultPage1["values"][i][11].to_i * length30ary
                end
              end
            else #一般
              if @length == 180 #フリータイム
                if resultPage2["values"][i][11] == "TRUE" #ワンドリンク制
                  hash[:price] = resultPage1["values"][i][20].to_i + 380
                else #飲み放題制
                  hash[:price] = resultPage1["values"][i][20].to_i
                end
              else #通常利用
                if resultPage2["values"][i][7] == "TRUE" #ワンドリンク制
                  hash[:price] = resultPage1["values"][i][12].to_i * length30ary + 380
                else #飲み放題制
                  hash[:price] = resultPage1["values"][i][12].to_i * length30ary
                end
              end
            end
          else #休日
            if classification == 'student' #学生
              if @length == 180 #フリータイム
                if resultPage2["values"][i][12] == "TRUE" #ワンドリンク制
                  hash[:price] = resultPage1["values"][i][21].to_i + 380
                else #飲み放題制
                  hash[:price] = resultPage1["values"][i][21].to_i
                end
              else #通常利用
                if resultPage2["values"][i][8] == "TRUE" #ワンドリンク制
                  hash[:price] = resultPage1["values"][i][13].to_i * length30ary + 380
                else #飲み放題制
                  hash[:price] = resultPage1["values"][i][13].to_i * length30ary
                end
              end
            else #一般
              if @length == 180 #フリータイム
                if resultPage2["values"][i][13] == "TRUE" #ワンドリンク制
                  hash[:price] = resultPage1["values"][i][22].to_i + 380
                else #飲み放題制
                  hash[:price] = resultPage1["values"][i][22].to_i
                end
              else #通常利用
                if resultPage2["values"][i][9] == "TRUE" #ワンドリンク制
                  hash[:price] = resultPage1["values"][i][14].to_i * length30ary + 380
                else #飲み放題制
                  hash[:price] = resultPage1["values"][i][14].to_i * length30ary
                end
              end
            end
          end
        end

        #注意事項の処理
        #時間帯を横断
        if @begin_at_h + length60ary >18
          @alertMultiTimeZone = true
        end
        #営業時間が終了する可能性
        if @begin_at_h + length60ary > 6
          @alertPossiblyClose = true
        end
        #開店前の可能性
        if @begin_at_h < 10
          @alertBeforeOpen = true
        end

        #料金以外の店舗情報を入力
        hash[:name] = resultPage1["values"][i][1]
        hash[:distance] = distance

        #所要時間の算出
        duration = distance / 80
        if duration >= 1
          hash[:duration] = duration
        else
          hash[:duration] = 1
        end
        hash[:company] = resultPage1["values"][i][5]
        hash[:phoneNumber] = resultPage1["values"][i][4]
        hash[:url] = resultPage1["values"][i][2]
        hash[:image] = resultPage1["values"][i][6]
        @array.push(hash)
      end
      i = i + 1
    end #while文のend
  @priceOrderArray = @array.sort_by { |a| a[:price] }
  @distanceOrderArray = @array.sort_by { |a| a[:distance] }
  @sortedArrayLength = @array.length
  end #resultコントローラーのend
end

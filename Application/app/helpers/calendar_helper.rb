# -*- coding: utf-8 -*-
module CalendarHelper
  def calender(date_org)
    cal = ""
    cal << "<table><thead><tr>"
    #曜日
    week = ["日", "月", "火", "水", "木", "金", "土"]
    #表示するカレンダーの年月日データ
    d = Date.new(date_org.year, date_org.month, date_org.day)
    #表示するカレンダーの1日の曜日
    youbi = d.beginning_of_month.cwday
    #表示するカレンダー1日より左にある余白の数
    left = (youbi == 7)? 0 : youbi
    #表示するカレンダーの最終日
    end_date = d.end_of_month
    #表示するカレンダーの最終日の曜日
    end_youbi = d.end_of_month.cwday
    #表示するカレンダーの最終日の右にある余白の数
    right = 6 - end_youbi
    #日にち
    date = 1
    week.each do |w|
      cal << "<th>#{w}</th>"
    end
    cal << "</tr></thead><tbody><tr>"
    #1日より左にある余白分<td></td>を書き出す
    left.times do
      cal << "<td></td>"
    end
    #最終日の日数分回す
    end_date.day.times do
      if youbi == 7 && date != 1
        youbi = 0
        cal << "</tr>"
        cal << "<tr>"
      elsif youbi ==7 && date ==1
        youbi = 0
      end
      if date_org.day == date && @date == date_org
        cal << "<td style=\"color:#ff0000;\">#{date}</td>"
      else
        url = url_for(:action => :day,:user => @user.login, :date => "#{date_org.year}-#{date_org.month}-#{date}", :type => @type, :project => @project, :ticket => @t_name)
        cal << "<td><a href=\"#{url}\">#{date}</a></td>"
      end
      youbi += 1
      date += 1
    end
    #最終日の右にある余白分<td></td>を書き出す
    right.times do
      cal << "<td></td>"
    end
    cal << "</tr></tbody>"
    cal << "</table>"
  end
end

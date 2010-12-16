# -*- coding: utf-8 -*-
class GraphController < ApplicationController
  include TtmsHelper
  #作業データのグラフ化
  def graph_day_all
    tm_set params
    @data = {}
    tickets = Ticket.where(:project_id => @project)
    tickets.each do |ticket|
      @data[ticket.name] = 
        tm_day_sum(
                   Tweet.user_and_ticket(@user.id, ticket.id).
                   work_time.
                   time_between(@date, @date.tomorrow))
    end
    color = ["#CCFF00", "#FF99FF", "#99FF00", "#9966FF", "#00FF00", "#FFFFFF", "#66FF99", "#DDAA00", "#0000FF"]
    bar = BarStack.new
    array = []
    keys = []
    max = 0
    cnt = 0
    @data.each do |key, value|
      keys << BarStackKey.new(color[cnt], key, 11)
      time = value
      pp time
      time = value.to_f / 3600 unless value == 0
      array << BarStackValue.new(time, color[cnt])
      max += time
      cnt += 1
    end

   
    bar.values = [array]
    bar.set_keys keys
    bar.tip = "時間:#val#<br>合計:#total#"

    x_labels = XAxisLabels.new
    x_labels.labels = [tm_sagyoubi(@date)]

    x = XAxis.new
    x.set_labels x_labels
    x.set_offset(true)
    y = YAxis.new
    y.set_range 0, max.to_i + 1
    
    x_legend = XLegend.new "Day" 
    x_legend.set_style '{font-size: 20px; color: #778877}'

    y_legend = YLegend.new "Time"
    y_legend.set_style '{font-size: 20px; color: #770077}'

    title = Title.new "#{tm_sagyoubi @date}作業時間"
    title.set_style '{font-size: 32px}'
    chart = OpenFlashChart.new
    chart << bar
    chart.set_title title
    chart.set_x_legend x_legend
    chart.set_y_legend y_legend
    chart.set_x_axis  x
    chart.set_y_axis y
    render :text => chart.to_s

  end

  def graph_24
    tm_set params
    @date = @date.to_time
    sagyou = []
    array = []
    t = []
    if @ticket
      tweets = Tweet.user_and_ticket(@user.id, @ticket.id).work_time
      tweets = tweets.time_between(@date, @date.since(1.day - 1))
      array = []
      flag = true
      befor = -32400
      after = 0
      if tweets[0].cmd_id == 3 || tweets[0].cmd_id == 2
        flag = !flag
      end
      comment = []
      t << @ticket.name
      tweets.each do |tweet|
        if flag
          befor = tweet.time.to_i - @date.to_i - 32400
          comment <<  tweet.cmd.cmd + '=>' +tweet.comment + "\n"
          flag = !flag
        else
          after = tweet.time.to_i - @date.to_i - 32400
          comment <<  tweet.cmd.cmd + '=>' + tweet.comment + "\n"
          bar = HBar.new
          bar.values = [HBarValue.new(befor, after, :tip => tm_time(after - befor) + "\n" + comment.join)]
          bar.colour = '#FEC13F'
          array <<  bar
          flag = !flag
          comment.clear
        end
      end
      unless flag
        after = 86400 - 32400
        bar = HBar.new
        bar.values = [HBarValue.new(befor, after, :tip => tm_time(after - befor) + "\n" + comment.join)]
        bar.colour = '#FEC13F'
        array <<  bar
      end
    elsif @project
      tweets = Tweet.where(:user_id => @user.id, :project_id => @project).work_time
      tickets = tweets.today_join_ticket(@date, @date.since(1.day))
      tickets.each do |ttt|
        ticket = ttt.ticket
        name = ticket.name
        tmp = []
        tweet = tweets.where(:ticket_id => ticket.id).time_between(@date, @date.since(1.day))
        flag = true
        befor = -32400
        after = 0
        next if tweet.empty?
        if tweet[0].cmd_id == 3 || tweet[0].cmd_id == 2
          flag = !flag
        end
        comment = []
        
        tweet.each do |t|
          if flag
            befor = t.time.to_i - @date.to_i - 32400
            comment <<  t.cmd.cmd + '=>' +t.comment + "\n"
            flag = !flag
          else
            after = t.time.to_i - @date.to_i - 32400
            comment <<  t.cmd.cmd + '=>' + t.comment + "\n"
            tmp << HBarValue.new(befor, after, :tip => tm_time(after - befor) + "\n" + comment.join)
            flag = !flag
            comment.clear
          end
        end
        unless flag
          after = 86400 - 32400
          tmp << HBarValue.new(befor, after, :tip => tm_time(after - befor) + "\n" + comment.join)
        end
        sagyou << [name, tmp]
        
      end
      sagyou.sort!{|a,b|a[1].size<=>b[1].size}
      sagyou.size.times do |i|
        t[i] = sagyou[i][0]
      end
      sagyou[0][1].size.times do |i|
        bar = HBar.new
        t2 = []
        bar.values = []
        sagyou.size.times do |j|
          t2 << sagyou[j][1][i] if sagyou[j][1][i]   
        end
        bar.values = t2
        bar.colour = '#FEC13F'
        array << bar
      end
    else
      tweets = Tweet.where(:user_id => @user.id).work_time
      project = tweets.today_join_project(@date, @date.since(1.day))
      project.each do |p|
        project = p.project
        name = project.name
        tmp = []
        tweet = tweets.where(:project_id => project.id).time_between(@date, @date.since(1.day))
        next if tweet.empty?
        flag = true
        befor = -32400
        after = 0
        if tweet[0].cmd_id == 3 || tweet[0].cmd_id == 2
          flag = !flag
        end
        comment = []
        
        tweet.each do |t|
          if flag
            befor = t.time.to_i - @date.to_i - 32400
            comment <<  t.cmd.cmd + '=>' +t.comment + "\n"
            flag = !flag
          else
            after = t.time.to_i - @date.to_i - 32400
            comment <<  t.cmd.cmd + '=>' + t.comment + "\n"
            tmp << HBarValue.new(befor, after, :tip => tm_time(after - befor) + "\n" + comment.join)
            flag = !flag
            comment.clear
          end
        end
        unless flag
          after = 86400 - 32400
          tmp << HBarValue.new(befor, after, :tip => tm_time(after - befor) + "\n" + comment.join)
        end
        sagyou << [name, tmp]
        
      end
      sagyou = sagyou.sort{|a,b|a[1].size<=>b[1].size}.reverse
      sagyou.reverse.each{|a|t << a[0]}
      sagyou[0][1].size.times do |i|
        bar = HBar.new
        t2 = []
        bar.values = []
        sagyou.size.times do |j|
          t2 << sagyou[j][1][i] if sagyou[j][1][i]   
        end
        bar.values = t2
        bar.colour = '#FEC13F'
        array << bar
      end
    end
    title = Title.new("24時間表示")
      

    chart = OpenFlashChart.new
    chart.set_title(title)

    x = XAxis.new
    x.set_offset(true)
    x.set_range(0 - 32400, 86400- 32400)
    x.steps = 3600
    time = []
    25.times{|i| time << i}
    labels = XAxisLabels.new
    labels.steps = 3600
    labels.visible_steps = 4
    labels.text = "#date: H:i #"
    x.labels = labels
    chart.set_x_axis(x)

    y = YAxis.new
#    y.set_range(1.5, 1)
    y.set_offset(true)
    y.set_labels(t)
    chart.set_y_axis(y)
    array.each{|data| chart.add_element data}
    render :text => chart.to_s
  end

  def graph_day
    tm_set params
    if @project
      @data = sagyouzikan :day, @date
    else    
      @data = tm_all_sagyou :day, @date
    end
    color = ["#CCFF00", "#FF99FF", "#99FF00", "#9966FF", "#00FF00", "#FFFFFF", "#66FF99", "#DDAA00", "#0000FF"]
    
    bar = BarStack.new
    array = []
    keys = []
    max = 0
    @data.each_with_index do |data, i|
      keys << BarStackKey.new(color[i], data[0], 11)
    end
    @data[0][1].size.times do |i|
      day = @data[0][1].keys.sort
      value = []
      sum = 0
      @data.each_with_index do |data, l|
        time = data[1][day[i]].to_f / 3600
        value << BarStackValue.new(time, color[l])
        sum += time
      end
      max = sum if sum > max
      array << value
    end

    bar.tip = "時間:#val#<br>合計:#total#"
    bar.values = array
    bar.set_keys keys
    
    x_labels = XAxisLabels.new
    x_labels.steps = 1
    x_labels.rotate = 50
    x_labels.labels = @data[0][1].keys.sort.map{|key| key = tm_sagyoubi key}

    x = XAxis.new
    x.set_labels x_labels

    y = YAxis.new
    y.set_range 0, max.to_i + 1
    
    x_legend = XLegend.new "Day" 
    x_legend.set_style '{font-size: 18px; color: #778877}'

    y_legend = YLegend.new "Time(h)"
    y_legend.set_style '{font-size: 18px; color: #770077}'

    title = Title.new "#{tm_sagyoubi @date.ago(4.day)}から5日間"
    title.set_style '{font-size: 28px}'
    chart = OpenFlashChart.new
    chart << bar
    chart.set_title title
    chart.set_x_legend x_legend
    chart.set_y_legend y_legend
    chart.set_x_axis  x
    chart.set_y_axis y
    render :text => chart.to_s

  end

  def graph_week
    tm_set params
    if @project
      @data = sagyouzikan :week, @date
    else
      @data = tm_all_sagyou :week, @date
    end
    color = ["#9966FF", "#00FF00","#DDAA00", "#0000FF", "#CCFF00", "#FF99FF", "#99FF00", "#FFFFFF", "#66FF99"]
    
    bar = BarStack.new
    array = []
    keys = []
    max = 0

    @data.each_with_index do |data, i|
      keys << BarStackKey.new(color[i], data[0], 11)
    end
    @data[0][1].size.times do |i|
      day = @data[0][1].keys.sort
      value = []
      sum = 0
      @data.each_with_index do |data, l|
        time = data[1][day[i]].to_f / 3600
        value << BarStackValue.new(time, color[l])
        sum += time
      end
      max = sum if sum > max
      array << value
    end

    bar.tip = "時間:#val#<br>合計:#total#"
    bar.values = array
    bar.set_keys keys
    
    x_labels = XAxisLabels.new
    x_labels.steps = 1
    x_labels.rotate = 50
    x_labels.labels = @data[0][1].keys.sort.map{|key| key = tm_sagyoubi key}

    x = XAxis.new
    x.set_labels x_labels

    y = YAxis.new
    y.set_range 0, max.to_i + 1, 5
    
    x_legend = XLegend.new "Day(week)" 
    x_legend.set_style '{font-size: 18px; color: #778877}'

    y_legend = YLegend.new "Time(h)"
    y_legend.set_style '{font-size: 18px; color: #770077}'

    title = Title.new "#{tm_sagyoubi @date.beginning_of_week.ago(4.week)}から5週間"
    title.set_style '{font-size: 28px}'
    chart = OpenFlashChart.new
    chart << bar
    chart.set_title title
    chart.set_x_legend x_legend
    chart.set_y_legend y_legend
    chart.set_x_axis  x
#    chart.y_asis = y
    chart.set_y_axis y
    render :text => chart.to_s
  end 

  def graph_month
    tm_set params
    if @project
      @data = sagyouzikan :month, @date
    else
      @data = tm_all_sagyou :month, @date
    end
    color = ["#CCFF00", "#FF99FF", "#99FF00", "#9966FF", "#00FF00", "#FFFFFF", "#66FF99", "#DDAA00", "#0000FF"]
    
    bar = BarStack.new
    array = []
    keys = []
    max = 0
    @data.each_with_index do |data, i|
      keys << BarStackKey.new(color[i], data[0], 11)
    end
    @data[0][1].size.times do |i|
      day = @data[0][1].keys.sort
      value = []
      sum = 0
      @data.each_with_index do |data, l|
        time = data[1][day[i]].to_f / 3600
        pp data
        value << BarStackValue.new(time, color[l], :tip => "時間:#val#<br>合計:#total#")
        sum += time
      end
      max = sum if sum > max
      array << value
    end
    bar.values = array
    bar.set_keys keys
    
    x_labels = XAxisLabels.new
    x_labels.steps = 1
    x_labels.rotate = 50
    x_labels.labels = @data[0][1].keys.sort.map{|key| key = tm_sagyoubi key}

    x = XAxis.new
    x.set_labels x_labels

    y = YAxis.new
    y.set_range 0, max.to_i + 1, 50
    
    x_legend = XLegend.new "Day(month)" 
    x_legend.set_style '{font-size: 18px; color: #778877}'

    y_legend = YLegend.new "Time(h)"
    y_legend.set_style '{font-size: 18px; color: #770077}'

    title = Title.new "#{tm_sagyoubi @date.beginning_of_month.ago(4.month)}から5ヶ月間"
    title.set_style '{font-size: 28px}'
    chart = OpenFlashChart.new
    chart << bar
    chart.set_title title
    chart.set_x_legend x_legend
    chart.set_y_legend y_legend
    chart.set_x_axis  x
    chart.set_y_axis y
    render :text => chart.to_s
  end
end

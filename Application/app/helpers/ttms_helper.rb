# -*- coding: utf-8 -*-
require 'pp'
module TtmsHelper
  def tm_set params
    @date = Date.parse params[:date] if params[:date]
    @type = params[:type] if params[:type]
    if params[:ticket]
      @ticket = Ticket.where(:name => params[:ticket]).first
      @t_name = @ticket.name
    end
    @project = Project.find(params[:project].to_i) if params[:project]
    if params[:user]
      @user = User.where(:login => params[:user]).first
    end
    @date ||= Date.today
#    @type ||= 'day'
    @user ||= User.find(session[:user_id])
  end
  def step type, date, str
    ido = :ago if str =~ /<</
    ido ||= :since
    type ||= 'day'
    date = date.send(ido, 1.send(type))
  end
  def tm_sagyoubi day
   day.strftime "%Y年%m月%d日"
  end
  def tm_sagyoutime time
    time.strftime "%H時%M分%S秒"
  end
  #秒から時間、分、秒に変更
  def tm_time time
    hour = time / (60 * 60)
    min = (time - hour * 60 * 60) / 60
    sec = time - (hour * 60 * 60 + min * 60)
    tm_time_string [hour,min,sec]
  end
  #数値から文字列に変換
  def tm_time_string x
    str = ""
    str << "#{x[0]}時間" #if x[0] > 0
    str << "#{x[1]}分" #if x[1] > 0
    str << "#{x[2]}秒"
  end
  #コマンドを元に数値をプラマイに変換
  def tm_cmd_sum tw
    time = tw.time.to_i
    time *= -1 if tw.cmd_id == 1 || tw.cmd_id == 4
    time
  end
  #時間の加減算処理
  def tm_day_sum data
    sum = 0
    unless data.empty?
      case data[0].cmd_id
      when 2
        sum -= data[0].time.beginning_of_day.to_i
      when 3
        sum -= data[0].time.beginning_of_day.to_i
#      when 4
#        sum -= data[0].time.beginning_of_day.to_i * 2
      end
      
      case data[data.size - 1].cmd_id
      when 1
        sum += data[data.size - 1].time.beginning_of_day.tomorrow.to_i
#      when 2
#        sum += data[data.size - 1].time.beginning_of_day.tomorrow.to_i * 2
      when 4
        sum += data[data.size - 1].time.beginning_of_day.tomorrow.to_i
      end
      data.each do |tw|
        begin
          sum += tm_cmd_sum(tw)
        rescue
          next
        end
      end    
    end
    sum
  end
    
  def tm_calc date, x, y
    data = {}
    user, ticket, date = @user.id, @ticket.id, date.to_time
    befor = date.send("beginning_of_#{y}").ago(1.send(x))
    case y
      when :day
      befor = date.beginning_of_day.ago(4.day)
      when :week
      befor = date.beginning_of_week.yesterday.ago(4.week)
      when :month
      befor = date.beginning_of_month.ago(4.month)
    end
    tweets = Tweet.user_and_ticket(user, ticket).work_time
    5.times do
      tmp = tweets.time_between(befor, befor.since(1.send(y) - 1))
      data[befor.to_date] = tm_day_sum(tmp)
      befor = befor.since(1.send(y))
    end
    return data #tweets
  end
  #  private
  def search_user
    @search_user = SearchForm.new params[:search_form], :user
  end
  def search_project
    @search_project = SearchForm.new params[:search_form], :ticket
  end
  def tm_layout_day day
    day_title = {'day' => '一日', 'week' => '一週間', 'month' => '一ヶ月', 'year' => '一年間'}
    day_title[day]
  end
  def tm_all_sagyou day, date
    data = []
    groups = Group.where(:user_id => @user.id)
    groups.each do |group|
      @project = group.project_id
      tmp = sagyouzikan day, date
      sum = {}
      tmp.each{|t| 
        t[1].each{|key, value|
          sum[key] ||= 0
          sum[key] += value
        }
      }
      p_user = Group.where(:project_id => @project, :master => true).first
      data << ["#{User.find(p_user.user_id).login}##{Project.find(@project).name}", sum]
    end
    @project = nil
    data
  end
  def sagyouzikan day, date
    data = []
    type = @type
    if @ticket == nil
      tickets = Ticket.where(:project_id => @project)
      tickets.each do |ticket|
        @ticket = ticket
        data << [ticket.name, tm_calc(date, type, day)]
      end
      data.sort{|a, b| a[1].size <=> b[1].size}
      @ticket = nil
    else
      name = Ticket.find(@ticket.id)
      data << [name.name, tm_calc(date, type, day)]
    end
    data
  end
  def day_sagyouzikan date
    tmp = date.to_time
    sum = resume = 0
    array = []
    datas = 
      Tweet.user_and_ticket(@user.id, @ticket.id).
      work_time.
      time_between(date, date.tomorrow)
    return if datas.empty?
    case datas[0].cmd_id
    when 2
      sum -= date.to_time.beginning_of_day.to_i
    when 3
      sum -= date.to_time.beginning_of_day.to_i
    when 4
      resume -= date.to_time.beginning_of_day.to_i
    end  
    datas.each do |data|
      time = tm_cmd_sum data
      sum += time
      case data.cmd_id
      when 1
        tmp = data.time
      when 2, 4
        resume += (time * (-1))
      when 3
        array << [tm_sagyoutime(tmp),
                  tm_sagyoutime(data.time),
                  tm_time(sum),
                  tm_time(resume)]
        sum = resume = 0
      end
    end
    unless sum == 0
      time = date.beginning_of_day.tomorrow.to_time.to_i
      case datas[datas.size - 1].cmd_id
      when 1
        sum += time
      when 2
        resume += time
      when 4
        sum += time
      end
      array << [tm_sagyoutime(tmp),
                tm_sagyoutime(date.to_time.tomorrow - 1),
                tm_time(sum),
                tm_time(resume)]
    end
    return array
  end
  def tm_comment date
    comment = []
    comments = Tweet.time_between(date, date.tomorrow).where(:cmd_id => 10, :ticket_id => @ticket.id)
    comments.each{|cmt| comment << [User.find(cmt.user_id).login, cmt.time, 'comment', cmt.comment, cmt.url]}
    comments = Tweet.time_between(date, date.tomorrow).where(:cmd_id => 1..4, :ticket_id => @ticket.id)
    comments.each do |cmt|
    comment << [User.find(cmt.user_id).login, cmt.time, Cmd.find(cmt.cmd_id).cmd, cmt.comment, cmt.url] if cmt.comment =~ /\S+/
    end
    comment.sort{|a,b|a[0]<=>b[0]}
  end
end

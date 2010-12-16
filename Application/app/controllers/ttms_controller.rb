# -*- coding: utf-8 -*-
require 'pp'
class TtmsController < ApplicationController
  include TtmsHelper
  include CalendarHelper
  before_filter :login_required, :except => :twitter
#ログイン画面
  def twitter
    if logged_in?
      redirect_to :action => :index
    else
      render :layout => false
    end
  end
#Twitterの投稿用フォーム表示
  def twitter_form
    @list = {:graph => 'グラフは見やすかったか', :use => '使いやすかったか',  :benri => '便利と思ったか', :next => 'これからも利用したいか'}
    render :layout => false
  end
#Twitterへの投稿
  def twitter_create
    pp params
    if params[:twitter]
      twitter = params[:twitter]
      text = ""
      text << "@EREFY"
      tmp = [twitter[:graph],twitter[:use],twitter[:benri],twitter[:next]]
      text << tmp.join(',')
      text << "コメント => #{twitter[:comment]}"
    end
    cansell = true if params[:cansell]
    if cansell
      @text = "投稿をキャンセルしました"
    elsif current_user.twitter.post('/statuses/update.json', :status => text)
      @text = "tweet成功"
    end
#  rescue
#    @text ||= "tweet失敗"
  ensure
    url = url_for :action => :twitter_form
    text = "#{@text}<br><a href=\"#{url}\" data-remote=\"true\" data-type=\"html\" data-update=\"twitter\">投稿</a>"
    render :text => text
  end
#カレンダー出力
  def cal
    tm_set params
    @cal = Date.parse params[:cal]
    @cal ||= @date
    befor =  url_for :action => :cal,:user => @user.login, :cal => @cal.ago(2.month).next_month, :date => @date, :type => @type, :project => @project, :ticket => @ticket
    after =  url_for :action => :cal,:user => @user.login, :cal => @cal.next_month, :date => @date, :type => @type, :project => @project, :ticket => @ticket
    text = ""
    text << "<a href=\"#{befor}\" data-remote=\"true\" data-type=\"html\" data-update=\"cal\"><<</a>"
    text << "#{@cal.year}年#{@cal.month}月"
    text << "<a href=\"#{after}\" data-remote=\"true\" data-type=\"html\" data-update=\"cal\">>></a>"
    text << calender(@cal)
    render :text => text
  end
#プロジェクト概要編集
  def edit
    pro = params[:project]
    @project = Project.find(pro[:id])
    @project.attributes = {:outline => pro[:outline], :updated_at => Time.now}
    @project.save
    render :layout => false
  end
#コメント非表示
  def not_comment
    @ticket = params[:ticket]
    @su = params[:su]
    render :layout => false
  end
#コメント表示
  def comment
    @su = params[:su]
    @ticket = params[:ticket]
    @comments = Tweet.where(:ticket_id => params[:ticket], :cmd_id => 1..4).where(:cmd_id => 10).where('comment like :q', :q => "%_%").order('time desc').limit(10)
    render :layout => false
  end
  def search
    @project = Project.find(params[:project])
    cansell = true if params[:cansell]
    group = Group.where(:user_id => session[:user_id], :project_id => @project.id, :master => true)
    if group.empty? || cansell
      render :edit, :layout => false
    else
      render :layout => false
    end
  end
#ユーザ一覧表示
  def user_list
    tm_set params
    @users = User.order(:name)
    @user_list = true
  end
#プロジェクト一覧表示
  def project_list
    tm_set params
    @projects = Project.order('updated_at desc')
    @project_list = true
  end
#プロジェクト詳細表示
  def p_more
    tm_set params
    @tickets = Ticket.where(:project_id => @project.id).order('updated_at desc')
  end
  def project
    @project_id = params[:project].to_i
    @tickets = Ticket.where(:project_id => @project_id)
    render :layout => false
  end
  def p_user
    session[:ticket] = 0
    session[:user] = params[:user_id].to_i
    session[:user_name] = User.find(session[:user]).name
    redirect_to :action => :day, :date => Date.today
  end
  def index
    tm_set params
   # search_use
    search_project unless params[:ticket]
    @date = Date.parse(params[:date]) if params[:date]
    @date ||= Date.today
   # if @search_user.x.present?
   #   @projects = Group.user_in_projects(@search_user.x)
    if params[:ticket]
#      @users = Group.joins(:user)(params[:project])
#      session[:project] = params[:project]    
    elsif @search_project.x.present?
      @users = Group.project_in_users(@search_project.x)
      session[:project] = @search_project.x
    else
      redirect_to :action => :day, :user => @user.login
    end
  end
#メイン
  def day
    tm_set params
    if @type && @project
      if @type == 'month'
        @data = sagyouzikan :month, @date
      elsif @type == 'week'
        @data = sagyouzikan :week, @date
      elsif @type == 'day'
        @data = sagyouzikan :day, @date
      end
      graph_url = url_for(:controller => :graph, :action => "graph_#{@type}", :type => @type, :date => @date, :user => @user.login, :project => @project, :ticket => @t_name)
      # @graph = open_flash_chart_object(500, 500, graph_url, true, "/ttms/")
      @graph = open_flash_chart_object(500, 500, graph_url, "")
      render :time
    elsif @project
      if @ticket == nil && !Tweet.users(@user.id).today_join_ticket(@date, @date.tomorrow).empty?
        @data = {}        
        tickets = Ticket.where(:project_id => @project)
        tickets.each do |ticket|
          @data[ticket.name] = 
            tm_day_sum(
                       Tweet.user_and_ticket(@user.id, ticket.id).
                       work_time.
                       time_between(@date, @date.tomorrow))
        end
        graph_url = url_for(:controller => :graph, :action => "graph_24",:user => @user.login, :date => @date, :project => @project, :ticket => @t_name)
        # @graph = open_flash_chart_object(500, 500, graph_url, true, "/ttms/")
        @graph = open_flash_chart_object(500, 500, graph_url, "")
        render :day_all
      elsif !Tweet.users(@user.id).today_join_ticket(@date, @date.tomorrow).empty?
        graph_url = url_for(:controller => :graph, :action => "graph_24", :type => @type, :date => @date, :user => @user.login, :project => @project, :ticket => @t_name)
        # @graph = open_flash_chart_object(500, 500, graph_url, true, "/ttms/")
        @graph = open_flash_chart_object(500, 500, graph_url, "")
        @data = day_sagyouzikan @date
        @comment = tm_comment @date
      end
    else
      if @type
        if @type == 'month'
          @data = tm_all_sagyou :month, @date
        elsif @type == 'week'
          @data = tm_all_sagyou :week, @date
        else
          @data = tm_all_sagyou :day, @date
        end
        graph_url = url_for(:controller => :graph, :action => "graph_#{@type}", :type => @type, :date => @date, :user => @user.login)
        # @graph = open_flash_chart_object(500, 500, graph_url, true, "/ttms/")
        @graph = open_flash_chart_object(500, 500, graph_url, "")
        render :time
      else
        @type = 'day'
        @data = tm_all_sagyou :day, @date
        @type = nil
        delete_list = []
        @data.each_with_index do |data, i|
          tmp = data[1][@date]
          next delete_list << i if tmp == 0
          data[1].clear
          data[1][@date] = tmp
        end
        delete_list.sort.reverse.each{|d|@data.delete_at(d)}
        graph_url = url_for(:controller => :graph, :action => "graph_24",:user => @user.login, :date => @date)
        # @graph = open_flash_chart_object(500, 500, graph_url, true, "/ttms/")
        @graph = open_flash_chart_object(500, 500, graph_url, "")
        render :time
      end
    end
  end


end

# -*- coding: utf-8 -*-
require 'rubygems'
require 'mysql2'
require 'active_record'
if RUBY_VERSION < '1.9'
  require 'kconv'
  require 'jcode'
  $KCODE = 'utf8'
end

class String
  def each_char_with_index
    i = 0
    split(//).each do |c|
      yield i, c
      i += 1
    end
  end
end
account = YAML.load_file 'account.yml'
ActiveRecord::Base.establish_connection(account['mysql'])
class CreateCmds < ActiveRecord::Migration
  def self.up
    create_table :cmds do |t|
      t.string :cmd, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :cmds
  end
end

class Tweet < ActiveRecord::Base
  belongs_to :user
  belongs_to :project
  belongs_to :cmd
  belongs_to :ticket
end

class User < ActiveRecord::Base
  has_many :tweets
  has_many :groups
  has_many :projects, :through => :groups
end

class Project < ActiveRecord::Base
  has_many :tweets
  has_many :groups
  has_many :tickets
  has_many :users, :through => :groups
end

class Ticket < ActiveRecord::Base
  belongs_to :project
  has_many :tweets
end

class Cmd < ActiveRecord::Base
  has_many :tweets
end

class Group < ActiveRecord::Base
  belongs_to :user
  belongs_to :project
  scope :project_master, lambda {|x, y|
    joins(:project).
    where(:projects => {:name => y}, :user_id => x, :master => true)
  }
end


class TweetSave
#=*=*=*=*=*=*=*= method 定義 =*=*=*=*=*=*=*=*=*=*=*=*

# プロジェクトが有ればプロジェクトを返す
  def p_check name
    project = Project.where(:name => name)
    return  project.first unless project.empty?
    raise "プロジェクトは存在しません"
  end

  def s_check name
    ticket = Ticket.where(:name => name)
    return ticket.first unless ticket.empty?
    raise "サブプロジェクトは存在しません"
  end

# 権限チェック

  def admin_check user_id, project_id
    group = p_in user_id, project_id
    return true if group.admin
    raise "そのコマンドの実行権限がありません"
  end

  def master_check user_id, project_id
    group = p_in user_id, project_id
    return true if group.master
    raise "そのコマンドの実行権限がありません"
  end

# プロジェクトに所属しているしていれグループを返す
  def p_in user_id, project_id
    group = Group.where(:user_id => user_id, :project_id => project_id)
    return group.first unless group.empty?
    raise "プロジェクトに所属していません"
  end

# 作業報告のコマンドが正しいかどうか
  def tweet_chack tweet, after, time
    raise "ミス" if tweet.time > time
    befor = Cmd.where(:id => tweet.cmd_id).first
    if befor.cmd =~ /^start$/ && after.cmd =~ /^start$|^resume$/
      raise "コマンドエラー 前回のコマンド#{befor.cmd} 今回のコマンド#{after.cmd}"
    end
    if befor.cmd =~ /^finish$/ && after.cmd =~ /^suspend$|^finish$|^resume$/
      raise "コマンドエラー 前回のコマンド#{befor.cmd} 今回のコマンド#{after.cmd}"
    end
    if befor.cmd =~ /^resume$/ && after.cmd =~ /^start$|^resume$/
      raise "コマンドエラー 前回のコマンド#{befor.cmd} 今回のコマンド#{after.cmd}" 
    end
    if befor.cmd =~ /^suspend$/ && after.cmd =~ /^suspend$|^finish$|^start$/
      raise "コマンドエラー 前回のコマンド#{befor.cmd} 今回のコマンド#{after.cmd}"
    end
  end


#*=*=*=*=*=*=*=* コマンドの処理 =*=*=*=*=*=*=*=*=*=*=*=*=*

# コマンド5 new プロジェクトの作成
  def cmd_new user_id, name
    group = Group.project_master user_id, name
    unless group.empty?
      raise "そのプロジェクトは既に存在します"
    end
    project_new user_id, name
    
  end

# コマンド6 s_new サブプロジェクト作成
  def cmd_add user_id, p_name, name
    project =  Group.project_master user_id, p_name
    if project.empty?
      raise "そのプロジェクトは存在しません"
    end
    unless Ticket.where(:name => name).empty?
      raise 'そのサブプロジェクトは既に存在します別の名前で登録してください。'
    end
    project_id = project.first.project_id
    ticket = ticket_new project_id, name
    tmp = Project.find(project_id)
    tmp.attributes = {:updated_at => Time.now}
    tmp.save
    return project_id, ticket.id
=begin
#ruby1.9系だとforce_encoding("UTF-8")をやらないとエンコードerror
#error:ASCII-8BIT and UTF-8
    raise "サブプロジェクトが作成されました。Project[#{project.name.force_encoding("UTF-8")}], SubProject[#{ticket.name.force_encoding("UTF-8")}]に対する作業報告は今後[#{ticket.p_name.force_encoding("UTF-8")}]に対して行ってください。"
=end  
  end

# コマンド7 p_outline プロジェクト概要設定
  def cmd_p_outline user_id, project_name, text
    group = Group.project_master user_id, project_name
    if group.empty?
      raise "プロジェクトは存在しません"
    end
    project = group.first.project
    project.attributes = {:outline => text, :updated_at => Time.now}
    project.save
    project.id
  end

# コマンド8 s_outline サブプロジェクト概要設定
  def cmd_outline user_id, s_name, text
    ticket = s_check s_name
    p_in user_id, ticket.project_id
    ticket.attributes = {:outline => text, :updated_at => Time.now}
    ticket.save
    ticket.id
  end

# コマンド9 ADD プロジェクトメンバーを追加する
  def cmd_join user_id, p_name, user_list
    group = Group.project_master user_id, p_name
    if group.empty?
      raise "プロジェクトは存在しません"
    end
    project = group.first.project
    user_list.each do |add_user|
      id, name = add_user['id'], add_user['name']
      next if name == 'TManagement'
      if User.where(:twitter_id => id).empty?
        user_new id, name
      end
      user = User.where(:twitter_id => id).first
      if Group.where(:project_id => project.id, :user_id => user.id).empty?
        group_new project.id, user.id
      end
    end
    project.attributes = {:updated_at => Time.now}
    project.save
    project.id
  end

# コマンド10 comment コメントを記入する
  def cmd_comment user_id, name
    ticket = s_check name
    p_in user_id, ticket.project_id
    ticket.attributes = {:updated_at => Time.now}
    project = Project.find(ticket.project_id).attributes = {:updated_at => Time.now}
    project.save
    return ticket.id, ticket.project_id
  end

# コマンド11 admin 権限の変更
  def cmd_admin user_id, p_name, user_list
    group = Group.project_master user_id, p_name
    if group.empty?
      raise "プロジェクトが存在しません"
    end
    project = group.first.project
    user_list.each do |user|
      id = User.where(:twitter_id => user['id'])
      next if id.empty? || user['name'] == 'TManagement'
      group = Group.where(:project_id => project.id, :user_id => id.first.id).first
      group.admin = true
      group.save
    end
    project.attributes = {:updated_at => Time.now}
    project.save
    project.id
  end

# コマンド12 rename プロジェクト名変更
  def cmd_rename user_id, name, new_name
    ticket = s_check name
    master_check user_id, ticket.project_id
    unless Ticket.where(:name => new_name).empty?
      raise "そのサブプロジェクト名は既に存在します"
    end
    ticket.attributes = {:name => new_name, :updated_at => Time.now}
    ticket.save
    ticket.id
  end

# コマンド13 help
  def cmd_help name = nil
    cmd = []
    if name
      Cmd.where('cmd like :q', :q => "#{name}%").each{|c| cmd << c.cmd}
    else
      Cmd.all.each{|c| cmd << c.cmd }
    end
    cmd
  end


#*=*=*=*=*=*=*=*=*=*= データベース更新処理 =*=*=*=*=*=*=*=*
  
# 新しいユーザ作成
  def user_new id, name
    user = User.new
    user.twitter_id = id
    user.name = name
    user.save
  end
  
# 新しいプロジェクト作成
  def project_new user_id, name
    project = Project.new
    project.name = name
    project.save
    group_new project.id, user_id, true
    project.id
  end
  
# グループテーブル作成
  def group_new project, user, flg = false
    group = Group.new
    group.user_id = user
    group.project_id = project
    group.master = flg
    group.admin = flg
    group.save
  end

# サブプロジェクト作成
  def ticket_new p_id, name
    mozi = (('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a).join
    mozi << ("-_")
    max = 12
    min = 0
    name.each_char_with_index do |i, char|
      raise "名前が長すぎです。英数字4~12文字での間で入力してください" if i > max
      raise "プロジェクト名は英数字だけ使用できます" unless  mozi[char]
      min = i
    end
    raise "名前が短すぎです。英数字4~12文字の間で入力してください" if min < 3
    ticket = Ticket.new
    ticket.name = name
    ticket.project_id = p_id
    ticket.save
    ticket
  end
##うまく書けばすべてのデータベース更新に応用出来る？
# 投稿データ保存
  def tweet_new data
    tweet = Tweet.new
    data.each do |key, value|
      tweet.instance_eval{@attributes["#{key}"] = value}
    end
    tweet.save
  end

# コマンド登録
  def cmd_new_add
    list = [:start, :suspend, :finish, :resume, :new, :add, :p_outline, :outline, :join, :cmt, :admin, :rename, :help]
    list.each do |l|
      cmd = Cmd.new
      cmd.cmd = l
      cmd.save
    end
  end

#=*=*=*=*=*=*=*=*=* main 処理 =*=*=*=*=*=*=*=*=*=*=*=
# 投稿データのフォーマットをチェック
  def tw_ecision status
    if status['text'] !~ /^\S+\s+(\S*\s*(\S*\s*(.*)))$/
      raise 'フォーマット形式が違います' 
    end
    tmp = [$1, $2, $3]
    text = {
      :cmd => tmp[0].sub!(tmp[1], "").strip, 
      :project => tmp[1].sub!(tmp[2], "").strip,
      :comment => tmp[2].strip}
      text[:cmd] = 'cmt' if text[:cmd] == 'comment'
    raise 'そのコマンドはありません' if Cmd.where(:cmd => text[:cmd]).empty?
# コマンドIDを取得
    cmd = Cmd.where(:cmd => text[:cmd]).first
    twitter_id = status['user']['id']
    name  = text[:project]
    tweet_time = Time.parse status['created_at']

# ユーザIDがあるか調べ、無ければ作成する
    if User.where(:twitter_id => twitter_id).empty?
      user_new twitter_id, status['user']['screen_name']
    end 
    user = User.where(:twitter_id => twitter_id).first
    
    url = "http://twitter.com/#{status['user']['screen_name']}/status/#{status['id']}"
    log = {
      :url => url,
      :user_id => user.id,
      :cmd_id => cmd.id,
      :time => tweet_time,
      :comment => text[:comment]}
# コマンド1~4は作業報告コマンド
    if cmd.id < 5
# サブプロジェクトが存在するかチェック
      if Ticket.where(:name => name).empty?
        raise "そのサブプロジェクトは存在しません"
      end
      ticket = Ticket.where(:name => name).first
      if Project.joins(:tickets, :groups).where(:tickets => {:name => name}, :groups =>{:user_id => user.id}).empty?
        raise "プロジェクトに所属していません"
      end
      befor = Tweet.where(:ticket_id => ticket.id, :user_id => user.id, :cmd_id => 1..4).order('time desc')
      tweet_chack(befor.first, cmd, tweet_time) unless befor.empty?
      project = Project.find(ticket.project_id)
      ticket.attributes = {:updated_at => Time.now}
      ticket.save
      project.attributes = {:updated_at => Time.now}
      project.save
      log[:ticket_id] = ticket.id
      log[:project_id] = project.id
    else
# コマンド5~は作業報告以外のコマンド
      case cmd.id
# 新しいプロジェクト立ち上げ
      when 5
        log[:project_id] = cmd_new user.id, name
# サブプロジェクト立ち上げ
      when 6
        log[:project_id], log[:ticket_id] = cmd_add user.id, name, text[:comment]
# プロジェクトのアウトライン編集
      when 7
        log[:project_id] = cmd_p_outline user.id, name, text[:comment]
# サブプロジェクトのアウトライン編集
      when 8
        log[:ticket_id] = cmd_outline user.id, name, text[:comment]
# プロジェクトにユーザの追加を行う
      when 9
        user_list = status['entities']['user_mentions']
        log[:project_id] = cmd_join user.id, name, user_list
# コメントを投稿する
      when 10
        log[:ticket_id], log[:project_id] = cmd_comment user.id, name
# 権限の変更
      when 11
        user_list = status['entities']['user_mentions']
        log[:project_id] = cmd_admin user.id, name, user_list
# プロジェクト名変更       
      when 12
        log[:ticket_id] = cmd_rename user.id, name, text[:comment]
# help
      when 13
        list = cmd_help name
        raise list.join(', ')
      end
    end
    tweet_new log
    raise "コマンド#{cmd.cmd}の処理完了！！"
  end
end

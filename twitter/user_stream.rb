# -*- coding: utf-8 -*-
require 'rubygems'
require 'net/https'
require 'oauth'
require 'json'
require './tweet'
require 'yaml'
class UserStream
  def start
    tweet = TweetSave.new
    account = YAML.load_file 'account.yml'
    twitter = account['twitter']
    # アクセス用のキーをセット
    sk = twitter['sk']
    ce = twitter['ce']
    at = twitter['at']
    ats = twitter['ats']
    consumer = OAuth::Consumer.new(sk, ce, :site => 'http://twitter.com')
    access_token = OAuth::AccessToken.new(consumer, at, ats)
    uri = URI.parse('https://userstream.twitter.com/2/user.json')
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    https.verify_mode = OpenSSL::SSL::VERIFY_NONE if https.use_ssl?

    #うまく簡潔に書けるようにする。現在はライブラリが無い既存のライブラリはβに対応しているのでhttpsには対応していない。2010/10/22

    https.start do |https|
      request = Net::HTTP::Get.new(uri.request_uri)
      request.oauth!(https, consumer, access_token)
      buf = ""
      https.request(request) do |response|
        response.read_body do |chunk|
          # この処理をしないとうまく読み取れない（あんまりよく分かってない）
          buf << chunk
          # 改行コードで区切って一行ずつ読み込み
          while (line = buf[/.+?(\r\n)+/m]) != nil 
            begin
              buf.sub!(line,"") # 読み込み済みの行を削除
              line.strip!
              status = JSON.parse(line)
              #流れてるデータ確認用
              #pp status
            rescue
              break # parseに失敗したら、次のループでchunkをもう1個読み込む
            end
            #自分宛のリプライを取り出す
            if status['in_reply_to_screen_name'] == 'TManagement'
             begin
               #外部処理に投げる
               tweet.tw_ecision status
             rescue => e
               message = "@#{status['user']['screen_name']} Time:#{Time.now} #{e.message}"
               #access_token.post('/statuses/update.json',
               #                  'status' => message,
               #                  'in_reply_to_status_id' => status['id'])
               open('log.txt', 'a'){|f| f.puts "Time#{Time.now} Message:#{e.message} TweetUser:#{status['user']['screen_name']}"}
               open('tweet_error.txt', 'a'){|f|
                  f.puts Time.now
                  f.puts e.message
                  f.puts e.backtrace
		}
               #p e.message
               #p e.backtrace
               next
             end
            end
          end
        end
      end
    end
  end
end

while true
  begin
    UserStream.new.start
  rescue => e
    open('log_full.txt', 'a'){|f|
      f.puts Time.now
      f.puts e.message
      f.puts e.backtrace
    }
  end
end

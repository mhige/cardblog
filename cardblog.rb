# 読み込み
require 'sinatra'
require 'sinatra/reloader' if development?
require 'mysql2'
require 'mysql2-cs-bind'
require 'pry'

# Mysqlドライバの設定
def db
  db = Mysql2::Client.new(
      host: 'localhost',
      port: 3306,
      username: 'root',
      password: '',
      database: 'cardblog',
      reconnect: true,
  )
end

#カードブログ
class CardBlog < Sinatra::Base
  #reloader
  configure :development do
    register Sinatra::Reloader
  end

# publicフォルダの設定
  set :public_folder, File.dirname(__FILE__) + '/public'

# ルーティング(Routes)
# layout.erbは自動で読み込まれる
# index.erb 読み込み
  get '/' do
    # 新着投稿を10件取得
    @new_posts_data = db.xquery("SELECT * From posts ORDER BY created_at DESC").to_a

    erb :index
  end

#新規投稿ページ（indexにあるので今のところ使わない）
  # get '/post' do
  #   erb :post
  # end

#新規投稿
  post '/' do

    # 画像情報を取得
    @filename = params[:file][:filename]
    file = params[:file][:tempfile]

    # 画像をディレクトリに配置
    File.open("./public/img/#{@filename}", 'wb') do |f|
      f.write(file.read)
    end

    @title = params[:title];
    @body = params[:body];

    db.xquery("INSERT INTO posts(created_at, update_at, title, body, main_image_url)
VALUES(cast(now() as datetime), cast(now() as datetime), '#{@title}', '#{@body}', '#{@filename}')")

    redirect '/'
  end
end

#binding.pry
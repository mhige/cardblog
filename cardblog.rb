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

#ユーザーIDをセット
def set_user
  return nil if session[:user_id].nil?
  @user = db.xquery("SELECT * From users WHERE id = ?", session[:user_id]).to_a.first
end

# ログインしているか否か
def login?
  !session[:user_id].nil?
end

#カードブログのアプリ
class CardBlog < Sinatra::Base
  #reloader
  configure :development do
    register Sinatra::Reloader
  end

  # セッション
  enable :sessions

  # publicフォルダの設定
  set :public_folder, File.dirname(__FILE__) + '/public'

  # トップページ
  get '/' do
    # ログイン確認とユーザーセット
    if login?
      set_user
    end

    #1ページ目
    @page = 1

    # 新着投稿を10件取得
    @new_posts_data = db.xquery("SELECT posts.id, posts.created_at, posts.update_at, user_id, title, body, main_image_url, user_name From posts JOIN users ON posts.user_id = users.id  ORDER BY posts.created_at DESC LIMIT 10").to_a

    erb :index
  end

  # ユーザーページ
  get '/page/?:page_number' do
    # URLに入れたパラメータを渡す
    @page = params[:page_number].to_i

    if !@page.nil?
      # MySQLのオフセットの数
      @offset_num = (@page - 1) * 10

      redirect '/' if @page == 1
      # 該当ページから新着投稿を10件取得
      @new_posts_data = db.xquery("SELECT posts.id, posts.created_at, posts.update_at, user_id, title, body, main_image_url, user_name From posts JOIN users ON posts.user_id = users.id ORDER BY posts.created_at DESC LIMIT 10 OFFSET #{@offset_num}").to_a
    end

    erb :index
  end

  # ユーザーのページ
  get '/:user_name' do
    # URLに入れたパラメータをユーザー名を渡す
    @user_name = params[:user_name]

    # URLに入れたパラメータの
    # user_idがあるか取得してみる
    @user_id = db.xquery("SELECT id From users WHERE user_name = ?", @user_name).to_a.first

    if !@user_id.nil?
      # 新着投稿を10件取得
      @new_posts_data = db.xquery("SELECT * From posts JOIN users ON posts.user_id = users.id WHERE users.id = ? ", @user_id['id']).to_a

      erb :user
    else
      redirect '/'
    end
  end

  #新規投稿
  # （indexにあるので今のところ使わない）
  # get '/post' do
  #   erb :post
  # end

  post '/' do
    #投稿者ID（セッションから取得）
    @user_id = session[:user_id]

    # 記事ID
    if !params[:id].nil?
      @post_id = params[:id]
    else
      @post_id = nil
    end

    # タイトル
    @title = params[:title];

    # 記事本文
    @body = params[:body];

    # 画像
    if params[:file].nil?
      @filename = params[:updatefile]
    else
      @filename = params[:file][:filename]
      file = params[:file][:tempfile]
      # 画像をディレクトリに配置
      File.open("./public/img/#{@filename}", 'w') do |f|
        f.write(file.read)
      end
    end

    # DBに書き込み
    if !params[:id].nil?
      # 編集
      db.xquery("UPDATE posts SET update_at = cast(now() as datetime), title = ?, body = ?, main_image_url = ? WHERE id = ?", @title, @body, @filename, @post_id)
    else
      # 新規投稿
      db.xquery("INSERT INTO posts(created_at, update_at, title, body, main_image_url, user_id) VALUES(cast(now() as datetime), cast(now() as datetime), ?, ?, ?, ?)", @title, @body, @filename, @user_id)
    end

    # トップにリダイレクト
    redirect '/'
  end

  #投稿削除
  post '/delete' do
    #記事のIDを受け取る
    @post_id = params[:post_id]
    # セッションのユーザーIDと記事のIDで
    # 検索して一致すれば DBのrowを削除
    db.xquery("DELETE FROM posts WHERE user_id = ? AND id = ?", session[:user_id], @post_id)

    # トップにリダイレクト
    redirect '/'
  end

  #ユーザー登録ページ
  get '/register' do
    redirect '/' if login?
    erb :register
  end

  #ユーザー登録
  post '/register' do

    # フォームの情報を変数に入れる
    @user_name = params[:user_name]
    @email = params[:email]
    @password = Digest::SHA1.hexdigest(params[:password])

    #DBにユーザーデータを書き込み
    if !@user_name.nil? && !@email.nil? && !@password.nil?
      #ユーザー名がすでに使われていないかチェック
      @used_names = db.xquery("SELECT * FROM users where user_name = ?", @user_name).to_a.first

      if @used_names.nil?
        # DBに書き込みq
        db.xquery("INSERT INTO users(created_at, update_at, user_name, password, email) VALUES(cast(now() as datetime), cast(now() as datetime), ?, ?, ? )", @user_name, @password, @email)

        #ログイン
        @user = db.xquery("SELECT * FROM users where email = ? and password = ?", @email, @password).to_a.first
        session[:user_id] = @user['id']
        set_user
      end
    end

    # トップへリダイレクト
    redirect '/'
  end

  # ログイン
  get '/login' do
    redirect '/' if login?
    erb :login
  end

  post '/login' do
    email = params[:email]
    password = Digest::SHA1.hexdigest(params[:password])

    user = db.xquery("SELECT * FROM users where email = ? and password = ?", email, password).to_a.first

    if user
      session[:user_id] = user['id']
      redirect '/'
    else
      erb :login
    end
  end

  # ログアウト
  get '/logout' do
    session[:user_id] = nil
    redirect '/'
  end


end

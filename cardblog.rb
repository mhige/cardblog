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

# user_idがDBにあるか確認（なかったらトップにリダイレクト）
def user_exist?
  @user_id = db.xquery("SELECT id From users WHERE user_name = ?", params[:user_name]).to_a.first
  !@user_id.nil?
end

# 1ページに表示する記事数
def posts_num_pages
  if !@page.nil?
    # MySQLのリミットの数
    @limit_num = 12
    if @page > 1
      @offset_num = (@page - 1) * @limit_num
    end
  end
end

# 記事を投稿
def post_article
  # 画像ファイル
  if params[:file].nil?
    # 編集でファイル名を変えないとき
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
    db.xquery("
      UPDATE posts
      SET
        update_at = cast(now() as datetime),
        title = ?,
        body = ?,
        main_image_url = ?
      WHERE id = ?
      ",
      params[:title],
      params[:body],
      @filename,
      params[:id]
    )
  else
    # 新規投稿
    db.xquery("
      INSERT INTO posts(
        created_at,
        update_at,
        title,
        body,
        main_image_url,
        user_id
        )
        VALUES(
          cast(now() as datetime),
          cast(now() as datetime),
          ?, ?, ?, ?
          )",
          params[:title],
          params[:body],
          @filename,
          session[:user_id]
        )
  end
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
    @page_path = 'page/'

    # ページタイトル
    @page_title = '新着記事'

    # 記事数設定
    posts_num_pages

    # 新着投稿を10件取得
    @new_posts_data = db.xquery("
      SELECT
        posts.id,
        posts.created_at,
        posts.update_at,
        user_id,
        title,
        body,
        main_image_url,
        user_name
      From posts
      JOIN users
      ON posts.user_id = users.id
      ORDER BY posts.created_at DESC
      LIMIT #{@limit_num}
      ").to_a

    erb :index
  end

  # 2ページ以降
  get '/page/:page_number' do
    # ログイン確認とユーザーセット
    if login?
      set_user
    end

    # ページ番号
    @page = params[:page_number].to_i
    @page_path = 'page/'

    redirect '/' if @page < 2

    # ページタイトル
    @page_title = '新着記事｜' + @page.to_s + 'ページ目'

    if !@page.nil?
      # 記事数設定
      posts_num_pages

      redirect '/' if @page == 1
      # 該当ページから新着投稿を10件取得
      @new_posts_data = db.xquery("
        SELECT
          posts.id,
          posts.created_at,
          posts.update_at,
          user_id,
          title,
          body,
          main_image_url,
          user_name
        From posts
        JOIN users
        ON posts.user_id = users.id
        ORDER BY posts.created_at
        DESC LIMIT #{@limit_num}
        OFFSET #{@offset_num}
        ").to_a
    end

    erb :index
  end

  # ユーザーのページ
  get '/user/:user_name' do
    # ユーザーが存在しない場合はトップへ
    redirect '/' if !user_exist?

    # ログイン確認とユーザーセット
    if login?
      set_user
    end

    # ページ番号
    @page = 1
    @page_path = 'user/' + params[:user_name] + '/'

    # ページタイトル
    @page_title = params[:user_name].to_s + ' さんの記事'

    # 記事数設定
    posts_num_pages

    # 新着投稿を10件取得
    @new_posts_data =
    db.xquery("
      SELECT
        posts.id,
        posts.created_at,
        posts.update_at,
        user_id,
        title,
        body,
        main_image_url,
        user_name
      From posts
      JOIN users
      ON posts.user_id = users.id
      WHERE users.id = ?
      ORDER BY posts.created_at DESC
      LIMIT #{@limit_num}
      ",
      @user_id['id']
    ).to_a

    erb :index
  end

  # ユーザーのページ（ページ有）
  get '/user/:user_name/:page_number' do
    # ユーザーが存在しない場合はトップへ
    redirect '/' if !user_exist?

    # ログイン確認とユーザーセット
    if login?
      set_user
    end

    # ページ番号
    @page = params[:page_number].to_i
    @page_path = 'user/' + params[:user_name] + '/'

    # ページタイトル
    @page_title = params[:user_name].to_s + ' さんの記事'

    # 記事数設定
    posts_num_pages

    # 新着投稿を10件取得
    @new_posts_data =
    db.xquery("
      SELECT
        posts.id,
        posts.created_at,
        posts.update_at,
        user_id,
        title,
        body,
        main_image_url,
        user_name
      From posts
      JOIN users
      ON posts.user_id = users.id
      WHERE users.id = ?
      ORDER BY posts.created_at DESC
      LIMIT #{@limit_num}
      OFFSET #{@offset_num}
      ",
      @user_id['id']
    ).to_a

    # 記事がない場合はユーザーのトップへリダイレクト
    redirect '/user/' + params[:user_name] if @new_posts_data.size < 1

    erb :index
  end

  post '/' do
    # 記事を投稿する
    post_article
    # トップにリダイレクト
    redirect '/'
  end

  post '/user/:user_name' do
    # 記事を投稿する
    post_article
    # 再読み込み
    redirect '/user/' + params[:user_name]
  end

  post '/user/:user_name/:page_number' do
    # 記事を投稿する
    post_article
    # 再読み込み
    redirect '/user/' + params[:user_name] + '/' + params[:page_number]
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

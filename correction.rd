= るびまコード添削: WikiR

（ここに企画の概要を書く）

第1回目は咳さんの書いたコードに対して私（須藤）がコメントします。

http://d.hatena.ne.jp/m_seki/20120213#1329064281

私が咳さんのコードに触れたのはたぶんRWikiです。私は咳さんがほとんどいじらなくなってからRWikiをいじっていた時期がありました。咳さんのコードをいじるのは5年以上ぶりです。

== まず、動かす

単に他の人のコードにコメントするだけであれば、コードを読んで気になるところにコメントするだけでもよいのですが、自分がちゃんと関わる気のあるコードならまずは動かしましょう。

WikiRはdRubyサーバーとdRubyサーバーに接続するCGIで構成されています。これは、咳プロダクツではよくあるパターンです。咳フリークならみんな知っています。

まずはdRubyサーバーを動かします。

  % ruby wikir.rb

次にCGIを動かします。CGIを動かすためにはHTTPサーバーが必要なので、まずはHTTPサーバーを作りましょう。

httpd.rb:
  #!/usr/bin/env ruby

  require "webrick"
  require "webrick/httpservlet/cgihandler"

  server = WEBrick::HTTPServer.new(:Port => 8080)
  cgi_script = File.expand_path("index.rb", File.dirname(__FILE__))
  server.mount("/", WEBrick::HTTPServlet::CGIHandler, cgi_script)
  trap(:INT) do
    server.shutdown
  end
  server.start

HTTPサーバーを動かします。

  % ruby httpd.rb
  [2012-10-09 21:57:22] INFO  WEBrick 1.3.1
  [2012-10-09 21:57:22] INFO  ruby 1.9.3 (2012-04-20) [x86_64-linux]
  [2012-10-09 21:57:22] INFO  WEBrick::HTTPServer#start: pid=14901 port=8080

localhostの8080番ポートでHTTPサーバーが起動しました。それでは、Webブラウザーでアクセスしましょう。

  % curl http://localhost:8080/
  <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0//EN">
  <HTML>
    <HEAD><TITLE>Internal Server Error</TITLE></HEAD>
    <BODY>
      <H1>Internal Server Error</H1>
      Premature end of script headers: /home/kou/work/ruby/rubima-correction-wikir/index.rb
      <HR>
      <ADDRESS>
       WEBrick/1.3.1 (Ruby/1.9.3/2012-04-20) at
       localhost:8080
      </ADDRESS>
    </BODY>
  </HTML>

CGIの実行に失敗しました。うまく行かないときはまずはログを確認します。HTTPサーバーのログを確認すると以下のようになっています。

  [2012-10-09 22:01:25] ERROR CGIHandler: /home/kou/work/ruby/rubima-correction-wikir/index.rb:
  /usr/lib/ruby/1.9.1/webrick/httpservlet/cgi_runner.rb:46:in `exec': No such file or directory - /home/kou/work/ruby/rubima-correction-wikir/index.rb (Errno::ENOENT)
          from /usr/lib/ruby/1.9.1/webrick/httpservlet/cgi_runner.rb:46:in `<main>'
  [2012-10-09 22:01:25] ERROR CGIHandler: /home/kou/work/ruby/rubima-correction-wikir/index.rb exit with 1
  [2012-10-09 22:01:25] ERROR Premature end of script headers: /home/kou/work/ruby/rubima-correction-wikir/index.rb
  localhost - - [09/Oct/2012:22:01:25 JST] "GET / HTTP/1.1" 500 365
  - -> /

ファイルが存在しているのにファイルの実行時に「No such file or directory」とでるときはshebang（ファイルの先頭の(({#!...}))のこと）がおかしいと相場が決まっています。index.rbを見てみましょう。

index.rb:
  #!/usr/local/bin/ruby
  require 'drb/drb'

  DRb.start_service('druby://localhost:0')
  ro = DRbObject.new_with_uri('druby://localhost:50830')
  ro.start(ENV.to_hash, $stdin, $stdout)

== XXX

  * 動かす
  * コードを書く

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

screenshots/cgi-fail.png

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

私の環境ではrubyコマンドは(({/usr/bin/ruby}))なので(({/usr/local/bin/ruby}))から(({/usr/bin/ruby}))に変更します。

  commit f9fdacafc7dbe57a537f09a013193f6fe257b454 (HEAD, master)
  Author: Kouhei Sutou <kou@clear-code.com>
  Date:   Tue Oct 9 22:06:59 2012 +0900

      Adjust shebang

      Ruby command exists at /usr/bin/ruby instead of /usr/local/bin/ruby on
      Debian GNU/Linux.
  ---
   index.rb |    2 +-
   1 file changed, 1 insertion(+), 1 deletion(-)

  diff --git a/index.rb b/index.rb
  index 22d10cd..1b146a6 100755
  --- a/index.rb
  +++ b/index.rb
  @@ -1,4 +1,4 @@
  -#!/usr/local/bin/ruby
  +#!/usr/bin/ruby
   require 'drb/drb'

   DRb.start_service('druby://localhost:0')

ふたたびWebブラウザーでアクセスすると今度はトップページが表示されます。

screenshots/cgi-work.png

これでスタート地点に立てました。それでは、コードを見ていきましょう。

== コードを見る

私がコードを読むときは2つのモードがあります。1つが「なんとなく読む」モードで、もう1つが「必要だから読む」モードです。「なんとなく読む」モードのときは上から順に読んでいって、なんか気になったらコメントしたり直したりたり無視したりします。「必要だから読む」モードのときは、まず必要なところを探して、見つけたらそこだけを集中して読んで他のところには目もくれずに必要なことだけ調べます。

「なんとなく読む」モードはコミットメール((-TODO: コミットメールについて書く。-))を読む時のモードです。「必要だから読む」モードは機能を追加する時やデバッグする時や実装を調べる時のモードです。

今回は機能追加などではなく、気になったことにコメントするために読むので「なんとなく読む」モードです。

WikiRはindex.rbとwikir.rbの2つのファイルで構成されています。まずは、本体であるwikir.rbの方から見ていきましょう。

=== wikir.rb

==== マジックコメント

はじめにファイル内で使うエンコーディングを指定するコメントがあります。

wikir.rb:
  1 # -*- coding: utf-8 -*-

これはマジックコメントと呼ばれています。マジックコメントには以下のようにいくつかの書き方があります。

  # -*- coding: エンコーディング名 -*-
  # -*- encoding: エンコーディング名 -*-
  # coding: エンコーディング名
  # coding = エンコーディング名
  # encoding: エンコーディング名
  # encoding = エンコーディング名
  # ...

たくさんあるとどの書き方がよいか悩むかもしれませんが、wikir.rbと同じ以下の書き方にしましょう((-Vimを使っている人は(({# vim: fileencoding=エンコーディング名}))でもよいです。-))。

  # -*- coding: エンコーディング名 -*-

この形式はRubyだけではなくGNU Emacsも認識できる形式です。GNU Emacsがエンコーディングを認識すると、保存するときに指定したエンコーディングに変換してくれます。そのため、マジックコメントで指定したエンコーディングと実際のエンコーディングが異なることがありません。なお、ruby-modeを使っているとASCII範囲外の文字列があれば自動でマジックコメントが挿入されるので意識せずにマジックコメントを指定していることでしょう。

==== ライブラリ読み込み

次にライブラリを読み込んでいます。

wikir.rb:
  2 require 'kramdown'
  3 require 'webrick'
  4 require 'webrick/cgi'
  5 require 'drb/drb'
  6 require 'erb'
  7 require 'monitor'

特に気になるところはありません。

==== (({WikiR::Book}))

いよいよクラス定義です。

wikir.rb:
   9 class WikiR
  10   class Book
  11     include MonitorMixin
  12     def initialize
  13       super()
  14       @page = {}
  15     end
  16
  17     def [](name)
  18       @page[name] || Page.new(name)
  19     end
  20
  21     def []=(name, src)
  22       synchronize do
  23         page = self[name]
  24         @page[name] = page
  25         page.set_src(src)
  26       end
  27     end
  28   end

まずは(({WikiR::Book}))です。これは複数のページを管理するクラスですね。咳さんはページを管理するクラスには「本」という名前をつけます。RWikiの時もそうでした。

ページを管理するクラスには他にも違う名前が考えられます。例えば「Wiki」という名前です。ページを全部集めたものがWikiだと考えれば適切な名前です。あるいは、「データベース」という名前です。ページが保存されている感じがします。「本」や「Wiki」ではどのように保存するかは気になりませんが、データベースという名前を使うとどのようにページを保存するかを意識している感じがしますね。

咳さんは何かに例えた名前をつけます。作っているものはWikiですが、「ページが集まっているものと言えば本だよね」という連想をして「本」という名前をつけたのでしょう。このように何かに例えた名前をつけると愛着がわき、例えたものベースで説明するようになります。例えば、「ページの数が増えてきて処理に時間がかかるようになったね」というのではなく、「本が厚くなって重くなったね」というような感じです。これには良い面と悪い面がある((-TODO: 説明する？-))のですが、自分が書いたソフトウェアに愛着がわくので一度は試してみるとよいでしょう。

さて、それではコードの中を見てみましょう。

wikir.rb:
  11 include MonitorMixin
  12 def initialize
  13   super()
  14   @page = {}
  15 end

(({MonitorMixin}))を使っています。咳さんが使っているのをよく見ます。

これはマルチスレッド対応なクラスを作る時に便利なモジュールで(({synchronize}))メソッドを提供します。同時に複数のスレッドからアクセスされそうなコードを(({synchronize}))メソッドのブロック内で呼び出すことで競合を防ぐことができます。例えば、以下のコードは(({Counter#up}))を複数のスレッドから同時に呼び出すと正しくカウントアップできません。

thread-unsafe-counter.rb:
  class Counter
    attr_reader :count
    def initialize
      @count = 0
    end

    def up
      count = @count
      sleep 0.00000001
      @count = count + 1
    end
  end

  counter = Counter.new

  threads = []
  100.times do
    threads << Thread.new do
      100.times do
        counter.up
      end
    end
  end
  threads.each(&:join)

  p counter.count # => 10000にならない！

これを(({MonitorMixin}))を使ってマルチスレッドでも正しくカウントアップできるようにすると以下のようになります。

thread-safe-counter-mixin.rb:
  require "monitor"

  class Counter
    include MonitorMixin

    attr_reader :count
    def initialize
      super()
      @count = 0
    end

    def up
      synchronize do
        count = @count
        sleep 0.00000001
        @count = count + 1
      end
    end
  end

  counter = Counter.new

  threads = []
  100.times do
    threads << Thread.new do
      100.times do
        counter.up
      end
    end
  end
  threads.each(&:join)

  p counter.count # => 10000になる！

違いは以下の通りです。

  % diff -u thread-unsafe-counter.rb thread-safe-counter-mixin.rb 
  --- thread-unsafe-counter.rb	2012-10-15 00:04:45.476261676 +0900
  +++ thread-safe-counter-mixin.rb	2012-10-15 00:04:34.440532956 +0900
  @@ -1,13 +1,20 @@
  +require "monitor"
  +
   class Counter
  +  include MonitorMixin
  +
     attr_reader :count
     def initialize
  +    super()
       @count = 0
     end

     def up
  -    count = @count
  -    sleep 0.00000001
  -    @count = count + 1
  +    synchronize do
  +      count = @count
  +      sleep 0.00000001
  +      @count = count + 1
  +    end
     end
   end

(({MonitorMixin}))を(({include}))して、(({initialize}))で(({super()}))して、(({up}))の中の処理を(({synchronize do ... end}))しています。これはdRubyを使ったプログラムでよく見る処理です。

と、(({MonitorMixin}))の説明をしてきましたが、私は(({MonitorMixin}))が好きではありません。(({initialize}))で(({super()}))するのがカッコ悪いなぁと思います。継承したときに(({initialize}))で(({super()}))するのは親クラスも初期化しないからといけないからだろうなぁとは思います。クラスをインスタンス化するときに(({initialize}))が呼ばれるというルールがあるからです。しかし、モジュールは(({initialize}))が呼ばれるというルールはありません。それなのに(({super}))を呼ばなければいけないのがカッコ悪いなぁと思う理由な気がします。

なお、Ruby 2.0では(({Module#prepend}))があるので、以下のようにすればクラス側で明示的に(({super}))を呼ばなくてもすみます。

module-prepend.rb:
  # -*- coding: utf-8 -*-

  module MonitorMixin
    def initialize
      p :monitor_mixin
      super # これは必要。これがないと:bookが出力されない
    end
  end

  class Book
    prepend MonitorMixin
    def initialize
      p :book
    end
  end

  Book.new # => :monitor_mixin
           #    :book

話が逸れましたが、(({super()}))を呼ばなければいけないなら(({@monitor = Monitor.new}))して(({@monitor.synchronize}))とする方が好きです。こっちの方が役割が分離されていてわかりやすいからです。

thread-safe-counter-composite.rb:
  require "monitor"

  class Counter
    attr_reader :count
    def initialize
      @count = 0
      @monitor = Monitor.new
    end

    def up
      @monitor.synchronize do
        count = @count
        sleep 0.00000001
        @count = count + 1
      end
    end
  end

ということで、(({WikiR::Book}))も(({MonitorMixin}))ではなく(({Monitor}))を使うようにします。

  commit 96488c8ee5e0158c3dc67bc280c76f8a60e78ae9 (HEAD, master)
  Author: Kouhei Sutou <kou@clear-code.com>
  Date:   Mon Oct 15 00:24:45 2012 +0900

      Use Monitor instead of MonitorMixin

      Monitor is readable rather than MonitorMixin.
  ---
   wikir.rb |    5 ++---
   1 file changed, 2 insertions(+), 3 deletions(-)

  diff --git a/wikir.rb b/wikir.rb
  index 2c73014..72c5a58 100644
  --- a/wikir.rb
  +++ b/wikir.rb
  @@ -8,9 +8,8 @@ require 'monitor'

   class WikiR
     class Book
  -    include MonitorMixin
       def initialize
  -      super()
  +      @monitor = Monitor.new
         @page = {}
       end

  @@ -19,7 +18,7 @@ class WikiR
       end

       def []=(name, src)
  -      synchronize do
  +      @monitor.synchronize do
           page = self[name]
           @page[name] = page
           page.set_src(src)

TODO: @pageを@pagesにしたい。


=== index.rb

index.rbはたった6行です。咳プロダクツらしいですね。

index.rb:
  #!/usr/bin/ruby
  require 'drb/drb'

  DRb.start_service('druby://localhost:0')
  ro = DRbObject.new_with_uri('druby://localhost:50830')
  ro.start(ENV.to_hash, $stdin, $stdout)

その人のコードを見続けていると、この人はどうしてこんなコードを書いたのか、というのがわかってきます。昔、咳さんのコードを見ていた私からすると「このコードはいろんなプロダクツで使いまわしているコードだろうなぁ」と感じます。

ちゃんと書いた咳さんのコードでは「(({ro}))（たぶん、Remote Objectの略）」という名前を使いません。咳さんなら「(({wikir}))（リモートにあるどのオブジェクトを触るかがわかる名前。後述する通りリモートにあるのは(({WikiR::UI}))だけど、(({ui}))）にはしないはず。リモートのオブジェクトを提供する側は公開用に(({WikiR::UI}))というオブジェクトを用意しているけど、使う側からすればWikiサービスを使いたいだけなので、それがUI用のやつかどうかなんて気にしない。）」や「(({front}))（dRuby本でも使われている伝統的な名前）」といった名前を使うはずです。


== XXX

  * 動かす
  * コードを書く

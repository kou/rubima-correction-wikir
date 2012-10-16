# -*- coding: utf-8 -*-
require 'kramdown'
require 'webrick'
require 'webrick/cgi'
require 'drb/drb'
require 'erb'
require 'monitor'

module WikiR
  class Book
    def initialize
      @monitor = Monitor.new
      @pages = {}
    end

    def [](name)
      @pages[name] || Page.new(name)
    end

    def []=(name, src)
      @monitor.synchronize do
        page = self[name]
        @pages[name] = page
        page.src = src
      end
    end
  end

  class Page
    def initialize(name)
      @name = name
      self.src = "# #{name}\n\nan empty page. edit me."
    end
    attr_reader :name, :src, :html, :warnings

    def src=(text)
      @src = text
      document = Kramdown::Document.new(text)
      @html = document.to_html
      @warnings = document.warnings
    end
  end

  class UI < WEBrick::CGI
    include ERB::Util
    extend ERB::DefMethod
    def_erb_method('to_html(page)', ERB.new(<<EOS))
<html>
<head>
<title>Kramdown</title>
<script language="JavaScript">
function open_edit(){
document.getElementById('edit').style.display = "block";
}
</script>
</head>
<body>
<%= page.html %>
<a href='javascript:open_edit()'>[edit]</a>
<div id='edit' style='display:none;'>
<form method='post'>
<textarea name='text' rows="40" cols="50"><%=h page.src %></textarea>
<input type='submit' name='ok' value='ok'/>
</form>
</div>
</body>
</html>
EOS

    def initialize(book, *args)
      super(*args)
      @book = book
    end

    def do_GET(req, res)
      do_request(req, res)
      build_page(req, res)
    end
    alias :do_POST :do_GET

    def do_request(req, res)
      text ,= req.query['text']
      return if text.nil? || text.empty?
      text = text.force_encoding('utf-8')
      @book[req.path_info] = text
    rescue
    end

    def build_page(req, res)
      res['content-type'] = 'text/html; charset=utf-8'
      res.body = to_html(@book[req.path_info])
    end
  end
end

if __FILE__ == $0
  book = WikiR::Book.new
  ui = WikiR::UI.new(book)
  DRb.start_service('druby://localhost:50830', ui)
  DRb.thread.join
end

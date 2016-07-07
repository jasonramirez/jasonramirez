# Rails + Markdown + Syntax Highlighting

==This post is to help you add syntax highlighting to your markdown in a rails
app.==  I prefer to use [Redcarpet] for markdown processing, and [Rouge] for
syntax highlighting. This is a complete ruby solution, I believe its the
[fastest], and somewhat easy to implement.

### Steps


1. [Add the `redcarpet` gem.](#redcarpet_gem)

1. [Build a `MarkdownParser` class to handle parsing our markdown.](#markdown_parser_class)

1. [Add the `rouge-rails` gem.](#rouge_rails_gem)

1. [Build a `RougeRenderer` class to handle syntax highlighting.](#rouge_renderer_class)

1. [Use the `RougeRenderer` class as the Redcarpet mardown renderer.](#modify_it)

1. [Set up your styleheets.](#stylesheets)

1. [Display the parsed markdown with syntax highlighting in code blocks](#use_it)

<a id="redcarpet_gem"></a>
### Add the redcarpet Gem

```ruby
# Gemfile

gem "redcarpet"
```

<a id="markdown_parser_class"></a>
### MarkdownParser Class

```ruby
# app/models/markdown_parser.rb

class MarkdownParser
  require "redcarpet"

  def initialize(markdown)
    @markdown = markdown
  end

  def markdown_to_html
    processor.render(@markdown).html_safe
  end

  def processor
    Redcarpet::Markdown.new(renderer, extensions = {})
  end

  def renderer
    Redcarpet::Render::HTML
  end
end
```

<a id="rouge_rails_gem"></a>
### Add the rouge-rails Gem

```ruby
# Gemfile

gem "rouge-rails"
```

<a id="rouge_renderer_class"></a>
### RougeRenderer Class

```ruby
# app/models/rouge_renderer.rb

class RougeRenderer < Redcarpet::Render::HTML
  require "rouge"
  require "rouge/plugins/redcarpet"

  include Rouge::Plugins::Redcarpet
end
```

<a id="modify_it"></a>
### Use RougeRenderer As Redcarpet Renderer

```ruby
# app/models/markdown_parser.rb

class MarkdownParser

  ...

  def renderer
    RougeRenderer.new(render_options = {})
  end
end
```

<a id="stylesheets"></a>
### Styelsheets

There are a couple of ways to add the code styles to you rails app. I like to
use the rouge `rougify` CLI command to generate a stylesheet.  The CLI command
should let you generate any theme found in the rouge gem's [themes].

[themes]:https://github.com/jneen/rouge/tree/master/lib/rouge/themes

For example, to generate a github stylesheet:

```bash
$ rougify style github > app/assets/stylesheets/github.css
```

Then add it to your `application.scss` file.

```sass
# app/assets/stylesheets/application.scss

@import "github";
```

You can also copy a stylesheet from [here], but be aware of how the classes are scoped. You will have to set up Rogue to handle themes.

[here]:https://github.com/jacobsimeon/rouge-rails/tree/master/app/assets/stylesheets/rouge

<a id="use_it"></a>
### Use it

Pass the markdown parser a file:

```erb
<%- file = File.read("path/to/file.md") %>
<%= MarkdownParser.new(file).markdown_to_html %>
```

Pass the markdown parser text:

```erb
<%= MarkdownParser.new("#heading ```code {} ```").markdown_to_html %>
```

---

<small>
  Resources:

  [Redcarpet]:https://github.com/vmg/redcarpet
  [Rouge]:https://github.com/jacobsimeon/rouge-rails
  [fastest]:https://www.sitepoint.com/markdown-processing-ruby/

  * https://github.com/vmg/redcarpet
  * https://github.com/jacobsimeon/rouge-rails
  * https://www.sitepoint.com/markdown-processing-ruby/
  * https://github.com/jneen/rouge/issues/140
  * http://rouge.jneen.net/

</small>

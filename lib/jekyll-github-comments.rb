require 'jekyll'
require 'liquid'

module Jekyll
  module GitHubComments
    DEFAULTS = {
      "branch" => "master",
      "comments_template" => "comments.html",
      "comment_template" => "comment.html"
    }

    class Comments < Liquid::Block
      def initialize(tag_name, markup, tokens)
        super
      end

      def parse(tokens)
        super
        @line = tokens[0].line_number
      end

      def render(context)
        if context["subcomments"] then
          context["comments"] = super
        else
          context["subcomments"] = true
          context["comments"] = super
          context["subcomments"] = false
        end

        config = DEFAULTS.merge(context["site"]["github_comments"] || {})

        path = context["page"]["path"]
        line_no = @line + context["page"]["yamlsize"] + 2
        context["comment_url"] = 
          "https://github.com/#{ config["repo"] }/edit/#{ config["branch"] }/#{ path }#L#{ line_no }"
        
        partial = Jekyll::Tags::IncludeTag.parse("include", config["comments_template"], [], @options)

        context.stack do
          partial.render(context)
        end
      end
    end

    class Comment < Liquid::Block
      VALID_SYNTAX = %r!
      ([\w-]+)\s*=\s*
        (?:"([^"\\]*(?:\\.[^"\\]*)*)"|'([^'\\]*(?:\\.[^'\\]*)*)'|([\w\.-]+))
      !x

      def initialize(tag_name, markup, tokens)
        super
        @params = markup
        full_valid_syntax = %r!\A\s*(?:#{VALID_SYNTAX}(?=\s|\z)\s*)*\z!
          unless @params =~ full_valid_syntax
            raise ArgumentError "Invalid syntax for comment tag: #{@params}"
        end
        @tag_name = tag_name
      end

      # Find threaded replies and store them separately to comment content
      def parse(tokens)
        @line = tokens[1].line_number

        @blank = true
        @nodelist ||= []
        @nodelist.clear
        @replylist = []

        while token = tokens.shift
          begin
            unless token.empty?
              case
              when token.start_with?(TAGSTART)
                if token =~ FullToken

                  # if we found the proper block delimiter just end parsing here and let the outer block
                  # proceed
                  return if block_delimiter == $1

                  if tag = Liquid::Template.tags[$1]
                    markup = token.is_a?(Liquid::Token) ? token.child($2) : $2
                    new_tag = tag.parse($1, markup, tokens, @options)
                    new_tag.line_number = token.line_number if token.is_a?(Liquid::Token)
                    if "responses" == $1
                      @replylist << new_tag
                    else
                      @blank &&= new_tag.blank?
                      @nodelist << new_tag
                    end
                  else
                    # this tag is not registered with the system
                    # pass it to the current block for special handling or error reporting
                    unknown_tag($1, $2, tokens)
                  end
                else
                  raise SyntaxError.new(options[:locale].t("errors.syntax.tag_termination".freeze, :token => token, :tag_end => TagEnd.inspect))
                end
              when token.start_with?(VARSTART)
                new_var = create_variable(token)
                new_var.line_number = token.line_number if token.is_a?(Liquid::Token)
                @nodelist << new_var
                @blank = false
              else
                @nodelist << token
                @blank &&= (token =~ /\A\s*\z/)
              end
            end
          rescue SyntaxError => e
            e.set_line_number_from_token(token)
            raise
          end
        end
      end

      def parse_params(context)
        params = {}
        markup = @params

        while (match = VALID_SYNTAX.match(markup))
          markup = markup[match.end(0)..-1]

          value = if match[2]
                    match[2].gsub(%r!\\"!, '"')
                  elsif match[3]
                    match[3].gsub(%r!\\'!, "'")
                  elsif match[4]
                    context[match[4]]
                  end

          params[match[1]] = value
        end
        params
      end

      # Remove leading whitespace to stop markdown treating it as code
      def align_left(string)
        return string if string.strip.size == 0

        relevant_lines = string.split(/\r\n|\r|\n/).select { |line| line.strip.size > 0 }
        indentation_levels = relevant_lines.map do |line|
          match = line.match(/^( +)[^ ]+/)
          match ? match[1].size : 0
        end

        indentation_level = indentation_levels.min
        string.gsub! /^#{' ' * indentation_level}/, '' if indentation_level > 0
        string
      end

      def render(context)
        config = DEFAULTS.merge(context["site"]["github_comments"] || {})

        comment = @params ? parse_params(context) : {}
        comment["content"] = align_left(super)
        comment["replies"] = render_all(@replylist, context) if @replylist.length 

        path = context["page"]["path"]
        line_no = @line + context["page"]["yamlsize"] + 2
        comment["reply_url"] = 
          "https://github.com/#{ config["repo"] }/edit/#{ config["branch"] }/#{ path }#L#{ line_no }"

        partial = Jekyll::Tags::IncludeTag.parse("include", config["comment_template"], [], @options)

        context.stack do
          context["comment"] = comment
          partial.render(context)
        end
      end
    end
  end
end


Jekyll::Hooks.register [:posts, :pages, :documents], :pre_render do |page, payload|
  content = File.read(page.path)
  if content =~ Jekyll::Document::YAML_FRONT_MATTER_REGEXP
    yaml = Regexp.last_match(1)
  end
  payload.page["yamlsize"] = yaml ? yaml.lines.count : 0
end

Liquid::Template.register_tag('responses', Jekyll::GitHubComments::Comments)
Liquid::Template.register_tag('response', Jekyll::GitHubComments::Comment)

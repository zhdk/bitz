require 'cinch'
require 'pry'

class Hello
  include Cinch::Plugin

  match "hello"

  def execute(m)
    m.reply "Hello, #{m.user.nick}"
  end
end


class Urls
  include Cinch::Plugin

  listen_to :channel, :method => :url_responder
  listen_to :private, :method => :url_responder

  def url_responder(m)
    if m.message =~ /!url (.+)/
      process_url(m)
    end
  end

  def process_url(m)
    matches = m.message.match(/!url (.+)/)
    string = matches[1]

    # TODO: Stick all these URLs in a hash, then respond accordingly if the url message matches 
    #       one of the hash keys. Maybe make it a general-purpose info dictionary?
    if m.channel == "#leihs"
      if string == "docs"
        m.reply "The leihs documentation is at http://github.com/zhdk/leihs/wiki"
      elsif string == "blog"
        m.reply "The leihs blog is at http://blog.zhdk.ch/leihs"
      elsif string == "group"
        m.reply "The leihs Google group is at http://groups.google.com/group/leihs"
      else
        m.reply "I don't have the faintest idea where or what '#{string}' could be"
      end
    end

    if m.channel == "#madek"
      if string == "docs"
        m.reply "The Madek documentation is at http://github.com/zhdk/madek/wiki"
      else
        m.reply "I don't have the faintest idea where or what '#{string}' could be"
      end
    end

  end
end

class Help
  include Cinch::Plugin
  listen_to :channel, :method => :help_responder

  def help_responder(m)
    if m.message == "!help"
      m.user.send("Hi there! Try one of the following commands:")
      m.user.send("!url docs    | Shows the URL for the project's documentation")
      m.user.send("!url blog    | Shows the URL for the project's blog")
      m.user.send("!url group   | Shows our Google group's URL")
      m.user.send("!latest      | Checks for the latest available versions of our software")
    end
  end
end

class Release
  include Cinch::Plugin

  listen_to :channel, :method => :release_responder

  def release_responder(m)
    if m.message == "!latest"
      if m.channel == "#leihs"
        latest_30 = `git ls-remote -t http://github.com/zhdk/leihs.git | cut -f 3 -d "/" | grep -v \"\\^\" | sort -V | tail -n 1`.strip
        latest_29 = `git ls-remote -t http://github.com/zhdk/leihs.git | cut -f 3 -d "/" | grep \"^2\.\" | grep -v \"\\^\" | sort -V | tail -n 1`.strip
        if latest_30.empty? or latest_29.empty?
          sorry(m)
        else
          m.reply("The latest version of leihs on GitHub is #{latest_29} for the 2.9 branch and #{latest_30} for the 3.x branch.")
        end
      elsif m.channel == "#madek"
        latest = `git ls-remote -t http://github.com/zhdk/madek.git | cut -f 3 -d "/" | grep -v \"\\^\" | sort -V | tail -n 1`
        latest.strip!
        if latest.empty?
          sorry(m)
        else
          m.reply("The latest version of Madek on GitHub is #{latest}.")
        end
      end
    end
  end

  def sorry(m)
    m.reply("Sorry, the latest release can't be determined at the moment. Please try again later.")
  end
end

class Excuses
  include Cinch::Plugin
  listen_to :message, :method => :excuse_us

  def excuse_us(m)

    # The user asked a question
    if m.message =~ /.*\?$/
      # But there is no one here to answer
      if m.channel.users.count == 3
        m.user.send("Hi there. I am a bot that helps out in #{m.channel}.")
        m.user.send("It seems that you've asked a question there, but there is no human logged on that could help you.")
        m.user.send("Instead of wasting your time waiting for a response, please have another look at our software's documentation instead.")
        m.user.send("You can get the URL by typing '!url docs' (without the quotes) in #{m.channel}.")
        m.user.send("In case you've already read our documentation a million times and are really annoyed that something doesn't work, please accept my apologies, but I am just a little bot and can't really do anything to help you.")
        m.user.send("Feel free to stick around the channel for a while to see if someone who is actually able to help you joins.")
      end

    end
  end

end



bot = Cinch::Bot.new do
  configure do |c|
    c.nick = "bitzbot"
    c.server = "irc.freenode.org"
    c.channels = ["#leihs", "#madek"]
    c.plugins.plugins = [Urls, Release, Help, Excuses]
  end
end

bot.start

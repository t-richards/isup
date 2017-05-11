require "colorize"
require "http"
require "./isup/version"

module Isup
  def self.redirect?(code)
    code == 301 || code == 302
  end

  def self.valid_response_code?(code)
    200 <= code <= 399
  end

  def self.success(uri, response)
    print "  ✔ #{response.status_code} ".colorize(:green).mode(:bold)
    puts uri
  end

  def self.failure(uri, response)
    print "  ✘ #{response.status_code} ".colorize(:red).mode(:bold)
    puts uri
    exit 1
  end

  def self.error(exception)
    print "  ✘ ERROR ".colorize(:red).mode(:bold)
    puts exception.message.colorize.mode(:bold)
    exit 2
  end

  def self.do_request(url)
    uri = URI.parse(url)
    client = HTTP::Client.new(uri)
    client.connect_timeout = 5.seconds
    response = client.get(
      uri.full_path,
      headers: HTTP::Headers{"User-Agent" => "isup v#{Isup::VERSION} (+https://github.com/t-richards/isup)"}
    )
    client.close

    if redirect?(response.status_code)
      success(uri, response)
      return do_request(response.headers["Location"])
    elsif valid_response_code?(response.status_code)
      return success(uri, response)
    end

    failure(uri, response)
  end

  def self.main
    if ARGV.size == 0
      puts "Usage: #{PROGRAM_NAME} <url>"
      exit 3
    end

    do_request(ARGV.first)
  rescue ex : Exception
    error(ex)
  end
end

Isup.main

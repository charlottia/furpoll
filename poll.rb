#!/usr/bin/env ruby

URL = "https://www.furaffinity.net/msg/pms/"
COOKIE = File.read("cookie").chomp

out = `curl -s -H"Cookie: #{COOKIE}" #{URL}`

if out =~ /class="no-sub"/
  system "printf \"furaffinity.login\" | nc -NU ../lilac/lilac.sock"
else
  count = out.scan(/notelinknote-unread/).count
  if count > 0
    system "printf \"furaffinity.#{count}\" | nc -NU ../lilac/lilac.sock"
  end
end


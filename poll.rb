#!/usr/bin/env ruby

URL = "https://www.furaffinity.net/msg/pms/"
COOKIE = File.read("cookie").chomp

out = `curl -s -H"Cookie: #{COOKIE}" #{URL}`

if out =~ /class="no-sub"/
  system "./mail.sh", "Need login again."
else
  count = out.scan(/note-unread/).count
  if count > 0
    system "./mail.sh", "You've got mail!"
  end
end


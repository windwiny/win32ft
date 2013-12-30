#!/usr/bin/env ruby -w
# encoding: GBK

require 'openssl'
require 'win32ft'
W = Win32ft

trap "SIGINT" do
  STDERR.puts "exit on Ctrl-C."
  exit 1
end

def getmd5(fn)
  md5 = OpenSSL::Digest::MD5.new
  File.open(fn, 'rb') do |f|
    while d = f.read(4096)
      md5.update(d)
    end
  end
  md5.hexdigest
end

def rolloldtime(d1, d2)
  fs1 = Dir.chdir(d1) { Dir.glob '*' }
  fs2 = Dir.chdir(d2) { Dir.glob '*' }
  fs = fs1 & fs2
  fs.each do |fn|
    f1 = File.join d1,fn
    f2 = File.join d2,fn
    if File.directory?(f1) && File.directory?(f2)
      rolloldtime(f1, f2)
    elsif File.file?(f1) && File.file?(f2)
      begin
        tc1, ta1, tm1, sz1 = W.getfiletime(f1, getsize: true)
        tc2, ta2, tm2, sz2 = W.getfiletime(f2, getsize: true)
        if sz1 == sz2 && (tc1 != tc2 || tm1 != tm2) && File.readable?(f1) && File.readable?(f2)
          next if sz1 > 2**20 * 200
          md1, md2 = getmd5(f1), getmd5(f2)
          if md1 == md2
            tcx = [tc1, tc2].min
            tax = [ta1, ta2].min
            tmx = [tm1, tm2].min
            if [tcx,tmx] != [tc1,tm1]
              W.setfiletime(f1, tcx, tax, tmx)
              puts " <   #{f1}   CT:#{W.ft2st(W.ft2lft(tcx))}   MT:#{W.ft2st(W.ft2lft(tmx))}"
            end
            if [tcx,tmx] != [tc2,tm2]
              W.setfiletime(f2, tcx, tax, tmx)
              puts "   > #{f2}   CT:#{W.ft2st(W.ft2lft(tcx))}   MT:#{W.ft2st(W.ft2lft(tmx))}"
            end
          end
        end
      rescue Exception => e
        STDERR.puts e
      end
    end
  end
end

def main
  if ARGV.size != 2
    STDERR.puts "Syntax: rolloldtimes.rb  Dir1 Dir2"
    exit 1
  end
  if !File.directory?(ARGV[0]) || !File.directory?(ARGV[1])
    STDERR.puts "Syntax:  Dir1 Dir2  must be directory"
  end
  rolloldtime(ARGV[0], ARGV[1])
end

if __FILE__ == $0
  main
end

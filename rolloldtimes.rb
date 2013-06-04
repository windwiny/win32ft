#!/usr/bin/env ruby -w
# encoding: GBK

require_relative 'win32ft'

trap "SIGINT" do
  STDERR.puts "exit on Ctrl-C."
  exit 1
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
        tc1, ta1, tm1, sz1 = Win32ft.getfiletime(f1, getsize: true)
        tc2, ta2, tm2, sz2 = Win32ft.getfiletime(f2, getsize: true)
        puts "#{f1} #{tc1} #{ta1} #{tm1} #{sz1}"
        puts "#{f2} #{tc2} #{ta2} #{tm2} #{sz2}"
        puts '----'
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

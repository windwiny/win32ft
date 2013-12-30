#!/usr/bin/env ruby -w
# encoding: GBK

require_relative 'win32ft'
require_relative "dirwalk"

G = {
  :autorun => false,
  :stdout => STDOUT,
  :prprog => true,
  :BS => '',
  :WS => '',
  :auto_fn => false,
  }

trap "SIGINT" do
  STDERR.puts "exit on Ctrl-C.  ids: #{$ids}  ifs: #{$ifs}"
  exit 1
end

if !STDOUT.tty? && STDERR.tty?
  G[:prprog] = true
  G[:BS] = "\b" * 78
  G[:WS] = " " * 78
  def tee(txt, both: true)
    puts txt
    STDERR.print txt if both
  end
else
  G[:prprog] = false
  def tee(txt, both: true)
    puts txt
  end
end

def prdi(di)
  $ids, $ifs = 0, 0
  t00 = t0 = Time.now
  Dir.walk('.') do |p, ds, fs|
    p.gsub!('/', "\\")
    $ids += 1
    tc, ta, tm = Win32ft.getfiletime(p)
    puts "#{p}\\ #{tc} #{ta} #{tm} 0"
    if G[:prprog]
      ts = Time.now
      if ts - t0 > 0.3
        STDERR.print "#{G[:BS]} Dir: #{di}  ds: #{$ids}  fs: #{$ifs}  time: #{ts - t00}"
        t0 = ts
      end
    end
    fs.each do |fn|
      fn = File.join(p, fn)
      fn.gsub!('/', "\\")
      $ifs += 1
      tc, ta, tm, sz= Win32ft.getfiletime(fn, getsize: true)
      puts "#{fn} #{tc} #{ta} #{tm} #{sz}"
    end
  end
  if G[:prprog]
    ts = Time.now
    STDERR.puts "#{G[:BS]} Dir: #{di}  ds: #{$ids}  fs: #{$ifs}  time: #{ts - t00}"
  end
end

def main
  if ARGV.include?('-o')
    G[:autofn] = true
    ARGV.delete('-o')
  end
  ARGV.each do |fn|
    fn = File.absolute_path(fn)
    if File.directory? fn
      Dir.chdir(fn) {prdi(fn)}
    end
  end
end

if __FILE__ == $0
  main
end

#!/usr/bin/env ruby -w
# encoding: GBK

require_relative 'win32ft'

G = {:autorun => false, :stdout => STDOUT}

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
  Dir.chdir(di)
  $ids, $ifs = 0, 0
  t00 = t0 = Time.now
  Dir.glob('**/*').each do |fn|
    if File.directory? fn
      $ids += 1
      tc, ta, tm = Win32ft.getfiletime(fn)
      puts "#{fn}/ #{tc} #{ta} #{tm} 0"
    elsif File.file? fn
      $ifs += 1
      tc, ta, tm, sz= Win32ft.getfiletime(fn, getsize: true)
      puts "#{fn} #{tc} #{ta} #{tm} #{sz}"
    end
    if G[:prprog]
      ts = Time.now
      if ts - t0 > 0.3
        STDERR.print "#{G[:BS]} Dir: #{di}  ds: #{$ids}  fs: #{$ifs}  time: #{ts - t00}"
        t0 = ts
      end
    end
  end
  if G[:prprog]
    ts = Time.now
    STDERR.puts "#{G[:BS]} Dir: #{di}  ds: #{$ids}  fs: #{$ifs}  time: #{ts - t00}"
  end
end

def main
  d0 = Dir.pwd
  ARGV.each do |fn|
    fn = File.absolute_path(fn)
    if File.directory? fn
      prdi(fn)
      Dir.chdir(d0)
    end
  end
end

if __FILE__ == $0
  main
end

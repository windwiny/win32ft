# encoding: GBK
#
# Dir::walk , like python os.walk
#

unless Dir.respond_to?(:walk)
  def Dir.walk(top, topdown=true, onerror=nil, followlinks=false, &block)
    # yield 3-tuple, dirpath, dirnames, filenames
    dirs, nondirs = [], []
    Dir.chdir(top) do
      begin
        names = Dir.glob('*', File::FNM_DOTMATCH)
        names.shift(2)  # shift '.' and '..'
      rescue Exception => err
        onerror.call(err) if onerror
        return
      end

      names.each do |name|
        if File.directory?(name)
          dirs << name
        else
          nondirs << name
        end
      end
    end

    if topdown
      block.call(top, dirs, nondirs)
    end

    dirs.each do |name|
      new_path = File.join(top, name)
      if followlinks || !File.symlink?(new_path)
        walk(new_path, topdown, onerror, followlinks, &block)
      end
    end

    if !topdown
      block.call(top, dirs, nondirs)
    end
  end
end

def test
  Dir.chdir ARGV[0]
  Dir.walk('.') do |x,y,z|
    p [x,y,z] 
  end
end

if __FILE__ == $0
  test
end

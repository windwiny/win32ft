# encoding: GBK

require_relative "../win32ft"

describe "FileTime" do
  it "new FileTime instance should ==" do
    FileTime.new.should == FileTime.new
  end
  it "new FileTime instance should equal" do
    FileTime.new.should equal(FileTime.new)
  end
  it "new FileTime instance should eql" do
    FileTime.new.should eql(FileTime.new)
  end
  it "new FileTime instance should eq" do
    FileTime.new.should eq(FileTime.new)
  end
end

describe "SystemTime" do
  it "new SystemTime instance should ==" do
    SystemTime.new.should == SystemTime.new
  end
  it "new SystemTime instance should equal" do
    SystemTime.new.should equal(SystemTime.new)
  end
  it "new SystemTime instance should eql" do
    SystemTime.new.should eql(SystemTime.new)
  end
  it "new SystemTime instance should eq" do
    SystemTime.new.should eq(SystemTime.new)
  end
end

describe "Large_Integer" do
  it "new Large_Integer instance should ==" do
    Large_Integer.new.should == Large_Integer.new
  end
  it "new Large_Integer instance should equal" do
    Large_Integer.new.should equal(Large_Integer.new)
  end
  it "new SystemTime instance should eql" do
    Large_Integer.new.should eql(Large_Integer.new)
  end
  it "new SystemTime instance should eq" do
    Large_Integer.new.should eq(Large_Integer.new)
  end
end

describe "GetLastError" do
  it "get last erro " do
    # FIXME
    #Win32ft.GetFileType -100
    #Win32ft.GetLastError.should == 6
  end
end

describe "FileTime LocalFileTime" do
  it "test swap filetime localfiletime" do
    ft1 = FileTime.new
    ft1[:dwHighDateTime], ft1[:dwLowDateTime] = 0x1CCF838, 0x1F2B7320
    ft2 = Win32ft.ft2lft(ft1)
    ft3 = Win32ft.lft2ft(ft2)
    
    ft1[:dwHighDateTime].should == ft3[:dwHighDateTime]
    ft1[:dwLowDateTime].should == ft3[:dwLowDateTime]
  end
end

describe "FileTime SystemTime" do
  it "test swap filetime systemtime" do
    ft1 = FileTime.new
    ft1[:dwHighDateTime], ft1[:dwLowDateTime] = 0x01CCF838, 0x1F2B7320
    st1 = Win32ft.ft2st(ft1)
    ft3 = Win32ft.st2ft(st1)
    ft1[:dwHighDateTime].should == ft3[:dwHighDateTime]
    ft1[:dwLowDateTime].should == ft3[:dwLowDateTime]
  end
end

describe "GetSystemTime" do
  it "getsystemtime is_a? SystemTime" do
    t1 = Win32ft.getsystemtime
    t1.should satisfy { |st| st.is_a? SystemTime}
  end
  it "getsystemtime [:wYear] == current year" do
    t1 = Win32ft.getsystemtime
    t1[:wYear].should == Time.now.year
  end
end

describe "GetLocalTime" do
  it "getlocaltime is_a? SystemTime" do
    t1 = Win32ft.getlocaltime
    t1.should satisfy { |st| st.is_a? SystemTime}
  end
  it "getlocaltime [:wYear] == current year" do
    t1 = Win32ft.getlocaltime
    t1[:wYear].should == Time.now.year
  end
end

describe "GetLocalTime GetSystemTime" do
  it "diff localtime systemtime" do
    st1 = Win32ft.getsystemtime
    lt1 = Win32ft.getlocaltime
    t1 = Time.utc st1[:wYear], st1[:wMonth], st1[:wDay], st1[:wHour], 
                  st1[:wMinute], st1[:wSecond]
    t2 = Time.local lt1[:wYear], lt1[:wMonth], lt1[:wDay], lt1[:wHour], 
                  lt1[:wMinute], lt1[:wSecond]
    t1.should == t2
  end
end


describe "File Create Read Write Flush Close GetFileSizeEx" do
  before(:all) do
    Dir.mkdir "c:\\tmp" rescue nil
    Dir.chdir "c:\\tmp"
    @fn1 = "c:\\tmp\\f1.txt"
    @msg = Time.now.to_s + " asfas f;asjf;lasdfj;s af;alsj f"
  end
    
  it "CreateFileA WriteFile CloseHandle GetFileSizeEx" do
    hf = Win32ft.CreateFileA(@fn1, CFflag::GENERIC_WRITE,
       CFflag::FILE_SHARE_READ | CFflag::FILE_SHARE_WRITE,
       nil, CFflag::OPEN_ALWAYS, 0, 0)
    hf.should satisfy { |obj| obj.is_a? Fixnum }
       
    wded = FFI::MemoryPointer.new(:uint32, 1)
    buffer = FFI::MemoryPointer.new(:char, @msg.bytesize)
    buffer.write_string @msg
    wfres = Win32ft.WriteFile(hf, buffer, @msg.bytesize, wded, nil)
    wfres.should be(true)
    wded.read_uint32.should == @msg.bytesize
    
    chres = Win32ft.CloseHandle(hf)
    chres.should be(true)
  end
  
  it "ReadFile" do
    buffer = FFI::MemoryPointer.new :char, @msg.bytesize*2
    rded = FFI::MemoryPointer.new :uint32, 1
    hf = Win32ft.CreateFileA(@fn1, CFflag::GENERIC_READ,
       CFflag::FILE_SHARE_READ | CFflag::FILE_SHARE_WRITE,
       nil, CFflag::OPEN_EXISTING, 0, 0)
    hf.should satisfy { |obj| obj.is_a? Fixnum }
    rfres = Win32ft.ReadFile(hf, buffer, @msg.bytesize*2, rded, nil)
    rfres.should be(true)
    rded.read_uint32.should == @msg.bytesize
    buffer.read_string.should == @msg
    Win32ft.CloseHandle(hf)
  end
  
  it "ReadFile no exist file" do
    Dir.mkdir "c:\\tmp" rescue nil
    fn = "c:\\tmp\\noexist.txt"
    hf = Win32ft.CreateFileA(fn, CFflag::GENERIC_READ,
       CFflag::FILE_SHARE_READ | CFflag::FILE_SHARE_WRITE,
       nil, CFflag::OPEN_EXISTING, 0, 0)
    hf.should == -1
  end
  
  it "getfilesize" do
    size = Win32ft.getfilesize(@fn1)
    size.should == @msg.bytesize
  end
end

describe "GetFileTime SetFileTime" do
  before(:all) do
    Dir.mkdir "c:\\tmp" rescue nil
    Dir.chdir "c:\\tmp"
    @fn1 = "c:\\tmp\\f1.txt"
    @msg = Time.now.to_s * 2
  end

  after(:all) do
    Win32ft.DeleteFile(@fn1).should == true
    Dir.chdir "c:\\"
    Dir.rmdir "c:\\tmp"
  end

  it "getfiletime" do
    tc1, ta1, tm1 = Win32ft.getfiletime(@fn1)
    tc1.should_not == FileTime.new
    ta1.should_not == FileTime.new
    tm1.should_not == FileTime.new
  end
  
  it "setfiletime getfiletime getfilesize" do
    require 'tempfile'
    tc1, ta1, tm1 = Win32ft.getfiletime(@fn1)
    fnt = Tempfile.new 'test'
    fnt.print @msg
    fnt.close

    tc2, ta2, tm2 = Win32ft.getfiletime(fnt.path)
    tc2.should_not == tc1
    ta2.should_not == ta1
    tm2.should_not == tm1
    
    res = Win32ft.setfiletime(fnt.path, tc1, ta1, tm1)
    res.should be(true)
    tc3, ta3, tm3, sz = Win32ft.getfiletime(fnt.path, getsize: true)
    tc3.should == tc1
    ta3.should == ta1
    tm3.should == tm1
    sz.to_i.should == @msg.bytesize
  end
  
  it "ft2double double2ft" do
    tc1, ta1, tm1 = Win32ft.getfiletime(@fn1)
    ftc1 = Win32ft.ft2double(tc1)
    fta1 = Win32ft.ft2double(ta1)
    ftm1 = Win32ft.ft2double(tm1)
    tc2 = Win32ft.double2ft(ftc1)
    ta2 = Win32ft.double2ft(fta1)
    tm2 = Win32ft.double2ft(ftm1)
    (tc2[:dwLowDateTime] - tc1[:dwLowDateTime]).should <= 10
    (ta2[:dwLowDateTime] - ta1[:dwLowDateTime]).should <= 10
    (tm2[:dwLowDateTime] - tm1[:dwLowDateTime]).should <= 10
  end
  
  it "copy file time" do
    f1 = Tempfile.new 't1'
    f1.print '111'
    f1.close
    sleep 0.1
    f2 = Tempfile.new 't2'
    f2.print '222222'
    f2.close
    tc1, ta1, tm1, sz1 = Win32ft.getfiletime f1.path, getsize: true
    tc2, ta2, tm2, sz2 = Win32ft.getfiletime f2.path, getsize: true
    tc2.should_not == tc1
    ta2.should_not == ta1
    tm2.should_not == tm1
    sz1.should_not == sz2
    
    tc1, ta1, tm1, sz1 = Win32ft.getfiletime f1.path, getsize: true
    Win32ft.copyfiletime(f1.path, f2.path)
    tc2, ta2, tm2, sz2 = Win32ft.getfiletime f2.path, getsize: true
    tc2.should == tc1
    ta2.should == ta1
    tm2.should == tm1
  end
  it "copy file time on some directory" do
    Dir.mkdir 'a' rescue nil
    t=Time.now.to_f.to_s
    f1 = open("a/a1#{t}", 'wb')
    f1.print '111'
    f1.close
    sleep 0.1
    f2 = open("a/a2#{t}", 'wb')
    f2.print '222222'
    f2.close
    tc1, ta1, tm1, sz1 = Win32ft.getfiletime f1.path, getsize: true
    tc2, ta2, tm2, sz2 = Win32ft.getfiletime f2.path, getsize: true
    tc2.should_not == tc1
    ta2.should_not == ta1
    tm2.should_not == tm1
    sz1.should_not == sz2
    
    tc1, ta1, tm1, sz1 = Win32ft.getfiletime f1.path, getsize: true
    Win32ft.copyfiletime(f1.path, f2.path)
    tc2, ta2, tm2, sz2 = Win32ft.getfiletime f2.path, getsize: true
    tc2.should == tc1
    ta2.should == ta1
    tm2.should == tm1
    Win32ft.DeleteFile(f1.path).should == true
    Win32ft.DeleteFile(f2.path).should == true
    Dir.rmdir 'a' rescue nil
  end
  it "copy file time on diff directory" do
    Dir.mkdir 'a' rescue nil
    Dir.mkdir 'b' rescue nil
    t=Time.now.to_f.to_s
    f1 = open("a/a#{t}", 'wb')
    f1.print '111'
    f1.close
    sleep 0.1
    f2 = open("b/a#{t}", 'wb')
    f2.print '222222'
    f2.close
    tc1, ta1, tm1, sz1 = Win32ft.getfiletime f1.path, getsize: true
    tc2, ta2, tm2, sz2 = Win32ft.getfiletime f2.path, getsize: true
    tc2.should_not == tc1
    ta2.should_not == ta1
    tm2.should_not == tm1
    sz1.should_not == sz2
    
    tc1, ta1, tm1, sz1 = Win32ft.getfiletime f1.path, getsize: true
    Win32ft.copyfiletime(f1.path, f2.path)
    tc2, ta2, tm2, sz2 = Win32ft.getfiletime f2.path, getsize: true
    tc2.should == tc1
    ta2.should == ta1
    tm2.should == tm1
    Win32ft.DeleteFile(f1.path).should == true
    Win32ft.DeleteFile(f2.path).should == true
    Dir.rmdir 'a' rescue nil
    Dir.rmdir 'b' rescue nil
  end
end

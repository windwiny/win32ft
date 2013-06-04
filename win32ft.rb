#!/usr/bin/env ruby -wKU
# encoding: GBK

require "ffi"

class FileTime < FFI::Struct
  layout :dwLowDateTime, FFI::Type::UINT32,
          :dwHighDateTime, FFI::Type::UINT32
  
  def ==(other)
    if other.is_a? self.class
      self[:dwLowDateTime] == other[:dwLowDateTime] && self[:dwHighDateTime] == other[:dwHighDateTime]
    elsif other.is_a? Numeric
      self[:dwHighDateTime] << 32 | self[:dwLowDateTime] == other
    else
      false
    end
  end
  def equal?(other)
    self == other
  end
  def eql?(other)
    self == other
  end
  def to_s
    "0x%08X%08X" % [self[:dwHighDateTime], self[:dwLowDateTime]]
  end
  def to_ii
    ((self[:dwHighDateTime] << 32 | self[:dwLowDateTime]) - 116444736000000000) / 10**7.0
  end
end

class SystemTime < FFI::Struct
  layout :wYear, FFI::Type::USHORT,
          :wMonth, FFI::Type::USHORT,
          :wDayOfWeek, FFI::Type::USHORT,
          :wDay, FFI::Type::USHORT,
          :wHour, FFI::Type::USHORT,
          :wMinute, FFI::Type::USHORT,
          :wSecond, FFI::Type::USHORT,
          :wMilliseconds, FFI::Type::USHORT

  def ==(other)
    if other.is_a? self.class
      self[:wYear] == other[:wYear] &&
      self[:wMonth] == other[:wMonth] &&
      self[:wDay] == other[:wDay] &&
      self[:wHour] == other[:wHour] &&
      self[:wMinute] == other[:wMinute] &&
      self[:wSecond] == other[:wSecond] &&
      self[:wMilliseconds] == other[:wMilliseconds]
    elsif other.is_a? String
      self.to_s == other
    else
      false
    end
  end
  def equal?(other)
    self == other
  end
  def eql?(other)
    self == other
  end
  def to_s
    "%04d-%02d-%02d %02d:%02d:%02d.%d" % [
      self[:wYear],self[:wMonth],self[:wDay],self[:wHour],self[:wMinute],self[:wSecond],self[:wMilliseconds]
    ]
  end
end

class Large_Integer < FFI::Struct
  layout :LowPart, FFI::Type::UINT32,
          :HighPart, FFI::Type::UINT32

  def ==(other)
    if other.is_a? self.class
      self[:HighPart] == other[:HighPart] && self[:LowPart] == other[:LowPart]
    elsif other.is_a? Numeric
      self[:HighPart] << 32 | self[:LowPart] == other
    else
      false
    end
  end
  def equal?(other)
    self == other
  end
  def eql?(other)
    self == other
  end
  def to_i
    self[:HighPart] << 32 | self[:LowPart]
  end
  def to_s
    to_i.to_s
  end
end

class HANDLE < FFI::Struct
  layout :handle, FFI::Type::UINT32
end

class CFflag
  GENERIC_READ      = 0x80000000
  GENERIC_WRITE     = 0x40000000
  GENERIC_EXECUTE   = 0x20000000
  GENERIC_ALL       = 0x10000000

  FILE_SHARE_READ   = 0x00000001
  FILE_SHARE_WRITE  = 0x00000002
  FILE_SHARE_DELETE = 0x00000004

  CREATE_NEW        = 1
  CREATE_ALWAYS     = 2
  OPEN_EXISTING     = 3
  OPEN_ALWAYS       = 4
  TRUNCATE_EXISTING = 5

  FILE_FLAG_WRITE_THROUGH         =0x80000000
  FILE_FLAG_OVERLAPPED            =0x40000000
  FILE_FLAG_NO_BUFFERING          =0x20000000
  FILE_FLAG_RANDOM_ACCESS         =0x10000000
  FILE_FLAG_SEQUENTIAL_SCAN       =0x08000000
  FILE_FLAG_DELETE_ON_CLOSE       =0x04000000
  FILE_FLAG_BACKUP_SEMANTICS      =0x02000000
  FILE_FLAG_POSIX_SEMANTICS       =0x01000000
  FILE_FLAG_OPEN_REPARSE_POINT    =0x00200000
  FILE_FLAG_OPEN_NO_RECALL        =0x00100000
  FILE_FLAG_FIRST_PIPE_INSTANCE   =0x00080000
end

module Win32ft
  extend FFI::Library
  ffi_lib 'msvcrt', 'kernel32'
  ffi_convention :stdcall
  
  attach_function :GetFileType, [:int], :int
  attach_function :GetLastError, [], :int
  attach_function :FormatMessageA, [:int, :pointer, :int, :int, :string, :int, :pointer], :int
  
  attach_function :FileTimeToLocalFileTime, [FileTime.by_ref, FileTime.by_ref], :bool
  attach_function :LocalFileTimeToFileTime, [FileTime.by_ref, FileTime.by_ref], :bool
  def self.ft2lft(ft)
    lft = FileTime.new
    FileTimeToLocalFileTime(ft, lft)
    lft
  end
  def self.lft2ft(lft)
    ft = FileTime.new
    LocalFileTimeToFileTime(lft, ft)
    ft
  end
  
  attach_function :FileTimeToSystemTime, [FileTime.by_ref, SystemTime.by_ref], :bool
  attach_function :SystemTimeToFileTime, [SystemTime.by_ref, FileTime.by_ref], :bool
  def self.ft2st(ft, convft2lft: false)
    ft = ft2lft(ft) if convft2lft
    st = SystemTime.new
    FileTimeToSystemTime(ft, st)
    st
  end
  def self.st2ft(st, convlft2ft: false)
    ft = FileTime.new
    SystemTimeToFileTime(st, ft)
    ft = lft2ft(ft) if convlft2ft
    ft
  end
  
  attach_function :GetSystemTime, [SystemTime.by_ref], :void
  def self.getsystemtime
    st = SystemTime.new
    GetSystemTime(st)
    st
  end
  attach_function :GetLocalTime, [SystemTime.by_ref], :void
  def self.getlocaltime
    lt = SystemTime.new
    GetLocalTime(lt)
    lt
  end
  
=begin
CreateFileA("", CF.GENERIC_READ,  CF.FILE_SHARE_READ | CF.FILE_SHARE_WRITE, 0, CF.OPEN_EXISTING, CF.FILE_FLAG_BACKUP_SEMANTICS, 0)
CreateFileA("", CF.GENERIC_WRITE, CF.FILE_SHARE_READ | CF.FILE_SHARE_WRITE, 0, CF.OPEN_EXISTING, CF.FILE_FLAG_BACKUP_SEMANTICS, 0)

   LPCSTR  lpFileName,             # "filename"
   DWORD   dwDesiredAccess,        # GENERIC_READ / GENERIC_WRITE / GENERIC_EXECUTE / GENERIC_ALL
   DWORD   dwShareMode,            # FILE_SHARE_READ /| FILE_SHARE_WRITE / FILE_SHARE_DELETE
   LPSECURITY_ATTRIBUTES   lp,     # 0
   DWORD   dwCreationDisposition,  # CREATE_NEW / CREATE_ALWAYS / OPEN_EXISTING / OPEN_ALWAYS / TRUNCATE_EXISTING
   DWORD   dwFlagsAndAttributes,   # 0 | CF.FILE_FLAG_BACKUP_SEMANTICS if dir
   HANDLE  hTemplateFile           # 0
       
ReadFile(
    HANDLE,
    ctypes.byref(sts),  # ctypes.create_string_buffer('',size=100).  chars
    100,    # chars len
    ctypes.byref(rd),   # ctypes.wintypes.DWORD(). # [output] read chars len
    0)

WriteFile(
    HANDLE,
    ctypes.byref(sts),  # ctypes.create_string_buffer('abcde',size=100).  chars
    5,    # chars len
    ctypes.byref(wd),   # ctypes.wintypes.DWORD(). # [output] write chars len
    0)

FlushFileBuffers(HANDLE)

CloseHandle(HANDLE)
=end
  attach_function  :CreateFileA,  [FFI::Type::STRING, FFI::Type::UINT32,
       FFI::Type::UINT32, :pointer, FFI::Type::UINT32,
       FFI::Type::UINT32, FFI::Type::UINT32], FFI::Type::INT32
  attach_function :ReadFile, [FFI::Type::INT32, :pointer, :uint32, :pointer, :pointer], :bool
  attach_function :WriteFile, [FFI::Type::INT32, :pointer, :uint32, :pointer, :pointer], :bool
  attach_function :FlushFileBuffers, [FFI::Type::INT32], :bool
  attach_function :CloseHandle, [FFI::Type::INT32], :bool
  
  attach_function :GetFileTime, [FFI::Type::INT32, FileTime.by_ref, FileTime.by_ref, FileTime.by_ref], :bool
  attach_function :SetFileTime, [FFI::Type::INT32, FileTime.by_ref, FileTime.by_ref, FileTime.by_ref], :bool
  def self.getfiletime(fn, getsize: false)
    tc, ta, tm = FileTime.new, FileTime.new, FileTime.new
    if getsize
      size = Large_Integer.new
      ttts = [tc, ta, tm, size]
    else
      ttts = [tc, ta, tm]
    end
    hf = CreateFileA(fn, CFflag::GENERIC_READ, CFflag::FILE_SHARE_READ | CFflag::FILE_SHARE_WRITE,
        nil, CFflag::OPEN_EXISTING, CFflag::FILE_FLAG_BACKUP_SEMANTICS, 0)
    if hf == -1
      STDERR.puts "getfiletime: Can not open file \"#{fn}\""
      return ttts
    end
    res = GetFileTime(hf, tc, ta, tm)
    if !res
      STDERR.puts "getfiletime: GetFileTime error."
      return ttts
    end
    if getsize
      res = GetFileSizeEx(hf, size)
      if !res
        STDERR.puts "getfiletime: GetFileSizeEx error."
        return ttts
      end
    end
    CloseHandle(hf)
    ttts
  end
  def self.setfiletime(fn, tc, ta, tm)
    hf = CreateFileA(fn, CFflag::GENERIC_WRITE, CFflag::FILE_SHARE_READ | CFflag::FILE_SHARE_WRITE,
        nil, CFflag::OPEN_EXISTING, CFflag::FILE_FLAG_BACKUP_SEMANTICS, 0)
    if hf == -1
      STDERR.puts "setfiletime: Can not open file \"#{fn}\""
      return false
    end
    res = SetFileTime(hf, tc, ta, tm)
    if !res
      STDERR.puts "setfiletime: SetFileTime error."
      return false
    end
    CloseHandle(hf)
    true
  end
  def self.double2ft(tt)
    wintt = (tt * 10**7 + 116444736000000000).to_i
    ft = FileTime.new
    ft[:dwHighDateTime] = wintt >> 32 & 0xFFFFFFFF
    ft[:dwLowDateTime] = wintt & 0xFFFFFFFF
    ft
  end
  def self.ft2double(ft)
    wintt = ft[:dwHighDateTime] << 32 | ft[:dwLowDateTime]
    tt = (wintt - 116444736000000000) / 10**7.0
    tt
  end
  
  attach_function :GetFileSizeEx, [FFI::Type::INT32, Large_Integer.by_ref], :bool
  def self.getfilesize(fn)
    hf = CreateFileA(fn, CFflag::GENERIC_READ, CFflag::FILE_SHARE_READ | CFflag::FILE_SHARE_WRITE,
        nil, CFflag::OPEN_EXISTING, CFflag::FILE_FLAG_BACKUP_SEMANTICS, 0)
    if hf == -1
      STDERR.puts "getfilesize: Can not open file \"#{fn}\""
      return false
    end
    size = Large_Integer.new
    res = GetFileSizeEx(hf, size)
    if !res
      STDERR.puts "getfilesize: GetFileSizeEx error."
      return false
    end
    CloseHandle(hf)
    size.to_i
  end
end

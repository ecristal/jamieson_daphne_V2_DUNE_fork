import hashlib
from base64 import standard_b64encode, standard_b64decode
import os
from math import ceil

class binfile(object):
  def __init__(self, binfilename,include_pagenumber=True,page_offset=0,include_command=True,command_string='wb64',header=True):
    self.filename = binfilename
    self.file = open(self.filename, 'rb')
    self.size = self.file.seek(0,os.SEEK_END)
    self.file.seek(0)
    self.current_page = 0
    self.pages = ceil(self.size/256)
    self.include_pagenumber = include_pagenumber
    self.include_command = include_command
    self.command_string = command_string
    self.page_offset = page_offset
    self.header = bool(header)

  def __enter__(self):
    return self

  def __exit__(self, *args):
    self.file.close()

  def __iter__(self):
    return self

  def __next__(self):
    return self.next()
  
  def __len__(self):
    return self.pages + int(self.header)

  def more(self):
    return (self.current_page+1) < self.pages + self.page_offset + int(self.header)

  def next(self):
    page = self.file.tell()//256 + self.page_offset + int(self.header)
    self.current_page = page
    pagedata = self.file.read(256)
    if pagedata == b'':
      raise StopIteration()
    if len(pagedata)<256:
      pagedata += (256-len(pagedata))*b'\x00'
    pagestring = f'{page:#08x}'
    datastring = standard_b64encode(pagedata).decode()
    return f'{self.command_string+" " if self.include_command else ""}{pagestring+" " if self.include_pagenumber else ""}{datastring}'
 
  def page(self,pageno):
    if self.header:
      if pageno == self.page_offset:
        return self.HeaderWriteCmd()
      else:
        pageno = pageno-(self.page_offset + int(self.header))
    if pageno<self.pages:
      self.file.seek(pageno*256)
      return self.next()
    else:
      raise EOFError
 
  def reset(self):
    self.file.seek(0)
    self.current_page = 0

  def getHash(self):
    startpos = self.file.tell()
    m = hashlib.sha256()
    self.file.seek(0)
    while True:
      pagedata = self.file.read(256)
      if pagedata == b'':
        break
      if len(pagedata)<256:
        pagedata += (256-len(pagedata))*b'\0'
      m.update(pagedata)
    self.file.seek(startpos)
    return m.digest()  # 32 bytes

  def getMagic(self):
    return (0xDAFF9E2A).to_bytes(4,'big')

  def getGitSha(self):
    basename = os.path.basename(self.filename)
    noext = os.path.splitext(basename)[0]
    gitsha = int(noext.split('_')[1],16)
    return gitsha.to_bytes(4,'big')

  def getPageRange(self):
    firstPage = self.page_offset + int(self.header)
    lastPage = self.page_offset + self.pages # this is the last page, and the header is at 0, so this is correct.
    return firstPage.to_bytes(4,'big')+lastPage.to_bytes(4,'big')
  
  def getValidMarker(self):
    return (0x0000FFFF).to_bytes(4,'big')*4

  def getHeader(self):
    header = b''
    header += self.getMagic() + self.getGitSha()
    header += self.getPageRange()
    header += self.getValidMarker()
    header += self.getHash()
    header += b'\xff'* (256-len(header))
    return header

  def PrintHex(self,value):
    out = ""
    length = 0
    for b in value:
      out += "{0:02x}".format(b)
      length += 1
      if length%2 == 0:
        out += ' '
      if length%16 == 0:
        out += '\n'
    return out
  
  def HeaderWriteCmd(self):
    pagestring = f'{self.page_offset:#08x}'
    pagedata = self.getHeader()
    datastring = standard_b64encode(pagedata).decode()
    return f'{self.command_string+" " if self.include_command else ""}{pagestring+" " if self.include_pagenumber else ""}{datastring}'

  def InvalidateHeaderWriteCmd(self,page): # writing ff doesn't change data, 00 clears it.
    pagestring = f'{self.page:#08x}'
    pagedata = self.invalidHeader
    datastring = standard_b64encode(pagedata).decode()
    return f'{self.command_string+" " if self.include_command else ""}{pagestring+" " if self.include_pagenumber else ""}{datastring}'

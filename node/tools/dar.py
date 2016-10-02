# Copyright 2016 The Bazel Authors, @pcj. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# In order to have a self-contained script with no import
# dependencies, this file is a merger of the following two files, with
# the gflags dependency removed and replaced with standard argparse
# library.
#
# https://github.com/bazelbuild/bazel/blob/master/tools/build_defs/pkg/archive.py
# https://github.com/bazelbuild/bazel/blob/master/tools/build_defs/pkg/build_tar.py
#
"""Deterministic archive manipulation library."""

import argparse
import os
import os.path
import subprocess
import sys
import tarfile
import tempfile

from StringIO import StringIO


class SimpleArFile(object):
  """A simple AR file reader.

  This enable to read AR file (System V variant) as described
  in https://en.wikipedia.org/wiki/Ar_(Unix).

  The standard usage of this class is:

  with SimpleArFile(filename) as ar:
    nextFile = ar.next()
    while nextFile:
      print nextFile.filename
      nextFile = ar.next()

  Upon error, this class will raise a ArError exception.
  """

  # TODO(dmarting): We should use a standard library instead but python 2.7
  #   does not have AR reading library.

  class ArError(Exception):
    pass

  class SimpleArFileEntry(object):
    """Represent one entry in a AR archive.

    Attributes:
      filename: the filename of the entry, as described in the archive.
      timestamp: the timestamp of the file entry.
      owner_id, group_id: numeric id of the user and group owning the file.
      mode: unix permission mode of the file
      size: size of the file
      data: the content of the file.
    """

    def __init__(self, f):
      self.filename = f.read(16).strip()
      if self.filename.endswith('/'):  # SysV variant
        self.filename = self.filename[:-1]
      self.timestamp = int(f.read(12).strip())
      self.owner_id = int(f.read(6).strip())
      self.group_id = int(f.read(6).strip())
      self.mode = int(f.read(8).strip(), 8)
      self.size = int(f.read(10).strip())
      pad = f.read(2)
      if pad != '\x60\x0a':
        raise SimpleArFile.ArError('Invalid AR file header')
      self.data = f.read(self.size)

  MAGIC_STRING = '!<arch>\n'

  def __init__(self, filename):
    self.filename = filename

  def __enter__(self):
    self.f = open(self.filename, 'rb')
    if self.f.read(len(self.MAGIC_STRING)) != self.MAGIC_STRING:
      raise self.ArError('Not a ar file: ' + self.filename)
    return self

  def __exit__(self, t, v, traceback):
    self.f.close()

  def next(self):
    """Read the next file. Returns None when reaching the end of file."""
    # AR sections are two bit aligned using new lines.
    if self.f.tell() % 2 != 0:
      self.f.read(1)
    # An AR sections is at least 60 bytes. Some file might contains garbage
    # bytes at the end of the archive, ignore them.
    if self.f.tell() > os.fstat(self.f.fileno()).st_size - 60:
      return None
    return self.SimpleArFileEntry(self.f)


class TarFileWriter(object):
  """A wrapper to write tar files."""

  class Error(Exception):
    pass

  def __init__(self, name, compression=''):
    print("tarfile name %s" % name)
    if compression in ['tgz', 'gz']:
      mode = 'w:gz'
    elif compression in ['bzip2', 'bz2']:
      mode = 'w:bz2'
    else:
      mode = 'w:'
    print("tarfile mode %s" % mode)
    # Support xz compression through xz... until we can use Py3
    self.xz = compression in ['xz', 'lzma']
    self.name = name
    self.tar = tarfile.open(name=name, mode=mode)
    #self.tar = tarfile.open(name="foo", mode='w:')
    self.members = set([])
    self.directories = set([])

  def __enter__(self):
    return self

  def __exit__(self, t, v, traceback):
    self.close()

  def add_dir(self,
              name,
              path,
              uid=0,
              gid=0,
              uname='',
              gname='',
              mtime=0,
              mode=None,
              depth=100):
    """Recursively add a directory.

    Args:
      name: the destination path of the directory to add.
      path: the path of the directory to add.
      uid: owner user identifier.
      gid: owner group identifier.
      uname: owner user names.
      gname: owner group names.
      mtime: modification time to put in the archive.
      mode: unix permission mode of the file, default 0644 (0755).
      depth: maximum depth to recurse in to avoid infinite loops
             with cyclic mounts.

    Raises:
      TarFileWriter.Error: when the recursion depth has exceeded the
                           `depth` argument.
    """
    if not (name == '.' or name.startswith('/') or name.startswith('./')):
      name = './' + name
    if os.path.isdir(path):
      # Remove trailing '/' (index -1 => last character)
      if name[-1] == '/':
        name = name[:-1]
      # Add the x bit to directories to prevent non-traversable directories.
      # The x bit is set only to if the read bit is set.
      dirmode = (mode | ((0o444 & mode) >> 2)) if mode else mode
      self.add_file(name + '/',
                    tarfile.DIRTYPE,
                    uid=uid,
                    gid=gid,
                    uname=uname,
                    gname=gname,
                    mtime=mtime,
                    mode=dirmode)
      if depth <= 0:
        raise self.Error('Recursion depth exceeded, probably in '
                         'an infinite directory loop.')
      # Iterate over the sorted list of file so we get a deterministic result.
      filelist = os.listdir(path)
      filelist.sort()
      for f in filelist:
        new_name = os.path.join(name, f)
        new_path = os.path.join(path, f)
        self.add_dir(new_name, new_path, uid, gid, uname, gname, mtime, mode,
                     depth - 1)
    else:
      self.add_file(name,
                    tarfile.REGTYPE,
                    file_content=path,
                    uid=uid,
                    gid=gid,
                    uname=uname,
                    gname=gname,
                    mtime=mtime,
                    mode=mode)

  def _addfile(self, info, fileobj=None):
    """Add a file in the tar file if there is no conflict."""
    if not info.name.endswith('/') and info.type == tarfile.DIRTYPE:
      # Enforce the ending / for directories so we correctly deduplicate.
      info.name += '/'
    if info.name not in self.members:
      self.tar.addfile(info, fileobj)
      self.members.add(info.name)
    elif info.type != tarfile.DIRTYPE:
      print('Duplicate file in archive: %s, '
            'picking first occurrence' % info.name)

  def add_file(self,
               name,
               kind=tarfile.REGTYPE,
               content=None,
               link=None,
               file_content=None,
               uid=0,
               gid=0,
               uname='',
               gname='',
               mtime=0,
               mode=None):
    """Add a file to the current tar.

    Args:
      name: the name of the file to add.
      kind: the type of the file to add, see tarfile.*TYPE.
      content: a textual content to put in the file.
      link: if the file is a link, the destination of the link.
      file_content: file to read the content from. Provide either this
          one or `content` to specifies a content for the file.
      uid: owner user identifier.
      gid: owner group identifier.
      uname: owner user names.
      gname: owner group names.
      mtime: modification time to put in the archive.
      mode: unix permission mode of the file, default 0644 (0755).
    """
    if file_content and os.path.isdir(file_content):
      # Recurse into directory
      self.add_dir(name, file_content, uid, gid, uname, gname, mtime, mode)
      return
    if not (name == '.' or name.startswith('/') or name.startswith('./')):
      name = './' + name
    if kind == tarfile.DIRTYPE:
      name = name.rstrip('/')
      if name in self.directories:
        return

    components = name.rsplit('/', 1)
    if len(components) > 1:
      d = components[0]
      self.add_file(d,
                    tarfile.DIRTYPE,
                    uid=uid,
                    gid=gid,
                    uname=uname,
                    gname=gname,
                    mtime=mtime,
                    mode=0o755)
    tarinfo = tarfile.TarInfo(name)
    tarinfo.mtime = mtime
    tarinfo.uid = uid
    tarinfo.gid = gid
    tarinfo.uname = uname
    tarinfo.gname = gname
    tarinfo.type = kind
    if mode is None:
      tarinfo.mode = 0o644 if kind == tarfile.REGTYPE else 0o755
    else:
      tarinfo.mode = mode
    if link:
      tarinfo.linkname = link
    if content:
      tarinfo.size = len(content)
      self._addfile(tarinfo, StringIO(content))
    elif file_content:
      with open(file_content, 'rb') as f:
        tarinfo.size = os.fstat(f.fileno()).st_size
        self._addfile(tarinfo, f)
    else:
      if kind == tarfile.DIRTYPE:
        self.directories.add(name)
      self._addfile(tarinfo)

  def add_tar(self,
              tar,
              rootuid=None,
              rootgid=None,
              numeric=False,
              name_filter=None,
              root=None):
    """Merge a tar content into the current tar, stripping timestamp.

    Args:
      tar: the name of tar to extract and put content into the current tar.
      rootuid: user id that we will pretend is root (replaced by uid 0).
      rootgid: group id that we will pretend is root (replaced by gid 0).
      numeric: set to true to strip out name of owners (and just use the
          numeric values).
      name_filter: filter out file by names. If not none, this method will be
          called for each file to add, given the name and should return true if
          the file is to be added to the final tar and false otherwise.
      root: place all non-absolute content under given root direcory, if not
          None.

    Raises:
      TarFileWriter.Error: if an error happens when uncompressing the tar file.
    """
    if root and root[0] not in ['/', '.']:
      # Root prefix should start with a '/', adds it if missing
      root = '/' + root
    compression = os.path.splitext(tar)[-1][1:]
    if compression == 'tgz':
      compression = 'gz'
    elif compression == 'bzip2':
      compression = 'bz2'
    elif compression == 'lzma':
      compression = 'xz'
    elif compression not in ['gz', 'bz2', 'xz']:
      compression = ''
    if compression == 'xz':
      # Python 2 does not support lzma, our py3 support is terrible so let's
      # just hack around.
      # Note that we buffer the file in memory and it can have an important
      # memory footprint but it's probably fine as we don't use them for really
      # large files.
      # TODO(dmarting): once our py3 support gets better, compile this tools
      # with py3 for proper lzma support.
      if subprocess.call('which xzcat', shell=True, stdout=subprocess.PIPE):
        raise self.Error('Cannot handle .xz and .lzma compression: '
                         'xzcat not found.')
      p = subprocess.Popen('cat %s | xzcat' % tar,
                           shell=True,
                           stdout=subprocess.PIPE)
      f = StringIO(p.stdout.read())
      p.wait()
      intar = tarfile.open(fileobj=f, mode='r:')
    else:
      intar = tarfile.open(name=tar, mode='r:' + compression)
    for tarinfo in intar:
      if name_filter is None or name_filter(tarinfo.name):
        tarinfo.mtime = 0
        if rootuid is not None and tarinfo.uid == rootuid:
          tarinfo.uid = 0
          tarinfo.uname = 'root'
        if rootgid is not None and tarinfo.gid == rootgid:
          tarinfo.gid = 0
          tarinfo.gname = 'root'
        if numeric:
          tarinfo.uname = ''
          tarinfo.gname = ''

        name = tarinfo.name
        if not name.startswith('/') and not name.startswith('.'):
          name = './' + name
        if root is not None:
          if name.startswith('.'):
            name = '.' + root + name.lstrip('.')
            # Add root dir with same permissions if missing. Note that
            # add_file deduplicates directories and is safe to call here.
            self.add_file('.' + root,
                          tarfile.DIRTYPE,
                          uid=tarinfo.uid,
                          gid=tarinfo.gid,
                          uname=tarinfo.uname,
                          gname=tarinfo.gname,
                          mtime=tarinfo.mtime,
                          mode=0o755)
          # Relocate internal hardlinks as well to avoid breaking them.
          link = tarinfo.linkname
          if link.startswith('.') and tarinfo.type == tarfile.LNKTYPE:
            tarinfo.linkname = '.' + root + link.lstrip('.')
        tarinfo.name = name

        if tarinfo.isfile():
          self._addfile(tarinfo, intar.extractfile(tarinfo.name))
        else:
          self._addfile(tarinfo)
    intar.close()

  def close(self):
    """Close the output tar file.

    This class should not be used anymore after calling that method.

    Raises:
      TarFileWriter.Error: if an error happens when compressing the output file.
    """
    self.tar.close()
    if self.xz:
      # Support xz compression through xz... until we can use Py3
      if subprocess.call('which xz', shell=True, stdout=subprocess.PIPE):
        raise self.Error('Cannot handle .xz and .lzma compression: '
                         'xz not found.')
      subprocess.call(
          'mv {0} {0}.d && xz -z {0}.d && mv {0}.d.xz {0}'.format(self.name),
          shell=True,
          stdout=subprocess.PIPE)


class TarFile(object):
  """A class to generates a Docker layer."""

  class DebError(Exception):
    pass

  def __init__(self, output, directory, compression):
    self.directory = directory
    self.output = output
    self.compression = compression

  def __enter__(self):
    self.tarfile = TarFileWriter(self.output, self.compression)
    return self

  def __exit__(self, t, v, traceback):
    self.tarfile.close()

  def add_file(self, f, destfile, mode=None):
    """Add a file to the tar file.

    Args:
       f: the file to add to the layer
       destfile: the name of the file in the layer
       mode: force to set the specified mode, by
          default the value from the source is taken.
    `f` will be copied to `self.directory/destfile` in the layer.
    """
    dest = destfile.lstrip('/')  # Remove leading slashes
    if self.directory and self.directory != '/':
      dest = self.directory.lstrip('/') + '/' + dest
    # If mode is unspecified, derive the mode from the file's mode.
    if mode is None:
      mode = 0o755 if os.access(f, os.X_OK) else 0o644
    self.tarfile.add_file(dest, file_content=f, mode=mode)

  def add_tar(self, tar):
    """Merge a tar file into the destination tar file.

    All files presents in that tar will be added to the output file
    under self.directory/path. No user name nor group name will be
    added to the output.

    Args:
      tar: the tar file to add
    """
    root = None
    if self.directory and self.directory != '/':
      root = self.directory
    self.tarfile.add_tar(tar, numeric=True, root=root)

  def add_link(self, symlink, destination):
    """Add a symbolic link pointing to `destination`.

    Args:
      symlink: the name of the symbolic link to add.
      destination: where the symbolic link point to.
    """
    self.tarfile.add_file(symlink, tarfile.SYMTYPE, link=destination)

  def add_deb(self, deb):
    """Extract a debian package in the output tar.

    All files presents in that debian package will be added to the
    output tar under the same paths. No user name nor group names will
    be added to the output.

    Args:
      deb: the tar file to add

    Raises:
      DebError: if the format of the deb archive is incorrect.
    """
    with SimpleArFile(deb) as arfile:
      current = arfile.next()
      while current and not current.filename.startswith('data.'):
        current = arfile.next()
      if not current:
        raise self.DebError(deb + ' does not contains a data file!')
      tmpfile = tempfile.mkstemp(suffix=os.path.splitext(current.filename)[-1])
      with open(tmpfile[1], 'wb') as f:
        f.write(current.data)
      self.add_tar(tmpfile[1])
      os.remove(tmpfile[1])


def main(args, unused_argv):
  # Parse modes arguments
  default_mode = None
  if args.mode:
    # Convert from octal
    default_mode = int(args.mode, 8)

  mode_map = {}
  if args.modes:
    for filemode in args.modes:
      (f, mode) = filemode.split('=', 1)
      if f[0] == '/':
        f = f[1:]
      mode_map[f] = int(mode, 8)

  # Add objects to the tar file
  with TarFile(args.output[0], args.directory, args.compression) as output:
    for f in args.file:
      (inf, tof) = f.split('=', 1)
      mode = default_mode
      if tof[0] == '/' and (tof[1:] in mode_map):
        mode = mode_map[tof[1:]]
      elif tof in mode_map:
        mode = mode_map[tof]
      output.add_file(inf, tof, mode)
    for tar in args.tar:
      output.add_tar(tar)
    for deb in args.deb:
      output.add_deb(deb)
    for link in args.link:
      l = link.split(':', 1)
      output.add_link(l[0], l[1])


# Replacement for gflags that I can't figure out how to import.

parser = argparse.ArgumentParser(description='Build a deterministic tar file.')

parser.add_argument("--output", nargs = 1,
                    help='The output file, mandatory')

parser.add_argument("--file", nargs="+",
                    help='A file to add to the layer')

parser.add_argument("--tar", nargs="*", default = [],
                    help='A tar file to add to the layer')

parser.add_argument("--link", nargs="*", default = [],
                    help='A tar file to add to the layer')

parser.add_argument("--deb", nargs="*", default = [],
                    help='A deb file to add to the layer')

parser.add_argument("--directory", nargs = "?",
                     help='Directory in which to store the file inside the layer')

parser.add_argument("--compression", nargs = "?",
                    help='Compression (`gz` or `bz2`), default is none.')

parser.add_argument("--mode", nargs = "?",
                    help='Force the mode on the added files (in octal).')

parser.add_argument("--modes", nargs="*", default = [],
                    help='Specific mode to apply to specific file (from the file argument), e.g., path/to/file=0455.')


if __name__ == '__main__':
  main(parser.parse_args(), sys.argv)

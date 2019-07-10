#
# The MIT License
#
# Copyright (c) 2019 - Present Aaron Ma http://www.aaronhma.com/,
# Copyright (c) 2017 - 2019 Firebolt, Inc. http://www.firebolt.ai/,
# Copyright (c) 2017 - 2019 Firebolt Space Agency,
# Copyright (c) 2019 Project Loop https://github.com/titan-loop/loop/.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
def _file_name(filePathName):
    if '/' in filePathName:
        return filePathName.rsplit('/', -1)[1]
    else:
        return filePathName

def _base_name(fileName):
    return fileName.split('.')[0]

def qt_cc_library(name, src, hdr, uis = [], res = [], normal_hdrs = [], deps = None, **kwargs):
    srcs = src
    for hItem in hdr:
        base_name = _base_name(_file_name(hItem))
        native.genrule(
            name = "%s_moc" % base_name,
            srcs = [hItem],
            outs = [ "moc_%s.cpp" % base_name ],
            cmd =  "if [[ `grep 'Q_OBJECT' $(location %s)` ]] ; \
            then /usr/local/Qt5.5.1/5.5/gcc_64/bin/moc $(location %s) -o $@ -f'%s'; \
            else echo '' > $@ ; fi"  % (hItem, hItem, '%s/%s' % (PACKAGE_NAME, hItem))
        )
        srcs.append("moc_%s.cpp" % base_name)

    for uitem in uis:
      base_name = _base_name(_file_name(uitem))
      native.genrule(
          name = "%s_ui" % base_name,
          srcs = [uitem],
          outs = ["ui_%s.h" % base_name],
          cmd = "/usr/local/Qt5.5.1/5.5/gcc_64/bin/uic $(locations %s) -o $@" % uitem,
      )
      hdr.append("ui_%s.h" % base_name)

    for ritem in res:
      base_name = _base_name(_file_name(ritem))
      native.genrule(
          name = "%s_res" % base_name,
          srcs = [ritem] + deps,
          outs = ["res_%s.cpp" % base_name],
          cmd = "/usr/local/Qt5.5.1/5.5/gcc_64/bin/rcc --name res --output $(OUTS) $(location %s)" % ritem,
      )
      srcs.append("res_%s.cpp" % base_name)

    hdrs = hdr + normal_hdrs

    native.cc_library(
        name = name,
        srcs = srcs,
        hdrs = hdrs,
        deps = deps,
        alwayslink = 1,
        **kwargs
    )

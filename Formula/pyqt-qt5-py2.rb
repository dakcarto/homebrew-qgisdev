class Pyqt < Formula
  desc "Python bindings for Qt"
  homepage "https://www.riverbankcomputing.com/software/pyqt/intro"
  url "https://downloads.sf.net/project/pyqt/PyQt4/PyQt-4.11.4/PyQt-mac-gpl-4.11.4.tar.gz"
  sha256 "f178ba12a814191df8e9f87fb95c11084a0addc827604f1a18a82944225ed918"

  bottle do
    # revision 1
    # sha256 "6b388201f123ab3c390e08f4ff1c97e6c3ae7e4c8644fb86a2775a82bc812c19" => :el_capitan
    # sha256 "3e2e252c58bcf2692d948cfee0273f8aaf052c4d1084acbbad7ba44a43619aee" => :yosemite
    # sha256 "7fa85daa46dc9639ad1a5ce930cac1d06c722528b3caad466044b22221b2253d" => :mavericks
  end

  keg_only "Special version of for QGIS development builds"

  depends_on :python
  depends_on "qt5"
  depends_on "sip"

  def install
    # On Mavericks we want to target libc++, this requires a non default qt makespec
    if ENV.compiler == :clang && MacOS.version >= :mavericks
      ENV.append "QMAKESPEC", "macx-clang"
    end

    py2_ver = Language::Python.major_minor_version("python").to_s

    ENV.prepend_path "PYTHONPATH", "#{Formula["sip"].opt_lib}/python#{py2_ver}/site-packages"

    args = %W[
      --confirm-license
      --bindir=#{bin}
      --destdir=#{lib}/python#{py2_ver}/site-packages
      --sipdir=#{share}/sip
    ]

    # We need to run "configure.py" so that pyqtconfig.py is generated, which
    # is needed by QGIS, PyQWT (and many other PyQt interoperable
    # implementations such as the ROS GUI libs). This file is currently needed
    # for generating build files appropriate for the qmake spec that was used
    # to build Qt. The alternatives provided by configure-ng.py is not
    # sufficient to replace pyqtconfig.py yet (see
    # https://github.com/qgis/QGIS/pull/1508). Using configure.py is
    # deprecated and will be removed with SIP v5, so we do the actual compile
    # using the newer configure-ng.py as recommended. In order not to
    # interfere with the build using configure-ng.py, we run configure.py in a
    # temporary directory and only retain the pyqtconfig.py from that.

    require "tmpdir"
    dir = Dir.mktmpdir
    begin
      cp_r(Dir.glob("*"), dir)
      cd dir do
        system python, "configure.py", *args
        inreplace "pyqtconfig.py", Formula["qt5"].prefix, Formula["qt5"].opt_prefix
        (lib/"python#{py2_ver}/site-packages/PyQt5").install "pyqtconfig.py"
      end
    ensure
      remove_entry_secure dir
    end

    # On Mavericks we want to target libc++, this requires a non default qt makespec
    if ENV.compiler == :clang && MacOS.version >= :mavericks
      args << "--spec" << "macx-clang"
    end

    system python, "configure-ng.py", *args
    system "make"
    system "make", "install"
    system "make", "clean" # for when building against multiple Pythons
  end

  def caveats
    "Phonon support is broken."
  end

  test do
    py2_ver = Language::Python.major_minor_version("python").to_s
    Pathname("test.py").write <<-EOS.undent
      from PyQt4 import QtNetwork
      QtNetwork.QNetworkAccessManager().networkAccessible()
    EOS
    ENV.prepend_path "PYTHONPATH", lib/"python#{py2_ver}/site-packages"
    system python, "test.py"
  end
end

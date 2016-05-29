class Pyqt5Qt5Py3 < Formula
  desc "Python bindings for v5 of Qt"
  homepage "https://www.riverbankcomputing.com/software/pyqt/download5"
  url "https://downloads.sourceforge.net/project/pyqt/PyQt5/PyQt-5.6/PyQt5_gpl-5.6.tar.gz"
  sha256 "2e481a6c4c41b96ed3b33449e5f9599987c63a5c8db93313bd57a6acbf20f0e1"

  bottle do
    # sha256 "4815f60529eadc829c704adbfb6a01ea2daec7acae4c4f7871579d3b01bdbc63" => :el_capitan
    # sha256 "ac14ff2a18458c8201415adf3dfbd872849b0fef9968e105c4ce43e72876fcbf" => :yosemite
    # sha256 "111602985fb4ced414dc4722a1af8ee3d428b2e013e22bdae8d0d059570ac44c" => :mavericks
  end

  keg_only "Special version for QGIS development builds"

  option "with-debug", "Build with debug symbols"
  option "with-docs", "Install HTML documentation and python examples"

  deprecated_option "enable-debug" => "with-debug"

  depends_on "python3"
  depends_on "qt5"
  depends_on "sip-py3"

  def install
    py_ver = Language::Python.major_minor_version("python3").to_s

    args = ["--confirm-license",
            "--bindir=#{bin}",
            "--destdir=#{lib}/python#{py_ver}/site-packages",
            "--stubsdir=#{lib}/python#{py_ver}/site-packages/PyQt5",
            "--sipdir=#{Formula["sip-py3"].opt_share}/sip/Qt5",
            # sip.h could not be found automatically
            "--sip-incdir=#{Formula["sip-py3"].opt_include}",
            # Make sure the qt5 version of qmake is found.
            # If qt4 is linked it will pickup that version otherwise.
            "--qmake=#{Formula["qt5"].bin}/qmake",
            # Force deployment target to avoid libc++ issues
            "QMAKE_MACOSX_DEPLOYMENT_TARGET=#{MacOS.version}",
            "--qml-plugindir=#{pkgshare}/plugins",
            "--verbose"]
    args << "--debug" if build.with? "debug"

    system "python3", "configure.py", *args
    system "make"
    system "make", "install"
    system "make", "clean"
  end
  doc.install "doc/html", "examples" if build.with? "docs"

  test do
    py_ver = Language::Python.major_minor_version("python3").to_s
    ENV.prepend_path "PYTHONPATH", lib/"python#{py_ver}/site-packages"
    system bin/"pyuic5", "--version"
    system bin/"pylupdate5", "-version"
    system bin/"python3", "-c", "import PyQt5"
    %w[
      Gui
      Location
      Multimedia
      Network
      Quick
      Svg
      WebEngineWidgets
      Widgets
      Xml
    ].each { |mod| system "python3", "-c", "import PyQt5.Qt#{mod}" }
  end
end

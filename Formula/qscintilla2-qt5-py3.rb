class Qscintilla2Qt5Py3 < Formula
  desc "Port to Qt of the Scintilla editing component"
  homepage "https://www.riverbankcomputing.com/software/qscintilla/intro"
  url "https://downloads.sf.net/project/pyqt/QScintilla2/QScintilla-2.9.2/QScintilla_gpl-2.9.2.tar.gz"
  sha256 "f2c8ccdc9d3dbb90764ceed53ea096da9bb13b6260da1324e6ab4ecea29e620a"

  bottle do
    # cellar :any
    # sha256 "4f4654cd52bb7c248b3a842cf0c7ee80b2f328655934a0521be54d4c16a6f4a6" => :el_capitan
    # sha256 "60fc2962adec3242ffff0f373c681f8d9bd4d3a278389bdbf344e1067dd38f9a" => :yosemite
    # sha256 "2eabd5ae2713d198c41c33d8fc7ae1f1c99a2b1a398b228602b5e26301a225c9" => :mavericks
  end

  keg_only "Special version for QGIS development builds"
  option "without-plugin", "Skip building the Qt Designer plugin"

  depends_on "python3"
  depends_on "pyqt5-qt5-py3"
  depends_on "qt5"

  def install
    py3_ver = Language::Python.major_minor_version("python3").to_s
    # On Mavericks we want to target libc++, this requires a unsupported/macx-clang-libc++ flag
    if ENV.compiler == :clang && MacOS.version >= :mavericks
      spec = (build.with?("qt5") ?"macx-clang" : "unsupported/macx-clang-libc++")
    else
      spec = "macx-g++"
    end
    args = %W[-config release -spec #{spec}]

    cd "Qt4Qt5" do
      inreplace "qscintilla.pro" do |s|
        s.gsub! "$$[QT_INSTALL_LIBS]", lib
        s.gsub! "$$[QT_INSTALL_HEADERS]", include
        s.gsub! "$$[QT_INSTALL_TRANSLATIONS]", "#{prefix}/trans"
        s.gsub! "$$[QT_INSTALL_DATA]", "#{prefix}/data"
      end

      inreplace "features/qscintilla2.prf" do |s|
        s.gsub! "$$[QT_INSTALL_LIBS]", lib
        s.gsub! "$$[QT_INSTALL_HEADERS]", include
      end

      system "qmake", "qscintilla.pro", *args
      system "make"
      system "make", "install"
    end

    # Add qscintilla2 features search path, since it is not installed in Qt keg's mkspecs/features/
    ENV["QMAKEFEATURES"] = "#{prefix}/data/mkspecs/features"

    cd "Python" do
      (share/"sip").mkpath
      system "python3", "configure.py", "-o", lib, "-n", include,
             "--apidir=#{prefix}/qsci",
                     "--destdir=#{lib}/python#{py3_ver}/site-packages/PyQt4",
             "--qsci-sipdir=#{share}/sip",
                     "--pyqt-sipdir=#{Formula["sip-py3"]}/share/sip",
             "--spec=#{spec}"
      system "make"
      system "make", "install"
      system "make", "clean"
    end

    if build.with? "plugin"
      mkpath prefix/"plugins/designer"
      cd "designer-Qt4Qt5" do
        inreplace "designer.pro" do |s|
          s.sub! "$$[QT_INSTALL_PLUGINS]", "#{lib}/qt4/plugins"
          s.sub! "$$[QT_INSTALL_LIBS]", lib
        end
        system Formula["qt5"].bin/"qmake", "designer.pro", *args
        system "make"
        system "make", "install"
      end
    end
  end

  test do
    py3_ver = Language::Python.major_minor_version("python3").to_s
    ENV.prepend_path "PYTHONPATH", lib/"python#{py3_ver}/site-packages"
    Pathname("test.py").write <<-EOS.undent
      import PyQt4.Qsci
      assert("QsciLexer" in dir(PyQt4.Qsci))
    EOS
    system "python3", "test.py"
  end
end

class SipPy2 < Formula
  desc "Tool to create Python bindings for C and C++ libraries"
  homepage "https://www.riverbankcomputing.com/software/sip/intro"
  url "https://downloads.sourceforge.net/project/pyqt/sip/sip-4.18/sip-4.18.tar.gz"
  sha256 "f1dc5c81c07a9ad97edcd4a0af964a41e420024ba7ca165afd2b351efd249cb6"

  head "https://www.riverbankcomputing.com/hg/sip", :using => :hg

  bottle do
    # cellar :any_skip_relocation
    # sha256 "53bc937d3dcbcee545f9eb1326b15a8d2770cf09891be230e020187daec2c81c" => :el_capitan
    # sha256 "3cec68a975b1dca7d6893009d8f73c8da4579a62ada8a5019aa527c580eddfdb" => :yosemite
    # sha256 "df0cdfacabba8e9758329590d1493ba4f1b632b829d5e1f9ca3c6477ba2f6f28" => :mavericks
  end

  keg_only "Special version for QGIS development builds"

  depends_on "python"

  def install
    py_ver = Language::Python.major_minor_version("python").to_s
    if build.head?
      # Link the Mercurial repository into the download directory so
      # build.py can use it to figure out a version number.
      ln_s cached_download + ".hg", ".hg"
      # build.py doesn't run with python3
      system "python", "build.py", "prepare"
    end

    # Note the binary `sip` is the same for python 2.x and 3.x
    system "python", "configure.py",
                   "--deployment-target=#{MacOS.version}",
                   "--destdir=#{lib}/python#{py_ver}/site-packages",
                   "--bindir=#{bin}",
                   "--incdir=#{include}",
                   "--sipdir=#{share}/sip"
    system "make"
    system "make", "install"
    system "make", "clean"
  end

  def post_install
    mkdir_p "#{share}/sip"
  end

  def caveats
    "The sip-dir for Python is #{share}/sip."
  end

  test do
    py_ver = Language::Python.major_minor_version("python").to_s
    (testpath/"test.h").write <<-EOS.undent
      #pragma once
      class Test {
      public:
        Test();
        void test();
      };
    EOS
    (testpath/"test.cpp").write <<-EOS.undent
      #include "test.h"
      #include <iostream>
      Test::Test() {}
      void Test::test()
      {
        std::cout << "Hello World!" << std::endl;
      }
    EOS
    (testpath/"test.sip").write <<-EOS.undent
      %Module test
      class Test {
      %TypeHeaderCode
      #include "test.h"
      %End
      public:
        Test();
        void test();
      };
    EOS
    (testpath/"generate.py").write <<-EOS.undent
      from sipconfig import SIPModuleMakefile, Configuration
      m = SIPModuleMakefile(Configuration(), "test.build")
      m.extra_libs = ["test"]
      m.extra_lib_dirs = ["."]
      m.generate()
    EOS
    (testpath/"run.py").write <<-EOS.undent
      from test import Test
      t = Test()
      t.test()
    EOS
    system ENV.cxx, "-shared", "-Wl,-install_name,#{testpath}/libtest.dylib",
                    "-o", "libtest.dylib", "test.cpp"
    system "#{bin}/sip", "-b", "test.build", "-c", ".", "test.sip"
    ENV["PYTHONPATH"] = lib/"python#{py_ver}/site-packages"
    system "python", "generate.py"
    system "make", "-j1", "clean", "all"
    system "python", "run.py"
  end
end

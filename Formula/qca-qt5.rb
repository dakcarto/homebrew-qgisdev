class QcaQt5 < Formula
  desc "Qt Cryptographic Architecture (QCA)"
  homepage "http://delta.affinix.com/qca/"
  head "https://anongit.kde.org/qca.git"

  stable do
    url "http://delta.affinix.com/download/qca/2.0/qca-2.1.0.tar.gz"
    sha256 "226dcd76138c3738cdc15863607a96b3758a4c3efd3c47295939bcea4e7a9284"

    # Fixes build with Qt 5.5 by adding a missing include (already fixed in HEAD).
    patch do
      url "https://quickgit.kde.org/?p=qca.git&a=commitdiff&h=7207e6285e932044cd66d49d0dc484666cfb0092&o=plain"
      sha256 "3c0707b3d05c708f93dfda27bdd6ed700e12e91a7dbf73a3c9316c71cf7e38ea"
    end
  end

  bottle do
    # revision 3
    # sha256 "62846de848b7e7c4f0b3eb5a045940c8b80554ef388d9646dd7b02b195b1a5c8" => :el_capitan
    # sha256 "a2afc96b7058b81e6b640c480b621434c7b6ba5e82cc0af4e38766d7efe42251" => :yosemite
    # sha256 "c948a6d95b7ff4da029eedeaca69e5b51d9227e9a7cf369daa98cfda5cf73528" => :mavericks
  end

  keg_only "Special version for QGIS development builds"

  option "with-api-docs", "Build API documentation"

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "qt5"

  # Plugins (QCA needs at least one plugin to do anything useful)
  depends_on "openssl" # qca-ossl
  depends_on "botan" => :optional # qca-botan
  depends_on "libgcrypt" => :optional # qca-gcrypt
  depends_on "gnupg" => :optional # qca-gnupg
  depends_on "nss" => :optional # qca-nss
  depends_on "pkcs11-helper" => :optional # qca-pkcs11

  if build.with? "api-docs"
    depends_on "graphviz" => :build
    depends_on "doxygen" => [:build, "with-graphviz"]
  end

  def install
    args = std_cmake_args
    args << "-DQT4_BUILD=OFF"
    args << "-DBUILD_TESTS=OFF"

    # Plugins (qca-ossl, qca-cyrus-sasl, qca-logger, qca-softstore always built)
    args << "-DWITH_botan_PLUGIN=#{build.with?("botan") ? "YES" : "NO"}"
    args << "-DWITH_gcrypt_PLUGIN=#{build.with?("libgcrypt") ? "YES" : "NO"}"
    args << "-DWITH_gnupg_PLUGIN=#{build.with?("gnupg") ? "YES" : "NO"}"
    args << "-DWITH_nss_PLUGIN=#{build.with?("nss") ? "YES" : "NO"}"
    args << "-DWITH_pkcs11_PLUGIN=#{build.with?("pkcs11-helper") ? "YES" : "NO"}"

    system "cmake", ".", *args
    system "make", "install"

    if build.with? "api-docs"
      system "make", "doc"
      doc.install "apidocs/html"
    end
  end

  test do
    system "#{bin}/qcatool", "--noprompt", "--newpass=",
                             "key", "make", "rsa", "2048", "test.key"
  end
end

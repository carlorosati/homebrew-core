# Major releases of erlang should typically start out as separate formula in
# Homebrew-versions, and only be merged to master when things like couchdb and
# elixir are compatible.
class Erlang < Formula
  desc "Programming language for highly scalable real-time systems"
  homepage "https://www.erlang.org/"
  # Download tarball from GitHub; it is served faster than the official tarball.
  url "https://github.com/erlang/otp/archive/OTP-19.2.tar.gz"
  sha256 "c6adbc82a45baa49bf9f5b524089da480dd27113c51b3d147aeb196fdb90516b"
  head "https://github.com/erlang/otp.git"

  bottle do
    cellar :any
    sha256 "d6886c87e637a969484df657ed6c95ec9828307f30ff357084e4ae37c735d5f1" => :sierra
    sha256 "8a2ee488e2fbb10eacbc6ee762b42454f9c8269d59a1edc775f030e93fafd3e6" => :el_capitan
    sha256 "947789237316504f7e3d7ab7d127d7609d3f6ece66afe50f1dd000b5b2bdb8ce" => :yosemite
  end

  option "without-hipe", "Disable building hipe; fails on various macOS systems"
  option "with-native-libs", "Enable native library compilation"
  option "with-dirty-schedulers", "Enable experimental dirty schedulers"
  option "with-java", "Build jinterface application"
  option "without-docs", "Do not install documentation"

  deprecated_option "disable-hipe" => "without-hipe"
  deprecated_option "no-docs" => "without-docs"

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "openssl"
  depends_on "fop" => :optional # enables building PDF docs
  depends_on :java => :optional
  depends_on "wxmac" => :recommended # for GUI apps like observer

  resource "man" do
    url "https://www.erlang.org/download/otp_doc_man_19.2.tar.gz"
    sha256 "8a76ff3bb40a6d6a1552fa5a4204c8a3c7d99d2ea6f12684f02d038b23ad25cb"
  end

  resource "html" do
    url "https://www.erlang.org/download/otp_doc_html_19.2.tar.gz"
    sha256 "c373c8c1a9fe7433825088684932f3ded76f53d5b8a4d3d2a364263f1f783043"
  end

  def install
    # Fixes "dyld: Symbol not found: _clock_gettime"
    # Reported 17 Sep 2016 https://bugs.erlang.org/browse/ERL-256
    if MacOS.version == "10.11" && MacOS::Xcode.installed? && MacOS::Xcode.version >= "8.0"
      ENV["erl_cv_clock_gettime_monotonic_default_resolution"] = "no"
      ENV["erl_cv_clock_gettime_monotonic_try_find_pthread_compatible"] = "no"
      ENV["erl_cv_clock_gettime_wall_default_resolution"] = "no"
    end

    # Unset these so that building wx, kernel, compiler and
    # other modules doesn't fail with an unintelligable error.
    %w[LIBS FLAGS AFLAGS ZFLAGS].each { |k| ENV.delete("ERL_#{k}") }

    ENV["FOP"] = "#{HOMEBREW_PREFIX}/bin/fop" if build.with? "fop"

    # Do this if building from a checkout to generate configure
    system "./otp_build", "autoconf" if File.exist? "otp_build"

    args = %W[
      --disable-debug
      --disable-silent-rules
      --prefix=#{prefix}
      --enable-kernel-poll
      --enable-threads
      --enable-sctp
      --enable-dynamic-ssl-lib
      --with-ssl=#{Formula["openssl"].opt_prefix}
      --enable-shared-zlib
      --enable-smp-support
    ]

    args << "--enable-darwin-64bit" if MacOS.prefer_64_bit? && OS.mac?
    args << "--enable-native-libs" if build.with? "native-libs"
    args << "--enable-dirty-schedulers" if build.with? "dirty-schedulers"
    args << "--enable-wx" if build.with? "wxmac"

    if MacOS.version >= :snow_leopard && MacOS::CLT.installed?
      args << "--with-dynamic-trace=dtrace"
    end

    if build.without? "hipe"
      # HIPE doesn't strike me as that reliable on macOS
      # https://syntatic.wordpress.com/2008/06/12/macports-erlang-bus-error-due-to-mac-os-x-1053-update/
      # https://www.erlang.org/pipermail/erlang-patches/2008-September/000293.html
      args << "--disable-hipe"
    else
      args << "--enable-hipe"
    end

    if build.with? "java"
      args << "--with-javac"
    else
      args << "--without-javac"
    end

    system "./configure", *args
    system "make"
    system "make", "install"

    if build.with? "docs"
      (lib/"erlang").install resource("man").files("man")
      doc.install resource("html")
    end
  end

  def caveats; <<-EOS.undent
    Man pages can be found in:
      #{opt_lib}/erlang/man

    Access them with `erl -man`, or add this directory to MANPATH.
    EOS
  end

  test do
    system "#{bin}/erl", "-noshell", "-eval", "crypto:start().", "-s", "init", "stop"
  end
end

class Rust < Formula
  desc "Safe, concurrent, practical language"
  homepage "https://www.rust-lang.org/"
  revision 1

  stable do
    url "https://static.rust-lang.org/dist/rustc-1.15.1-src.tar.gz"
    sha256 "2e7daad418a830b45b977cd7ecf181b65f30f73df63ff36e124ea5fe5d1af327"

    resource "cargo" do
      url "https://github.com/rust-lang/cargo.git",
          :tag => "0.16.0",
          :revision => "6e0c18cccc8b0c06fba8a8d76486f81a792fb420"
    end

    resource "racer" do
      url "https://github.com/phildawes/racer/archive/2.0.5.tar.gz"
      sha256 "370e8e2661b379185667001884b51bdc4b414abdc27bb9671513c1912ad8be25"
    end
  end

  bottle do
    sha256 "a668d0c7892dfc0fcf19c9293d8094178e0eb2f1923a98afc150abf157026978" => :sierra
    sha256 "05a8050aa155339b1bb123763cfde37321cc540ba441962e9ac3fb9698770837" => :el_capitan
    sha256 "3d58445118ec95a4de71ec5a0cee5679ef393b138dad75c266d013ee805c5c59" => :yosemite
  end

  head do
    url "https://github.com/rust-lang/rust.git"

    resource "cargo" do
      url "https://github.com/rust-lang/cargo.git"
    end
  end

  option "with-llvm", "Build with brewed LLVM. By default, Rust's LLVM will be used."
  option "with-racer", "Build Racer code completion tool, and retain Rust sources."

  depends_on "cmake" => :build
  depends_on "pkg-config" => :run
  depends_on "llvm" => :optional
  depends_on "openssl"
  depends_on "libssh2"
  unless OS.mac?
    depends_on "binutils" => :build unless OS.mac?
    depends_on :python unless OS.mac?
  end

  conflicts_with "multirust", :because => "both install rustc, rustdoc, cargo, rust-lldb, rust-gdb"

  # According to the official readme, GCC 4.7+ is required
  fails_with :gcc_4_0
  fails_with :gcc
  ("4.3".."4.6").each do |n|
    fails_with :gcc => n
  end

  resource "cargobootstrap" do
    if OS.mac?
      url "https://s3.amazonaws.com/rust-lang-ci/cargo-builds/fbeea902d2c9a5be6d99cc35681565d8f7832592/cargo-nightly-x86_64-apple-darwin.tar.gz"
      version "2016-12-15"
      sha256 "ad6c31b41fef1d68e4523eb7d090fe8103848f30eb5ac8cba5128b7c11ed23fc"
    elsif OS.linux?
      # From: https://github.com/rust-lang/rust/blob/1.15.1/src/stage0.txt
      url "https://s3.amazonaws.com/rust-lang-ci/cargo-builds/fbeea902d2c9a5be6d99cc35681565d8f7832592/cargo-nightly-x86_64-unknown-linux-gnu.tar.gz"
      # From:
      # name=cargo-nightly-x86_64-unknown-linux-gnu && tar -zxvf $name.tar.gz $name/version && cat $name/version
      version "2016-12-15b"
      sha256 "0e052514ee88f236153a0d6c6f38f66d691eb4cf1ac09e6040d96e5101d57800"
    end
  end

  def install
    # Reduce memory usage below 4 GB for Circle CI.
    ENV["MAKEFLAGS"] = "-j12" if ENV["CIRCLECI"]
    args = ["--prefix=#{prefix}"]
    args << "--disable-rpath" if build.head?
    args << "--enable-clang" if ENV.compiler == :clang
    args << "--llvm-root=#{Formula["llvm"].opt_prefix}" if build.with? "llvm"
    args << "--enable-sccache"
    if build.head?
      args << "--release-channel=nightly"
    else
      args << "--release-channel=stable"
    end
    system "./configure", *args
    system "make"
    system "make", "install"

    resource("cargobootstrap").stage do
      system "./install.sh", "--prefix=#{buildpath}/cargobootstrap"
      if OS.linux? and Formula["glibc"].installed?
        keg = Keg.new(prefix)
        file = Pathname.new('#{buildpath}/cargobootstrap')
        keg.change_rpath(file, Keg::PREFIX_PLACEHOLDER, HOMEBREW_PREFIX.to_s)
      end
    end
    ENV.prepend_path "PATH", buildpath/"cargobootstrap/bin"

    resource("cargo").stage do
      system "./configure", "--prefix=#{prefix}", "--local-rust-root=#{prefix}",
                            "--enable-optimize"
      system "make"
      system "make", "install"
    end

    if build.with? "racer"
      resource("racer").stage do
        ENV.prepend_path "PATH", bin
        cargo_home = buildpath/"cargo_home"
        cargo_home.mkpath
        ENV["CARGO_HOME"] = cargo_home
        system bin/"cargo", "build", "--release", "--verbose"
        (libexec/"bin").install "target/release/racer"
        (bin/"racer").write_env_script(libexec/"bin/racer", :RUST_SRC_PATH => pkgshare/"rust_src")
      end
      # Remove any binary files; as Homebrew will run ranlib on them and barf.
      rm_rf Dir["src/{llvm,test,librustdoc,etc/snapshot.pyc}"]
      (pkgshare/"rust_src").install Dir["src/*"]
    end

    rm_rf prefix/"lib/rustlib/uninstall.sh"
    rm_rf prefix/"lib/rustlib/install.log"
  end

  test do
    system "#{bin}/rustdoc", "-h"
    (testpath/"hello.rs").write <<-EOS.undent
    fn main() {
      println!("Hello World!");
    }
    EOS
    system "#{bin}/rustc", "hello.rs"
    assert_equal "Hello World!\n", `./hello`
    system "#{bin}/cargo", "new", "hello_world", "--bin"
    assert_equal "Hello, world!",
                 (testpath/"hello_world").cd { `#{bin}/cargo run`.split("\n").last }
  end
end

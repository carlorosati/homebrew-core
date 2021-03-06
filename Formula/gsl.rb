class Gsl < Formula
  desc "Numerical library for C and C++"
  homepage "https://www.gnu.org/software/gsl/"
  url "https://ftpmirror.gnu.org/gsl/gsl-2.3.tar.gz"
  mirror "https://ftp.gnu.org/gnu/gsl/gsl-2.3.tar.gz"
  sha256 "562500b789cd599b3a4f88547a7a3280538ab2ff4939504c8b4ac4ca25feadfb"

  bottle do
    cellar :any
    sha256 "1bb5851b23af3a29907fe944b0223f84a2a13f9f493a124b9f659f3ac77cfbce" => :sierra
    sha256 "ca5dd754f6988ee2083be33660530854b3a8d4ab2ab6026d9da6613cfec7431e" => :el_capitan
    sha256 "27e916ed0e2bec74aeb88e694a22f0076e225c6a0b8c9b5450d5cbc0db842e3e" => :yosemite
    sha256 "99d57cebb43fbc890e74e7e71a650b038f639c87ec1197e42ce3179b10378cf6" => :x86_64_linux
  end

  option :universal

  def install
    ENV.universal_binary if build.universal?

    system "./configure", "--disable-dependency-tracking", "--prefix=#{prefix}"
    system "make" # A GNU tool which doesn't support just make install! Shameful!
    system "make", "install"
  end

  test do
    system bin/"gsl-randist", "0", "20", "cauchy", "30"
  end
end

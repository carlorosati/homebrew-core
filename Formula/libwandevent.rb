class Libwandevent < Formula
  desc "API for developing event-driven programs"
  homepage "http://research.wand.net.nz/software/libwandevent.php"
  url "http://research.wand.net.nz/software/libwandevent/libwandevent-3.0.2.tar.gz"
  sha256 "48fa09918ff94f6249519118af735352e2119dc4f9b736c861ef35d59466644a"

  bottle do
    cellar :any
    sha256 "e4b00ade9387b8fdccf72bbe9edd0e334c69f23597f85dd1e6da02088703c286" => :sierra
    sha256 "f1459d39284b520c17443c6bef5ccb641dfe1e20266a4f34071f6a87cd9669e4" => :el_capitan
    sha256 "b8c90b8dca1d0ded39036d7f23b4e33857c7914e178ba8ac8870ab702f96fa04" => :yosemite
  end

  def install
    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    (testpath/"test.cpp").write <<-EOS.undent
      #include <sys/time.h>
      #include <libwandevent.h>

      int main() {
        wand_event_init();
        return 0;
      }
    EOS
    system ENV.cc, "test.cpp", "-L#{lib}", "-lwandevent", "-o", "test"
    system "./test"
  end
end

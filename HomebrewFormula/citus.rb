class Citus < Formula
  desc "PostgreSQL-based distributed RDBMS"
  homepage "https://www.citusdata.com"
  url "https://api.github.com/repos/citusdata/citus/tarball/3039a584ad78c6f843c079484f9e6dfbddf65087?access_token=#{ENV["GITHUB_TOKEN"]}"
  version "5.0.0-rc.3"
  sha256 "6cef2a68fda2a389a11d42dd522d8f026429062f9e084bda225415efcb962710"

  bottle do
    root_url "https://s3.amazonaws.com/packages.citusdata.com/homebrew"
    cellar :any
    sha256 "1d0ee0bb0aa4c2b45167e7fbcb5932127b1120eb792d45ed3f09e2ad76494b6e" => :el_capitan
  end

  depends_on "postgresql"

  def install
    config_args = %W[--prefix=#{prefix} PG_CONFIG=#{Formula["postgresql"].opt_bin}/pg_config]

    # workaround for https://github.com/Homebrew/homebrew/issues/49948
    make_args = ["libpq=-L#{Formula["postgresql"].opt_lib} -lpq"]

    system "./configure", *config_args
    system "make", *make_args

    mkdir "stage"
    system "make", "install", "DESTDIR=#{buildpath}/stage"

    bin.install Dir["stage/**/bin/*"]
    lib.install Dir["stage/**/lib/*"]
    include.install Dir["stage/**/include/*"]
    (share/"postgresql/extension").install Dir["stage/**/share/postgresql/extension/*"]
  end

  test do
    system "true"
  end
end

FROM ubuntu:20.04
# the following are needed to make sure the timezone packages don't ask for your timezone.
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true
ENV HARNESS_PERL_SWITCHES -MDevel::Cover
RUN apt-get update && \
	apt-get install -qy --no-install-recommends --no-install-suggests \
	make=4.2.1-1.2 \
	cpanminus=1.7044-1 \
	libtest-harness-perl=3.42-2 \
	libdata-dump-perl=1.23-1 \
	liblist-moreutils-perl=0.416-1build5 \
	libtest-exception-perl=0.43-1 \
	libtry-tiny-perl=0.30-1 \
	libexception-class-perl=1.44-1 \
	libdbix-class-perl=0.082841-1 \
	libdbix-dbschema-perl=0.45-1 \
	libdbd-sqlite3-perl=1.64-1build1 \
	libtext-csv-perl=2.00-1 \
	libjson-perl=4.02000-2 \
	libdevel-cover-perl=1.33-1build1 \
	git=1:2.25.1-1ubuntu3.1 && \
	rm -rf /var/lib/apt/lists/* && \
	cpanm --notest Array::Utils \
	DBIx::Class::DynamicSubclass \
	Mojolicious \
	Mojolicious::Plugin::NotYAMLConfig \
	Mojolicious::Plugin::DBIC \
	Mojolicious::Plugin::Authentication \
	Devel::Cover::Report::Codecov
ENTRYPOINT ["/bin/bash"]

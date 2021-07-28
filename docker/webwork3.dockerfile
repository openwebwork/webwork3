FROM ubuntu:20.04
# the following are needed to make sure the timezone packages don't ask for your timezone.
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true
ENV HARNESS_PERL_SWITCHES -MDevel::Cover
RUN apt-get update
RUN apt-get install -qy make \
    cpanminus \
    libtest-harness-perl \
    libdata-dump-perl \
    liblist-moreutils-perl \
    libtest-exception-perl \
    libtry-tiny-perl \
    libexception-class-perl \
    libdbix-class-perl \
    libdbix-dbschema-perl \
    libdbd-sqlite3-perl \
    libtext-csv-perl \
    libjson-perl \
    libdevel-cover-perl
RUN cpanm --notest Array::Utils \
    DBIx::Class::DynamicSubclass \
    Mojolicious \
    Mojolicious::Plugin::NotYAMLConfig \
    Mojolicious::Plugin::DBIC \
    Mojolicious::Plugin::Authentication \
    Devel::Cover::Report::Codecov
ENTRYPOINT /bin/bash
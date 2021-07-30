FROM scottw/alpine-perl:latest
RUN apk update && \
	apk add bash perl-data-dump perl-list-moreutils perl-text-csv \
	perl-test-exception perl-try-tiny perl-dbix-dbschema perl-sql-translator \
	perl-module-build perl-json-xs perl-clone perl-yaml perl-digest-md5 \
	perl-capture-tiny perl-io-socket-ssl perl-json-xs perl-uri \
	perl-exception-class
RUN	cpanm -fi --notest \
	Array::Utils \
	Perl::Tidy \
	DBIx::Class::DynamicSubclass \
	Devel::Cover \
	Mojolicious \
	Mojolicious::Plugin::DBIC \
	Mojolicious::Plugin::Authentication \
	Devel::Cover::Report::Codecov
ENTRYPOINT /bin/bash
FROM scottw/alpine-perl:5.32.0
RUN apk update && \
	apk add --no-cache bash=5.1.8-r0 perl-data-dump=1.25-r0 perl-list-moreutils=0.430-r0 perl-text-csv=2.01-r0 \
	perl-test-exception=0.43-r2 perl-try-tiny=0.30-r3 perl-dbix-dbschema=0.45-r2 perl-sql-translator=1.62-r0 \
	perl-module-build=0.4231-r1 perl-json-xs=4.03-r1 perl-clone=0.45-r1 perl-yaml=1.30-r2 perl-digest-md5=2.58-r2 \
	perl-capture-tiny=0.48-r2 perl-io-socket-ssl=2.071-r0 perl-uri=5.09-r0 \
	perl-exception-class=1.44-r2 && \
	cpanm -fi --notest \
	Array::Utils \
	Perl::Tidy \
	DBIx::Class::DynamicSubclass \
	Devel::Cover \
	Mojolicious \
	Mojolicious::Plugin::DBIC \
	Mojolicious::Plugin::Authentication \
	Devel::Cover::Report::Codecov
ENTRYPOINT ["/bin/bash"]

FROM scottw/alpine-perl:latest
RUN apk update && \
	apk add bash
RUN	cpanm -fi --notest \
  Data::Dump \
	DBIC \
	List::MoreUtils \
	Text::CSV \
	Test::Exception \
	Try::Tiny \
	Array::Utils \
	Exception::Class \
	DBIx::Class::Schema \
	DBIx::Class::DynamicSubclass \
	SQL::Translator \
	JSON \
	Clone \
	YAML::XS \
	Mojolicious \
	Mojolicious::Plugin::DBIC \
	Mojolicious::Plugin::Authentication
ENTRYPOINT /bin/bash
#! /bin/bash
perl db/build_db.pl
prove '.**/*.t'
#! /bin/bash
cd t || exit
perl db/build_db.pl
prove ./*/*.t

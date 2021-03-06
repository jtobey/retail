# !/bin/sh -e
# Test retail does what it should.
# Since: Wed Dec  3 16:55:07 EST 2014
#
#    Copyright (c) 2014, Mark Bucciarelli <mkbucc@gmail.com>
#
#    Permission to use, copy, modify, and/or distribute this software
#    for any purpose with or without fee is hereby granted, provided
#    that the above copyright notice and this permission notice
#    appear in all copies.
#
#    THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
#    WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
#    WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL
#    THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR
#    CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
#    LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
#    NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
#    CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#


RETAIL=./retail
D=./testing

rm -rf $D
mkdir -p $D

fail() {
	echo "FAIL: $1"
	exit 1
}

# retail outputs two lines added since last run.
cat > $D/1.log << EOF
line1
line2
line3
EOF
$RETAIL -o $D/1.offset $D/1.log > /dev/null
cat >> $D/1.log <<EOF
line4
line5
EOF
$RETAIL -o $D/1.offset $D/1.log > $D/1.act
cat > $D/1.exp << EOF
line4
line5
EOF
diff $D/1.act $D/1.exp && printf "." || fail "didn't see two new lines"

# retail uses offset.<logfile> as default offset filename
cat > $D/2.log << EOF
line1
line2
line3
EOF
$RETAIL $D/2.log > /dev/null
F=offset.2.log
[ -f $D/$F ] && printf "."  || fail "default offset file \"$D/$F\" not created."

# If rotated, output lines from old inode + lines from new file.
LF=$D/3.log
cat > $LF << EOF
line1
line2
line3
EOF
$RETAIL $LF > /dev/null
cat >> $LF << EOF
line4
line5
EOF
mv $LF $LF.1
cat > $LF << EOF
line6
line7
EOF
$RETAIL  $LF > $D/3.act
cat > $D/3.exp << EOF
line4
line5
line6
line7
EOF
diff $D/3.act $D/3.exp && printf "." || fail "didn't follow a move log rotation"



# Test that passing directory for offset works.
LF=$D/4.log
cat > $LF << EOF
line1
line2
line3
EOF
mkdir -p $D/offsets
$RETAIL -o $D/offsets/ $LF > /dev/null
[ -f $D/offsets/offset.4.log ] && printf "."  || fail "default offset file \"$D/offsets/offset.4.log\" not created."
cat >> $LF << EOF
line4
line5
EOF
$RETAIL -o $D/offsets/ $LF > $D/4.act
cat > $D/4.exp << EOF
line4
line5
EOF
diff $D/4.act $D/4.exp && printf "." || fail "using offset directory"

# If rotated via copy and trunate, output lines from old inode + lines from new file.
LF=$D/5.log
cat > $LF << EOF
line1
line2
line3
EOF
$RETAIL $LF > /dev/null
cat >> $LF << EOF
line4
line5
EOF
cp $LF $LF.1
> $LF
cat > $LF << EOF
line6
line7
EOF
$RETAIL  $LF > $D/5.act
cat > $D/5.exp << EOF
line4
line5
line6
line7
EOF
diff $D/5.act $D/5.exp && printf "." || fail "didn't follow a copy/truncate log rotation"


# Rotated via move then gzipped.
LF=$D/6.log
cat > $LF << EOF
line1
line2
line3
EOF
$RETAIL $LF > /dev/null
cat >> $LF << EOF
line4
line5
EOF
mv $LF $LF.1
gzip $LF.1
cat > $LF << EOF
line6
line7
EOF
$RETAIL  $LF > $D/6.act
cat > $D/6.exp << EOF
line4
line5
line6
line7
EOF
diff $D/6.act $D/6.exp && printf "." || fail "Didn't follow a gzipped move rotation."

# Dumping an empty log file is not an error.
LF=$D/7\.log
touch $LF
$RETAIL $LF > /dev/null


# If inode matches, make sure base name does too.
# In practice, 
# I saw inodes reused.
# Specifically, 
# the lastinode in the auth.log offset file 
# was being used by syslog.2.gz.
# Once a file is gzipped (e.g., auth.log),
# the inode of the ungzipped file 
# becomes available.
LF=$D/8.log
cat > $LF << EOF
line1
line2
line3
EOF
$RETAIL $LF > /dev/null
cat >> $LF << EOF
line4
line5
EOF
mv $LF $D/abc.8.log.1
cat > $LF << EOF
line6
line7
EOF
$RETAIL  $LF > $D/8.act
cat > $D/8.exp << EOF
line6
line7
EOF
diff $D/8.act $D/8.exp && printf "." || fail "Didn't check base name."


printf "\nSUCCESS!\n"
#rm -rf $D

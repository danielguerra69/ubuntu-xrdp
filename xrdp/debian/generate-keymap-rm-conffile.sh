#!/bin/mksh
#-
# Copyright (c) 2016 Dominik George <nik@naturalnet.de>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#-
# This script parses upstream versions from debian/changelog and then
# analyses the corresponding upstream git tags for xrdp keymap files
# that have been removed since the last version. It outputs the result
# in the format suitable for adding to debian/xrdp.maintscript.

# Pipe all upstream versions to co-process in chronological order
dpkg-parsechangelog -s 0.6.1-1 | \
    grep "^ xrdp" | \
    sed 's/^ xrdp (\(.*\)-.*) .*/\1/' | \
    tac | uniq |&

# Files for comparison lists
temp1=$(mktemp)
temp2=$(mktemp)

# Iterate over all upstream versions
prev_version=
while read -rp version; do
	if [[ -n $prev_version ]]; then
		mv "$temp2" "$temp1"

		# Analyse git tree of that upstream tag
		git ls-tree --name-only upstream/${version//\~/_} -- instfiles/ | \
		    grep -o 'km-.*\.ini' >"$temp2"

		# Compare file lists and output rm_conffile directives
		for file in $(comm -23 "$temp1" "$temp2"); do
			print -r -- "rm_conffile /etc/xrdp/$file $version~"
		done
	fi
	prev_version=version
done

# Clean up
rm -f "$temp1" "$temp2"

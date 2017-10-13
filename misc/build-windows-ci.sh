#!/bin/bash -e

# Intended to be used to build a Windows-native version on some Linux CI
(
cd $(dirname $0)/..
# we're now in the root: parent of the script dir.

OUTDIR=edid-decode-built

echo "Rebuild the app"
echo
make clean "$@"
make "$@"

echo "Creating output directory $OUTDIR and copying files"
rm -rf $OUTDIR
mkdir -p $OUTDIR
export FULL_OUTDIR="$(cd ${OUTDIR} && pwd)"
echo "  - full path: ${FULL_OUTDIR}"
echo
cp edid-decode.c $OUTDIR
cp edid-decode $OUTDIR/edid-decode.exe

cat misc/edid-txt.cmd | todos > $OUTDIR/edid-decode.html

echo "Rebuild the manpage HTML"
echo
groff -mandoc edid-decode.1 -T html > $OUTDIR/edid-decode.html

echo "Build the readme HTML"
echo
if [ "x$MARKDOWN" != "x" ] && which markdown > /dev/null; then
    markdown README.md > $OUTDIR/README.html
else
    # "Format" readme by appending markdeep footer
    cat README.md misc/markdeep-footer > $OUTDIR/README.html
    cp misc/markdeep.min.js $OUTDIR
    cat misc/markdeep-license.txt | todos > $OUTDIR/markdeep-license.txt
fi

echo "Update the version text file"
echo

VER=$(git describe --long --match "fork-point*")
echo "$VER" > $OUTDIR/version.txt

FORK_POINT_NUM=$(echo "$VER" | sed -E 's/^fork-point-([0-9]+)-.*/\1/')
COMMITS_SINCE=$(echo "$VER" | sed -E 's/^fork-point-[0-9]+-([0-9]+).*/\1/')
COMMIT_HASH=$(echo "$VER" | sed -E 's/^fork-point-[0-9]+-[0-9]+-g([0-9a-f]+)/\1/')


echo "Generate bintray descriptor"
echo
cat > bintray.json <<EOS
{
    /* Bintray package information.
       In case the package already exists on Bintray, only the name, repo and subject
       fields are mandatory. */

    "package": {
        "name": "edid-decode",
        "repo": "edid-decode-windows",
        "subject": "rpavlik"
    },

    /* Package version information.
       In case the version already exists on Bintray, only the name fields is mandatory. */

    "version": {
        "name": "${VER}",
        "desc": "Automated build/version: Commit with hash ${COMMIT_HASH}, which is ${COMMITS_SINCE} since fork point number ${FORK_POINT_NUM}",
        //"released": "2015-01-04",
        "vcs_tag": "${COMMIT_HASH}",
        "gpgSign": false
    },

    "files":
        [
        {"includePattern": "edid-decode-built/(.*)", "uploadPattern": "/$1"}
        ],
    "publish": true
}
EOS

echo "Contents of output directory:"
ls -la $OUTDIR
)
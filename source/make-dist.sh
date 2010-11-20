#!/bin/bash

# Create diaspora distribution tarballs.
#
# Usage: See  function usage() at bottom.
#
GIT_REPO='http://github.com/diaspora/diaspora.git'
VERSION='0.0'

. ./funcs.sh

function build_git_gems()
# Usage: build_git_gems <Gemfile> <tmpdir> <gemdir>
# Horrible hack, in wait for bundler handling git gems OK.
{
    [ -d 'gem-tmp' ] || mkdir gem-tmp
    cd gem-tmp
    rm -rf *

    grep 'git:'  ../$1 |  sed 's/,/ /g' | awk '
       /^.*git:\/\/.*$/  {
                    gsub( "=>", " ")
                    if ( $1 != "gem") {
                          print "Strange git: line (ignored) :" $0
                          next
                    }
                    name = $2
                    url=""
                    for (i = 3; i <= NF; i += 1) {
                        key = $i
                        i += 1
                        if (key == ":git")
                            url = $i
                    }
                    cmd = sprintf( "git clone --bare --quiet %s", url)
                    print "Running: ", cmd
                    system( cmd)
                }'

    mv devise-mongo_mapper.git devise-mongo_mapper

    # See https://github.com/collectiveidea/devise-mongo_mapper/issues/issue/1
    # Patch gemspeces which don't Dir.glob() their content.
    git clone --quiet devise-mongo_mapper d-m_m > /dev/null
    cd d-m_m
        sed -i "s/\['README.md'\]/Dir.glob('README.md')/" \
            devise-mongo_mapper.gemspec
        git commit --quiet -a -m "make-dist.sh: Fixing file paths"
        git push --quiet origin master
    cd ..
    rm -rf d-m_m

    git clone --quiet em-websocket e-w > /dev/null
    cd e-w
        sed  -i -e '/s\..*files/,/\]/s/\("[^"]*"\)/Dir.glob(\1)/g' \
                -e '/s\..*files/,/\]/s/\[//g'                      \
                -e '/s\..*files/,/\]/s/,/ + /g'                    \
                -e '/s\..*files/,/\]/s/\]//g'                      \
                em-websocket.gemspec
        git commit --quiet -a -m "make-dist.sh: Fixing file paths"
        git push --quiet origin master
    cd ..
    rm -rf e-w

    for dir in *; do
        if  [ ! -e  $dir/*.gemspec ]; then
            cp -ar $dir ../$2
        fi
    done
    cd ..
    # rm -rf gem-tmp
}

function make_src
# Create a distribution tarball
# Usage:  make src  <commit>
{
    echo "Using repo:          $GIT_REPO"
    commit=$(checkout ${1:-'HEAD'})
    echo "Commit id:           $commit"

    if [[ "$TAGGED_REL" = 'true' ]]; then
        RELEASE_DIR="diaspora-$VERSION-$1"
    else
        RELEASE_DIR="diaspora-$VERSION-$commit"
    fi
    rm -rf dist/${RELEASE_DIR}
    mkdir dist/${RELEASE_DIR}
    cd dist
        mkdir ${RELEASE_DIR}/master
        cp -ar diaspora/*  diaspora/.git* ${RELEASE_DIR}/master
        (
             cd  ${RELEASE_DIR}/master
             rm -rf vendor/bundle/* vendor/git/* vendor/cache/* gem-tmp
             git show --name-only > config/gitversion
             tar czf public/source.tar.gz  \
                 --exclude='source.tar.gz' -X .gitignore *
             find $PWD  -name .git\* | xargs rm -rf
             rm -rf .bundle
             /usr/bin/patch -p1 -s <../../../add-bundle.diff
        )
        tar czf ${RELEASE_DIR}.tar.gz  ${RELEASE_DIR} && \
            rm -rf ${RELEASE_DIR}
    cd ..
    echo "Source:              dist/${RELEASE_DIR}.tar.gz"
    echo "Required bundle:     $(git_id dist/diaspora/Gemfile)"
}

function make_docs()
{
    local gems=$1
    local dest=$2

    for gem in $(ls $gems); do
        local name=$(basename $gem)
        [ -r "$gems/$gem/README*" ] && {
             local readme=$(basename $gems/$gem/README*)
             cp  -a $gems/$gem/$readme $dest/$readme.$name
        }
        [ -r "$gems/$gem/COPYRIGHT" ] && \
             cp -a $gems/$gem/COPYRIGHT $dest/COPYRIGHT.$name
        [ -r "$gems/$gem/LICENSE" ] && \
             cp -a $gems/$gem/LICENSE $dest/LICENSE.$name
        [ -r "$gems/$gem/License" ] && \
             cp -a $gems/$gem/License $dest/License.$name
        [ -r "$gems/$gem/MIT-LICENSE" ] && \
             cp -a $gems/$gem/MIT-LICENSE $dest/MIT-LICENSE.$name
        [ -r "$gems/$gem/COPYING" ] && \
             cp -a $gems/$gem/COPYING $dest/COPYING.$name
    done
}


function make_bundle()
# Create the bundle tarball
# Usage:  make_bundle [ commit, defaults to HEAD]
#
{
    checkout ${1:-'HEAD'} >/dev/null
    local bundle_id=$( git_id dist/diaspora/Gemfile)
    if [[ "$TAGGED_REL" = 'true' ]]; then
        local bundle_name="diaspora-bundle-$VERSION-$1"
    else
        local bundle_name="diaspora-bundle-$VERSION-$bundle_id"
    fi

    test -e  "dist/$bundle_name.tar.gz" || {
        echo "Creating bundle $bundle_name"
        cd dist
            rm -rf $bundle_name
            cd diaspora
                rm Gemfile.lock
                rm -rf .bundle
                if [ "$BUNDLE_FIX" = 'yes' ]; then
                    bundle update
                fi

                [ -d 'git-repos' ] || mkdir  git-repos
                rm -rf git-repos/*
                git checkout Gemfile
                build_git_gems  Gemfile git-repos
                sed -i  's|git://.*/|git-repos/|g' Gemfile
                # see: http://bugs.joindiaspora.com/issues/440
                bundle install --path=vendor/bundle  || {
                    bundle install --path=vendor/bundle || {
                        echo "bundle install failed, giving up" >&2
                        exit 3
                    }
                }
                bundle package

                mkdir  -p "../$bundle_name/docs"
                mkdir -p "../$bundle_name/vendor"
                cp -ar AUTHORS Gemfile Gemfile.lock GNU-AGPL-3.0 COPYRIGHT \
                    ../$bundle_name

                make_docs "vendor/bundle/ruby/1.8/gems/"  "../$bundle_name/docs"
                mv vendor/cache   ../$bundle_name/vendor
                mv vendor/gems    ../$bundle_name/vendor
                mv vendor/plugins ../$bundle_name/vendor
                mv git-repos      ../$bundle_name
                git checkout Gemfile
            cd ..
            tar czf $bundle_name.tar.gz $bundle_name
            mv $bundle_name/vendor/cache diaspora/vendor/cache
        cd ..
    }
    echo
    echo "Bundle: dist/$bundle_name.tar.gz"
}

function usage()
{
        cat <<- EOF

	Usage: make-dist [options]  <dist|bundle>

	Options:

	-h             Print this message.
	-c  commit     Use a given commit, defaults to last checked in.
	-t  tag        Use a tag instead of date_commit tarball name.
	-v  version    Use a given version, defaults to 0.0
	-u  uri        Git repository URI, defaults to
	               $GIT_REPO.
	-f             For bundle, fix dependencies by running 'bundle update'
	               before 'bundle install'

	source         Build a diaspora application tarball.
	bundle         Build a bundler(1) bundle for diaspora.

	All results are stored in dist/

	EOF
}


commit='HEAD'
BUNDLE_FIX='no'
while getopts ":c:u:v:t:fh" opt
do
    case $opt in
        u)   GIT_REPO="$OPTARG"
             ;;
        v)   VERSION="$OPTARG"
             ;;
        c)   commit="${OPTARG:0:7}"
             ;;
        t)   tag="$OPTARG"
             ;;
        f)   BUNDLE_FIX='yes'
             ;;
        h)   usage
             exit 0
             ;;
        *)   usage
             exit 2
             ;;
    esac
done
shift $(($OPTIND - 1))


test $# -gt 1 -o $# -eq 0 && {
    usage;
    exit 2;
}

if [[ -n "$tag" &&  "$commit" != 'HEAD' ]]; then
    echo "Use either -t or -c."
    exit 2
fi

TAGGED_REL=""
if [[ -n "$tag" ]]; then
    TAGGED_REL="true"
    commit=$tag
fi

typeset -r GIT_REPO  BUNDLE_FIX VERSION TAGGED_REL
export LANG=C

echo $PATH | grep -q '.rvm'  && {
    cat <<- EOF
	WARNING: Your PATH contains .rvm entries which might cause
	all sort of trouble. You have been warned!
	EOF
}

case $1 in

    "bundle")  make_bundle $commit $BUNDLE_FIX
               ;;
    'source')  make_src $commit
               ;;
           *)  usage
               exit 1
               ;;
esac




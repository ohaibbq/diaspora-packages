#
# Common stuff for pkg scripts
#

function git_id
#
# Echo package-friendly source id.
#
# Usage: git_id [-n] [file or directory]
#
{
    local nl="\n"
    local file_or_dir="$PWD"
    test "$1" = '-n' && { nl=""; shift; }
    test -n "$1" && file_or_dir="$1"
    if [ -d $file_or_dir ]; then
        local file=""
        local dir=$file_or_dir
    else
        local file=$(basename $file_or_dir)
        local dir=$(dirname $file_or_dir)
    fi

    (
        cd $dir
        git log -1 --abbrev-commit --date=iso $file |
            awk  -v nl="$nl" \
               ' BEGIN         { commit = ""; d[1] = "" }
                /^commit/      { if ( commit ==  "") commit = $2 }
                /^Date:/       { if (d[1] == "") {
                                     split( $2, d, "-")
                                     split( $3, t, ":")
                                 }
                               }
                END            { printf( "%s%s%s%s%s_%s%s",
                                     substr( d[1],3), d[2], d[3],
                                     t[1], t[2],
                                     commit, nl)
                               }'
    )
}


function checkout()
# Checkout last version of diaspora unless it's already there.
# Uses global GIT_REPO   to determine repo url.
# Usage: checkout [commit id, defaults to HEAD]
# Returns: commit for current branch's HEAD.
{
    mkdir dist  &>/dev/null || :
    (
        local last_repo=''
        cd dist

        test -e '.last-repo' &&
            last_repo=$( cat '.last-repo')
        test  "$last_repo" != $GIT_REPO &&
            rm -rf diaspora
        test -d diaspora || {
            git clone --quiet $GIT_REPO;
            cd diaspora
                git submodule --quiet update --init pkg &>/dev/null
            cd ..
            for p in ../../*.patch; do
                git apply --whitespace=fix  $p  > /dev/null
            done &> /dev/null || :
        }
        echo -n "$GIT_REPO" > .last-repo

        cd diaspora;
        git checkout --quiet Gemfile Gemfile.lock
        git pull --quiet --tags origin master
        [ -n "$1" ] && git reset --hard  --quiet  $1
        git_id  -n
    )
}


#
# Best effort external hostname, defaults to local hostname.
#
function get_hostname
{
    local hostname=$(hostname) || hostname="localhost.localdomain"
    local url
    for url in 'http://checkip.dyndns.org' 'http://ekiga.net/ip/'
    do
        if wget -O ip -T 10 -q  $url; then
            local ip_addr=$(egrep -o '[0-9.]+' ip) || continue

            if local new_hostname=$( host $ip_addr) ; then
                new_hostname="${new_hostname##*domain name pointer}"
                break
            fi
        fi
    done
    rm -f ip
    echo -n ${new_hostname:-$hostname}
}


function init_appconfig
# Edit pod_url in hostname
# Silently uses hostname argument if present, else runs dialog.
# Usage: init_appconfig <app_config.yml> [hostname]
{
    config=$1
    local arg_hostname="$2"
    local curr_hostname=$( awk '/pod_url:/ { print $2; exit }' <$config )

    if [ -n "$arg_hostname" ]; then
        sed -i "/pod_url:/s|$curr_hostname|$arg_hostname|g" $config && \
            echo "config/app_config.yml updated, pod_url is $arg_hostname."
        return 0
    else
        ext_hostname=$( get_hostname)
        while : ; do
            echo "Current hostname is \"$curr_hostname\""
            echo -n "Enter new hostname [$ext_hostname] :"
            read new_hostname garbage
            [ -z "$new_hostname" ] && new_hostname="$ext_hostname"
            echo -n "Use \"$new_hostname\" as pod_url (Yes/No) [Yes]? :"
            read yesno garbage
            [ "${yesno:0:1}" = 'y' -o "${yesno:0:1}" = 'Y' -o -z "$yesno" ] && {
                sed -i "/pod_url:/s|$hostname|$new_hostname|g" $config &&
                    echo "config/app_config.yml updated."
                break
            }
        done
    fi
}

function init_public
# Create all dynamically generated files in public/ folder
{
    bundle exec thin \
         -d --pid log/thin.pid --address localhost --port 3000 \
         start
    for ((i = 0; i < 20; i += 1)) do
        sleep 2
        wget -q -O server.html http://localhost:3000 && \
            rm server.html && break
    done
    bundle exec thin --pid log/thin.pid stop
    if [ -e server.html ]; then
        echo "Cannot get index.html from web server (aborted)" >&2
        return 2
    fi
    bundle exec jammit
}


#!/bin/bash
# -*- coding: utf-8 -*-
#{
# Copyright 2018 Samsung Electronics France SAS
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with the
#    distribution.
# 3. Neither the name NuttX nor the names of its contributors may be
#    used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
# OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
# AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#}

set -e
set -x

env_()
{
    project="tizenrt"
    org="Samsung"
    branch="master"
    url_suffix="#${branch}"

    #{TODO: Update here if needed
    user="rzr"
    org="${user}"
    #branch="sandbox/${user}/devel/${branch}"
    #url_suffix="#${branch}"
    url_suffix="" # TODO: For older docker
    #}

    url="https://github.com/${org}/${project}.git${url_suffix}"
    run_url="https://raw.githubusercontent.com/${org}/${project}/${branch}/run.sh"
    release="0.0.0"

    src=false
    if [ -d '.git' ] && which git > /dev/null 2>&1 ; then
        src=true
        branch=$(git rev-parse --abbrev-ref HEAD) ||:
        release=$(git describe --tags || echo "$release")
    fi

    SELF="$0"
    [ "$SELF" != "$SHELL" ] || SELF="${PWD}/run.sh"
    [ "$SELF" != "/bin/bash" ] || SELF="${DASH_SOURCE}"
    [ "$SELF" != "/bin/bash" ] || SELF="${BASH_SOURCE}"
    self_basename=$(basename -- "${SELF}")
}


usage_()
{
    cat<<EOF
Usage:
$0
or
curl -sL "${run_url}" | bash -

EOF
}


die_()
{
    errno=$?
    echo "error: [$errno] $@"
    exit $errno
}


debian_install_()
{
    which sudo || su -c 'apt-get install -y sudo'
    sudo groups "${USER}" | grep sudo || su -c "addgroup ${USER} sudo"
    sudo groups "${USER}" | grep sudo || die_ "Please type: su -l $USER and run script again"
    sudo apt-get install -y "$@"
}


debian_setup_()
{
    git version || debian_install_ -y git
    docker version || debian_install_ docker.io
}


setup_()
{
    docker version && return $? ||:

    if [ -r /etc/debian_version ] ; then
        debian_setup_
    else
        cat<<EOF
warning: OS not supported
Please ask for support at:
${url}
EOF
        cat /etc/os-release ||:
    fi

    docker version && return $? ||:
    docker --version || die_ "please install docker"
    groups | grep docker \
        || sudo addgroup ${USER} docker \
        || die_ "${USER} must be in docker group"
    su -l $USER -c "docker version" \
        && { su -l $USER -c "$SHELL $SELF $@" ; exit $?; } \
        || die_ "unexpected error"
}


prep_()
{
    echo "Prepare: "
    cat /etc/os-release
    docker version || setup_
}


build_()
{
    version="latest"
    outdir="${PWD}/tmp/out"
    container="${project}"
    branch_name=$(echo "${branch}" | sed -e 's|/|.|g')
    dir="/usr/local/src/${project}/"
    image="${user}/${project}/${branch}"
    tag="$image:${version}"
    tag="${project}:${branch_name}"
    tag="${project}:${branch_name}.${release}"
    container="${project}"
    if $src && [ "run.sh" = "${self_basename}" ] ; then
        docker build -t "$tag" .
    else
        docker build -t "$tag" "${url}"
    fi
    docker rm "${container}" > /dev/null 2>&1 ||:
    docker create --name "${container}" "${tag}" /bin/true
    rm -rf "${outdir}"
    mkdir -p "${outdir}"
    docker cp "${container}:${dir}" "${outdir}"
    echo "Check Ouput files in:"
    ls "${outdir}/"*
}


test_()
{
    curl -sL "${run_url}" | bash -
}


main_()
{
    env_ "$@"
    usage_ "$@"
    prep_ "$@"
    build_ "$@"
}


main_ "$@"

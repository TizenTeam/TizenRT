#!/bin/bash
# -*- coding: utf-8 -*-
#{
# Copyright 2018 Samsung Electronics France SAS
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#}

set -e
set -x

env_()
{
    project="iotjs"
    org="Samsung"
    branch="master"
    url_suffix="#{branch}"

    # user="rzr" # Update here if forking
    org="TizenTeam"
    # branch="sandbox/${user}/${branch}"
    # url_suffix="#{branch}"
    url_suffix="" # TODO: For older docker

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


setup_debian_()
{
    which docker || sudo apt-get install docker.io
    which git || sudo apt-get install git

    sudo apt-get install qemu qemu-user-static binfmt-support
    sudo update-binfmts --enable qemu-arm
}


setup_()
{
    docker version && return $? ||:

    if [ -r /etc/debian_version ] ; then
        setup_debian_
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
    container=$(echo "${container}" | sed -e 's|/|-|g')
    if $src && [ "run.sh" = "${self_basename}" ] ; then
        docker build -t "${tag}" .
    else
        docker build -t "${tag}" "${url}"
    fi
    docker rm "${container}" > /dev/null 2>&1 ||:
    docker create --name "${container}" "${tag}" /bin/true
    rm -rf "${outdir}"
    mkdir -p "${outdir}"
    docker cp "${container}:${dir}" "${outdir}"
    echo "Check Ouput files in:"
    ls "${outdir}/"*
    find "${outdir}" -iname "*.deb"
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

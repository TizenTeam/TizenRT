#{
devel/webthings: ${contents_dir}/webthing-node
	ls $<

${contents_dir}/webthing-node: ${HOME}/mnt/webthing-node/ ${devel_self}
	rsync -avx "$</" "$@/"
	rm -rf "$@/.git"
	rm -rf "$@/node_modules"

contents: devel/webthings
#}

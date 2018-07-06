
iotjs_modules_url=https://github.com/tizenteam/iotjs
iotjs_modules_branch?=sandbox/rzr/air-lpwan-demo/master
demo_dir?=external/iotjs_modules/air-lpwan-demo
private_dir?=${demo_dir}/private
#demo_dir?=.

${demo_dir}:
	mkdir -p ${@D}
	git clone -b ${iotjs_modules_branch} ${iotjs_modules_url} $@

${demo_dir}/%: ${demo_dir}
	ls $@

prep_files+=${demo_dir}
prep_files+=${demo_dir}/index.js


${demo_dir}/private/config.js: ${demo_dir}/config.js
	@mkdir -p ${@D}
	cp -av $< $@

devel/private:
	@mkdir -p ${demo_dir}/private
	rsync -avx ${HOME}/backup/${CURDIR}/${private_dir}/ ${private_dir}/ || echo "TODO"
	ls ${private_dir} 

private/rm:
	rm -rf ${CURDIR}/${demo_dir}/private


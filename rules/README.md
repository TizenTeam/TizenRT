# Build: #

    cd ~/mnt/TizenRT
    make devel/contents
    cd externalwebthing-node
    if [ ! -d mastodon-lite ] ; then
        npm install mastodon-lite
        cp -rfa node_modules/mastodon-lite .
    fi
    rm  tools/fs/contents/webthing-node/.mastodon-lite.json 
    cat ~/.mastodon-lite-tizenhelper.json >  tools/fs/contents/webthing-node/.mastodon-lite.json 
    make run

# Usage: #

    ifconfig ; wifi startsta ; wifi join $ssid $pass ; ifconfig wl1 dhcp ; ifconfig
    cd /rom/webthing-node ; iotjs example/artik05x-thing.js

    cat ~/.mastodon-lite-tizenhelper.json >  tools/fs/contents/webthing-node/.mastodon-lite.json 
    cd /rom/webthing-node ; iotjs example/mastodon-thing.js 8042


# Resources: #

* https://wiki.tizen.org/User:Pcoval
* https://s-opensource.org/author/philcovalsamsungcom/


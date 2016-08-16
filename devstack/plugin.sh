#!/usr/bin/env bash
# Copyright 2016 Massachusetts Open Cloud
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

PROXY_FILES=$DEST/proxy
PROXY_CONF=/etc/k2k-proxy.conf

function install_proxy {
    cd $PROXY_FILES
    sudo python setup.py install
    sudo cp etc/k2k-proxy.conf $PROXY_CONF
}


function configure_proxy {
    cd $PROXY_FILES

    # Nova
    iniset $NOVA_CONF glance api_servers "http://localhost:$PROXY_PORT/image"

    # Cinder
    iniset $CINDER_CONF glance_api_servers "http://localhost:$PROXY_PORT/image"
    iniset $CINDER_CONF oslo_messaging_notifications driver messaging
    iniset $CINDER_CONF oslo_messaging_notifications topics notifications

    # Glance
    iniset $GLANCE_CONF oslo_messaging_notifications driver messaging
    iniset $CINDER_CONF oslo_messaging_notifications topics notifications

    # Proxy
    iniset $PROXY_CONF proxy port $PROXY_PORT

    # TODO: Use DevStack installed MySQL
    iniset $PROXY_CONF keystone auth_url "http://localhost:5000/v3"
    iniset $PROXY_CONF keystone username admin
    iniset $PROXY_CONF keystone user_domain_id default
    iniset $PROXY_CONF keystone project_name admin
    iniset $PROXY_CONF keystone project_domain_id default
    iniset $PROXY_CONF keystone password $ADMIN_PASSWORD

    iniset $PROXY_CONF proxy service_providers default

    iniset $PROXY_CONF sp_default sp_name default
    iniset $PROXY_CONF sp_default auth_url "http://localhost:5000/v3"
    iniset $PROXY_CONF sp_default image_endpoint "http://localhost:9292"
    iniset $PROXY_CONF sp_default volume_endpoint "http://localhost:8776"

    # TODO(knikolla): plug this in with the DevStack plugin for Keystone
    # so that it registers the service provider this is registered with it.
}


function run_proxy {
    cd $PROXY_FILES

    # Configure the endpoints in the service catalog
    python -m devstack.create_endpoints

    # Run the proxy in a screen window
    run_process proxy "$PROXY_FILES/run_proxy.sh"

    # Todo: Run the listener in another screen window
}


function uninstall_proxy {
    sudo pip uninstall k2k-proxy
}

if [[ "$1" == "stack" && "$2" == "install" ]]; then
    install_proxy
elif [[ "$1" == "stack" && "$2" == "post-config" ]]; then
    configure_proxy
elif [[ "$1" == "stack" && "$2" == "extra" ]]; then
    run_proxy
fi

if [[ "$1" == "unstack" ]]; then
    :
fi

if [[ "$1" == "clean" ]]; then
        uninstall_proxy
fi

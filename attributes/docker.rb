default[:docker][:allow_incoming_connections] = true
default[:docker][:port] = 4243
default[:docker][:enable_ufw] = true
default[:docker][:ufw_path] = '/etc/default/ufw'
default[:docker][:bin] = '/usr/bin/docker'

default[:docker][:user] = 'deployer'

default[:docker][:src] = '/etc/docker'

default[:docker][:installs] = {}
default[:docker][:builds] = {}
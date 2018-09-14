![latest 0.1.0](https://img.shields.io/badge/latest-0.1.0-green.svg?style=flat)
[![license](https://img.shields.io/github/license/speto/nginx-proxy-helper.svg?maxAge=2592000)](https://opensource.org/licenses/MIT)

# Nginx Proxy Helper

Simple tool to connect all nginx containers to a single network with [nginx-proxy](https://github.com/jwilder/nginx-proxy) automated Nginx Reverse Proxy for Docker.  

## Install

Download via

```shell
git clone https://github.com/speto/nginx-proxy-helper
```

## Usage

Start some example dummy nginx containers from multiple compose files targeting to the sample html index files:

```shell
$ cd ./example
$ docker-compose up -d
Creating network "nginx-proxy-helper-example_default" with the default driver
Creating symfony-demo_nginx_1  ... done
Creating symfony-demo2_nginx_1 ... done
Creating project_nginx_1       ... done
```

Run `./nginx-proxy-helper.sh` shell script to create network, nginx-proxy container and connect all nginx containers:

```shell
$ ./nginx-proxy-helper.sh
Running nginx proxy container nginx-proxy on port 80
ee1e18cf9293ac52d6a040a4c3ac9e087759228562606a6c8d5e68c51fd963c2
Creating nginx proxy network: nginx-proxy-network
b8168727b7446c2c8ed3dcd0c25030d85d1b1e5e82fdf7666834e3d8a9c237ec
Connecting nginx-proxy to nginx-proxy-network
Connecting project_nginx_1 to nginx-proxy-network
Restarting project_nginx_1
Connecting symfony-demo2_nginx_1 to nginx-proxy-network
Restarting symfony-demo2_nginx_1
Connecting symfony-demo_nginx_1 to nginx-proxy-network
Restarting symfony-demo_nginx_1
```

Finally test if everything works.  
Let's assume a local dns server like [dnsmasq](https://gist.github.com/eloypnd/5efc3b590e7c738630fdcf0c10b68072) with configuration line `address=/localhost/127.0.0.1` in `dnsmasq.conf` for resolving  all `*.localhost` requests to `127.0.0.1`.  
Or entry line like `127.0.0.1 project.localhost` in our `/etc/hosts`.  
Then just use modern command line HTTP client [httpie](https://httpie.org/) and request:
```shell
$ http project.localhost
HTTP/1.1 200 OK
Accept-Ranges: bytes
Connection: keep-alive
Content-Length: 16
Content-Type: text/html
Server: nginx/1.14.0

<h1>Project</h1>
```

Or open [project.localhost](http://project.localhost/) in a browser.

### Docker-compose services example

[./example/docker-compose-project.yml](./example/docker-compose-project.yml)
```yaml
services:
  project_nginx:
    container_name: project_nginx_1
    image: nginx:alpine
    volumes:
      - ./html/project.html:/usr/share/nginx/html/index.html:ro
    environment:
      - VIRTUAL_HOST=project.localhost
```

[./example/docker-compose-symfony-demo.yml](./example/docker-compose-symfony-demo.yml)
```yaml
services:
  symfony-demo_nginx:
    container_name: symfony-demo_nginx_1
    image: nginx:alpine
    volumes:
    - ./html/symfony-demo.html:/usr/share/nginx/html/index.html:ro
    environment:
    - VIRTUAL_HOST=symfony-demo.localhost
```

[./example/html/project.html](./example/html/project.html)
```html
<h1>Project</h1>
```

## Customize

It is easy to extend via your own .env file.  
Just `cp .env.dist .env` and edit variables. 

```dotenv
NGINX_PROXY_NETWORK=nginx-proxy-network
NGINX_PROXY_CONTAINER_NAME=nginx-proxy
NGINX_PROXY_EXPOSED_PORT=80
NGINX_PROXY_IMAGE_NAME=jwilder/nginx-proxy
NGINX_CONTAINER_NAME_PATTERN=nginx #pattern for docker ps filtering
```

### MIT license

Copyright (c) 2018, Štefan Peťovský
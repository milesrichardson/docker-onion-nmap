## docker-onion-nmap

Use nmap to scan hidden "onion" services on the Tor network. Minimal image
based on alpine, using proxychains to wrap nmap. Tor and dnsmasq are run
as daemons via s6, and proxychains wraps nmap to use the Tor SOCKS proxy on port 9050. Tor is also configured via [DNSPort](https://www.torproject.org/docs/tor-manual.html.en#DNSPort) to anonymously resolve DNS requests to port 9053. dnsmasq is configured to with this localhost:9053 as an authority DNS server. Proxychains is configured to proxy DNS through the local resolver, so all DNS requests will go through Tor and applications can resolve .onion addresses.

### Example:

``` bash
$ docker run --rm -it milesrichardson/onion-nmap -p 80,443 facebookcorewwwi.onion
[tor_wait] Wait for Tor to boot... (might take a while)
[tor_wait] Done. Tor booted.
[nmap onion] nmap -p 80,443 facebookcorewwwi.onion
[proxychains] config file found: /etc/proxychains.conf
[proxychains] preloading /usr/lib/libproxychains4.so
[proxychains] DLL init: proxychains-ng 4.12

Starting Nmap 7.60 ( https://nmap.org ) at 2017-10-23 16:17 UTC
[proxychains] Dynamic chain  ...  127.0.0.1:9050  ...  facebookcorewwwi.onion:443  ...  OK
[proxychains] Dynamic chain  ...  127.0.0.1:9050  ...  facebookcorewwwi.onion:80  ...  OK
Nmap scan report for facebookcorewwwi.onion (224.0.0.1)
Host is up (2.7s latency).

PORT    STATE SERVICE
80/tcp  open  http
443/tcp open  https

Nmap done: 1 IP address (1 host up) scanned in 3.58 seconds
```

### How it works:

When the container boots, it launches Tor and dnsmasq as daemons. The `tor_wait`
script then waits for the Tor SOCKS proxy to be up before executing your command.

### Arguments:

By default, args to `docker run` are passed to [/bin/nmap](/bin/nmap)
which calls nmap with args `-sT -PN -n "$@"` necessary for it to work over Tor ([via explainshell.com](https://explainshell.com/explain?cmd=nmap+-sT+-PN+-n)).

For example, this:

``` bash
docker run --rm -it milesrichardson/onion-nmap -p 80,443 facebookcorewwwi.onion
```

will be executed as:

``` sh
proxychains4 -f /etc/proxychains.conf /usr/bin/nmap -sT -PN -n -p 80,443 facebookcorewwwi.onion
```

In addition to the custom script for `nmap`, custom wrapper scripts for `curl`
and `nc` exist to wrap them in proxychains, at [/bin/curl](/bin/curl)
and [/bin/nc](/bin/nc). To call them, simply specify `curl` or `nc`
as the first argument to `docker run`. For example:

``` bash
docker run --rm -it milesrichardson/onion-nmap nc -z 80 facebookcorewwwi.onion
```

will be executed as:

``` bash
proxychains4 -f /etc/proxychains.conf /usr/bin/nc -z 80 facebookcorewwwi.onion
```

and

``` bash
docker run --rm -it milesrichardson/onion-nmap curl -I https://facebookcorewwwi.onion
```

will be executed as:

```
proxychains4 -f /etc/proxychains.conf /usr/bin/curl -I https://facebookcorewwwi.onion
```

If you want to call any other command, including the original `/usr/bin/nmap` or
`/usr/bin/nc` or `/usr/bin/curl` you can specify it as the first argument to docker run, e.g.:

``` bash
docker run --rm -it milesrichardson/onion-nmap /usr/bin/curl -x socks4h://localhost:9050 https://facebookcorewwwi.onion
```

### Environment variables:

There is only one environment variable: `DEBUG_LEVEL`. If you set it to
anything other than `0`, more debugging info will be printed (specifically,
the attempted to connections to Tor while waiting for it to boot). Example:

``` bash
$ docker run -e DEBUG_LEVEL=1 --rm -it milesrichardson/onion-nmap -p 80,443 facebookcorewwwi.onion
[tor_wait] Wait for Tor to boot... (might take a while)
[tor_wait retry 0] Check socket is open on localhost:9050...
[tor_wait retry 0] Socket OPEN on localhost:9050
[tor_wait retry 0] Check SOCKS proxy is up on localhost:9050 (timeout 2 )...
[tor_wait retry 0] SOCKS proxy DOWN on localhost:9050, try again...
[tor_wait retry 1] Check socket is open on localhost:9050...
[tor_wait retry 1] Socket OPEN on localhost:9050
[tor_wait retry 1] Check SOCKS proxy is up on localhost:9050 (timeout 4 )...
[tor_wait retry 1] SOCKS proxy DOWN on localhost:9050, try again...
[tor_wait retry 2] Check socket is open on localhost:9050...
[tor_wait retry 2] Socket OPEN on localhost:9050
[tor_wait retry 2] Check SOCKS proxy is up on localhost:9050 (timeout 6 )...
[tor_wait retry 2] SOCKS proxy UP on localhost:9050
[tor_wait] Done. Tor booted.
[nmap onion] nmap -p 80,443 facebookcorewwwi.onion
[proxychains] config file found: /etc/proxychains.conf
[proxychains] preloading /usr/lib/libproxychains4.so
[proxychains] DLL init: proxychains-ng 4.12

Starting Nmap 7.60 ( https://nmap.org ) at 2017-10-23 16:34 UTC
[proxychains] Dynamic chain  ...  127.0.0.1:9050  ...  facebookcorewwwi.onion:443  ...  OK
[proxychains] Dynamic chain  ...  127.0.0.1:9050  ...  facebookcorewwwi.onion:80  ...  OK
Nmap scan report for facebookcorewwwi.onion (224.0.0.1)
Host is up (2.8s latency).

PORT    STATE SERVICE
80/tcp  open  http
443/tcp open  https

Nmap done: 1 IP address (1 host up) scanned in 4.05 seconds
```

### Notes:

- No UDP available over Tor
- Tor can take 10-20 seconds to boot. If this is untenable, another option is to run the proxy in its own container, or run it as the main process and then run "exec" to call commands like nmap

### gr33tz:

- [@jessfraz](https://github.com/jessfraz) [tor-proxy](https://github.com/jessfraz/dockerfiles/tree/master/tor-proxy)
- [@zuazo](https://github.com/zuazo) [alpine-tor-docker](https://github.com/zuazo/alpine-tor-docker)
- [shellhacks](https://www.shellhacks.com/anonymous-port-scanning-nmap-tor-proxychains/)
- [crypto-rebels.de](https://www.crypto-rebels.de/scanhidden.html)

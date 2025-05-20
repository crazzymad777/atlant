module atlant.http.server;

import atlant.utils.configuration;

extern(C) void* run_server_instance(void* data)
{
    ServerInstance* instance = cast(ServerInstance*) data;
    // import core.stdc.stdio;
    // printf("%s : %d\n", instance.addr, instance.port);
    instance.serve();
    return null;
}

bool doWork = true;

extern (C) void termination_handler(int signum) nothrow @nogc
{
    import core.sys.posix.unistd;
    doWork = false;
}

import atlant.net.ipv6: normalize, normalize4to6;

struct ServerInstance
{
    private int sockfd = -1;
    int family;
    char* addr;
    int port;
    bool anyaddr;
    bool translated;
    debug bool logpid;

    int tryFamily(int V = 6)()
    {
        import core.sys.posix.sys.socket;
        family = V == 6 ? AF_INET6 : AF_INET;
        import core.sys.posix.netinet.in_;
        import core.sys.posix.unistd;

        import core.stdc.string;
        import core.stdc.stdio;
        import core.stdc.errno;

        static if (V == 6)
        {
        sockaddr_in6 servaddr;
        }
        else
        {
        sockaddr_in servaddr;
        }

        int sockfd = socket(family, SOCK_STREAM, 0);
        if (sockfd == -1)
        {
            perror("socket");
            return -1;
        }

        int v = 1;
        setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &v, int.sizeof);
        setsockopt(sockfd, SOL_SOCKET, SO_REUSEPORT, &v, int.sizeof);

        bool success = false;

        static if (V == 6)
        {
        servaddr.sin6_family = cast(ushort) family;
        servaddr.sin6_port = htons(cast(ushort) port);
        }
        else
        {
        servaddr.sin_family = cast(ushort) family;
        servaddr.sin_port = htons(cast(ushort) port);
        }

        if (addr is null)
        {
            static if (V == 6)
            {
                servaddr.sin6_addr = in6addr_any;
            }
            else
            {
                servaddr.sin_addr.s_addr = htonl(INADDR_ANY);
            }
            success = true;
            anyaddr = true;
        }

        if (!success)
        {
            static if (V == 6)
            {
                if (inet_pton(family, addr, &servaddr.sin6_addr) == 1)
                {
                    success = true;
                }
            }
            else
            {
                if (inet_pton(family, addr, &servaddr.sin_addr) == 1)
                {
                    success = true;
                }
            }
        }

        static if (V == 6)
        {
        if (!success)
        {
            if (inet_pton(AF_INET, addr, &servaddr.sin6_addr) == 1)
            {
                family = AF_INET; // actual family is IPv4
                translated = true;

                normalize4to6(&servaddr);
                success = true;
            }
        }
        }

        bool silent = false;

        if (!success)
        {
            import core.sys.posix.netdb;

            addrinfo* addrinfo;
            int result = getaddrinfo(addr, null, null, &addrinfo);

            if (result == 0)
            {
                int pid;
                while (addrinfo !is null)
                {
                    pid = fork();
                    if (pid == 0)
                    {
                        success = true;
                        silent = true;

                        static if (V == 6)
                        {
                            if (addrinfo.ai_family == AF_INET)
                            {
                                family = AF_INET; // actual family is IPv4
                                translated = true;
                                memcpy(&servaddr, &addrinfo.ai_addr, addrinfo.ai_addrlen);
                                normalize4to6(&servaddr);
                            }
                        }
                        break;
                    }

                    debug if (logpid) printf("%d: fork %d\n", getpid(), pid);
                    addrinfo = addrinfo.ai_next;
                    // i++;
                }

                if (pid != 0)
                {
                    import core.sys.posix.sys.wait;
                    debug if (logpid) printf("%d: wait\n", getpid());
                    while (wait(null) > 0) {}
                    debug if (logpid) printf("%d: continue\n", getpid());
                    return -2;
                }
            }
            else
            {
                perror("getaddrinfo");
            }
        }

        if (success)
        {
            if (bind(sockfd, cast(sockaddr*) &servaddr, servaddr.sizeof) != 0)
            {
                if (!silent) perror("bind");
                return -2;
            }

            if ((listen(sockfd, 0)) != 0)
            {
                if (!silent) perror("listen");
                return -2;
            }

            this.sockfd = sockfd;
            return 0;
        }
        return -2;
    }

    void serve()
    {
        import core.sys.posix.sys.socket;
        import core.sys.posix.unistd;
        import core.stdc.string;
        import core.stdc.stdio;
        import core.stdc.errno;

        int status = tryFamily!6();
        if (status == -1)
        {
            status = tryFamily!4();
            if (status < 0)
            {
                return;
            }
        }

        if (status != 0)
        {
            return;
        }

        // printf("signal: %d \n", getpid());
        import core.sys.posix.signal;
        if (signal(SIGINT, &termination_handler) == SIG_IGN)
        {
            signal(SIGINT, SIG_IGN);
        }

        int sockfd = this.sockfd;
        import core.sys.posix.sys.time;
        timeval timeout;
        timeout.tv_sec = 5;
        timeout.tv_usec = 0;
        setsockopt (sockfd, SOL_SOCKET, SO_RCVTIMEO, &timeout, timeout.sizeof);

        import core.sys.posix.netinet.in_;
        sockaddr_in6 clientaddr;
        uint addrlen;
        int pid = -1;
        debug if (logpid) printf("%d: accepting\n", getpid());
        while (doWork)
        {
            int conn = accept(sockfd, cast(sockaddr*) &clientaddr, &addrlen);
            if (conn == -1)
            {
                if (errno == EAGAIN || errno == EWOULDBLOCK || errno == ECONNABORTED || errno == EMFILE || errno == ENFILE || errno == ENOBUFS || errno == ENOMEM || errno == EPERM || errno == EPROTO)
                {
                    continue;
                }

                perror("accept");
                break;
            }
            else
            {
                import atlant.http.session;
                Session session = Session(conn);

                // What if server listen IPv4 mapped to IPv6 address?
                normalize(anyaddr, family, &clientaddr, translated);
                session.load(family, clientaddr);

                pid = session.spawn();
                if (pid == 0)
                {
                    break;
                }
                debug printf("%d: fork %d\n", getpid(), pid);
            }
        }

        if (pid != 0)
        {
            close(sockfd);
        }
    }
}

struct Server
{
    ServerInstance instance;

    void listen(Configuration* conf)
    {
        import core.sys.posix.sys.wait;
        import core.sys.posix.unistd;
        instance.port = conf.port;
        debug
        {
            instance.logpid = conf.logpid;
        }

        auto addrNodePort = conf.listOfPorts.front();
        if (conf.defaultBindAddresses)
        {

            if (addrNodePort !is null)
            {
                instance.port = addrNodePort.value;
            }

            instance.addr = null;
            run_server_instance(cast(void*) &instance);
        }
        else
        {
            auto addrNode = conf.listOfAddresses.front();
            int currentPort = conf.port;

            if (addrNodePort !is null)
            {
                currentPort = addrNodePort.value;
            }

            import core.stdc.stdio;
            while (addrNode !is null)
            {
                int pid = fork();
                if (pid == 0)
                {
                    instance.addr = addrNode.value;
                    instance.port = currentPort;
                    run_server_instance(cast(void*) &instance);
                    break;
                }
                debug if (conf.logpid) printf("%d: fork %d\n", getpid(), pid);
                addrNode = addrNode.next;

                if (addrNodePort !is null)
                {
                    if (addrNodePort.next !is null)
                    {
                        addrNodePort = addrNodePort.next;
                        currentPort = addrNodePort.value;
                    }
                }
            }

            debug if (conf.logpid) printf("%d: wait\n", getpid());
            while (wait(null) > 0) {}
            debug if (conf.logpid) printf("%d: continue\n", getpid());
        }
    }
}

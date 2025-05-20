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
        import core.sys.posix.sys.socket: AF_INET6, AF_INET;
        const af_const = family = V == 6 ? AF_INET6 : AF_INET;
        family = af_const;

        import core.sys.posix.netinet.in_: sockaddr_in6, inet_pton, sockaddr, sockaddr_in, in6addr_any, htons, htonl, INADDR_ANY;
        import core.stdc.stdio: printf, perror;

        sockaddr_in6 servaddr;
        import atlant.net.address;
        bool success = false;
        bool flag = false;
        success = parse(addr, cast(ushort) port, &servaddr, &flag);
        if (flag == true)
        {
            family = AF_INET; // actual family is IPv4
            translated = true;
        }

        if (!success)
        {
            import core.sys.posix.unistd: getpid, fork;
            import core.sys.posix.netdb;

            addrinfo* addrinfo;
            int result = getaddrinfo(addr, null, null, &addrinfo);

            if (result == 0)
            {
                bool parent = true;
                int pid;
                while (addrinfo !is null)
                {
                    pid = fork();
                    if (pid == 0)
                    {
                        parent = false;
                        success = true;

                        static if (V == 6)
                        {
                            if (addrinfo.ai_family == AF_INET)
                            {
                                import core.stdc.string: memcpy;
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

                if (parent)
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
            import atlant.net.socket: create;

            int sockfd = create(af_const, cast(sockaddr*) &servaddr, servaddr.sizeof);
            if (sockfd == -1)
            {
                return -1;
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
        // if (status == -1)
        // {
        //     status = tryFamily!4();
        //     if (status < 0)
        //     {
        //         return;
        //     }
        // }

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
                debug if (logpid) printf("%d: fork %d\n", getpid(), pid);
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

            bool parent = true;
            import core.stdc.stdio;
            while (addrNode !is null)
            {
                int pid = fork();
                if (pid == 0)
                {
                    parent = false;
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

            if (parent)
            {
                debug if (conf.logpid) printf("%d: wait\n", getpid());
                while (wait(null) > 0) {}
                debug if (conf.logpid) printf("%d: continue\n", getpid());
            }
        }
    }
}

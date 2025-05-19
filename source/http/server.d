module atlant.http.server;

import atlant.utils.configuration;

extern(C) void* run_server_instance(void* data)
{
    ServerInstance* instance = cast(ServerInstance*) data;
    instance.serve();
    return null;
}

bool doWork = true;

extern (C) void termination_handler(int signum) nothrow @nogc
{
    import core.sys.posix.unistd;
    doWork = false;
}

import core.sys.posix.netinet.in_;
void normalize(bool anyaddr, int family, sockaddr_in6* addr)
{
    // import core.sys.posix.netinet.in_;
    import core.sys.posix.sys.socket;
    if (anyaddr)
    {
        if (family == AF_INET6)
        {
            if (addr.sin6_addr.s6_addr[0x0a] == 0xff &&
                addr.sin6_addr.s6_addr[0x0b] == 0xff)
            {
                int hits = 0;
                for (; hits  < 0xa; hits ++)
                {
                    if (addr.sin6_addr.s6_addr[hits ] != 0)
                    {
                        break;
                    }
                }

                if (hits == 0xa)
                {
                    // That's IPv4 address mapped to IPv6
                    // Translation
                    addr.sin6_family = AF_INET;
                    addr.sin6_addr.s6_addr[0x00] = addr.sin6_addr.s6_addr[0x0c];
                    addr.sin6_addr.s6_addr[0x01] = addr.sin6_addr.s6_addr[0x0d];
                    addr.sin6_addr.s6_addr[0x02] = addr.sin6_addr.s6_addr[0x0e];
                    addr.sin6_addr.s6_addr[0x03] = addr.sin6_addr.s6_addr[0x0f];

                    for (int i = 0x0a; i <= 0x0f; i++)
                    {
                        addr.sin6_addr.s6_addr[i] = 0x0;
                    }
                }
            }
        }
    }
}

struct ServerInstance
{
    private int sockfd = -1;
    int family;
    char* addr;
    int port;
    bool anyaddr;

    int try6()
    {
        import core.sys.posix.sys.socket;
        family = AF_INET6;
        import core.sys.posix.netinet.in_;
        import core.sys.posix.unistd;

        import core.stdc.string;
        import core.stdc.stdio;
        import core.stdc.errno;

        sockaddr_in6 servaddr;
        int sockfd = socket(AF_INET6, SOCK_STREAM, 0);
        if (sockfd == -1)
        {
            perror("socket");
            return -1;
        }

        int v = 1;
        setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &v, int.sizeof);
        setsockopt(sockfd, SOL_SOCKET, SO_REUSEPORT, &v, int.sizeof);

        bool success = false;

        servaddr.sin6_family = AF_INET6;
        servaddr.sin6_port = htons(cast(ushort) port);

        if (addr is null)
        {
            servaddr.sin6_addr = in6addr_any;
            success = true;
            anyaddr = true;
        }

        if (!success)
        {
            if (inet_pton(AF_INET6, addr, &servaddr.sin6_addr) == 1)
            {
                success = true;
            }
        }

        if (!success)
        {
            if (inet_pton(AF_INET, addr, &servaddr.sin6_addr) == 1)
            {
                family = AF_INET; // actual family is IPv4

                servaddr.sin6_family = AF_INET6;
                servaddr.sin6_addr.s6_addr[0x0a] = 0xff;
                servaddr.sin6_addr.s6_addr[0x0b] = 0xff;

                servaddr.sin6_addr.s6_addr[0x0c] = servaddr.sin6_addr.s6_addr[0x00];
                servaddr.sin6_addr.s6_addr[0x0d] = servaddr.sin6_addr.s6_addr[0x01];
                servaddr.sin6_addr.s6_addr[0x0e] = servaddr.sin6_addr.s6_addr[0x02];
                servaddr.sin6_addr.s6_addr[0x0f] = servaddr.sin6_addr.s6_addr[0x03];

                for (int i = 0x00; i < 0x0a; i++)
                {
                    servaddr.sin6_addr.s6_addr[i] = 0x0;
                }
                success = true;
            }
        }

        if (success)
        {
            if (bind(sockfd, cast(sockaddr*) &servaddr, servaddr.sizeof) != 0)
            {
                perror("bind");
                return -2;
            }
        }

        if ((listen(sockfd, 0)) != 0)
        {
            perror("listen");
            return -2;
        }

        this.sockfd = sockfd;
        return 0;
    }

    int try4()
    {
        import core.sys.posix.sys.socket;
        family = AF_INET;
        import core.sys.posix.netinet.in_;
        import core.sys.posix.unistd;

        import core.stdc.string;
        import core.stdc.stdio;
        import core.stdc.errno;

        sockaddr_in servaddr;
        int sockfd = socket(AF_INET, SOCK_STREAM, 0);
        if (sockfd == -1)
        {
            perror("socket");
            return -1;
        }

        int v = 1;
        setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &v, int.sizeof);
        setsockopt(sockfd, SOL_SOCKET, SO_REUSEPORT, &v, int.sizeof);

        servaddr.sin_family = AF_INET;
        servaddr.sin_port = htons(cast(ushort) port);

        bool success = false;

        if (addr is null)
        {
            servaddr.sin_addr.s_addr = htonl(INADDR_ANY);
            success = true;
            anyaddr = true;
        }
        else
        {
            if (inet_pton(AF_INET, addr, &servaddr.sin_addr) == 1)
            {
                success = true;
            }
        }

        if (bind(sockfd, cast(sockaddr*) &servaddr, servaddr.sizeof) != 0)
        {
            perror("bind");
            return -2;
        }

        if ((listen(sockfd, 0)) != 0)
        {
            perror("listen");
            return -2;
        }

        this.sockfd = sockfd;

        return 0;
    }

    void serve()
    {
        import core.sys.posix.sys.socket;
        import core.sys.posix.unistd;
        import core.stdc.string;
        import core.stdc.stdio;
        import core.stdc.errno;

        if (try6() == -1)
        {
            if (try4() < 0)
            {
                return;
            }
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
                normalize(anyaddr, family, &clientaddr);
                pid = session.spawn(family, clientaddr);
                if (pid == 0)
                {
                    break;
                }
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

        if (conf.defaultBindAddresses)
        {
            instance.addr = null;
            run_server_instance(cast(void*) &instance);
        }
        else
        {
            auto addrNode = conf.listOfAddresses.front();
            while (addrNode !is null)
            {
                int pid = fork();
                if (pid == 0)
                {
                    instance.addr = addrNode.value;
                    run_server_instance(cast(void*) &instance);
                    break;
                }
                addrNode = addrNode.next;
            }

            while (wait(null) > 0) {}
        }
    }
}

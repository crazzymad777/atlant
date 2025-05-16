module atlant.http.server;

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

struct ServerInstance
{
    private int sockfd = -1;
    int port;

    void serve()
    {
        import core.sys.posix.netinet.in_;
        import core.sys.posix.sys.socket;
        import core.sys.posix.unistd;

        import core.stdc.string;
        import core.stdc.stdio;
        import core.stdc.errno;

        sockaddr_in servaddr;
        int sockfd = socket(AF_INET, SOCK_STREAM, 0);
        if (sockfd == -1)
        {
            printf("socket failed: %s, %d\n", strerror(errno), errno);
            return;
        }

        int v = 1;
        setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &v, int.sizeof);
        setsockopt(sockfd, SOL_SOCKET, SO_REUSEPORT, &v, int.sizeof);

        servaddr.sin_family = AF_INET;
        servaddr.sin_addr.s_addr = htonl(INADDR_ANY);
        servaddr.sin_port = htons(cast(ushort) port);

        if (bind(sockfd, cast(sockaddr*) &servaddr, servaddr.sizeof) != 0)
        {
            printf("bind failed: %s, %d\n", strerror(errno), errno);
            return;
        }

        if ((listen(sockfd, 0)) != 0)
        {
            printf("listen failed: %s, %d\n", strerror(errno), errno);
            return;
        }

        // printf("signal: %d \n", getpid());
        import core.sys.posix.signal;
        if (signal(SIGINT, &termination_handler) == SIG_IGN)
        {
            signal(SIGINT, SIG_IGN);
        }

        import core.sys.posix.sys.time;
        timeval timeout;
        timeout.tv_sec = 5;
        timeout.tv_usec = 0;
        setsockopt (sockfd, SOL_SOCKET, SO_RCVTIMEO, &timeout, timeout.sizeof);

        int pid = -1;
        while (doWork)
        {
            int conn = accept(sockfd, null, null);
            if (conn == -1)
            {
                if (errno == EAGAIN || errno == EWOULDBLOCK || errno == ECONNABORTED || errno == EMFILE || errno == ENFILE || errno == ENOBUFS || errno == ENOMEM || errno == EPERM || errno == EPROTO)
                {
                    continue;
                }

                printf("accept break: %s, %d\n", strerror(errno), errno);

                break;
            }
            else
            {
                import atlant.http.session;
                Session session = Session(conn);
                pid = session.spawn();
                if (pid == 0)
                {
                    break;
                }
            }
        }

        if (pid != 0)
        {
            // printf("close main %d\n", sockfd);
            // close(sockfd);
            shutdown(sockfd, SHUT_RDWR);
        }

        // join here session threads...
    }
}

struct Server
{
    ServerInstance instance;

    void listen(int port)
    {
        import core.sys.posix.unistd;
        instance.port = port;
        run_server_instance(cast(void*) &instance);
    }
}

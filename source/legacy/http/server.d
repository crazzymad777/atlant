module atlant.http.server;

extern(C) void* run_server_instance(void* data)
{
    ServerInstance* instance = cast(ServerInstance*) data;
    instance.serve();
    return null;
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

        while (true)
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
                session.spawn();
            }
        }

        close(sockfd);

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

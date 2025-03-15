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

    void serve()
    {
        import core.sys.linux.errno;

        import core.sys.posix.netinet.in_;
        import core.sys.posix.sys.socket;
        import core.sys.posix.unistd;

        sockaddr_in servaddr;
        int sockfd = socket(AF_INET, SOCK_STREAM, 0);
        if (sockfd == -1)
        {
            return;
        }

        servaddr.sin_family = AF_INET;
        servaddr.sin_addr.s_addr = htonl(INADDR_ANY);
        servaddr.sin_port = htons(8080);

        if (bind(sockfd, cast(sockaddr*) &servaddr, servaddr.sizeof) != 0)
        {
            return;
        }

        if ((listen(sockfd, 0)) != 0)
        {
            return;
        }

        while (true)
        {
            int conn = accept(sockfd, null, null);
            if (conn == -1)
            {
                if (conn == EAGAIN || conn == EWOULDBLOCK || conn == ECONNABORTED || conn == EMFILE || conn == ENFILE || conn == ENOBUFS || conn == ENOMEM || conn == EPERM || conn == EPROTO)
                {
                    continue;
                }

                break;
            }
            else
            {
                import atlant.http.session;
                Session session = Session(conn);
                session.fork();
            }
        }

        close(sockfd);

        // join here session threads...
    }
}

struct Server
{
    ServerInstance instance;

    void listen()
    {
        import atlant.utils.thread;
        Thread thread = Thread(&run_server_instance, cast(void*) &instance);
        thread.join();
    }
}

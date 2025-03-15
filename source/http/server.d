module atlant.http.server;

extern(C) void* run(void* data)
{
    ServerInstance* instance = cast(ServerInstance*) data;
    instance.listen();
    return null;
}

struct ServerInstance
{
    private int sockfd = -1;

    void listen()
    {
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
    }

    ~this()
    {
        import core.sys.posix.unistd;
        if (sockfd > 0)
        {
            close(sockfd);
        }
    }
}

struct Server
{
    ServerInstance instance;

    void listen()
    {
        import atlant.utils.thread;
        Thread thread = Thread(&run, cast(void*) &instance);
        thread.join();
    }
}

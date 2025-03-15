module atlant.http.session;

import atlant.utils.thread;

extern(C) void* run_session(void* data)
{
    Session* session = cast(Session*) data;
    session.serve();
    return null;
}

struct Session
{
    int sockfd;
    this(int sockfd)
    {
        this.sockfd = sockfd;
    }

    void serve()
    {
        import core.sys.posix.unistd;
        close(sockfd);
    }

    Thread fork()
    {
        Thread thread = Thread(&run_session, cast(void*) &this);
        return thread;
    }
}

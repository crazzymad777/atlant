module atlant.http.session;

import atlant.utils.thread;
import atlant.http.parser;

enum HttpMethod
{
    UNSUPPORTED,
    HEAD,
    GET
}

extern(C) void* run_session(void* data)
{
    Session* session = cast(Session*) data;
    session.serve();
    return null;
}

struct Session
{
    Parser parser;
    int sockfd;
    this(int sockfd)
    {
        this.sockfd = sockfd;
    }

    void serve()
    {
        import core.stdc.string;
        import core.stdc.stdio;
        import core.sys.posix.unistd;
        import atlant.http.chunk;
        import core.stdc.errno;

        Chunk chunk;
        while (true)
        {
            chunk.length = chunk.buffer.sizeof;
            import core.sys.posix.sys.socket;

            long status = recv(sockfd, &chunk.buffer, chunk.buffer.sizeof, 0);
            if (status > 0)
            {
                printf("Received %ld\n", status);
                import atlant.main;
                chunk.length = status;
                int count = parser.feed(&chunk);
                bool keepAlive = true;

                for (int i = 0; i < count; i++)
                {
                    import std.conv: to;
                    import std.string;
                    Request req = parser.requests.front();
                    parser.requests.removeFront();
                    Response res = handleRequest(req);
                    string head;
                    if (res.status == 200)
                    {
                        head = "HTTP/1.1 200 OK\r\n";
                    }
                    else if (res.status == 404)
                    {
                        head = "HTTP/1.1 404 Not Found\r\n";
                    }
                    else
                    {
                        head = "HTTP/1.1 " ~ to!string(res.status) ~ "\r\n";
                    }
                    head ~= "Server: atlant/0.0.1\r\nContent-Type: " ~ res.mime ~ "\r\nContent-Length: " ~ to!string(res.body.length) ~ "\r\n\r\n";
                    send(sockfd, toStringz(head), head.length, 0);

                    if (req.method != HttpMethod.HEAD)
                    {
                        send(sockfd, res.body.ptr, res.body.length, 0);
                    }

                    keepAlive &= req.keepAlive;
                }

                if (!keepAlive)
                {
                    printf("DO NOT KEEP CONNECTION\n");
                    break;
                }
            }
            else if (status == 0)
            {
                printf("Received %ld\n", status);
                // break;
            }
            else if (status == -1)
            {
                if (errno == EAGAIN || errno == EWOULDBLOCK)
                {
                    continue;
                }
                break;
            }
        }
        close(sockfd);
    }

    void spawn()
    {
        import core.sys.posix.unistd;
        import core.stdc.stdio;
        int pid = fork();
        if (pid == 0)
        {
            printf("Session job (%d) had started.\n", getpid());
            run_session(cast(void*) &this);
        }
    }
}

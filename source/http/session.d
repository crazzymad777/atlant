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
        import core.stdc.stdio;
        import core.sys.posix.unistd;
        import atlant.http.chunk;
        import core.stdc.errno;

        Chunk chunk;
        // chunk.length = chunk.buffer.sizeof;
        while (true)
        {
            chunk.length = chunk.buffer.sizeof;
            import core.sys.posix.sys.socket;
            long status = recv(sockfd, &chunk.buffer, chunk.length, 0);
            if (status > 0)
            {
                chunk.length = status;
                int count = parser.feed(&chunk);

                //
                // for (int i = 0; i < count; i++)
                // {
                //     import std.string;
                //     send(sockfd, toStringz(stub), stub.length, 0);
                // }
                import atlant.main;
                bool keepAlive = true;
                for (int i = 0; i < count; i++)
                {
                    import std.conv: to;
                    import std.string;
                    Request req = parser.requests.front();
                    parser.requests.removeFront();
                    Response res = handleRequest(req);
                    string stub;
                    if (res.status == 200)
                    {
                        stub = "HTTP/1.1 200 OK\r\n";
                    }
                    else if (res.status == 404)
                    {
                        stub = "HTTP/1.1 404 Not Found\r\n";
                    }
                    else
                    {
                        stub = "HTTP/1.1 " ~ to!string(res.status) ~ "\r\n";
                    }
                    stub ~= "Server: atlant/0.0.1\r\nContent-Type: " ~ res.mime ~ "\r\nContent-Length: " ~ to!string(res.body.length) ~ "\r\n\r\n";
                    //string stub = "HTTP/1.1 200 OK\r\nServer: atlant/0.0.1\r\nContent-Type: text/plain\r\nContent-Length: 0\r\n\r\n";
                    if (req.method != HttpMethod.HEAD)
                    {
                        stub ~= res.body;
                    }
                    else
                    {
                        printf("HEAD\n");
                    }
                    send(sockfd, toStringz(stub), stub.length, 0);
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
                break;
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

    Thread fork()
    {
        Thread thread = Thread(&run_session, cast(void*) &this);
        return thread;
    }
}

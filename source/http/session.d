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
        import core.sys.posix.unistd;
        import atlant.http.chunk;
        import core.stdc.errno;

        Chunk chunk;
        chunk.length = chunk.buffer.sizeof;
        while (true)
        {
            import core.sys.posix.sys.socket;
            long status = recv(sockfd, &chunk.buffer, chunk.length, 0);
            if (status > 0)
            {
                chunk.length = status;
                int count = parser.feed(&chunk);

                auto stub = "HTTP/1.1 200 OK\r\nServer: atlant-0.0.1\r\nContent-Type: text/plain\r\nContent-Length: 0\r\n\r\n";
                for (int i = 0; i < count; i++)
                {
                    send(sockfd, &stub, stub.length, 0);
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

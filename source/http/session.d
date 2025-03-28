module atlant.http.session;

public import atlant.http.parser: Request;
import atlant.utils.array;
import atlant.http.parser;
import atlant.utils.data;

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

struct Response
{
    int status;
    Data body;
    string mime;
}

Data build(string...)(string args)
{
    import core.stdc.stdlib;
    import core.stdc.string;
    int count = 0;
    foreach(x; args)
    {
        count += x.length;
    }
    Data data = Data(malloc(count), count);
    count = 0;
    ubyte* dest = cast(ubyte*) data.pointer;

    foreach(x; args)
    {
        memcpy(dest, x.ptr, x.length);
        dest += x.length;
    }
    return data;
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
        import core.stdc.stdlib;
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
                bool closeConnection = true;

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

                    Data data = build(head, "Server: atlant/0.0.1\r\nContent-Type: ", res.mime, "\r\nContent-Length: ", to!string(res.body.length), "\r\n\r\n");
                    send(sockfd, data.pointer, data.length, 0);
                    free(data.pointer);

                    if (req.method != HttpMethod.HEAD)
                    {
                        send(sockfd, res.body.pointer, res.body.length, 0);
                    }

                    closeConnection &= req.closeConnection;
                }

                if (closeConnection)
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

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
                    Request req = parser.requests.front().value;
                    Response res = handleRequest(req);

                    char[24] x;
                    if (res.status == 200)
                    {
                        snprintf(&x[0], 24, "HTTP/1.1 200 OK");
                    }
                    else if (res.status == 404)
                    {
                        snprintf(&x[0], 24, "HTTP/1.1 404 Not Found");
                    }
                    else
                    {
                        snprintf(&x[0], 24, "HTTP/1.1 %d", res.status);
                    }

                    char[256] buffer;
                    int bytes = snprintf(&buffer[0], 256, "%s\r\nServer: atlant/0.0.1\r\nContent-Type: text-plain\r\nContent-Length: %lu\r\n\r\n", &x[0], res.body.length);

                    //Data data = build(head, "Server: atlant/0.0.1\r\nContent-Type: ", res.mime, "\r\nContent-Length: ", to!string(res.body.length), "\r\n\r\n");
                    send(sockfd, &buffer[0], bytes, 0);
                    //free(data.pointer);

                    if (req.method != HttpMethod.HEAD)
                    {
                        send(sockfd, res.body.pointer, res.body.length, 0);
                    }

                    closeConnection &= req.closeConnection;
                    parser.requests.removeFront();
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

module atlant.http.session;

public import atlant.http.parser: Request;
import atlant.utils.array;
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

import atlant.cache.gem;

struct Response
{
    int status;
    ResultType type;

    enum ResultType
    {
        array,
        text,
        gem
    };

    union
    {
        Array!char array;
        char[256] text;
        Gem* gem;
    }
}

import atlant.http.server: doWork;

struct Session
{
    import core.sys.posix.netinet.in_;
    char[INET6_ADDRSTRLEN] addrbuf;
    // int addrport = 0;
    Parser parser;
    int sockfd;

    this(int sockfd)
    {
        this.sockfd = sockfd;
    }

    void serve()
    {
        import core.stdc.time;
        char[256] timestamp;
        time_t now;
        tm* tmptr;

        import core.stdc.stdlib;
        import core.stdc.string;
        import core.stdc.stdio;
        import core.sys.posix.unistd;
        import atlant.http.chunk;
        import core.stdc.errno;

        Chunk chunk;
        while (doWork)
        {
            chunk.length = chunk.buffer.sizeof;
            import core.sys.posix.sys.socket;

            long status = recv(sockfd, &chunk.buffer, chunk.buffer.sizeof, 0);
            if (status > 0)
            {
                // printf("Received %ld\n", status);
                import atlant;
                chunk.length = status;
                int count = parser.feed(&chunk);
                bool closeConnection = true;

                for (int i = 0; i < count; i++)
                {
                    now = time(null);
                    tmptr = localtime(&now);
                    Response res;
                    Request req = parser.requests.front().value;
                    handleRequest(req, &res);

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

                    char* data_to_response;
                    char* mime;
                    size_t length;

                    if (res.type == Response.ResultType.gem)
                    {
                        data_to_response = res.gem.data;
                        mime = res.gem.mime.data;
                        length = res.gem.length;
                    }
                    else if (res.type == Response.ResultType.text)
                    {
                        import core.stdc.string;
                        data_to_response = cast(char*) &res.text[0];
                        mime = cast(char*) "text/plain; charset=utf-8";
                        length = strlen(data_to_response);
                    }
                    else if (res.type == Response.ResultType.array)
                    {
                        import core.stdc.string;
                        data_to_response = res.array.data();
                        mime = cast(char*) "text/plain; charset=utf-8";
                        length = res.array.size() - 1;
                    }

                    import atlant: SERVER_STRING;
                    char[256] buffer;
                    int bytes = snprintf(&buffer[0], 256, "%s\r\nServer: %s\r\nContent-Type: %s\r\nContent-Length: %lu\r\n\r\n", &x[0], SERVER_STRING.ptr, mime, length);

                    send(sockfd, &buffer[0], bytes, 0);
                    char* method = cast(char*) "-".ptr;
                    if (req.method != HttpMethod.HEAD)
                    {
                        send(sockfd, data_to_response, length, 0);
                        if (req.method == HttpMethod.GET)
                        {
                            method = cast(char*) "GET".ptr;
                        }
                    }
                    else
                    {
                        method = cast(char*) "HEAD".ptr;
                    }

                    import atlant: accesslog;
                    if (accesslog !is null)
                    {
                        timestamp[0] = '-';
                        timestamp[1] = '\0';
                        strftime(&timestamp[0], timestamp.sizeof, "%Y-%m-%dT%H:%M:%S%z", tmptr);
                        fprintf(accesslog, "%s %s %s /%s %d %lu\n", &addrbuf[0], &timestamp[0], method, req.s1.data, res.status, length);
                        fflush(accesslog);
                    }

                    closeConnection &= req.closeConnection;
                    parser.requests.removeFront();
                    // res.gem.clean();
                    if (res.type == Response.ResultType.array)
                    {
                        res.array.drop();
                    }
                    req.s1.drop();
                }

                if (closeConnection)
                {
                    // printf("DO NOT KEEP CONNECTION\n");
                    break;
                }
            }
            else if (status == 0)
            {
                // printf("Received %ld\n", status);
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

    int spawn(int family, sockaddr_in6 clientaddr)
    {
        import core.stdc.stdio;
        if (inet_ntop(family, cast(sockaddr*) &clientaddr, &addrbuf[0], addrbuf.sizeof) is null)
        {

            perror("inet_ntop");
            addrbuf[0] = '-';
            addrbuf[1] = '\0';
            // addrport = clientaddr.sin6_port;
        }
        // printf("%s\n", &addrbuf[0]);

        import core.sys.posix.unistd;

        int pid = fork();
        if (pid == 0)
        {
            // import core.sys.posix.signal;
            // signal(SIGINT, SIG_DFL);
            // printf("Session job (%d) had started.\n", getpid());
            run_session(cast(void*) &this);
        }
        return pid;
    }
}

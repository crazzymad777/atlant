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

import atlant.cache.gem;

struct Response
{
    int status;
    ResultType type;

    enum ResultType
    {
        text,
        gem
    };

    union
    {
        char[256] text;
        Gem* gem;
    }
}

import atlant.http.server: doWork;

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
        while (doWork)
        {
            chunk.length = chunk.buffer.sizeof;
            import core.sys.posix.sys.socket;

            long status = recv(sockfd, &chunk.buffer, chunk.buffer.sizeof, 0);
            if (status > 0)
            {
                // printf("Received %ld\n", status);
                import atlant.main;
                chunk.length = status;
                int count = parser.feed(&chunk);
                bool closeConnection = true;

                for (int i = 0; i < count; i++)
                {
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
                        mime = cast(char*) "text/plain";
                        length = strlen(data_to_response);
                    }

                    char[256] buffer;
                    int bytes = snprintf(&buffer[0], 256, "%s\r\nServer: atlant/0.0.1\r\nContent-Type: %s\r\nContent-Length: %lu\r\n\r\n", &x[0], mime, length);

                    send(sockfd, &buffer[0], bytes, 0);
                    if (req.method != HttpMethod.HEAD)
                    {
                        send(sockfd, data_to_response, length, 0);
                    }

                    closeConnection &= req.closeConnection;
                    parser.requests.removeFront();
                    // res.gem.clean();
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

    int spawn()
    {
        import core.sys.posix.unistd;
        import core.stdc.stdio;
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

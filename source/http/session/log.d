module atlant.http.session.log;

struct Log
{
    import core.sys.posix.netinet.in_;
    import atlant.http.session: HttpMethod;
    char[INET6_ADDRSTRLEN] addrbuf;
    // int addrport = 0;
    void write(LogTime* logtime, HttpMethod httpMethod, char* path, int status, ulong response)
    {
        import atlant: accesslog;
        import core.stdc.stdio;
        if (accesslog !is null)
        {
            char* method = cast(char*) "-".ptr;
            if (httpMethod == HttpMethod.HEAD)
            {
                method = cast(char*) "HEAD".ptr;
            }
            else if (httpMethod == HttpMethod.GET)
            {
                method = cast(char*) "GET".ptr;
            }

            logtime.format();
            fprintf(accesslog, "%s %s %s /%s %d %lu\n", &addrbuf[0], &logtime.timestamp[0], method, path, status, response);
            fflush(accesslog);
        }
    }
}

struct LogTime
{
    import core.stdc.time;
    void notch()
    {
        now = time(null);
        tmptr = localtime(&now);
    }

    void format()
    {
        timestamp[0] = '-';
        timestamp[1] = '\0';
        strftime(&timestamp[0], timestamp.sizeof, "%Y-%m-%dT%H:%M:%S%z", tmptr);
    }

    char[256] timestamp;
    time_t now;
    tm* tmptr;
}

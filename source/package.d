module atlant;

const PROGRAM_NAME = "atlant";
const VERSION = "0.0.1";

const SERVER_STRING = PROGRAM_NAME ~ "/" ~ VERSION;

import atlant.utils.string;
import atlant.http.session;
import atlant.cache.gem;

import atlant.cache.hash_table;
HashTable ht;

import core.stdc.stdio;
FILE* pidfile(char* filename)
{
    FILE* f = null;
    if (filename !is null)
    {
        f = fopen(filename, "w");
        if (f !is null)
        {
            import core.sys.posix.unistd;
            fprintf(f, "%d", getpid());
            fclose(f);
        }
        else
        {
            perror(filename);
        }
    }
    return f;
}

FILE* accesslog = null;

void openlog(char* filename)
{
    if (filename is null)
    {
        return;
    }

    accesslog = fopen(filename, "a");
    if (accesslog is null)
    {
        perror(filename);
    }
}

void closelog()
{
    if (accesslog !is null)
    {
        fclose(accesslog);
    }
}

void handleRequest(Request req, Response* res)
{
    import atlant.utils.array;
    import core.stdc.stdio;

    String s2;
    decodeURI(&req.s1, &s2);
	auto gem = ht.getGem(&s2);

	if (gem !is null)
	{
        *res = Response(200, Response.ResultType.gem, gem: gem);
        s2.drop();
        return;
	}

    string str = "Requested Resource /%s Not Found";
	size_t n = str.length - 2 + s2.length + 1;
	res.array = Array!(char)(n);
	res.type = Response.ResultType.array;
	snprintf(res.array.data(), n, str.ptr, s2.data);
	res.status = 404;
	s2.drop();
	return;
}

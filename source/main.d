module atlant.main;

import atlant.cache.hash_table;
HashTable ht;
string bodyNotFound = "Requested Resource Not Found";
Gem notFound;

extern(C) void main()
{
    notFound = Gem(null, String.staticCString(cast(char*) "text/plain".ptr), -1, true, cast(char*) bodyNotFound.ptr, bodyNotFound.length);

    import atlant.utils.configuration;
    import atlant.filesystem.scanner;
    import core.stdc.stdio;

    Configuration conf;
    defaultConfiguration(&conf);
    // parseArgs...
    printf("directory=%s\n", conf.directory.data);
    printf("port=%d\n", conf.port);

    Scanner scanner = Scanner(conf.directory.data);
    scanner.scan();
    scanner.detach(); // detach tree root
    // scanner.show();

    ht = HashTable(scanner.root);
    // ht.show();
    // ht.drop();

    import atlant.http.server;
    Server server;
	server.listen(conf.port);
}

import atlant.utils.string;
import atlant.http.session;
import atlant.cache.gem;

void handleRequest(Request req, Response* res)
{
    import atlant.utils.data;
    import core.stdc.stdio;

	auto gem = ht.getGem(&req.s1);
	if (gem !is null)
	{
        *res = Response(200, Response.ResultType.gem, gem: gem);
        return;
	}
	snprintf(cast(char*) res.text, 256, "Requested Resource /%s Not Found", req.s1.data);
	res.type = Response.ResultType.text;
	res.status = 404;
	return;
}

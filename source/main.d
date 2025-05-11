module atlant.main;

import atlant.cache.hash_table;
HashTable ht;

extern(C) void main(int argc, char** argv)
{
    import core.stdc.stdio;
    import atlant.utils.configuration;
    import atlant.filesystem.scanner;

    Configuration conf;
    defaultConfiguration(&conf);
    parseArgs(&conf, argc, argv);

    Scanner scanner = Scanner(conf.directory.data);
    scanner.scan();
    scanner.detach(); // detach tree root

    ht = HashTable(scanner.root);

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
